import 'package:akuko/core/analytics/analytics_service.dart';
import 'package:akuko/core/api/analytics_api.dart';

class ApiAnalyticsService implements AnalyticsService {
  ApiAnalyticsService(this._api, {this.enabled = true});

  final AnalyticsApi _api;
  final bool enabled;

  @override
  bool get isEnabled => enabled;

  @override
  Future<void> track(
    String eventType, {
    String? bookId,
    Map<String, Object?>? payload,
  }) async {
    if (!isEnabled) return;
    final merged = <String, Object?>{
      if (bookId != null) 'book_id': bookId,
      ...?payload,
    };
    await _api.track(eventType, payload: merged.isEmpty ? null : merged);
  }
}
