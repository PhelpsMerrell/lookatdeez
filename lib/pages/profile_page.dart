import 'package:flutter/material.dart';
import '../services/api_service.dart';
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
        errorMessage = null;
      });
    } catch (e) {
      print('Profile API error: $e');

      // Fallback to local data if API fails — using the correct keys
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
          errorMessage = 'Using offline data — backend may be unavailable';
        });
      } catch (fallbackError) {
        print('Fallback error: $fallbackError');
        setState(() {
          userProfile = null;
          isLoading = false;
          errorMessage = 'Failed to load profile: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadUserProfile,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userProfile == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(errorMessage ?? 'Failed to load profile'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: loadUserProfile,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      if (errorMessage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning, color: Colors.orange.shade700, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  errorMessage!,
                                  style: TextStyle(color: Colors.orange.shade700),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              child: Text(
                                _getDisplayName().isNotEmpty
                                    ? _getDisplayName()[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _getDisplayName(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getEmail(),
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'User ID: ${_getUserId()}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_getCreatedAt() != null)
                              Text(
                                'Member since: ${_formatDate(_getCreatedAt()!)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  String _getDisplayName() {
    // Handle both camelCase and PascalCase from backend
    return userProfile?['displayName']?.toString()
        ?? userProfile?['DisplayName']?.toString()
        ?? 'Unknown User';
  }

  String _getEmail() {
    return userProfile?['email']?.toString()
        ?? userProfile?['Email']?.toString()
        ?? 'unknown@example.com';
  }

  String _getUserId() {
    return userProfile?['id']?.toString()
        ?? userProfile?['Id']?.toString()
        ?? 'unknown';
  }

  DateTime? _getCreatedAt() {
    final createdAtStr = (userProfile?['createdAt'] ?? userProfile?['CreatedAt'])?.toString();
    if (createdAtStr != null) {
      return DateTime.tryParse(createdAtStr);
    }
    return null;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
