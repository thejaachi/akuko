import 'package:akuko/core/auth/auth_session_manager.dart';
import 'package:akuko/core/error/exceptions.dart';
import 'package:akuko/core/error/failures.dart';
import 'package:akuko/core/utils/result.dart';
import 'package:akuko/features/subscriptions/data/datasources/subscription_remote_datasource.dart';
import 'package:akuko/features/subscriptions/data/models/subscription_model.dart';
import 'package:akuko/features/subscriptions/data/services/paystack_service.dart';
import 'package:akuko/features/subscriptions/domain/entities/paystack_transaction.dart';
import 'package:akuko/features/subscriptions/domain/entities/subscription.dart';
import 'package:akuko/features/subscriptions/domain/repositories/subscription_repository.dart';

class ApiSubscriptionRepository implements SubscriptionRepository {
  ApiSubscriptionRepository(this._remote, this._paystack, this._session);

  final SubscriptionRemoteDataSource _remote;
  final PaystackService _paystack;
  final AuthSessionManager _session;

  Failure _mapError(Object error) => switch (error) {
        AuthException(:final message) => AuthFailure(message, error),
        NetworkException(:final message) => NetworkFailure(message),
        ServerException(:final message) => ServerFailure(message, error),
        _ => UnknownFailure('Subscription operation failed', error),
      };

  @override
  Stream<Subscription> watchMySubscription() {
    final uid = _session.currentUser?.id ?? '';
    return _remote.watchMySubscription().map((rows) {
      if (rows.isEmpty) return Subscription.freeFor(uid);
      return SubscriptionModel.fromJson(rows.first);
    });
  }

  @override
  Future<Result<Subscription>> getMySubscription() {
    return guardAsync(
      () async {
        final row = await _remote.getMySubscription();
        final uid = _session.currentUser?.id ?? '';
        if (row == null) return Subscription.freeFor(uid);
        return SubscriptionModel.fromJson(row);
      },
      onError: (e, _) => _mapError(e),
    );
  }

  @override
  Future<Result<PaystackInit>> initializeTransaction({
    String? planCode,
    int? amount,
    String? currency,
    Map<String, dynamic>? metadata,
  }) {
    return guardAsync(
      () => _paystack.initializeTransaction(
        planCode: planCode,
        amount: amount,
        currency: currency,
        metadata: metadata,
      ),
      onError: (e, _) => _mapError(e),
    );
  }

  @override
  Future<Result<PaystackVerification>> verifyTransaction(String reference) {
    return guardAsync(
      () => _paystack.verifyTransaction(reference),
      onError: (e, _) => _mapError(e),
    );
  }

  @override
  Future<Result<void>> cancelSubscription() {
    return guardAsync(
      _paystack.cancelSubscription,
      onError: (e, _) => _mapError(e),
    );
  }
}
