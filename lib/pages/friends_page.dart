import 'package:flutter/material.dart';
import '../models/friend.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/glass_theme.dart';

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
    setState(() { _isLoading = true; _loadError = null; });
    try {
      List<Friend> friendsList = [];
      FriendRequestsEnvelope? requestsEnvelope;

      try {
        friendsList = await ApiService.getCurrentUserFriends();
      } catch (e) {
        print('Error loading friends: $e');
      }

      try {
        requestsEnvelope = await ApiService.getFriendRequests();
      } catch (e) {
        requestsEnvelope = FriendRequestsEnvelope(sent: [], received: []);
      }

      setState(() {
        _friends = friendsList;
        _requests = requestsEnvelope;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<Friend> get _filteredFriends {
    if (_searchQuery.isEmpty) return _friends;
    return _friends.where((f) =>
      f.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      f.email.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  int get _pendingCount =>
      _requests?.received.where((r) => r.status == FriendRequestStatus.pending).length ?? 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.scaffoldGradient,
        child: SafeArea(
          child: Column(
            children: [
              // Nav bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back_ios, color: Colors.white.withOpacity(0.8), size: 20),
                    ),
                    const Expanded(
                      child: Text(
                        'Friends',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),
              // Tabs
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.cyan,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withOpacity(0.4),
                tabs: [
                  Tab(text: 'Friends (${_friends.length})'),
                  Tab(text: 'Requests ($_pendingCount)'),
                  const Tab(text: 'Add'),
                ],
              ),
              // Content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.cyan))
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
              ),
            ],
          ),
        ),
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
            Icon(Icons.cloud_off, size: 64, color: Colors.red.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text('Failed to load', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 8),
            Text(_loadError!, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh, color: Colors.cyan),
              label: const Text('Retry', style: TextStyle(color: Colors.cyan)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsTab() {
    return Column(
      children: [
        if (_friends.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: _glassTextField(
              controller: _searchController,
              hint: 'Search friends...',
              prefixIcon: Icons.search,
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
        Expanded(
          child: _filteredFriends.isEmpty
              ? _emptyState(
                  icon: Icons.group_outlined,
                  title: _friends.isEmpty ? 'No friends yet' : 'No results',
                  subtitle: _friends.isEmpty ? 'Add friends to share playlists' : 'Try a different search',
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: Colors.cyan,
                  child: ListView.builder(
                    itemCount: _filteredFriends.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (_, i) => _buildFriendCard(_filteredFriends[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildRequestsTab() {
    final pending = _requests?.received
        .where((r) => r.status == FriendRequestStatus.pending)
        .toList() ?? [];

    return pending.isEmpty
        ? _emptyState(icon: Icons.inbox_outlined, title: 'No pending requests', subtitle: 'Requests will appear here')
        : RefreshIndicator(
            onRefresh: _loadData,
            color: Colors.cyan,
            child: ListView.builder(
              itemCount: pending.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (_, i) => _buildRequestCard(pending[i]),
            ),
          );
  }

  Widget _buildAddFriendsTab() {
    return _AddFriendsView(
      friends: _friends,
      requests: _requests,
      onRequestSent: _loadData,
      tabController: _tabController,
    );
  }

  Widget _buildFriendCard(Friend friend) {
    final name = friend.displayName.isNotEmpty ? friend.displayName : friend.email;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        radius: AppTheme.radiusSm,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.cyan.withOpacity(0.15),
              child: Text(name[0].toUpperCase(), style: const TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                  if (friend.displayName.isNotEmpty && friend.displayName != friend.email)
                    Text(friend.email, style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12)),
                  Text('Friends since ${_formatDate(friend.friendsSince)}',
                      style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 11)),
                ],
              ),
            ),
            PopupMenuButton(
              icon: Icon(Icons.more_vert, color: Colors.white.withOpacity(0.4)),
              color: const Color(0xFF252536),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(children: [
                    Icon(Icons.person_remove, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Text('Remove', style: TextStyle(color: Colors.red)),
                  ]),
                ),
              ],
              onSelected: (_) => _removeFriend(friend),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(FriendRequest request) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        radius: AppTheme.radiusSm,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.blue.withOpacity(0.15),
              child: Text(
                request.fromUserDisplayName.isNotEmpty ? request.fromUserDisplayName[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(request.fromUserDisplayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                  Text('Sent ${_formatDate(request.requestedAt)}',
                      style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.check_circle_outline, color: Colors.green),
              onPressed: () => _respondToRequest(request, FriendRequestStatus.accepted),
            ),
            IconButton(
              icon: Icon(Icons.cancel_outlined, color: Colors.red.withOpacity(0.7)),
              onPressed: () => _respondToRequest(request, FriendRequestStatus.declined),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.white.withOpacity(0.15)),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.4))),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.25))),
        ],
      ),
    );
  }

  Widget _glassTextField({
    required TextEditingController controller,
    required String hint,
    IconData? prefixIcon,
    ValueChanged<String>? onChanged,
    VoidCallback? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      onChanged: onChanged,
      onSubmitted: onSubmitted != null ? (_) => onSubmitted() : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.white.withOpacity(0.4)) : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          borderSide: const BorderSide(color: Colors.cyan),
        ),
      ),
    );
  }

  Future<void> _removeFriend(Friend friend) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        title: const Text('Remove Friend', style: TextStyle(color: Colors.white)),
        content: Text('Remove ${friend.displayName}?', style: TextStyle(color: Colors.white.withOpacity(0.7))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.6)))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.removeFriend(friend.id);
        await _loadData();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _respondToRequest(FriendRequest request, FriendRequestStatus status) async {
    try {
      await ApiService.updateFriendRequest(request.id, status);
      await _loadData();
      if (mounted) {
        final action = status == FriendRequestStatus.accepted ? 'accepted' : 'declined';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${request.fromUserDisplayName} $action'),
            backgroundColor: status == FriendRequestStatus.accepted ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }
}

/// Add friends tab
class _AddFriendsView extends StatefulWidget {
  final List<Friend> friends;
  final FriendRequestsEnvelope? requests;
  final VoidCallback onRequestSent;
  final TabController tabController;

  const _AddFriendsView({
    required this.friends,
    required this.requests,
    required this.onRequestSent,
    required this.tabController,
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
    setState(() { _isSearching = true; _hasSearched = true; });
    try {
      final results = await ApiService.searchUsers(query.trim());
      if (mounted) setState(() { _searchResults = results; _isSearching = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  String _getUserStatus(User user) {
    if (widget.friends.any((f) => f.id == user.id)) return 'friends';
    if (widget.requests?.sent.any((r) => r.toUserId == user.id && r.status == FriendRequestStatus.pending) == true) return 'request_sent';
    if (widget.requests?.received.any((r) => r.fromUserId == user.id && r.status == FriendRequestStatus.pending) == true) return 'request_received';
    return 'none';
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
                  style: const TextStyle(color: Colors.white),
                  onSubmitted: _searchUsers,
                  decoration: InputDecoration(
                    hintText: 'Search by name or email...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.4)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.06),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      borderSide: const BorderSide(color: Colors.cyan),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _searchUsers(_searchController.text),
                child: GlassCard(
                  radius: AppTheme.radiusSm,
                  padding: const EdgeInsets.all(12),
                  child: const Icon(Icons.search, color: Colors.cyan, size: 20),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isSearching
              ? const Center(child: CircularProgressIndicator(color: Colors.cyan))
              : _searchResults.isEmpty && _hasSearched
                  ? Center(child: Text('No users found', style: TextStyle(color: Colors.white.withOpacity(0.4))))
                  : _searchResults.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_search, size: 64, color: Colors.white.withOpacity(0.15)),
                              const SizedBox(height: 16),
                              Text('Search for friends', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.4))),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _searchResults.length,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemBuilder: (_, i) {
                            final user = _searchResults[i];
                            final status = _getUserStatus(user);
                            final name = user.displayName.isNotEmpty ? user.displayName : user.email;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: GlassCard(
                                radius: AppTheme.radiusSm,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.blue.withOpacity(0.15),
                                      child: Text(name[0].toUpperCase(), style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                                          if (user.displayName.isNotEmpty && user.displayName != user.email)
                                            Text(user.email, style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    _buildStatusWidget(user, status),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }

  Widget _buildStatusWidget(User user, String status) {
    switch (status) {
      case 'friends':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Text('Friends', style: TextStyle(color: Colors.green.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500)),
        );
      case 'request_sent':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Text('Pending', style: TextStyle(color: Colors.orange.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500)),
        );
      case 'request_received':
        return GestureDetector(
          onTap: () => widget.tabController.animateTo(1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Text('View Request', style: TextStyle(color: Colors.blue.withOpacity(0.8), fontSize: 12)),
          ),
        );
      default:
        return GestureDetector(
          onTap: () => _sendFriendRequest(user),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.cyan.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.cyan.withOpacity(0.3)),
            ),
            child: const Text('Add', style: TextStyle(color: Colors.cyan, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        );
    }
  }

  Future<void> _sendFriendRequest(User user) async {
    try {
      await AuthService.ensureUserExists();
      await ApiService.sendFriendRequest(user.id);
      widget.onRequestSent();
      if (mounted) {
        final name = user.displayName.isNotEmpty ? user.displayName : user.email;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request sent to $name'), backgroundColor: Colors.green),
        );
        _searchUsers(_searchController.text);
      }
    } catch (e) {
      if (mounted) {
        String msg;
        Color bg;
        if (e is FriendRequestException) {
          msg = e.message;
          bg = Colors.orange;
        } else {
          msg = 'Failed: $e';
          bg = Colors.red;
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: bg));
      }
    }
  }
}
