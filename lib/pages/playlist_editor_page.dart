import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../models/video_item.dart';
import '../services/api_service.dart';
import '../widgets/video_card.dart';
import '../widgets/friend_share_sheet.dart';
import '../widgets/video_terms_dialog.dart';
import 'playlist_player_page.dart';

class PlaylistEditorPage extends StatefulWidget {
  final Playlist playlist;
  final Function(Playlist) onPlaylistUpdated;

  const PlaylistEditorPage({
    super.key,
    required this.playlist,
    required this.onPlaylistUpdated,
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
    print('=== PlaylistEditorPage initialized ===');
    print('Widget playlist ID: "${widget.playlist.id}"');
    print('Widget playlist name: "${widget.playlist.name}"');
    print('Local playlist ID: "${playlist.id}"');
    print('Local playlist name: "${playlist.name}"');
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
        final itemOrder = playlist.videos.map((video) => video.id).toList();
        await ApiService.reorderPlaylistItems(playlist.id, itemOrder);
        print('Order saved successfully');
      } catch (e) {
        print('Failed to save order: $e');
        // Note: We don't show a snackbar here since the widget might be disposed
      }
    }
  }

  Future<void> addVideo() async {
    titleController.clear();
    urlController.clear();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Video'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Enter video title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'URL',
                hintText: 'https://...',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Supported: YouTube, Instagram, TikTok, Vimeo, Twitch, direct video files',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: VideoTermsButton(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop({
              'title': titleController.text,
              'url': urlController.text,
            }),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null &&
        result['title']!.isNotEmpty &&
        result['url']!.isNotEmpty) {
      
      setState(() => isLoading = true);
      
      try {
        print('=== About to call API addItemToPlaylist ===');
        print('Using playlist ID: "${playlist.id}"');
        print('Title: "${result['title']!}"');
        print('URL: "${result['url']!}"');
        
        // Call your actual API to add the item
        final newVideo = await ApiService.addItemToPlaylist(
          playlist.id,
          result['title']!,
          result['url']!,
        );

        setState(() {
          playlist.videos.add(newVideo);
          isLoading = false;
        });

        widget.onPlaylistUpdated(playlist);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Video added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        setState(() => isLoading = false);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding video: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteVideo(int index) async {
    final video = playlist.videos[index];
    
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Video'),
        content: Text('Remove "${video.title}" from this playlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
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
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Video removed successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        setState(() => isLoading = false);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error removing video: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showShareSheet() {
    // This shows the sheet; no need to wrap it in another showModalBottomSheet
    showFriendShareSheet(context);
  }

  void _openPlayMode() {
    if (playlist.videos.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlaylistPlayerPage(playlist: playlist),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add some videos first to start playing'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _reorderVideos(int oldIndex, int newIndex) async {
    setState(() {
      // Adjust newIndex if moving down
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      
      final VideoItem item = playlist.videos.removeAt(oldIndex);
      playlist.videos.insert(newIndex, item);
      
      // Mark that order has changed
      hasOrderChanged = true;
    });
    
    widget.onPlaylistUpdated(playlist);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: isLoading ? null : addVideo,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        child: const Icon(Icons.add),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Top action bar
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Icons.arrow_back_ios),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  onPressed: _showShareSheet,
                                  icon: const Icon(Icons.share_rounded),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer
                                        .withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            
                            // Playlist icon and info - now a play button
                            GestureDetector(
                              onTap: _openPlayMode,
                              child: Hero(
                                tag: 'playlist-icon-${playlist.id}',
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: playlist.videos.isNotEmpty 
                                        ? Colors.green.withOpacity(0.2)
                                        : Theme.of(context).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(20),
                                    border: playlist.videos.isNotEmpty 
                                        ? Border.all(color: Colors.green, width: 2)
                                        : null,
                                  ),
                                  child: Icon(
                                    playlist.videos.isNotEmpty 
                                        ? Icons.play_circle_fill
                                        : Icons.playlist_play,
                                    color: playlist.videos.isNotEmpty 
                                        ? Colors.green
                                        : Theme.of(context).colorScheme.primary,
                                    size: 40,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            Text(
                              playlist.name,
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${playlist.videos.length} videos',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Video list or empty state
                  if (playlist.videos.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.video_call_outlined,
                              size: 80,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No videos yet',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add your first video to get started',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: addVideo,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Video'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: ReorderableListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          onReorder: _reorderVideos,
                          itemCount: playlist.videos.length,
                          itemBuilder: (context, index) {
                            final video = playlist.videos[index];
                            return Container(
                              key: ValueKey(video.id),
                              margin: const EdgeInsets.only(bottom: 12),
                              child: VideoCard(
                                video: video,
                                onDelete: () => _deleteVideo(index),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
              
              // Loading overlay
              if (isLoading)
                Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
