import 'package:flutter_test/flutter_test.dart';
import 'package:suikai/data/models.dart';

void main() {
  group('ShortVideoRecord YouTube URL parsing', () {
    test('parses a YouTube Shorts URL', () {
      expect(
        ShortVideoRecord.youtubeVideoId(
          'https://youtube.com/shorts/dQw4w9WgXcQ',
        ),
        'dQw4w9WgXcQ',
      );
    });

    test('parses a YouTube watch URL', () {
      expect(
        ShortVideoRecord.youtubeVideoId(
          'https://www.youtube.com/watch?v=dQw4w9WgXcQ&feature=share',
        ),
        'dQw4w9WgXcQ',
      );
    });

    test('parses a youtu.be URL', () {
      expect(
        ShortVideoRecord.youtubeVideoId('https://youtu.be/dQw4w9WgXcQ'),
        'dQw4w9WgXcQ',
      );
    });

    test('rejects invalid YouTube URLs', () {
      for (final value in <String>[
        'https://example.com/watch?v=dQw4w9WgXcQ',
        'https://youtube.com/shorts/too-short',
        'javascript:alert(1)',
      ]) {
        expect(ShortVideoRecord.youtubeVideoId(value), isNull, reason: value);
        expect(ShortVideoRecord.isValidYouTubeUrl(value), isFalse);
      }
    });
  });
}
