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
| Conversion MP3 | `ffmpeg_kit_flutter_new` **variant `audio`** (contient `libmp3lame`) — transcodage + tags ID3 + miniature |
| Téléchargement | `dio` (progression, gestion de flux) |
| Persistance | `sqflite` (table des téléchargements ; `drift` envisageable si on veut du typé) |
| Tâche de fond | Foreground Service Android (téléchargement + conversion survivent à la mise en arrière-plan) |
| Stockage / permissions | `path_provider`, `permission_handler` |

### Moteur d'extraction derrière une interface

Le moteur est isolé derrière une abstraction pour pouvoir basculer sans refacto
le jour où `youtube_explode_dart` casse :

```dart
abstract class VideoExtractor {
  Future<VideoInfo> extractVideo(String url);
  Stream<VideoInfo> extractPlaylist(String url);
}
```

- **v1** : implémentation `YoutubeExplodeExtractor` (par défaut) + un réglage dans
  les settings « moteur d'extraction » déjà câblé sur l'interface.
- **v2** : implémentation `YtDlpExtractor` (bridge `youtubedl-android`,
  runtime Python). Le réglage devient réellement basculable une fois cette
  implémentation présente.

Choix de mettre l'interface en v1 mais de différer `YtDlpExtractor` : le bridge
natif (Python + platform channel) est lourd et inutile tant que le moteur Dart
tient ; l'interface garantit zéro refacto au moment de l'ajouter.

### Choix du variant FFmpeg

FFmpeg n'a pas d'encodeur MP3 natif : il faut `libmp3lame`, présent uniquement
dans le variant **`audio`** (et `full`), pas dans `min`. On cible donc le variant
`audio` — plus léger que `full-gpl` tout en couvrant le MP3.

## 4. Flux complet

1. Écran principal = WebView YouTube + FAB « Télécharger » + accès « Mes téléchargements ».
2. L'utilisateur navigue et ouvre une vidéo.
3. Clic FAB :
   - URL avec `list=` → dialog radio (cette vidéo / toute la playlist).
   - URL sans `list=` → étape suivante directement.
4. **Choix du format à chaque fois** : dialog MP4 (vidéo) vs MP3 (audio) +
   qualité. Le dernier choix est mémorisé et pré-sélectionné.
5. Extraction du/des flux via le `VideoExtractor` actif.
6. Téléchargement dans un **Foreground Service** (notification persistante avec
   progression) : par vidéo si playlist, file séquentielle.
7. Si MP3 : transcodage FFmpeg → injection titre / artiste / pochette.
8. Rangement : MP3 dans `Music/`, vidéo dans `Movies/`, visible par les lecteurs
   du système.

### Stratégie d'erreur (playlist)

Une vidéo qui échoue (privée, age-gate, supprimée) **ne bloque pas** la file :
on **skip et on continue**, en consignant l'échec dans le `DownloadRepository`.
À la fin, notification de synthèse : « 28/30 téléchargés, 2 échecs ».

### Nommage des fichiers

`{titre}.mp3` / `{titre}.mp4` avec titre **normalisé en slug** : suppression des
caractères interdits sur FAT32/exFAT (`\ / : * ? " < > |`) pour la compatibilité
carte SD, troncature de longueur, dédoublonnage par suffixe `(2)` si collision.

## 5. Découpage en modules

Chaque module a une responsabilité unique et est testable isolément.

- **`webview_screen`** — WebView + FAB, suivi de l'URL courante, détection
  playlist, déclenchement du flux de téléchargement.
- **`VideoExtractor`** (interface) + `YoutubeExplodeExtractor` (impl v1) —
  entrée : URL ; sortie : métadonnées + flux. Gère vidéo seule **et**
  énumération de playlist.
- **`download_service`** — télécharge un flux donné avec progression ; gère la
  file d'attente séquentielle (skip + log sur erreur). Tourne dans le Foreground
  Service.
- **`conversion_service`** — appels FFmpeg : audio → `.mp3` + tags + pochette.
- **`storage_service`** — chemins de destination, normalisation du nom de
  fichier, permissions, scan média (Android 13+ : `READ_MEDIA_*`).
- **`DownloadRepository`** (sqflite) — persiste l'état de chaque téléchargement
  (url, statut, format, chemin local, timestamp, erreur). Source de vérité de
  `downloads_screen`, survit au redémarrage de l'app.
- **`downloads_screen`** — état de la file (en cours, terminés, erreurs), lu
  depuis le `DownloadRepository`.
- **Settings** — réglage « moteur d'extraction » (câblé sur `VideoExtractor`).

## 6. Périmètre

### v1 (ce design)
- WebView YouTube + FAB Télécharger.
- Téléchargement vidéo (MP4) et audio (MP3 réel).
- Choix de format à chaque fois, dernier choix mémorisé.
- Auto-détection playlist + radio cette vidéo / playlist complète.
- Playlist : **téléchargement complet** (toutes les vidéos), file séquentielle,
  skip + log des échecs + notif de synthèse.
- Foreground Service (téléchargement survit à l'arrière-plan).
- Persistance de l'état via `DownloadRepository` (sqflite).
- Interface `VideoExtractor` + impl `YoutubeExplodeExtractor` + réglage câblé.
- Écran « Mes téléchargements ».

### v2 (plus tard)
- Implémentation `YtDlpExtractor` (rend le réglage de moteur réellement basculable).
- Sélection des vidéos d'une playlist par cases à cocher.
- Réglage de format par défaut dans les paramètres.
- Reprise de téléchargements interrompus.

## 7. Points de vigilance

- **FFmpeg-kit officiel archivé (début 2025)** → dépendance au fork
  `ffmpeg_kit_flutter_new`, variant `audio` ; impact taille APK (~+20–30 Mo vs
  variant `min`, mais bien moins que `full-gpl`).
- **`youtube_explode_dart`** peut casser lors de changements YouTube → garder la
  lib à jour. L'interface `VideoExtractor` permet de basculer vers `YtDlpExtractor`
  (v2) sans refacto le jour où ça lâche.
- **Android 13+** : permissions média granulaires (`READ_MEDIA_AUDIO`,
  `READ_MEDIA_VIDEO`).
- **WebView YouTube** : connexion au compte, pubs et bandeaux possibles ; on
  embarque le site tel quel sans le modifier.
- Usage strictement personnel ; respecter les conditions d'utilisation de YouTube
  relève de la responsabilité de l'utilisateur.
