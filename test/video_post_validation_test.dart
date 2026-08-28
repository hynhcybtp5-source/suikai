import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:suikai/services/listing_publish_error.dart';
import 'package:suikai/services/video_post_validation.dart';

void main() {
  test('final video smaller than 5 MiB is allowed', () {
    expect(
      () => VideoPostValidation.validateMetadata(
        durationMilliseconds: 1000,
        sizeBytes: VideoPostValidation.maxSizeBytes - 1,
      ),
      returnsNormally,
    );
  });

  test('final video exactly 5 MiB is allowed', () {
    expect(
      () => VideoPostValidation.validateMetadata(
        durationMilliseconds: 1000,
        sizeBytes: VideoPostValidation.maxSizeBytes,
      ),
      returnsNormally,
    );
  });

  test('final video larger than 5 MiB is blocked before upload', () {
    expect(
      () => VideoPostValidation.validateMetadata(
        durationMilliseconds: 1000,
        sizeBytes: VideoPostValidation.maxSizeBytes + 1,
      ),
      throwsFormatException,
    );
  });

  test(
    'actual final file larger than 5 MiB is blocked before upload',
    () async {
      final directory = await Directory.systemTemp.createTemp('suikai_video_');
      final file = File('${directory.path}/final.mp4');
      await file.writeAsBytes(
        List<int>.filled(VideoPostValidation.maxSizeBytes + 1, 0),
      );
      try {
        await expectLater(
          VideoPostValidation.validateFinalFile(
            path: file.path,
            durationMilliseconds: 1000,
            sizeBytes: 1024,
          ),
          throwsFormatException,
        );
      } finally {
        await directory.delete(recursive: true);
      }
    },
  );

  test('video longer than 30 seconds is blocked', () {
    expect(
      () => VideoPostValidation.validateMetadata(
        durationMilliseconds: VideoPostValidation.maxDurationMilliseconds + 1,
        sizeBytes: 1024,
      ),
      throwsFormatException,
    );
  });

  test('HTTP 413 maps to a safe file-too-large message', () {
    final message = ListingPublishError.messageKeyFor(
      Exception('413 Request Entity Too Large nginx'),
    );
    expect(message, 'ไฟล์มีขนาดใหญ่เกินกว่าที่ระบบรองรับ');
    expect(message.toLowerCase(), isNot(contains('nginx')));
    expect(message, isNot(contains('413')));
  });
}
