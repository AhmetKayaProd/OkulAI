/// Gemini API Configuration
/// 
/// SECURITY NOTE: This file contains sensitive API key
/// For production, migrate to:
/// 1. Flutter environment variables
/// 2. Firebase Secret Manager
/// 3. Cloud Functions

class ApiConfig {
  // Environment variable with fallback for development
  static String get geminiApiKey {
    const apiKey = String.fromEnvironment(
      'GEMINI_API_KEY',
      defaultValue: 'AIzaSyBWKE_QM7on4ljJRCjaDQb9-Aj-2mKlGjQ', // NEW WORKING KEY
    );
    return apiKey;
  }

  // Warning message for hardcoded key usage
  static bool get isUsingFallbackKey {
    return geminiApiKey == 'AIzaSyBSJ8H2jn2KXiqKra-Bc2xGtWJcungDCQU';
  }

  static String get securityWarning {
    return isUsingFallbackKey
        ? '⚠️ Using development API key. Set GEMINI_API_KEY environment variable for production.'
        : '✓ Using environment API key';
  }
}
