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
        throw Exception('Auth error: $error');
      }
      
      if (code != null) {
        await _exchangeCodeForTokens(code);
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
      'prompt': 'select_account',
    };
    
    final queryString = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    
    return '${AuthConfig.authority}/oauth2/v2.0/authorize?$queryString';
  }
  
  static Future<void> _exchangeCodeForTokens(String code) async {
    final tokenUrl = '${AuthConfig.authority}/oauth2/v2.0/token';
    
    final body = {
      'client_id': AuthConfig.clientId,
      'code': code,
      'redirect_uri': AuthConfig.currentRedirectUri,
      'grant_type': 'authorization_code',
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
      
      final userInfo = await _fetchUserInfoFromGraph(accessToken);
      await _storeUserInfo(userInfo);
    } else {
      final errorData = json.decode(response.body);
      throw Exception('Token exchange failed: ${errorData['error']}');
    }
  }
  
  static Future<Map<String, dynamic>> _fetchUserInfoFromGraph(String accessToken) async {
    final response = await http.get(
      Uri.parse('https://graph.microsoft.com/v1.0/me'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch user info: ${response.statusCode}');
    }
  }
  
  static Future<void> _storeUserInfo(Map<String, dynamic> userInfo) async {
    final prefs = await SharedPreferences.getInstance();
    
    final userId = userInfo['id'];
    final email = userInfo['mail'] ?? userInfo['userPrincipalName'];
    final name = userInfo['displayName'];
    
    if (userId != null) await prefs.setString('userId', userId);
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
    final accessToken = await getAccessToken();
    return accessToken != null;
  }
  
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    final logoutUrl = '${AuthConfig.authority}/oauth2/v2.0/logout?post_logout_redirect_uri=${Uri.encodeComponent(AuthConfig.currentRedirectUri)}';
    html.window.location.href = logoutUrl;
  }
  
  static Future<String?> getUserId() async {
    final userInfo = await getUserInfo();
    return userInfo?['id'];
  }
  
  static Future<String?> getBearerToken() async {
    final token = await getAccessToken();
    return token != null ? 'Bearer $token' : null;
  }
  
  static Future<void> ensureUserExists() async {
    try {
      final userInfo = await getUserInfo();
      if (userInfo == null) return;
      
      final email = userInfo['mail'] ?? userInfo['userPrincipalName'];
      final displayName = userInfo['displayName'];
      final microsoftUserId = userInfo['id'];
      
      if (email == null || displayName == null || microsoftUserId == null) return;
      
      print('Ensuring Microsoft user exists: $email, $displayName, $microsoftUserId');
      
      final apiUrl = Uri.base.host == 'localhost' 
          ? 'http://localhost:7071/api'
          : 'https://lookatdeez-functions.azurewebsites.net/api';
      
      final response = await http.post(
        Uri.parse('$apiUrl/users'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': await getBearerToken() ?? '',
        },
        body: json.encode({
          'email': email,
          'displayName': displayName,
        }),
      );
      
      print('Ensure user response: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 201) {
        // User created successfully
        final userData = json.decode(response.body);
        print('Microsoft user created in database with ID: ${userData['id']}');
        
        // Store the database user ID (not the Microsoft ID)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', userData['id']);
        await prefs.setString('email', userData['email']);
        await prefs.setString('displayName', userData['displayName']);
        
      } else if (response.statusCode == 409) {
        // User already exists, find them
        print('Microsoft user already exists, finding them...');
        await _findAndStoreExistingUser(email);
        
      } else {
        print('Failed to create/find user: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error ensuring user exists: $e');
    }
  }
  
  static Future<void> _findAndStoreExistingUser(String email) async {
    try {
      final apiUrl = Uri.base.host == 'localhost' 
          ? 'http://localhost:7071/api'
          : 'https://lookatdeez-functions.azurewebsites.net/api';
      
      final response = await http.get(
        Uri.parse('$apiUrl/users/search?q=${Uri.encodeComponent(email)}'),
        headers: {
          'Content-Type': 'application/json',
          'x-user-id': 'temp-search-user',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> users = json.decode(response.body);
        final user = users.firstWhere(
          (u) => u['email'].toLowerCase() == email.toLowerCase(),
          orElse: () => null,
        );
        
        if (user != null) {
          print('Found existing user: ${user['id']}');
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userId', user['id']);
          await prefs.setString('email', user['email']);
          await prefs.setString('displayName', user['displayName']);
        }
      }
    } catch (e) {
      print('Error finding existing user: $e');
    }
  }
}