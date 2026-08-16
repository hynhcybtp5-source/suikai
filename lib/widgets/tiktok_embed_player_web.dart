// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

class TikTokEmbedPlayer extends StatefulWidget {
  final String videoId;
  final bool active;
  final bool muted;
  final VoidCallback onFailed;

  const TikTokEmbedPlayer({
    super.key,
    required this.videoId,
    required this.active,
    required this.muted,
    required this.onFailed,
  });

  @override
  State<TikTokEmbedPlayer> createState() => _TikTokEmbedPlayerState();
}

class _TikTokEmbedPlayerState extends State<TikTokEmbedPlayer> {
  late final String viewType;
  late final html.IFrameElement iframe;
  late final html.EventListener errorListener;
  late final StreamSubscription<html.MessageEvent> messages;
  bool ready = false;

  @override
  void initState() {
    super.initState();
    viewType = 'suikai-tiktok-${identityHashCode(this)}';
    iframe = html.IFrameElement()
      ..src =
          'https://www.tiktok.com/player/v1/${widget.videoId}'
          '?autoplay=${widget.active ? 1 : 0}&muted=${widget.muted ? 1 : 0}&loop=1&controls=1&play_button=0&volume_control=1'
      ..allow = 'autoplay; fullscreen'
      ..style.border = '0'
      ..style.width = '100%'
      ..style.height = '100%';
    ui_web.platformViewRegistry.registerViewFactory(viewType, (_) => iframe);
    errorListener = (_) => widget.onFailed();
    iframe.addEventListener('error', errorListener);
    messages = html.window.onMessage.listen(_onMessage);
  }

  void _send(String type) {
    iframe.contentWindow?.postMessage({
      'type': type,
      'x-tiktok-player': true,
    }, '*');
    debugPrint('TikTok ${widget.videoId}: $type');
  }

  void _start() {
    if (!ready || !widget.active) return;
    _send(widget.muted ? 'mute' : 'unMute');
    _send('play');
  }

  void _stop() {
    if (!ready) return;
    _send('pause');
    _send('mute');
  }

  void _onMessage(html.MessageEvent event) {
    if (event.origin != 'https://www.tiktok.com') return;
    dynamic data = event.data;
    if (data is String) {
      try {
        data = jsonDecode(data);
      } catch (_) {
        return;
      }
    }
    if (data is! Map || data['x-tiktok-player'] != true) return;
    switch (data['type']) {
      case 'onPlayerReady':
        ready = true;
        debugPrint('TikTok ${widget.videoId}: player ready');
        _start();
      case 'onStateChange' when data['value'] == 1:
        debugPrint('TikTok ${widget.videoId}: playing');
      case 'onPlayerError':
        debugPrint('TikTok ${widget.videoId}: error ${data['value']}');
        widget.onFailed();
    }
  }

  @override
  void didUpdateWidget(covariant TikTokEmbedPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      widget.active ? _start() : _stop();
    } else if (ready && widget.active && oldWidget.muted != widget.muted) {
      _send(widget.muted ? 'mute' : 'unMute');
    }
  }

  @override
  void dispose() {
    _stop();
    messages.cancel();
    iframe.removeEventListener('error', errorListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HtmlElementView(viewType: viewType);
}
