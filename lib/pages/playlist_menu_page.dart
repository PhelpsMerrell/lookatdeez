import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/glass_theme.dart';
import 'friends_page.dart';
import 'login_page.dart';
import 'playlist_editor_page.dart';
import 'profile_page.dart';

class PlaylistMenuPage extends StatefulWidget {
  const PlaylistMenuPage({super.key});

  @override
  State<PlaylistMenuPage> createState() => _PlaylistMenuPageState();
}

class _PlaylistMenuPageState extends State<PlaylistMenuPage> {
  List<Playlist> playlists = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadPlaylists();
  }

  Future<void> loadPlaylists() async {
    setState(() => isLoading = true);
    try {
      final loadedPlaylists = await ApiService.getPlaylists();
      setState(() {
        playlists = loadedPlaylists;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading playlists: $e')),
        );
      }
    }
  }

  Future<void> createNewPlaylist() async {
    final nameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: const Text('New Playlist', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Playlist Name',
            labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              borderSide: const BorderSide(color: Colors.cyan),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.6))),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(nameController.text),
            child: const Text('Create', style: TextStyle(color: Colors.cyan)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        final newPlaylist = await ApiService.createPlaylist(result);
        setState(() => playlists.add(newPlaylist));
        if (mounted) _navigateToPlaylist(newPlaylist);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating playlist: $e')),
          );
        }
      }
    }
  }

  void _navigateToPlaylist(Playlist playlist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlaylistEditorPage(
          playlist: playlist,
          onPlaylistUpdated: (updated) {
            setState(() {
              final i = playlists.indexWhere((p) => p.id == updated.id);
              if (i != -1) playlists[i] = updated;
            });
          },
        ),
      ),
    ).then((_) => loadPlaylists());
  }

  Future<void> _deletePlaylist(int index) async {
    final playlist = playlists[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: const Text('Delete Playlist', style: TextStyle(color: Colors.white)),
        content: Text(
          'Delete "${playlist.name}"? This cannot be undone.',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.6))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.deletePlaylist(playlist.id);
        setState(() => playlists.removeAt(index));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting playlist: $e')),
          );
        }
      }
    }
  }

  void _openPlayMode(Playlist playlist) {
    if (playlist.videos.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlaylistEditorPage(
            playlist: playlist,
            onPlaylistUpdated: (updated) {
              setState(() {
                final i = playlists.indexWhere((p) => p.id == updated.id);
                if (i != -1) playlists[i] = updated;
              });
            },
            startInPlayMode: true,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.scaffoldGradient,
        child: SafeArea(
          child: Column(
            children: [
              // Toolbar
              _buildToolbar(),
              // Content
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.cyan))
                    : RefreshIndicator(
                        onRefresh: loadPlaylists,
                        color: Colors.cyan,
                        child: _buildPlaylistList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Spacer(),
          Text(
            'Look at Deez',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          PopupMenuButton<String>(
            icon: Icon(Icons.person_outline, color: Colors.white.withOpacity(0.8)),
            color: const Color(0xFF252536),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
                case 'friends':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const FriendsPage()));
                case 'signout':
                  _signOut();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'profile', child: _MenuRow(icon: Icons.account_circle_outlined, label: 'Profile')),
              PopupMenuItem(value: 'friends', child: _MenuRow(icon: Icons.group_outlined, label: 'Friends')),
              PopupMenuItem(value: 'signout', child: _MenuRow(icon: Icons.logout, label: 'Sign out')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: playlists.length + 1, // +1 for the add button row
      itemBuilder: (context, index) {
        // First row: Add button
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _AddPlaylistRow(onTap: createNewPlaylist),
          );
        }

        final playlistIndex = index - 1;
        final playlist = playlists[playlistIndex];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _PlaylistMenuRow(
            playlist: playlist,
            onTap: () => _navigateToPlaylist(playlist),
            onPlay: () => _openPlayMode(playlist),
            onDelete: () => _deletePlaylist(playlistIndex),
          ),
        );
      },
    );
  }

  void _signOut() async {
    try {
      await AuthService.logout();
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }
}

// ── Menu popup row ──
class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MenuRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}

// ── Add playlist row (matches iOS "+" button) ──
class _AddPlaylistRow extends StatelessWidget {
  final VoidCallback onTap;
  const _AddPlaylistRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
    );
  }
}

// ── Playlist row (matches iOS PlaylistMenuRow) ──
class _PlaylistMenuRow extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback onTap;
  final VoidCallback onPlay;
  final VoidCallback onDelete;

  const _PlaylistMenuRow({
    required this.playlist,
    required this.onTap,
    required this.onPlay,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        radius: AppTheme.radiusMd,
        child: Row(
          children: [
            // Left: text content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playlist.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.layers_outlined,
                            size: 13, color: Colors.white.withOpacity(0.45)),
                        const SizedBox(width: 4),
                        Text(
                          '${playlist.videos.length}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.45),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Right: play button
            GestureDetector(
              onTap: playlist.videos.isNotEmpty ? onPlay : null,
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                    width: 0.5,
                  ),
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  size: 20,
                  color: playlist.videos.isNotEmpty
                      ? Colors.white.withOpacity(0.7)
                      : Colors.white.withOpacity(0.15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
