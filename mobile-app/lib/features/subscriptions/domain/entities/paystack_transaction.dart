import 'package:equatable/equatable.dart';

/// Result of initializing a Paystack transaction server-side. The client opens
/// [authorizationUrl] in a WebView and later verifies [reference].
class PaystackInit extends Equatable {
  const PaystackInit({
    required this.authorizationUrl,
    required this.reference,
    this.accessCode,
  });

  final String authorizationUrl;
  final String reference;
  final String? accessCode;

  @override
  List<Object?> get props => [authorizationUrl, reference, accessCode];
}

/// Outcome of a server-side transaction verification.
enum PaystackVerifyStatus { success, pending, failed }

class PaystackVerification extends Equatable {
  const PaystackVerification({required this.status});

  final PaystackVerifyStatus status;

  bool get isSuccess => status == PaystackVerifyStatus.success;

  static PaystackVerifyStatus statusFromWire(String? value) => switch (value) {
        'success' => PaystackVerifyStatus.success,
        'pending' || 'ongoing' || 'processing' => PaystackVerifyStatus.pending,
        _ => PaystackVerifyStatus.failed,
      };

  @override
  List<Object?> get props => [status];
}
