import 'package:equatable/equatable.dart';

import 'package:akuko/features/subscriptions/domain/entities/subscription.dart';

/// The capability matrix derived from a [Subscription]. This is the single
/// source of truth for what a given tier may do; the `SubscriptionGuard`
/// (in `core/guards`) reads it and the UI gates features through the guard.
///
/// FREE vs PREMIUM:
///   * free    -> ads shown, limited downloads, no AI, no audiobooks, no sync
///   * premium -> ad-free, unlimited downloads, AI summaries/chat, audiobooks,
///                cloud sync
class Entitlements extends Equatable {
  const Entitlements({
    required this.isPremium,
    required this.showAds,
    required this.unlimitedDownloads,
    required this.maxFreeDownloads,
    required this.aiFeatures,
    required this.audiobooks,
    required this.cloudSync,
  });

  /// Free-tier capabilities.
  factory Entitlements.free() => const Entitlements(
        isPremium: false,
        showAds: true,
        unlimitedDownloads: false,
        maxFreeDownloads: 3,
        aiFeatures: false,
        audiobooks: false,
        cloudSync: false,
      );

  /// Premium-tier capabilities.
  factory Entitlements.premium() => const Entitlements(
        isPremium: true,
        showAds: false,
        unlimitedDownloads: true,
        maxFreeDownloads: -1, // unlimited
        aiFeatures: true,
        audiobooks: true,
        cloudSync: true,
      );

  /// Derive the active entitlement set from a subscription (null => free).
  factory Entitlements.fromSubscription(Subscription? subscription) {
    final premium = subscription?.isPremiumActive ?? false;
    return premium ? Entitlements.premium() : Entitlements.free();
  }

  final bool isPremium;
  final bool showAds;
  final bool unlimitedDownloads;

  /// Cap on offline downloads for the free tier (`-1` means unlimited).
  final int maxFreeDownloads;
  final bool aiFeatures;
  final bool audiobooks;
  final bool cloudSync;

  @override
  List<Object?> get props => [
        isPremium,
        showAds,
        unlimitedDownloads,
        maxFreeDownloads,
        aiFeatures,
        audiobooks,
        cloudSync,
      ];
}
