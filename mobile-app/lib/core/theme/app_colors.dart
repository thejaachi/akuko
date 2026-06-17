import 'package:flutter/material.dart';

/// African modernist palette for Akuko — earth tones, sienna, forest, cobalt.
class AppColors {
  const AppColors._();

  // ── Surfaces ──────────────────────────────────────────────────────────────
  static const Color earthBackground = Color(0xFF1A1410);
  static const Color charcoal = Color(0xFF121212);
  static const Color warmSurface = Color(0xFF2A221C);
  static const Color surfaceElevated = Color(0xFF332A22);

  // ── Accents (contextual) ──────────────────────────────────────────────────
  static const Color burntSienna = Color(0xFFC45C26);
  static const Color forestGreen = Color(0xFF2D5A3D);
  static const Color cobaltBlue = Color(0xFF2E4A7A);
  static const Color warmGold = Color(0xFFC9A227);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textWarm = Color(0xFFF5F0E8);
  static const Color textMuted = Color(0xFFA89B8C);

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const Color brandSeed = forestGreen;
  static const Color accent = burntSienna;
  static const Color premium = warmGold;
  static const Color error = Color(0xFFB3261E);

  // Light scheme surfaces.
  static const Color lightBackground = Color(0xFFFBFAF7);
  static const Color lightSurface = Color(0xFFFFFFFF);

  // Dark scheme — alias to earth palette.
  static const Color darkBackground = charcoal;
  static const Color darkSurface = warmSurface;

  // Sepia (reading-comfort) palette.
  static const Color sepiaBackground = Color(0xFFF4ECD8);
  static const Color sepiaSurface = Color(0xFFEDE3C8);
  static const Color sepiaText = Color(0xFF5B4636);

  // Card borders / gradients derived from warm surface.
  static const Color cardBorder = Color(0xFF3D3228);
  static const Color cardGradientStart = Color(0xFF2A221C);
  static const Color cardGradientEnd = Color(0xFF1A1410);

  // Primary accent alias (replaces former violet primary).
  static const Color primaryAccent = burntSienna;
  static const Color secondaryAccent = forestGreen;
  static const Color tertiaryAccent = cobaltBlue;
}
