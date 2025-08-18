# iOS Share Extension Setup Instructions

Since iOS Share Extensions require Xcode configuration, you'll need to manually add this when you're ready to test on iOS:

## Steps to Add iOS Share Extension:

1. **Open iOS project in Xcode:**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Add Share Extension Target:**
   - File → New → Target
   - Choose "Share Extension" 
   - Product Name: "LookatdeezShare"
   - Bundle Identifier: "com.yourcompany.lookatdeez.share"
   - Language: Swift

3. **Configure Share Extension Info.plist:**
   Add to the Share Extension's Info.plist:
   ```xml
   <key>NSExtension</key>
   <dict>
       <key>NSExtensionAttributes</key>
       <dict>
           <key>NSExtensionActivationRule</key>
           <dict>
               <key>NSExtensionActivationSupportsWebURLWithMaxCount</key>
               <integer>1</integer>
               <key>NSExtensionActivationSupportsText</key>
               <true/>
           </dict>
       </dict>
       <key>NSExtensionMainStoryboard</key>
       <string>MainInterface</string>
       <key>NSExtensionPointIdentifier</key>
       <string>com.apple.share-services</string>
   </dict>
   ```

4. **Replace ShareViewController.swift content:**
   ```swift
   import UIKit
   import Social

   class ShareViewController: SLComposeServiceViewController {
       override func isContentValid() -> Bool {
           return true
       }
       
       override func didSelectPost() {
           if let content = contentText,
              let url = extractURL(from: content) {
               
               let urlScheme = "lookatdeez://share?url=\(url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
               
               if let shareURL = URL(string: urlScheme) {
                   self.extensionContext?.open(shareURL, completionHandler: { _ in
                       self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
                   })
               }
           }
       }
       
       override func configurationItems() -> [Any]! {
           return []
       }
       
       private func extractURL(from text: String) -> String? {
           let types: NSTextCheckingResult.CheckingType = .link
           let detector = try? NSDataDetector(types: types.rawValue)
           let matches = detector?.matches(in: text, options: [], range: NSMakeRange(0, text.count)) ?? []
           
           return matches.first?.url?.absoluteString
       }
   }
   ```

5. **Update main app URL scheme handling** (add to AppDelegate.swift):
   ```swift
   @available(iOS 9.0, *)
   override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
       if url.scheme == "lookatdeez" {
           // Handle the shared URL
           return true
       }
       return false
   }
   ```

## Testing:
- The share extension will appear in Safari, YouTube, etc. when you tap Share
- Your app icon will show up as "lookatdeez" 
- Tapping it will open your main app with the shared URL

## Note:
This setup is only needed for iOS. Android share targets work automatically with the AndroidManifest.xml changes we made.
