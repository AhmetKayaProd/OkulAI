# ÖdevAI Production Deployment Komutları

## Firebase Rules Deployment
```bash
# Deploy rules
firebase deploy --only firestore:rules

# Verify deployment
firebase firestore:rules:get

# Test rules (optional)
firebase emulators:start --only firestore
```

## Run Application
```bash
# With API key
flutter run --dart-define=GEMINI_API_KEY=your_key_here

# Or load from .env
# (requires flutter_dotenv package - currently not installed)
flutter run
```

## Test Commands
```bash
# All tests
flutter test

# Single file
flutter test test/models/homework_model_test.dart

# With coverage
flutter test --coverage
```

## Build Commands
```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# Check size
flutter build apk --analyze-size
```

## Firebase Emulator
```bash
# Start all emulators
firebase emulators:start

# Firestore only
firebase emulators:start --only firestore

# With UI
firebase emulators:start --only firestore,ui
```

## Maintenance
```bash
# Clean build
flutter clean
flutter pub get

# Update dependencies
flutter pub upgrade

# Doctor check
flutter doctor -v
```
