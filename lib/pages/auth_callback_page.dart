import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthCallbackPage extends StatefulWidget {
  const AuthCallbackPage({super.key});

  @override
  State<AuthCallbackPage> createState() => _AuthCallbackPageState();
}

class _AuthCallbackPageState extends State<AuthCallbackPage> {
  @override
  void initState() {
    super.initState();
    _handleCallback();
  }

  Future<void> _handleCallback() async {
    try {
      // The AuthService.initialize() will handle the redirect response
      await AuthService.initialize();
      
      // Check if login was successful
      final isLoggedIn = await AuthService.isLoggedIn();
      
      if (isLoggedIn && mounted) {
        // Navigate back to main app
        Navigator.of(context).pushReplacementNamed('/');
      } else {
        // Login failed, redirect to login page
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      print('Auth callback error: $e');
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Completing sign in...'),
          ],
        ),
      ),
    );
  }
}
