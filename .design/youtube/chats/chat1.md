# Interface minimaliste

_Started 2026-05-20 15:29 UTC_

---

## User

fait moi une iterface minimaliste simple d'utilisation qui respecete ca

## Assistant

_[tool: list_files]_

_[tool: list_files]_

_[tool: questions_v2]_

## User

Questions answered:
- screens: Écran principal : WebView YouTube + FAB Télécharger, Dialog playlist détectée (radio : cette vidéo / toute la playlist), Dialog choix de format (MP4 vs MP3 + qualité), Notification de téléchargement en cours (Foreground Service), Écran « Mes téléchargements » (en cours / terminés / erreurs), Écran Paramètres (moteur d'extraction, défauts), Onboarding / permissions au 1er lancement
- theme: Les deux, basculables via Tweaks
- accent: 4
- fab_style: FAB extended (icône + texte « Télécharger »)
- format_picker: Bottom sheet : liste linéaire (1080p MP4, 720p MP4, 320kbps MP3...)
- interactivity: Decide for me
- downloads_layout: 3 onglets : En cours / Terminés / Erreurs
- tweaks: Thème clair / sombre, Langue (FR / EN), Couleur d'accent, Style du FAB (circulaire / extended / pill), Densité (compact / confortable) sur l'écran téléchargements
- vibe: Minimaliste épuré, beaucoup d'espace, peu de chrome

## Assistant

_[tool: update_todos]_

_[tool: copy_starter_component]_

_[tool: copy_starter_component]_

_[tool: copy_starter_component]_

_[tool: read_file]_

_[tool: read_file]_

_[tool: read_file]_

_[tool: write_file]_

## Assistant

_[tool: write_file]_

Now let me build everything. Starting with shared styles and components:

_[tool: write_file]_

_[tool: write_file]_

_[tool: write_file]_

_[tool: write_file]_

_[tool: write_file]_

_[tool: write_file]_

_[tool: grep]_

_[tool: grep]_

_[tool: read_file]_

_[tool: str_replace_edit]_

_[tool: write_file]_

_[tool: show_html]_

_[tool: done]_

_[tool: fork_verifier_agent]_

Voilà — interface minimaliste pour Tubebox sur un canvas Figma-like avec 8 frames Android côte à côte :

**Flux principal** (4 frames)
- **Principal · WebView + FAB** — *cliquable* : tape sur « Télécharger » pour déclencher le vrai flux (playlist détectée → choix de format → confirmation).
- Playlist détectée · radio dialog
- Choix de format · bottom sheet linéaire (MP4/MP3 × 3 qualités, dernier choix mémorisé)
- Notification · Foreground Service (badge en bas du shade)

**Bibliothèque** (3 frames) — onglets En cours / Terminés / Erreurs, avec progress + pulse pendant la conversion MP3.

**Setup** (2 frames) — Onboarding/permissions et Paramètres (moteur d'extraction câblé sur l'interface `VideoExtractor` v1, slot yt-dlp grisé pour v2).

**Tweaks** (toolbar en bas) :
- Thème clair / sombre
- Couleur d'accent (5 swatches, orange par défaut)
- Style du FAB : Extended / Circulaire / Pill
- Densité (téléchargements) : Confortable / Compact
- Langue : FR / EN

Vibe épuré : Geist + Geist Mono, hairlines à 0.5 px, beaucoup d'espace, aucun emoji superflu, accent orange uniquement sur les actions de téléchargement.

Pour itérer : commente directement sur n'importe quel élément du canvas, ou demande-moi des variations (autre layout pour le sheet de format, autre traitement de l'onboarding, etc.).

