import 'dart:convert';
import 'dart:html' as html;
import 'dart:math' as math;
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import '../config/auth_config.dart';
import '../config/environment.dart';

class AuthService {
  static const String _accessTokenKey = 'ms_access_token';
  static const String _refreshTokenKey = 'ms_refresh_token';
  static const String _tokenExpiryKey = 'ms_token_expiry';
  static const String _userInfoKey = 'ms_user_info';
  static const String _codeVerifierKey = 'pkce_code_verifier';
  static const String _authProviderKey = 'auth_provider'; // "local" or "microsoft"

  static Future<void> initialize() async {}

  // ============================
  // Local email+password auth
  // ============================

  /// Register a new account with email + password.
  /// Returns a map with 'success' bool and 'error' string on failure.
  static Future<Map<String, dynamic>> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final apiUrl = Environment.apiBaseUrl;
      final response = await http.post(
        Uri.parse('$apiUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email.trim(),
          'password': password,
          'displayName': displayName.trim(),
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        await _storeLocalAuthData(data);
        return {'success': true};
      } else {
        final errorBody = _parseError(response.body);
        return {'success': false, 'error': errorBody};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  /// Login with email + password.
  static Future<Map<String, dynamic>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final apiUrl = Environment.apiBaseUrl;
      final response = await http.post(
        Uri.parse('$apiUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email.trim(),
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _storeLocalAuthData(data);
        return {'success': true};
      } else {
        final errorBody = _parseError(response.body);
        return {'success': false, 'error': errorBody};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<void> _storeLocalAuthData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final token = data['token'] as String;
    final expiresAt = data['expiresAt'] as String;
    final user = data['user'] as Map<String, dynamic>;

    await prefs.setString(_accessTokenKey, token);
    await prefs.setString(_tokenExpiryKey, expiresAt);
    await prefs.setString(_authProviderKey, 'local');
    await prefs.setString('microsoftUserId', user['id']);
    await prefs.setString('userEmail', user['email']);
    await prefs.setString('userName', user['displayName']);
    await prefs.setString(_userInfoKey, json.encode({
      'id': user['id'],
      'displayName': user['displayName'],
      'email': user['email'],
    }));
    // No refresh token for local auth — token lasts 24h
    await prefs.remove(_refreshTokenKey);
  }

  static String _parseError(String body) {
    try {
      final data = json.decode(body);
      return data['error'] ?? 'Unknown error';
    } catch (_) {
      return body.isNotEmpty ? body : 'Unknown error';
    }
  }

  // ============================
  // Microsoft OAuth (existing)
  // ============================

  static Future<bool> handleAuthCallback() async {
    final currentUrl = Uri.base;
    final code = currentUrl.queryParameters['code'];
    final error = currentUrl.queryParameters['error'];

    if (error != null) {
      final desc = currentUrl.queryParameters['error_description'] ?? 'Unknown error';
      throw Exception('Auth error: $error - $desc');
    }

    if (code == null) {
      throw Exception('No authorization code received');
    }

    await _exchangeCodeForTokens(code);

    // Mark as microsoft auth
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authProviderKey, 'microsoft');

    return true;
  }

  static Future<void> loginWithMicrosoft() async {
    final authUrl = await _buildAuthUrl();
    html.window.location.href = authUrl;
  }

  static String _generateCodeVerifier() {
    final random = math.Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  static String _generateCodeChallenge(String codeVerifier) {
    final bytes = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytes);
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  static Future<String> _buildAuthUrl() async {
    final codeVerifier = _generateCodeVerifier();
    final codeChallenge = _generateCodeChallenge(codeVerifier);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_codeVerifierKey, codeVerifier);

    final params = {
      'client_id': AuthConfig.clientId,
      'response_type': 'code',
      'redirect_uri': AuthConfig.redirectUri,
      'scope': AuthConfig.scopes.join(' '),
      'response_mode': 'query',
      'state': 'state_${DateTime.now().millisecondsSinceEpoch}',
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
    };

    final queryString = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return '${AuthConfig.signUpSignInUrl}?$queryString';
  }

  static Future<void> _exchangeCodeForTokens(String code) async {
    final tokenUrl = AuthConfig.tokenEndpoint;
    final prefs = await SharedPreferences.getInstance();
    final codeVerifier = prefs.getString(_codeVerifierKey);

    if (codeVerifier == null) {
      throw Exception('Code verifier not found — PKCE state was lost');
    }

    final body = {
      'client_id': AuthConfig.clientId,
      'code': code,
      'redirect_uri': AuthConfig.redirectUri,
      'grant_type': 'authorization_code',
      'code_verifier': codeVerifier,
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

      await prefs.setString(_accessTokenKey, accessToken);
      if (refreshToken != null) {
        await prefs.setString(_refreshTokenKey, refreshToken);
      }
      await prefs.setString(_tokenExpiryKey, expiryTime.toIso8601String());
      await prefs.remove(_codeVerifierKey);

      final userInfo = _extractUserInfoFromToken(accessToken);
      await _storeUserInfo(userInfo);
    } else {
      await prefs.remove(_codeVerifierKey);
      try {
        final errorData = json.decode(response.body);
        throw Exception('Token exchange failed: ${errorData['error']} - ${errorData['error_description']}');
      } catch (e) {
        if (e.toString().contains('Token exchange failed')) rethrow;
        throw Exception('Token exchange failed: HTTP ${response.statusCode}');
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
      return {
        'id': 'unknown-${DateTime.now().millisecondsSinceEpoch}',
        'displayName': 'User',
        'email': 'no-email@example.com',
      };
    }
  }

  static String _extractEmail(Map<String, dynamic> tokenPayload) {
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
    if (userInfo['id'] != null) await prefs.setString('microsoftUserId', userInfo['id']);
    if (userInfo['email'] != null) await prefs.setString('userEmail', userInfo['email']);
    if (userInfo['displayName'] != null) await prefs.setString('userName', userInfo['displayName']);
    await prefs.setString(_userInfoKey, json.encode(userInfo));
  }

  // ============================
  // Shared auth methods
  // ============================

  static Future<String?> getAuthProvider() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_authProviderKey);
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString(_accessTokenKey);
    final expiryString = prefs.getString(_tokenExpiryKey);

    if (accessToken == null) return null;

    if (expiryString != null) {
      final expiry = DateTime.parse(expiryString);
      if (DateTime.now().isAfter(expiry.subtract(const Duration(minutes: 5)))) {
        // Only Microsoft tokens can be refreshed
        final provider = prefs.getString(_authProviderKey);
        if (provider == 'microsoft') {
          final refreshed = await _refreshAccessToken();
          if (refreshed) return prefs.getString(_accessTokenKey);
        }
        // Local tokens can't be refreshed — user must re-login
        return null;
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
    if (userInfoJson != null) return json.decode(userInfoJson);
    return null;
  }

  static Future<bool> isLoggedIn() async {
    final accessToken = await getAccessToken();
    return accessToken != null;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final provider = prefs.getString(_authProviderKey);

    // Clear all local state
    await prefs.clear();

    if (provider == 'microsoft') {
      // Microsoft logout redirects to their logout page
      final logoutUrl = '${AuthConfig.logoutEndpoint}?post_logout_redirect_uri=${Uri.encodeComponent(AuthConfig.postLogoutRedirectUri)}';
      html.window.location.href = logoutUrl;
    } else {
      // Local auth — just go to root, the AuthGate will show login page
      html.window.location.href = '/';
    }
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
    if (token == null) return null;

    // Check expiry
    try {
      final handler = JwtDecoder.decode(token);
      final exp = handler['exp'];
      if (exp != null) {
        final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        if (DateTime.now().isAfter(expiry)) {
          final prefs = await SharedPreferences.getInstance();
          final provider = prefs.getString(_authProviderKey);
          if (provider == 'microsoft') {
            final refreshed = await _refreshAccessToken();
            if (refreshed) {
              final newToken = await getAccessToken();
              if (newToken != null) return 'Bearer $newToken';
            }
          }
          return null;
        }
      }
    } catch (_) {}

    return 'Bearer $token';
  }

  /// For Microsoft users: creates/verifies the user record in the backend.
  /// For local users: user was already created during registration, this is a no-op.
  static Future<bool> ensureUserExists() async {
    final prefs = await SharedPreferences.getInstance();
    final provider = prefs.getString(_authProviderKey);

    // Local users are created during registration — no need to call backend
    if (provider == 'local') return true;

    try {
      final bearerToken = await getBearerToken();
      if (bearerToken == null) return false;

      final apiUrl = Environment.apiBaseUrl;
      final microsoftUserId = await getMicrosoftUserId();
      final userInfo = await getUserInfo();

      if (microsoftUserId == null || userInfo == null) return false;

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

      if (response.statusCode == 201 || response.statusCode == 200) {
        final userData = json.decode(response.body);
        await prefs.setString('databaseUserId', userData['id']);
        if (userData['email'] != null) await prefs.setString('userEmail', userData['email']);
        if (userData['displayName'] != null) await prefs.setString('userName', userData['displayName']);
        return true;
      } else if (response.statusCode == 401) {
        await logout();
        return false;
      }
      return false;
    } catch (e) {
      print('Error ensuring user exists: $e');
      return false;
    }
  }
}
