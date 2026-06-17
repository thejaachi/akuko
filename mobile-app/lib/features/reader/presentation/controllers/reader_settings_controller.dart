import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:akuko/core/config/shared_preferences_provider.dart';
import 'package:akuko/core/theme/reader_theme.dart';

const _prefsKey = 'akuko.reader.settings';

/// Holds and persists the user's [ReaderSettings] (font size, line spacing,
/// reader theme, font family). Persisted locally via shared_preferences for
/// instant startup; the profile sync to `reading_preferences` is Phase 2.
class ReaderSettingsController extends StateNotifier<ReaderSettings> {
  ReaderSettingsController(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static ReaderSettings _load(SharedPreferences prefs) {
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return const ReaderSettings();
    try {
      return ReaderSettings.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return const ReaderSettings();
    }
  }

  Future<void> _persist() async {
    await _prefs.setString(_prefsKey, jsonEncode(state.toJson()));
  }

  Future<void> setFontSize(double value) async {
    state = state.copyWith(
      fontSize: value.clamp(
        ReaderSettings.minFontSize,
        ReaderSettings.maxFontSize,
      ),
    );
    await _persist();
  }

  Future<void> setLineSpacing(double value) async {
    state = state.copyWith(
      lineSpacing: value.clamp(
        ReaderSettings.minLineSpacing,
        ReaderSettings.maxLineSpacing,
      ),
    );
    await _persist();
  }

  Future<void> setThemeMode(ReaderThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _persist();
  }

  Future<void> setFontFamily(String family) async {
    state = state.copyWith(fontFamily: family);
    await _persist();
  }
}

final readerSettingsProvider =
    StateNotifierProvider<ReaderSettingsController, ReaderSettings>((ref) {
  return ReaderSettingsController(ref.watch(sharedPreferencesProvider));
});
