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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black87,
              Colors.black54,
              Colors.black87,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar with Platform Info
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.playlist.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            children: [
                              Text(
                                VideoUrlParser.getPlatformIcon(currentParsedVideo.platform),
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                VideoUrlParser.getPlatformName(currentParsedVideo.platform),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${currentIndex + 1} of ${widget.playlist.videos.length}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => VideoTermsDialog.show(context),
                      icon: const Icon(Icons.info_outline, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: openVideoUrl,
                      icon: const Icon(Icons.open_in_new, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),

              // Main Video Display Area
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
                    
                    return Container(
                      margin: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Video Title
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              video.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // DEBUG: Show parsed video info (remove this in production)
                          VideoDebugWidget(
                            url: video.url,
                            parsedVideo: parsedVideo,
                          ),
                          
                          // Video Player Area
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              constraints: const BoxConstraints(
                                minHeight: 200,
                                maxHeight: 400,
                              ),
                              child: VideoPlayerWidget(
                                parsedVideo: parsedVideo,
                                title: video.title,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Video Info & Actions
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                // Platform and Status Info
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          VideoUrlParser.getPlatformIcon(parsedVideo.platform),
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          VideoUrlParser.getPlatformName(parsedVideo.platform),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(parsedVideo.platform),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _getStatusText(parsedVideo.platform),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 12),
                                
                                // URL Display (truncated)
                                Text(
                                  video.url,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 12,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Action Buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: isLoading ? null : openVideoUrl,
                                        icon: isLoading 
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              )
                                            : const Icon(Icons.open_in_new, size: 18),
                                        label: Text(
                                          isLoading ? 'Opening...' : 'Open Original',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white.withOpacity(0.1),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Bottom Navigation Controls
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Previous Button
                    IconButton(
                      onPressed: hasPreviousVideo ? goToPrevious : null,
                      icon: const Icon(Icons.skip_previous, size: 36),
                      style: IconButton.styleFrom(
                        backgroundColor: hasPreviousVideo 
                            ? Colors.white.withOpacity(0.1) 
                            : Colors.transparent,
                        foregroundColor: hasPreviousVideo 
                            ? Colors.white 
                            : Colors.white.withOpacity(0.3),
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                    
                    // Video Counter with Platform Icons
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${currentIndex + 1} / ${widget.playlist.videos.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            VideoUrlParser.getPlatformIcon(currentParsedVideo.platform),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    
                    // Next Button
                    IconButton(
                      onPressed: hasNextVideo ? goToNext : null,
                      icon: const Icon(Icons.skip_next, size: 36),
                      style: IconButton.styleFrom(
                        backgroundColor: hasNextVideo 
                            ? Colors.white.withOpacity(0.1) 
                            : Colors.transparent,
                        foregroundColor: hasNextVideo 
                            ? Colors.white 
                            : Colors.white.withOpacity(0.3),
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(VideoPlatform platform) {
    switch (platform) {
      case VideoPlatform.youtube:
      case VideoPlatform.vimeo:
      case VideoPlatform.direct:
        return Colors.green;
      case VideoPlatform.instagram:
      case VideoPlatform.tiktok:
      case VideoPlatform.twitch:
        return Colors.orange;
      case VideoPlatform.twitter:
      case VideoPlatform.unsupported:
        return Colors.red;
    }
  }

  String _getStatusText(VideoPlatform platform) {
    switch (platform) {
      case VideoPlatform.youtube:
      case VideoPlatform.vimeo:
      case VideoPlatform.direct:
        return 'PLAYABLE';
      case VideoPlatform.instagram:
      case VideoPlatform.tiktok:
      case VideoPlatform.twitch:
        return 'EMBED';
      case VideoPlatform.twitter:
      case VideoPlatform.unsupported:
        return 'LINK ONLY';
    }
  }
}
