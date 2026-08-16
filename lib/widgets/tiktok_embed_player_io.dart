import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

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
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    final params = WebViewPlatform.instance is WebKitWebViewPlatform
        ? WebKitWebViewControllerCreationParams(
            allowsInlineMediaPlayback: true,
            mediaTypesRequiringUserAction: <PlaybackMediaTypes>{},
          )
        : const PlatformWebViewControllerCreationParams();
    controller = WebViewController.fromPlatformCreationParams(params);
    if (controller.platform is AndroidWebViewController) {
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..addJavaScriptChannel(
        'SuikaiPlayer',
        onMessageReceived: (message) {
          debugPrint('TikTok ${widget.videoId}: ${message.message}');
          if (message.message.startsWith('error')) widget.onFailed();
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {
            if (error.isForMainFrame == true) _failed();
          },
        ),
      )
      ..loadHtmlString(_html());
  }

  void _failed() {
    widget.onFailed();
  }

  @override
  void didUpdateWidget(covariant TikTokEmbedPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      controller.runJavaScript('setActive(${widget.active});');
    } else if (widget.active && oldWidget.muted != widget.muted) {
      controller.runJavaScript('setMuted(${widget.muted});');
    }
  }

  String _html() {
    final playerUrl =
        'https://www.tiktok.com/player/v1/${widget.videoId}'
        '?autoplay=${widget.active ? 1 : 0}&muted=${widget.muted ? 1 : 0}&loop=1&controls=1';
    return '''
<!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1">
<style>html,body,iframe{margin:0;width:100%;height:100%;border:0;background:#000;overflow:hidden}</style>
</head><body>
<iframe id="player" src="${htmlEscape.convert(playerUrl)}" allow="autoplay; fullscreen" allowfullscreen></iframe>
<script>
const player=document.getElementById('player');
let ready=false, desiredActive=${widget.active}, desiredMuted=${widget.muted};
function report(value){SuikaiPlayer.postMessage(value);}
function send(type){
  player.contentWindow.postMessage({type:type,'x-tiktok-player':true},'*');
  report(type);
}
function start(){
  if(!ready||!desiredActive)return;
  send(desiredMuted?'mute':'unMute');
  send('play');
}
function stop(){if(!ready)return;send('pause');send('mute');}
function setActive(value){desiredActive=value;if(value)start();else stop();}
function setMuted(value){
  desiredMuted=value;
  if(ready&&desiredActive)send(value?'mute':'unMute');
}
window.addEventListener('message',function(event){
  if(event.source!==player.contentWindow)return;
  let data=event.data;
  if(typeof data==='string'){try{data=JSON.parse(data);}catch(_){return;}}
  if(!data||data['x-tiktok-player']!==true)return;
  if(data.type==='onPlayerReady'){
    ready=true;report('player ready');start();
  }else if(data.type==='onStateChange'&&data.value===1){
    report('playing');
  }else if(data.type==='onPlayerError'){
    report('error '+JSON.stringify(data.value));
  }
});
</script></body></html>''';
  }

  @override
  void dispose() {
    controller.runJavaScript(
      "setActive(false);document.getElementById('player')?.remove();",
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: controller);
}
