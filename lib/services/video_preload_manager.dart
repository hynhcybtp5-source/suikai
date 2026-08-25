import 'dart:async';

import 'package:video_player/video_player.dart';

import '../data/models.dart';

/// Page-owned controller cache for a short-video feed.  It never writes video
/// bytes to disk and keeps only previous/current/next controllers warm.
class VideoPreloadManager {
  final Map<String, Future<VideoPlayerController>> _pending = {};
  final Map<String, VideoPlayerController> _controllers = {};
  int _windowGeneration = 0;
  bool _disposed = false;

  String _key(ListingVideoRecord video) => video.videoMediaId;

  Future<VideoPlayerController> controllerFor(
    ListingVideoRecord video,
    Future<String> Function(ListingVideoRecord video) resolveUrl,
  ) {
    final key = _key(video);
    final ready = _controllers[key];
    if (ready != null) return Future.value(ready);
    return _pending.putIfAbsent(key, () async {
      VideoPlayerController? controller;
      try {
        // A newly signed URL is requested for each create/retry. This keeps the
        // existing Supabase signed-URL flow intact when a URL has expired.
        for (var attempt = 0; attempt < 2; attempt++) {
          controller = VideoPlayerController.networkUrl(
            Uri.parse(await resolveUrl(video)),
          );
          try {
            await controller.initialize();
            await controller.setLooping(true);
            if (_disposed) {
              await controller.dispose();
              throw StateError('video_preload_manager_disposed');
            }
            _controllers[key] = controller;
            return controller;
          } catch (_) {
            await controller.dispose();
            controller = null;
            if (attempt == 1) rethrow;
          }
        }
        throw StateError('video_controller_create_failed');
      } finally {
        _pending.remove(key);
      }
    });
  }

  /// Preload only a tight window: previous one, current, next one, optionally
  /// the second next. Controllers outside that window are disposed.
  Future<void> prepareWindow({
    required List<ListingVideoRecord> videos,
    required int activeIndex,
    required Future<String> Function(ListingVideoRecord video) resolveUrl,
    bool preloadSecondNext = false,
  }) async {
    if (_disposed || videos.isEmpty) return;
    final generation = ++_windowGeneration;
    final upper = activeIndex + (preloadSecondNext ? 2 : 1);
    final keepIndexes = <int>{
      for (var index = activeIndex - 1; index <= upper; index++)
        if (index >= 0 && index < videos.length) index,
    };
    final keepKeys = keepIndexes.map((index) => _key(videos[index])).toSet();
    await Future.wait<void>([
      for (final index in keepIndexes)
        () async {
          // A failed preload must not prevent the current clip or other warm
          // neighbours from working; it will be retried if that clip becomes active.
          try {
            await controllerFor(videos[index], resolveUrl);
          } catch (_) {}
        }(),
    ]);
    if (_disposed || generation != _windowGeneration) return;
    await _disposeExcept(keepKeys);
  }

  Future<void> playOnly(
    ListingVideoRecord active,
    Future<String> Function(ListingVideoRecord video) resolveUrl,
  ) async {
    if (_disposed) return;
    final activeKey = _key(active);
    for (final entry in _controllers.entries) {
      if (entry.key != activeKey && entry.value.value.isPlaying) {
        await entry.value.pause();
      }
    }
    final controller = await controllerFor(active, resolveUrl);
    if (!_disposed && controller.value.isInitialized) await controller.play();
  }

  Future<void> pauseAll() async {
    for (final controller in _controllers.values) {
      if (controller.value.isPlaying) await controller.pause();
    }
  }

  Future<void> _disposeExcept(Set<String> keepKeys) async {
    final stale = _controllers.entries
        .where((entry) => !keepKeys.contains(entry.key))
        .toList();
    for (final entry in stale) {
      _controllers.remove(entry.key);
      await entry.value.dispose();
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    final controllers = _controllers.values.toList();
    _controllers.clear();
    await Future.wait(controllers.map((controller) => controller.dispose()));
  }
}
