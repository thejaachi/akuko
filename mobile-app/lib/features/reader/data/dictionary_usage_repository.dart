import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:akuko/core/guards/subscription_guard.dart';

final dictionaryUsageRepositoryProvider =
    Provider<DictionaryUsageRepository>((ref) {
  return DictionaryUsageRepository(ref);
});

/// Tracks daily dictionary lookups via shared_preferences.
class DictionaryUsageRepository {
  DictionaryUsageRepository(this._ref);

  final Ref _ref;

  static const _prefsKey = 'dictionary_lookups_date';
  static const _prefsCountKey = 'dictionary_lookups_count';

  int get _dailyLimit =>
      _ref.read(subscriptionGuardProvider).dictionaryDailyLimit;

  bool get _unlimited =>
      _ref.read(subscriptionGuardProvider).canUseUnlimitedDictionary();

  Future<int?> remainingToday() async {
    if (_unlimited) return null;
    final used = await _countToday();
    return (_dailyLimit - used).clamp(0, _dailyLimit);
  }

  Future<bool> canLookup() async {
    if (_unlimited) return true;
    final remaining = await remainingToday();
    return (remaining ?? 0) > 0;
  }

  Future<void> recordLookup(String word) async {
    if (_unlimited) return;

    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    final storedDate = prefs.getString(_prefsKey);
    var count = prefs.getInt(_prefsCountKey) ?? 0;

    if (storedDate != today) {
      count = 0;
      await prefs.setString(_prefsKey, today);
    }

    count++;
    await prefs.setInt(_prefsCountKey, count);
  }

  Future<int> _countToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    final storedDate = prefs.getString(_prefsKey);
    if (storedDate != today) return 0;
    return prefs.getInt(_prefsCountKey) ?? 0;
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }
}
