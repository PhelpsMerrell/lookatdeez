class AuthConfig {
  // Azure Entra External ID (CIAM) Configuration (lookatdeez tenant)
  static const String clientId = 'f0749993-27a7-486f-930d-16a825e017bf';
  static const String tenantName = 'lookatdeez';
  static const String tenantId   = 'f8c9ea6d-89ab-4b1e-97db-dc03a426ec60';

  // B2C-style flow names (kept as-is for compatibility; not used in CIAM URL paths)
  static const String signUpSignInFlow   = 'b2c_1_signup_signin';
  static const String editProfileFlow    = 'b2c_1_profile_edit';
  static const String resetPasswordFlow  = 'b2c_1_password_reset';

  // ---------- UPDATED: CIAM authority & endpoints ----------
  // Base authority for CIAM (use this if your auth library wants an "authority")
  static String get authorityBase =>
      'https://$tenantName.ciamlogin.com/$tenantId';

  // Keep existing getters/names; point them to CIAM base so nothing else breaks
  static String get authority => authorityBase;
  static String get resetPasswordAuthority => authorityBase;

  // Explicit OIDC v2.0 endpoints for your flows
  static String get authorizationEndpoint =>
      '$authorityBase/oauth2/v2.0/authorize';
  static String get tokenEndpoint =>
      '$authorityBase/oauth2/v2.0/token';
  static String get logoutEndpoint =>
      '$authorityBase/oauth2/v2.0/logout';
  static String get openIdConfiguration =>
      '$authorityBase/v2.0/.well-known/openid-configuration';

  // Redirect URIs - must exactly match app registration
  static const String redirectUri      = 'https://lookatdeez.com/auth/callback';
  static const String redirectUriLocal = 'http://localhost:5173/auth/callback';

  // Scopes for CIAM/OIDC
  static const List<String> scopes = [
    'openid',
    'profile',
    'email',
    'offline_access',
  ];

  // Get the correct redirect URI based on environment
  static String get currentRedirectUri {
    final host = Uri.base.host;
    if (host == 'localhost' || host.startsWith('127.0.0.1')) {
      return redirectUriLocal;
    }
    return redirectUri;
  }
}
