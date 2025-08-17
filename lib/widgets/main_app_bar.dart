import 'package:flutter/material.dart';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onOpenFriends;
  final VoidCallback? onSignOut;

  const MainAppBar({
    super.key,
    this.title = 'Video Playlists',
    this.onOpenProfile,
    this.onOpenFriends,
    this.onSignOut,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      centerTitle: true,
      actions: [
        PopupMenuButton<String>(
          tooltip: 'Profile & Friends',
          icon: const Icon(Icons.person_outline),
          onSelected: (value) {
            switch (value) {
              case 'profile':
                onOpenProfile?.call();
                break;
              case 'friends':
                onOpenFriends?.call();
                break;
              case 'signout':
                onSignOut?.call();
                break;
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'profile',
              child: ListTile(
                leading: Icon(Icons.account_circle_outlined),
                title: Text('Profile'),
              ),
            ),
            PopupMenuItem(
              value: 'friends',
              child: ListTile(
                leading: Icon(Icons.group_outlined),
                title: Text('Friends'),
              ),
            ),
            PopupMenuItem(
              value: 'signout',
              child: ListTile(
                leading: Icon(Icons.logout),
                title: Text('Sign out'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
