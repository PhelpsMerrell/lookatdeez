import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/auth_config.dart';

class AuthService {
  static bool _isInitialized = false;
  
  // Initialize auth service
  static Future<void> initialize() async {
    try {
      _isInitialized = true;
      print('Auth service initialized');
      
      // Check if we're returning from Microsoft auth
      await _handleAuthCallback();
    } catch (e) {
      print('Auth initialization error: $e');
    }
  }
  
  // Handle auth callback from Microsoft
  static Future<void> _handleAuthCallback() async {
    try {
      // This would normally parse URL parameters for auth code
      // For now, we'll keep it simple and let the redirect handle it
      final currentUrl = Uri.base.toString();
      print('Current URL: $currentUrl');
      
      if (currentUrl.contains('/auth/callback')) {
        // We're in the callback - this means auth completed
        // In a real implementation, we'd parse the auth code here
        print('Auth callback detected');
      }
    } catch (e) {
      print('Callback handling error: $e');
    }
  }
  
  // Login with Microsoft (redirect approach)
  static Future<void> login() async {
    try {
      // Create Microsoft OAuth URL
      final authUrl = _buildAuthUrl();
      
      // Redirect to Microsoft login
      if (await canLaunchUrl(Uri.parse(authUrl))) {
        await launchUrl(
          Uri.parse(authUrl),
          mode: LaunchMode.platformDefault,
        );
      } else {
        throw Exception('Could not launch Microsoft login');
      }
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }
  
  // Build Microsoft OAuth URL
  static String _buildAuthUrl() {
    final params = {
      'client_id': AuthConfig.clientId,
      'response_type': 'code',
      'redirect_uri': AuthConfig.currentRedirectUri,
      'scope': AuthConfig.scopes.join(' '),
      'response_mode': 'query',
      'state': _generateState(),
    };
    
    final queryString = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    
    return '${AuthConfig.authority}/oauth2/v2.0/authorize?$queryString';
  }
  
  // Generate random state for security
  static String _generateState() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return 'state_$timestamp';
  }
  
  // For now, return null - in real implementation this would exchange auth code for token
  static Future<String?> getAccessToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('access_token');
    } catch (e) {
      print('Token acquisition error: $e');
      return null;
    }
  }
  
  // Get user info (mock for now)
  static Future<Map<String, dynamic>?> getUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      final userEmail = prefs.getString('userEmail');
      final userName = prefs.getString('userName');
      
      if (userId != null) {
        return {
          'id': userId,
          'email': userEmail,
          'name': userName,
        };
      }
      
      return null;
    } catch (e) {
      print('User info error: $e');
      return null;
    }
  }
  
  // Save user info (for testing)
  static Future<void> saveUserInfo(Map<String, dynamic> userInfo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', userInfo['id'] ?? '');
      await prefs.setString('userEmail', userInfo['email'] ?? '');
      await prefs.setString('userName', userInfo['name'] ?? '');
      await prefs.setString('access_token', userInfo['access_token'] ?? '');
    } catch (e) {
      print('Save user info error: $e');
    }
  }
  
  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      return userId != null && userId.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  // Logout
  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      // Redirect to Microsoft logout
      final logoutUrl = '${AuthConfig.authority}/oauth2/v2.0/logout?post_logout_redirect_uri=${Uri.encodeComponent(AuthConfig.currentRedirectUri)}';
      
      if (await canLaunchUrl(Uri.parse(logoutUrl))) {
        await launchUrl(
          Uri.parse(logoutUrl),
          mode: LaunchMode.platformDefault,
        );
      }
    } catch (e) {
      print('Logout error: $e');
    }
  }
  
  // Get stored user ID for API calls
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }
  
  // Get bearer token for API authorization
  static Future<String?> getBearerToken() async {
    final token = await getAccessToken();
    return token != null ? 'Bearer $token' : null;
  }
  
  // Mock login for testing (simulates successful Microsoft auth)
  static Future<void> mockMicrosoftLogin() async {
    try {
      // Simulate successful Microsoft login
      final mockUserInfo = {
        'id': 'microsoft-user-${DateTime.now().millisecondsSinceEpoch}',
        'email': 'user@outlook.com',
        'name': 'Microsoft User',
        'access_token': 'mock-access-token-${DateTime.now().millisecondsSinceEpoch}',
      };
      
      await saveUserInfo(mockUserInfo);
      print('Mock Microsoft login successful');
    } catch (e) {
      print('Mock login error: $e');
      rethrow;
    }
  }
}
