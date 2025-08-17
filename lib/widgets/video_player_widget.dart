import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/video_url_parser.dart';

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
    switch (widget.parsedVideo.platform) {
      case VideoPlatform.youtube:
        return YouTubePlayerWidget(
          parsedVideo: widget.parsedVideo,
          title: widget.title,
        );
      
      case VideoPlatform.instagram:
      case VideoPlatform.tiktok:
      case VideoPlatform.vimeo:
      case VideoPlatform.twitch:
        return WebViewPlayerWidget(
          parsedVideo: widget.parsedVideo,
          title: widget.title,
        );
      
      case VideoPlatform.direct:
        return DirectVideoPlayerWidget(
          parsedVideo: widget.parsedVideo,
          title: widget.title,
        );
      
      case VideoPlatform.twitter:
      case VideoPlatform.unsupported:
      default:
        return UnsupportedVideoWidget(
          parsedVideo: widget.parsedVideo,
          title: widget.title,
        );
    }
  }
}

// YouTube Player Widget
class YouTubePlayerWidget extends StatefulWidget {
  final ParsedVideo parsedVideo;
  final String title;

  const YouTubePlayerWidget({
    super.key,
    required this.parsedVideo,
    required this.title,
  });

  @override
  State<YouTubePlayerWidget> createState() => _YouTubePlayerWidgetState();
}

class _YouTubePlayerWidgetState extends State<YouTubePlayerWidget> {
  YoutubePlayerController? _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() async {
    try {
      print('Initializing YouTube player with video ID: ${widget.parsedVideo.videoId}');
      
      _controller = YoutubePlayerController(
        initialVideoId: widget.parsedVideo.videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          enableCaption: true,
          captionLanguage: 'en',
          showLiveFullscreenButton: false,
        ),
      );

      // Simple approach - just wait a bit then mark as ready
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
      
    } catch (e) {
      print('YouTube player initialization error: $e');
      setState(() {
        _error = 'Failed to load YouTube video: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return ErrorVideoWidget(
        error: _error!,
        originalUrl: widget.parsedVideo.originalUrl,
        title: widget.title,
      );
    }

    if (_isLoading || _controller == null) {
      return const LoadingVideoWidget();
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: YoutubePlayer(
          controller: _controller!,
          showVideoProgressIndicator: true,
          aspectRatio: 16 / 9,
          progressIndicatorColor: Theme.of(context).colorScheme.primary,
          progressColors: ProgressBarColors(
            playedColor: Theme.of(context).colorScheme.primary,
            handleColor: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

// WebView Player Widget (for Instagram, TikTok, Vimeo, etc.)
class WebViewPlayerWidget extends StatefulWidget {
  final ParsedVideo parsedVideo;
  final String title;

  const WebViewPlayerWidget({
    super.key,
    required this.parsedVideo,
    required this.title,
  });

  @override
  State<WebViewPlayerWidget> createState() => _WebViewPlayerWidgetState();
}

class _WebViewPlayerWidgetState extends State<WebViewPlayerWidget> {
  late WebViewController _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    try {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.black)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              setState(() => _isLoading = true);
            },
            onPageFinished: (String url) {
              setState(() => _isLoading = false);
            },
            onWebResourceError: (WebResourceError error) {
              setState(() {
                _error = 'Failed to load video: ${error.description}';
                _isLoading = false;
              });
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.parsedVideo.embedUrl));
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize video player: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return ErrorVideoWidget(
        error: _error!,
        originalUrl: widget.parsedVideo.originalUrl,
        title: widget.title,
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              const Center(
                child: LoadingVideoWidget(),
              ),
          ],
        ),
      ),
    );
  }
}

// Direct Video Player Widget
class DirectVideoPlayerWidget extends StatefulWidget {
  final ParsedVideo parsedVideo;
  final String title;

  const DirectVideoPlayerWidget({
    super.key,
    required this.parsedVideo,
    required this.title,
  });

  @override
  State<DirectVideoPlayerWidget> createState() => _DirectVideoPlayerWidgetState();
}

class _DirectVideoPlayerWidgetState extends State<DirectVideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() async {
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.parsedVideo.originalUrl),
      );
      
      await _controller!.initialize();
      
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load video: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return ErrorVideoWidget(
        error: _error!,
        originalUrl: widget.parsedVideo.originalUrl,
        title: widget.title,
      );
    }

    if (_isLoading || _controller == null) {
      return const LoadingVideoWidget();
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: Stack(
            children: [
              VideoPlayer(_controller!),
              VideoPlayerControlsOverlay(controller: _controller!),
            ],
          ),
        ),
      ),
    );
  }
}

// Video Player Controls Overlay
class VideoPlayerControlsOverlay extends StatefulWidget {
  final VideoPlayerController controller;

  const VideoPlayerControlsOverlay({
    super.key,
    required this.controller,
  });

  @override
  State<VideoPlayerControlsOverlay> createState() => _VideoPlayerControlsOverlayState();
}

class _VideoPlayerControlsOverlayState extends State<VideoPlayerControlsOverlay> {
  bool _showControls = true;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _showControls = !_showControls),
      child: Container(
        color: Colors.transparent,
        child: _showControls
            ? Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withAlpha(179),
                      Colors.transparent,
                      Colors.black.withAlpha(179),
                    ],
                  ),
                ),
                child: Center(
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        widget.controller.value.isPlaying
                            ? widget.controller.pause()
                            : widget.controller.play();
                      });
                    },
                    icon: Icon(
                      widget.controller.value.isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

// Unsupported Video Widget
class UnsupportedVideoWidget extends StatelessWidget {
  final ParsedVideo parsedVideo;
  final String title;

  const UnsupportedVideoWidget({
    super.key,
    required this.parsedVideo,
    required this.title,
  });

  Future<void> _openUrl() async {
    final uri = Uri.parse(parsedVideo.originalUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[900],
        border: Border.all(color: Colors.grey[700]!),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            VideoUrlParser.getPlatformIcon(parsedVideo.platform),
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 16),
          Text(
            VideoUrlParser.getPlatformName(parsedVideo.platform),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            parsedVideo.metadata['error'] ?? 'Video embedding not supported',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _openUrl,
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open in Browser'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// Loading Video Widget
class LoadingVideoWidget extends StatelessWidget {
  const LoadingVideoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[900],
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading video...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

// Error Video Widget
class ErrorVideoWidget extends StatelessWidget {
  final String error;
  final String originalUrl;
  final String title;

  const ErrorVideoWidget({
    super.key,
    required this.error,
    required this.originalUrl,
    required this.title,
  });

  Future<void> _openUrl() async {
    final uri = Uri.parse(originalUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.red[900]?.withAlpha(51),
        border: Border.all(color: Colors.red[700]!),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'Failed to Load Video',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _openUrl,
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open Original URL'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
