import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:akuko/core/router/routes.dart';
import 'package:akuko/core/theme/app_colors.dart';
import 'package:akuko/core/utils/extensions.dart';
import 'package:akuko/features/books/presentation/widgets/book_cover.dart';
import 'package:akuko/features/library/domain/entities/library_entry.dart';

class ContinueReadingCard extends StatelessWidget {
  const ContinueReadingCard({required this.entry, super.key});

  final LibraryEntry entry;

  @override
  Widget build(BuildContext context) {
    final book = entry.book;
    final progress = (entry.progressPercent / 100).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () => context.push(AppRoutes.readerPath(book.id)),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.warmSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              child: BookCover(coverUrl: book.coverUrl, title: book.title),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Continue Reading',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: AppColors.burntSienna,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleSmall?.copyWith(
                      color: AppColors.textWarm,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: AppColors.cardBorder,
                      color: AppColors.warmGold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${entry.progressPercent.toStringAsFixed(0)}% complete',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
