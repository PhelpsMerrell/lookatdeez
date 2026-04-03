import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/glass_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userProfile;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadUserProfile();
  }

  Future<void> loadUserProfile() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final profile = await ApiService.getCurrentUserProfile();
      setState(() {
        userProfile = profile;
        isLoading = false;
      });
    } catch (e) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final fallbackProfile = {
          'displayName': prefs.getString('userName') ?? 'Unknown User',
          'email': prefs.getString('userEmail') ?? 'unknown@example.com',
          'id': prefs.getString('microsoftUserId') ?? 'unknown',
          'createdAt': DateTime.now().toIso8601String(),
        };
        setState(() {
          userProfile = fallbackProfile;
          isLoading = false;
          errorMessage = 'Using offline data';
        });
      } catch (fallbackError) {
        setState(() {
          userProfile = null;
          isLoading = false;
          errorMessage = 'Failed to load profile: $e';
        });
      }
    }
  }

  String _getDisplayName() =>
      userProfile?['displayName']?.toString() ??
      userProfile?['DisplayName']?.toString() ??
      'Unknown User';

  String _getEmail() =>
      userProfile?['email']?.toString() ??
      userProfile?['Email']?.toString() ??
      'unknown@example.com';

  String _getUserId() =>
      userProfile?['id']?.toString() ??
      userProfile?['Id']?.toString() ??
      'unknown';

  DateTime? _getCreatedAt() {
    final str = (userProfile?['createdAt'] ?? userProfile?['CreatedAt'])?.toString();
    return str != null ? DateTime.tryParse(str) : null;
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

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
                        'Profile',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      onPressed: loadUserProfile,
                      icon: Icon(Icons.refresh, color: Colors.white.withOpacity(0.8), size: 20),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.cyan))
                    : userProfile == null
                        ? _buildError()
                        : _buildProfile(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.withOpacity(0.7)),
          const SizedBox(height: 16),
          Text(errorMessage ?? 'Failed to load', style: TextStyle(color: Colors.white.withOpacity(0.6))),
          const SizedBox(height: 16),
          TextButton(
            onPressed: loadUserProfile,
            child: const Text('Retry', style: TextStyle(color: Colors.cyan)),
          ),
        ],
      ),
    );
  }

  Widget _buildProfile() {
    final name = _getDisplayName();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (errorMessage != null) ...[
            GlassCard(
              radius: AppTheme.radiusSm,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange.withOpacity(0.8), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(errorMessage!,
                        style: TextStyle(color: Colors.orange.withOpacity(0.8), fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          // Avatar
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.cyan.withOpacity(0.2),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.cyan),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            _getEmail(),
            style: TextStyle(color: Colors.white.withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
          // Details card
          GlassCard(
            radius: AppTheme.radiusMd,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _detailRow('User ID', _getUserId()),
                if (_getCreatedAt() != null)
                  _detailRow('Member since', _formatDate(_getCreatedAt()!)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
