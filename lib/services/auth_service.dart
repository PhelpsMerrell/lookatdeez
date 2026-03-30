import 'dart:convert';
import 'dart:html' as html;
import 'dart:math' as math;
import 'dart:typed_data';
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

  /// Initialize auth service. Only checks existing token state.
  /// Does NOT handle the OAuth callback — that's AuthCallbackPage's job.
  static Future<void> initialize() async {
    // Nothing to do here now. AuthCallbackPage handles the callback flow.
    // This exists so main.dart doesn't break and for future init work.
  }

  /// Called by AuthCallbackPage to exchange the auth code for tokens.
  /// Returns true on success, false on failure.
  static Future<bool> handleAuthCallback() async {
    final currentUrl = Uri.base;
    final code = currentUrl.queryParameters['code'];
    final error = currentUrl.queryParameters['error'];

    if (error != null) {
      final desc = currentUrl.queryParameters['error_description'] ?? 'Unknown error';
      print('OAuth error: $error - $desc');
      throw Exception('Auth error: $error - $desc');
    }

    if (code == null) {
      print('No auth code found in callback URL');
      throw Exception('No authorization code received');
    }

    print('Received OAuth code, exchanging for tokens...');
    await _exchangeCodeForTokens(code);
    print('Token exchange complete');
    return true;
  }

  static Future<void> login() async {
    final authUrl = await _buildAuthUrl();
    html.window.location.href = authUrl;
  }

  // PKCE helper methods
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

    print('=== Building CIAM Auth URL ===');
    print('Client ID: ${AuthConfig.clientId}');
    print('Redirect URI: ${AuthConfig.redirectUri}');
    print('Authority: ${AuthConfig.authority}');
    print('Scopes: ${AuthConfig.scopes.join(' ')}');

    final queryString = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final authUrl = '${AuthConfig.signUpSignInUrl}?$queryString';
    print('Full CIAM Auth URL: $authUrl');
    return authUrl;
  }

  static Future<void> _exchangeCodeForTokens(String code) async {
    final tokenUrl = AuthConfig.tokenEndpoint;

    print('Exchanging code for CIAM tokens at: $tokenUrl');

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

    print('CIAM token response status: ${response.statusCode}');

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

      // Clean up the code verifier
      await prefs.remove(_codeVerifierKey);

      // Extract user info from JWT token and store it
      final userInfo = _extractUserInfoFromToken(accessToken);
      await _storeUserInfo(userInfo);
    } else {
      // Clean up the code verifier on error
      await prefs.remove(_codeVerifierKey);

      try {
        final errorData = json.decode(response.body);
        print('CIAM error: ${errorData['error']} - ${errorData['error_description']}');
        throw Exception('Token exchange failed: ${errorData['error']} - ${errorData['error_description']}');
      } catch (e) {
        if (e is Exception && e.toString().contains('Token exchange failed')) rethrow;
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

    if (accessToken == null) {
      return null;
    }

    if (expiryString != null) {
      final expiry = DateTime.parse(expiryString);
      if (DateTime.now().isAfter(expiry.subtract(const Duration(minutes: 5)))) {
        print('Token expired or expiring soon, attempting refresh...');
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

  /// Checks if tokens exist and are valid. Does NOT hit the backend.
  static Future<bool> isLoggedIn() async {
    final accessToken = await getAccessToken();
    return accessToken != null;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    final logoutUrl = '${AuthConfig.logoutEndpoint}?post_logout_redirect_uri=${Uri.encodeComponent(AuthConfig.postLogoutRedirectUri)}';
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

    if (token != null) {
      // Validate token is not expired before returning
      try {
        final handler = JwtDecoder.decode(token);
        final exp = handler['exp'];
        if (exp != null) {
          final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
          if (DateTime.now().isAfter(expiry)) {
            print('Token is expired, attempting refresh...');
            final refreshed = await _refreshAccessToken();
            if (refreshed) {
              final newToken = await getAccessToken();
              if (newToken != null) {
                return 'Bearer $newToken';
              }
            }
            return null;
          }
        }
      } catch (e) {
        print('Error validating token expiry: $e');
        // Continue anyway, let the server validate
      }

      return 'Bearer $token';
    }

    return null;
  }

  /// Creates the user in the backend if they don't exist yet.
  /// Uses Environment.apiBaseUrl for consistency.
  static Future<bool> ensureUserExists() async {
    try {
      final bearerToken = await getBearerToken();
      if (bearerToken == null) {
        print('No bearer token available');
        return false;
      }

      final apiUrl = Environment.apiBaseUrl;

      final microsoftUserId = await getMicrosoftUserId();
      final userInfo = await getUserInfo();

      if (microsoftUserId == null || userInfo == null) {
        print('Missing user info: microsoftUserId=$microsoftUserId, userInfo=$userInfo');
        return false;
      }

      print('Creating/verifying user with backend at $apiUrl...');

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

      if (response.statusCode == 201 || response.statusCode == 200) {
        final userData = json.decode(response.body);
        print('User verified/created in database with ID: ${userData['id']}');

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('databaseUserId', userData['id']);
        if (userData['email'] != null) await prefs.setString('userEmail', userData['email']);
        if (userData['displayName'] != null) await prefs.setString('userName', userData['displayName']);

        return true;
      } else if (response.statusCode == 401) {
        print('JWT token invalid — clearing auth state');
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
