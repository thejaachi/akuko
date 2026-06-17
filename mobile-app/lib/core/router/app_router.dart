import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';



import 'package:akuko/core/feature_flags/app_features.dart';

import 'package:akuko/core/feature_flags/feature_flag_provider.dart';

import 'package:akuko/core/router/main_shell.dart';

import 'package:akuko/core/router/routes.dart';

import 'package:akuko/core/widgets/coming_soon_page.dart';

import 'package:akuko/features/admin/admin_feature.dart';

import 'package:akuko/features/auth/presentation/controllers/auth_controller.dart';

import 'package:akuko/features/auth/presentation/pages/forgot_password_page.dart';

import 'package:akuko/features/auth/presentation/pages/login_page.dart';

import 'package:akuko/features/auth/presentation/pages/register_page.dart';

import 'package:akuko/features/author/author_feature.dart';

import 'package:akuko/features/books/presentation/pages/book_detail_page.dart';

import 'package:akuko/features/books/presentation/pages/category_catalog_page.dart';

import 'package:akuko/features/books/presentation/pages/category_page.dart';

import 'package:akuko/features/books/presentation/pages/home_page.dart';

import 'package:akuko/features/legal/privacy_policy_page.dart';
import 'package:akuko/features/legal/terms_of_service_page.dart';
import 'package:akuko/features/library/presentation/pages/request_book_page.dart';

import 'package:akuko/features/profile/presentation/pages/manage_address_page.dart';

import 'package:akuko/features/profile/presentation/pages/profile_edit_page.dart';

import 'package:akuko/features/profile/presentation/pages/reading_preferences_page.dart';

import 'package:akuko/features/profile/presentation/pages/security_privacy_page.dart';

import 'package:akuko/features/profile/presentation/pages/support_help_page.dart';

import 'package:akuko/features/profile/presentation/pages/transaction_history_page.dart';

import 'package:akuko/features/reading_circles/presentation/pages/circle_detail_page.dart';
import 'package:akuko/features/reading_circles/presentation/pages/reading_circles_page.dart';

import 'package:akuko/features/wallet/presentation/pages/top_up_wallet_page.dart';

import 'package:akuko/shared/domain/entities/profile.dart';


import 'package:akuko/features/library/presentation/pages/library_page.dart';

import 'package:akuko/features/profile/presentation/pages/profile_page.dart';

import 'package:akuko/features/publisher/publisher_feature.dart';

import 'package:akuko/features/reader/presentation/pages/reader_page.dart';

import 'package:akuko/features/subscriptions/presentation/pages/subscription_page.dart';



final _rootNavigatorKey = GlobalKey<NavigatorState>();



bool _isFlagOn(Ref ref, String key) =>
    ref.read(isFeatureEnabledProvider(key));



/// The app's GoRouter, wired to auth state and feature flags for redirects.

final routerProvider = Provider<GoRouter>((ref) {

  final authRepo = ref.watch(authRepositoryProvider);



  // Re-run redirects when auth or flags change.

  ref.watch(featureFlagSnapshotProvider);

  final refresh = ValueNotifier<int>(0);

  final authSub = authRepo.authStateChanges().listen((_) => refresh.value++);
  ref.listen(featureFlagsProvider, (_, __) => refresh.value++);

  ref.onDispose(() {
    authSub.cancel();
    refresh.dispose();
  });



  const authRoutes = {

    AppRoutes.login,

    AppRoutes.register,

    AppRoutes.forgotPassword,

  };



  const phasedRoutes = {

    AppRoutes.authorDashboard: AppFeatures.authorDashboard,

    AppRoutes.publisherDashboard: AppFeatures.publisherDashboard,

    AppRoutes.admin: AppFeatures.adminMobile,

  };



  String? phasedRedirect(String location) {

    final flagKey = phasedRoutes[location];

    if (flagKey == null) return null;

    if (!_isFlagOn(ref, flagKey)) return AppRoutes.comingSoon;

    return null;

  }



  return GoRouter(

    navigatorKey: _rootNavigatorKey,

    initialLocation: AppRoutes.home,

    refreshListenable: refresh,

    redirect: (context, state) {

      final loggedIn = authRepo.currentUser != null;

      final loc = state.matchedLocation;

      final goingToAuth = authRoutes.contains(loc);



      if (!loggedIn && !goingToAuth) return AppRoutes.login;

      if (loggedIn && goingToAuth) return AppRoutes.home;



      return phasedRedirect(loc);

    },

    routes: [

      GoRoute(

        path: AppRoutes.login,

        name: AppRouteNames.login,

        builder: (_, __) => const LoginPage(),

      ),

      GoRoute(

        path: AppRoutes.register,

        name: AppRouteNames.register,

        builder: (_, __) => const RegisterPage(),

      ),

      GoRoute(

        path: AppRoutes.forgotPassword,

        name: AppRouteNames.forgotPassword,

        builder: (_, __) => const ForgotPasswordPage(),

      ),



      GoRoute(

        path: AppRoutes.comingSoon,

        name: AppRouteNames.comingSoon,

        parentNavigatorKey: _rootNavigatorKey,

        builder: (_, __) => const ComingSoonPage(),

      ),



      GoRoute(

        path: AppRoutes.authorDashboard,

        name: AppRouteNames.authorDashboard,

        parentNavigatorKey: _rootNavigatorKey,

        builder: (_, __) => const AuthorDashboardPage(),

      ),

      GoRoute(

        path: AppRoutes.publisherDashboard,

        name: AppRouteNames.publisherDashboard,

        parentNavigatorKey: _rootNavigatorKey,

        builder: (_, __) => const PublisherDashboardPage(),

      ),

      GoRoute(

        path: AppRoutes.admin,

        name: AppRouteNames.admin,

        parentNavigatorKey: _rootNavigatorKey,

        builder: (_, __) => const AdminDeepLinkPage(),

      ),



      // Full-screen routes (rendered above the shell).

      GoRoute(

        path: AppRoutes.bookDetail,

        name: AppRouteNames.bookDetail,

        parentNavigatorKey: _rootNavigatorKey,

        builder: (_, state) =>

            BookDetailPage(bookId: state.pathParameters['id']!),

      ),

      GoRoute(

        path: AppRoutes.reader,

        name: AppRouteNames.reader,

        parentNavigatorKey: _rootNavigatorKey,

        builder: (_, state) =>

            ReaderPage(bookId: state.pathParameters['id']!),

      ),

      GoRoute(

        path: AppRoutes.categoryDetail,

        name: AppRouteNames.categoryDetail,

        parentNavigatorKey: _rootNavigatorKey,

        builder: (_, state) =>

            CategoryPage(slug: state.pathParameters['slug']!),

      ),

      GoRoute(

        path: AppRoutes.catalogCategory,

        name: AppRouteNames.catalogCategory,

        parentNavigatorKey: _rootNavigatorKey,

        builder: (_, state) => CategoryCatalogPage(

          categorySlug: state.pathParameters['category']!,

        ),

      ),

      GoRoute(

        path: AppRoutes.readingCircles,

        name: AppRouteNames.readingCircles,

        parentNavigatorKey: _rootNavigatorKey,

        builder: (_, __) => const ReadingCirclesPage(),

        routes: [

          GoRoute(

            path: ':id',

            name: AppRouteNames.circleDetail,

            builder: (_, state) => CircleDetailPage(

              circleId: state.pathParameters['id']!,

            ),

          ),

        ],

      ),

      GoRoute(

        path: AppRoutes.requestBook,

        name: AppRouteNames.requestBook,

        parentNavigatorKey: _rootNavigatorKey,

        builder: (_, __) => const RequestBookPage(),

      ),

      GoRoute(

        path: AppRoutes.walletTopUp,

        name: AppRouteNames.walletTopUp,

        parentNavigatorKey: _rootNavigatorKey,

        builder: (_, __) => const TopUpWalletPage(),

      ),

      GoRoute(

        path: AppRoutes.profileEdit,

        name: AppRouteNames.profileEdit,

        parentNavigatorKey: _rootNavigatorKey,

        builder: (_, state) =>

            ProfileEditPage(profile: state.extra! as Profile),

      ),

      GoRoute(

        path: AppRoutes.readingPreferences,

        name: AppRouteNames.readingPreferences,

        parentNavigatorKey: _rootNavigatorKey,

        builder: (_, __) => const ReadingPreferencesPage(),

      ),

      GoRoute(

        path: AppRoutes.manageAddress,

        name: AppRouteNames.manageAddress,

        parentNavigatorKey: _rootNavigatorKey,

        builder: (_, __) => const ManageAddressPage(),

      ),

      GoRoute(

        path: AppRoutes.transactionHistory,

        name: AppRouteNames.transactionHistory,

        parentNavigatorKey: _rootNavigatorKey,

        builder: (_, __) => const TransactionHistoryPage(),

      ),

      GoRoute(

        path: AppRoutes.securityPrivacy,

        name: AppRouteNames.securityPrivacy,

        parentNavigatorKey: _rootNavigatorKey,

        builder: (_, __) => const SecurityPrivacyPage(),

      ),

      GoRoute(

        path: AppRoutes.supportHelp,

        name: AppRouteNames.supportHelp,

        parentNavigatorKey: _rootNavigatorKey,

        builder: (_, __) => const SupportHelpPage(),

      ),

      GoRoute(

        path: AppRoutes.privacyPolicy,

        name: AppRouteNames.privacyPolicy,

        parentNavigatorKey: _rootNavigatorKey,

        builder: (_, __) => const PrivacyPolicyPage(),

      ),

      GoRoute(

        path: AppRoutes.termsOfService,

        name: AppRouteNames.termsOfService,

        parentNavigatorKey: _rootNavigatorKey,

        builder: (_, __) => const TermsOfServicePage(),

      ),

      // Bottom-navigation shell.

      StatefulShellRoute.indexedStack(

        builder: (_, __, navigationShell) =>

            MainShell(navigationShell: navigationShell),

        branches: [

          StatefulShellBranch(

            routes: [

              GoRoute(

                path: AppRoutes.home,

                name: AppRouteNames.home,

                builder: (_, __) => const HomePage(),

              ),

            ],

          ),

          StatefulShellBranch(

            routes: [

              GoRoute(

                path: AppRoutes.subscription,

                name: AppRouteNames.subscription,

                builder: (_, __) => const SubscriptionPage(),

              ),

            ],

          ),

          StatefulShellBranch(

            routes: [

              GoRoute(

                path: AppRoutes.library,

                name: AppRouteNames.library,

                builder: (_, __) => const LibraryPage(),

              ),

            ],

          ),

          StatefulShellBranch(

            routes: [

              GoRoute(

                path: AppRoutes.profile,

                name: AppRouteNames.profile,

                builder: (_, __) => const ProfilePage(),

              ),

            ],

          ),

        ],

      ),

    ],

  );

});


