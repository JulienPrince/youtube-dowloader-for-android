import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

class ConversionService {
  /// Transcode [inputPath] (m4a/webm) vers [outputPath] (.mp3),
  /// injecte titre/artiste et la pochette [thumbnailPath].
  Future<bool> toMp3({
    required String inputPath,
    required String outputPath,
    required String title,
    required String artist,
    String? thumbnailPath,
  }) async {
    final cover = thumbnailPath != null ? '-i "$thumbnailPath"' : '';
    final mapCover = thumbnailPath != null
        ? '-map 0:a -map 1:0 -id3v2_version 3 -metadata:s:v title="Album cover" -metadata:s:v comment="Cover (front)"'
        : '-map 0:a';
    final cmd =
        '-y -i "$inputPath" $cover -vn $mapCover '
        '-c:a libmp3lame -q:a 2 '
        '-metadata title="$title" -metadata artist="$artist" '
        '"$outputPath"';
    final session = await FFmpegKit.execute(cmd);
    final rc = await session.getReturnCode();
    return ReturnCode.isSuccess(rc);
  }
}
