import 'package:flutter/material.dart';

import 'package:akuko/core/theme/app_colors.dart';
import 'package:akuko/core/utils/extensions.dart';

/// Stylized Akuko mark — geometric typeface + interlocking Adinkra wisdom symbol.
class AkukoLogoMark extends StatelessWidget {
  const AkukoLogoMark({
    this.size = 36,
    this.showLabel = true,
    super.key,
  });

  final double size;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: Size(size, size),
          painter: _AdinkraWisdomPainter(),
        ),
        if (showLabel) ...[
          const SizedBox(width: 10),
          Text(
            'Akuko',
            style: context.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textWarm,
              letterSpacing: 1.2,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ],
    );
  }
}

/// Interlocking Adinkra-inspired symbol — wisdom / storytelling (Sankofa + Gye Nyame arcs).
class _AdinkraWisdomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.42;

    final gold = Paint()
      ..color = AppColors.warmGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final sienna = Paint()
      ..color = AppColors.burntSienna
      ..style = PaintingStyle.fill;

    final green = Paint()
      ..color = AppColors.forestGreen.withOpacity(0.85)
      ..style = PaintingStyle.fill;

    // Outer interlocking arcs — Gye Nyame-inspired linked circles.
    for (var i = 0; i < 3; i++) {
      final angle = i * 2.094; // 120° apart
      final ox = cx + r * 0.38 * _cos(angle);
      final oy = cy + r * 0.38 * _sin(angle);
      canvas.drawCircle(Offset(ox, oy), r * 0.28, gold);
    }

    // Central diamond — geometric story frame.
    final frame = Path()
      ..moveTo(cx, cy - r * 0.55)
      ..lineTo(cx + r * 0.55, cy)
      ..lineTo(cx, cy + r * 0.55)
      ..lineTo(cx - r * 0.55, cy)
      ..close();
    canvas.drawPath(frame, gold..strokeWidth = 1.5);

    // Twin owl eyes — wisdom / Akuko storytelling motif.
    canvas.drawCircle(Offset(cx - r * 0.22, cy - r * 0.05), r * 0.14, sienna);
    canvas.drawCircle(Offset(cx + r * 0.22, cy - r * 0.05), r * 0.14, sienna);
    canvas.drawCircle(
      Offset(cx - r * 0.22, cy - r * 0.05),
      r * 0.05,
      Paint()..color = AppColors.textWarm,
    );
    canvas.drawCircle(
      Offset(cx + r * 0.22, cy - r * 0.05),
      r * 0.05,
      Paint()..color = AppColors.textWarm,
    );

    // Open book arc at base — oral tradition.
    final book = Path()
      ..moveTo(cx - r * 0.42, cy + r * 0.28)
      ..quadraticBezierTo(cx, cy + r * 0.55, cx + r * 0.42, cy + r * 0.28)
      ..lineTo(cx, cy + r * 0.12)
      ..close();
    canvas.drawPath(book, green);

    // Radiating story rays.
    for (var i = -2; i <= 2; i++) {
      final angle = -1.5708 + i * 0.22;
      canvas.drawLine(
        Offset(cx, cy - r * 0.48),
        Offset(
          cx + r * 0.3 * _cos(angle),
          cy - r * 0.48 + r * 0.3 * _sin(angle),
        ),
        gold..strokeWidth = 1.2,
      );
    }
  }

  double _cos(double a) => 1 - (a * a) / 2 + (a * a * a * a) / 24;
  double _sin(double a) => a - (a * a * a) / 6;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
