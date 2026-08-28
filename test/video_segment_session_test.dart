import 'package:flutter_test/flutter_test.dart';
import 'package:suikai/services/video_segment_session.dart';

void main() {
  group('VideoSegmentSession', () {
    test('adds durations without exceeding 30 seconds', () {
      final session = VideoSegmentSession();
      session.add(
        const VideoSegment(path: 'one.mp4', duration: Duration(seconds: 12)),
      );
      session.add(
        const VideoSegment(path: 'two.mp4', duration: Duration(seconds: 18)),
      );
      expect(session.totalDuration, const Duration(seconds: 30));
      expect(session.isFull, isTrue);
    });

    test('rejects a segment past the remaining duration', () {
      final session = VideoSegmentSession();
      session.add(
        const VideoSegment(path: 'one.mp4', duration: Duration(seconds: 28)),
      );
      expect(
        () => session.add(
          const VideoSegment(path: 'two.mp4', duration: Duration(seconds: 3)),
        ),
        throwsFormatException,
      );
    });

    test('delete last segment restores remaining duration', () {
      final session = VideoSegmentSession();
      session.add(
        const VideoSegment(path: 'one.mp4', duration: Duration(seconds: 12)),
      );
      session.add(
        const VideoSegment(path: 'two.mp4', duration: Duration(seconds: 8)),
      );
      expect(session.removeLast()!.path, 'two.mp4');
      expect(session.totalDuration, const Duration(seconds: 12));
      expect(session.remaining, const Duration(seconds: 18));
    });

    test('done is allowed before the maximum duration', () {
      final session = VideoSegmentSession();
      session.add(
        const VideoSegment(path: 'one.mp4', duration: Duration(seconds: 1)),
      );
      expect(session.isFull, isFalse);
      expect(session.segments, hasLength(1));
    });
  });
}
