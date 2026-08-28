import 'dart:io';

import 'package:flutter/services.dart';

/// Uses the platform encoders already bundled by Suikai.  This avoids an
/// FFmpeg dependency and produces exactly one MP4 for the existing uploader.
class VideoSegmentMerger {
  static const _channel = MethodChannel('com.suikai.suikai/video_watermark');

  static Future<String> merge({
    required List<String> sourcePaths,
    required String outputPath,
  }) async {
    if (sourcePaths.isEmpty)
      throw ArgumentError.value(sourcePaths, 'sourcePaths');
    if (sourcePaths.length == 1) return sourcePaths.single;
    if (!Platform.isAndroid && !Platform.isIOS) {
      throw UnsupportedError(
        'video_segment_merge_not_supported_on_this_platform',
      );
    }
    final path = await _channel.invokeMethod<String>('merge', {
      'sourcePaths': sourcePaths,
      'outputPath': outputPath,
    });
    if (path == null || path != outputPath) {
      throw StateError('video_segment_merge_failed');
    }
    return path;
  }
}
