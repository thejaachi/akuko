import 'package:flutter_riverpod/flutter_riverpod.dart';



import 'package:akuko/core/feature_flags/app_features.dart';

import 'package:akuko/core/feature_flags/feature_flag.dart';

import 'package:akuko/core/feature_flags/feature_flag_provider.dart';

import 'package:akuko/features/subscriptions/domain/entities/entitlements.dart';

import 'package:akuko/features/subscriptions/presentation/controllers/subscription_providers.dart';



/// Centralized premium access control. This is the single source of truth the

/// UI consults before exposing entitlement-gated features. It derives from

/// [Entitlements] (subscription tier) **and** [FeatureFlagSnapshot] (phased

/// rollout), so premium UX stays hidden until both subscription and flags allow it.

///

/// Server-side gating (signed-url / tts edge functions via `is_premium()`) is

/// the real enforcement boundary; this guard prevents the client from offering

/// premium UX to free users and routes them to the paywall instead.

class SubscriptionGuard {

  const SubscriptionGuard(this._entitlements, this._flags);



  final Entitlements _entitlements;

  final FeatureFlagSnapshot _flags;



  bool _flag(String key) =>

      _flags.isEnabled(key, defaultValue: AppFeatures.defaultEnabled(key));



  /// Premium tier is active (ad-free, full feature set when flags allow).

  bool isPremium() => _entitlements.isPremium;



  /// AI summaries (premium + `ai_summaries` flag).

  bool canUseAISummaries() =>

      _entitlements.aiFeatures && _flag(AppFeatures.aiSummaries);



  /// Reading assistant / Q&A (premium + `ai_assistant` flag).

  bool canUseAIAssistant() =>

      _entitlements.aiFeatures && _flag(AppFeatures.aiAssistant);



  /// Any AI surface (summaries or assistant).

  bool canUseAI() => canUseAISummaries() || canUseAIAssistant();



  /// Unlimited offline downloads (premium + `unlimited_downloads` flag).

  bool canDownloadUnlimited() =>

      _entitlements.unlimitedDownloads &&

      _flag(AppFeatures.unlimitedDownloads);



  /// Text-to-speech / audiobook mode (premium + `audiobook_mode` flag).

  bool canUseAudiobooks() =>

      _entitlements.audiobooks && _flag(AppFeatures.audiobookMode);



  /// Cross-device cloud sync (premium + `cloud_sync` flag).

  bool canCloudSync() =>

      _entitlements.cloudSync && _flag(AppFeatures.cloudSync);



  /// Whether ads should be shown (free tier only, when `ads` flag is on).

  bool showsAds() => _entitlements.showAds && _flag(AppFeatures.ads);



  /// Free-tier download cap (`-1` => unlimited).

  int get maxFreeDownloads => _entitlements.maxFreeDownloads;



  /// Creating reading circles (premium / VIP only).

  bool canCreateReadingCircle() => _entitlements.isPremium;

  /// Contextual dictionary — unlimited for premium subscribers.

  bool canUseUnlimitedDictionary() => _entitlements.isPremium;

  /// Free-tier daily dictionary lookup cap.

  int get dictionaryDailyLimit => 5;

  /// Max characters per reading-circle post (free vs paid).

  int circlePostCharLimit() => _entitlements.isPremium ? 500 : 140;

}



/// Reads live entitlements and feature flags; watch before gating UI.

final subscriptionGuardProvider = Provider<SubscriptionGuard>((ref) {

  return SubscriptionGuard(

    ref.watch(entitlementsProvider),

    ref.watch(featureFlagSnapshotProvider),

  );

});


