# API Key Setup for Production

## Development Mode (Current)
The app uses a hardcoded API key with environment variable fallback for development.

## Production Setup

### Option 1: Environment Variable (Recommended for Flutter)

**Build with environment variable**:
```bash
flutter build apk --dart-define=GEMINI_API_KEY=your_actual_api_key_here
flutter build appbundle --dart-define=GEMINI_API_KEY=your_prod_key_here
```

**For iOS**:
```bash
flutter build ios --dart-define=GEMINI_API_KEY=your_actual_api_key_here
```

### Option 2: Firebase Secret Manager (Most Secure)

1. Migrate API key to Firebase Secret Manager
2. Access via Cloud Functions
3. App calls Cloud Function instead of direct API

**Steps**:
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Add secret
firebase functions:secrets:set GEMINI_API_KEY
# Enter your API key when prompted

# Deploy functions with secret access
firebase deploy --only functions
```

### Option 3: Flutter Dotenv

1. Add `flutter_dotenv` to pubspec.yaml
2. Create `.env` file (add to .gitignore!)
3. Load in app initialization

**Example `.env`**:
```
GEMINI_API_KEY=AIzaSyYOUR_ACTUAL_KEY_HERE
```

## Security Checklist

- [ ] Remove hardcoded key from ai_config_store.dart
- [ ] Add .env to .gitignore
- [ ] Use environment variables for builds
- [ ] Migrate to Cloud Functions for production
- [ ] Enable API key restrictions in Google Cloud Console
- [ ] Set up key rotation schedule

## Current Status

✅ ApiConfig class created with environment variable support
✅ ai_config_store updated to use ApiConfig
⏸️ Waiting for production deployment decision

## Next Steps

1. Choose deployment strategy (Option 1, 2, or 3)
2. Update build scripts
3. Test with production API key
4. Deploy to staging environment
5. Monitor API usage and costs
