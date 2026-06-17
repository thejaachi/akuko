import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:akuko/core/network/api_client_provider.dart';
import 'package:akuko/features/auth/presentation/controllers/auth_controller.dart';
import 'package:akuko/features/subscriptions/data/datasources/subscription_remote_datasource.dart';
import 'package:akuko/features/subscriptions/data/repositories/api_subscription_repository.dart';
import 'package:akuko/features/subscriptions/data/services/paystack_service.dart';
import 'package:akuko/features/subscriptions/domain/entities/entitlements.dart';
import 'package:akuko/features/subscriptions/domain/entities/subscription.dart';
import 'package:akuko/features/subscriptions/domain/repositories/subscription_repository.dart';

final subscriptionRemoteDataSourceProvider =
    Provider<SubscriptionRemoteDataSource>((ref) {
  return SubscriptionRemoteDataSource(
    ref.watch(premiumApiProvider),
    ref.watch(authSessionManagerProvider),
  );
});

final paystackServiceProvider = Provider<PaystackService>((ref) {
  return PaystackService(
    ref.watch(paymentsApiProvider),
    ref.watch(premiumApiProvider),
  );
});

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return ApiSubscriptionRepository(
    ref.watch(subscriptionRemoteDataSourceProvider),
    ref.watch(paystackServiceProvider),
    ref.watch(authSessionManagerProvider),
  );
});

final mySubscriptionProvider = StreamProvider<Subscription>((ref) {
  ref.watch(currentUserProvider);
  return ref.watch(subscriptionRepositoryProvider).watchMySubscription();
});

final entitlementsProvider = Provider<Entitlements>((ref) {
  final sub = ref.watch(mySubscriptionProvider);
  return Entitlements.fromSubscription(sub.asData?.value);
});
