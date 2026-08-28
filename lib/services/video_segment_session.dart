import 'dart:core';

/// Local-only state for a multi-part camera recording.  Segments never leave
/// the device; callers merge them into one MP4 before the normal upload flow.
class VideoSegment {
  final String path;
  final Duration duration;
  const VideoSegment({required this.path, required this.duration});
}

class VideoSegmentSession {
  static const maximumDuration = Duration(seconds: 30);
  final List<VideoSegment> _segments = [];

  List<VideoSegment> get segments => List.unmodifiable(_segments);
  Duration get totalDuration => _segments.fold(
    Duration.zero,
    (total, segment) => total + segment.duration,
  );
  Duration get remaining => maximumDuration - totalDuration;
  bool get isFull => remaining <= Duration.zero;

  void add(VideoSegment segment) {
    if (segment.duration <= Duration.zero || segment.duration > remaining) {
      throw const FormatException('video_segment_duration_exceeds_limit');
    }
    _segments.add(segment);
  }

  VideoSegment? removeLast() =>
      _segments.isEmpty ? null : _segments.removeLast();
}
