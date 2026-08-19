import 'dart:typed_data';

class PreparedVideoPost {
  final String path;
  final Uint8List thumbnailBytes;
  final int durationMilliseconds;
  final int sizeBytes;
  const PreparedVideoPost({
    required this.path,
    required this.thumbnailBytes,
    required this.durationMilliseconds,
    required this.sizeBytes,
  });
}

class VideoPostProcessor {
  static Future<PreparedVideoPost> prepare(String sourcePath) =>
      throw UnsupportedError('video_post_not_supported_on_web');
}
