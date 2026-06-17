import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:akuko/core/api/analytics_api.dart';
import 'package:akuko/core/api/api_client.dart';
import 'package:akuko/core/api/auth_api.dart';
import 'package:akuko/core/api/books_api.dart';
import 'package:akuko/core/api/downloads_api.dart';
import 'package:akuko/core/api/feature_flags_api.dart';
import 'package:akuko/core/api/notifications_api.dart';
import 'package:akuko/core/api/payments_api.dart';
import 'package:akuko/core/api/premium_api.dart';
import 'package:akuko/core/api/reading_api.dart';
import 'package:akuko/core/api/token_storage.dart';
import 'package:akuko/core/api/user_api.dart';
import 'package:akuko/core/auth/auth_session_manager.dart';
import 'package:akuko/core/config/shared_preferences_provider.dart';
import 'package:akuko/features/auth/domain/entities/auth_user.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage(ref.watch(sharedPreferencesProvider));
});

final authSessionManagerProvider = Provider<AuthSessionManager>((ref) {
  final manager = AuthSessionManager(ref.watch(tokenStorageProvider));
  ref.onDispose(manager.dispose);
  return manager;
});

final apiClientProvider = Provider<AkukoApiClient>((ref) {
  final client = AkukoApiClient(
    tokenStorage: ref.watch(tokenStorageProvider),
    onUnauthorized: () async => ref.read(authSessionManagerProvider).clear(),
  );
  ref.onDispose(client.dispose);
  return client;
});

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
  );
});

final booksApiProvider = Provider<BooksApi>((ref) {
  return BooksApi(ref.watch(apiClientProvider));
});

final readingApiProvider = Provider<ReadingApi>((ref) {
  return ReadingApi(ref.watch(apiClientProvider));
});

final premiumApiProvider = Provider<PremiumApi>((ref) {
  return PremiumApi(ref.watch(apiClientProvider));
});

final paymentsApiProvider = Provider<PaymentsApi>((ref) {
  return PaymentsApi(ref.watch(apiClientProvider));
});

final downloadsApiProvider = Provider<DownloadsApi>((ref) {
  return DownloadsApi(ref.watch(apiClientProvider));
});

final userApiProvider = Provider<UserApi>((ref) {
  return UserApi(ref.watch(apiClientProvider));
});

final notificationsApiProvider = Provider<NotificationsApi>((ref) {
  return NotificationsApi(ref.watch(apiClientProvider));
});

final analyticsApiProvider = Provider<AnalyticsApi>((ref) {
  return AnalyticsApi(ref.watch(apiClientProvider));
});

final featureFlagsApiProvider = Provider<FeatureFlagsApi>((ref) {
  return FeatureFlagsApi(ref.watch(apiClientProvider));
});

/// Streams auth user changes for router redirects.
final authStateChangesProvider = StreamProvider<AuthUser?>((ref) {
  return ref.watch(authSessionManagerProvider).authStateChanges;
});
