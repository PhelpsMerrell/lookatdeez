import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'playlist_menu_page.dart';
import 'login_page.dart';

class AuthCallbackPage extends StatefulWidget {
  const AuthCallbackPage({super.key});

  @override
  State<AuthCallbackPage> createState() => _AuthCallbackPageState();
}

class _AuthCallbackPageState extends State<AuthCallbackPage> {
  bool _isProcessing = true;
  String _status = 'Processing authentication...';
  String? _error;

  @override
  void initState() {
    super.initState();
    _processCallback();
  }

  Future<void> _processCallback() async {
    try {
      print('=== Processing Auth Callback ===');

      setState(() => _status = 'Exchanging authorization code...');

      // This is the ONE place that exchanges the auth code for tokens.
      await AuthService.handleAuthCallback();

      setState(() => _status = 'Creating user account...');

      final userCreated = await AuthService.ensureUserExists();
      if (!userCreated) {
        // User creation failed but tokens are valid — continue anyway.
        // The user record will be created on the next API call that needs it.
        print('Warning: ensureUserExists returned false, continuing anyway');
      }

      setState(() {
        _status = 'Authentication successful!';
        _isProcessing = false;
      });

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const PlaylistMenuPage()),
          (route) => false,
        );
      }
    } catch (e) {
      print('Auth callback error: $e');
      setState(() {
        _error = e.toString();
        _isProcessing = false;
        _status = 'Authentication failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF312E81)],
          ),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(40),
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _error != null
                          ? [Colors.red, Colors.redAccent]
                          : _isProcessing
                              ? [Colors.cyan, Colors.blue]
                              : [Colors.green, Colors.lightGreen],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                      : Icon(
                          _error != null ? Icons.error : Icons.check_circle,
                          color: Colors.white,
                          size: 40,
                        ),
                ),
                const SizedBox(height: 24),
                Text(
                  _error != null
                      ? 'Authentication Failed'
                      : _isProcessing
                          ? 'Authenticating...'
                          : 'Authentication Successful!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  _status,
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                      (route) => false,
                    ),
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text('Try Again', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan.withValues(alpha: 0.8),
                      minimumSize: const Size(200, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
