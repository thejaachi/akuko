import 'package:akuko/core/error/failures.dart';
import 'package:akuko/core/feature_flags/app_features.dart';
import 'package:akuko/core/feature_flags/feature_flag.dart';
import 'package:akuko/core/feature_flags/feature_flag_repository.dart';
import 'package:akuko/core/api/feature_flags_api.dart';
import 'package:akuko/core/utils/result.dart';

class ApiFeatureFlagRepository implements FeatureFlagRepository {
  ApiFeatureFlagRepository(this._api);

  final FeatureFlagsApi _api;

  Map<String, FeatureFlag> _cache = Map<String, FeatureFlag>.from(
    AppFeatures.defaultFlags,
  );

  @override
  FeatureFlagSnapshot get snapshot => FeatureFlagSnapshot(_cache);

  @override
  Map<String, FeatureFlag> getAll() => Map.unmodifiable(_cache);

  @override
  Future<Result<Map<String, FeatureFlag>>> refresh() async {
    return guardAsync(
      () async {
        final merged = Map<String, FeatureFlag>.from(AppFeatures.defaultFlags);
        try {
          final rows = await _api.list();
          for (final row in rows) {
            final key = row['key'] as String?;
            if (key == null || key.isEmpty) continue;
            merged[key] = FeatureFlag(
              key: key,
              enabled: row['enabled'] as bool? ?? false,
              phase: (row['phase'] as num?)?.toInt() ?? 4,
              description: row['description'] as String?,
            );
          }
        } catch (_) {
          _cache = merged;
          return merged;
        }
        _cache = merged;
        return merged;
      },
      onError: (error, _) => ServerFailure(
        'Could not load feature flags',
        error,
      ),
    );
  }
}
