/// Localized home greeting strings.
///
/// Locale resolution order:
/// 1. `shared_preferences` key [prefsLocaleGreeting]
/// 2. `profiles.reading_preferences` jsonb `locale` field
/// 3. English default
///
/// TODO(geolocation): integrate a device-locale / geolocation package to infer
/// greeting language when no preference is stored.
library;

import 'package:akuko/core/constants/app_constants.dart';

/// Supported greeting languages for the home header.
enum GreetingLocale {
  en('en', 'Hello'),
  ig('ig', 'Nnọọ'),
  yo('yo', 'Kẹasạn'),
  ha('ha', 'Sannu');

  const GreetingLocale(this.code, this.greetingWord);

  final String code;
  final String greetingWord;

  static GreetingLocale fromCode(String? code) {
    if (code == null || code.isEmpty) return GreetingLocale.en;
    final normalized = code.toLowerCase().split('_').first.split('-').first;
    return GreetingLocale.values.firstWhere(
      (l) => l.code == normalized,
      orElse: () => GreetingLocale.en,
    );
  }
}

/// Formats a personalized greeting for the home header.
class GreetingLocalization {
  const GreetingLocalization._();

  static const prefsLocaleGreeting = AppConstants.prefsLocaleGreeting;

  /// Extracts the first token from [fullName] for a friendly salutation.
  static String firstName(String? fullName) {
    final trimmed = fullName?.trim();
    if (trimmed == null || trimmed.isEmpty) return 'Reader';
    return trimmed.split(RegExp(r'\s+')).first;
  }

  /// Returns e.g. `Hello, Amara` for English.
  static String format(GreetingLocale locale, String name) {
    final safeName = name.isEmpty ? 'Reader' : name;
    return '${locale.greetingWord}, $safeName';
  }
}
