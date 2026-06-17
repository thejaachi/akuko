import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:akuko/core/theme/app_colors.dart';

/// Material 3 themes for Akuko: light, dark (earth-toned), and sepia reading.
class AppTheme {
  const AppTheme._();

  static ThemeData get light => _build(
        Brightness.light,
        ColorScheme.fromSeed(
          seedColor: AppColors.forestGreen,
          brightness: Brightness.light,
        ).copyWith(surface: AppColors.lightSurface),
        scaffoldBackground: AppColors.lightBackground,
      );

  static ThemeData get dark => _build(
        Brightness.dark,
        const ColorScheme(
          brightness: Brightness.dark,
          primary: AppColors.burntSienna,
          onPrimary: AppColors.textWarm,
          secondary: AppColors.forestGreen,
          onSecondary: AppColors.textWarm,
          tertiary: AppColors.cobaltBlue,
          onTertiary: AppColors.textWarm,
          error: AppColors.error,
          onError: Colors.white,
          surface: AppColors.warmSurface,
          onSurface: AppColors.textWarm,
          onSurfaceVariant: AppColors.textMuted,
          outline: AppColors.cardBorder,
          surfaceContainerHighest: AppColors.surfaceElevated,
        ),
        scaffoldBackground: AppColors.earthBackground,
      );

  /// A warm, low-contrast theme tuned for long reading sessions.
  static ThemeData get sepia => _build(
        Brightness.light,
        ColorScheme.fromSeed(
          seedColor: AppColors.warmGold,
          brightness: Brightness.light,
        ).copyWith(
          surface: AppColors.sepiaSurface,
          onSurface: AppColors.sepiaText,
        ),
        scaffoldBackground: AppColors.sepiaBackground,
      );

  static ThemeData _build(
    Brightness brightness,
    ColorScheme scheme, {
    required Color scaffoldBackground,
  }) {
    final baseTextTheme = brightness == Brightness.dark
        ? Typography.material2021().white
        : Typography.material2021().black;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBackground,
      textTheme: GoogleFonts.interTextTheme(baseTextTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBackground,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withOpacity(0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.burntSienna,
          foregroundColor: AppColors.textWarm,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
