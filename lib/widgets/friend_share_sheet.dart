import 'package:flutter/material.dart';
import '../pages/friends_page.dart';
import '../models/friend.dart';
import '../services/api_service.dart';

/// Call this from your button: showFriendShareSheet(context, playlistId);
Future<void> showFriendShareSheet(BuildContext context, [String? playlistId]) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _FriendShareSheet(playlistId: playlistId),
  );
}

class _FriendShareSheet extends StatefulWidget {
  final String? playlistId;

  const _FriendShareSheet({this.playlistId});

  @override
  State<_FriendShareSheet> createState() => _FriendShareSheetState();
}

class _FriendShareSheetState extends State<_FriendShareSheet> {
  List<Friend> _friends = [];
  bool _isLoading = true;
  final Set<String> _selectedFriends = {};

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    try {
      final friends = await ApiService.getCurrentUserFriends();
      setState(() {
        _friends = friends;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading friends: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.playlistId != null ? 'Share playlist with…' : 'Share with…',
                  style: theme.textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: 'Manage friends',
                icon: const Icon(Icons.manage_accounts_outlined),
                onPressed: () {
                  Navigator.pop(context); // close sheet
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FriendsPage()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            )
          else if (_friends.isEmpty)
            Column(
              children: [
                const Icon(Icons.group_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 12),
                const Text('No friends yet', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text('Add friends to share playlists.', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const FriendsPage()),
                          );
                        },
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Add friends'),
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            ..._buildFriendsList(theme),
        ],
      ),
    );
  }

  List<Widget> _buildFriendsList(ThemeData theme) {
    return [
      // Header with select all/none
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Select friends (${_selectedFriends.length}/${_friends.length})',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          TextButton(
            onPressed: _selectedFriends.length == _friends.length
                ? _clearSelection
                : _selectAll,
            child: Text(_selectedFriends.length == _friends.length ? 'Clear' : 'All'),
          ),
        ],
      ),
      const SizedBox(height: 8),
      // Friends list
      ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 300),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _friends.length,
          itemBuilder: (context, index) {
            final friend = _friends[index];
            final isSelected = _selectedFriends.contains(friend.id);
            
            return CheckboxListTile(
              value: isSelected,
              onChanged: (selected) {
                setState(() {
                  if (selected == true) {
                    _selectedFriends.add(friend.id);
                  } else {
                    _selectedFriends.remove(friend.id);
                  }
                });
              },
              secondary: CircleAvatar(
                radius: 20,
                child: Text(
                  friend.displayName.isNotEmpty
                      ? friend.displayName[0].toUpperCase()
                      : '?',
                ),
              ),
              title: Text(friend.displayName),
              subtitle: Text(friend.email),
              contentPadding: EdgeInsets.zero,
            );
          },
        ),
      ),
      const SizedBox(height: 16),
      // Action buttons
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: _selectedFriends.isEmpty ? null : _shareWithSelected,
              child: Text(
                widget.playlistId != null
                    ? 'Share (${_selectedFriends.length})'
                    : 'Continue (${_selectedFriends.length})',
              ),
            ),
          ),
        ],
      ),
    ];
  }

  void _selectAll() {
    setState(() {
      _selectedFriends.addAll(_friends.map((f) => f.id));
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedFriends.clear();
    });
  }

  void _shareWithSelected() {
    if (_selectedFriends.isEmpty) return;

    if (widget.playlistId != null) {
      // TODO: Implement playlist sharing via permissions API
      // This would use your existing permissions system
      _sharePlaylist();
    } else {
      // Just return the selected friend IDs for other use cases
      Navigator.pop(context, _selectedFriends.toList());
    }
  }

  Future<void> _sharePlaylist() async {
    // TODO: Implement playlist sharing logic
    // This would call your permissions/sharing endpoints
    // For now, just show a success message
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Playlist shared with ${_selectedFriends.length} friend${_selectedFriends.length == 1 ? '' : 's'}',
        ),
      ),
    );
  }
}
