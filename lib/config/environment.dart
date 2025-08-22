// Environment configuration for different deployment targets
class Environment {
  static const bool isProduction = bool.fromEnvironment('dart.vm.product');
  static const String? forceApiUrl = String.fromEnvironment('API_URL');
  
  static String get apiBaseUrl {
    // If API_URL is explicitly set during build, use it
    if (forceApiUrl != null && forceApiUrl!.isNotEmpty) {
      return forceApiUrl!;
    }
    
    // Check if running on your custom domain
    if (isProduction) {
      return 'https://lookatdeez-functions.azurewebsites.net/api';
    }
    
    // Local development
    return 'http://localhost:7071/api';
  }
}
