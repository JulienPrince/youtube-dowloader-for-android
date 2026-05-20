import 'package:flutter_test/flutter_test.dart';
import 'package:tubebox/services/storage_service.dart';

void main() {
  test('supprime les caractères interdits FAT32', () {
    expect(StorageService.safeFileName(r'a/b:c*d?e"f<g>h|i'), 'abcdefghi');
  });
  test('trim et collapse les espaces', () {
    expect(StorageService.safeFileName('  Ma   Vidéo  '), 'Ma Vidéo');
  });
  test('tronque à 120 caractères', () {
    final long = 'x' * 200;
    expect(StorageService.safeFileName(long).length, 120);
  });
  test('fallback si vide', () {
    expect(StorageService.safeFileName('///'), 'download');
  });
}
