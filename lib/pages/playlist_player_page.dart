import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/playlist.dart';
import '../services/video_url_parser.dart';
import '../theme/glass_theme.dart';
import '../widgets/video_player_widget.dart';
import '../widgets/video_debug_widget.dart';

class PlaylistPlayerPage extends StatefulWidget {
  final Playlist playlist;
  final int startIndex;

  const PlaylistPlayerPage({
    super.key,
    required this.playlist,
    this.startIndex = 0,
  });

  @override
  State<PlaylistPlayerPage> createState() => _PlaylistPlayerPageState();
}

class _PlaylistPlayerPageState extends State<PlaylistPlayerPage> {
  late int currentIndex;
  late PageController pageController;
  late List<ParsedVideo> parsedVideos;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.startIndex.clamp(0, widget.playlist.videos.length - 1);
    pageController = PageController(initialPage: currentIndex);
    parsedVideos = widget.playlist.videos
        .map((v) => VideoUrlParser.parseUrl(v.url))
        .toList();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  bool get hasNext => currentIndex < widget.playlist.videos.length - 1;
  bool get hasPrev => currentIndex > 0;

  void _step(int delta) {
    if (widget.playlist.videos.isEmpty) return;
    final next = (currentIndex + delta).clamp(0, widget.playlist.videos.length - 1);
    if (next != currentIndex) {
      pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.playlist.videos.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.video_library_outlined, size: 64, color: Colors.white.withOpacity(0.2)),
              const SizedBox(height: 16),
              Text('No videos to play', style: TextStyle(color: Colors.white.withOpacity(0.5))),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Vertical paging player (matches iOS ScrollView + paging) ──
          PageView.builder(
            controller: pageController,
            scrollDirection: Axis.vertical,
            onPageChanged: (index) => setState(() => currentIndex = index),
            itemCount: widget.playlist.videos.length,
            itemBuilder: (context, index) {
              final video = widget.playlist.videos[index];
              final parsed = parsedVideos[index];

              return Column(
                children: [
                  if (kDebugMode)
                    VideoDebugWidget(url: video.url, parsedVideo: parsed),
                  Expanded(
                    child: VideoPlayerWidget(
                      parsedVideo: parsed,
                      title: video.title,
                    ),
                  ),
                ],
              );
            },
          ),

          // ── Floating glass toolbar (matches iOS PlayAllToolbar) ──
          Positioned(
            left: 12,
            right: 12,
            bottom: MediaQuery.of(context).padding.bottom + 8,
            child: _PlayAllToolbar(
              currentIndex: currentIndex,
              totalCount: widget.playlist.videos.length,
              onDismiss: () => Navigator.pop(context),
              onPrev: () => _step(-1),
              onNext: () => _step(1),
              hasPrev: hasPrev,
              hasNext: hasNext,
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating glass toolbar matching the iOS PlayAllToolbar.
class _PlayAllToolbar extends StatelessWidget {
  final int currentIndex;
  final int totalCount;
  final VoidCallback onDismiss;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final bool hasPrev;
  final bool hasNext;

  const _PlayAllToolbar({
    required this.currentIndex,
    required this.totalCount,
    required this.onDismiss,
    required this.onPrev,
    required this.onNext,
    required this.hasPrev,
    required this.hasNext,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppTheme.radiusXl,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Close button
          _toolbarButton(
            icon: Icons.close,
            onTap: onDismiss,
          ),

          const Spacer(),

          // Navigation capsule
          GlassCard(
            radius: 20,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _toolbarButton(
                  icon: Icons.keyboard_arrow_up,
                  onTap: hasPrev ? onPrev : null,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  '${currentIndex + 1} / $totalCount',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 10),
                _toolbarButton(
                  icon: Icons.keyboard_arrow_down,
                  onTap: hasNext ? onNext : null,
                  size: 18,
                ),
              ],
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }

  Widget _toolbarButton({
    required IconData icon,
    VoidCallback? onTap,
    double size = 16,
  }) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          size: size,
          color: Colors.white.withOpacity(enabled ? 0.85 : 0.2),
        ),
      ),
    );
  }
}
