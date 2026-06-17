import 'package:flutter/material.dart';

import 'package:akuko/core/theme/app_colors.dart';
import 'package:akuko/core/utils/extensions.dart';

enum CollectionTab { myLibrary, myAuthors, wishlist, requests }

class CollectionTabBar extends StatelessWidget {
  const CollectionTabBar({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final CollectionTab selected;
  final ValueChanged<CollectionTab> onSelected;

  static const _labels = {
    CollectionTab.myLibrary: 'My Library',
    CollectionTab.myAuthors: 'My Authors',
    CollectionTab.wishlist: 'Wishlist',
    CollectionTab.requests: 'Requests',
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: CollectionTab.values.map((tab) {
          final isSelected = tab == selected;
          return GestureDetector(
            onTap: () => onSelected(tab),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected
                        ? AppColors.burntSienna
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                _labels[tab]!,
                style: context.textTheme.labelLarge?.copyWith(
                  color: isSelected
                      ? AppColors.burntSienna
                      : AppColors.textMuted,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
