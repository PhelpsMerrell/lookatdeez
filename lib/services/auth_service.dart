import 'dart:convert';
import 'dart:html' as html;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import '../config/auth_config.dart';

class AuthService {
  static const String _accessTokenKey = 'ms_access_token';
  static const String _refreshTokenKey = 'ms_refresh_token';
  static const String _tokenExpiryKey = 'ms_token_expiry';
  static const String _userInfoKey = 'ms_user_info';
  
  static Future<void> initialize() async {
    await _handleAuthCallback();
  }
  
  static Future<void> _handleAuthCallback() async {
    final currentUrl = Uri.base;
    if (currentUrl.path == '/auth/callback') {
      final code = currentUrl.queryParameters['code'];
      final error = currentUrl.queryParameters['error'];
      
      if (error != null) {
        print('OAuth error: $error');
        throw Exception('Auth error: $error');
      }
      
      if (code != null) {
        print('Received OAuth code, exchanging for tokens...');
        await _exchangeCodeForTokens(code);
        print('Token exchange complete, redirecting to main app');
        // Navigate to main page after successful authentication
        html.window.location.href = '/';
      }
    }
  }
  
  static Future<void> login() async {
    final authUrl = _buildAuthUrl();
    html.window.location.href = authUrl;
  }
  
  static String _buildAuthUrl() {
    final params = {
      'client_id': AuthConfig.clientId,
      'response_type': 'code',
      'redirect_uri': AuthConfig.currentRedirectUri,
      'scope': AuthConfig.scopes.join(' '),
      'response_mode': 'query',
      'state': 'state_${DateTime.now().millisecondsSinceEpoch}',
    };
    
    print('=== Building Auth URL ===');
    print('Client ID: ${AuthConfig.clientId}');
    print('Redirect URI: ${AuthConfig.currentRedirectUri}');
    print('Authority: ${AuthConfig.authority}');
    print('Scopes: ${AuthConfig.scopes.join(' ')}');
    
    final queryString = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    
    final authUrl = '${AuthConfig.authority}/oauth2/v2.0/authorize?$queryString';
    print('Full Auth URL: $authUrl');
    return authUrl;
  }
  
  static Future<void> _exchangeCodeForTokens(String code) async {
    final tokenUrl = '${AuthConfig.authority}/oauth2/v2.0/token';
    
    print('Exchanging code for tokens at: $tokenUrl');
    
    final body = {
      'client_id': AuthConfig.clientId,
      'code': code,
      'redirect_uri': AuthConfig.currentRedirectUri,
      'grant_type': 'authorization_code',
      'scope': AuthConfig.scopes.join(' '),
    };
    
    print('Token exchange body: $body');
    
    final response = await http.post(
      Uri.parse(tokenUrl),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&'),
    );
    
    print('Token response status: ${response.statusCode}');
    print('Token response body: ${response.body}');
    
    if (response.statusCode == 200) {
      final tokenData = json.decode(response.body);
      
      final accessToken = tokenData['access_token'] as String;
      final refreshToken = tokenData['refresh_token'] as String?;
      final expiresIn = tokenData['expires_in'] as int;
      
      final expiryTime = DateTime.now().add(Duration(seconds: expiresIn));
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessTokenKey, accessToken);
      if (refreshToken != null) {
        await prefs.setString(_refreshTokenKey, refreshToken);
      }
      await prefs.setString(_tokenExpiryKey, expiryTime.toIso8601String());
      
      // Extract user info from JWT token
      final userInfo = _extractUserInfoFromToken(accessToken);
      await _storeUserInfo(userInfo);
      
      // Ensure user exists in backend after token exchange
      await ensureUserExists();
    } else {
      // More detailed error logging
      try {
        final errorData = json.decode(response.body);
        print('Detailed error from Microsoft:');
        print('  Error: ${errorData['error']}');
        print('  Error Description: ${errorData['error_description']}');
        print('  Error URI: ${errorData['error_uri']}');
        throw Exception('Token exchange failed: ${errorData['error']} - ${errorData['error_description']}');
      } catch (e) {
        print('Could not parse error response, raw body: ${response.body}');
        throw Exception('Token exchange failed: HTTP ${response.statusCode} - ${response.body}');
      }
    }
  }
  
  static Map<String, dynamic> _extractUserInfoFromToken(String accessToken) {
    try {
      final handler = JwtDecoder.decode(accessToken);
      
      return {
        'id': handler['oid'] ?? handler['sub'] ?? 'unknown',
        'displayName': handler['name'] ?? handler['given_name'] ?? 'User',
        'email': _extractEmail(handler),
      };
    } catch (e) {
      print('Error extracting user info from token: $e');
      return {
        'id': 'unknown-${DateTime.now().millisecondsSinceEpoch}',
        'displayName': 'User',
        'email': 'no-email@example.com',
      };
    }
  }
  
  static String _extractEmail(Map<String, dynamic> tokenPayload) {
    // Try different possible email claims
    if (tokenPayload['email'] != null) return tokenPayload['email'];
    if (tokenPayload['emails'] != null && tokenPayload['emails'] is List) {
      final emails = tokenPayload['emails'] as List;
      if (emails.isNotEmpty) return emails.first.toString();
    }
    if (tokenPayload['preferred_username'] != null) return tokenPayload['preferred_username'];
    return 'no-email@example.com';
  }
  
  static Future<void> _storeUserInfo(Map<String, dynamic> userInfo) async {
    final prefs = await SharedPreferences.getInstance();
    
    final userId = userInfo['id'];
    final email = userInfo['email'];
    final name = userInfo['displayName'];
    
    if (userId != null) await prefs.setString('microsoftUserId', userId);
    if (email != null) await prefs.setString('userEmail', email);
    if (name != null) await prefs.setString('userName', name);
    
    await prefs.setString(_userInfoKey, json.encode(userInfo));
  }
  
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString(_accessTokenKey);
    final expiryString = prefs.getString(_tokenExpiryKey);
    
    if (accessToken == null) return null;
    
    if (expiryString != null) {
      final expiry = DateTime.parse(expiryString);
      if (DateTime.now().isAfter(expiry.subtract(const Duration(minutes: 5)))) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          return prefs.getString(_accessTokenKey);
        } else {
          return null;
        }
      }
    }
    
    return accessToken;
  }
  
  static Future<bool> _refreshAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString(_refreshTokenKey);
    
    if (refreshToken == null) return false;
    
    final tokenUrl = '${AuthConfig.authority}/oauth2/v2.0/token';
    
    final body = {
      'client_id': AuthConfig.clientId,
      'refresh_token': refreshToken,
      'grant_type': 'refresh_token',
      'scope': AuthConfig.scopes.join(' '),
    };
    
    final response = await http.post(
      Uri.parse(tokenUrl),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&'),
    );
    
    if (response.statusCode == 200) {
      final tokenData = json.decode(response.body);
      
      await prefs.setString(_accessTokenKey, tokenData['access_token']);
      if (tokenData['refresh_token'] != null) {
        await prefs.setString(_refreshTokenKey, tokenData['refresh_token']);
      }
      
      final newExpiry = DateTime.now().add(Duration(seconds: tokenData['expires_in']));
      await prefs.setString(_tokenExpiryKey, newExpiry.toIso8601String());
      
      return true;
    }
    
    return false;
  }
  
  static Future<Map<String, dynamic>?> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userInfoJson = prefs.getString(_userInfoKey);
    
    if (userInfoJson != null) {
      return json.decode(userInfoJson);
    }
    return null;
  }
  
  static Future<bool> isLoggedIn() async {
    print('=== Checking if user is logged in ===');
    final accessToken = await getAccessToken();
    print('Access token exists: ${accessToken != null}');
    
    if (accessToken != null) {
      // Also check if user exists in backend
      try {
        final userExists = await _checkUserExistsInBackend();
        print('User exists in backend: $userExists');
        
        // If token is valid but user doesn't exist in backend, create them
        if (!userExists) {
          print('Creating user in backend...');
          final created = await ensureUserExists();
          print('User creation result: $created');
          return created;
        }
        
        return userExists;
      } catch (e) {
        print('Error checking user in backend: $e');
        return false;
      }
    }
    
    return false;
  }
  
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    final logoutUrl = '${AuthConfig.authority}/oauth2/v2.0/logout?post_logout_redirect_uri=${Uri.encodeComponent(AuthConfig.currentRedirectUri)}';
    html.window.location.href = logoutUrl;
  }
  
  static Future<String?> getMicrosoftUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('microsoftUserId');
  }
  
  static Future<String?> getDatabaseUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('databaseUserId');
  }
  
  static Future<String?> getBearerToken() async {
    final token = await getAccessToken();
    return token != null ? 'Bearer $token' : null;
  }
  
  static Future<bool> _checkUserExistsInBackend() async {
    try {
      final bearerToken = await getBearerToken();
      if (bearerToken == null) {
        print('No bearer token available for user check');
        return false;
      }
      
      final microsoftUserId = await getMicrosoftUserId();
      if (microsoftUserId == null) {
        print('No Microsoft user ID available');
        return false;
      }
      
      final apiUrl = Uri.base.host == 'localhost' 
          ? 'http://localhost:7071/api'
          : 'https://lookatdeez-functions.azurewebsites.net/api';
      
      print('Checking if user exists in backend: $microsoftUserId');
      
      // Try to get user profile to see if they exist
      final response = await http.get(
        Uri.parse('$apiUrl/users/$microsoftUserId/profile'),
        headers: {
          'Authorization': bearerToken,
          'x-user-id': microsoftUserId, // Add the required header
        },
      );
      
      print('User profile check response: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('User exists in backend');
        return true;
      } else if (response.statusCode == 404) {
        print('User does not exist in backend, will create');
        return false;
      } else {
        print('Unexpected response from backend: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error checking user exists: $e');
      return false;
    }
  }
  
  static Future<bool> ensureUserExists() async {
    try {
      final bearerToken = await getBearerToken();
      if (bearerToken == null) {
        print('No bearer token available');
        return false;
      }
      
      final apiUrl = Uri.base.host == 'localhost' 
          ? 'http://localhost:7071/api'
          : 'https://lookatdeez-functions.azurewebsites.net/api';
      
      print('Creating/verifying user with backend...');
      
      final microsoftUserId = await getMicrosoftUserId();
      final userInfo = await getUserInfo();
      
      if (microsoftUserId == null || userInfo == null) {
        print('Missing user info: microsoftUserId=$microsoftUserId, userInfo=$userInfo');
        return false;
      }
      
      final response = await http.post(
        Uri.parse('$apiUrl/users'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': bearerToken,
        },
        body: json.encode({
          'email': userInfo['email'] ?? 'no-email@example.com',
          'displayName': userInfo['displayName'] ?? 'User',
        }),
      );
      
      print('User creation response: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        // User created or already exists
        final userData = json.decode(response.body);
        print('User verified/created in database with ID: ${userData['id']}');
        
        // Store the database user ID - should be same as Microsoft ID
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('databaseUserId', userData['id']);
        await prefs.setString('userEmail', userData['email']);
        await prefs.setString('displayName', userData['displayName']);
        
        return true;
      } else if (response.statusCode == 401) {
        print('JWT token invalid - clearing auth state');
        await logout();
        return false;
      } else {
        print('Failed to create/verify user: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error ensuring user exists: $e');
      return false;
    }
  }
}