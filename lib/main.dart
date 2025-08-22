import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/auth_callback_page.dart';
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
      title: 'Vertical Content Playlists',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/auth/callback': (context) => const AuthCallbackPage(),
        '/login': (context) => const LoginPage(),
      },
      // Enable this temporarily to debug hero animations
      debugShowCheckedModeBanner: false,
    );
  }
}

// Uncomment this line temporarily to debug hero animations
bool debugPaintHeroAnimations = true;