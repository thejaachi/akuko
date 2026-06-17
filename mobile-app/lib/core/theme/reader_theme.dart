import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'package:akuko/core/theme/app_colors.dart';

/// Reading surface theme. Distinct from the app-wide [ThemeMode] because the
/// reader supports a `sepia` mode that Material does not model natively.
enum ReaderThemeMode {
  light,
  dark,
  sepia;

  String get label => switch (this) {
        ReaderThemeMode.light => 'Light',
        ReaderThemeMode.dark => 'Dark',
        ReaderThemeMode.sepia => 'Sepia',
      };

  Color get background => switch (this) {
        ReaderThemeMode.light => AppColors.lightBackground,
        ReaderThemeMode.dark => AppColors.earthBackground,
        ReaderThemeMode.sepia => AppColors.sepiaBackground,
      };

  Color get foreground => switch (this) {
        ReaderThemeMode.light => const Color(0xFF1A1A1A),
        ReaderThemeMode.dark => AppColors.textWarm,
        ReaderThemeMode.sepia => AppColors.sepiaText,
      };

  static ReaderThemeMode fromName(String? name) =>
      ReaderThemeMode.values.firstWhere(
        (m) => m.name == name,
        orElse: () => ReaderThemeMode.light,
      );
}

/// User-tunable reading preferences. Serialises to/from the
/// `profiles.reading_preferences` jsonb column:
/// `{fontSize, lineSpacing, themeMode, fontFamily}`.
class ReaderSettings extends Equatable {
  const ReaderSettings({
    this.fontSize = 18.0,
    this.lineSpacing = 1.5,
    this.themeMode = ReaderThemeMode.light,
    this.fontFamily = 'Literata',
  });

  final double fontSize;
  final double lineSpacing;
  final ReaderThemeMode themeMode;
  final String fontFamily;

  // Bounds used by the settings sliders.
  static const double minFontSize = 12;
  static const double maxFontSize = 32;
  static const double minLineSpacing = 1.0;
  static const double maxLineSpacing = 2.4;

  static const List<String> availableFonts = [
    'Literata',
    'Merriweather',
    'Lora',
    'Inter',
  ];

  ReaderSettings copyWith({
    double? fontSize,
    double? lineSpacing,
    ReaderThemeMode? themeMode,
    String? fontFamily,
  }) {
    return ReaderSettings(
      fontSize: fontSize ?? this.fontSize,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      themeMode: themeMode ?? this.themeMode,
      fontFamily: fontFamily ?? this.fontFamily,
    );
  }

  Map<String, dynamic> toJson() => {
        'fontSize': fontSize,
        'lineSpacing': lineSpacing,
        'themeMode': themeMode.name,
        'fontFamily': fontFamily,
      };

  factory ReaderSettings.fromJson(Map<String, dynamic> json) {
    return ReaderSettings(
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 18.0,
      lineSpacing: (json['lineSpacing'] as num?)?.toDouble() ?? 1.5,
      themeMode: ReaderThemeMode.fromName(json['themeMode'] as String?),
      fontFamily: json['fontFamily'] as String? ?? 'Literata',
    );
  }

  @override
  List<Object?> get props => [fontSize, lineSpacing, themeMode, fontFamily];
}
