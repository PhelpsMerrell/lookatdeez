# Share Target Implementation - Testing Guide

## What We've Implemented

✅ **Android Share Target** - Automatically works via AndroidManifest.xml  
✅ **Flutter Share Handler** - Receives and processes shared URLs  
✅ **Smart Title Extraction** - Auto-fetches page titles from URLs  
✅ **Playlist Picker Modal** - Choose which playlist to add to  
✅ **Pre-filled Add Dialog** - Same UI as manual add, just pre-populated  

🔄 **iOS Share Extension** - Requires manual Xcode setup (see ios_share_extension_setup.md)

## User Flow (Android)

1. **External app** (YouTube, Chrome, etc.) → Share button
2. **Share menu appears** → "lookatdeez" shows as option  
3. **User taps lookatdeez** → App opens with playlist picker modal
4. **User selects playlist** → Navigate to playlist editor
5. **Add dialog appears** → URL + auto-extracted title pre-filled
6. **User confirms/edits** → Item added to playlist

## Testing Commands

### 1. Install Dependencies
```bash
cd C:\projects\FAANG\lookatdeez
flutter pub get
```

### 2. Test Current API (Verify Backend Works)
```bash
curl -X POST "http://localhost:7071/api/playlists/test-playlist-id/items" ^
  -H "Content-Type: application/json" ^
  -H "x-user-id: test-user" ^
  -d "{\"title\":\"Shared YouTube Video\",\"url\":\"https://youtube.com/watch?v=dQw4w9WgXcQ\"}"
```

### 3. Build and Test Android
```bash
# Build for Android
flutter build apk --debug

# Or run directly on connected device/emulator
flutter run -d android
```

### 4. Test Share Functionality (Android)
1. Install the app on Android device/emulator
2. Open Chrome/YouTube and navigate to any video
3. Tap Share button 
4. Look for "lookatdeez" in the share menu
5. Tap it → Should open your app with playlist picker

### 5. Test Web (Share not supported, but app should still work)
```bash
flutter run -d chrome
```

## Manual Testing Scenarios

### Android Share Test:
1. **YouTube Video**: Share from YouTube app → Should extract video title
2. **Website**: Share URL from Chrome → Should extract page title  
3. **Long URL**: Share complex URL → Should handle and extract
4. **Multiple URLs**: Share text with multiple URLs → Should pick first one

### Error Handling Test:
1. **Invalid URL**: Share non-URL text → Should show error
2. **Network timeout**: Share URL from offline → Should use fallback title
3. **No playlists**: Share when no playlists exist → Should show message

## Files Modified/Created:

### New Files:
- `lib/services/share_handler.dart` - Complete share handling logic
- `ios_share_extension_setup.md` - iOS setup instructions

### Modified Files:
- `pubspec.yaml` - Added share dependencies  
- `android/app/src/main/AndroidManifest.xml` - Android share target config
- `ios/Runner/Info.plist` - iOS URL scheme support
- `lib/main.dart` - Initialize share handler

## Next Steps:

1. **Test Android immediately** - Should work out of the box
2. **Set up iOS share extension** - Follow ios_share_extension_setup.md when ready
3. **Deploy to TestFlight/Play Store** - Share targets only work in production builds

## Architecture Notes:

- **Cross-platform**: Same Flutter code handles both iOS/Android
- **Reuses existing UI**: Share flow uses same playlist picker + add item dialog
- **Smart title extraction**: Fetches page metadata for better UX
- **Fallback handling**: Graceful degradation when title extraction fails
- **Platform detection**: Only initializes share handler on mobile platforms

## Troubleshooting:

### Android Issues:
- **App doesn't appear in share menu**: Check AndroidManifest.xml intent filters
- **App crashes on share**: Check Flutter logs for share_handler errors
- **No title extracted**: Check network permissions and URL accessibility

### iOS Issues (when implemented):
- **Share extension not visible**: Verify Xcode target configuration
- **App doesn't open**: Check URL scheme registration in Info.plist
- **Permission errors**: Verify App Transport Security settings

### General Issues:
- **API errors**: Verify backend is running on localhost:7071
- **No playlists**: Create at least one playlist before testing
- **Title extraction slow**: Normal for complex pages, shows loading indicator

## API Integration:

The share handler integrates with your existing API endpoints:

```dart
// Uses your existing playlist loading
ApiService.getPlaylists()

// Uses your existing add item endpoint  
ApiService.addItemToPlaylist(playlistId, title, url)
```

## Share Target Registration:

**Android** (automatic):
```xml
<intent-filter>
    <action android:name="android.intent.action.SEND" />
    <category android:name="android.intent.category.DEFAULT" />
    <data android:mimeType="text/plain" />
</intent-filter>
```

**iOS** (manual setup required):
```xml
<key>NSExtensionActivationRule</key>
<dict>
    <key>NSExtensionActivationSupportsWebURLWithMaxCount</key>
    <integer>1</integer>
</dict>
```

## Performance Considerations:

- **Title extraction**: 5-second timeout to prevent hanging
- **Modal loading**: Shows loading states during API calls
- **Memory management**: Properly disposes subscriptions
- **Error handling**: Graceful fallbacks for network issues

## Security Notes:

- **URL validation**: Extracts and validates URLs before processing
- **XSS protection**: Uses html parser package for safe title extraction
- **Network security**: iOS NSAppTransportSecurity allows HTTPS requests
- **Intent filtering**: Android filters ensure only text/URL content is received
