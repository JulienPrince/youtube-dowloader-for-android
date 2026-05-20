import '../models/video_info.dart';

class PlaylistMeta {
  final String title;
  final int count;
  const PlaylistMeta(this.title, this.count);
}

abstract class VideoExtractor {
  Future<VideoInfo> extractVideo(String url);
  Future<PlaylistMeta> playlistMeta(String url);
  Stream<VideoInfo> extractPlaylist(String url);
}
