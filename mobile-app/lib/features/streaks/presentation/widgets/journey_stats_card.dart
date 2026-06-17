import 'package:flutter/material.dart';

import 'package:akuko/core/theme/app_colors.dart';
import 'package:akuko/core/utils/extensions.dart';
import 'package:akuko/core/widgets/circular_journey_visual.dart';
import 'package:akuko/features/streaks/domain/entities/journey_reward.dart';

class JourneyStatsCard extends StatelessWidget {
  const JourneyStatsCard({required this.reward, super.key});

  final JourneyReward reward;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircularJourneyVisual(reward: reward, size: 120),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Akuko Journey',
                  style: context.textTheme.titleMedium?.copyWith(
                    color: AppColors.textWarm,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _MilestoneStat(
                  label: 'Page Turner',
                  value: '${reward.booksCompleted * 50 + reward.readingStreakDays * 10} pages',
                  type: MilestoneSymbolType.shield,
                ),
                const SizedBox(height: 8),
                _MilestoneStat(
                  label: 'Completed',
                  value: '${reward.booksCompleted}',
                  type: MilestoneSymbolType.openBook,
                ),
                const SizedBox(height: 8),
                _MilestoneStat(
                  label: 'Streak',
                  value: '${reward.readingStreakDays}d',
                  type: MilestoneSymbolType.risingSun,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestoneStat extends StatelessWidget {
  const _MilestoneStat({
    required this.label,
    required this.value,
    required this.type,
  });

  final String label;
  final String value;
  final MilestoneSymbolType type;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 22,
          height: 22,
          child: CustomPaint(
            painter: _MiniSymbolPainter(type: type),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: context.textTheme.titleSmall?.copyWith(
            color: AppColors.textWarm,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: context.textTheme.labelSmall?.copyWith(
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _MiniSymbolPainter extends CustomPainter {
  _MiniSymbolPainter({required this.type});

  final MilestoneSymbolType type;

  @override
  void paint(Canvas canvas, Size size) {
    MilestoneSymbolPainter(
      type: type,
      color: AppColors.warmGold,
    ).paint(canvas, size);
  }

  @override
  bool shouldRepaint(_MiniSymbolPainter old) => old.type != type;
}
