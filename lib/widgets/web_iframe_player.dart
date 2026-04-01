import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import '../services/video_url_parser.dart';

/// A widget that embeds a video via iframe for Flutter web.
/// Works with YouTube, Vimeo, and any platform that provides an embed URL.
class WebIframePlayer extends StatefulWidget {
  final ParsedVideo parsedVideo;

  const WebIframePlayer({
    super.key,
    required this.parsedVideo,
  });

  @override
  State<WebIframePlayer> createState() => _WebIframePlayerState();
}

class _WebIframePlayerState extends State<WebIframePlayer> {
  late String _viewType;

  @override
  void initState() {
    super.initState();
    _registerView();
  }

  @override
  void didUpdateWidget(WebIframePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.parsedVideo.embedUrl != widget.parsedVideo.embedUrl) {
      _registerView();
    }
  }

  void _registerView() {
    final embedUrl = widget.parsedVideo.embedUrl;
    _viewType = 'iframe-player-${embedUrl.hashCode}-${DateTime.now().millisecondsSinceEpoch}';

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) {
        final iframe = html.IFrameElement()
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..allowFullscreen = true;

        // Set permissions for video playback
        iframe.allow =
            'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share';

        // Build src with appropriate params per platform
        if (widget.parsedVideo.platform == VideoPlatform.youtube) {
          iframe.src = '$embedUrl?rel=0&modestbranding=1&playsinline=1';
        } else {
          iframe.src = embedUrl;
        }

        return iframe;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: HtmlElementView(viewType: _viewType),
      ),
    );
  }
}
