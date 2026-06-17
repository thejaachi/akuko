import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:akuko/core/theme/app_colors.dart';

/// Adire/Ankara-inspired geometric overlay. Complexity scales with tier.
enum PatternTier { free, standard, premium, vip }

class AfricanPatternPainter extends CustomPainter {
  AfricanPatternPainter({
    required this.tier,
    this.opacity = 0.12,
    this.color = AppColors.burntSienna,
  });

  final PatternTier tier;
  final double opacity;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final fillPaint = Paint()
      ..color = color.withOpacity(opacity * 0.6)
      ..style = PaintingStyle.fill;

    switch (tier) {
      case PatternTier.free:
        _drawLines(canvas, size, paint, spacing: 28);
      case PatternTier.standard:
        _drawLines(canvas, size, paint, spacing: 22);
        _drawTriangles(canvas, size, fillPaint, count: 6);
      case PatternTier.premium:
        _drawLines(canvas, size, paint, spacing: 18);
        _drawTriangles(canvas, size, fillPaint, count: 12);
        _drawDiamonds(canvas, size, paint, count: 8);
      case PatternTier.vip:
        _drawLines(canvas, size, paint, spacing: 14);
        _drawTriangles(canvas, size, fillPaint, count: 18);
        _drawDiamonds(canvas, size, paint, count: 16);
        _drawInterlock(canvas, size, paint);
    }
  }

  void _drawLines(Canvas canvas, Size size, Paint paint, {required double spacing}) {
    for (var x = 0.0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawTriangles(
    Canvas canvas,
    Size size,
    Paint paint, {
    required int count,
  }) {
    final rng = math.Random(42);
    for (var i = 0; i < count; i++) {
      final cx = rng.nextDouble() * size.width;
      final cy = rng.nextDouble() * size.height;
      final s = 8.0 + rng.nextDouble() * 10;
      final path = Path()
        ..moveTo(cx, cy - s)
        ..lineTo(cx - s, cy + s)
        ..lineTo(cx + s, cy + s)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  void _drawDiamonds(
    Canvas canvas,
    Size size,
    Paint paint, {
    required int count,
  }) {
    final rng = math.Random(7);
    for (var i = 0; i < count; i++) {
      final cx = rng.nextDouble() * size.width;
      final cy = rng.nextDouble() * size.height;
      final s = 5.0 + rng.nextDouble() * 8;
      final path = Path()
        ..moveTo(cx, cy - s)
        ..lineTo(cx + s, cy)
        ..lineTo(cx, cy + s)
        ..lineTo(cx - s, cy)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  void _drawInterlock(Canvas canvas, Size size, Paint paint) {
    const step = 24.0;
    for (var y = 0.0; y < size.height; y += step) {
      for (var x = 0.0; x < size.width; x += step) {
        canvas.drawArc(
          Rect.fromCircle(center: Offset(x, y), radius: step * 0.35),
          0,
          math.pi,
          false,
          paint,
        );
        canvas.drawArc(
          Rect.fromCircle(center: Offset(x + step / 2, y + step / 2), radius: step * 0.35),
          math.pi,
          math.pi,
          false,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(AfricanPatternPainter oldDelegate) =>
      oldDelegate.tier != tier || oldDelegate.opacity != opacity;
}

/// Stacks a [child] over a tier-pattern background.
class PatternBackground extends StatelessWidget {
  const PatternBackground({
    required this.tier,
    required this.child,
    this.patternColor,
    this.opacity,
    super.key,
  });

  final PatternTier tier;
  final Widget child;
  final Color? patternColor;
  final double? opacity;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: AfricanPatternPainter(
                tier: tier,
                color: patternColor ?? AppColors.warmGold,
                opacity: opacity ?? _opacityForTier(tier),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }

  static double _opacityForTier(PatternTier tier) => switch (tier) {
        PatternTier.free => 0.08,
        PatternTier.standard => 0.10,
        PatternTier.premium => 0.12,
        PatternTier.vip => 0.15,
      };
}
