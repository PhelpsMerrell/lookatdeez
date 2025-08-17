import 'package:flutter/material.dart';
import '../pages/friends_page.dart';

/// Call this from your button: showFriendShareSheet(context);
Future<void> showFriendShareSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => const _FriendShareSheet(),
  );
}

class _FriendShareSheet extends StatelessWidget {
  const _FriendShareSheet();

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
              Expanded(child: Text('Share with…', style: theme.textTheme.titleLarge)),
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
      ),
    );
  }
}
