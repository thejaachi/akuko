import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:akuko/core/analytics/analytics_service.dart';
import 'package:akuko/core/analytics/api_analytics_service.dart';
import 'package:akuko/core/network/api_client_provider.dart';

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return ApiAnalyticsService(ref.watch(analyticsApiProvider));
});
