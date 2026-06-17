/// App-wide constants and Supabase table/column names.
///
/// Table and column identifiers are kept here so the DB schema (which uses
/// `snake_case`) is referenced from a single place. Dart entities expose the
/// same fields in `camelCase`.
class AppConstants {
  const AppConstants._();

  static const String appName = 'Akuko';

  // Shared preferences keys.
  static const String prefsReaderTheme = 'akuko.reader.theme';
  static const String prefsReaderFontSize = 'akuko.reader.fontSize';
  static const String prefsReaderLineSpacing = 'akuko.reader.lineSpacing';
  static const String prefsReaderFontFamily = 'akuko.reader.fontFamily';
  static const String prefsCurrency = 'akuko.profile.currency';
  static const String prefsLocaleGreeting = 'akuko.locale_greeting';
  static const String prefsCowriesBalance = 'akuko.wallet.cowries_balance';
  static const String prefsReaderVolumeKeys = 'reader.volumeKeysEnabled';
  static const String prefsReaderTouchTurn = 'reader.touchTurnEnabled';
  static const String prefsAudioStreak = 'akuko.streaks.audioStreak';
  static const String prefsRewardXp = 'akuko.rewards.xp';
  static const String prefsJourneyLevel = 'akuko.journey.lastLevel';

  // Pagination defaults.
  static const int defaultPageSize = 20;
}

/// Supabase table names (matches `docs/CANONICAL_SPEC.md`).
class SupabaseTables {
  const SupabaseTables._();

  static const String profiles = 'profiles';
  static const String categories = 'categories';
  static const String books = 'books';
  static const String readingProgress = 'reading_progress';
  static const String bookmarks = 'bookmarks';
  static const String highlights = 'highlights';
  static const String notes = 'notes';
  static const String reviews = 'reviews';
  static const String readingLists = 'reading_lists';
  static const String readingListItems = 'reading_list_items';
  static const String readingGoals = 'reading_goals';
  static const String readingStreaks = 'reading_streaks';
  static const String subscriptionPlans = 'subscription_plans';
  static const String userSubscriptions = 'user_subscriptions';
  static const String aiSummaries = 'ai_summaries';
  static const String notifications = 'notifications';
  static const String featureFlags = 'feature_flags';
  static const String analyticsEvents = 'analytics_events';
  static const String wallets = 'wallets';
  static const String walletTransactions = 'wallet_transactions';
  static const String paymentTransactions = 'payment_transactions';
  static const String subscriptions = 'subscriptions';
  static const String bookRequests = 'book_requests';
  static const String readingCircles = 'reading_circles';
  static const String readingCircleMembers = 'reading_circle_members';
}
