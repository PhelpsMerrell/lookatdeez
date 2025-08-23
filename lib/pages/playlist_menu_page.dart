import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/main_app_bar.dart';
import '../widgets/playlist_card.dart';
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
        title: const Text('Create New Playlist'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Playlist Name',
            hintText: 'Enter playlist name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(nameController.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        final newPlaylist = await ApiService.createPlaylist(result);
        setState(() {
          playlists.add(newPlaylist);
        });
        // Navigate to the new playlist
        if (mounted) {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  PlaylistEditorPage(
                playlist: newPlaylist,
                onPlaylistUpdated: (updatedPlaylist) {
                  setState(() {
                    final index = playlists.indexWhere(
                        (p) => p.id == updatedPlaylist.id);
                    if (index != -1) {
                      playlists[index] = updatedPlaylist;
                    }
                  });
                },
              ),
              transitionDuration: const Duration(milliseconds: 300),
            ),
          );
        }
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
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            PlaylistEditorPage(
          playlist: playlist,
          onPlaylistUpdated: (updatedPlaylist) {
            setState(() {
              final index = playlists.indexWhere(
                  (p) => p.id == updatedPlaylist.id);
              if (index != -1) {
                playlists[index] = updatedPlaylist;
              }
            });
          },
        ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  Future<void> _deletePlaylist(int index) async {
    final playlist = playlists[index];
    try {
      await ApiService.deletePlaylist(playlist.id);
      setState(() {
        playlists.removeAt(index);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting playlist: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(
    title: 'Video Playlists',
    onOpenProfile: () => Navigator.push(
      context, MaterialPageRoute(builder: (_) => const ProfilePage())),
    onOpenFriends: () => Navigator.push(
      context, MaterialPageRoute(builder: (_) => const FriendsPage())),
    onSignOut: _signOut, // your function
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
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.video_library_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Video Playlists',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage your TikToks, Reels & Shorts',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              // Create button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: createNewPlaylist,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.add_circle_outline, size: 24),
                    label: const Text(
                      'Create New Playlist',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Playlists Grid
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : playlists.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.playlist_add_outlined,
                                  size: 80,
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No playlists yet',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Create your first playlist to get started',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 1.2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: playlists.length,
                              itemBuilder: (context, index) {
                                final playlist = playlists[index];
                                return PlaylistCard(
                                  playlist: playlist,
                                  onTap: () => _navigateToPlaylist(playlist),
                                  onDelete: () => _deletePlaylist(index),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

void _signOut() async {
  try {
    // Call the auth service logout which clears tokens and redirects to Microsoft logout
    await AuthService.logout();
    
    // The logout method will redirect to Microsoft's logout page and then back to our app
    // so we don't need to navigate manually here
  } catch (e) {
    print('Sign out error: $e');
    
    // If there's an error, still try to navigate to login page
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }
}

}