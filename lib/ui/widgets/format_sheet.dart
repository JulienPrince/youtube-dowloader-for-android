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
                    color: isLast ? c.accent.withValues(alpha: 0.08) : Colors.transparent,
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
