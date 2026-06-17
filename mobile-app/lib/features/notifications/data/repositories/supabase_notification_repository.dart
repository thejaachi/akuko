import 'package:akuko/core/error/exceptions.dart';
import 'package:akuko/core/error/failures.dart';
import 'package:akuko/core/utils/result.dart';
import 'package:akuko/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:akuko/features/notifications/data/models/app_notification_model.dart';
import 'package:akuko/features/notifications/domain/entities/app_notification.dart';
import 'package:akuko/features/notifications/domain/repositories/notification_repository.dart';

class SupabaseNotificationRepository implements NotificationRepository {
  SupabaseNotificationRepository(this._remote);

  final NotificationRemoteDataSource _remote;

  Failure _mapError(Object error) => switch (error) {
        ServerException(:final message) => ServerFailure(message, error),
        _ => UnknownFailure('Notification error', error),
      };

  @override
  Future<Result<List<AppNotification>>> listForUser(
    String userId, {
    int limit = 20,
  }) {
    return guardAsync(() async {
      final rows = await _remote.listForUser(userId, limit: limit);
      return rows.map(AppNotificationModel.fromJson).toList();
    }, onError: (e, _) => _mapError(e));
  }

  @override
  Future<Result<int>> unreadCount(String userId) {
    return guardAsync(
      () => _remote.unreadCount(userId),
      onError: (e, _) => _mapError(e),
    );
  }

  @override
  Future<Result<void>> markRead(String notificationId) {
    return guardAsync(() async {
      await _remote.markRead(notificationId);
    }, onError: (e, _) => _mapError(e));
  }
}
