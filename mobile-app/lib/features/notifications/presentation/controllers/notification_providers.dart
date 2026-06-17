import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:akuko/core/network/api_client_provider.dart';
import 'package:akuko/core/utils/result.dart';
import 'package:akuko/features/auth/presentation/controllers/auth_controller.dart';
import 'package:akuko/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:akuko/features/notifications/data/repositories/supabase_notification_repository.dart';
import 'package:akuko/features/notifications/domain/entities/app_notification.dart';
import 'package:akuko/features/notifications/domain/repositories/notification_repository.dart';

final notificationRemoteDataSourceProvider =
    Provider<NotificationRemoteDataSource>((ref) {
  return NotificationRemoteDataSource(ref.watch(notificationsApiProvider));
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return SupabaseNotificationRepository(
    ref.watch(notificationRemoteDataSourceProvider),
  );
});

final notificationsProvider =
    FutureProvider<List<AppNotification>>((ref) async {
  ref.watch(currentUserProvider);
  final userId = ref.watch(authRepositoryProvider).currentUser?.id;
  if (userId == null) return const [];
  return (await ref.watch(notificationRepositoryProvider).listForUser(userId))
      .getOrThrow();
});

final unreadNotificationCountProvider = FutureProvider<int>((ref) async {
  ref.watch(currentUserProvider);
  final userId = ref.watch(authRepositoryProvider).currentUser?.id;
  if (userId == null) return 0;
  return (await ref.watch(notificationRepositoryProvider).unreadCount(userId))
      .getOrThrow();
});
