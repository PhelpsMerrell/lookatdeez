import 'package:flutter/material.dart';
import '../services/video_url_parser.dart';
import '../widgets/video_thumbnail_widget.dart';

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
    // Use thumbnail approach for all video types
    return VideoThumbnailWidget(
      parsedVideo: widget.parsedVideo,
      title: widget.title,
    );
  }
}
