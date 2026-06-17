import 'package:flutter/material.dart';

import 'package:akuko/core/theme/app_colors.dart';
import 'package:akuko/core/utils/extensions.dart';

enum ContentType { fiction, nonfiction, poetry }

class ContentTypeTabs extends StatelessWidget {
  const ContentTypeTabs({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final ContentType selected;
  final ValueChanged<ContentType> onSelected;

  static const _labels = {
    ContentType.fiction: 'Fiction',
    ContentType.nonfiction: 'Nonfiction',
    ContentType.poetry: 'Poetry',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: ContentType.values.map((type) {
          final isSelected = type == selected;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Material(
                color: isSelected
                    ? AppColors.burntSienna.withOpacity(0.2)
                    : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onSelected(type),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.burntSienna
                            : AppColors.cardBorder,
                      ),
                    ),
                    child: Text(
                      _labels[type]!,
                      textAlign: TextAlign.center,
                      style: context.textTheme.labelLarge?.copyWith(
                        color: isSelected
                            ? AppColors.burntSienna
                            : AppColors.textMuted,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
