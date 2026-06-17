/// Centralised route paths and names. Using constants (rather than string
/// literals scattered across the app) keeps navigation type-safe-ish and
/// refactor-friendly. Helper builders construct parameterised locations.
class AppRoutes {
  const AppRoutes._();

  // Auth
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Books / home
  static const String home = '/home';
  /// Legacy search path (inline search lives on Home; kept for deep links).
  static const String search = '/search';
  static const String categories = '/categories';

  /// Category listing, e.g. `/categories/:slug`.
  static const String categoryDetail = '/categories/:slug';

  /// Book detail, e.g. `/book/:id` (UUID or curated slug).
  static const String bookDetail = '/book/:id';

  /// Reader, e.g. `/read/:id`.
  static const String reader = '/read/:id';

  // Library & profile
  static const String library = '/library';
  static const String profile = '/profile';

  // Subscriptions / paywall
  static const String subscription = '/subscription';

  // Community & wallet
  static const String readingCircles = '/reading-circles';
  static const String circleDetail = '/reading-circles/:id';
  static const String requestBook = '/request-book';
  static const String catalogCategory = '/catalog/:category';
  static const String walletTopUp = '/wallet/top-up';

  // Profile sub-routes
  static const String profileEdit = '/profile/edit';
  static const String readingPreferences = '/profile/reading-preferences';
  static const String manageAddress = '/profile/manage-address';
  static const String transactionHistory = '/profile/transactions';
  static const String securityPrivacy = '/profile/security';
  static const String supportHelp = '/profile/support';
  static const String privacyPolicy = '/legal/privacy';
  static const String termsOfService = '/legal/terms';

  // Phased ecosystem (feature-flagged)
  static const String authorDashboard = '/author';
  static const String publisherDashboard = '/publisher';
  static const String admin = '/admin';
  static const String comingSoon = '/coming-soon';

  // ---- location builders ----
  static String categoryDetailPath(String slug) => '/categories/$slug';
  static String bookDetailPath(String id) => '/book/$id';
  static String circleDetailPath(String id) => '/reading-circles/$id';
  static String readerPath(String id) => '/read/$id';
  static String catalogCategoryPath(String category) => '/catalog/$category';
}

/// Named-route identifiers used with `context.goNamed` / `pushNamed`.
class AppRouteNames {
  const AppRouteNames._();

  static const String login = 'login';
  static const String register = 'register';
  static const String forgotPassword = 'forgotPassword';
  static const String home = 'home';
  static const String search = 'search';
  static const String categories = 'categories';
  static const String categoryDetail = 'categoryDetail';
  static const String bookDetail = 'bookDetail';
  static const String reader = 'reader';
  static const String library = 'library';
  static const String profile = 'profile';
  static const String subscription = 'subscription';
  static const String authorDashboard = 'authorDashboard';
  static const String publisherDashboard = 'publisherDashboard';
  static const String admin = 'admin';
  static const String comingSoon = 'comingSoon';
  static const String readingCircles = 'readingCircles';
  static const String circleDetail = 'circleDetail';
  static const String requestBook = 'requestBook';
  static const String catalogCategory = 'catalogCategory';
  static const String walletTopUp = 'walletTopUp';
  static const String profileEdit = 'profileEdit';
  static const String readingPreferences = 'readingPreferences';
  static const String manageAddress = 'manageAddress';
  static const String transactionHistory = 'transactionHistory';
  static const String securityPrivacy = 'securityPrivacy';
  static const String supportHelp = 'supportHelp';
  static const String privacyPolicy = 'privacyPolicy';
  static const String termsOfService = 'termsOfService';
}
