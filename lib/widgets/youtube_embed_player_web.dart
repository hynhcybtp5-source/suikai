// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

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
  late final String _viewType;
  late final html.IFrameElement _iframe;
  late final html.EventListener _errorListener;

  @override
  void initState() {
    super.initState();
    _viewType = 'suikai-youtube-${identityHashCode(this)}';
    _iframe = html.IFrameElement()
      ..src = _embedUrl()
      ..allow = 'autoplay; fullscreen; picture-in-picture'
      ..setAttribute('referrerpolicy', 'strict-origin-when-cross-origin')
      // Popups escape the embed into a separate browser tab; they never
      // replace Suikai's short-video page.
      ..setAttribute(
        'sandbox',
        'allow-scripts allow-same-origin allow-presentation allow-popups '
            'allow-popups-to-escape-sandbox',
      )
      ..style.border = '0'
      ..style.width = '100%'
      ..style.height = '100%';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (_) => _iframe);
    _errorListener = (_) => widget.onFailed();
    _iframe.addEventListener('error', _errorListener);
  }

  void _command(String function) {
    _iframe.contentWindow?.postMessage(
      jsonEncode(<String, String>{'event': 'command', 'func': function}),
      'https://www.youtube.com',
    );
  }

  void _syncPlayback() {
    _command(widget.muted ? 'mute' : 'unMute');
    _command(widget.active ? 'playVideo' : 'pauseVideo');
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
    _command('pauseVideo');
    _iframe.removeEventListener('error', _errorListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HtmlElementView(viewType: _viewType);
}
