## iOS Setup & Release Checklist

This repository now includes the platform code and configuration required for an iOS build. Follow the steps below on a Mac with the latest Xcode installed.

### 1. Prerequisites
- macOS with **Xcode 15+** and command line tools.
- Flutter SDK (run `flutter doctor` to confirm all checks).
- CocoaPods (`sudo gem install cocoapods`).
- An Apple Developer Program account (needed for signing, TestFlight, App Store submission).

### 2. One-time project setup
1. From the repo root run:
   ```sh
   flutter clean
   flutter pub get
   ```
2. Install iOS pods (only available on macOS):
   ```sh
   cd ios
   pod install
   cd ..
   ```
3. Open `ios/Runner.xcworkspace` in Xcode and set:
   - **Bundle Identifier** (e.g. `com.yourorg.natdemy`)
   - **Team** for code signing
   - Version / build numbers (match `pubspec.yaml`)
4. Ensure an App Icon set exists in `Runner/Assets.xcassets` (already generated via `flutter_launcher_icons`, update if branding changes).

### 3. Platform-specific considerations
- **Screen recording block**: `ScreenRecordingService` now works on iOS. By default the app hides content whenever iOS detects screen recording or mirroring; the Flutter method channel can temporarily disable that overlay.
- **Photo library access**: `Info.plist` contains `NSPhotoLibraryUsageDescription` and `NSPhotoLibraryAddUsageDescription` so the profile editor can read/write images.
- **Minimum iOS version**: set to 12.0 in the Podfile and Xcode build settings. Update both if you raise the minimum.
- **Networking**: all API calls use HTTPS (`https://lms.natdemy.com`), so no extra ATS exceptions are required. If you introduce plain HTTP endpoints you must update `Info.plist` accordingly.
- **URL launching / WhatsApp links**: currently open via HTTPS (`https://wa.me/...`), so no `LSApplicationQueriesSchemes` entries are necessary.

### 4. Building & running
- **Simulator/Device**:
  ```sh
  flutter run -d <device_id>
  ```
  or press **Run** inside Xcode with a connected iPhone / Simulator selected.
- **Release build**:
  ```sh
  flutter build ios --release
  ```
  Then open Xcode → **Product ▸ Archive** to generate the `.ipa` for TestFlight/App Store.

### 5. TestFlight / App Store
1. Create the App Store Connect record (matching bundle ID).
2. Upload the archive via Xcode Organizer or Apple’s Transporter app.
3. Configure App Privacy responses, screenshots (6.7", 6.5", 5.5"), and descriptive text.
4. Use TestFlight for QA before submitting for review.

### 6. Common issues
- **Pod install fails**: run `sudo gem install cocoapods`, then `arch -x86_64 pod install` if you’re on Apple Silicon and hit compatibility issues.
- **`flutter run` can’t find a device**: open Xcode once to accept the license, then launch a simulator via `open -a Simulator`.
- **Code signing errors**: verify the “Team” and provisioning profiles in Xcode’s Runner target settings. Debug/Release/Profile configs must all have valid signing.

Keep this document updated whenever new native permissions, plugins, or release steps are introduced.



