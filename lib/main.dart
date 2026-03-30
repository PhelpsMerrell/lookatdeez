import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/auth_callback_page.dart';
import 'pages/playlist_menu_page.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await AuthService.initialize();
  } catch (e) {
    print('Auth initialization failed: $e');
  }

  runApp(const PlaylistApp());
}

class PlaylistApp extends StatelessWidget {
  const PlaylistApp({super.key});

  @override
  Widget build(BuildContext context) {
    // If the browser landed on /auth/callback, go straight there.
    // Otherwise use the normal AuthGate flow.
    final isCallback = Uri.base.path == '/auth/callback';

    return MaterialApp(
      title: 'Look at Deez',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: isCallback ? const AuthCallbackPage() : const AuthGate(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/playlists': (context) => const PlaylistMenuPage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    try {
      print('AuthGate: Checking authentication state...');
      final isLoggedIn = await AuthService.isLoggedIn();
      print('AuthGate: User is logged in: $isLoggedIn');

      if (isLoggedIn && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PlaylistMenuPage()),
        );
        return;
      }
    } catch (e) {
      print('AuthGate error: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F172A),
                Color(0xFF1E3A8A),
                Color(0xFF312E81),
              ],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.cyan),
          ),
        ),
      );
    }

    return const LoginPage();
  }
}
