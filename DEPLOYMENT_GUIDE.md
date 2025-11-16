# E-Learning Management App - Deployment Guide

## Phase 4 Deployment Requirements

This guide covers deploying the E-Learning Management application to multiple platforms as required for Phase 4.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Android APK Build](#android-apk-build)
3. [Windows EXE Build](#windows-exe-build)
4. [Web Deployment](#web-deployment)
5. [Testing Checklist](#testing-checklist)
6. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Software
- Flutter SDK 3.33.0 or higher
- Dart SDK 3.6.0 or higher
- Android Studio (for Android builds)
- Visual Studio 2022 (for Windows builds)
- Git
- Firebase CLI
- A code editor (VS Code recommended)

### Firebase Setup
Ensure Firebase is properly configured:
- `android/app/google-services.json` (Android)
- `web/firebase-config.js` (Web)
- `windows/runner/firebase_options.dart` (Windows)

### Dependencies Check
```bash
flutter doctor -v
```
Ensure all required dependencies are installed and configured.

---

## Android APK Build

### 1. Configure Build Settings

#### Update `android/app/build.gradle`:
```gradle
android {
    namespace = "com.example.e_learning_management"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.example.e_learning_management"
        minSdk = 21
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.debug
            // Note: For production, use proper signing configuration
        }
    }
}
```

### 2. Build APK

#### Debug APK (for testing):
```bash
flutter build apk --debug
```
Output: `build/app/outputs/flutter-apk/app-debug.apk`

#### Release APK (for distribution):
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

#### Build for multiple ABIs (recommended):
```bash
flutter build apk --split-per-abi --release
```
Outputs:
- `app-armeabi-v7a-release.apk` (32-bit ARM)
- `app-arm64-v8a-release.apk` (64-bit ARM)
- `app-x86_64-release.apk` (64-bit x86)

### 3. Test APK

Install on physical device or emulator:
```bash
flutter install
```

Or manually install:
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

### 4. APK Size Optimization

To reduce APK size:
```bash
flutter build apk --release --shrink --obfuscate --split-debug-info=build/debug-info
```

---

## Windows EXE Build

### 1. Enable Windows Support
```bash
flutter config --enable-windows-desktop
flutter create --platforms=windows .
```

### 2. Build Windows Application

#### Debug Build:
```bash
flutter build windows --debug
```

#### Release Build:
```bash
flutter build windows --release
```

Output directory: `build/windows/x64/runner/Release/`

### 3. Create Installer (Optional)

#### Using Inno Setup:

1. Install Inno Setup: https://jrsoftware.org/isdl.php

2. Create `installer.iss`:
```iss
[Setup]
AppName=E-Learning Management
AppVersion=1.0.0
DefaultDirName={pf}\ELearningManagement
DefaultGroupName=E-Learning Management
OutputDir=build\windows\installer
OutputBaseFilename=ELearningManagement-Setup
Compression=lzma2
SolidCompression=yes

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs

[Icons]
Name: "{group}\E-Learning Management"; Filename: "{app}\e_learning_management.exe"
Name: "{commondesktop}\E-Learning Management"; Filename: "{app}\e_learning_management.exe"
```

3. Build installer:
```bash
iscc installer.iss
```

#### Using MSIX:
```bash
flutter pub add msix
flutter pub run msix:create
```

### 4. Test Windows Build

Run the executable:
```bash
.\build\windows\x64\runner\Release\e_learning_management.exe
```

---

## Web Deployment

### 1. Build Web Version

#### Production Build:
```bash
flutter build web --release --web-renderer canvaskit
```

Alternative renderer (better compatibility):
```bash
flutter build web --release --web-renderer html
```

Auto-select renderer:
```bash
flutter build web --release --web-renderer auto
```

Output directory: `build/web/`

### 2. Deploy to Firebase Hosting

#### Initialize Firebase (if not done):
```bash
firebase login
firebase init hosting
```

When prompted:
- Choose `build/web` as public directory
- Configure as single-page app: **Yes**
- Set up automatic builds: **No** (for now)

#### Deploy:
```bash
firebase deploy --only hosting
```

Your app will be available at: `https://your-project-id.web.app`

### 3. Deploy to GitHub Pages (Alternative)

#### Update `pubspec.yaml`:
Add base href configuration in build command:
```bash
flutter build web --release --base-href "/e-learning-management/"
```

#### Deploy using GitHub Actions:

Create `.github/workflows/deploy.yml`:
```yaml
name: Deploy to GitHub Pages

on:
  push:
    branches: [ main ]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.33.0'

      - name: Build Web
        run: flutter build web --release --base-href "/e-learning-management/"

      - name: Deploy
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./build/web
```

### 4. Test Web Build Locally

```bash
cd build/web
python -m http.server 8000
```

Visit: `http://localhost:8000`

---

## Testing Checklist

### Pre-Deployment Testing

#### Android APK:
- [ ] App launches successfully
- [ ] Login/Register works
- [ ] All screens render correctly on different screen sizes
- [ ] CSV import functionality works
- [ ] Offline capability works
- [ ] Search/filter/sort works on all screens
- [ ] Notifications work
- [ ] Firebase connectivity verified
- [ ] No crashes during normal usage

#### Windows EXE:
- [ ] Application launches
- [ ] Login/Register works
- [ ] All features work as expected
- [ ] Window resizing works properly
- [ ] Responsive design works
- [ ] Firebase connectivity verified
- [ ] No crashes during normal usage

#### Web Application:
- [ ] App loads in Chrome
- [ ] App loads in Firefox
- [ ] App loads in Edge
- [ ] App loads in Safari
- [ ] Mobile browser compatibility
- [ ] All features work
- [ ] Responsive design verified
- [ ] Firebase connectivity verified
- [ ] No console errors

### Responsive Design Testing

#### Mobile (320px - 480px):
- [ ] Left sidebar collapses properly
- [ ] Right sidebar scales correctly
- [ ] Course grid shows 1 column
- [ ] Login/register screens readable
- [ ] Dialogs fit screen
- [ ] Text is readable
- [ ] Touch targets are adequate (44x44px min)

#### Tablet (481px - 768px):
- [ ] Sidebars scale appropriately
- [ ] Course grid shows 2 columns
- [ ] All screens usable
- [ ] No horizontal scrolling

#### Desktop (769px+):
- [ ] Course grid shows 3-4 columns
- [ ] Right sidebar shows at 400px width
- [ ] All features accessible
- [ ] Optimal layout utilized

---

## Build Optimization

### Reduce Build Size

#### For Android:
```bash
flutter build apk --release --shrink --obfuscate --split-per-abi
```

#### For Web:
```bash
flutter build web --release --tree-shake-icons --source-maps
```

### Performance Optimization

Add to `android/gradle.properties`:
```properties
org.gradle.jvmargs=-Xmx4096M
org.gradle.parallel=true
org.gradle.caching=true
```

---

## Troubleshooting

### Common Issues

#### Android Build Fails:
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter build apk --release
```

#### Windows Build Fails:
```bash
# Ensure Visual Studio 2022 is installed
# Run from VS Developer Command Prompt
flutter clean
flutter pub get
flutter build windows --release
```

#### Web Build Fails:
```bash
# Clear web cache
rm -rf build/web
flutter clean
flutter pub get
flutter build web --release
```

#### Firebase Connection Issues:
1. Check `google-services.json` is in `android/app/`
2. Verify `firebase-config.js` in `web/`
3. Run `flutterfire configure` to regenerate configs
4. Ensure Firebase project is active

#### APK Not Installing:
```bash
# Check for signing issues
# Enable USB debugging on device
# Check device security settings
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

---

## Deployment Checklist

### Before Submission:
- [ ] All builds compile successfully
- [ ] Android APK tested on physical device
- [ ] Windows EXE tested on Windows 10/11
- [ ] Web app deployed and accessible
- [ ] All mandatory Phase 4 features working:
  - [ ] CSV Import with preview
  - [ ] Semester switcher
  - [ ] Offline capability
  - [ ] Search/filter/sort on all screens
  - [ ] Responsive design
- [ ] Demo video recorded (5-10 minutes)
- [ ] Documentation complete
- [ ] All tests passing
- [ ] No critical bugs

### Submission Package:
- [ ] Android APK file
- [ ] Windows installer/executable
- [ ] Web deployment URL
- [ ] Source code (GitHub link)
- [ ] Demo video
- [ ] Documentation
- [ ] README with setup instructions

---

## Performance Benchmarks

### Target Metrics:
- **APK Size**: < 50MB (optimized)
- **Web First Load**: < 3 seconds
- **Windows EXE Size**: < 100MB
- **App Launch Time**: < 2 seconds
- **Screen Transitions**: < 300ms

---

## Post-Deployment

### Monitoring:
- Check Firebase Console for crash reports
- Monitor user feedback
- Track performance metrics
- Update as needed

### Maintenance:
- Keep dependencies updated
- Fix bugs promptly
- Add features based on feedback
- Regular security updates

---

## Additional Resources

- [Flutter Deployment Docs](https://docs.flutter.dev/deployment)
- [Firebase Hosting Docs](https://firebase.google.com/docs/hosting)
- [Android App Bundle Guide](https://developer.android.com/guide/app-bundle)
- [Windows Desktop Support](https://docs.flutter.dev/platform-integration/windows/building)

---

**Last Updated**: 2025-11-16
**Version**: 1.0.0
**Phase**: 4 - Deployment
