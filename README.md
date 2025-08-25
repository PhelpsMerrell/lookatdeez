# LookAtDeez Frontend 🎵✨

A beautiful, modern Flutter web application for creating and sharing video url playlists across multiple platforms.

## 🌐 Live Application
**Website**: [https://lookatdeez.com](https://lookatdeez.com)  
**Backend API**: [https://lookatdeez-functions.azurewebsites.net](https://lookatdeez-functions.azurewebsites.net)

## 🎯 What is LookAtDeez?

LookAtDeez is your personal video playlist curator that brings together content from YouTube, TikTok, Instagram Reels, Twitch, Vimeo, and more into organized, shareable playlists. Tired of your texted shorts getting lost and your firends arent watching them? package all the mems and funny or informative content you want them to consume in a playlist! so much easier and quick to make

## 🏗️ Technology Stack

### Framework & Language
- **Flutter 3.9+** - Google's UI toolkit for building natively compiled applications
- **Dart** - The programming language optimized for client development

### Key Packages
- **HTTP Client**: `http ^1.1.0` - REST API communication
- **Authentication**: Microsoft OAuth 2.0 with PKCE
- **State Management**: Built-in Flutter state management
- **Video Players**: Multiple video player implementations
- **Local Storage**: `shared_preferences ^2.2.2` - Client-side data persistence
- **JWT Handling**: `jwt_decoder ^2.0.1` - Token management

### Authentication & Security
- **OAuth 2.0 + PKCE**: Secure authentication flow
- **JWT Tokens**: Stateless authentication with refresh capabilities
- **Microsoft Entra ID**: Enterprise-grade identity management

## 📁 Project Structure

```
lookatdeez/
├── lib/
│   ├── config/                  # Configuration files
│   │   ├── auth_config.dart     # Authentication settings
│   │   └── environment.dart     # Environment variables
│   ├── models/                  # Data models
│   │   ├── playlist.dart        # Playlist data structure
│   │   ├── video_item.dart      # Video item model
│   │   ├── friend.dart          # User/friend model
│   │   └── user.dart           # User profile model
│   ├── pages/                   # Screen/page widgets
│   │   ├── login_page.dart      # Authentication screen
│   │   ├── playlist_menu_page.dart    # Main dashboard
│   │   ├── playlist_editor_page.dart  # Playlist editing
│   │   ├── playlist_player_page.dart  # Video playback
│   │   ├── friends_page.dart    # Social features
│   │   └── profile_page.dart    # User profile
│   ├── services/                # Business logic & API
│   │   ├── auth_service.dart    # Authentication management
│   │   └── api_service.dart     # Backend API communication
│   ├── widgets/                 # Reusable UI components
│   │   ├── playlist_card.dart   # Playlist preview cards
│   │   ├── video_card.dart      # Video item display
│   │   ├── friend_share_sheet.dart # Sharing interface
│   │   └── main_app_bar.dart    # Navigation header
│   └── main.dart               # Application entry point
├── web/                        # Web-specific assets
├── android/                    # Android build configuration
├── pubspec.yaml               # Dependencies and metadata
└── README.md                  # This file
```

## 🚀 Features Deep Dive

### 🎵 Playlist Management
- **Create Playlists**: Give your collections meaningful names and descriptions
- **Add Content**: Support for multiple video platforms with URL validation
- **Drag & Drop Reordering**: Intuitive playlist organization
- **Real-time Sync**: Changes instantly reflected across devices

### 👥 Social Features
- **Friend System**: Send and accept friend requests
- **User Discovery**: Search for friends by name or email
- **Playlist Sharing**: Share your creations with your network
- **Activity Feed**: See what your friends are creating













## 🌍 Deployment

### Azure Static Web Apps
The application is deployed using Azure Static Web Apps with GitHub Actions for continuous deployment.

**Production URL**: [https://lookatdeez.com](https://lookatdeez.com)



## 📱 Platform Support

### Current Support
- ✅ **Web (Chrome, Firefox, Safari, Edge)**
- ✅ **Progressive Web App (PWA) capabilities**

### Future Roadmap
- 📱 **iOS App** (Flutter native)
- 🤖 **Android App** (Flutter native)
- 💻 **Desktop Apps** (Windows, macOS, Linux)

## 🔧 Configuration

### Authentication Settings
```dart
// lib/config/auth_config.dart
class AuthConfig {
  static const String clientId = 'your-client-id';
  static const String tenantId = 'your-tenant-id';
  static const String redirectUri = 'https://lookatdeez.com/auth/callback';
  static const List<String> scopes = ['openid', 'profile', 'email', 'offline_access'];
}
```

### API Configuration
```dart
// lib/config/environment.dart
class Environment {
  static const String apiBaseUrl = 'https://lookatdeez-functions.azurewebsites.net/api';
  static const int requestTimeoutSeconds = 30;
  static const bool enableLogging = true; // Set to false in production
}
```

## 🐛 Troubleshooting

### Common Issues
1. **Login Issues**: Clear browser cache and ensure redirect URI is configured correctly
2. **CORS Errors**: Verify backend CORS settings include your domain
3. **Token Expiry**: Refresh the page to trigger automatic token renewal
4. **Video Playback**: Check if the video URL is accessible and from a supported platform

### Debug Mode
Enable debug logging by setting `Environment.enableLogging = true` in your configuration.

## 🤝 Contributing

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### Code Style
- Follow [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Use `flutter format .` before committing
- Write descriptive commit messages

## 📄 License

This project is proprietary software. All rights reserved.

---

**🎵 Made with Flutter & ❤️ for music enthusiasts worldwide**

*Start curating your perfect playlist today at [lookatdeez.com](https://lookatdeez.com)!*
