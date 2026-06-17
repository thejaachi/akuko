import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:akuko/core/localization/greeting_localization.dart';
import 'package:akuko/features/profile/presentation/controllers/profile_providers.dart';

/// Resolved greeting locale from prefs or profile reading_preferences.
final greetingLocaleProvider = FutureProvider<GreetingLocale>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final fromPrefs = prefs.getString(GreetingLocalization.prefsLocaleGreeting);
  if (fromPrefs != null && fromPrefs.isNotEmpty) {
    return GreetingLocale.fromCode(fromPrefs);
  }

  final profile = await ref.watch(currentProfileProvider.future);
  final localeField = profile?.readingPreferences?['locale'];
  if (localeField is String && localeField.isNotEmpty) {
    return GreetingLocale.fromCode(localeField);
  }

  // TODO(geolocation): infer locale from device / geolocation when unset.
  return GreetingLocale.en;
});

/// Personalized home greeting, e.g. `Hello, Amara`.
final greetingProvider = Provider<AsyncValue<String>>((ref) {
  final profile = ref.watch(currentProfileProvider);
  final locale = ref.watch(greetingLocaleProvider);

  return profile.when(
    loading: () => const AsyncLoading(),
    error: (e, st) => AsyncError(e, st),
    data: (p) => locale.when(
      loading: () => const AsyncLoading(),
      error: (e, st) => AsyncError(e, st),
      data: (loc) {
        final name = GreetingLocalization.firstName(p?.fullName);
        return AsyncData(GreetingLocalization.format(loc, name));
      },
    ),
  );
});
