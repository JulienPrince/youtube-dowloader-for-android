import 'package:flutter_test/flutter_test.dart';
import 'package:tubebox/utils/url_utils.dart';

void main() {
  test('extrait le videoId d une watch url', () {
    expect(UrlUtils.videoId('https://m.youtube.com/watch?v=abc123XYZ_-'), 'abc123XYZ_-');
  });
  test('extrait le videoId d une short url', () {
    expect(UrlUtils.videoId('https://youtu.be/abc123XYZ_-'), 'abc123XYZ_-');
  });
  test('retourne null si pas une vidéo', () {
    expect(UrlUtils.videoId('https://m.youtube.com/feed/subscriptions'), isNull);
  });
  test('détecte une playlist via list=', () {
    expect(UrlUtils.isPlaylist('https://m.youtube.com/watch?v=abc&list=PL123'), isTrue);
  });
  test('pas de playlist sans list=', () {
    expect(UrlUtils.isPlaylist('https://m.youtube.com/watch?v=abc'), isFalse);
  });
  test('extrait le listId', () {
    expect(UrlUtils.listId('https://m.youtube.com/watch?v=abc&list=PL123'), 'PL123');
  });
  test('détecte un Mix/Radio (list=RD…)', () {
    expect(UrlUtils.isMix('https://m.youtube.com/watch?v=abc&list=RDabc'), isTrue);
    expect(UrlUtils.isMix('https://m.youtube.com/watch?v=abc&list=PL123'), isFalse);
    expect(UrlUtils.isMix('https://m.youtube.com/watch?v=abc'), isFalse);
  });
}
