import 'package:akuko/core/api/notifications_api.dart';
import 'package:akuko/core/error/exceptions.dart';

class NotificationRemoteDataSource {
  NotificationRemoteDataSource(this._api);

  final NotificationsApi _api;

  Future<List<Map<String, dynamic>>> listForUser(
    String userId, {
    int limit = 20,
  }) async {
    try {
      return await _api.list(limit: limit);
    } catch (e) {
      throw ServerException('Failed to load notifications', e);
    }
  }

  Future<int> unreadCount(String userId) async {
    try {
      final rows = await _api.list(limit: 100);
      return rows.where((r) => r['is_read'] != true).length;
    } catch (e) {
      throw ServerException('Failed to count notifications', e);
    }
  }

  Future<void> insertMilestone({
    required String userId,
    required String title,
    required String body,
  }) async {
    // Server-side notifications only — client cannot insert milestones yet.
  }

  Future<void> markRead(String notificationId) async {
    // TODO(notifications): mark-read endpoint not in API.md.
    throw const ServerException('Mark read not available via API yet');
  }
}
