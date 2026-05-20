import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/video_info.dart';
import '../models/stream_option.dart';
import '../models/download_format.dart';
import 'video_extractor.dart';

class YoutubeExplodeExtractor implements VideoExtractor {
  final YoutubeExplode _yt = YoutubeExplode();

  @override
  Future<VideoInfo> extractVideo(String url) async {
    final video = await _yt.videos.get(url);
    final manifest = await _yt.videos.streamsClient.getManifest(video.id);

    final options = <StreamOption>[];
    for (final s in manifest.muxed) {
      options.add(StreamOption(
        format: DownloadFormat.mp4,
        label: s.qualityLabel,
        url: s.url.toString(),
        container: s.container.name,
      ));
    }
    final audio = manifest.audioOnly.withHighestBitrate();
    options.add(StreamOption(
      format: DownloadFormat.mp3,
      label: 'Audio ${audio.bitrate.kiloBitsPerSecond.round()}kbps',
      url: audio.url.toString(),
      container: audio.container.name,
      bitrate: audio.bitrate.kiloBitsPerSecond.round(),
    ));

    return VideoInfo(
      id: video.id.value,
      title: video.title,
      author: video.author,
      thumbnailUrl: video.thumbnails.highResUrl,
      duration: video.duration ?? Duration.zero,
      options: options,
    );
  }

  @override
  Future<PlaylistMeta> playlistMeta(String url) async {
    final pl = await _yt.playlists.get(url);
    return PlaylistMeta(pl.title, pl.videoCount ?? 0);
  }

  @override
  Stream<VideoInfo> extractPlaylist(String url) async* {
    await for (final v in _yt.playlists.getVideos(url)) {
      yield await extractVideo(v.url);
    }
  }

  void dispose() => _yt.close();
}
