import 'package:flutter/material.dart';

import 'package:akuko/core/theme/app_colors.dart';
import 'package:akuko/core/utils/extensions.dart';
import 'package:akuko/shared/domain/entities/book_delivery_format.dart';

/// Delivery-format filter tabs: Ebooks · Audiobooks · Hardcopy.
class BookFormatFilterTabs extends StatelessWidget {
  const BookFormatFilterTabs({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final BookDeliveryFormat? selected;
  final ValueChanged<BookDeliveryFormat?> onSelected;

  static const _formats = [
    BookDeliveryFormat.ebook,
    BookDeliveryFormat.audiobook,
    BookDeliveryFormat.hardcopy,
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        children: _formats.map((format) {
          final isSelected = selected == format;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Material(
                color: isSelected
                    ? AppColors.forestGreen.withOpacity(0.18)
                    : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => onSelected(isSelected ? null : format),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.forestGreen
                            : AppColors.cardBorder,
                      ),
                    ),
                    child: Text(
                      format.label,
                      textAlign: TextAlign.center,
                      style: context.textTheme.labelMedium?.copyWith(
                        color: isSelected
                            ? AppColors.forestGreen
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
