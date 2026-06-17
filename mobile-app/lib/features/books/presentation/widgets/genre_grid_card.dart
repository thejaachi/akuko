import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:akuko/core/theme/app_colors.dart';
import 'package:akuko/core/utils/extensions.dart';
import 'package:akuko/features/books/data/curated_home_content.dart';
import 'package:akuko/shared/domain/entities/category.dart';

/// Organic genre card with CustomPaint motif icons for Browse by Genre grid.
class GenreGridCard extends StatelessWidget {
  const GenreGridCard({
    required this.category,
    required this.index,
    required this.onTap,
    this.motif,
    super.key,
  });

  final Category category;
  final int index;
  final VoidCallback onTap;
  final GenreMotif? motif;

  static final _accentColors = [
    AppColors.burntSienna,
    AppColors.forestGreen,
    AppColors.cobaltBlue,
    AppColors.warmGold,
  ];

  GenreMotif get _motif {
    if (motif != null) return motif!;
    for (final g in CuratedHomeContent.curatedGenres) {
      if (g.slug == category.slug || g.name == category.name) return g.motif;
    }
    return GenreMotif.values[index % GenreMotif.values.length];
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColors[index % _accentColors.length];
    final radii = BorderRadius.only(
      topLeft: Radius.circular(16 + (index % 3) * 2.0),
      topRight: Radius.circular(12 + (index % 2) * 4.0),
      bottomLeft: Radius.circular(14 + (index % 2) * 3.0),
      bottomRight: Radius.circular(18 + (index % 3) * 2.0),
    );

    return InkWell(
      borderRadius: radii,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radii,
          color: AppColors.surfaceElevated,
          border: Border.all(color: AppColors.cardBorder.withOpacity(0.6)),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -8,
              bottom: -8,
              child: Opacity(
                opacity: 0.15,
                child: CustomPaint(
                  size: const Size(64, 64),
                  painter: GenreMotifPainter(motif: _motif, color: accent),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withOpacity(0.25),
                      border: Border.all(color: accent.withOpacity(0.5)),
                    ),
                    child: CustomPaint(
                      painter: GenreMotifPainter(motif: _motif, color: accent),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    category.name,
                    style: context.textTheme.titleSmall?.copyWith(
                      color: AppColors.textWarm,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Distinct illustrative icons per genre motif.
class GenreMotifPainter extends CustomPainter {
  GenreMotifPainter({required this.motif, required this.color});

  final GenreMotif motif;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final fill = Paint()
      ..color = color.withOpacity(0.25)
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final s = size.width * 0.28;

    switch (motif) {
      case GenreMotif.pyramid:
        final path = Path()
          ..moveTo(cx, cy - s)
          ..lineTo(cx + s, cy + s * 0.7)
          ..lineTo(cx - s, cy + s * 0.7)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, paint);
        canvas.drawLine(
          Offset(cx - s * 0.5, cy + s * 0.05),
          Offset(cx + s * 0.5, cy + s * 0.05),
          paint,
        );
      case GenreMotif.brain:
        canvas.drawArc(
          Rect.fromCenter(center: Offset(cx, cy), width: s * 1.8, height: s * 1.4),
          math.pi * 0.15,
          math.pi * 0.7,
          false,
          paint,
        );
        canvas.drawArc(
          Rect.fromCenter(center: Offset(cx, cy), width: s * 1.8, height: s * 1.4),
          math.pi * 1.15,
          math.pi * 0.7,
          false,
          paint,
        );
        canvas.drawLine(Offset(cx, cy - s * 0.5), Offset(cx, cy + s * 0.5), paint);
      case GenreMotif.book:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, cy), width: s * 1.4, height: s * 1.6),
            const Radius.circular(2),
          ),
          paint,
        );
        canvas.drawLine(
          Offset(cx, cy - s * 0.7),
          Offset(cx, cy + s * 0.7),
          paint,
        );
      case GenreMotif.heart:
        final heart = Path()
          ..moveTo(cx, cy + s * 0.35)
          ..cubicTo(
            cx - s * 1.1,
            cy - s * 0.2,
            cx - s * 0.4,
            cy - s * 0.9,
            cx,
            cy - s * 0.35,
          )
          ..cubicTo(
            cx + s * 0.4,
            cy - s * 0.9,
            cx + s * 1.1,
            cy - s * 0.2,
            cx,
            cy + s * 0.35,
          );
        canvas.drawPath(heart, fill);
        canvas.drawPath(heart, paint);
      case GenreMotif.orbit:
        canvas.drawCircle(Offset(cx, cy), s * 0.2, fill);
        canvas.drawCircle(Offset(cx, cy), s * 0.2, paint);
        canvas.drawCircle(Offset(cx, cy), s * 0.75, paint);
        canvas.drawCircle(Offset(cx + s * 0.55, cy - s * 0.3), s * 0.12, fill);
      case GenreMotif.lightning:
        final bolt = Path()
          ..moveTo(cx + s * 0.15, cy - s)
          ..lineTo(cx - s * 0.25, cy + s * 0.05)
          ..lineTo(cx + s * 0.05, cy + s * 0.05)
          ..lineTo(cx - s * 0.15, cy + s)
          ..lineTo(cx + s * 0.35, cy - s * 0.05)
          ..lineTo(cx + s * 0.05, cy - s * 0.05)
          ..close();
        canvas.drawPath(bolt, fill);
        canvas.drawPath(bolt, paint);
      case GenreMotif.quill:
        canvas.drawLine(
          Offset(cx - s * 0.5, cy + s * 0.6),
          Offset(cx + s * 0.4, cy - s * 0.7),
          paint..strokeWidth = 2,
        );
        canvas.drawLine(
          Offset(cx - s * 0.3, cy + s * 0.4),
          Offset(cx - s * 0.7, cy + s * 0.8),
          paint..strokeWidth = 1.2,
        );
      case GenreMotif.portrait:
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(cx, cy - s * 0.25),
            width: s * 0.9,
            height: s,
          ),
          paint,
        );
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(cx, cy + s * 0.55),
            width: s * 1.4,
            height: s * 0.9,
          ),
          math.pi,
          math.pi,
          false,
          paint,
        );
      case GenreMotif.cross:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(cx, cy + s * 0.15),
              width: s * 0.5,
              height: s * 1.1,
            ),
            const Radius.circular(1),
          ),
          paint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(cx, cy - s * 0.1),
              width: s * 1.1,
              height: s * 0.5,
            ),
            const Radius.circular(1),
          ),
          paint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(cx, cy + s * 0.55),
              width: s * 0.7,
              height: s * 0.35,
            ),
            const Radius.circular(1),
          ),
          fill,
        );
    }
  }

  @override
  bool shouldRepaint(GenreMotifPainter old) =>
      old.motif != motif || old.color != color;
}
