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
