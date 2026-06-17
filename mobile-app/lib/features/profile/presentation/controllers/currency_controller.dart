import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:akuko/core/config/shared_preferences_provider.dart';
import 'package:akuko/core/constants/app_constants.dart';

const supportedCurrencies = ['NGN', 'USD', 'GBP', 'EUR'];

class CurrencyController extends StateNotifier<String> {
  CurrencyController(this._ref) : super(_load(_ref));

  final Ref _ref;

  static String _load(Ref ref) {
    return ref.read(sharedPreferencesProvider).getString(
              AppConstants.prefsCurrency,
            ) ??
        'NGN';
  }

  Future<void> setCurrency(String code) async {
    if (!supportedCurrencies.contains(code)) return;
    state = code;
    await _ref
        .read(sharedPreferencesProvider)
        .setString(AppConstants.prefsCurrency, code);
  }
}

final currencyControllerProvider =
    StateNotifierProvider<CurrencyController, String>(
  CurrencyController.new,
);
