import 'dart:io';
import 'dart:typed_data';

import 'package:video_compress/video_compress.dart';

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

/// Native-only processing. The result is MP4/AAC from the platform encoder.
class VideoPostProcessor {
  static const _maxDurationMs = 30 * 1000;
  static const _maxSizeBytes = 5 * 1024 * 1024;

  static Future<PreparedVideoPost> prepare(String sourcePath) async {
    final original = await VideoCompress.getMediaInfo(sourcePath);
    final originalDuration = original.duration?.round() ?? 0;
    if (originalDuration > _maxDurationMs) {
      throw const FormatException('video_duration_exceeds_30_seconds');
    }
    final compressed = await VideoCompress.compressVideo(
      sourcePath,
      quality: VideoQuality.MediumQuality,
      deleteOrigin: false,
      includeAudio: true,
    );
    final path = compressed?.path;
    if (path == null || path.isEmpty) {
      throw StateError('video_compression_failed');
    }
    final output = File(path);
    final sizeBytes = await output.length();
    if (sizeBytes > _maxSizeBytes) {
      throw const FormatException('video_size_exceeds_5_mb');
    }
    final duration = compressed?.duration?.round() ?? originalDuration;
    if (duration > _maxDurationMs) {
      throw const FormatException('video_duration_exceeds_30_seconds');
    }
    final thumbnail = await VideoCompress.getByteThumbnail(
      path,
      quality: 70,
      position: 500,
    );
    if (thumbnail == null || thumbnail.isEmpty) {
      throw StateError('video_thumbnail_generation_failed');
    }
    return PreparedVideoPost(
      path: path,
      thumbnailBytes: thumbnail,
      durationMilliseconds: duration,
      sizeBytes: sizeBytes,
    );
  }
}
