# YouTube Downloader Android — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** App Flutter Android (usage perso) embarquant YouTube dans une WebView, avec un bouton flottant qui télécharge la vidéo courante en MP4 ou en vrai MP3, support playlist auto-détecté.

**Architecture:** WebView (`flutter_inappwebview`) → suivi d'URL → FAB Télécharger → extraction via une interface `VideoExtractor` (impl `youtube_explode_dart`) → téléchargement `dio` dans un Foreground Service → conversion FFmpeg (`audio` variant) pour le MP3 → état persisté en `sqflite`.

**Tech Stack:** Flutter/Dart, flutter_inappwebview, youtube_explode_dart, ffmpeg_kit_flutter_new (audio), dio, sqflite, path_provider, permission_handler, flutter_foreground_task.

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
    settings_service.dart                # SharedPreferences: moteur + dernier format
  ui/
    webview_screen.dart                  # WebView + FAB + suivi URL + détection playlist
    downloads_screen.dart                # file: en cours / terminés / erreurs
    widgets/
      format_dialog.dart                 # choix mp4/mp3 + qualité
      playlist_choice_dialog.dart        # radio: cette vidéo / playlist
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
flutter create --org com.prince --project-name yt_downloader --platforms android .
```
Expected: arbre `lib/`, `android/`, `pubspec.yaml` créés. (Le repo a déjà `docs/`, ne pas l'écraser.)

- [ ] **Step 2: Ajouter les dépendances**

Run:
```bash
flutter pub add flutter_inappwebview youtube_explode_dart dio sqflite path_provider permission_handler shared_preferences flutter_foreground_task
flutter pub add ffmpeg_kit_flutter_new
flutter pub add --dev flutter_test
```
Expected: `pubspec.yaml` mis à jour, `flutter pub get` OK.

- [ ] **Step 3: Fixer minSdk et nom**

Modifier `android/app/build.gradle.kts` (ou `.gradle`) : `minSdk = 24`, `applicationId = "com.prince.yt_downloader"`. Modifier `android/app/src/main/AndroidManifest.xml` : `android:label="YT Downloader"`.

- [ ] **Step 4: Vérifier le build**

Run: `flutter build apk --debug`
Expected: BUILD SUCCESSFUL.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "chore: scaffold Flutter app + deps"
```

---

## Task 2: url_utils (parsing URL, détection playlist)

**Files:**
- Create: `lib/utils/url_utils.dart`
- Test: `test/utils/url_utils_test.dart`

- [ ] **Step 1: Écrire les tests**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:yt_downloader/utils/url_utils.dart';

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
import 'package:yt_downloader/models/download_task.dart';
import 'package:yt_downloader/models/download_format.dart';

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
import 'package:yt_downloader/services/storage_service.dart';

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
import 'package:yt_downloader/data/download_repository.dart';
import 'package:yt_downloader/models/download_task.dart';
import 'package:yt_downloader/models/download_format.dart';

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

abstract class VideoExtractor {
  Future<VideoInfo> extractVideo(String url);
  Stream<VideoInfo> extractPlaylist(String url);
}
```

- [ ] **Step 2: Écrire le test d intégration (réseau, optionnel en CI)**

```dart
@Tags(['network'])
import 'package:flutter_test/flutter_test.dart';
import 'package:yt_downloader/extractor/youtube_explode_extractor.dart';

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
    final dir = Directory('/storage/emulated/0/$sub');
    if (await dir.exists()) return dir.path;
    final fallback = await getExternalStorageDirectory();
    return fallback!.path;
  }

  static Future<String> musicPath(String fileName) async =>
      p.join(await _baseDir('Music'), fileName);

  static Future<String> videoPath(String fileName) async =>
      p.join(await _baseDir('Movies'), fileName);

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
import 'package:shared_preferences/shared_preferences.dart';
import '../models/download_format.dart';

class SettingsService {
  static const _kEngine = 'extractor_engine'; // 'youtube_explode' | 'yt_dlp'
  static const _kLastFormat = 'last_format';

  Future<String> engine() async =>
      (await SharedPreferences.getInstance()).getString(_kEngine) ?? 'youtube_explode';

  Future<void> setEngine(String v) async =>
      (await SharedPreferences.getInstance()).setString(_kEngine, v);

  Future<DownloadFormat> lastFormat() async {
    final v = (await SharedPreferences.getInstance()).getString(_kLastFormat);
    return v == null ? DownloadFormat.mp4 : DownloadFormat.values.byName(v);
  }

  Future<void> setLastFormat(DownloadFormat f) async =>
      (await SharedPreferences.getInstance()).setString(_kLastFormat, f.name);
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

## Task 11: Dialogs (format + choix playlist)

**Files:**
- Create: `lib/ui/widgets/format_dialog.dart`, `lib/ui/widgets/playlist_choice_dialog.dart`
- Test: `test/ui/format_dialog_test.dart` (widget test)

- [ ] **Step 1: Écrire le widget test du format_dialog**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yt_downloader/ui/widgets/format_dialog.dart';
import 'package:yt_downloader/models/download_format.dart';

void main() {
  testWidgets('retourne le format choisi', (tester) async {
    DownloadFormat? picked;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (ctx) => ElevatedButton(
        onPressed: () async =>
            picked = await showFormatDialog(ctx, DownloadFormat.mp4),
        child: const Text('open'),
      )),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('MP3 (audio)'));
    await tester.pumpAndSettle();
    expect(picked, DownloadFormat.mp3);
  });
}
```

- [ ] **Step 2: Lancer, vérifier l échec**

Run: `flutter test test/ui/format_dialog_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implémenter `format_dialog.dart`**

```dart
import 'package:flutter/material.dart';
import '../../models/download_format.dart';

Future<DownloadFormat?> showFormatDialog(
    BuildContext context, DownloadFormat last) {
  return showDialog<DownloadFormat>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: const Text('Format de téléchargement'),
      children: [
        SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, DownloadFormat.mp4),
          child: const Text('MP4 (vidéo)'),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, DownloadFormat.mp3),
          child: const Text('MP3 (audio)'),
        ),
      ],
    ),
  );
}
```

- [ ] **Step 4: Lancer, vérifier le succès**

Run: `flutter test test/ui/format_dialog_test.dart`
Expected: PASS.

- [ ] **Step 5: Implémenter `playlist_choice_dialog.dart`**

```dart
import 'package:flutter/material.dart';

enum PlaylistChoice { single, all }

Future<PlaylistChoice?> showPlaylistChoiceDialog(
    BuildContext context, int count) {
  PlaylistChoice choice = PlaylistChoice.single;
  return showDialog<PlaylistChoice>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Playlist détectée'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<PlaylistChoice>(
              title: const Text('Cette vidéo seulement'),
              value: PlaylistChoice.single,
              groupValue: choice,
              onChanged: (v) => setState(() => choice = v!),
            ),
            RadioListTile<PlaylistChoice>(
              title: Text('Toute la playlist ($count vidéos)'),
              value: PlaylistChoice.all,
              groupValue: choice,
              onChanged: (v) => setState(() => choice = v!),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, choice),
              child: const Text('Télécharger')),
        ],
      ),
    ),
  );
}
```

- [ ] **Step 6: Commit**

```bash
git add lib/ui/widgets test/ui
git commit -m "feat: format + playlist choice dialogs"
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
import '../extractor/youtube_explode_extractor.dart';
import '../services/download_service.dart';
import '../data/download_repository.dart';
import '../settings/settings_service.dart';
import '../models/download_format.dart';
import '../utils/url_utils.dart';
import 'widgets/format_dialog.dart';
import 'widgets/playlist_choice_dialog.dart';
import 'downloads_screen.dart';

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
    DownloadFormat? format;
    bool wholePlaylist = false;

    if (UrlUtils.isPlaylist(url)) {
      final choice = await showPlaylistChoiceDialog(context, 0);
      if (choice == null) return;
      wholePlaylist = choice == PlaylistChoice.all;
    }
    format = await showFormatDialog(context, await _settings.lastFormat());
    if (format == null) return;
    await _settings.setLastFormat(format);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Téléchargement lancé…')),
    );

    if (wholePlaylist) {
      final (ok, total) =
          await _downloader.downloadPlaylist(_extractor.extractPlaylist(url), format);
      _toast('$ok/$total téléchargés');
    } else {
      final info = await _extractor.extractVideo(url);
      final opt = info.options.firstWhere((o) => o.format == format);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('YT Downloader'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_done),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => DownloadsScreen(repo: widget.repo))),
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
              icon: const Icon(Icons.download),
              label: const Text('Télécharger'),
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

- [ ] **Step 1: Implémenter `downloads_screen.dart`**

```dart
import 'package:flutter/material.dart';
import '../data/download_repository.dart';
import '../models/download_task.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes téléchargements'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh)],
      ),
      body: FutureBuilder<List<DownloadTask>>(
        future: _future,
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final tasks = snap.data!;
          if (tasks.isEmpty) return const Center(child: Text('Aucun téléchargement'));
          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (ctx, i) {
              final t = tasks[i];
              return ListTile(
                title: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${t.format.name} · ${t.status.name}'
                    '${t.error != null ? ' · ${t.error}' : ''}'),
                trailing: t.status == DownloadStatus.downloading ||
                        t.status == DownloadStatus.converting
                    ? SizedBox(
                        width: 36, height: 36,
                        child: CircularProgressIndicator(value: t.progress))
                    : Icon(t.status == DownloadStatus.done
                        ? Icons.check_circle
                        : t.status == DownloadStatus.failed
                            ? Icons.error
                            : Icons.schedule),
              );
            },
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 2: Implémenter `app.dart`**

```dart
import 'package:flutter/material.dart';
import 'data/download_repository.dart';
import 'ui/webview_screen.dart';

class App extends StatelessWidget {
  final DownloadRepository repo;
  const App({super.key, required this.repo});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YT Downloader',
      theme: ThemeData(colorSchemeSeed: Colors.red, useMaterial3: true),
      home: WebViewScreen(repo: repo),
    );
  }
}
```

- [ ] **Step 3: Réécrire `main.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'data/download_repository.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repo = DownloadRepository();
  await repo.open();
  await [Permission.storage, Permission.audio, Permission.videos, Permission.notification]
      .request();
  runApp(App(repo: repo));
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
1. La WebView ouvre YouTube mobile, navigation OK.
2. Ouvrir une vidéo → le FAB « Télécharger » apparaît.
3. Clic → dialog format → choisir MP3 → snackbar « lancé » puis « Terminé ».
4. Le `.mp3` est dans `Music/`, lisible par un lecteur, avec titre/pochette.
5. Ouvrir une vidéo avec `&list=` → le dialog radio playlist apparaît.
6. Onglet « Mes téléchargements » liste l item ; relancer l app → toujours présent.

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

Dans `webview_screen.dart`, encadrer `_onDownloadPressed` :
```dart
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
// au début du vrai téléchargement (après choix format) :
    await FlutterForegroundTask.startService(
      notificationTitle: 'Téléchargement en cours',
      notificationText: 'YT Downloader',
    );
// dans un finally après la fin (single ou playlist) :
    await FlutterForegroundTask.stopService();
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
```
