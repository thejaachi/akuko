import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:akuko/core/feature_flags/api_feature_flag_repository.dart';
import 'package:akuko/core/feature_flags/app_features.dart';
import 'package:akuko/core/feature_flags/feature_flag.dart';
import 'package:akuko/core/feature_flags/feature_flag_repository.dart';
import 'package:akuko/core/network/api_client_provider.dart';

final featureFlagRepositoryProvider = Provider<FeatureFlagRepository>((ref) {
  return ApiFeatureFlagRepository(ref.watch(featureFlagsApiProvider));
});

final featureFlagsProvider = FutureProvider<Map<String, FeatureFlag>>((ref) async {
  final repo = ref.watch(featureFlagRepositoryProvider);
  final result = await repo.refresh();
  return result.fold(
    (_) => repo.getAll(),
    (map) => map,
  );
});

final featureFlagsBootstrapProvider = Provider<void>((ref) {
  ref.watch(featureFlagsProvider);
});

final featureFlagSnapshotProvider = Provider<FeatureFlagSnapshot>((ref) {
  final async = ref.watch(featureFlagsProvider);
  return async.when(
    data: (_) => ref.watch(featureFlagRepositoryProvider).snapshot,
    loading: () => FeatureFlagSnapshot(AppFeatures.defaultFlags),
    error: (_, __) => FeatureFlagSnapshot(AppFeatures.defaultFlags),
  );
});

final isFeatureEnabledProvider = Provider.family<bool, String>((ref, key) {
  final snapshot = ref.watch(featureFlagSnapshotProvider);
  return snapshot.isEnabled(key, defaultValue: AppFeatures.defaultEnabled(key));
});
