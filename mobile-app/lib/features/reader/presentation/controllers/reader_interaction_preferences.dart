import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:akuko/core/config/shared_preferences_provider.dart';
import 'package:akuko/core/constants/app_constants.dart';

class ReaderInteractionPreferences {
  const ReaderInteractionPreferences({
    this.volumeKeysEnabled = false,
    this.touchTurnEnabled = true,
  });

  final bool volumeKeysEnabled;
  final bool touchTurnEnabled;

  ReaderInteractionPreferences copyWith({
    bool? volumeKeysEnabled,
    bool? touchTurnEnabled,
  }) {
    return ReaderInteractionPreferences(
      volumeKeysEnabled: volumeKeysEnabled ?? this.volumeKeysEnabled,
      touchTurnEnabled: touchTurnEnabled ?? this.touchTurnEnabled,
    );
  }
}

class ReaderInteractionPreferencesController
    extends StateNotifier<ReaderInteractionPreferences> {
  ReaderInteractionPreferencesController(this._prefs)
      : super(
          ReaderInteractionPreferences(
            volumeKeysEnabled:
                _prefs.getBool(AppConstants.prefsReaderVolumeKeys) ?? false,
            touchTurnEnabled:
                _prefs.getBool(AppConstants.prefsReaderTouchTurn) ?? true,
          ),
        );

  final SharedPreferences _prefs;

  Future<void> setVolumeKeysEnabled(bool value) async {
    state = state.copyWith(volumeKeysEnabled: value);
    await _prefs.setBool(AppConstants.prefsReaderVolumeKeys, value);
  }

  Future<void> setTouchTurnEnabled(bool value) async {
    state = state.copyWith(touchTurnEnabled: value);
    await _prefs.setBool(AppConstants.prefsReaderTouchTurn, value);
  }
}

final readerInteractionPreferencesProvider = StateNotifierProvider<
    ReaderInteractionPreferencesController, ReaderInteractionPreferences>((ref) {
  return ReaderInteractionPreferencesController(
    ref.watch(sharedPreferencesProvider),
  );
});
