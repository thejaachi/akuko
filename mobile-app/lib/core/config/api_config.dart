import 'package:akuko/core/config/env.dart';

/// WordPress Akuko Mobile API configuration.
class ApiConfig {
  const ApiConfig._();

  static String get baseUrl {
    final raw = Env.apiBaseUrl;
    return raw.endsWith('/') ? raw : '$raw/';
  }

  static Duration get connectTimeout => const Duration(seconds: 30);

  static Duration get receiveTimeout => const Duration(seconds: 30);

  static const int maxRetries = 2;
}
