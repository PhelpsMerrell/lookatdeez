# Flutter Video Player Enhancement - Installation Commands

## Run these commands in your terminal:

# 1. Install new dependencies
flutter pub get

# 2. For iOS - add permissions to ios/Runner/Info.plist
echo "Add these permissions to ios/Runner/Info.plist:"
echo "<key>NSCameraUsageDescription</key>"
echo "<string>This app needs camera access to play videos</string>"
echo "<key>NSMicrophoneUsageDescription</key>"
echo "<string>This app needs microphone access to play videos</string>"
echo "<key>io.flutter.embedded_views_preview</key>"
echo "<true/>"

# 3. For Android - add permissions to android/app/src/main/AndroidManifest.xml
echo "Add these permissions to android/app/src/main/AndroidManifest.xml:"
echo "<uses-permission android:name=\"android.permission.INTERNET\" />"
echo "<uses-permission android:name=\"android.permission.ACCESS_NETWORK_STATE\" />"

# 4. Test the implementation with LEGAL examples
echo "Legal test URLs to try (all public content):"
echo "YouTube: https://www.youtube.com/watch?v=dQw4w9WgXcQ"
echo "Vimeo: https://vimeo.com/148751763"
echo "Direct Video: https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
echo "Instagram: https://www.instagram.com/p/ABC123DEF456/ (replace with real public post)"
echo "TikTok: https://www.tiktok.com/@username/video/1234567890123456789 (replace with real public video)"

# 5. Test API endpoints
echo "\n=== API Test Commands ==="
echo "Add YouTube video:"
echo 'curl -X POST "http://localhost:7071/api/playlists/test-playlist/items" -H "Content-Type: application/json" -H "x-user-id: test-user" -d "{\"title\":\"Rick Roll Classic\",\"url\":\"https://www.youtube.com/watch?v=dQw4w9WgXcQ\"}"'

echo "\nAdd Vimeo video:"
echo 'curl -X POST "http://localhost:7071/api/playlists/test-playlist/items" -H "Content-Type: application/json" -H "x-user-id: test-user" -d "{\"title\":\"Vimeo Test Video\",\"url\":\"https://vimeo.com/148751763\"}"'

echo "\nAdd Direct Video:"
echo 'curl -X POST "http://localhost:7071/api/playlists/test-playlist/items" -H "Content-Type: application/json" -H "x-user-id: test-user" -d "{\"title\":\"Big Buck Bunny Sample\",\"url\":\"https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4\"}"'

# 6. Run the app
flutter run -d chrome  # for web testing
# or
flutter run  # for mobile testing

echo "\n=== LEGAL NOTICE ==="
echo "✅ All test URLs use public domain or officially embeddable content"
echo "✅ App includes terms notice explaining legal usage"
echo "✅ Users are informed about platform policies"
echo "✅ No content is stored - only official embed methods used"
echo "📋 Terms dialog is accessible via info button in video player"
