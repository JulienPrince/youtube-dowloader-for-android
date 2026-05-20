# Tubebox

> Téléchargez. C'est tout.

Application Android (Flutter) à usage personnel pour télécharger des vidéos YouTube en **MP4** ou en **vrai MP3**, directement depuis une WebView YouTube embarquée.

## Fonctionnalités

- **YouTube embarqué** — navigue dans YouTube comme d'habitude, dans l'app.
- **Bouton « Télécharger » flottant** — récupère la vidéo de la page courante.
- **MP4 ou MP3** — choix du format à chaque fois (bottom sheet), dernier choix mémorisé.
- **Vrai `.mp3`** — transcodage FFmpeg avec titre, artiste et pochette intégrés.
- **Playlists** — auto-détectées ; choix « cette vidéo » ou « toute la playlist » (téléchargement séquentiel, les échecs sont ignorés et journalisés).
- **Téléchargements** — écran à 3 onglets : En cours / Terminés / Erreurs, état persisté entre les lancements.
- **Foreground Service** — les téléchargements continuent en arrière-plan.
- **Thème clair / sombre** + couleur d'accent, police Geist.

Fichiers rangés dans `Music/Tubebox` (audio) et `Movies/Tubebox` (vidéo).

## Stack

| Rôle | Techno |
|------|--------|
| Framework | Flutter / Dart (Material 3) |
| WebView | `flutter_inappwebview` |
| Extraction | `youtube_explode_dart` (derrière une interface `VideoExtractor`) |
| Conversion MP3 | `ffmpeg_kit_flutter_new` (variant `audio`, `libmp3lame`) |
| Téléchargement | `dio` |
| Persistance | `sqflite` |
| Tâche de fond | `flutter_foreground_task` |

## Architecture

```
lib/
  models/       VideoInfo, StreamOption, DownloadTask, DownloadFormat
  extractor/    VideoExtractor (interface) + YoutubeExplodeExtractor
  services/     storage, download (file + skip/log), conversion (FFmpeg)
  data/         DownloadRepository (sqflite)
  settings/     SettingsService (moteur, dernier format, thème, accent)
  theme/        AppTheme + tokens Tubebox (clair/sombre)
  ui/           webview, downloads (3 onglets), settings, onboarding, widgets/
  utils/        url_utils (videoId, détection playlist)
```

Le moteur d'extraction est isolé derrière `VideoExtractor` : un bridge `yt-dlp` pourra être ajouté (v2) sans toucher au reste.

## Démarrer

Prérequis : Flutter (stable) + SDK Android.

```bash
flutter pub get
flutter run            # sur un device/émulateur Android
flutter test           # tests (ajouter --exclude-tags network pour ignorer le test réseau)
flutter build apk --debug
```

minSdk **24** (Android 7+). Distribution : APK direct (pas de Play Store).

## Limitations connues

- `youtube_explode_dart` ne fournit du MP4 *muxed* (audio+vidéo) qu'en qualités limitées (souvent ≤ 720p).
- Le changement de thème / d'accent s'applique au prochain lancement.
- Usage strictement personnel ; le respect des conditions d'utilisation de YouTube relève de l'utilisateur.
