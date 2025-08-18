@echo off
title Share Target Implementation Test

echo 🚀 Share Target Implementation Test
echo ==================================
echo.

:: Check if Flutter is available
flutter --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Flutter not found. Please install Flutter first.
    pause
    exit /b 1
)

echo ✅ Flutter found

:: Check if we're in the right directory
if not exist "pubspec.yaml" (
    echo ❌ Not in Flutter project directory. Please cd to your project root.
    pause
    exit /b 1
)

echo ✅ In Flutter project directory

:: Install dependencies
echo 📦 Installing dependencies...
flutter pub get

if errorlevel 1 (
    echo ❌ Failed to install dependencies
    pause
    exit /b 1
)

echo ✅ Dependencies installed successfully

:: Test API endpoint (if backend is running)
echo.
echo 🔗 Testing API endpoint...
curl -s -w "%%{http_code}" -X POST "http://localhost:7071/api/playlists/test-playlist-id/items" ^
  -H "Content-Type: application/json" ^
  -H "x-user-id: test-user" ^
  -d "{\"title\":\"Test Shared Video\",\"url\":\"https://youtube.com/watch?v=test\"}" ^
  -o nul > temp_response.txt 2>&1

if exist temp_response.txt (
    set /p response=<temp_response.txt
    del temp_response.txt
    
    if "!response!"=="201" (
        echo ✅ API endpoint is working ^(HTTP 201^)
    ) else if "!response!"=="200" (
        echo ✅ API endpoint is working ^(HTTP 200^)
    ) else if "!response!"=="000" (
        echo ⚠️  Backend not running ^(start with 'func start' in api directory^)
    ) else (
        echo ⚠️  API returned HTTP !response! ^(check backend logs^)
    )
) else (
    echo ⚠️  Could not test API endpoint ^(curl might not be available^)
)

:: Check platform-specific files
echo.
echo 📱 Checking platform configurations...

:: Check Android manifest
findstr /C:"android.intent.action.SEND" android\app\src\main\AndroidManifest.xml >nul 2>&1
if errorlevel 1 (
    echo ❌ Android share target NOT configured
) else (
    echo ✅ Android share target configured
)

:: Check iOS info.plist
findstr /C:"CFBundleURLTypes" ios\Runner\Info.plist >nul 2>&1
if errorlevel 1 (
    echo ❌ iOS URL scheme NOT configured
) else (
    echo ✅ iOS URL scheme configured
)

:: Check if share handler exists
if exist "lib\services\share_handler.dart" (
    echo ✅ Share handler service created
) else (
    echo ❌ Share handler service missing
)

echo.
echo 🎯 Next Steps:
echo 1. Run 'flutter run -d android' to test on Android device
echo 2. Share a URL from Chrome/YouTube to test the feature
echo 3. For iOS: Follow ios_share_extension_setup.md instructions
echo.
echo 📚 See share_implementation_guide.md for detailed testing instructions
echo.
pause
