import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/auth_callback_page.dart';
import 'pages/playlist_menu_page.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Microsoft Auth
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
    return MaterialApp(
      title: 'Look at Deez',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthGate(), // Use AuthGate as the initial widget
      routes: {
        '/login': (context) => const LoginPage(),
        '/auth/callback': (context) => const AuthCallbackPage(),
        '/playlists': (context) => const PlaylistMenuPage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

// New AuthGate widget to handle initial authentication state
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    try {
      // Check current URL for auth callback
      final currentPath = Uri.base.path;
      if (currentPath == '/auth/callback') {
        // Let AuthCallbackPage handle the callback
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthCallbackPage()),
        );
        return;
      }

      print('AuthGate: Checking authentication state...');
      final isLoggedIn = await AuthService.isLoggedIn();
      print('AuthGate: User is logged in: $isLoggedIn');
      
      if (mounted) {
        setState(() {
          _isAuthenticated = isLoggedIn;
          _isLoading = false;
        });
        
        if (isLoggedIn) {
          // Navigate to main app
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PlaylistMenuPage()),
          );
        }
      }
    } catch (e) {
      print('AuthGate error: $e');
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
          _isLoading = false;
        });
      }
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
            child: CircularProgressIndicator(
              color: Colors.cyan,
            ),
          ),
        ),
      );
    }

    // Show login page if not authenticated
    return const LoginPage();
  }
}