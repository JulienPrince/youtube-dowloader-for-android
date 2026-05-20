@Tags(['network'])
library;

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
