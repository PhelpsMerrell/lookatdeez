import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/playlist.dart';
import '../models/video_item.dart';
import '../services/video_url_parser.dart';
import '../widgets/video_player_widget.dart';
import '../widgets/video_terms_dialog.dart';
import '../widgets/video_debug_widget.dart';

class PlaylistPlayerPage extends StatefulWidget {
  final Playlist playlist;

  const PlaylistPlayerPage({
    super.key,
    required this.playlist,
  });

  @override
  State<PlaylistPlayerPage> createState() => _PlaylistPlayerPageState();
}

class _PlaylistPlayerPageState extends State<PlaylistPlayerPage> {
  int currentIndex = 0;
  PageController pageController = PageController();
  bool isLoading = false;
  List<ParsedVideo> parsedVideos = [];

  @override
  void initState() {
    super.initState();
    _parseAllVideos();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  void _parseAllVideos() {
    parsedVideos = widget.playlist.videos
        .map((video) => VideoUrlParser.parseUrl(video.url))
        .toList();
  }

  VideoItem get currentVideo => widget.playlist.videos[currentIndex];
  ParsedVideo get currentParsedVideo => parsedVideos[currentIndex];
  bool get hasNextVideo => currentIndex < widget.playlist.videos.length - 1;
  bool get hasPreviousVideo => currentIndex > 0;

  void goToNext() {
    if (hasNextVideo) {
      setState(() => currentIndex++);
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void goToPrevious() {
    if (hasPreviousVideo) {
      setState(() => currentIndex--);
      pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> openVideoUrl() async {
    setState(() => isLoading = true);
    try {
      final uri = Uri.parse(currentVideo.url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open: ${currentVideo.url}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid URL: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.playlist.videos.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.playlist.name),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.video_call_outlined, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text('No videos to play', style: TextStyle(fontSize: 18)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.playlist.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => VideoTermsDialog.show(context),
                    icon: const Icon(Icons.info_outline, color: Colors.white70, size: 20),
                  ),
                  IconButton(
                    onPressed: isLoading ? null : openVideoUrl,
                    icon: Icon(
                      Icons.open_in_new,
                      color: isLoading ? Colors.white30 : Colors.white70,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            // ── Video Title + Platform ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    VideoUrlParser.getPlatformIcon(currentParsedVideo.platform),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      currentVideo.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${currentIndex + 1} / ${widget.playlist.videos.length}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Main Video Player Area (swipeable) ──
            Expanded(
              child: PageView.builder(
                controller: pageController,
                onPageChanged: (index) {
                  setState(() => currentIndex = index);
                },
                itemCount: widget.playlist.videos.length,
                itemBuilder: (context, index) {
                  final video = widget.playlist.videos[index];
                  final parsedVideo = parsedVideos[index];

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // Debug info (only in debug builds)
                        if (kDebugMode)
                          VideoDebugWidget(
                            url: video.url,
                            parsedVideo: parsedVideo,
                          ),

                        // Video Player — takes all available space
                        Expanded(
                          child: VideoPlayerWidget(
                            parsedVideo: parsedVideo,
                            title: video.title,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // URL display (subtle)
                        Text(
                          video.url,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // ── Bottom Navigation Controls ──
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Previous
                  _NavButton(
                    icon: Icons.skip_previous_rounded,
                    enabled: hasPreviousVideo,
                    onPressed: goToPrevious,
                  ),

                  // Open in app button
                  TextButton.icon(
                    onPressed: isLoading ? null : openVideoUrl,
                    icon: Icon(
                      Icons.open_in_new,
                      size: 16,
                      color: isLoading ? Colors.white30 : Colors.white60,
                    ),
                    label: Text(
                      'Open in ${VideoUrlParser.getPlatformName(currentParsedVideo.platform)}',
                      style: TextStyle(
                        color: isLoading ? Colors.white30 : Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ),

                  // Next
                  _NavButton(
                    icon: Icons.skip_next_rounded,
                    enabled: hasNextVideo,
                    onPressed: goToNext,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  const _NavButton({
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 36),
      style: IconButton.styleFrom(
        backgroundColor: enabled ? Colors.white.withOpacity(0.1) : Colors.transparent,
        foregroundColor: enabled ? Colors.white : Colors.white.withOpacity(0.2),
        padding: const EdgeInsets.all(12),
      ),
    );
  }
}
