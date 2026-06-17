import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:akuko/core/constants/app_constants.dart';
import 'package:akuko/core/feature_flags/feature_flag_provider.dart';
import 'package:akuko/core/router/app_router.dart';
import 'package:akuko/core/theme/app_theme.dart';
import 'package:akuko/core/theme/theme_controller.dart';

/// Root application widget: wires the router, themes, and theme-mode controller.
class AkukoApp extends ConsumerWidget {
  const AkukoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(featureFlagsBootstrapProvider);
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeControllerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
