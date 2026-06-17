import 'package:flutter/material.dart';

import 'package:akuko/core/theme/app_colors.dart';
import 'package:akuko/core/utils/extensions.dart';

class StreakPill extends StatelessWidget {
  const StreakPill({required this.days, super.key});

  final int days;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.warmSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department,
            size: 16,
            color: AppColors.burntSienna,
          ),
          const SizedBox(width: 4),
          Text(
            '$days day streak',
            style: context.textTheme.labelMedium?.copyWith(
              color: AppColors.burntSienna,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
