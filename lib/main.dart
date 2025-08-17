import 'package:flutter/material.dart';
import 'pages/login_page.dart';

void main() {
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
      home: const LoginPage(),
      // Enable this temporarily to debug hero animations
      debugShowCheckedModeBanner: false,
    );
  }
}

// Uncomment this line temporarily to debug hero animations
bool debugPaintHeroAnimations = true;