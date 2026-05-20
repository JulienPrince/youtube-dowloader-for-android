import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class StorageService {
  static String safeFileName(String raw) {
    var s = raw.replaceAll(RegExp(r'[\\/:*?"<>|]'), '');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (s.length > 120) s = s.substring(0, 120);
    return s.isEmpty ? 'download' : s;
  }

  static Future<String> _baseDir(String sub) async {
    var dir = Directory('/storage/emulated/0/$sub');
    if (!await Directory('/storage/emulated/0').exists()) {
      dir = Directory(p.join((await getExternalStorageDirectory())!.path, sub));
    }
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  static Future<String> musicPath(String fileName) async =>
      p.join(await _baseDir('Music/Tubebox'), fileName);

  static Future<String> videoPath(String fileName) async =>
      p.join(await _baseDir('Movies/Tubebox'), fileName);

  static Future<String> tempPath(String fileName) async =>
      p.join((await getTemporaryDirectory()).path, fileName);
}
