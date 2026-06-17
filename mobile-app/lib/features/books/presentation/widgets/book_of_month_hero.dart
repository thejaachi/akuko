import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:akuko/core/router/routes.dart';
import 'package:akuko/core/theme/app_colors.dart';
import 'package:akuko/core/utils/extensions.dart';
import 'package:akuko/features/books/data/curated_home_content.dart';
import 'package:akuko/features/books/presentation/widgets/curated_book_cover.dart';

/// Full-bleed Book of the Month hero with vibrant African portrait placeholder.
class BookOfMonthHero extends StatelessWidget {
  const BookOfMonthHero({required this.book, super.key});

  final CuratedBookSpec book;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.bookDetailPath(book.id)),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: AppColors.burntSienna.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Full-bleed cover art placeholder.
            CuratedBookCover.fromSpec(
              book,
              aspectRatio: 16 / 9,
              compact: false,
            ),
            // Portrait silhouette overlay — stylized African portrait motif.
            Positioned(
              right: 24,
              bottom: 0,
              top: 20,
              width: 100,
              child: CustomPaint(
                painter: _PortraitSilhouettePainter(
                  accent: Color(book.gradientStart),
                ),
              ),
            ),
            // Gradient scrim for legibility.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.75),
                    Colors.black.withOpacity(0.2),
                    Colors.transparent,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            // Text overlay.
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warmGold.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Book of the Month',
                      style: context.textTheme.labelSmall?.copyWith(
                        color: AppColors.earthBackground,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: MediaQuery.sizeOf(context).width * 0.52,
                      child: Text(
                        book.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.headlineSmall?.copyWith(
                          color: AppColors.textWarm,
                          fontWeight: FontWeight.bold,
                          height: 1.15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleSmall?.copyWith(
                      color: AppColors.warmGold,
                      fontWeight: FontWeight.w600,
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

class _PortraitSilhouettePainter extends CustomPainter {
  _PortraitSilhouettePainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..shader = LinearGradient(
        colors: [
          accent.withOpacity(0.6),
          AppColors.burntSienna.withOpacity(0.4),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Head.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.22),
        width: size.width * 0.55,
        height: size.height * 0.28,
      ),
      fill,
    );

    // Neck + shoulders.
    final body = Path()
      ..moveTo(size.width * 0.2, size.height * 0.38)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.32,
        size.width * 0.8,
        size.height * 0.38,
      )
      ..lineTo(size.width * 0.95, size.height)
      ..lineTo(size.width * 0.05, size.height)
      ..close();
    canvas.drawPath(body, fill);

    // Geometric headwrap motif.
    final wrapPaint = Paint()
      ..color = AppColors.warmGold.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.18),
        width: size.width * 0.7,
        height: size.height * 0.2,
      ),
      3.14,
      3.14,
      false,
      wrapPaint,
    );
  }

  @override
  bool shouldRepaint(_PortraitSilhouettePainter old) => old.accent != accent;
}
