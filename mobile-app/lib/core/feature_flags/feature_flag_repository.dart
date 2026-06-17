import 'package:akuko/core/feature_flags/feature_flag.dart';
import 'package:akuko/core/utils/result.dart';

/// Loads and caches feature flags from Supabase (`feature_flags` table).
abstract class FeatureFlagRepository {
  /// In-memory snapshot (empty until first [refresh]).
  FeatureFlagSnapshot get snapshot;

  /// Fetch remote flags, merge with defaults, update cache. Safe if table missing.
  Future<Result<Map<String, FeatureFlag>>> refresh();

  /// Returns cached map, or client defaults if never refreshed.
  Map<String, FeatureFlag> getAll();
}
