import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralised access to environment configuration.
///
/// Values are resolved in the following order:
///   1. `--dart-define` (compile-time, highest priority)
///   2. `.env` file loaded via flutter_dotenv at startup
///   3. A safe fallback (usually an empty string)
class Env {
  const Env._();

  static String _read(String key, {String fallback = ''}) {
    const undefined = '__akuko_undefined__';
    final fromDefine = String.fromEnvironment(key, defaultValue: undefined);
    if (fromDefine != undefined && fromDefine.isNotEmpty) {
      return fromDefine;
    }
    return dotenv.maybeGet(key) ?? fallback;
  }

  static String get apiBaseUrl => _read(
        'AKUKO_API_BASE_URL',
        fallback: 'https://books.ikikearts.com/wp-json/akuko/v1/',
      );

  /// Paystack PUBLIC key (safe to ship in the client).
  static String get paystackPublicKey => _read('PAYSTACK_PUBLIC_KEY');

  static String get paystackCurrency =>
      _read('PAYSTACK_CURRENCY', fallback: 'NGN');

  static String get paystackPlanMonthly => _read('PAYSTACK_PLAN_MONTHLY');
  static String get paystackPlanYearly => _read('PAYSTACK_PLAN_YEARLY');

  static bool get isConfigured => apiBaseUrl.isNotEmpty;

  static bool get isPaystackConfigured => paystackPublicKey.isNotEmpty;

  static String get openAiApiKey => _read('OPENAI_API_KEY');

  static String get geminiApiKey => _read('GEMINI_API_KEY');

  static bool get isGeminiConfigured => geminiApiKey.isNotEmpty;

  /// Web OAuth client ID — required on Android for Google ID tokens.
  static String get googleWebClientId => _read('GOOGLE_WEB_CLIENT_ID');

  static bool get isGoogleSignInConfigured => googleWebClientId.isNotEmpty;
}
