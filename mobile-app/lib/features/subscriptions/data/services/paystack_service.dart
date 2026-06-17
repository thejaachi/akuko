import 'package:akuko/core/api/payments_api.dart';
import 'package:akuko/core/api/premium_api.dart';
import 'package:akuko/core/error/exceptions.dart';
import 'package:akuko/features/subscriptions/domain/entities/paystack_transaction.dart';

/// Paystack checkout helpers — verify/subscribe via WordPress API.
///
/// TODO(payments): `/payments/initialize` is not in API.md; hosted checkout
/// init remains unavailable until the backend exposes it.
class PaystackService {
  PaystackService(this._payments, this._premium);

  final PaymentsApi _payments;
  final PremiumApi _premium;

  static const String callbackUrlPrefix = 'https://akuko.app/paystack/callback';

  Future<PaystackInit> initializeTransaction({
    String? planCode,
    int? amount,
    String? currency,
    Map<String, dynamic>? metadata,
  }) async {
    // No WordPress initialize endpoint — document gap for operators.
    throw const ServerException(
      'Paystack checkout initialization is not available via the API yet. '
      'Use cowries or contact support.',
    );
  }

  Future<PaystackVerification> verifyTransaction(String reference) async {
    final verification = await _payments.verify(reference);
    if (verification.isSuccess) {
      try {
        await _premium.subscribe(reference);
      } catch (_) {
        // Premium subscribe may already be applied by verify webhook.
      }
    }
    return verification;
  }

  Future<void> cancelSubscription() async {
    // TODO(premium): No cancel endpoint in API.md.
    throw const ServerException('Subscription cancellation is not available yet.');
  }
}
