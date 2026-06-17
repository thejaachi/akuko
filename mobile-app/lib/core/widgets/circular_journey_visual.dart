import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:akuko/core/theme/app_colors.dart';
import 'package:akuko/core/utils/extensions.dart';
import 'package:akuko/features/streaks/domain/entities/journey_reward.dart';
import 'package:akuko/features/streaks/presentation/controllers/streak_providers.dart';

/// Interlocking circular journey visualization with cultural milestone badges.
class CircularJourneyVisual extends ConsumerWidget {
  const CircularJourneyVisual({
    required this.reward,
    this.size = 120,
    super.key,
  });

  final JourneyReward reward;
  final double size;

  static const _milestones = [
    _Milestone(
      id: 'pageTurner',
      label: 'Page Turner',
      threshold: 3,
      type: MilestoneSymbolType.shield,
    ),
    _Milestone(
      id: 'completed',
      label: 'Completed',
      threshold: 1,
      type: MilestoneSymbolType.openBook,
    ),
    _Milestone(
      id: 'streak',
      label: 'Streak',
      threshold: 7,
      type: MilestoneSymbolType.risingSun,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(readingStreakProvider);
    final streakDays = streakAsync.value?.currentStreak ?? reward.readingStreakDays;
    final booksDone = reward.booksCompleted;
    final pagesTurned = booksDone * 50 + streakDays * 10; // proxy for page-turner milestone

    final values = <String, int>{
      'pageTurner': pagesTurned,
      'completed': booksDone,
      'streak': streakDays,
    };

    final progress = reward.progressToNextLevel.clamp(0.0, 1.0);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _InterlockRingPainter(progress: progress),
          ),
          ...List.generate(_milestones.length, (i) {
            final m = _milestones[i];
            final achieved = (values[m.id] ?? 0) >= m.threshold;
            final angle = -math.pi / 2 + (2 * math.pi / _milestones.length) * i;
            final radius = size * 0.46;
            final badgeSize = 30.0;
            final x = size / 2 + radius * math.cos(angle) - badgeSize / 2;
            final y = size / 2 + radius * math.sin(angle) - badgeSize / 2;
            return Positioned(
              left: x,
              top: y,
              child: MilestoneBadge(
                type: m.type,
                achieved: achieved,
                size: badgeSize,
              ),
            );
          }),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Lv ${reward.level}',
                style: context.textTheme.titleMedium?.copyWith(
                  color: AppColors.textWarm,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                reward.levelTitle,
                style: context.textTheme.labelSmall?.copyWith(
                  color: AppColors.warmGold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum MilestoneSymbolType { shield, openBook, risingSun }

class MilestoneBadge extends StatelessWidget {
  const MilestoneBadge({
    required this.type,
    required this.achieved,
    this.size = 28,
    super.key,
  });

  final MilestoneSymbolType type;
  final bool achieved;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _label,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: achieved
              ? AppColors.forestGreen.withOpacity(0.9)
              : AppColors.warmSurface,
          border: Border.all(
            color: achieved ? AppColors.warmGold : AppColors.cardBorder,
            width: 1.5,
          ),
        ),
        child: CustomPaint(
          painter: MilestoneSymbolPainter(
            type: type,
            color: achieved ? AppColors.textWarm : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  String get _label => switch (type) {
        MilestoneSymbolType.shield => 'Page Turner',
        MilestoneSymbolType.openBook => 'Completed',
        MilestoneSymbolType.risingSun => 'Streak',
      };
}

class MilestoneSymbolPainter extends CustomPainter {
  MilestoneSymbolPainter({required this.type, required this.color});

  final MilestoneSymbolType type;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final fill = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final s = size.width * 0.28;

    switch (type) {
      case MilestoneSymbolType.shield:
        final shield = Path()
          ..moveTo(cx, cy - s)
          ..lineTo(cx + s * 0.85, cy - s * 0.3)
          ..lineTo(cx + s * 0.85, cy + s * 0.4)
          ..quadraticBezierTo(cx, cy + s * 1.1, cx - s * 0.85, cy + s * 0.4)
          ..lineTo(cx - s * 0.85, cy - s * 0.3)
          ..close();
        canvas.drawPath(shield, fill);
        canvas.drawPath(shield, paint);
      case MilestoneSymbolType.openBook:
        canvas.drawArc(
          Rect.fromCenter(center: Offset(cx - s * 0.3, cy), width: s, height: s * 1.2),
          -math.pi / 4,
          math.pi / 2,
          false,
          paint,
        );
        canvas.drawArc(
          Rect.fromCenter(center: Offset(cx + s * 0.3, cy), width: s, height: s * 1.2),
          3 * math.pi / 4,
          math.pi / 2,
          false,
          paint,
        );
        canvas.drawLine(Offset(cx, cy - s * 0.35), Offset(cx, cy + s * 0.35), paint);
      case MilestoneSymbolType.risingSun:
        canvas.drawArc(
          Rect.fromCenter(center: Offset(cx, cy + s * 0.2), width: s * 1.6, height: s),
          math.pi,
          math.pi,
          false,
          paint..strokeWidth = 1.6,
        );
        for (var i = -2; i <= 2; i++) {
          final angle = -math.pi / 2 + i * 0.35;
          canvas.drawLine(
            Offset(cx, cy - s * 0.1),
            Offset(cx + s * 0.7 * math.cos(angle), cy - s * 0.1 + s * 0.7 * math.sin(angle)),
            paint..strokeWidth = 1.2,
          );
        }
    }
  }

  @override
  bool shouldRepaint(MilestoneSymbolPainter old) =>
      old.type != type || old.color != color;
}

/// Interlocking double-ring progress painter.
class _InterlockRingPainter extends CustomPainter {
  _InterlockRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.width * 0.4;
    final innerR = size.width * 0.32;
    const stroke = 5.0;

    final bg = Paint()
      ..color = AppColors.cardBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final fg = Paint()
      ..shader = SweepGradient(
        colors: [
          AppColors.burntSienna,
          AppColors.warmGold,
          AppColors.forestGreen,
        ],
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
      ).createShader(Rect.fromCircle(center: center, radius: outerR))
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, outerR, bg);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: outerR),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fg,
    );

    // Inner interlocking ring — offset arc for visual depth.
    final innerPaint = Paint()
      ..color = AppColors.cobaltBlue.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, innerR, innerPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: innerR),
      math.pi / 4,
      math.pi * 0.75,
      false,
      innerPaint..color = AppColors.cobaltBlue.withOpacity(0.55),
    );
  }

  @override
  bool shouldRepaint(_InterlockRingPainter old) => old.progress != progress;
}

class _Milestone {
  const _Milestone({
    required this.id,
    required this.label,
    required this.threshold,
    required this.type,
  });

  final String id;
  final String label;
  final int threshold;
  final MilestoneSymbolType type;
}
