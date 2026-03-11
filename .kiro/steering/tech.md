# Technology Stack

## Framework & Language
- Flutter SDK (Dart 3.11.1+)
- Material Design 3 with dark theme
- Target platforms: Android & iOS

## Key Dependencies
- `http` (1.6.0) - HTTP client for API communication
- `flutter_secure_storage` (10.0.0) - Secure token storage
- `shared_preferences` (2.5.4) - Local data persistence
- `jwt_decoder` (2.0.1) - JWT token parsing
- `intl` (0.20.2) - Internationalization and date formatting
- `cupertino_icons` (1.0.8) - iOS-style icons

## Backend Integration
- Spring Boot REST API (base URL: `http://10.0.2.2:8080/api` for Android emulator)
- JWT Bearer token authentication
- JSON request/response format

## Development Tools
- `flutter_lints` (6.0.0) - Recommended linting rules
- `flutter_test` - Built-in testing framework

## Common Commands

### Development
```bash
# Get dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# Run with hot reload
flutter run --hot

# Build for Android
flutter build apk

# Build for iOS
flutter build ios
```

### Testing & Quality
```bash
# Run tests
flutter test

# Analyze code
flutter analyze

# Check for outdated packages
flutter pub outdated

# Upgrade dependencies
flutter pub upgrade
```

### Cleanup
```bash
# Clean build artifacts
flutter clean

# Clean and reinstall dependencies
flutter clean && flutter pub get
```

## Build System
- Gradle (Android) - Kotlin DSL
- Xcode (iOS) - Swift
- Flutter build system manages cross-platform compilation
