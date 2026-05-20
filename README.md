# Tubebox

> Téléchargez. C'est tout.

Application Android (Flutter) à usage personnel pour télécharger des vidéos YouTube en **MP4** ou en **vrai MP3**, directement depuis une WebView YouTube embarquée.

## Fonctionnalités

- **YouTube embarqué** — navigue dans YouTube comme d'habitude, dans l'app.
- **Bouton « Télécharger » flottant** — récupère la vidéo de la page courante (loader « Analyse… » pendant l'extraction).
- **MP4 ou MP3** — bottom sheet de choix (dernier choix mémorisé), ou format par défaut imposé via les Paramètres.
- **Vrai `.mp3`** — transcodage FFmpeg (bitrate réglable) avec titre, artiste et pochette intégrés.
- **Playlists** — vraies playlists `PL…` auto-détectées : choix « cette vidéo » ou « toute la playlist » (téléchargement séquentiel, échecs ignorés + journalisés).
- **Mes téléchargements** — 3 onglets (En cours / Terminés / Erreurs), live, état persisté. Tap sur un terminé = **ouvre/lit le fichier** ; swipe = supprimer ; **Tout effacer** ; **Réessayer** sur les erreurs.
- **Paramètres** — thème clair/sombre + couleur d'accent **appliqués en live**, format par défaut, qualité audio (MP3), qualité vidéo max, dossiers musique/vidéo configurables.
- **Foreground Service** — les téléchargements continuent en arrière-plan.

Fichiers rangés par défaut dans `Music/Tubebox` (audio) et `Movies/Tubebox` (vidéo) — sous-dossier configurable dans les Paramètres.

## Installation (APK)

Releases : [GitHub Releases](https://github.com/JulienPrince/youtube-dowloader-for-android/releases).
Sur un vrai téléphone, prends l'APK **`arm64-v8a`** (~99% des appareils récents), autorise « installer des applis inconnues », puis ouvre l'APK. minSdk **24** (Android 7+), hors Play Store.

## Stack

| Rôle | Techno |
|------|--------|
| Framework | Flutter / Dart (Material 3) |
| WebView | `flutter_inappwebview` |
| Extraction | `youtube_explode_dart` (clients `androidVr` + `android`) derrière l'interface `VideoExtractor` |
| Téléchargement du flux | client natif `streamsClient.get()` (requêtes Range segmentées, plein débit) |
| Conversion MP3 | `ffmpeg_kit_flutter_new` (variant `audio`, `libmp3lame`) |
| Persistance | `sqflite` · Préférences `shared_preferences` |
| Tâche de fond | `flutter_foreground_task` |
| Divers | `dio` (miniature), `open_filex`, `path_provider`, `permission_handler`, `google_fonts` |

## Architecture

```
lib/
  models/       VideoInfo, StreamOption (url + sizeBytes + source natif), DownloadTask, DownloadFormat
  extractor/    VideoExtractor (interface) + YoutubeExplodeExtractor (extraction + readStream)
  services/     storage, download (file + skip/log), conversion (FFmpeg)
  data/         DownloadRepository (sqflite : CRUD, failStale, clearAll)
  settings/     SettingsService (persistance) + SettingsController (thème/accent live)
  theme/        AppTheme + TubeboxColors (ThemeExtension, clair/sombre)
  ui/           splash, onboarding, webview, downloads (3 onglets), settings, widgets/
  utils/        url_utils (videoId, isPlaylist, isMix)
```

Le moteur d'extraction est isolé derrière `VideoExtractor` : un bridge `yt-dlp` (`YtDlpExtractor`) pourra être ajouté en v2 sans toucher au reste.

### Pourquoi `androidVr` + client natif ?

Les URLs de flux du client YouTube par défaut renvoient **403** (anti-bot/PoToken), et un GET HTTP générique (`dio`) sur l'URL est **throttlé ~9×** par googlevideo. Tubebox demande donc le manifeste avec les clients `androidVr`/`android` (URLs téléchargeables sans PoToken) et télécharge via le **client natif segmenté** de `youtube_explode_dart` → plein débit, fiable.

## Démarrer

Prérequis : Flutter (stable) + SDK Android.

```bash
flutter pub get
flutter run                              # device/émulateur Android
flutter test --exclude-tags network      # tests (le tag network nécessite Internet)
flutter build apk --release --split-per-abi
```

## Limitations connues

- **Mix / Radio YouTube** (`list=RD…`, ce dans quoi les clips musicaux s'ouvrent auto) : non énumérables par `youtube_explode_dart` → message clair, seule la vidéo courante est téléchargée. Les vraies playlists `PL…` fonctionnent. (Le support complet des mixes nécessiterait yt-dlp — v2.)
- MP4 *muxé* (audio+vidéo) limité en qualité par `youtube_explode_dart` (souvent ≤ 720p).
- `youtube_explode_dart` peut casser lors de changements YouTube ; l'interface `VideoExtractor` permet de basculer vers yt-dlp (v2).
- APK release signé avec la clé debug (sideload uniquement).
- Usage strictement personnel ; le respect des conditions d'utilisation de YouTube relève de l'utilisateur.

## Licence

Code sous licence **[MIT](LICENSE)** © 2026 Julien Prince.

Dépendances/ressources bundlées sous leurs propres licences : FFmpeg + `libmp3lame` (LGPL), police **Pirata One** (SIL Open Font License), `youtube_explode_dart` (MIT).
