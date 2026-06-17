import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:akuko/core/theme/app_colors.dart';
import 'package:akuko/core/utils/extensions.dart';
import 'package:akuko/features/books/presentation/controllers/book_providers.dart';

/// African language filter chips below search on Home.
class LanguageFilterChips extends ConsumerWidget {
  const LanguageFilterChips({super.key});

  static const languages = [
    ('All', null),
    ('English', 'en'),
    ('Igbo', 'ig'),
    ('Yoruba', 'yo'),
    ('Hausa', 'ha'),
    ('Swahili', 'sw'),
    ('French', 'fr'),
    ('Arabic', 'ar'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedLanguageFilterProvider);

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: languages.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (label, code) = languages[i];
          final isSelected = selected == code;
          return FilterChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (_) =>
                ref.read(selectedLanguageFilterProvider.notifier).state = code,
            selectedColor: AppColors.forestGreen.withOpacity(0.35),
            checkmarkColor: AppColors.warmGold,
            side: BorderSide(
              color: isSelected ? AppColors.forestGreen : AppColors.cardBorder,
            ),
            labelStyle: TextStyle(
              color: isSelected ? AppColors.textWarm : AppColors.textMuted,
              fontSize: context.textTheme.labelLarge?.fontSize,
            ),
          );
        },
      ),
    );
  }
}
