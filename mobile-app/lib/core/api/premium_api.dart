import 'package:akuko/core/api/api_client.dart';

class PremiumApi {
  PremiumApi(this._client);

  final AkukoApiClient _client;

  Future<Map<String, dynamic>?> status() async {
    final data = await _client.get('premium/status', auth: true);
    if (data == null) return null;
    return Map<String, dynamic>.from(data as Map);
  }

  Future<Map<String, dynamic>> subscribe(String reference) async {
    final data = await _client.post(
      'premium/subscribe',
      auth: true,
      body: {'reference': reference},
    );
    return Map<String, dynamic>.from(data as Map);
  }
}
