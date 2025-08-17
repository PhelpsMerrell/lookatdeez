import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/playlist.dart';
import '../models/video_item.dart';

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

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  VideoItem get currentVideo => widget.playlist.videos[currentIndex];
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
        decoration: BoxDecoration(
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
              // Top Bar
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
                          Text(
                            '${currentIndex + 1} of ${widget.playlist.videos.length}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        // Navigate back to editor
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.edit, color: Colors.white),
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
                    return Container(
                      margin: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Video Preview Card
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[900],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Placeholder for video thumbnail/embed
                                  Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(60),
                                    ),
                                    child: Icon(
                                      Icons.play_circle_fill,
                                      size: 60,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  // Video Title
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 24),
                                    child: Text(
                                      video.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  
                                  // Video URL (truncated)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 24),
                                    child: Text(
                                      video.url,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Play Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: isLoading ? null : openVideoUrl,
                              icon: isLoading 
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.play_arrow, size: 28),
                              label: Text(
                                isLoading ? 'Opening...' : 'Play Video',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
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
                    
                    // Video Counter
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${currentIndex + 1} / ${widget.playlist.videos.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
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
}
