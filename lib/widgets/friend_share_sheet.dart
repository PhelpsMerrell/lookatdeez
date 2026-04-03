import 'package:flutter/material.dart';
import '../pages/friends_page.dart';
import '../models/friend.dart';
import '../services/api_service.dart';
import '../theme/glass_theme.dart';

/// Call this from your button: showFriendShareSheet(context, playlistId);
Future<void> showFriendShareSheet(BuildContext context, [String? playlistId]) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: const Color(0xFF1A1A28),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Manage friends',
                icon: Icon(Icons.manage_accounts_outlined, color: Colors.white.withOpacity(0.6)),
                onPressed: () {
                  Navigator.pop(context);
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
              child: CircularProgressIndicator(color: Colors.cyan),
            )
          else if (_friends.isEmpty)
            Column(
              children: [
                Icon(Icons.group_outlined, size: 64, color: Colors.white.withOpacity(0.15)),
                const SizedBox(height: 12),
                const Text('No friends yet',
                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 4),
                Text('Add friends to share playlists.',
                    style: TextStyle(color: Colors.white.withOpacity(0.5)),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white.withOpacity(0.7),
                          side: BorderSide(color: Colors.white.withOpacity(0.2)),
                        ),
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
                        icon: const Icon(Icons.person_add_alt_1, size: 18),
                        label: const Text('Add friends'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.cyan.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            ..._buildFriendsList(),
        ],
      ),
    );
  }

  List<Widget> _buildFriendsList() {
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Select friends (${_selectedFriends.length}/${_friends.length})',
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
          ),
          TextButton(
            onPressed: _selectedFriends.length == _friends.length
                ? _clearSelection
                : _selectAll,
            child: Text(
              _selectedFriends.length == _friends.length ? 'Clear' : 'All',
              style: const TextStyle(color: Colors.cyan),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 300),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _friends.length,
          itemBuilder: (context, index) {
            final friend = _friends[index];
            final isSelected = _selectedFriends.contains(friend.id);

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedFriends.remove(friend.id);
                    } else {
                      _selectedFriends.add(friend.id);
                    }
                  });
                },
                child: GlassCard(
                  radius: AppTheme.radiusSm,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      // Checkbox
                      Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color: isSelected ? Colors.cyan : Colors.white.withOpacity(0.3),
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.cyan.withOpacity(0.15),
                        child: Text(
                          friend.displayName.isNotEmpty
                              ? friend.displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: Colors.cyan, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(friend.displayName,
                                style: const TextStyle(
                                    color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14)),
                            Text(friend.email,
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.35), fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white.withOpacity(0.7),
                side: BorderSide(color: Colors.white.withOpacity(0.2)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
              ),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: _selectedFriends.isEmpty ? null : _shareWithSelected,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.cyan.withOpacity(0.8),
                disabledBackgroundColor: Colors.cyan.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
              ),
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
    setState(() => _selectedFriends.addAll(_friends.map((f) => f.id)));
  }

  void _clearSelection() {
    setState(() => _selectedFriends.clear());
  }

  void _shareWithSelected() {
    if (_selectedFriends.isEmpty) return;

    if (widget.playlistId != null) {
      _sharePlaylist();
    } else {
      Navigator.pop(context, _selectedFriends.toList());
    }
  }

  Future<void> _sharePlaylist() async {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Playlist shared with ${_selectedFriends.length} friend${_selectedFriends.length == 1 ? '' : 's'}',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }
}
