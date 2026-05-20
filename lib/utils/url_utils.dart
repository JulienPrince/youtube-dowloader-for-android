class UrlUtils {
  static String? videoId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    if (uri.host.contains('youtu.be')) {
      final seg = uri.pathSegments;
      return seg.isNotEmpty && seg.first.isNotEmpty ? seg.first : null;
    }
    final v = uri.queryParameters['v'];
    return (v != null && v.isNotEmpty) ? v : null;
  }

  static bool isPlaylist(String url) => listId(url) != null;

  static String? listId(String url) {
    final id = Uri.tryParse(url)?.queryParameters['list'];
    return (id != null && id.isNotEmpty) ? id : null;
  }

  /// Mix / Radio YouTube (list=RD…) : auto-généré et infini, non énumérable.
  static bool isMix(String url) {
    final id = listId(url);
    return id != null && id.startsWith('RD');
  }
}
