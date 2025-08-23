import 'package:flutter/material.dart';
import 'package:lookatdeez/pages/playlist_menu_page.dart';

import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  
  late AnimationController _snowflakeController;
  late AnimationController _fadeController;
  
  @override
  void initState() {
    super.initState();
    _snowflakeController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..forward();
    
    // Check if already logged in via Microsoft
    _checkExistingAuth();
  }
  
  Future<void> _checkExistingAuth() async {
    try {
      print('LoginPage: Checking if user is already logged in...');
      final isLoggedIn = await AuthService.isLoggedIn();
      print('LoginPage: User is logged in: $isLoggedIn');
      
      if (isLoggedIn && mounted) {
        print('LoginPage: User is authenticated, navigating to PlaylistMenuPage');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PlaylistMenuPage()),
        );
      } else {
        print('LoginPage: User not logged in, staying on login page');
      }
    } catch (e) {
      print('Error checking existing auth: $e');
    }
  }
  
  @override
  void dispose() {
    _snowflakeController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

void _handleSubmit() async {
  setState(() => _isLoading = true);
  
  try {
    await _handleMicrosoftLogin();
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Authentication failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}



  Future<void> _handleMicrosoftLogin() async {
    try {
      print('Starting Microsoft login...');
      await AuthService.login();
      print('Microsoft login completed successfully');
      
      // After successful login, the auth callback will handle user creation
      // and redirect to the playlist menu, so we don't need to do anything else here
    } catch (e) {
      print('Microsoft login failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Microsoft authentication failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    }
  }

  void _handleSocialLogin(String provider) {
    print('Continue with $provider');
    // TODO: Integrate with Azure AD B2C social providers
    // Example: await authService.signInWithSocial(provider);
  }

  Widget _buildSocialButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
      ),
    );
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A), // slate-900
              Color(0xFF1E3A8A), // blue-900
              Color(0xFF312E81), // indigo-900
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: FadeTransition(
                opacity: _fadeController,
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo and title
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.cyan, Colors.blue],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: RotationTransition(
                          turns: _snowflakeController,
                          child: const Icon(
                            Icons.ac_unit,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Welcome to Look at Deez',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Create and share your music playlists',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Info about authentication
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 32),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                        ),
                        child: const Text(
                          'Sign in securely with Microsoft. Your account will be created automatically on first sign-in.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      // Microsoft Sign-in button
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _handleSubmit,
                          icon: _isLoading 
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.login, color: Colors.white),
                          label: Text(
                            _isLoading 
                                ? 'Signing in...'
                                : 'Sign in',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ).copyWith(
                            backgroundColor: WidgetStateProperty.all(
                              Colors.cyan.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ),

                      // Footer note
                      const Text(
                        'Secure authentication powered by Microsoft Entra',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}