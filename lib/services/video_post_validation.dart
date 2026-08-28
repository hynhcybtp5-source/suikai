import 'dart:io';

/// Shared constraints for the single final MP4 that is sent to Storage.
///
/// Keeping this separate from the processor ensures the final file is checked
/// again immediately before any listing media is uploaded.
class VideoPostValidation {
  static const maxDurationMilliseconds = 30 * 1000;
  static const maxSizeBytes = 5 * 1024 * 1024;

  static void validateMetadata({
    required int durationMilliseconds,
    required int sizeBytes,
  }) {
    if (durationMilliseconds > maxDurationMilliseconds) {
      throw const FormatException('video_duration_exceeds_30_seconds');
    }
    if (sizeBytes > maxSizeBytes) {
      throw const FormatException('video_size_exceeds_5_mb');
    }
  }

  /// Reads the completed MP4's real size right before upload. The processor's
  /// metadata remains a first-line check; this catches a changed/replaced
  /// temporary file without making any network request.
  static Future<void> validateFinalFile({
    required String path,
    required int durationMilliseconds,
    required int sizeBytes,
  }) async {
    validateMetadata(
      durationMilliseconds: durationMilliseconds,
      sizeBytes: sizeBytes,
    );
    final file = File(path);
    if (!await file.exists()) {
      throw StateError('video_final_file_not_found');
    }
    if (await file.length() > maxSizeBytes) {
      throw const FormatException('video_size_exceeds_5_mb');
    }
  }
}
