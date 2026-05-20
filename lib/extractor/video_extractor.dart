import '../models/video_info.dart';
import '../models/stream_option.dart';

class PlaylistMeta {
  final String title;
  final int count;
  const PlaylistMeta(this.title, this.count);
}

abstract class VideoExtractor {
  Future<VideoInfo> extractVideo(String url);
  Future<PlaylistMeta> playlistMeta(String url);
  Stream<VideoInfo> extractPlaylist(String url);

  /// Lit les octets d'un flux. L'extracteur télécharge ce qu'il a produit via
  /// son propre client (évite le throttling de googlevideo qui frappe un GET
  /// HTTP générique). [option] doit provenir d'un [VideoInfo] de cet extracteur.
  Stream<List<int>> readStream(StreamOption option);
}
