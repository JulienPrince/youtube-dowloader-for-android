class StorageService {
  static String safeFileName(String raw) {
    var s = raw.replaceAll(RegExp(r'[\\/:*?"<>|]'), '');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (s.length > 120) s = s.substring(0, 120);
    return s.isEmpty ? 'download' : s;
  }
}
