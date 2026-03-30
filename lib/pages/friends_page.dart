import 'package:flutter/material.dart';
import '../models/friend.dart';
import '../services/api_service.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Friend> _friends = [];
  FriendRequestsEnvelope? _requests;
  bool _isLoading = true;
  String? _loadError;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      print('Loading friends data...');
      
      // Load friends and requests separately to better handle errors
      List<Friend> friendsList = [];
      FriendRequestsEnvelope? requestsEnvelope;
      
      try {
        print('Fetching current user friends...');
        friendsList = await ApiService.getCurrentUserFriends();
        print('Friends loaded: ${friendsList.length}');
      } catch (e) {
        print('Error loading friends: $e');
        // Continue loading requests even if friends fail
      }
      
      try {
        print('Fetching friend requests...');
        requestsEnvelope = await ApiService.getFriendRequests();
        print('Requests loaded - Sent: ${requestsEnvelope.sent.length}, Received: ${requestsEnvelope.received.length}');
      } catch (e) {
        print('Error loading friend requests: $e');
        requestsEnvelope = FriendRequestsEnvelope(sent: [], received: []);
      }
      
      setState(() {
        _friends = friendsList;
        _requests = requestsEnvelope;
        _isLoading = false;
      });
    } catch (e) {
      print('Unexpected error in _loadData: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading friends: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  List<Friend> get _filteredFriends {
    if (_searchQuery.isEmpty) return _friends;
    return _friends.where((friend) =>
      friend.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      friend.email.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  int get _pendingCount =>
      _requests?.received.where((r) => r.status == FriendRequestStatus.pending).length ?? 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'Friends (${_friends.length})',
              icon: const Icon(Icons.group),
            ),
            Tab(
              text: 'Received ($_pendingCount)',
              icon: const Icon(Icons.inbox),
            ),
            const Tab(
              text: 'Add Friends',
              icon: Icon(Icons.person_add),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? _buildErrorState()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildFriendsTab(),
                    _buildRequestsTab(),
                    _buildAddFriendsTab(),
                  ],
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Failed to load friends',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _loadError!,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsTab() {
    return Column(
      children: [
        if (_friends.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search friends...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
        ],
        Expanded(
          child: _filteredFriends.isEmpty
              ? _buildEmptyState(
                  icon: Icons.group_outlined,
                  title: _friends.isEmpty ? 'No friends yet' : 'No friends found',
                  subtitle: _friends.isEmpty
                      ? 'Add friends to start sharing playlists'
                      : 'Try a different search term',
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    itemCount: _filteredFriends.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final friend = _filteredFriends[index];
                      return _buildFriendCard(friend);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildRequestsTab() {
    final pendingRequests = _requests?.received
        .where((r) => r.status == FriendRequestStatus.pending)
        .toList() ?? [];

    return pendingRequests.isEmpty
        ? _buildEmptyState(
            icon: Icons.inbox_outlined,
            title: 'No pending requests',
            subtitle: 'Friend requests will appear here',
          )
        : RefreshIndicator(
            onRefresh: _loadData,
            child: ListView.builder(
              itemCount: pendingRequests.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final request = pendingRequests[index];
                return _buildRequestCard(request);
              },
            ),
          );
  }

  Widget _buildAddFriendsTab() {
    return _AddFriendsView(
      friends: _friends,
      requests: _requests,
      onRequestSent: _loadData,
    );
  }

  Widget _buildFriendCard(Friend friend) {
    final displayName = friend.displayName.isNotEmpty ? friend.displayName : friend.email;
    final avatar = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Text(
            avatar,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
          ),
        ),
        title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (friend.displayName.isNotEmpty && friend.displayName != friend.email)
              Text(friend.email, style: const TextStyle(fontSize: 12)),
            Text(
              'Friends since ${_formatDate(friend.friendsSince)}',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'remove',
              child: Row(
                children: [
                  Icon(Icons.person_remove, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Remove friend'),
                ],
              ),
            ),
          ],
          onSelected: (value) => _removeFriend(friend),
        ),
      ),
    );
  }

  Widget _buildRequestCard(FriendRequest request) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            request.fromUserDisplayName.isNotEmpty
                ? request.fromUserDisplayName[0].toUpperCase()
                : '?',
          ),
        ),
        title: Text(request.fromUserDisplayName),
        subtitle: Text('Sent ${_formatDate(request.requestedAt)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: () => _respondToRequest(request, FriendRequestStatus.accepted),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () => _respondToRequest(request, FriendRequestStatus.declined),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Future<void> _removeFriend(Friend friend) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Friend'),
        content: Text('Remove ${friend.displayName} from your friends?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.removeFriend(friend.id);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${friend.displayName} removed from friends')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error removing friend: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _respondToRequest(FriendRequest request, FriendRequestStatus status) async {
    try {
      await ApiService.updateFriendRequest(request.id, status);
      await _loadData();

      if (mounted) {
        final action = status == FriendRequestStatus.accepted ? 'accepted' : 'declined';
        final name = request.fromUserDisplayName.isNotEmpty
            ? request.fromUserDisplayName
            : 'Friend request';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name $action'),
            backgroundColor: status == FriendRequestStatus.accepted ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error responding to request: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }
}

/// Add friends tab — receives parent data instead of fetching its own copy.
class _AddFriendsView extends StatefulWidget {
  final List<Friend> friends;
  final FriendRequestsEnvelope? requests;
  final VoidCallback onRequestSent;

  const _AddFriendsView({
    required this.friends,
    required this.requests,
    required this.onRequestSent,
  });

  @override
  State<_AddFriendsView> createState() => _AddFriendsViewState();
}

class _AddFriendsViewState extends State<_AddFriendsView> {
  final TextEditingController _searchController = TextEditingController();
  List<User> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      final results = await ApiService.searchUsers(query.trim());
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _getUserStatus(User user) {
    if (widget.friends.any((friend) => friend.id == user.id)) {
      return 'friends';
    }

    if (widget.requests?.sent.any((r) =>
        r.toUserId == user.id && r.status == FriendRequestStatus.pending) == true) {
      return 'request_sent';
    }

    if (widget.requests?.received.any((r) =>
        r.fromUserId == user.id && r.status == FriendRequestStatus.pending) == true) {
      return 'request_received';
    }

    return 'none';
  }

  Widget _buildActionButton(User user, String status) {
    switch (status) {
      case 'friends':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green[300]!),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: 16, color: Colors.green[700]),
              const SizedBox(width: 4),
              Text('Friends',
                  style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w500, fontSize: 12)),
            ],
          ),
        );
      case 'request_sent':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange[300]!),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.schedule, size: 16, color: Colors.orange[700]),
              const SizedBox(width: 4),
              Text('Pending',
                  style: TextStyle(color: Colors.orange[700], fontWeight: FontWeight.w500, fontSize: 12)),
            ],
          ),
        );
      case 'request_received':
        return OutlinedButton.icon(
          onPressed: () {
            final parentState = context.findAncestorStateOfType<_FriendsPageState>();
            parentState?._tabController.animateTo(1);
          },
          icon: const Icon(Icons.inbox, size: 16),
          label: const Text('View Request', style: TextStyle(fontSize: 12)),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.blue,
            side: BorderSide(color: Colors.blue[300]!),
          ),
        );
      default:
        return ElevatedButton.icon(
          onPressed: () => _sendFriendRequest(user),
          icon: const Icon(Icons.person_add, size: 16),
          label: const Text('Add', style: TextStyle(fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search by name or email...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: _searchUsers,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _searchUsers(_searchController.text),
                icon: const Icon(Icons.search),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        if (_isSearching)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_searchResults.isEmpty && _hasSearched)
          const Expanded(
            child: Center(child: Text('No users found. Try a different search term.')),
          )
        else if (_searchResults.isEmpty)
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_search, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Search for friends',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  SizedBox(height: 8),
                  Text('Enter a name or email to find friends',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final user = _searchResults[index];
                final status = _getUserStatus(user);
                final displayName = user.displayName.isNotEmpty ? user.displayName : user.email;

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue[100],
                      child: Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ),
                    title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: user.displayName.isNotEmpty && user.displayName != user.email
                        ? Text(user.email, style: const TextStyle(fontSize: 12))
                        : null,
                    trailing: _buildActionButton(user, status),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Future<void> _sendFriendRequest(User user) async {
    try {
      await ApiService.sendFriendRequest(user.id);
      widget.onRequestSent();

      if (mounted) {
        final displayName = user.displayName.isNotEmpty ? user.displayName : user.email;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Friend request sent to $displayName'),
            backgroundColor: Colors.green,
          ),
        );
        // Re-search to update button states
        _searchUsers(_searchController.text);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage;
        Color backgroundColor;

        if (e is FriendRequestException) {
          if (e.message.toLowerCase().contains('already friends')) {
            errorMessage = '${user.displayName} is already your friend!';
            backgroundColor = Colors.orange;
          } else if (e.message.toLowerCase().contains('pending')) {
            errorMessage = 'Friend request to ${user.displayName} is already pending';
            backgroundColor = Colors.orange;
          } else if (e.message.toLowerCase().contains('yourself')) {
            errorMessage = "You can't send a friend request to yourself";
            backgroundColor = Colors.orange;
          } else {
            errorMessage = e.message;
            backgroundColor = Colors.red;
          }
        } else {
          errorMessage = 'Failed to send friend request. Please try again.';
          backgroundColor = Colors.red;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: backgroundColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
