# YouTube Downloader Android — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** App Flutter Android (usage perso) embarquant YouTube dans une WebView, avec un bouton flottant qui télécharge la vidéo courante en MP4 ou en vrai MP3, support playlist auto-détecté.

**Architecture:** WebView (`flutter_inappwebview`) → suivi d'URL → FAB Télécharger → extraction via une interface `VideoExtractor` (impl `youtube_explode_dart`) → téléchargement `dio` dans un Foreground Service → conversion FFmpeg (`audio` variant) pour le MP3 → état persisté en `sqflite`.

**Tech Stack:** Flutter/Dart, flutter_inappwebview, youtube_explode_dart, ffmpeg_kit_flutter_new (audio), dio, sqflite, path_provider, permission_handler, flutter_foreground_task, google_fonts.

**App :** **Tubebox** — tagline « Téléchargez. C'est tout. ». Package `com.prince.tubebox`.

---

## Design System (issu du handoff Claude Design)

Reproduire fidèlement ces tokens. Vibe minimaliste : beaucoup d'espace, hairlines 0.5px, accent orange **uniquement** sur les actions de téléchargement.

**Polices :** Geist (sans) + Geist Mono (chiffres/labels techniques), via `google_fonts`. `letter-spacing: -0.005em`, features `ss01 cv11`.

**Accent :** `#FF7A00` (orange, défaut). Palette settings : `#FF7A00`, `#FF0033`, `#2E7DFF`, `#16A34A`, mono.

**Tokens couleur (clair / sombre) :**

| token | light | dark |
|-------|-------|------|
| bg | `#FAFAFA` | `#0A0A0A` |
| bg-2 | `#F4F4F4` | `#0F0F0F` |
| surface | `#FFFFFF` | `#141414` |
| surface-2 | `#F7F7F7` | `#1A1A1A` |
| text | `#0A0A0A` | `#FAFAFA` |
| text-2 | `#404040` | `#D4D4D4` |
| muted | `#737373` | `#8A8A8A` |
| faint | `#A3A3A3` | `#5C5C5C` |
| border | `#EAEAEA` | `#1F1F1F` |
| border-2 | `#D4D4D4` | `#2A2A2A` |
| error | `#E04444` | `#E04444` |

**Composants clés :**
- **FAB** : extended (icône download + « Télécharger »), `height 52`, `radius 28`, fond accent, ombre teintée accent. Position bottom-right 16.
- **Bottom sheet format** : liste linéaire, chaque ligne = icône (film/musique) + label (`MP4 1080p`, `MP3 320 kbps`) + taille estimée + tag (`Full HD`, `Léger`…). Badge accent « Dernier utilisé » sur le dernier choix. Note bas de sheet « Demander à chaque fois ».
- **Dialog playlist** : titre + sous-titre, carte contexte (icône liste + titre playlist + nb), 2 `RadioRow` (« Cette vidéo seulement » / « Toute la playlist (N vidéos) »), boutons Annuler / Continuer. Row sélectionnée = fond `accent 8%`.
- **Téléchargements** : 3 onglets soulignés (En cours / Terminés / Erreurs) avec pastille de compte. Ligne active = thumbnail + titre + `MP4 720p · 78 Mo` + boutons pause/close + `pbar` (barre 3px) ; conversion = barre rayée + point pulsant ; en file = point gris. Ligne terminée = thumbnail + meta + menu. Ligne erreur = carré rouge + raison en rouge + bouton retry.
- **pbar** : 3px, radius 999, fond `border`, remplissage accent. Variante indéterminée (sweep) + variante rayée (conversion).
- **Settings** : sections en eyebrow majuscule ; cartes moteur (radio + label mono + tag `v1` / `Bientôt` grisé) ; rows label/valeur/chevron.
- **Onboarding** : BrandMark (carré accent 56px, radius 16, flèche download blanche), titre 28px, sous-titre muted, liste de 3 permissions (Stockage / Notifications / Tâche d'arrière-plan) avec état Autorisé/Autoriser, CTA pleine largeur « Commencer ».

---

## File Structure

```
lib/
  main.dart                              # bootstrap + permissions
  app.dart                               # MaterialApp + routes
  models/
    video_info.dart                      # métadonnées + flux dispo
    stream_option.dart                   # un format téléchargeable (mp4/audio + qualité)
    download_task.dart                   # enregistrement persistant + DownloadStatus
    download_format.dart                 # enum DownloadFormat { mp4, mp3 }
  extractor/
    video_extractor.dart                 # interface VideoExtractor
    youtube_explode_extractor.dart       # impl v1
  services/
    storage_service.dart                 # chemins + normalisation nom fichier + scan média
    download_service.dart                # download flux + file séquentielle
    conversion_service.dart              # FFmpeg audio -> mp3 + tags
    foreground_download_task.dart        # handler du Foreground Service
  data/
    download_repository.dart             # sqflite CRUD des DownloadTask
  settings/
    settings_service.dart                # SharedPreferences: moteur + dernier format + thème
  theme/
    app_theme.dart                       # tokens Tubebox (clair/sombre) + Geist + accent
  ui/
    onboarding_screen.dart               # permissions 1er lancement
    webview_screen.dart                  # WebView + FAB + suivi URL + détection playlist
    downloads_screen.dart                # 3 onglets: en cours / terminés / erreurs
    settings_screen.dart                 # moteur d'extraction + défauts + stockage + à propos
    widgets/
      format_sheet.dart                  # bottom sheet linéaire mp4/mp3 + qualités + badge
      playlist_choice_dialog.dart        # radio: cette vidéo / playlist + carte contexte
  utils/
    url_utils.dart                       # parsing URL: videoId, isPlaylist, listId
android/app/src/main/AndroidManifest.xml # permissions + foreground service
test/
  utils/url_utils_test.dart
  models/download_task_test.dart
  services/storage_service_test.dart
  data/download_repository_test.dart
  extractor/youtube_explode_extractor_test.dart
```

Tâches ordonnées des unités pures (testables sans device) vers l'UI/natif (vérif manuelle).

---

## Task 1: Scaffold du projet Flutter

**Files:**
- Create: tout l'arbre Flutter via CLI

- [ ] **Step 1: Créer le projet**

Run:
```bash
cd /Volumes/SSD-Prince/Dev/Projet/Personel/youtube-dowloader-for-android
flutter create --org com.prince --project-name tubebox --platforms android .
```
Expected: arbre `lib/`, `android/`, `pubspec.yaml` créés. (Le repo a déjà `docs/`, ne pas l'écraser.)

- [ ] **Step 2: Ajouter les dépendances**

Run:
```bash
flutter pub add flutter_inappwebview youtube_explode_dart dio sqflite path_provider permission_handler shared_preferences flutter_foreground_task google_fonts
flutter pub add ffmpeg_kit_flutter_new
flutter pub add --dev flutter_test
```
Expected: `pubspec.yaml` mis à jour, `flutter pub get` OK.

- [ ] **Step 3: Fixer minSdk et nom**

Modifier `android/app/build.gradle.kts` (ou `.gradle`) : `minSdk = 24`, `applicationId = "com.prince.tubebox"`. Modifier `android/app/src/main/AndroidManifest.xml` : `android:label="Tubebox"`.

- [ ] **Step 4: Vérifier le build**

Run: `flutter build apk --debug`
Expected: BUILD SUCCESSFUL.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "chore: scaffold Flutter app + deps"
```

---

## Task 1.1: Thème Tubebox (tokens + Geist + accent)

**Files:**
- Create: `lib/theme/app_theme.dart`

> Fondation visuelle réutilisée par tous les écrans. Couleurs custom exposées via une extension de thème pour coller aux tokens du design (au-delà du ColorScheme Material).

- [ ] **Step 1: Implémenter**

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const kAccentDefault = Color(0xFFFF7A00);
const kAccentOptions = [
  Color(0xFFFF7A00), Color(0xFFFF0033), Color(0xFF2E7DFF), Color(0xFF16A34A),
];

@immutable
class TubeboxColors extends ThemeExtension<TubeboxColors> {
  final Color bg, bg2, surface, surface2, text, text2, muted, faint, border, border2, error, accent;
  const TubeboxColors({
    required this.bg, required this.bg2, required this.surface, required this.surface2,
    required this.text, required this.text2, required this.muted, required this.faint,
    required this.border, required this.border2, required this.error, required this.accent,
  });

  static const light = TubeboxColors(
    bg: Color(0xFFFAFAFA), bg2: Color(0xFFF4F4F4), surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFF7F7F7), text: Color(0xFF0A0A0A), text2: Color(0xFF404040),
    muted: Color(0xFF737373), faint: Color(0xFFA3A3A3), border: Color(0xFFEAEAEA),
    border2: Color(0xFFD4D4D4), error: Color(0xFFE04444), accent: kAccentDefault,
  );
  static const dark = TubeboxColors(
    bg: Color(0xFF0A0A0A), bg2: Color(0xFF0F0F0F), surface: Color(0xFF141414),
    surface2: Color(0xFF1A1A1A), text: Color(0xFFFAFAFA), text2: Color(0xFFD4D4D4),
    muted: Color(0xFF8A8A8A), faint: Color(0xFF5C5C5C), border: Color(0xFF1F1F1F),
    border2: Color(0xFF2A2A2A), error: Color(0xFFE04444), accent: kAccentDefault,
  );

  TubeboxColors withAccent(Color a) => TubeboxColors(
    bg: bg, bg2: bg2, surface: surface, surface2: surface2, text: text, text2: text2,
    muted: muted, faint: faint, border: border, border2: border2, error: error, accent: a,
  );

  @override
  TubeboxColors copyWith() => this;
  @override
  TubeboxColors lerp(ThemeExtension<TubeboxColors>? other, double t) =>
      other is TubeboxColors ? other : this;
}

class AppTheme {
  static ThemeData _build(TubeboxColors c, Brightness b) {
    final base = b == Brightness.dark ? ThemeData.dark() : ThemeData.light();
    return base.copyWith(
      scaffoldBackgroundColor: c.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: c.accent, brightness: b, primary: c.accent, surface: c.surface,
      ),
      textTheme: GoogleFonts.geistTextTheme(base.textTheme)
          .apply(bodyColor: c.text, displayColor: c.text),
      extensions: [c],
      useMaterial3: true,
    );
  }

  static ThemeData light(Color accent) =>
      _build(TubeboxColors.light.withAccent(accent), Brightness.light);
  static ThemeData dark(Color accent) =>
      _build(TubeboxColors.dark.withAccent(accent), Brightness.dark);
}

extension TubeboxColorsX on BuildContext {
  TubeboxColors get c => Theme.of(this).extension<TubeboxColors>()!;
  TextStyle get mono => GoogleFonts.geistMono();
}
```

- [ ] **Step 2: Vérifier la compilation**

Run: `flutter analyze lib/theme/app_theme.dart`
Expected: No issues.

- [ ] **Step 3: Commit**

```bash
git add lib/theme/app_theme.dart
git commit -m "feat: tubebox theme (tokens light/dark, geist, accent)"
```

---

## Task 2: url_utils (parsing URL, détection playlist)

**Files:**
- Create: `lib/utils/url_utils.dart`
- Test: `test/utils/url_utils_test.dart`

- [ ] **Step 1: Écrire les tests**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tubebox/utils/url_utils.dart';

void main() {
  test('extrait le videoId d une watch url', () {
    expect(UrlUtils.videoId('https://m.youtube.com/watch?v=abc123XYZ_-'), 'abc123XYZ_-');
  });
  test('extrait le videoId d une short url', () {
    expect(UrlUtils.videoId('https://youtu.be/abc123XYZ_-'), 'abc123XYZ_-');
  });
  test('retourne null si pas une vidéo', () {
    expect(UrlUtils.videoId('https://m.youtube.com/feed/subscriptions'), isNull);
  });
  test('détecte une playlist via list=', () {
    expect(UrlUtils.isPlaylist('https://m.youtube.com/watch?v=abc&list=PL123'), isTrue);
  });
  test('pas de playlist sans list=', () {
    expect(UrlUtils.isPlaylist('https://m.youtube.com/watch?v=abc'), isFalse);
  });
  test('extrait le listId', () {
    expect(UrlUtils.listId('https://m.youtube.com/watch?v=abc&list=PL123'), 'PL123');
  });
}
```

- [ ] **Step 2: Lancer, vérifier l échec**

Run: `flutter test test/utils/url_utils_test.dart`
Expected: FAIL (UrlUtils inexistant).

- [ ] **Step 3: Implémenter**

```dart
class UrlUtils {
  static String? videoId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    if (uri.host.contains('youtu.be')) {
      final seg = uri.pathSegments;
      return seg.isNotEmpty && seg.first.isNotEmpty ? seg.first : null;
    }
    final v = uri.queryParameters['v'];
    return (v != null && v.isNotEmpty) ? v : null;
  }

  static bool isPlaylist(String url) => listId(url) != null;

  static String? listId(String url) {
    final id = Uri.tryParse(url)?.queryParameters['list'];
    return (id != null && id.isNotEmpty) ? id : null;
  }
}
```

- [ ] **Step 4: Lancer, vérifier le succès**

Run: `flutter test test/utils/url_utils_test.dart`
Expected: PASS (6 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/utils/url_utils.dart test/utils/url_utils_test.dart
git commit -m "feat: url utils (videoId, playlist detection)"
```

---

## Task 3: Modèles (DownloadFormat, StreamOption, VideoInfo, DownloadTask)

**Files:**
- Create: `lib/models/download_format.dart`, `lib/models/stream_option.dart`, `lib/models/video_info.dart`, `lib/models/download_task.dart`
- Test: `test/models/download_task_test.dart`

- [ ] **Step 1: Écrire les modèles simples (pas de logique → pas de test)**

`lib/models/download_format.dart`:
```dart
enum DownloadFormat { mp4, mp3 }
```

`lib/models/stream_option.dart`:
```dart
import 'download_format.dart';

class StreamOption {
  final DownloadFormat format;
  final String label;        // ex "720p", "Audio 128kbps"
  final String url;          // url du flux (expirable)
  final String container;    // mp4, m4a, webm
  final int? bitrate;

  const StreamOption({
    required this.format,
    required this.label,
    required this.url,
    required this.container,
    this.bitrate,
  });
}
```

`lib/models/video_info.dart`:
```dart
import 'stream_option.dart';

class VideoInfo {
  final String id;
  final String title;
  final String author;
  final String thumbnailUrl;
  final Duration duration;
  final List<StreamOption> options;

  const VideoInfo({
    required this.id,
    required this.title,
    required this.author,
    required this.thumbnailUrl,
    required this.duration,
    required this.options,
  });
}
```

- [ ] **Step 2: Écrire le test de DownloadTask (sérialisation sqflite)**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tubebox/models/download_task.dart';
import 'package:tubebox/models/download_format.dart';

void main() {
  test('toMap / fromMap round-trip', () {
    final t = DownloadTask(
      id: 'abc',
      title: 'Ma vidéo',
      format: DownloadFormat.mp3,
      status: DownloadStatus.downloading,
      localPath: null,
      progress: 0.5,
      error: null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(1000),
    );
    final back = DownloadTask.fromMap(t.toMap());
    expect(back.id, 'abc');
    expect(back.format, DownloadFormat.mp3);
    expect(back.status, DownloadStatus.downloading);
    expect(back.progress, 0.5);
    expect(back.createdAt, t.createdAt);
  });
}
```

- [ ] **Step 3: Lancer, vérifier l échec**

Run: `flutter test test/models/download_task_test.dart`
Expected: FAIL.

- [ ] **Step 4: Implémenter `lib/models/download_task.dart`**

```dart
import 'download_format.dart';

enum DownloadStatus { queued, downloading, converting, done, failed }

class DownloadTask {
  final String id;
  final String title;
  final DownloadFormat format;
  final DownloadStatus status;
  final String? localPath;
  final double progress;
  final String? error;
  final DateTime createdAt;

  const DownloadTask({
    required this.id,
    required this.title,
    required this.format,
    required this.status,
    required this.localPath,
    required this.progress,
    required this.error,
    required this.createdAt,
  });

  DownloadTask copyWith({
    DownloadStatus? status,
    String? localPath,
    double? progress,
    String? error,
  }) =>
      DownloadTask(
        id: id,
        title: title,
        format: format,
        status: status ?? this.status,
        localPath: localPath ?? this.localPath,
        progress: progress ?? this.progress,
        error: error ?? this.error,
        createdAt: createdAt,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'format': format.name,
        'status': status.name,
        'localPath': localPath,
        'progress': progress,
        'error': error,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory DownloadTask.fromMap(Map<String, Object?> m) => DownloadTask(
        id: m['id'] as String,
        title: m['title'] as String,
        format: DownloadFormat.values.byName(m['format'] as String),
        status: DownloadStatus.values.byName(m['status'] as String),
        localPath: m['localPath'] as String?,
        progress: (m['progress'] as num).toDouble(),
        error: m['error'] as String?,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(m['createdAt'] as int),
      );
}
```

- [ ] **Step 5: Lancer, vérifier le succès**

Run: `flutter test test/models/download_task_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/models test/models
git commit -m "feat: models (format, stream option, video info, download task)"
```

---

## Task 4: storage_service — normalisation du nom de fichier

**Files:**
- Create: `lib/services/storage_service.dart`
- Test: `test/services/storage_service_test.dart`

> Note: les chemins disque et le scan média nécessitent un device ; ici on teste uniquement la fonction pure `safeFileName`. Le reste (`musicDir`, `videoDir`, `scanMedia`) est ajouté sans test et vérifié manuellement en Task 11.

- [ ] **Step 1: Écrire le test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tubebox/services/storage_service.dart';

void main() {
  test('supprime les caractères interdits FAT32', () {
    expect(StorageService.safeFileName(r'a/b:c*d?e"f<g>h|i'), 'abcdefghi');
  });
  test('trim et collapse les espaces', () {
    expect(StorageService.safeFileName('  Ma   Vidéo  '), 'Ma Vidéo');
  });
  test('tronque à 120 caractères', () {
    final long = 'x' * 200;
    expect(StorageService.safeFileName(long).length, 120);
  });
  test('fallback si vide', () {
    expect(StorageService.safeFileName('///'), 'download');
  });
}
```

- [ ] **Step 2: Lancer, vérifier l échec**

Run: `flutter test test/services/storage_service_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implémenter (uniquement `safeFileName` pour l instant)**

```dart
class StorageService {
  static String safeFileName(String raw) {
    var s = raw.replaceAll(RegExp(r'[\\/:*?"<>|]'), '');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (s.length > 120) s = s.substring(0, 120);
    return s.isEmpty ? 'download' : s;
  }
}
```

- [ ] **Step 4: Lancer, vérifier le succès**

Run: `flutter test test/services/storage_service_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/services/storage_service.dart test/services/storage_service_test.dart
git commit -m "feat: storage service safeFileName"
```

---

## Task 5: download_repository (sqflite)

**Files:**
- Create: `lib/data/download_repository.dart`
- Test: `test/data/download_repository_test.dart`

> On teste avec `sqflite_common_ffi` (DB en mémoire) pour ne pas dépendre d un device.

- [ ] **Step 1: Ajouter la dép de test**

Run: `flutter pub add --dev sqflite_common_ffi`
Expected: OK.

- [ ] **Step 2: Écrire le test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tubebox/data/download_repository.dart';
import 'package:tubebox/models/download_task.dart';
import 'package:tubebox/models/download_format.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  DownloadTask sample(String id) => DownloadTask(
        id: id, title: 't$id', format: DownloadFormat.mp3,
        status: DownloadStatus.queued, localPath: null,
        progress: 0, error: null,
        createdAt: DateTime.fromMillisecondsSinceEpoch(int.parse(id)),
      );

  test('upsert puis getAll trié par createdAt desc', () async {
    final repo = DownloadRepository();
    await repo.open(inMemory: true);
    await repo.upsert(sample('1'));
    await repo.upsert(sample('2'));
    final all = await repo.getAll();
    expect(all.map((t) => t.id).toList(), ['2', '1']);
  });

  test('upsert met à jour le statut', () async {
    final repo = DownloadRepository();
    await repo.open(inMemory: true);
    await repo.upsert(sample('1'));
    await repo.upsert(sample('1').copyWith(status: DownloadStatus.done));
    final all = await repo.getAll();
    expect(all.single.status, DownloadStatus.done);
  });
}
```

- [ ] **Step 3: Lancer, vérifier l échec**

Run: `flutter test test/data/download_repository_test.dart`
Expected: FAIL.

- [ ] **Step 4: Implémenter**

```dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/download_task.dart';

class DownloadRepository {
  late Database _db;

  Future<void> open({bool inMemory = false}) async {
    final path = inMemory ? inMemoryDatabasePath : p.join(await getDatabasesPath(), 'downloads.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, _) => db.execute('''
        CREATE TABLE downloads(
          id TEXT PRIMARY KEY, title TEXT, format TEXT, status TEXT,
          localPath TEXT, progress REAL, error TEXT, createdAt INTEGER
        )'''),
    );
  }

  Future<void> upsert(DownloadTask t) => _db.insert(
        'downloads', t.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  Future<List<DownloadTask>> getAll() async {
    final rows = await _db.query('downloads', orderBy: 'createdAt DESC');
    return rows.map(DownloadTask.fromMap).toList();
  }

  Future<void> delete(String id) =>
      _db.delete('downloads', where: 'id = ?', whereArgs: [id]);
}
```

- [ ] **Step 5: Lancer, vérifier le succès**

Run: `flutter test test/data/download_repository_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 6: Commit**

```bash
git add lib/data/download_repository.dart test/data/download_repository_test.dart pubspec.yaml
git commit -m "feat: download repository (sqflite)"
```

---

## Task 6: VideoExtractor interface + YoutubeExplodeExtractor

**Files:**
- Create: `lib/extractor/video_extractor.dart`, `lib/extractor/youtube_explode_extractor.dart`
- Test: `test/extractor/youtube_explode_extractor_test.dart` (test d intégration réseau, marqué `@Tags(['network'])`)

- [ ] **Step 1: Écrire l interface**

```dart
import '../models/video_info.dart';

class PlaylistMeta {
  final String title;
  final int count;
  const PlaylistMeta(this.title, this.count);
}

abstract class VideoExtractor {
  Future<VideoInfo> extractVideo(String url);
  Future<PlaylistMeta> playlistMeta(String url);
  Stream<VideoInfo> extractPlaylist(String url);
}
```

- [ ] **Step 2: Écrire le test d intégration (réseau, optionnel en CI)**

```dart
@Tags(['network'])
import 'package:flutter_test/flutter_test.dart';
import 'package:tubebox/extractor/youtube_explode_extractor.dart';

void main() {
  test('extrait infos + options d une vidéo connue', () async {
    final ex = YoutubeExplodeExtractor();
    final info = await ex.extractVideo('https://www.youtube.com/watch?v=dQw4w9WgXcQ');
    expect(info.title, isNotEmpty);
    expect(info.options.where((o) => o.label.startsWith('Audio')), isNotEmpty);
    expect(info.options.where((o) => o.container == 'mp4'), isNotEmpty);
    ex.dispose();
  });
}
```

- [ ] **Step 3: Lancer, vérifier l échec**

Run: `flutter test test/extractor/youtube_explode_extractor_test.dart`
Expected: FAIL (classe inexistante).

- [ ] **Step 4: Implémenter**

```dart
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/video_info.dart';
import '../models/stream_option.dart';
import '../models/download_format.dart';
import 'video_extractor.dart';

class YoutubeExplodeExtractor implements VideoExtractor {
  final YoutubeExplode _yt = YoutubeExplode();

  @override
  Future<VideoInfo> extractVideo(String url) async {
    final video = await _yt.videos.get(url);
    final manifest = await _yt.videos.streamsClient.getManifest(video.id);

    final options = <StreamOption>[];
    for (final s in manifest.muxed) {
      options.add(StreamOption(
        format: DownloadFormat.mp4,
        label: s.videoQualityLabel,
        url: s.url.toString(),
        container: s.container.name,
      ));
    }
    final audio = manifest.audioOnly.withHighestBitrate();
    options.add(StreamOption(
      format: DownloadFormat.mp3,
      label: 'Audio ${audio.bitrate.kiloBitsPerSecond.round()}kbps',
      url: audio.url.toString(),
      container: audio.container.name,
      bitrate: audio.bitrate.kiloBitsPerSecond.round(),
    ));

    return VideoInfo(
      id: video.id.value,
      title: video.title,
      author: video.author,
      thumbnailUrl: video.thumbnails.highResUrl,
      duration: video.duration ?? Duration.zero,
      options: options,
    );
  }

  @override
  Future<PlaylistMeta> playlistMeta(String url) async {
    final pl = await _yt.playlists.get(url);
    return PlaylistMeta(pl.title, pl.videoCount ?? 0);
  }

  @override
  Stream<VideoInfo> extractPlaylist(String url) async* {
    await for (final v in _yt.playlists.getVideos(url)) {
      yield await extractVideo(v.url);
    }
  }

  void dispose() => _yt.close();
}
```

- [ ] **Step 5: Lancer, vérifier le succès (réseau requis)**

Run: `flutter test test/extractor/youtube_explode_extractor_test.dart`
Expected: PASS si réseau dispo. (Si offline : skip — c est un test réseau.)

- [ ] **Step 6: Commit**

```bash
git add lib/extractor test/extractor
git commit -m "feat: video extractor interface + youtube_explode impl"
```

---

## Task 7: conversion_service (FFmpeg audio → mp3 + tags)

**Files:**
- Create: `lib/services/conversion_service.dart`

> FFmpeg nécessite un device/émulateur → pas de test unitaire ; vérif manuelle en Task 13. La commande est figée ici.

- [ ] **Step 1: Implémenter**

```dart
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

class ConversionService {
  /// Transcode [inputPath] (m4a/webm) vers [outputPath] (.mp3),
  /// injecte titre/artiste et la pochette [thumbnailPath].
  Future<bool> toMp3({
    required String inputPath,
    required String outputPath,
    required String title,
    required String artist,
    String? thumbnailPath,
  }) async {
    final cover = thumbnailPath != null ? '-i "$thumbnailPath"' : '';
    final mapCover = thumbnailPath != null
        ? '-map 0:a -map 1:0 -id3v2_version 3 -metadata:s:v title="Album cover" -metadata:s:v comment="Cover (front)"'
        : '-map 0:a';
    final cmd =
        '-y -i "$inputPath" $cover -vn $mapCover '
        '-c:a libmp3lame -q:a 2 '
        '-metadata title="$title" -metadata artist="$artist" '
        '"$outputPath"';
    final session = await FFmpegKit.execute(cmd);
    final rc = await session.getReturnCode();
    return ReturnCode.isSuccess(rc);
  }
}
```

- [ ] **Step 2: Vérifier la compilation**

Run: `flutter analyze lib/services/conversion_service.dart`
Expected: No issues.

- [ ] **Step 3: Commit**

```bash
git add lib/services/conversion_service.dart
git commit -m "feat: conversion service (ffmpeg audio -> mp3 + tags)"
```

---

## Task 8: storage_service — chemins disque + scan média

**Files:**
- Modify: `lib/services/storage_service.dart`

- [ ] **Step 1: Ajouter les chemins (au-dessus de safeFileName, dans la même classe)**

```dart
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// dans class StorageService :
  static Future<String> _baseDir(String sub) async {
    var dir = Directory('/storage/emulated/0/$sub');
    if (!await Directory('/storage/emulated/0').exists()) {
      dir = Directory(p.join((await getExternalStorageDirectory())!.path, sub));
    }
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  static Future<String> musicPath(String fileName) async =>
      p.join(await _baseDir('Music/Tubebox'), fileName);

  static Future<String> videoPath(String fileName) async =>
      p.join(await _baseDir('Movies/Tubebox'), fileName);

  static Future<String> tempPath(String fileName) async =>
      p.join((await getTemporaryDirectory()).path, fileName);
```

- [ ] **Step 2: Vérifier que les tests existants passent encore**

Run: `flutter test test/services/storage_service_test.dart`
Expected: PASS (safeFileName intact).

- [ ] **Step 3: Commit**

```bash
git add lib/services/storage_service.dart
git commit -m "feat: storage service disk paths (Music/Movies/temp)"
```

---

## Task 9: download_service (téléchargement + file séquentielle + skip erreur)

**Files:**
- Create: `lib/services/download_service.dart`

> Orchestration s appuyant sur `dio`, `StorageService`, `ConversionService`, `DownloadRepository`. Vérif manuelle end-to-end en Task 13.

- [ ] **Step 1: Implémenter**

```dart
import 'package:dio/dio.dart';
import '../data/download_repository.dart';
import '../models/download_task.dart';
import '../models/download_format.dart';
import '../models/video_info.dart';
import '../models/stream_option.dart';
import 'storage_service.dart';
import 'conversion_service.dart';

class DownloadService {
  final Dio _dio;
  final DownloadRepository _repo;
  final ConversionService _conversion;

  DownloadService(this._repo, {Dio? dio, ConversionService? conversion})
      : _dio = dio ?? Dio(),
        _conversion = conversion ?? ConversionService();

  /// Télécharge une vidéo. Met à jour le repo au fil de l eau.
  /// Retourne true si succès, false si échec (sans throw, pour la file).
  Future<bool> downloadOne(VideoInfo info, StreamOption option) async {
    final base = StorageService.safeFileName(info.title);
    var task = DownloadTask(
      id: info.id, title: info.title, format: option.format,
      status: DownloadStatus.downloading, localPath: null,
      progress: 0, error: null, createdAt: DateTime.now(),
    );
    await _repo.upsert(task);
    try {
      if (option.format == DownloadFormat.mp4) {
        final out = await StorageService.videoPath('$base.mp4');
        await _dio.download(option.url, out,
            onReceiveProgress: (r, t) => _progress(task, r, t));
        task = task.copyWith(status: DownloadStatus.done, localPath: out, progress: 1);
      } else {
        final tmp = await StorageService.tempPath('$base.${option.container}');
        await _dio.download(option.url, tmp,
            onReceiveProgress: (r, t) => _progress(task, r, t));
        await _repo.upsert(task.copyWith(status: DownloadStatus.converting, progress: 1));
        final out = await StorageService.musicPath('$base.mp3');
        final ok = await _conversion.toMp3(
          inputPath: tmp, outputPath: out,
          title: info.title, artist: info.author,
        );
        if (!ok) throw Exception('FFmpeg failed');
        task = task.copyWith(status: DownloadStatus.done, localPath: out, progress: 1);
      }
      await _repo.upsert(task);
      return true;
    } catch (e) {
      await _repo.upsert(task.copyWith(status: DownloadStatus.failed, error: e.toString()));
      return false;
    }
  }

  void _progress(DownloadTask task, int received, int total) {
    if (total <= 0) return;
    _repo.upsert(task.copyWith(progress: received / total));
  }

  /// File séquentielle: skip + log sur échec. Retourne (ok, total).
  Future<(int, int)> downloadPlaylist(
      Stream<VideoInfo> videos, DownloadFormat format) async {
    int ok = 0, total = 0;
    await for (final info in videos) {
      total++;
      final opt = _pickOption(info, format);
      if (opt == null) continue;
      if (await downloadOne(info, opt)) ok++;
    }
    return (ok, total);
  }

  StreamOption? _pickOption(VideoInfo info, DownloadFormat format) {
    final matches = info.options.where((o) => o.format == format);
    return matches.isEmpty ? null : matches.first;
  }
}
```

- [ ] **Step 2: Vérifier la compilation**

Run: `flutter analyze lib/services/download_service.dart`
Expected: No issues.

- [ ] **Step 3: Commit**

```bash
git add lib/services/download_service.dart
git commit -m "feat: download service (single + playlist queue, skip on error)"
```

---

## Task 10: settings_service (moteur + dernier format)

**Files:**
- Create: `lib/settings/settings_service.dart`

- [ ] **Step 1: Implémenter**

```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class SettingsService {
  static const _kEngine = 'extractor_engine'; // 'youtube_explode' | 'yt_dlp'
  static const _kLastFormatLabel = 'last_format_label';
  static const _kThemeMode = 'theme_mode'; // 'light' | 'dark' | 'system'
  static const _kAccent = 'accent';
  static const _kOnboarded = 'onboarded';

  Future<String> engine() async =>
      (await SharedPreferences.getInstance()).getString(_kEngine) ?? 'youtube_explode';
  Future<void> setEngine(String v) async =>
      (await SharedPreferences.getInstance()).setString(_kEngine, v);

  // Label du dernier format choisi (ex "MP3 128kbps") -> badge "Dernier utilisé".
  Future<String?> lastFormatLabel() async =>
      (await SharedPreferences.getInstance()).getString(_kLastFormatLabel);
  Future<void> setLastFormatLabel(String label) async =>
      (await SharedPreferences.getInstance()).setString(_kLastFormatLabel, label);

  Future<ThemeMode> themeMode() async {
    final v = (await SharedPreferences.getInstance()).getString(_kThemeMode);
    return switch (v) { 'light' => ThemeMode.light, 'dark' => ThemeMode.dark, _ => ThemeMode.system };
  }
  Future<void> setThemeMode(ThemeMode m) async =>
      (await SharedPreferences.getInstance()).setString(_kThemeMode, m.name);

  Future<Color> accent() async {
    final v = (await SharedPreferences.getInstance()).getInt(_kAccent);
    return v == null ? kAccentDefault : Color(v);
  }
  Future<void> setAccent(Color c) async =>
      (await SharedPreferences.getInstance()).setInt(_kAccent, c.value);

  Future<bool> onboarded() async =>
      (await SharedPreferences.getInstance()).getBool(_kOnboarded) ?? false;
  Future<void> setOnboarded() async =>
      (await SharedPreferences.getInstance()).setBool(_kOnboarded, true);
}
```

- [ ] **Step 2: Vérifier la compilation**

Run: `flutter analyze lib/settings/settings_service.dart`
Expected: No issues.

- [ ] **Step 3: Commit**

```bash
git add lib/settings/settings_service.dart
git commit -m "feat: settings service (engine + last format)"
```

---

## Task 11: Format bottom sheet + playlist dialog (design Tubebox)

**Files:**
- Create: `lib/ui/widgets/format_sheet.dart`, `lib/ui/widgets/playlist_choice_dialog.dart`
- Test: `test/ui/format_sheet_test.dart` (widget test)

> Référence visuelle : `.design/youtube/project/screens-main.jsx` (`FormatSheet`, `PlaylistDialog`). Le sheet est peuplé par les `StreamOption` réels de la vidéo (pas une liste figée) ; le badge « Dernier utilisé » s'affiche sur l'option dont le `label` == dernier label mémorisé.

- [ ] **Step 1: Écrire le widget test du sheet**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tubebox/ui/widgets/format_sheet.dart';
import 'package:tubebox/models/stream_option.dart';
import 'package:tubebox/models/download_format.dart';
import 'package:tubebox/theme/app_theme.dart';

void main() {
  testWidgets('retourne l option choisie', (tester) async {
    final opts = [
      const StreamOption(format: DownloadFormat.mp4, label: 'MP4 720p', url: 'u1', container: 'mp4'),
      const StreamOption(format: DownloadFormat.mp3, label: 'Audio 128kbps', url: 'u2', container: 'm4a'),
    ];
    StreamOption? picked;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(kAccentDefault),
      home: Builder(builder: (ctx) => ElevatedButton(
        onPressed: () async => picked = await showFormatSheet(ctx, opts, null),
        child: const Text('open'),
      )),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Audio 128kbps'));
    await tester.pumpAndSettle();
    expect(picked?.label, 'Audio 128kbps');
  });
}
```

- [ ] **Step 2: Lancer, vérifier l échec**

Run: `flutter test test/ui/format_sheet_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implémenter `format_sheet.dart`**

```dart
import 'package:flutter/material.dart';
import '../../models/stream_option.dart';
import '../../models/download_format.dart';
import '../../theme/app_theme.dart';

Future<StreamOption?> showFormatSheet(
    BuildContext context, List<StreamOption> options, String? lastLabel) {
  return showModalBottomSheet<StreamOption>(
    context: context,
    backgroundColor: context.c.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      final c = ctx.c;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
              child: Text('Choisir le format',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: c.text)),
            ),
            ...options.map((o) {
              final isLast = o.label == lastLabel;
              final isVideo = o.format == DownloadFormat.mp4;
              return InkWell(
                onTap: () => Navigator.pop(ctx, o),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: isLast ? c.accent.withOpacity(0.08) : Colors.transparent,
                  ),
                  child: Row(children: [
                    Container(
                      width: 40, height: 40, alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: c.surface2, borderRadius: BorderRadius.circular(12)),
                      child: Icon(isVideo ? Icons.movie_outlined : Icons.music_note_outlined,
                          size: 20, color: isVideo ? c.text : c.accent),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text(o.label,
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.text)),
                            if (isLast) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                    color: c.accent, borderRadius: BorderRadius.circular(999)),
                                child: const Text('Dernier utilisé',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
                              ),
                            ],
                          ]),
                          const SizedBox(height: 2),
                          Text(o.container.toUpperCase(),
                              style: TextStyle(fontSize: 12, color: c.muted)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 18, color: c.faint),
                  ]),
                ),
              );
            }),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
              child: Text('Demander à chaque fois',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: c.muted)),
            ),
          ],
        ),
      );
    },
  );
}
```

- [ ] **Step 4: Lancer, vérifier le succès**

Run: `flutter test test/ui/format_sheet_test.dart`
Expected: PASS.

- [ ] **Step 5: Implémenter `playlist_choice_dialog.dart`**

```dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

enum PlaylistChoice { single, all }

Future<PlaylistChoice?> showPlaylistChoiceDialog(
  BuildContext context, {
  required String playlistTitle,
  required int count,
  required String videoTitle,
}) {
  PlaylistChoice choice = PlaylistChoice.single;
  return showDialog<PlaylistChoice>(
    context: context,
    builder: (ctx) {
      final c = ctx.c;
      return StatefulBuilder(builder: (ctx, setState) {
        Widget radio(PlaylistChoice value, String title, String sub) {
          final on = choice == value;
          return InkWell(
            onTap: () => setState(() => choice = value),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: on ? c.accent.withOpacity(0.08) : Colors.transparent,
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 20, height: 20, margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: on ? c.accent : c.border2, width: on ? 5 : 1.5),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.text)),
                    const SizedBox(height: 2),
                    Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: c.muted)),
                  ]),
                ),
              ]),
            ),
          );
        }

        return Dialog(
          backgroundColor: c.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Cette vidéo fait partie d'une playlist",
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: c.text, height: 1.25)),
              const SizedBox(height: 6),
              Text('Que voulez-vous télécharger ?', style: TextStyle(fontSize: 13, color: c.muted)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Icon(Icons.playlist_play, size: 16, color: c.muted),
                  const SizedBox(width: 10),
                  Expanded(child: Text(playlistTitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: c.text2))),
                  Text('$count', style: TextStyle(fontSize: 11, color: c.muted)),
                ]),
              ),
              const SizedBox(height: 12),
              radio(PlaylistChoice.single, 'Cette vidéo seulement', videoTitle),
              radio(PlaylistChoice.all, 'Toute la playlist ($count vidéos)', '~ ${count * 14} min de contenu'),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(onPressed: () => Navigator.pop(ctx),
                    child: Text('Annuler', style: TextStyle(color: c.text2))),
                const SizedBox(width: 4),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: c.accent),
                  onPressed: () => Navigator.pop(ctx, choice),
                  child: const Text('Continuer'),
                ),
              ]),
            ]),
          ),
        );
      });
    },
  );
}
```

- [ ] **Step 6: Commit**

```bash
git add lib/ui/widgets test/ui
git commit -m "feat: format bottom sheet + playlist dialog (tubebox design)"
```

---

## Task 11.1: settings_screen (moteur + apparence + stockage + à propos)

**Files:**
- Create: `lib/ui/settings_screen.dart`

> Référence : `.design/youtube/project/screens-other.jsx` (`SettingsScreen`). Le thème et l'accent s'appliquent au prochain lancement (v1).

- [ ] **Step 1: Implémenter**

```dart
import 'package:flutter/material.dart';
import '../settings/settings_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settings = SettingsService();
  ThemeMode _mode = ThemeMode.system;
  Color _accent = kAccentDefault;

  @override
  void initState() {
    super.initState();
    _settings.themeMode().then((m) => setState(() => _mode = m));
    _settings.accent().then((a) => setState(() => _accent = a));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg, surfaceTintColor: Colors.transparent, elevation: 0,
        title: const Text('Paramètres', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: ListView(children: [
        _section(c, "Moteur d'extraction"),
        _engineCard(c, 'youtube_explode_dart', 'Pur Dart. Rapide, léger. Par défaut.', 'v1', active: true),
        _engineCard(c, 'yt-dlp (bridge natif)', 'Plus robuste, plus lourd. Bientôt.', 'Bientôt', active: false, disabled: true),
        _section(c, 'Apparence'),
        _row(c, 'Thème', child: _themeSelector()),
        _row(c, "Couleur d'accent", child: _accentSwatches(c)),
        _section(c, 'Par défaut'),
        _staticRow(c, 'Format par défaut', 'Demander à chaque fois'),
        _staticRow(c, 'Qualité audio', '320 kbps'),
        _staticRow(c, 'Qualité vidéo max', '1080p'),
        _section(c, 'Stockage'),
        _staticRow(c, 'Dossier musique', 'Music/Tubebox', icon: Icons.folder_outlined),
        _staticRow(c, 'Dossier vidéos', 'Movies/Tubebox', icon: Icons.folder_outlined),
        _section(c, 'À propos'),
        _staticRow(c, 'Version', '1.0.0'),
        _staticRow(c, 'Build', '2026.05.20 · APK'),
        const SizedBox(height: 32),
      ]),
    );
  }

  Widget _section(TubeboxColors c, String label) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Text(label.toUpperCase(),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: c.muted)),
      );

  Widget _engineCard(TubeboxColors c, String title, String sub, String tag,
      {required bool active, bool disabled = false}) {
    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: active ? c.accent.withOpacity(0.07) : c.surface2,
          border: Border.all(color: active ? c.accent.withOpacity(0.35) : c.border, width: 0.5),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 20, height: 20, margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: active ? c.accent : c.border2, width: active ? 5 : 1.5)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(title,
                    style: context.mono.copyWith(fontSize: 13, fontWeight: FontWeight.w600, color: c.text))),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: active ? c.accent : c.border, borderRadius: BorderRadius.circular(999)),
                  child: Text(tag,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                          color: active ? Colors.white : c.muted)),
                ),
              ]),
              const SizedBox(height: 4),
              Text(sub, style: TextStyle(fontSize: 12, color: c.muted, height: 1.4)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _row(TubeboxColors c, String title, {required Widget child}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border, width: 0.5))),
        child: Row(children: [
          Expanded(child: Text(title, style: TextStyle(fontSize: 14, color: c.text))),
          child,
        ]),
      );

  Widget _staticRow(TubeboxColors c, String title, String value, {IconData? icon}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border, width: 0.5))),
        child: Row(children: [
          if (icon != null) ...[Icon(icon, size: 18, color: c.muted), const SizedBox(width: 12)],
          Expanded(child: Text(title, style: TextStyle(fontSize: 14, color: c.text))),
          Text(value, style: TextStyle(fontSize: 13, color: c.muted)),
          Icon(Icons.chevron_right, size: 16, color: c.faint),
        ]),
      );

  Widget _themeSelector() => SegmentedButton<ThemeMode>(
        segments: const [
          ButtonSegment(value: ThemeMode.system, label: Text('Auto')),
          ButtonSegment(value: ThemeMode.light, label: Text('Clair')),
          ButtonSegment(value: ThemeMode.dark, label: Text('Sombre')),
        ],
        selected: {_mode},
        showSelectedIcon: false,
        onSelectionChanged: (s) {
          setState(() => _mode = s.first);
          _settings.setThemeMode(s.first);
        },
      );

  Widget _accentSwatches(TubeboxColors c) => Row(
        mainAxisSize: MainAxisSize.min,
        children: kAccentOptions.map((color) {
          final on = color.value == _accent.value;
          return GestureDetector(
            onTap: () {
              setState(() => _accent = color);
              _settings.setAccent(color);
            },
            child: Container(
              width: 24, height: 24, margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                  color: color, shape: BoxShape.circle,
                  border: Border.all(color: on ? c.text : Colors.transparent, width: 2)),
            ),
          );
        }).toList(),
      );
}
```

- [ ] **Step 2: Vérifier la compilation**

Run: `flutter analyze lib/ui/settings_screen.dart`
Expected: No issues.

- [ ] **Step 3: Commit**

```bash
git add lib/ui/settings_screen.dart
git commit -m "feat: settings screen (engine, theme, accent, storage, about)"
```

---

## Task 11.2: onboarding_screen (permissions 1er lancement)

**Files:**
- Create: `lib/ui/onboarding_screen.dart`

> Référence : `.design/youtube/project/screens-other.jsx` (`OnboardingScreen`). Demande les permissions puis marque `onboarded` et ouvre la WebView.

- [ ] **Step 1: Implémenter**

```dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../data/download_repository.dart';
import '../settings/settings_service.dart';
import '../theme/app_theme.dart';
import 'webview_screen.dart';

class OnboardingScreen extends StatelessWidget {
  final DownloadRepository repo;
  const OnboardingScreen({super.key, required this.repo});

  Future<void> _start(BuildContext context) async {
    await [
      Permission.storage, Permission.audio, Permission.videos, Permission.notification,
    ].request();
    await SettingsService().setOnboarded();
    if (!context.mounted) return;
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => WebViewScreen(repo: repo)));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final perms = <(IconData, String, String)>[
      (Icons.folder_outlined, 'Stockage', 'Pour ranger les fichiers dans Musique / Vidéos.'),
      (Icons.notifications_outlined, 'Notifications', 'Pour vous prévenir quand un téléchargement est prêt.'),
      (Icons.bolt_outlined, "Tâche d'arrière-plan", 'Pour finir les téléchargements écran éteint.'),
    ];
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Tubebox', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.text)),
              Text('1 / 1', style: TextStyle(fontSize: 11, color: c.muted)),
            ]),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.download, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 28),
                  Text('Téléchargez vos vidéos préférées.',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: c.text, height: 1.15)),
                  const SizedBox(height: 12),
                  Text("Naviguez sur YouTube comme d'habitude. Une fois sur une vidéo, touchez « Télécharger ».",
                      style: TextStyle(fontSize: 14, color: c.muted, height: 1.45)),
                  const SizedBox(height: 28),
                  ...perms.map((p) => Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border, width: 0.5))),
                        child: Row(children: [
                          Container(
                            width: 36, height: 36, alignment: Alignment.center,
                            decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(10)),
                            child: Icon(p.$1, size: 18, color: c.text2),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(p.$2, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.text)),
                              const SizedBox(height: 1),
                              Text(p.$3, style: TextStyle(fontSize: 12, color: c.muted)),
                            ]),
                          ),
                        ]),
                      )),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity, height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: c.accent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999))),
                onPressed: () => _start(context),
                child: const Text('Commencer', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Vérifier la compilation**

Run: `flutter analyze lib/ui/onboarding_screen.dart`
Expected: No issues.

- [ ] **Step 3: Commit**

```bash
git add lib/ui/onboarding_screen.dart
git commit -m "feat: onboarding screen (permissions, brand mark)"
```

---

## Task 12: webview_screen (WebView + FAB + suivi URL + détection playlist)

**Files:**
- Create: `lib/ui/webview_screen.dart`

> Intègre WebView, suivi d URL, et branche les dialogs + DownloadService. Vérif manuelle en Task 13.

- [ ] **Step 1: Implémenter**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../extractor/video_extractor.dart';
import '../extractor/youtube_explode_extractor.dart';
import '../services/download_service.dart';
import '../data/download_repository.dart';
import '../settings/settings_service.dart';
import '../models/video_info.dart';
import '../theme/app_theme.dart';
import '../utils/url_utils.dart';
import 'widgets/format_sheet.dart';
import 'widgets/playlist_choice_dialog.dart';
import 'downloads_screen.dart';
import 'settings_screen.dart';

class WebViewScreen extends StatefulWidget {
  final DownloadRepository repo;
  const WebViewScreen({super.key, required this.repo});
  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  String _currentUrl = 'https://m.youtube.com';
  final _settings = SettingsService();
  late final _extractor = YoutubeExplodeExtractor();
  late final _downloader = DownloadService(widget.repo);

  bool get _onVideo => UrlUtils.videoId(_currentUrl) != null;

  Future<void> _onDownloadPressed() async {
    final url = _currentUrl;

    // 1. infos de la vidéo courante (titre + options réelles)
    VideoInfo info;
    try {
      info = await _extractor.extractVideo(url);
    } catch (_) {
      _toast('Impossible de lire cette vidéo');
      return;
    }

    // 2. si playlist -> dialog cette vidéo / toute la playlist
    bool wholePlaylist = false;
    if (UrlUtils.isPlaylist(url)) {
      PlaylistMeta meta;
      try {
        meta = await _extractor.playlistMeta(url);
      } catch (_) {
        meta = const PlaylistMeta('Playlist', 0);
      }
      if (!mounted) return;
      final choice = await showPlaylistChoiceDialog(context,
          playlistTitle: meta.title, count: meta.count, videoTitle: info.title);
      if (choice == null) return;
      wholePlaylist = choice == PlaylistChoice.all;
    }

    // 3. choix du format (bottom sheet, peuplé par les options réelles)
    if (!mounted) return;
    final opt = await showFormatSheet(context, info.options, await _settings.lastFormatLabel());
    if (opt == null) return;
    await _settings.setLastFormatLabel(opt.label);

    _toast('Téléchargement lancé…');

    if (wholePlaylist) {
      final (ok, total) =
          await _downloader.downloadPlaylist(_extractor.extractPlaylist(url), opt.format);
      _toast('$ok/$total téléchargés');
    } else {
      final success = await _downloader.downloadOne(info, opt);
      _toast(success ? 'Terminé : ${info.title}' : 'Échec du téléchargement');
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Tubebox', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_done_outlined),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => DownloadsScreen(repo: widget.repo))),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(_currentUrl)),
        onUpdateVisitedHistory: (controller, url, _) {
          if (url != null) setState(() => _currentUrl = url.toString());
        },
      ),
      floatingActionButton: _onVideo
          ? FloatingActionButton.extended(
              onPressed: _onDownloadPressed,
              backgroundColor: c.accent,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.download),
              label: const Text('Télécharger', style: TextStyle(fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }

  @override
  void dispose() {
    _extractor.dispose();
    super.dispose();
  }
}
```

- [ ] **Step 2: Vérifier la compilation**

Run: `flutter analyze lib/ui/webview_screen.dart`
Expected: No issues.

- [ ] **Step 3: Commit**

```bash
git add lib/ui/webview_screen.dart
git commit -m "feat: webview screen + download FAB + playlist detection"
```

---

## Task 13: downloads_screen + app.dart + main.dart + permissions

**Files:**
- Create: `lib/ui/downloads_screen.dart`, `lib/app.dart`
- Modify: `lib/main.dart`, `android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1: Implémenter `downloads_screen.dart`** (3 onglets, design Tubebox)

> Référence : `.design/youtube/project/screens-other.jsx` (`DownloadsScreen`, `ActiveRow`, `DoneRow`, `ErrorRow`). On regroupe les `DownloadTask` par statut.

```dart
import 'package:flutter/material.dart';
import '../data/download_repository.dart';
import '../models/download_task.dart';
import '../models/download_format.dart';
import '../theme/app_theme.dart';

class DownloadsScreen extends StatefulWidget {
  final DownloadRepository repo;
  const DownloadsScreen({super.key, required this.repo});
  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  late Future<List<DownloadTask>> _future = widget.repo.getAll();
  void _refresh() => setState(() => _future = widget.repo.getAll());

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: c.bg,
        appBar: AppBar(
          backgroundColor: c.bg,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: const Text('Mes téléchargements', style: TextStyle(fontWeight: FontWeight.w600)),
          actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh)],
          bottom: TabBar(
            indicatorColor: c.accent,
            labelColor: c.text,
            unselectedLabelColor: c.muted,
            tabs: const [Tab(text: 'En cours'), Tab(text: 'Terminés'), Tab(text: 'Erreurs')],
          ),
        ),
        body: FutureBuilder<List<DownloadTask>>(
          future: _future,
          builder: (ctx, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final all = snap.data!;
            bool isActive(DownloadTask t) =>
                t.status == DownloadStatus.queued ||
                t.status == DownloadStatus.downloading ||
                t.status == DownloadStatus.converting;
            return TabBarView(children: [
              _list(all.where(isActive).toList(), _activeRow),
              _list(all.where((t) => t.status == DownloadStatus.done).toList(), _doneRow),
              _list(all.where((t) => t.status == DownloadStatus.failed).toList(), _errorRow),
            ]);
          },
        ),
      ),
    );
  }

  Widget _list(List<DownloadTask> tasks, Widget Function(BuildContext, DownloadTask) row) {
    if (tasks.isEmpty) {
      return Center(child: Text('Rien ici', style: TextStyle(color: context.c.muted)));
    }
    return ListView.separated(
      itemCount: tasks.length,
      separatorBuilder: (_, __) => Divider(height: 0.5, color: context.c.border),
      itemBuilder: (ctx, i) => row(ctx, tasks[i]),
    );
  }

  Widget _thumb(BuildContext ctx, DownloadTask t) {
    final c = ctx.c;
    return Container(
      width: 56, height: 35, alignment: Alignment.center,
      decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(8)),
      child: Icon(t.format == DownloadFormat.mp3 ? Icons.music_note : Icons.movie,
          size: 16, color: c.muted),
    );
  }

  Widget _activeRow(BuildContext ctx, DownloadTask t) {
    final c = ctx.c;
    final converting = t.status == DownloadStatus.converting;
    final queued = t.status == DownloadStatus.queued;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _thumb(ctx, t),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.text, height: 1.3)),
            const SizedBox(height: 3),
            Text(t.format.name.toUpperCase(), style: TextStyle(fontSize: 11, color: c.muted)),
          ])),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 3,
            value: (converting || queued) ? null : t.progress,
            backgroundColor: c.border,
            valueColor: AlwaysStoppedAnimation(c.accent),
          ),
        ),
        const SizedBox(height: 6),
        Text(queued ? 'En file' : converting ? 'Conversion MP3…' : '${(t.progress * 100).round()}%',
            style: TextStyle(fontSize: 11, color: c.muted)),
      ]),
    );
  }

  Widget _doneRow(BuildContext ctx, DownloadTask t) {
    final c = ctx.c;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(children: [
        _thumb(ctx, t),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.text)),
          const SizedBox(height: 2),
          Text('${t.format.name.toUpperCase()} · ${t.localPath?.split('/').last ?? ''}',
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: c.muted)),
        ])),
        Icon(Icons.check_circle, size: 18, color: c.accent),
      ]),
    );
  }

  Widget _errorRow(BuildContext ctx, DownloadTask t) {
    final c = ctx.c;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 52, height: 32, alignment: Alignment.center,
          decoration: BoxDecoration(
              color: c.error.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
          child: Icon(Icons.error_outline, size: 18, color: c.error),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.text)),
          const SizedBox(height: 2),
          Text(t.error ?? 'Échec', maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: c.error)),
        ])),
        Icon(Icons.refresh, size: 16, color: c.text2),
      ]),
    );
  }
}
```

- [ ] **Step 2: Implémenter `app.dart`**

```dart
import 'package:flutter/material.dart';
import 'data/download_repository.dart';
import 'theme/app_theme.dart';
import 'ui/webview_screen.dart';
import 'ui/onboarding_screen.dart';

class App extends StatelessWidget {
  final DownloadRepository repo;
  final ThemeMode themeMode;
  final Color accent;
  final bool onboarded;
  const App({
    super.key,
    required this.repo,
    required this.themeMode,
    required this.accent,
    required this.onboarded,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tubebox',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(accent),
      darkTheme: AppTheme.dark(accent),
      themeMode: themeMode,
      home: onboarded ? WebViewScreen(repo: repo) : OnboardingScreen(repo: repo),
    );
  }
}
```

- [ ] **Step 3: Réécrire `main.dart`**

```dart
import 'package:flutter/material.dart';
import 'data/download_repository.dart';
import 'settings/settings_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repo = DownloadRepository();
  await repo.open();
  final settings = SettingsService();
  final themeMode = await settings.themeMode();
  final accent = await settings.accent();
  final onboarded = await settings.onboarded();
  runApp(App(repo: repo, themeMode: themeMode, accent: accent, onboarded: onboarded));
}
```

- [ ] **Step 4: Ajouter les permissions dans `AndroidManifest.xml`** (avant `<application>`)

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO"/>
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
    android:maxSdkVersion="28"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_DATA_SYNC"/>
```

- [ ] **Step 5: Build + vérif analyze**

Run: `flutter analyze && flutter build apk --debug`
Expected: No issues + BUILD SUCCESSFUL.

- [ ] **Step 6: Vérification manuelle sur device/émulateur**

Run: `flutter run`
Vérifier :
1. 1er lancement → écran Onboarding Tubebox, « Commencer » demande les permissions puis ouvre la WebView.
2. La WebView ouvre YouTube mobile, navigation OK ; FAB orange « Télécharger » visible sur une vidéo.
3. Clic → bottom sheet format (options réelles, badge « Dernier utilisé ») → choisir MP3 → snackbar « lancé » puis « Terminé ».
4. Le `.mp3` est dans `Music/Tubebox/`, lisible par un lecteur, avec titre/pochette.
5. Ouvrir une vidéo avec `&list=` → dialog playlist (radio cette vidéo / toute la playlist) avant le sheet.
6. Écran « Mes téléchargements » : 3 onglets (En cours / Terminés / Erreurs) ; relancer l app → terminés toujours présents.
7. Thème : `body[data-theme]` clair par défaut ; tester le sombre via le réglage (effet au prochain lancement).

- [ ] **Step 7: Commit**

```bash
git add lib/ui/downloads_screen.dart lib/app.dart lib/main.dart android/app/src/main/AndroidManifest.xml
git commit -m "feat: downloads screen + app wiring + permissions"
```

---

## Task 14: Foreground Service (survie en arrière-plan)

**Files:**
- Create: `lib/services/foreground_download_task.dart`
- Modify: `lib/ui/webview_screen.dart` (démarrer/arrêter le service autour des téléchargements), `AndroidManifest.xml` (déclarer le service via `flutter_foreground_task`)

> `flutter_foreground_task` affiche une notification persistante avec progression et empêche Android de tuer le process pendant une playlist longue.

- [ ] **Step 1: Configurer le service au démarrage dans `main.dart`** (après `ensureInitialized`)

```dart
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

// dans main(), avant runApp :
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'downloads',
      channelName: 'Téléchargements',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
    ),
    iosNotificationOptions: const IOSNotificationOptions(),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.nothing(),
      autoRunOnBoot: false,
      allowWakeLock: true,
    ),
  );
```

- [ ] **Step 2: Démarrer/arrêter le service autour du téléchargement**

Dans `webview_screen.dart`, encadrer la phase de téléchargement de `_onDownloadPressed` (après `setLastFormatLabel`, autour du bloc `if (wholePlaylist) … else …`) :
```dart
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
// juste avant le bloc de téléchargement :
    await FlutterForegroundTask.startService(
      notificationTitle: 'Téléchargement en cours',
      notificationText: 'Tubebox',
    );
    try {
      // ... bloc if (wholePlaylist) { ... } else { ... } ...
    } finally {
      await FlutterForegroundTask.stopService();
    }
```

- [ ] **Step 3: Déclarer le service dans `AndroidManifest.xml`** (dans `<application>`)

```xml
<service
    android:name="com.pravera.flutter_foreground_task.service.ForegroundService"
    android:foregroundServiceType="dataSync"
    android:exported="false"/>
```

- [ ] **Step 4: Build + vérif manuelle**

Run: `flutter run`
Vérifier : lancer une playlist, mettre l app en arrière-plan → notification persistante visible, le téléchargement continue, notif disparaît à la fin.

- [ ] **Step 5: Commit**

```bash
git add lib/main.dart lib/ui/webview_screen.dart lib/services/foreground_download_task.dart android/app/src/main/AndroidManifest.xml
git commit -m "feat: foreground service for background downloads"
```

---

## Notes d implémentation

- **Réseau dans les tests** : le test extracteur (Task 6) est taggé `network` ; l exclure en CI avec `flutter test --exclude-tags network`.
- **Wiring du settings/moteur** : v1 instancie directement `YoutubeExplodeExtractor`. Pour activer le switch, `WebViewScreen` lira `SettingsService.engine()` et choisira l impl — trivial une fois `YtDlpExtractor` ajouté (v2).
- **Quota MP4 muxed** : `youtube_explode_dart` ne fournit du muxed (audio+vidéo) qu en qualités limitées (souvent ≤ 720p). Pour de la HD vidéo il faudrait muxer un flux vidéo-only + audio-only via FFmpeg — hors périmètre v1.
- **Police Geist** : si la version installée de `google_fonts` n'expose pas `GoogleFonts.geist()` / `GoogleFonts.geistMono()`, soit mettre `google_fonts` à jour, soit bundler les .ttf Geist dans `assets/fonts/` et les déclarer dans `pubspec.yaml` (fallback : Inter).
- **API `flutter_foreground_task`** : la signature de `ForegroundTaskOptions` varie selon la version. Adapter au constructeur de la version résolue par `pub get` (vérifier la doc de la version installée).
- **Référence visuelle** : le bundle Claude Design est conservé dans `.design/youtube/project/` (HTML/CSS/JSX). Les tâches UI le citent pour les détails pixel ; reproduire le rendu, pas la structure interne du prototype.
- **Thème runtime** : en v1, changer thème/accent dans les Paramètres s'applique au prochain lancement (lu une fois au boot). Live-reload = v2 (remonter via un `ValueNotifier` au-dessus de `MaterialApp`).
```
