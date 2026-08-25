import 'dart:io';

import 'package:flutter/services.dart';

/// Platform-owned watermark export for locally downloaded share videos.
///
/// Android uses Jetpack Media3 Transformer and iOS uses AVFoundation. Keeping
/// this boundary small prevents Flutter from owning an FFmpeg binary just for
/// the share watermark.
class VideoWatermarkProcessor {
  static const _channel = MethodChannel('com.suikai.suikai/video_watermark');

  static Future<void> apply({
    required String sourcePath,
    required String logoPath,
    required String outputPath,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      throw UnsupportedError('video_watermark_not_supported_on_this_platform');
    }
    final exportedPath = await _channel.invokeMethod<String>('apply', {
      'sourcePath': sourcePath,
      'logoPath': logoPath,
      'outputPath': outputPath,
    });
    if (exportedPath == null || exportedPath != outputPath) {
      throw StateError('video_watermark_export_failed');
    }
  }
}
