class AuthConfig {
  // Your actual Azure app registration values
  static const String clientId = 'f0749993-27a7-486f-930d-16a825e017bf';
  static const String tenantId = 'f8c9ea6d-89ab-4b1e-97db-dc03a426ec60';
  static const String authority = 'https://login.microsoftonline.com/$tenantId';
  
  // Redirect URIs - these need to match what you configure in Azure
  static const String redirectUri = 'https://lookatdeez.com/auth/callback';
  static const String redirectUriLocal = 'http://localhost:5173/auth/callback';
  
  // Scopes your app needs
  static const List<String> scopes = [
    'openid',
    'profile',
    'email',
    'User.Read'
  ];
  
  // Get the correct redirect URI based on environment
  static String get currentRedirectUri {
    // Check if we're running locally
    final host = Uri.base.host;
    if (host == 'localhost' || host.startsWith('127.0.0.1')) {
      return redirectUriLocal;
    }
    return redirectUri;
  }
}
