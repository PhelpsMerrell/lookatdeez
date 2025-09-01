import 'package:flutter/foundation.dart';

// Azure AD B2C CIAM Configuration
class AuthConfig {
  static const String tenantId = 'f8c9ea6d-89ab-4b1e-97db-dc03a426ec60';
  static const String clientId = 'f0749993-27a7-486f-930d-16a825e017bf';
  
  // CIAM endpoints (B2C)
  static const String authority = 'https://lookatdeez.ciamlogin.com/$tenantId';
  static const String tokenEndpoint = '$authority/oauth2/v2.0/token';
  static const String authEndpoint = '$authority/oauth2/v2.0/authorize';
  static const String logoutEndpoint = '$authority/oauth2/v2.0/logout';
  
  // User flow for CIAM (sign up and sign in combined)
  static const String userFlow = 'B2C_1_signupsignin1';
  
  // Redirect URIs
  static const String redirectUri = kIsWeb 
    ? (kDebugMode ? 'http://localhost:5173/auth/callback' : 'https://lookatdeez.com/auth/callback')
    : 'msauth://com.example.lookatdeez/auth';
  
  static const String postLogoutRedirectUri = kIsWeb 
    ? (kDebugMode ? 'http://localhost:5173' : 'https://lookatdeez.com')
    : 'msauth://com.example.lookatdeez';
    
  // CIAM scopes
  static const List<String> scopes = [
    'openid',
    'offline_access', // For refresh tokens
    'https://lookatdeez.onmicrosoft.com/44c46a0b-0c02-4e97-be76-cbe30edc3829/access' // Backend API scope
  ];
  
  // Token storage keys
  static const String accessTokenKey = 'flutter.ms_access_token';
  static const String refreshTokenKey = 'flutter.ms_refresh_token';
  static const String expiryKey = 'flutter.ms_token_expiry';
  static const String userIdKey = 'flutter.ms_user_id';
  static const String emailKey = 'flutter.ms_email';
  
  // CIAM specific URLs (CIAM doesn't use ?p= parameter)
  static String get signUpSignInUrl => '$authority/oauth2/v2.0/authorize';
  static String get jwksUrl => '$authority/discovery/v2.0/keys';
}
