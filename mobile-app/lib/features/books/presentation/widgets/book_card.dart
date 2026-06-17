import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:akuko/core/router/routes.dart';
import 'package:akuko/core/theme/app_colors.dart';
import 'package:akuko/features/books/presentation/widgets/book_cover.dart';
import 'package:akuko/features/reading_circles/presentation/controllers/reading_circle_providers.dart';
import 'package:akuko/features/reading_circles/presentation/widgets/reading_circle_sheet.dart';
import 'package:akuko/shared/domain/entities/book.dart';

/// Compact book tile used in horizontal carousels and grids.
class BookCard extends ConsumerWidget {
  const BookCard({required this.book, this.width = 130, super.key});

  final Book book;
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final circle = ref.watch(readingCircleForBookProvider(book.id));

    return SizedBox(
      width: width,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(AppRoutes.bookDetailPath(book.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                BookCover(coverUrl: book.coverUrl, title: book.title),
                if (book.isPremium)
                  const Positioned(
                    top: 6,
                    right: 6,
                    child: _PremiumBadge(),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall,
            ),
            Text(
              book.author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (circle != null) ...[
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => ReadingCircleSheet.show(context, bookId: book.id),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.forestGreen.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.forestGreen.withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    circle.name.length > 18
                        ? 'Join Circle'
                        : circle.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.forestGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PremiumBadge extends StatelessWidget {
  const _PremiumBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium, size: 12, color: AppColors.warmGold),
          SizedBox(width: 2),
          Text(
            'Premium',
            style: TextStyle(color: Colors.white, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
