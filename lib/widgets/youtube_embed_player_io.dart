import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class YouTubeEmbedPlayer extends StatefulWidget {
  final String videoId;
  final bool active;
  final bool muted;
  final VoidCallback onFailed;

  const YouTubeEmbedPlayer({
    super.key,
    required this.videoId,
    required this.active,
    required this.muted,
    required this.onFailed,
  });

  @override
  State<YouTubeEmbedPlayer> createState() => _YouTubeEmbedPlayerState();
}

class _YouTubeEmbedPlayerState extends State<YouTubeEmbedPlayer> {
  static const _embedReferrer = 'https://suikai-897bb.web.app/';
  late final WebViewController _controller;
  bool _playerReady = false;
  bool _contained = false;

  @override
  void initState() {
    super.initState();
    _debug('load', _embedUrl());
    final params = WebViewPlatform.instance is WebKitWebViewPlatform
        ? WebKitWebViewControllerCreationParams(
            allowsInlineMediaPlayback: true,
            mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
          )
        : const PlatformWebViewControllerCreationParams();
    _controller = WebViewController.fromPlatformCreationParams(params);
    if (_controller.platform is AndroidWebViewController) {
      (_controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }
    _controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: _onNavigationRequest,
          onUrlChange: (change) {
            final url = change.url;
            if (url == null) return;
            _debug('onUrlChange', url);
            if (!_isPlayerUrl(url)) _contain(url);
          },
          onPageStarted: (url) => _debug('onPageStarted', url),
          onPageFinished: (url) {
            _debug('onPageFinished', url);
            if (_isPlayerUrl(url)) {
              _playerReady = true;
              _syncPlayback();
            } else {
              _contain(url);
            }
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == true) {
              _debug('main-frame error ${error.errorCode}', error.description);
              // YouTube's embedded player can emit a transient main-frame
              // error while its media/consent resources are redirected. The
              // final URL callback below is authoritative; failing here makes
              // valid videos immediately fall back to the external link.
            }
          },
        ),
      )
      ..loadRequest(
        Uri.parse(_embedUrl()),
        // Android/iOS WebViews do not provide a Referer by default. YouTube
        // requires this client identity for embedded playback (Error 153).
        headers: const <String, String>{'Referer': _embedReferrer},
      );
  }

  NavigationDecision _onNavigationRequest(NavigationRequest request) {
    _debug('onNavigationRequest', request.url);
    if (_isPlayerUrl(request.url)) return NavigationDecision.navigate;
    if (_playerReady) unawaited(_openExternal(request.url));
    _contain(request.url);
    return NavigationDecision.prevent;
  }

  bool _isPlayerUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null) return false;
    if (uri.scheme == 'about' && uri.path == 'blank') return true;
    final host = uri.host.toLowerCase();
    final segments = uri.pathSegments.where((segment) => segment.isNotEmpty);
    return uri.scheme == 'https' &&
        (host == 'www.youtube.com' ||
            host == 'youtube.com' ||
            host == 'www.youtube-nocookie.com') &&
        segments.length >= 2 &&
        segments.first == 'embed' &&
        segments.elementAt(1) == widget.videoId;
  }

  Future<void> _openExternal(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'https') return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // The player stays contained if no external app/browser is available.
    }
  }

  void _contain(String url) {
    if (_contained) return;
    _contained = true;
    _debug('blocked navigation', url);
    _fail();
  }

  void _fail() {
    _debug('fallback', _embedUrl());
    widget.onFailed();
  }

  void _debug(String event, String value) {
    if (!kDebugMode) return;
    final uri = Uri.tryParse(value);
    final safe = uri == null ? value : '${uri.scheme}://${uri.host}${uri.path}';
    debugPrint('YouTube player $event: $safe');
  }

  void _syncPlayback() {
    final command = widget.active ? 'play' : 'pause';
    final muted = widget.muted ? 'muted = true' : 'muted = false';
    unawaited(
      _controller.runJavaScript(
        'document.querySelectorAll("video").forEach((v) => '
        '{ v.$muted; v.$command(); });',
      ),
    );
  }

  @override
  void didUpdateWidget(covariant YouTubeEmbedPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active || oldWidget.muted != widget.muted) {
      _syncPlayback();
    }
  }

  String _embedUrl() =>
      'https://www.youtube.com/embed/${widget.videoId}'
      '?autoplay=${widget.active ? 1 : 0}&mute=${widget.muted ? 1 : 0}'
      '&playsinline=1&rel=0&enablejsapi=1'
      '&origin=https%3A%2F%2Fsuikai-897bb.web.app'
      '&widget_referrer=https%3A%2F%2Fsuikai-897bb.web.app';

  @override
  void dispose() {
    if (_playerReady) {
      unawaited(
        _controller.runJavaScript(
          'document.querySelectorAll("video").forEach((v) => v.pause());',
        ),
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: _controller);
}
