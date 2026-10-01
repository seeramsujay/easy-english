class AppConstants {
  // RevenueCat API Key provided by user
  static const String revenueCatApiKey = 'test_GgvQOwcslbINPAtgGoOOehUJdhe';

  // RevenueCat Entitlement ID
  static const String proEntitlementId = 'easy_english_pro';

  // Offering Product Identifiers
  static const String productYearly = 'yearly';
  static const String productMonthly = 'monthly';

  // Vercel Gemini AI Coach Endpoint
  static const String aiCoachEndpoint = String.fromEnvironment(
    'AI_COACH_ENDPOINT',
    defaultValue: 'https://easy-english.vercel.app/api/coach',
  );

  // Signaling Server Endpoint
  static const String signalingEndpoint = String.fromEnvironment(
    'SIGNALING_ENDPOINT',
    defaultValue: 'wss://easyenglish-signaling.workers.dev',
  );

  // Legal & Support URLs
  static const String termsOfServiceUrl = 'https://easyenglish.app/terms';
  static const String privacyPolicyUrl = 'https://easyenglish.app/privacy';
}
