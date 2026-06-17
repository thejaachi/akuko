import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:akuko/core/config/shared_preferences_provider.dart';

const _prefsKey = 'akuko.app.themeMode';

/// Controls the app-wide [ThemeMode] (system / light / dark), persisted to
/// shared_preferences. The reader screen manages its own sepia-capable theme
/// via `ReaderSettings`.
class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController(this._ref) : super(_load(_ref));

  final Ref _ref;

  static ThemeMode _load(Ref ref) {
    final prefs = ref.read(sharedPreferencesProvider);
    final name = prefs.getString(_prefsKey);
    return ThemeMode.values.firstWhere(
      (m) => m.name == name,
      orElse: () => ThemeMode.dark,
    );
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await _ref.read(sharedPreferencesProvider).setString(_prefsKey, mode.name);
  }

  Future<void> toggle() => setMode(
        state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
      );
}

final themeModeControllerProvider =
    StateNotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);
