@Tags(['network'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tubebox/extractor/youtube_explode_extractor.dart';
import 'package:tubebox/models/download_format.dart';

void main() {
  test('extrait infos + options d une vidéo connue', () async {
    final ex = YoutubeExplodeExtractor();
    final info = await ex.extractVideo('https://www.youtube.com/watch?v=dQw4w9WgXcQ');
    expect(info.title, isNotEmpty);
    expect(info.options.where((o) => o.label.startsWith('Audio')), isNotEmpty);
    expect(info.options.where((o) => o.container == 'mp4'), isNotEmpty);
    // Le fix throttling : chaque option porte sa taille + un handle natif.
    final audio = info.options.firstWhere((o) => o.format == DownloadFormat.mp3);
    expect(audio.sizeBytes, isNotNull);
    expect(audio.source, isNotNull);
    ex.dispose();
  });

  test('readStream télécharge le flux complet via le client yt (non throttlé)',
      () async {
    final ex = YoutubeExplodeExtractor();
    // "Me at the zoo" : petit fichier, parfait pour un test rapide.
    final info = await ex.extractVideo('https://www.youtube.com/watch?v=jNQXAC9IVRw');
    final audio = info.options.firstWhere((o) => o.format == DownloadFormat.mp3);
    var received = 0;
    await for (final chunk in ex.readStream(audio)) {
      received += chunk.length;
    }
    expect(received, greaterThan(0));
    expect(received, audio.sizeBytes); // octets reçus == taille annoncée
    ex.dispose();
  }, timeout: const Timeout(Duration(seconds: 40)));
}
