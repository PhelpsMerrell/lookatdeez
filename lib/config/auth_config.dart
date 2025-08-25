class AuthConfig {
  // App registration
  static const String clientId = 'f0749993-27a7-486f-930d-16a825e017bf';

  // Tenant identifiers
  static const String tenantName = 'lookatdeez';
  static const String tenantId   = 'f8c9ea6d-89ab-4b1e-97db-dc03a426ec60';

  // Use the correct CIAM authority format
  static String get authority => 'https://$tenantName.ciamlogin.com/$tenantId';

  // Redirect URIs (must exactly match those in your app registration)
  static const String redirectUri = 'https://lookatdeez.com/auth/callback';
  static const String redirectUriLocal = 'http://localhost:5173/auth/callback';

  // Scopes - request token for this application, not Microsoft Graph
  static const List<String> scopes = [
    'openid',
    'profile',
    'email',
    'offline_access',
    clientId,  // Add your client ID as a scope to get token for your app
  ];

  static String get currentRedirectUri {
    // Check if we're on localhost or production
    final currentHost = Uri.base.host;
    if (currentHost == 'localhost' || currentHost == '127.0.0.1') {
      return redirectUriLocal;
    }
    return redirectUri;
  }
}
