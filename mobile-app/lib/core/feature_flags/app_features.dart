import 'package:akuko/core/feature_flags/feature_flag.dart';

/// Canonical feature-flag keys (wire format: snake_case in Supabase).
///
/// Client fallbacks in [defaultFlags] keep Phase 1 shippable before migration
/// `0008` deploys the `feature_flags` table.
class AppFeatures {
  const AppFeatures._();

  // Creator / publisher portals (Phase 3–4)
  static const String authorDashboard = 'author_dashboard';
  static const String publisherDashboard = 'publisher_dashboard';
  static const String royalties = 'royalties';
  static const String payouts = 'payouts';

  // Premium product surfaces (Phase 2+)
  static const String aiSummaries = 'ai_summaries';
  static const String aiAssistant = 'ai_assistant';
  static const String audiobookMode = 'audiobook_mode';
  static const String unlimitedDownloads = 'unlimited_downloads';
  static const String cloudSync = 'cloud_sync';

  // Community & engagement (Phase 2+)
  static const String reviews = 'reviews';
  static const String readingLists = 'reading_lists';
  static const String goals = 'reading_goals';
  static const String notifications = 'notifications';
  static const String highlights = 'highlights';

  // Monetization / ops
  static const String ads = 'ads';
  static const String adminMobile = 'admin_mobile';

  /// All known keys (for validation and default seeding).
  static const List<String> allKeys = [
    authorDashboard,
    publisherDashboard,
    royalties,
    payouts,
    aiSummaries,
    aiAssistant,
    audiobookMode,
    unlimitedDownloads,
    cloudSync,
    reviews,
    readingLists,
    goals,
    notifications,
    highlights,
    ads,
    adminMobile,
  ];

  /// Phase 1 client defaults when the remote table is absent or a key is missing.
  static Map<String, FeatureFlag> get defaultFlags => {
        for (final key in allKeys)
          key: FeatureFlag(
            key: key,
            enabled: _defaultEnabled(key),
            phase: _defaultPhase(key),
            description: _descriptions[key],
          ),
      };

  static bool defaultEnabled(String key) =>
      defaultFlags[key]?.enabled ?? false;

  static bool _defaultEnabled(String key) => switch (key) {
        ads => true,
        _ => false,
      };

  static int _defaultPhase(String key) => switch (key) {
        ads => 1,
        reviews || readingLists || goals || notifications || highlights => 2,
        aiSummaries ||
        aiAssistant ||
        audiobookMode ||
        unlimitedDownloads ||
        cloudSync =>
          2,
        authorDashboard || publisherDashboard => 3,
        royalties || payouts || adminMobile => 4,
        _ => 4,
      };

  static const Map<String, String> _descriptions = {
    authorDashboard: 'Author manuscript & earnings portal',
    publisherDashboard: 'Publisher catalogue & royalty ops',
    royalties: 'Royalty statements and accruals',
    payouts: 'Withdrawal requests',
    aiSummaries: 'AI book/chapter summaries',
    aiAssistant: 'In-reader reading assistant',
    audiobookMode: 'TTS / audiobook playback',
    unlimitedDownloads: 'Unlimited offline downloads (with premium)',
    cloudSync: 'Cross-device library sync',
    reviews: 'Book reviews & ratings UI',
    readingLists: 'Curated reading lists',
    goals: 'Reading goals & streaks',
    notifications: 'In-app notification center',
    highlights: 'Highlights & notes in reader',
    ads: 'Ad placements on free tier',
    adminMobile: 'Mobile admin entry (deep link only)',
  };
}
