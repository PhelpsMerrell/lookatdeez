import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/video_url_parser.dart';

class VideoThumbnailWidget extends StatefulWidget {
  final ParsedVideo parsedVideo;
  final String title;

  const VideoThumbnailWidget({
    super.key,
    required this.parsedVideo,
    required this.title,
  });

  @override
  State<VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {
  bool _imageLoading = true;
  bool _imageError = false;

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl = _getThumbnailUrl();
    final platformInfo = _getPlatformInfo();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black,
        border: Border.all(color: Colors.grey[800]!, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _launchVideo,
          child: Column(
            children: [
              // Thumbnail Section
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Thumbnail Image
                        if (thumbnailUrl != null && !_imageError)
                          Image.network(
                            thumbnailUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (mounted) setState(() => _imageLoading = false);
                                });
                                return child;
                              }
                              return Container(
                                color: Colors.grey[900],
                                child: const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) setState(() => _imageError = true);
                              });
                              return Container(color: Colors.grey[900]);
                            },
                          ),
                        
                        // Fallback when no thumbnail or error
                        if (thumbnailUrl == null || _imageError)
                          Container(
                            color: Colors.grey[900],
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    VideoUrlParser.getPlatformIcon(widget.parsedVideo.platform),
                                    style: const TextStyle(fontSize: 48),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    VideoUrlParser.getPlatformName(widget.parsedVideo.platform),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Play Overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withAlpha(0),
                                Colors.black.withAlpha(0),
                                Colors.black.withAlpha(128),
                              ],
                            ),
                          ),
                        ),

                        // Play Button
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(179),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.play_arrow,
                              color: platformInfo['color'],
                              size: 32,
                            ),
                          ),
                        ),

                        // Platform Badge
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: platformInfo['color'].withAlpha(204),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  VideoUrlParser.getPlatformIcon(widget.parsedVideo.platform),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  VideoUrlParser.getPlatformName(widget.parsedVideo.platform),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Info Section
              Expanded(
                flex: 1,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Title
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      
                      // Platform and Action
                      Row(
                        children: [
                          Text(
                            VideoUrlParser.getPlatformIcon(widget.parsedVideo.platform),
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Tap to open in ${platformInfo['appName']}',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 11,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.open_in_new,
                            color: platformInfo['color'],
                            size: 14,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _getThumbnailUrl() {
    switch (widget.parsedVideo.platform) {
      case VideoPlatform.youtube:
        // Try different YouTube thumbnail qualities
        final videoId = widget.parsedVideo.videoId;
        return 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
        
      case VideoPlatform.vimeo:
        // Vimeo thumbnails require API call, but we can try a common pattern
        final videoId = widget.parsedVideo.videoId;
        return 'https://vumbnail.com/$videoId.jpg';
        
      case VideoPlatform.instagram:
      case VideoPlatform.tiktok:
      case VideoPlatform.twitch:
      case VideoPlatform.twitter:
        // These would need API calls for real thumbnails
        // For now, return null to show platform icon
        return null;
        
      case VideoPlatform.direct:
        // Could potentially extract thumbnail from video
        return null;
        
      case VideoPlatform.unsupported:
      default:
        return null;
    }
  }

  Map<String, dynamic> _getPlatformInfo() {
    switch (widget.parsedVideo.platform) {
      case VideoPlatform.youtube:
        return {
          'color': Colors.red,
          'appName': 'YouTube',
        };
      case VideoPlatform.instagram:
        return {
          'color': const Color(0xFFE4405F),
          'appName': 'Instagram',
        };
      case VideoPlatform.tiktok:
        return {
          'color': Colors.black,
          'appName': 'TikTok',
        };
      case VideoPlatform.vimeo:
        return {
          'color': const Color(0xFF1AB7EA),
          'appName': 'Vimeo',
        };
      case VideoPlatform.twitch:
        return {
          'color': const Color(0xFF9146FF),
          'appName': 'Twitch',
        };
      case VideoPlatform.twitter:
        return {
          'color': const Color(0xFF1DA1F2),
          'appName': 'Twitter/X',
        };
      case VideoPlatform.direct:
        return {
          'color': Colors.blue,
          'appName': 'Video Player',
        };
      case VideoPlatform.unsupported:
      default:
        return {
          'color': Colors.grey,
          'appName': 'Browser',
        };
    }
  }

  Future<void> _launchVideo() async {
    try {
      final uri = Uri.parse(widget.parsedVideo.originalUrl);
      
      // Launch with external application mode for better app switching
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      
      if (!launched) {
        // Fallback to in-app browser if external launch fails
        await launchUrl(
          uri,
          mode: LaunchMode.inAppBrowserView,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
