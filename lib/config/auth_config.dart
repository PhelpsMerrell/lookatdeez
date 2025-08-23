class AuthConfig {
  // App registration
  static const String clientId = 'f0749993-27a7-486f-930d-16a825e017bf';

  // Tenant identifiers
  static const String tenantName = 'lookatdeez';
  static const String tenantId   = 'f8c9ea6d-89ab-4b1e-97db-dc03a426ec60';

  // (Kept for compatibility; CIAM does not put these in the URL path)
  static const String signUpSignInFlow = 'b2c_1_signup_signin';
  static const String editProfileFlow  = 'b2c_1_profile_edit';
  static const String resetPasswordFlow = 'b2c_1_password_reset';

  // ----- CIAM Authority & Endpoints -----
  // Use these for OIDC/OAuth flows
  static String get authorityBase =>
      'https://$tenantName.ciamlogin.com/$tenantId';

  // MSAL-style authority root (if a library asks for "authority")
  static String get authority => authorityBase; // e.g., https://lookatdeez.ciamlogin.com/<tenantId>

  // OIDC v2.0 endpoints
  static String get openIdConfiguration =>
      '$authorityBase/v2.0/.well-known/openid-configuration';

  static String get authorizationEndpoint =>
      '$authorityBase/oauth2/v2.0/authorize';

  static String get tokenEndpoint =>
      '$authorityBase/oauth2/v2.0/token';

  static String get logoutEndpoint =>
      '$authorityBase/oauth2/v2.0/logout';

  // Redirect URIs (must exactly match those in your app registration)
  static const String redirectUri      = 'https://lookatdeez.com/auth/callback';
  static const String redirectUriLocal = 'http://localhost:5173/auth/callback';

  // Scopes (minimum: openid; add profile/email/offline_access as needed)
  static const List<String> scopes = [
    'openid',
    'profile',
    'email',
    'offline_access',
  ];

  static String get currentRedirectUri {
    // Use localhost for development, production URL for deployed app
    final currentHost = Uri.base.host;
    if (currentHost == 'localhost' || currentHost == '127.0.0.1') {
      return redirectUriLocal;
    }
    return redirectUri;
  }

  

  // Helper: build a full authorize URL for Authorization Code + PKCE
  static Uri buildAuthorizeUri({
    required String state,
    required String nonce,
    required String codeChallenge,
    String responseMode = 'query',
    String responseType = 'code',
    List<String>? extraScopes,
    String? overrideRedirectUri,
    bool promptLogin = false,
  }) {
    final uri = Uri.parse(authorizationEndpoint);
    final allScopes = [
      ...scopes,
      if (extraScopes != null) ...extraScopes,
    ].join(' ');

    final params = <String, String>{
      'client_id': clientId,
      'redirect_uri': overrideRedirectUri ?? currentRedirectUri,
      'response_type': responseType,
      'response_mode': responseMode,
      'scope': allScopes,
      'state': state,
      'nonce': nonce,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
      if (promptLogin) 'prompt': 'login',
    };

    return uri.replace(queryParameters: params);
  }
}
