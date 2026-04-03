import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../models/video_item.dart';
import '../services/api_service.dart';
import '../theme/glass_theme.dart';
import '../widgets/friend_share_sheet.dart';
import '../widgets/video_terms_dialog.dart';
import 'playlist_player_page.dart';

class PlaylistEditorPage extends StatefulWidget {
  final Playlist playlist;
  final Function(Playlist) onPlaylistUpdated;
  final bool startInPlayMode;

  const PlaylistEditorPage({
    super.key,
    required this.playlist,
    required this.onPlaylistUpdated,
    this.startInPlayMode = false,
  });

  @override
  State<PlaylistEditorPage> createState() => _PlaylistEditorPageState();
}

class _PlaylistEditorPageState extends State<PlaylistEditorPage> {
  late Playlist playlist;
  final titleController = TextEditingController();
  final urlController = TextEditingController();
  bool isLoading = false;
  bool hasOrderChanged = false;

  @override
  void initState() {
    super.initState();
    playlist = Playlist(
      id: widget.playlist.id,
      name: widget.playlist.name,
      videos: List.from(widget.playlist.videos),
    );

    if (widget.startInPlayMode && playlist.videos.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openPlayMode());
    }
  }

  @override
  void dispose() {
    _saveOrderIfChanged();
    titleController.dispose();
    urlController.dispose();
    super.dispose();
  }

  Future<void> _saveOrderIfChanged() async {
    if (hasOrderChanged && playlist.videos.isNotEmpty) {
      try {
        final itemOrder = playlist.videos.map((v) => v.id).toList();
        await ApiService.reorderPlaylistItems(playlist.id, itemOrder);
      } catch (e) {
        print('Failed to save order: $e');
      }
    }
  }

  Future<void> addVideo() async {
    titleController.clear();
    urlController.clear();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: const Text('Add Item', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogTextField(titleController, 'Title', 'Video title'),
            const SizedBox(height: 14),
            _dialogTextField(urlController, 'URL', 'https://...', isUrl: true),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: VideoTermsButton(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.6))),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop({
              'title': titleController.text,
              'url': urlController.text,
            }),
            child: const Text('Add', style: TextStyle(color: Colors.cyan)),
          ),
        ],
      ),
    );

    if (result != null && result['url']!.isNotEmpty) {
      final title = result['title']!.isNotEmpty ? result['title']! : 'Untitled Item';
      setState(() => isLoading = true);
      try {
        final newVideo = await ApiService.addItemToPlaylist(
          playlist.id, title, result['url']!,
        );
        setState(() {
          playlist.videos.add(newVideo);
          isLoading = false;
        });
        widget.onPlaylistUpdated(playlist);
      } catch (e) {
        setState(() => isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _deleteVideo(int index) async {
    final video = playlist.videos[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: const Text('Remove Item', style: TextStyle(color: Colors.white)),
        content: Text(
          'Remove "${video.title}"?',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.6))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => isLoading = true);
      try {
        await ApiService.removeItemFromPlaylist(playlist.id, video.id);
        setState(() {
          playlist.videos.removeAt(index);
          isLoading = false;
        });
        widget.onPlaylistUpdated(playlist);
      } catch (e) {
        setState(() => isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _openPlayMode() {
    if (playlist.videos.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlaylistPlayerPage(playlist: playlist),
        ),
      );
    }
  }

  Future<void> _reorderVideos(int oldIndex, int newIndex) async {
    setState(() {
      if (oldIndex < newIndex) newIndex -= 1;
      final item = playlist.videos.removeAt(oldIndex);
      playlist.videos.insert(newIndex, item);
      hasOrderChanged = true;
    });
    widget.onPlaylistUpdated(playlist);
  }

  Widget _dialogTextField(
    TextEditingController controller,
    String label,
    String hint, {
    bool isUrl = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isUrl ? TextInputType.url : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          borderSide: const BorderSide(color: Colors.cyan),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.scaffoldGradient,
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildNavBar(),
                  _buildStickyPlayButton(),
                  Expanded(
                    child: playlist.videos.isEmpty
                        ? _buildEmptyState()
                        : _buildItemsList(),
                  ),
                  _buildStickyAddButton(),
                ],
              ),
              if (isLoading)
                Container(
                  color: Colors.black.withOpacity(0.4),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.cyan),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios, color: Colors.white.withOpacity(0.8), size: 20),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              playlist.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            onPressed: () => showFriendShareSheet(context),
            icon: Icon(Icons.ios_share, color: Colors.white.withOpacity(0.8), size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyPlayButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GestureDetector(
        onTap: playlist.videos.isNotEmpty ? _openPlayMode : null,
        child: GlassCard(
          radius: AppTheme.radiusSm,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Icon(
              Icons.play_arrow_rounded,
              size: 28,
              color: playlist.videos.isNotEmpty
                  ? Colors.white.withOpacity(0.85)
                  : Colors.white.withOpacity(0.2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStickyAddButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: GestureDetector(
        onTap: isLoading ? null : addVideo,
        child: GlassCard(
          radius: AppTheme.radiusSm,
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Center(
            child: Icon(
              Icons.add,
              color: Colors.white.withOpacity(0.5),
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.video_library_outlined, size: 64, color: Colors.white.withOpacity(0.15)),
          const SizedBox(height: 16),
          Text(
            'No items yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + below to add your first video',
            style: TextStyle(color: Colors.white.withOpacity(0.2)),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onReorder: _reorderVideos,
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) => Material(
            color: Colors.transparent,
            elevation: 0,
            child: child,
          ),
          child: child,
        );
      },
      itemCount: playlist.videos.length,
      itemBuilder: (context, index) {
        final video = playlist.videos[index];
        return _PlaylistItemRow(
          key: ValueKey(video.id),
          video: video,
          index: index,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlaylistPlayerPage(
                  playlist: playlist,
                  startIndex: index,
                ),
              ),
            );
          },
          onDelete: () => _deleteVideo(index),
        );
      },
    );
  }
}

// ── Item row (matches iOS PlaylistItemCard) ──
class _PlaylistItemRow extends StatelessWidget {
  final VideoItem video;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PlaylistItemRow({
    super.key,
    required this.video,
    required this.index,
    required this.onTap,
    required this.onDelete,
  });

  String get _displayHost {
    try {
      var host = Uri.parse(video.url).host;
      if (host.startsWith('www.')) host = host.substring(4);
      return host;
    } catch (_) {
      return video.url;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: () => _showContextMenu(context),
        child: GlassCard(
          radius: AppTheme.radiusSm,
          child: Row(
            children: [
              const SizedBox(width: 12),
              // Video info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _displayHost,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.25),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Drag handle
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(
                    Icons.drag_handle,
                    color: Colors.white.withOpacity(0.2),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              video.title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
