/// Product analytics hook (architecture seam). Implementations write to
/// `analytics_events` when deployed; otherwise no-op.
abstract class AnalyticsService {
  const AnalyticsService();

  /// Whether events are persisted (remote table + config).
  bool get isEnabled;

  /// Record a product event. [payload] is optional JSON-serializable data.
  Future<void> track(
    String eventType, {
    String? bookId,
    Map<String, Object?>? payload,
  });
}

/// No-op used when analytics is disabled or the table is missing.
class NoOpAnalyticsService implements AnalyticsService {
  const NoOpAnalyticsService();

  @override
  bool get isEnabled => false;

  @override
  Future<void> track(
    String eventType, {
    String? bookId,
    Map<String, Object?>? payload,
  }) async {}
}
