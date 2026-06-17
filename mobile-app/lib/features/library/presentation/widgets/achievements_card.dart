import 'package:flutter/material.dart';

import 'package:akuko/core/theme/app_colors.dart';
import 'package:akuko/core/utils/extensions.dart';
import 'package:akuko/core/widgets/circular_journey_visual.dart';
import 'package:akuko/features/streaks/domain/entities/journey_reward.dart';

class AchievementsCard extends StatelessWidget {
  const AchievementsCard({required this.reward, super.key});

  final JourneyReward reward;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.cardGradientStart, AppColors.cardGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          CircularJourneyVisual(reward: reward, size: 100),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Achievements',
                  style: context.textTheme.titleMedium?.copyWith(
                    color: AppColors.textWarm,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _AchievementRow(
                  label: 'Books completed',
                  value: '${reward.booksCompleted}',
                ),
                _AchievementRow(
                  label: 'Reading streak',
                  value: '${reward.readingStreakDays} days',
                ),
                _AchievementRow(
                  label: 'Level',
                  value: '${reward.level} · ${reward.levelTitle}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementRow extends StatelessWidget {
  const _AchievementRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.warmGold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: context.textTheme.labelSmall?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
          Text(
            value,
            style: context.textTheme.labelMedium?.copyWith(
              color: AppColors.textWarm,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
