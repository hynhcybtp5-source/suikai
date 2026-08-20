import 'package:flutter_test/flutter_test.dart';
import 'package:suikai/data/models.dart';

void main() {
  test('video-only listing metadata has a video and thumbnail reference', () {
    const video = ListingVideoRecord(
      id: 'video-1',
      videoMediaId: 'video-media-1',
      thumbnailMediaId: 'thumbnail-media-1',
      videoPath: 'listings/drafts/owner/video.mp4',
      thumbnailPath: 'listings/drafts/owner/thumbnail.jpg',
      durationMilliseconds: 1000,
      sizeBytes: 1024,
    );

    expect(video.videoMediaId, isNotEmpty);
    expect(video.thumbnailMediaId, isNotEmpty);
    expect(video.durationMilliseconds, greaterThan(0));
  });
}
