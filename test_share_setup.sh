#!/bin/bash

# Share Target Implementation - Quick Test Script
# Run this to verify your setup is working

echo "🚀 Share Target Implementation Test"
echo "=================================="
echo

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found. Please install Flutter first."
    exit 1
fi

echo "✅ Flutter found"

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Not in Flutter project directory. Please cd to your project root."
    exit 1
fi

echo "✅ In Flutter project directory"

# Install dependencies
echo "📦 Installing dependencies..."
flutter pub get

# Check if dependencies installed correctly
if [ $? -eq 0 ]; then
    echo "✅ Dependencies installed successfully"
else
    echo "❌ Failed to install dependencies"
    exit 1
fi

# Test API endpoint (if backend is running)
echo
echo "🔗 Testing API endpoint..."
response=$(curl -s -w "%{http_code}" -X POST "http://localhost:7071/api/playlists/test-playlist-id/items" \
  -H "Content-Type: application/json" \
  -H "x-user-id: test-user" \
  -d '{"title":"Test Shared Video","url":"https://youtube.com/watch?v=test"}' \
  -o /dev/null)

if [ "$response" -eq 201 ] || [ "$response" -eq 200 ]; then
    echo "✅ API endpoint is working (HTTP $response)"
elif [ "$response" -eq 000 ]; then
    echo "⚠️  Backend not running (start with 'func start' in api directory)"
else
    echo "⚠️  API returned HTTP $response (check backend logs)"
fi

# Check platform-specific files
echo
echo "📱 Checking platform configurations..."

# Check Android manifest
if grep -q "android.intent.action.SEND" android/app/src/main/AndroidManifest.xml; then
    echo "✅ Android share target configured"
else
    echo "❌ Android share target NOT configured"
fi

# Check iOS info.plist
if grep -q "CFBundleURLTypes" ios/Runner/Info.plist; then
    echo "✅ iOS URL scheme configured"
else
    echo "❌ iOS URL scheme NOT configured"
fi

# Check if share handler exists
if [ -f "lib/services/share_handler.dart" ]; then
    echo "✅ Share handler service created"
else
    echo "❌ Share handler service missing"
fi

echo
echo "🎯 Next Steps:"
echo "1. Run 'flutter run -d android' to test on Android device"
echo "2. Share a URL from Chrome/YouTube to test the feature"
echo "3. For iOS: Follow ios_share_extension_setup.md instructions"
echo
echo "📚 See share_implementation_guide.md for detailed testing instructions"
