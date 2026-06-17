import 'package:akuko/core/api/api_client.dart';

class AnalyticsApi {
  AnalyticsApi(this._client);

  final AkukoApiClient _client;

  Future<void> track(String event, {Map<String, Object?>? payload}) async {
    try {
      await _client.post(
        'analytics/event',
        body: {
          'event': event,
          if (payload != null) 'payload': payload,
        },
      );
    } catch (_) {
      // Analytics must never break UX.
    }
  }
}
