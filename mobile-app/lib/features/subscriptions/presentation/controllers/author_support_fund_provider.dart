import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:akuko/core/config/shared_preferences_provider.dart';

const _prefsKey = 'author_support_fund_enabled';

/// Whether user opts to contribute 5% to Author Support Fund at checkout.
final authorSupportFundProvider =
    StateNotifierProvider<AuthorSupportFundNotifier, bool>((ref) {
  return AuthorSupportFundNotifier(ref.watch(sharedPreferencesProvider));
});

class AuthorSupportFundNotifier extends StateNotifier<bool> {
  AuthorSupportFundNotifier(this._prefs)
      : super(_prefs.getBool(_prefsKey) ?? false);

  final SharedPreferences _prefs;

  Future<void> setEnabled(bool value) async {
    state = value;
    await _prefs.setBool(_prefsKey, value);
  }

  void toggle() => setEnabled(!state);
}
