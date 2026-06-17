import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:akuko/core/router/routes.dart';
import 'package:akuko/core/theme/app_colors.dart';
import 'package:akuko/shared/domain/entities/category.dart';

class GenreChipRow extends StatelessWidget {
  const GenreChipRow({
    required this.categories,
    this.selectedSlug,
    super.key,
  });

  final List<Category> categories;
  final String? selectedSlug;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = categories[i];
          final selected = cat.slug == selectedSlug;
          return FilterChip(
            label: Text(cat.name),
            selected: selected,
            onSelected: (_) =>
                context.push(AppRoutes.categoryDetailPath(cat.slug)),
            selectedColor: AppColors.forestGreen.withOpacity(0.35),
            checkmarkColor: AppColors.warmGold,
            side: BorderSide(
              color: selected ? AppColors.forestGreen : AppColors.cardBorder,
            ),
            backgroundColor: AppColors.surfaceElevated,
            labelStyle: TextStyle(
              color: selected ? AppColors.textWarm : AppColors.textMuted,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          );
        },
      ),
    );
  }
}
