# YouTube Downloader + MP3 (Android, Flutter) — Design

Date : 2026-05-20
Statut : validé (design), spec en revue

## 1. Objectif

Application Android **à usage personnel** permettant de naviguer dans YouTube
directement depuis l'app et de télécharger la vidéo en cours (MP4) ou son audio
converti en **vrai fichier `.mp3`**. Support des playlists avec détection
automatique.

Distribution : APK direct (pas de Play Store, pas de contrainte de validation).

## 2. Principe d'UX

- L'app embarque le **site YouTube mobile** dans une WebView : l'utilisateur
  navigue et regarde YouTube normalement, dans l'app.
- Un **bouton flottant « Télécharger »** par-dessus la WebView lit en continu
  l'URL de la page courante.
- Au clic, l'app récupère le lien de la vidéo courante et lance le flux de
  téléchargement.

### Auto-détection playlist

- L'app surveille l'URL courante de la WebView.
- Si l'URL contient un paramètre `list=...` → **playlist détectée**.
- Au clic sur Télécharger, une boîte de dialogue à boutons **radio** s'affiche :
  - ◉ Cette vidéo seulement
  - ○ Toute la playlist (N vidéos)
- Sans paramètre `list=` → pas de radio, on passe directement au choix du format.

## 3. Stack technique

| Rôle | Choix |
|------|-------|
| Framework | Flutter + Dart, UI Material 3 |
| WebView | `flutter_inappwebview` (suivi d'URL temps réel, overlay, interception navigation) |
| Extraction YouTube | `youtube_explode_dart` (pur Dart : infos, flux vidéo/audio, playlists) |
| Conversion MP3 | FFmpeg via fork maintenu (ex. `ffmpeg_kit_flutter_new`) — transcodage + tags ID3 + miniature |
| Téléchargement | `dio` (progression, gestion de flux) |
| Stockage / permissions | `path_provider`, `permission_handler` |

Moteur d'extraction retenu : `youtube_explode_dart` (100 % Dart, idéal
apprentissage). **Plan B** documenté : bridge `yt-dlp` (youtubedl-android) si la
fiabilité devient un problème.

## 4. Flux complet

1. Écran principal = WebView YouTube + FAB « Télécharger » + accès « Mes téléchargements ».
2. L'utilisateur navigue et ouvre une vidéo.
3. Clic FAB :
   - URL avec `list=` → dialog radio (cette vidéo / toute la playlist).
   - URL sans `list=` → étape suivante directement.
4. **Choix du format à chaque fois** : dialog MP4 (vidéo) vs MP3 (audio) +
   qualité. Le dernier choix est mémorisé et pré-sélectionné.
5. Extraction du/des flux via `youtube_explode_dart`.
6. Téléchargement avec barre de progression (par vidéo si playlist, file
   séquentielle).
7. Si MP3 : transcodage FFmpeg → injection titre / artiste / pochette.
8. Rangement : MP3 dans `Music/`, vidéo dans `Movies/`, visible par les lecteurs
   du système.

## 5. Découpage en modules

Chaque module a une responsabilité unique et est testable isolément.

- **`webview_screen`** — WebView + FAB, suivi de l'URL courante, détection
  playlist, déclenchement du flux de téléchargement.
- **`youtube_service`** — entrée : URL ; sortie : métadonnées + flux
  disponibles. Gère vidéo seule **et** énumération de playlist.
- **`download_service`** — télécharge un flux donné avec progression ; gère la
  file d'attente séquentielle pour les playlists.
- **`conversion_service`** — appels FFmpeg : audio → `.mp3` + tags + pochette.
- **`storage_service`** — chemins de destination, permissions, scan média
  (Android 13+ : `READ_MEDIA_*`).
- **`downloads_screen`** — état de la file (en cours, terminés, erreurs).

## 6. Périmètre

### v1 (ce design)
- WebView YouTube + FAB Télécharger.
- Téléchargement vidéo (MP4) et audio (MP3 réel).
- Choix de format à chaque fois, dernier choix mémorisé.
- Auto-détection playlist + radio cette vidéo / playlist complète.
- Playlist : **téléchargement complet** (toutes les vidéos), file séquentielle.
- Écran « Mes téléchargements ».

### v2 (plus tard)
- Sélection des vidéos d'une playlist par cases à cocher.
- Réglage de format par défaut dans les paramètres.
- Reprise de téléchargements interrompus.
- Bridge `yt-dlp` en alternative au moteur Dart.

## 7. Points de vigilance

- **FFmpeg-kit officiel archivé (début 2025)** → dépendance à un fork
  communautaire ; impact sur la taille de l'APK (+30–50 Mo selon les ABI ciblées).
- **`youtube_explode_dart`** peut casser lors de changements YouTube → garder la
  lib à jour ; plan B yt-dlp.
- **Android 13+** : permissions média granulaires (`READ_MEDIA_AUDIO`,
  `READ_MEDIA_VIDEO`).
- **WebView YouTube** : connexion au compte, pubs et bandeaux possibles ; on
  embarque le site tel quel sans le modifier.
- Usage strictement personnel ; respecter les conditions d'utilisation de YouTube
  relève de la responsabilité de l'utilisateur.
