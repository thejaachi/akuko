import 'dart:async';

import 'package:akuko/core/api/premium_api.dart';
import 'package:akuko/core/auth/auth_session_manager.dart';
import 'package:akuko/core/error/exceptions.dart';

/// Premium subscription status via WordPress API (polls instead of Realtime).
class SubscriptionRemoteDataSource {
  SubscriptionRemoteDataSource(this._api, this._session);

  final PremiumApi _api;
  final AuthSessionManager _session;

  String get _userId {
    final id = _session.currentUser?.id;
    if (id == null) throw const AuthException('Not authenticated');
    return id;
  }

  Stream<List<Map<String, dynamic>>> watchMySubscription() async* {
    while (true) {
      try {
        final row = await getMySubscription();
        yield row == null ? <Map<String, dynamic>>[] : [row];
      } catch (_) {
        yield const [];
      }
      await Future<void>.delayed(const Duration(seconds: 30));
    }
  }

  Future<Map<String, dynamic>?> getMySubscription() async {
    try {
      final status = await _api.status();
      if (status == null) return null;
      return {
        ...status,
        'user_id': _userId,
      };
    } catch (e) {
      throw ServerException('Failed to load subscription', e);
    }
  }
}
