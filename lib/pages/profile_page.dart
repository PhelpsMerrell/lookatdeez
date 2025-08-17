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
      print('Loading user profile...');
      final profile = await ApiService.getCurrentUserProfile();
      print('Profile loaded: $profile');
      
      setState(() {
        userProfile = profile;
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      print('Profile API error: $e');
      
      // Fallback to local data if API fails
      try {
        final prefs = await SharedPreferences.getInstance();
        final fallbackProfile = {
          'displayName': prefs.getString('displayName') ?? 'Unknown User',
          'email': prefs.getString('email') ?? 'unknown@example.com',
          'id': prefs.getString('userId') ?? 'unknown',
          'createdAt': DateTime.now().toIso8601String(),
        };
        
        setState(() {
          userProfile = fallbackProfile;
          isLoading = false;
          errorMessage = 'Using offline data';
        });
      } catch (fallbackError) {
        print('Fallback error: $fallbackError');
        setState(() {
          userProfile = {
            'displayName': 'Error Loading Profile',
            'email': 'error@example.com',
            'id': 'error',
            'createdAt': DateTime.now().toIso8601String(),
          };
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
                      const Text('Failed to load profile'),
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
                      const SizedBox(height: 32),
                      // Debug info (remove in production)
                      if (userProfile != null) ...[
                        const Divider(),
                        const Text('Debug Info:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            userProfile.toString(),
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  String _getDisplayName() {
    return userProfile?['displayName']?.toString() ?? 'Unknown User';
  }

  String _getEmail() {
    return userProfile?['email']?.toString() ?? 'unknown@example.com';
  }

  String _getUserId() {
    return userProfile?['id']?.toString() ?? 'unknown';
  }

  DateTime? _getCreatedAt() {
    final createdAtStr = userProfile?['createdAt']?.toString();
    if (createdAtStr != null) {
      return DateTime.tryParse(createdAtStr);
    }
    return null;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
