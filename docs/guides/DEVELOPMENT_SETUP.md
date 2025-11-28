# Development Setup Guide

This guide will help you set up your development environment for CodeForge AI.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Android Development](#android-development)
3. [iOS Development](#ios-development)
4. [Flutter Development](#flutter-development)
5. [Backend Development](#backend-development)
6. [Common Issues](#common-issues)

## Prerequisites

### General Tools
- **Git**: Version control
- **Docker**: For backend services and databases
- **Docker Compose**: For orchestrating services
- **IDE**: VS Code, Android Studio, or Xcode

### API Keys (for backend)
- OpenAI API key or Anthropic API key (for AI features)
- Firebase project (for authentication, analytics, crashlytics)
- Google Cloud Platform or AWS account (for cloud services)

## Android Development

### System Requirements
- **OS**: Windows 10+, macOS 10.14+, or Linux
- **RAM**: 8GB minimum, 16GB recommended
- **Disk Space**: 10GB free space

### Installation Steps

#### 1. Install Android Studio
Download from [developer.android.com](https://developer.android.com/studio)

```bash
# macOS (via Homebrew)
brew install --cask android-studio

# Linux (Snap)
sudo snap install android-studio --classic
```

#### 2. Install Java Development Kit (JDK)
```bash
# macOS
brew install openjdk@17

# Linux (Ubuntu/Debian)
sudo apt-get install openjdk-17-jdk

# Verify installation
java -version  # Should show 17.x
```

#### 3. Configure Android SDK
Open Android Studio → Settings → Appearance & Behavior → System Settings → Android SDK

Install:
- Android SDK Platform 35 (Android 15)
- Android SDK Build-Tools 34.0.0
- Android Emulator
- Android SDK Platform-Tools

#### 4. Set Environment Variables
Add to your `~/.bashrc`, `~/.zshrc`, or equivalent:

```bash
export ANDROID_HOME=$HOME/Library/Android/sdk  # macOS
# export ANDROID_HOME=$HOME/Android/Sdk  # Linux
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
```

#### 5. Clone and Open Project
```bash
git clone https://github.com/Misha70707/tweny_fo_seven_tree_sixty_five.git
cd tweny_fo_seven_tree_sixty_five/mobile/android
```

Open the `mobile/android` directory in Android Studio.

#### 6. Sync Gradle
Android Studio will prompt you to sync Gradle. Click "Sync Now".

If sync fails, try:
```bash
./gradlew clean
./gradlew build --refresh-dependencies
```

#### 7. Create Emulator
Tools → Device Manager → Create Device
- Choose: Pixel 7 Pro
- System Image: Android 15 (API 35)
- AVD Name: CodeForge_Test

#### 8. Configure API Keys
Create `local.properties` in `mobile/android/`:

```properties
sdk.dir=/Users/yourname/Library/Android/sdk
OPENAI_API_KEY=your_openai_key_here
FIREBASE_PROJECT_ID=your_firebase_project
```

#### 9. Run the App
```bash
# Via Android Studio: Click the green "Run" button

# Via command line:
./gradlew installDebug
adb shell am start -n com.codeforgeai.app/.MainActivity
```

### Android Troubleshooting
- **Gradle sync fails**: Delete `.gradle` and `.idea` folders, restart Android Studio
- **Emulator won't start**: Enable virtualization in BIOS (VT-x for Intel, AMD-V for AMD)
- **Build errors**: `./gradlew clean` and rebuild

## iOS Development

### System Requirements
- **OS**: macOS 13 Ventura or later (iOS development requires macOS)
- **RAM**: 8GB minimum, 16GB recommended
- **Disk Space**: 20GB free (Xcode is large)

### Installation Steps

#### 1. Install Xcode
Download from Mac App Store or [developer.apple.com](https://developer.apple.com/xcode/)

```bash
# Or via command line (slower):
xcode-select --install
```

After installation:
```bash
sudo xcodebuild -license accept
```

#### 2. Install CocoaPods (optional, we prefer Swift Package Manager)
```bash
sudo gem install cocoapods
pod setup
```

#### 3. Install Homebrew (if not already installed)
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

#### 4. Install SwiftLint
```bash
brew install swiftlint
```

#### 5. Clone and Open Project
```bash
git clone https://github.com/Misha70707/tweny_fo_seven_tree_sixty_five.git
cd tweny_fo_seven_tree_sixty_five/mobile/ios
```

Open `CodeForgeAI.xcworkspace` (or `.xcodeproj` if no CocoaPods) in Xcode.

#### 6. Configure Signing
- Open project settings
- Select target: CodeForgeAI
- Signing & Capabilities tab
- Team: Select your Apple Developer account
- Bundle Identifier: com.codeforgeai.app (change if needed)

#### 7. Configure API Keys
Create `Config.xcconfig` in `mobile/ios/CodeForgeAI/`:

```
OPENAI_API_KEY = your_openai_key_here
FIREBASE_PROJECT_ID = your_firebase_project
```

Add to `.gitignore`:
```
Config.xcconfig
```

#### 8. Install Dependencies (if using CocoaPods)
```bash
cd mobile/ios
pod install
```

#### 9. Select Simulator
Product → Destination → iPhone 15 Pro (or any iOS 15+ simulator)

#### 10. Run the App
```bash
# Via Xcode: Cmd+R

# Via command line:
xcodebuild -workspace CodeForgeAI.xcworkspace \
  -scheme CodeForgeAI \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build
```

### iOS Troubleshooting
- **Signing errors**: Create a free Apple Developer account at [developer.apple.com](https://developer.apple.com)
- **Simulator not booting**: `killall -9 com.apple.CoreSimulator.CoreSimulatorService`
- **Build fails**: Clean build folder (Cmd+Shift+K), then rebuild

## Flutter Development

### System Requirements
- **OS**: Windows, macOS, or Linux
- **RAM**: 8GB minimum
- **Disk Space**: 10GB free

### Installation Steps

#### 1. Install Flutter SDK
Visit [flutter.dev](https://flutter.dev/docs/get-started/install)

```bash
# macOS
brew install flutter

# Linux
cd ~
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.16.0-stable.tar.xz
tar xf flutter_linux_3.16.0-stable.tar.xz
export PATH="$PATH:`pwd`/flutter/bin"
```

#### 2. Run Flutter Doctor
```bash
flutter doctor
```

Fix any issues reported (Android SDK, Xcode, etc.)

#### 3. Install Flutter Plugins
For VS Code:
- Flutter extension
- Dart extension

For Android Studio:
- Flutter plugin
- Dart plugin

#### 4. Clone and Setup Project
```bash
git clone https://github.com/Misha70707/tweny_fo_seven_tree_sixty_five.git
cd tweny_fo_seven_tree_sixty_five/mobile/cross-platform/flutter
flutter pub get
```

#### 5. Configure API Keys
Create `.env` file:

```env
OPENAI_API_KEY=your_key_here
FIREBASE_PROJECT_ID=your_project
API_BASE_URL=http://localhost:3000
```

#### 6. Run the App
```bash
# List devices
flutter devices

# Run on specific device
flutter run -d <device_id>

# Run in debug mode with hot reload
flutter run
```

### Flutter Troubleshooting
- **pub get fails**: `flutter clean && flutter pub get`
- **Hot reload not working**: Press `r` in terminal or restart app with `R`
- **Build errors**: Check `flutter doctor` output

## Backend Development

### System Requirements
- **OS**: Any (Windows, macOS, Linux)
- **RAM**: 4GB minimum
- **Docker**: 20.10+
- **Node.js**: 20+ (or Python 3.11+)

### Installation Steps

#### 1. Install Docker
Download from [docker.com](https://www.docker.com/products/docker-desktop)

```bash
# Verify installation
docker --version
docker-compose --version
```

#### 2. Install Node.js (if using Node backend)
```bash
# macOS
brew install node@20

# Linux (Ubuntu)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verify
node --version  # Should be v20.x
npm --version
```

#### 3. Install Python (if using Python backend)
```bash
# macOS
brew install python@3.11

# Linux
sudo apt-get install python3.11 python3.11-venv python3-pip

# Verify
python3 --version  # Should be 3.11.x
```

#### 4. Clone Repository
```bash
git clone https://github.com/Misha70707/tweny_fo_seven_tree_sixty_five.git
cd tweny_fo_seven_tree_sixty_five/backend
```

#### 5. Set Up Environment Variables
Create `.env` file in `backend/api/`:

```env
NODE_ENV=development
PORT=3000

# Database
DATABASE_URL=postgresql://postgres:password@localhost:5432/codeforge_dev
REDIS_URL=redis://localhost:6379

# AI Provider
OPENAI_API_KEY=your_openai_key_here
# or
ANTHROPIC_API_KEY=your_anthropic_key_here

# Authentication
JWT_SECRET=your_super_secret_jwt_key_change_this
JWT_EXPIRATION=15m
REFRESH_TOKEN_EXPIRATION=30d

# OAuth
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret
APPLE_CLIENT_ID=your_apple_client_id
APPLE_CLIENT_SECRET=your_apple_client_secret

# Firebase
FIREBASE_PROJECT_ID=your_firebase_project
FIREBASE_PRIVATE_KEY=your_firebase_private_key
FIREBASE_CLIENT_EMAIL=your_firebase_client_email

# Storage
GCS_BUCKET_NAME=codeforge-dev-files  # or AWS_S3_BUCKET
```

#### 6. Start Services with Docker Compose
```bash
cd backend
docker-compose up -d
```

This starts:
- PostgreSQL (port 5432)
- Redis (port 6379)
- pgAdmin (port 5050, optional)

#### 7. Install Dependencies
```bash
cd backend/api

# Node.js
npm install

# Python
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

#### 8. Run Database Migrations
```bash
# Node.js (with Prisma)
npx prisma migrate dev
npx prisma generate

# Python (with Alembic)
alembic upgrade head
```

#### 9. Seed Database (optional)
```bash
# Node.js
npm run seed

# Python
python scripts/seed.py
```

#### 10. Start Development Server
```bash
# Node.js
npm run dev  # Uses nodemon for hot reload

# Python
uvicorn main:app --reload  # FastAPI
# or
python manage.py runserver  # Django
```

API should be available at `http://localhost:3000`

#### 11. Verify Installation
```bash
curl http://localhost:3000/health
# Expected: {"status": "ok", "timestamp": "..."}
```

### Backend Troubleshooting
- **Port already in use**: Change PORT in `.env` or kill existing process
- **Database connection fails**: Ensure Docker containers are running: `docker ps`
- **Migration errors**: Drop database and recreate: `docker-compose down -v && docker-compose up -d`

## Common Issues

### All Platforms
**Issue**: Git clone fails
- **Solution**: Check network, try SSH instead of HTTPS, or download ZIP

**Issue**: Out of disk space
- **Solution**: Free up space, Docker images can be large: `docker system prune -a`

### API Keys
**Issue**: API calls return 401 Unauthorized
- **Solution**: Verify API keys in `.env` files, ensure they're not expired

### Firewall/Network
**Issue**: Can't connect to localhost services
- **Solution**: Check firewall settings, ensure Docker networking is enabled

## Next Steps

Once your environment is set up:

1. Read the [Architecture Overview](../architecture/OVERVIEW.md)
2. Review [API Documentation](../api/README.md)
3. Check open issues on GitHub
4. Join the Discord community (link in main README)

## Getting Help

- **Documentation**: [docs/](../)
- **Issues**: [GitHub Issues](https://github.com/Misha70707/tweny_fo_seven_tree_sixty_five/issues)
- **Discord**: [Community server](https://discord.gg/codeforgeai)
- **Email**: dev@codeforgeai.app

---

**Happy Coding!** 🚀
