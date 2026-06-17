import 'package:akuko/core/api/api_client.dart';

class FeatureFlagsApi {
  FeatureFlagsApi(this._client);

  final AkukoApiClient _client;

  Future<List<Map<String, dynamic>>> list() async {
    final data = await _client.get('feature-flags');
    return apiListOf(data);
  }
}
