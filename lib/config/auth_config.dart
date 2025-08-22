class AuthConfig {
  // Azure AD B2C Configuration (lookatdeez tenant)
  static const String clientId = 'f0749993-27a7-486f-930d-16a825e017bf'; // Update if different in B2C
  static const String tenantName = 'lookatdeez';
  static const String tenantId = 'f8c9ea6d-89ab-4b1e-97db-dc03a426ec60'; // Your B2C tenant ID
  
  // B2C User Flow Names (your exact names)
  static const String signUpSignInFlow = 'B2C_1_signup_signin';
  static const String editProfileFlow = 'B2C_1_profile_edit';
  static const String resetPasswordFlow = 'B2C_1_password_reset';
  
  // B2C Authority URLs
  static String get authority => 'https://$tenantName.b2clogin.com/$tenantName.onmicrosoft.com/$signUpSignInFlow';
  static String get resetPasswordAuthority => 'https://$tenantName.b2clogin.com/$tenantName.onmicrosoft.com/$resetPasswordFlow';
  
  // Redirect URIs - these need to match what you configure in your B2C app registration
  static const String redirectUri = 'https://lookatdeez.com/auth/callback';
  static const String redirectUriLocal = 'http://localhost:5173/auth/callback';
  
  // Scopes for B2C
  static const List<String> scopes = [
    'openid',
    'profile',
    'email',
    'offline_access'
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
