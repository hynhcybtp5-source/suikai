import 'dart:io';
import 'dart:typed_data';

import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';

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
    final source = File(sourcePath);
    final sourceSizeBytes = await source.length();

    // Camera recordings that already meet the upload limit must not pass
    // through the Android hardware encoder. On affected MediaTek devices the
    // third-party compressor can create an MP4 whose container is valid but
    // whose H.264 frames no longer decode. Uploading the camera original is
    // both lossless and reliable when it is already within our limit.
    if (sourceSizeBytes <= _maxSizeBytes) {
      return _prepareOriginal(
        sourcePath: sourcePath,
        durationMilliseconds: originalDuration,
        sizeBytes: sourceSizeBytes,
      );
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
    await _verifyPlayableOutput(path);
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

  static Future<PreparedVideoPost> _prepareOriginal({
    required String sourcePath,
    required int durationMilliseconds,
    required int sizeBytes,
  }) async {
    final thumbnail = await VideoCompress.getByteThumbnail(
      sourcePath,
      quality: 70,
      position: 500,
    );
    if (thumbnail == null || thumbnail.isEmpty) {
      throw StateError('video_thumbnail_generation_failed');
    }
    return PreparedVideoPost(
      path: sourcePath,
      thumbnailBytes: thumbnail,
      durationMilliseconds: durationMilliseconds,
      sizeBytes: sizeBytes,
    );
  }

  /// Decode-initialize the generated file before it can be uploaded. This
  /// catches invalid MP4 containers produced by a device encoder immediately,
  /// while the user can still choose or record a replacement clip.
  static Future<void> _verifyPlayableOutput(String path) async {
    final controller = VideoPlayerController.file(File(path));
    try {
      await controller.initialize();
      if (!controller.value.isInitialized ||
          controller.value.duration <= Duration.zero) {
        throw StateError('video_output_invalid');
      }
    } catch (_) {
      throw StateError('video_output_invalid');
    } finally {
      await controller.dispose();
    }
  }
}
