import 'package:akuko/core/api/api_client.dart';

class NotificationsApi {
  NotificationsApi(this._client);

  final AkukoApiClient _client;

  Future<List<Map<String, dynamic>>> list({int limit = 20}) async {
    final data = await _client.get('notifications', auth: true);
    final list = apiListOf(data);
    return list.take(limit).map(apiNormalizeRow).toList();
  }

  Future<void> registerDeviceToken({
    required String token,
    required String platform,
  }) async {
    await _client.post(
      'notifications/device-token',
      auth: true,
      body: {'token': token, 'platform': platform},
    );
  }
}
