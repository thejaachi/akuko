import 'package:flutter/material.dart';

import 'package:akuko/core/theme/app_colors.dart';
import 'package:akuko/features/books/data/curated_home_content.dart';

/// Placeholder cover — gradient, geometric border, title + author overlay.
class CuratedBookCover extends StatelessWidget {
  const CuratedBookCover({
    required this.title,
    required this.author,
    this.coverAssetPath,
    this.gradientStart,
    this.gradientEnd,
    this.accentIndex = 0,
    this.aspectRatio = 2 / 3,
    this.compact = false,
    super.key,
  });

  factory CuratedBookCover.fromSpec(
    CuratedBookSpec spec, {
    double aspectRatio = 2 / 3,
    bool compact = false,
  }) {
    return CuratedBookCover(
      title: spec.title,
      author: spec.author,
      coverAssetPath: spec.coverAssetPath,
      gradientStart: Color(spec.gradientStart),
      gradientEnd: Color(spec.gradientEnd),
      accentIndex: spec.accentIndex,
      aspectRatio: aspectRatio,
      compact: compact,
    );
  }

  final String title;
  final String author;
  final String? coverAssetPath;
  final Color? gradientStart;
  final Color? gradientEnd;
  final int accentIndex;
  final double aspectRatio;
  final bool compact;

  static const _accents = [
    AppColors.burntSienna,
    AppColors.forestGreen,
    AppColors.cobaltBlue,
    AppColors.warmGold,
  ];

  @override
  Widget build(BuildContext context) {
    final accent = _accents[accentIndex % _accents.length];
    final start = gradientStart ?? AppColors.cardGradientStart;
    final end = gradientEnd ?? AppColors.cardGradientEnd;

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (coverAssetPath != null)
              Image.asset(
                coverAssetPath!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _gradientBackground(start, end),
              )
            else
              _gradientBackground(start, end),
            if (coverAssetPath == null)
              CustomPaint(
                painter: _GeometricFramePainter(accent: accent),
              ),
            Padding(
              padding: EdgeInsets.all(compact ? 8 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!compact)
                    Container(
                      width: 28,
                      height: 3,
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  const Spacer(),
                  Text(
                    title,
                    maxLines: compact ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textWarm,
                      fontWeight: FontWeight.bold,
                      fontSize: compact ? 11 : 13,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: compact ? 9 : 11,
                    ),
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

Widget _gradientBackground(Color start, Color end) {
  return DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [start, end],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  );
}

class _GeometricFramePainter extends CustomPainter {
  _GeometricFramePainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accent.withOpacity(0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const inset = 6.0;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      paint,
    );

    // Corner diamonds — adinkra-inspired frame accents.
    final cornerPaint = Paint()
      ..color = accent.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    for (final corner in [
      Offset(inset + 4, inset + 4),
      Offset(size.width - inset - 4, inset + 4),
      Offset(inset + 4, size.height - inset - 4),
      Offset(size.width - inset - 4, size.height - inset - 4),
    ]) {
      final path = Path()
        ..moveTo(corner.dx, corner.dy - 4)
        ..lineTo(corner.dx + 4, corner.dy)
        ..lineTo(corner.dx, corner.dy + 4)
        ..lineTo(corner.dx - 4, corner.dy)
        ..close();
      canvas.drawPath(path, cornerPaint);
    }

    // Horizontal motif lines across upper third.
    final linePaint = Paint()
      ..color = accent.withOpacity(0.15)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = size.height * 0.18 + i * 8;
      canvas.drawLine(
        Offset(inset + 12, y),
        Offset(size.width - inset - 12, y),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_GeometricFramePainter old) => old.accent != accent;
}
