import 'package:flutter/material.dart';
import '../services/video_url_parser.dart';
import '../widgets/video_thumbnail_widget.dart';
import '../widgets/web_iframe_player.dart';

class VideoPlayerWidget extends StatefulWidget {
  final ParsedVideo parsedVideo;
  final String title;

  const VideoPlayerWidget({
    super.key,
    required this.parsedVideo,
    required this.title,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  @override
  Widget build(BuildContext context) {
    // Use iframe embed for platforms that support it
    if (_canEmbed(widget.parsedVideo)) {
      return WebIframePlayer(parsedVideo: widget.parsedVideo);
    }

    // Fall back to thumbnail + external launch for others
    return VideoThumbnailWidget(
      parsedVideo: widget.parsedVideo,
      title: widget.title,
    );
  }

  /// Returns true if this video platform supports in-page iframe embedding.
  bool _canEmbed(ParsedVideo video) {
    if (video.embedUrl.isEmpty) return false;

    switch (video.platform) {
      case VideoPlatform.youtube:
      case VideoPlatform.vimeo:
      case VideoPlatform.direct:
        return true;
      case VideoPlatform.instagram:
      case VideoPlatform.tiktok:
      case VideoPlatform.twitch:
        // These have embed URLs but they're unreliable / require auth
        // Still try them — if iframe fails, user can tap "Open Original"
        return true;
      case VideoPlatform.twitter:
      case VideoPlatform.unsupported:
        return false;
    }
  }
}
