import 'package:akuko/core/utils/result.dart';
import 'package:akuko/features/notifications/domain/entities/app_notification.dart';

abstract interface class NotificationRepository {
  Future<Result<List<AppNotification>>> listForUser(String userId, {int limit});
  Future<Result<int>> unreadCount(String userId);
  Future<Result<void>> markRead(String notificationId);
}
