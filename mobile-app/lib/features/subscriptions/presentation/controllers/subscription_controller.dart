import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:akuko/features/subscriptions/domain/entities/paystack_transaction.dart';
import 'package:akuko/features/subscriptions/domain/repositories/subscription_repository.dart';
import 'package:akuko/features/subscriptions/presentation/controllers/subscription_providers.dart';

/// Stages of the secure purchase flow:
///   idle -> initializing -> checkout -> verifying -> active | failed
enum SubscriptionFlowStage {
  idle,
  initializing,
  checkout,
  verifying,
  active,
  failed,
}

class SubscriptionFlowState extends Equatable {
  const SubscriptionFlowState({
    this.stage = SubscriptionFlowStage.idle,
    this.init,
    this.message,
  });

  final SubscriptionFlowStage stage;

  /// Present once a transaction is initialized (drives the checkout WebView).
  final PaystackInit? init;

  /// Error or status message for the UI.
  final String? message;

  bool get isBusy =>
      stage == SubscriptionFlowStage.initializing ||
      stage == SubscriptionFlowStage.verifying;

  SubscriptionFlowState copyWith({
    SubscriptionFlowStage? stage,
    PaystackInit? init,
    String? message,
  }) {
    return SubscriptionFlowState(
      stage: stage ?? this.stage,
      init: init ?? this.init,
      message: message,
    );
  }

  @override
  List<Object?> get props => [stage, init, message];
}

/// Orchestrates init -> checkout -> verify. Payment status is established only
/// by the server (`verifyTransaction` + webhook), never trusted from the WebView.
class SubscriptionController extends StateNotifier<SubscriptionFlowState> {
  SubscriptionController(this._repo) : super(const SubscriptionFlowState());

  final SubscriptionRepository _repo;

  /// Step 1: initialize a transaction. On success the state moves to
  /// `checkout` carrying the [PaystackInit] (authorization URL + reference).
  Future<PaystackInit?> startCheckout({
    String? planCode,
    int? amount,
    String? currency,
    Map<String, dynamic>? metadata,
  }) async {
    state = const SubscriptionFlowState(
      stage: SubscriptionFlowStage.initializing,
    );
    final result = await _repo.initializeTransaction(
      planCode: planCode,
      amount: amount,
      currency: currency,
      metadata: metadata,
    );
    return result.fold(
      (failure) {
        state = SubscriptionFlowState(
          stage: SubscriptionFlowStage.failed,
          message: failure.message,
        );
        return null;
      },
      (init) {
        state = SubscriptionFlowState(
          stage: SubscriptionFlowStage.checkout,
          init: init,
        );
        return init;
      },
    );
  }

  /// Step 2: verify after the checkout WebView returns. Establishes the real
  /// outcome from Paystack server-side.
  Future<bool> verify(String reference) async {
    state = state.copyWith(stage: SubscriptionFlowStage.verifying);
    final result = await _repo.verifyTransaction(reference);
    return result.fold(
      (failure) {
        state = SubscriptionFlowState(
          stage: SubscriptionFlowStage.failed,
          message: failure.message,
        );
        return false;
      },
      (verification) {
        if (verification.isSuccess) {
          state = const SubscriptionFlowState(
            stage: SubscriptionFlowStage.active,
          );
          return true;
        }
        state = const SubscriptionFlowState(
          stage: SubscriptionFlowStage.failed,
          message: 'Payment was not completed.',
        );
        return false;
      },
    );
  }

  /// Cancel auto-renew. Returns true on success.
  Future<bool> cancel() async {
    final result = await _repo.cancelSubscription();
    return result.fold(
      (failure) {
        state = state.copyWith(message: failure.message);
        return false;
      },
      (_) => true,
    );
  }

  /// If the user abandons checkout (closes the WebView without paying).
  void abortCheckout() {
    state = const SubscriptionFlowState(stage: SubscriptionFlowStage.idle);
  }

  void reset() => state = const SubscriptionFlowState();
}

final subscriptionControllerProvider =
    StateNotifierProvider<SubscriptionController, SubscriptionFlowState>((ref) {
  return SubscriptionController(ref.watch(subscriptionRepositoryProvider));
});
