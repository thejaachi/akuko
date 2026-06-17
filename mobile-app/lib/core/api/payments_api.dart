import 'package:akuko/core/api/api_client.dart';
import 'package:akuko/features/subscriptions/domain/entities/paystack_transaction.dart';

class PaymentsApi {
  PaymentsApi(this._client);

  final AkukoApiClient _client;

  Future<PaystackVerification> verify(String reference) async {
    final data = await _client.post(
      'payments/verify',
      auth: true,
      body: {'reference': reference},
    ) as Map<String, dynamic>;

    return PaystackVerification(
      status: PaystackVerification.statusFromWire(
        data['status'] as String? ?? data['payment_status'] as String?,
      ),
    );
  }

  Future<List<Map<String, dynamic>>> history({
    int page = 1,
    int perPage = 30,
  }) async {
    final data = await _client.get(
      'payments/history',
      auth: true,
      queryParams: {'page': '$page', 'per_page': '$perPage'},
    );
    return apiListOf(data).map(apiNormalizeRow).toList();
  }
}
