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
                color: on ? c.accent.withValues(alpha: 0.08) : Colors.transparent,
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
              radio(PlaylistChoice.all, 'Toute la playlist ($count vidéos)',
                  'Téléchargées une par une'),
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
