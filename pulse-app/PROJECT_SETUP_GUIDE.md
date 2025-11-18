# Pulse App - Project Setup Guide

## Quick Start (5 minutes)

This guide walks you through setting up the development environment and project structure for the Pulse App MVP.

---

## **Prerequisites**

### **General**
- Git (latest)
- GitHub account with SSH keys configured
- Text editor or IDE (VS Code, Xcode, Android Studio)

### **iOS Development**
- macOS 12.5+
- Xcode 14.0+ (download from App Store)
- CocoaPods: `sudo gem install cocoapods`

### **Android Development**
- macOS, Windows, or Linux
- Android Studio Giraffe (2022.3.1)+
- JDK 11+
- Android SDK 33+ (API level 33)

### **Backend/Firebase**
- Node.js 18+
- Firebase CLI: `npm install -g firebase-tools`
- Google Cloud account

---

## **Project Structure**

```
pulse-app/
├── .github/
│   └── workflows/           # CI/CD pipelines
│       ├── ios-build.yml
│       ├── android-build.yml
│       └── backend-deploy.yml
├── ios/                     # iOS app (SwiftUI)
│   ├── Pulse.xcodeproj
│   ├── Pulse/
│   │   ├── App.swift
│   │   ├── Scenes/
│   │   ├── ViewModels/
│   │   ├── Models/
│   │   ├── Services/
│   │   └── UI/
│   ├── PulseTests/
│   ├── Podfile
│   └── Podfile.lock
├── android/                 # Android app (Jetpack Compose)
│   ├── app/
│   ├── gradle/
│   ├── build.gradle
│   ├── settings.gradle
│   └── local.properties
├── backend/                 # Firebase Cloud Functions
│   ├── functions/
│   │   ├── src/
│   │   │   ├── routine-suggestions.ts
│   │   │   ├── achievement-handler.ts
│   │   │   ├── notification-dispatcher.ts
│   │   │   └── community-recommendations.ts
│   │   ├── tests/
│   │   └── package.json
│   ├── firestore.rules
│   ├── firebase.json
│   └── .firebaserc
├── docs/                    # Documentation
│   ├── USER_PERSONAS.md
│   ├── WIREFRAMES_UI_DESIGN.md
│   ├── TECHNICAL_ARCHITECTURE.md
│   ├── API_SPECIFICATION.md
│   └── DEPLOYMENT.md
├── .gitignore
├── README.md
└── CONTRIBUTING.md
```

---

## **Step 1: Repository Setup**

### **Clone the Repository**

```bash
# Clone via HTTPS
git clone https://github.com/pulse-app/pulse-mvp.git
cd pulse-mvp

# Clone via SSH (recommended)
git clone git@github.com:pulse-app/pulse-mvp.git
cd pulse-mvp
```

### **Create Development Branch**

```bash
# Create your feature branch
git checkout -b feature/setup-mvp

# Verify branch
git branch -a
```

### **Initialize Submodules (if using private docs)**

```bash
git submodule update --init --recursive
```

---

## **Step 2: iOS Development Setup**

### **Install Dependencies**

```bash
cd ios

# Install CocoaPods dependencies
pod install --repo-update

# Verify installation
ls -la Pods/
```

### **Open Project**

```bash
# Open workspace (NOT .xcodeproj)
open Pulse.xcworkspace
```

### **Verify Build**

```bash
# Build from command line
xcodebuild -workspace Pulse.xcworkspace \
  -scheme Pulse \
  -configuration Debug \
  -destination generic/platform=iOS \
  build
```

### **Configure Code Signing**

1. Open Pulse.xcworkspace in Xcode
2. Select "Pulse" target
3. Go to Signing & Capabilities
4. Select team account (or create free account)
5. Enable automatic code signing

### **First Run**

```bash
# Run simulator
xcodebuild -workspace Pulse.xcworkspace \
  -scheme Pulse \
  -destination 'platform=iOS Simulator,name=iPhone 14 Pro' \
  run
```

---

## **Step 3: Android Development Setup**

### **Install SDK Components**

Open Android Studio and install:
1. SDK Platform for Android 13 (API 33)
2. Google APIs for Android 13
3. Android Virtual Device (AVD) - Pixel 6 with Android 13

### **Configure Local Properties**

Create `android/local.properties`:

```properties
sdk.dir=/Users/YOUR_USERNAME/Library/Android/sdk
ndk.dir=/Users/YOUR_USERNAME/Library/Android/sdk/ndk/25.1.8937393
```

### **Sync Gradle**

```bash
cd android
./gradlew --version  # Verify Gradle
./gradlew clean      # Clean build
./gradlew build      # Build project
```

### **Run on Emulator**

```bash
# List available emulators
emulator -list-avds

# Start emulator
emulator -avd Pixel_6_API_33

# Build and run app
./gradlew installDebug
```

### **First Run**

```bash
# Run tests
./gradlew test

# Build APK for testing
./gradlew assembleDebug
```

---

## **Step 4: Firebase Backend Setup**

### **Create Firebase Project**

```bash
# Login to Firebase
firebase login

# Initialize Firebase project
firebase init

# Select features:
# - Authentication
# - Firestore Database
# - Cloud Functions
# - Cloud Storage
# - Hosting (optional)
```

### **Configure Project**

```bash
cd backend

# Install dependencies
npm install

# Verify Firebase config
cat firebase.json
```

### **Set Up Firestore**

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create new Firestore database
3. Select region: `us-central1` (or closest to users)
4. Start in test mode (secure later)
5. Deploy Firestore rules:

```bash
firebase deploy --only firestore:rules
```

### **Set Up Authentication**

1. In Firebase Console → Authentication
2. Enable sign-in methods:
   - Apple (iOS only)
   - Google
3. Add app IDs for iOS and Android

### **Deploy Cloud Functions**

```bash
cd backend/functions

# Install deps
npm install

# Deploy
firebase deploy --only functions
```

Verify deployment:

```bash
firebase functions:list
```

---

## **Step 5: Environment Variables & Secrets**

### **Create `.env` Files**

**iOS: `ios/.env.local`**
```
FIREBASE_PROJECT_ID=pulse-app-dev
FIREBASE_API_KEY=<your-api-key>
POSTHOG_API_KEY=<posthog-key>
```

**Android: `android/app/.env`**
```
FIREBASE_PROJECT_ID=pulse-app-dev
FIREBASE_API_KEY=<your-api-key>
POSTHOG_API_KEY=<posthog-key>
```

**Backend: `backend/.env.local`**
```
FIREBASE_PROJECT_ID=pulse-app-dev
POSTHOG_API_KEY=<posthog-key>
SENDGRID_API_KEY=<sendgrid-key>
```

### **Generate Secrets**

```bash
# Generate signing keys (Android)
keytool -genkey -v -keystore android/app/keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias pulse-app

# Add to .gitignore
echo "*.jks" >> .gitignore
echo ".env.local" >> .gitignore
```

---

## **Step 6: Git Configuration**

### **Configure Git Hooks**

```bash
# Install pre-commit hooks
pip install pre-commit
pre-commit install

# Create `.pre-commit-config.yaml`
cat > .pre-commit-config.yaml << EOF
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-json
      - id: check-yaml
  - repo: https://github.com/hadialqattan/pycln
    rev: v2.1.3
    hooks:
      - id: pycln
        args: [--all]
EOF
```

### **Create .gitignore**

```bash
# iOS
ios/Pods/
ios/Podfile.lock
ios/DerivedData/
ios/.DS_Store

# Android
android/.gradle/
android/local.properties
android/*.jks
android/app/debug/
android/app/release/

# Backend
backend/node_modules/
backend/.env.local
backend/lib/

# General
.DS_Store
.vscode/
.idea/
*.swp
*.swo
```

---

## **Step 7: Development Workflow**

### **Daily Sync**

```bash
# Update from main
git fetch origin
git rebase origin/main

# Install any new dependencies
cd ios && pod install
cd ../android && ./gradlew build
cd ../backend && npm install
```

### **Create Feature Branch**

```bash
git checkout -b feature/routine-engine-mvp
```

### **Commit Changes**

```bash
# Stage changes
git add .

# Commit with descriptive message
git commit -m "feat: implement routine engine with task scheduling"

# Push to branch
git push -u origin feature/routine-engine-mvp
```

### **Create Pull Request**

```bash
# Use GitHub CLI (if installed)
gh pr create --title "Implement Routine Engine" \
  --body "Adds task scheduling and routine execution logic"

# Or create manually on GitHub
```

---

## **Step 8: Running Tests**

### **iOS Tests**

```bash
cd ios

# Run unit tests
xcodebuild test -workspace Pulse.xcworkspace \
  -scheme Pulse \
  -destination 'platform=iOS Simulator,name=iPhone 14 Pro'

# Run with code coverage
xcodebuild test -workspace Pulse.xcworkspace \
  -scheme Pulse \
  -enableCodeCoverage YES
```

### **Android Tests**

```bash
cd android

# Run unit tests
./gradlew test

# Run instrumented tests (on emulator/device)
./gradlew connectedAndroidTest
```

### **Backend Tests**

```bash
cd backend/functions

# Run tests
npm test

# Run with coverage
npm run test:coverage
```

---

## **Step 9: Debugging & Development Tools**

### **iOS**

```bash
# Enable logging
export OS_LOG_LEVEL=debug

# Use Xcode debugger
# - Set breakpoints in Xcode
# - Run → Run (⌘R)
# - Console window shows logs

# Instrument app (performance)
Product → Profile (⌘I)
```

### **Android**

```bash
# View logs
./gradlew logcat

# Use Android Studio Debugger
# - Set breakpoints
# - Run → Debug 'app'
# - Logcat window shows logs

# Profile with Profiler
View → Tool Windows → Profiler
```

### **Firebase**

```bash
# View Firestore data
firebase firestore:delete --recursive

# Monitor functions
firebase functions:log

# Test security rules
firebase emulators:start
# Access emulator at localhost:4000
```

---

## **Step 10: Deployment Checklist**

### **Before Pushing to Production**

- [ ] All tests passing locally
- [ ] Code review approved (2+ reviewers)
- [ ] No console errors/warnings
- [ ] Performance metrics acceptable
- [ ] Security audit completed
- [ ] Firebase Firestore rules secured
- [ ] API keys rotated
- [ ] Documentation updated

### **Deploy to App Stores**

**iOS:**
```bash
cd ios

# Archive for App Store
xcodebuild archive -workspace Pulse.xcworkspace \
  -scheme Pulse \
  -archivePath ./build/Pulse.xcarchive

# Use Xcode Organizer for upload
# Xcode → Window → Organizer → Archives
```

**Android:**
```bash
cd android

# Build signed APK/AAB
./gradlew bundleRelease

# Upload to Google Play Console
# - Internal Testing → Production
```

---

## **Troubleshooting**

### **iOS: Pod Installation Failed**

```bash
# Clean and reinstall
rm -rf Pods/
rm -rf Podfile.lock
pod install --repo-update
```

### **Android: Gradle Sync Failed**

```bash
# Clean Gradle cache
./gradlew clean

# Sync with new build tools
./gradlew --refresh-dependencies build
```

### **Firebase: Authentication Error**

```bash
# Re-login
firebase logout
firebase login

# Verify project
firebase projects:list
```

### **Simulator/Emulator Issues**

```bash
# iOS: Reset simulator
xcrun simctl erase all

# Android: Delete and recreate AVD
emulator -list-avds
emulator -wipe-data -avd Pixel_6_API_33
```

---

## **Next Steps**

1. ✅ Clone repository
2. ✅ Set up iOS development environment
3. ✅ Set up Android development environment
4. ✅ Configure Firebase backend
5. → Begin Phase 2: Core Engine Implementation

---

## **Resources**

- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [Android Developer Guide](https://developer.android.com/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [SwiftUI Tutorial](https://developer.apple.com/tutorials/swiftui)
- [Jetpack Compose Tutorial](https://developer.android.com/jetpack/compose)

---

## **Support**

For setup issues or questions:
1. Check troubleshooting section above
2. Search GitHub Issues
3. Post in team Slack channel: #pulse-dev
4. Contact lead developer: dev@pulseapp.io

