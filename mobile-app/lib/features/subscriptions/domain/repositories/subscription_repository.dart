import 'package:akuko/core/utils/result.dart';
import 'package:akuko/features/subscriptions/domain/entities/paystack_transaction.dart';
import 'package:akuko/features/subscriptions/domain/entities/subscription.dart';

/// Read + checkout contract for subscriptions.
///
/// Reads come from the `subscriptions` table (RLS: owner-only select). Mutating
/// operations are routed through Paystack edge functions — the client never
/// writes subscription status directly, and payment success is confirmed only
/// server-side.
abstract interface class SubscriptionRepository {
  /// Live stream of the current user's subscription (Supabase Realtime). Emits
  /// a `free` default until a row exists, then live updates as the webhook
  /// flips state. Errors surface to the stream.
  Stream<Subscription> watchMySubscription();

  /// One-shot fetch of the current user's subscription.
  Future<Result<Subscription>> getMySubscription();

  /// Initialize a Paystack transaction for [planCode] (a Paystack plan code) or
  /// an ad-hoc [amount] in minor units (kobo). Returns the hosted checkout URL.
  Future<Result<PaystackInit>> initializeTransaction({
    String? planCode,
    int? amount,
    String? currency,
    Map<String, dynamic>? metadata,
  });

  /// Verify a transaction by [reference] after the WebView checkout returns.
  Future<Result<PaystackVerification>> verifyTransaction(String reference);

  /// Cancel (disable auto-renew of) the current user's subscription via the
  /// backend. The subscription stays premium until the paid period ends.
  Future<Result<void>> cancelSubscription();
}
