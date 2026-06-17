import 'package:equatable/equatable.dart';

/// Remote-config row from `feature_flags` (migration 0008+).
///
/// [phase] is the product launch phase (1–4) this flag belongs to; it is
/// informational for ops and docs — runtime gating uses [enabled] only.
class FeatureFlag extends Equatable {
  const FeatureFlag({
    required this.key,
    required this.enabled,
    required this.phase,
    this.description,
  });

  final String key;
  final bool enabled;
  final int phase;
  final String? description;

  @override
  List<Object?> get props => [key, enabled, phase, description];
}

/// Immutable snapshot used by [SubscriptionGuard] and the router.
class FeatureFlagSnapshot {
  const FeatureFlagSnapshot(this._byKey);

  factory FeatureFlagSnapshot.empty() => const FeatureFlagSnapshot({});

  final Map<String, FeatureFlag> _byKey;

  bool isEnabled(String key, {bool defaultValue = false}) {
    return _byKey[key]?.enabled ?? defaultValue;
  }

  int phaseFor(String key, {int defaultPhase = 4}) {
    return _byKey[key]?.phase ?? defaultPhase;
  }
}
