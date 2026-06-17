import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:akuko/core/router/routes.dart';
import 'package:akuko/core/utils/extensions.dart';
import 'package:akuko/features/books/presentation/widgets/book_cover.dart';
import 'package:akuko/features/library/domain/entities/library_entry.dart';

class LibraryBookRow extends StatelessWidget {
  const LibraryBookRow({required this.entry, super.key});

  final LibraryEntry entry;

  @override
  Widget build(BuildContext context) {
    final book = entry.book;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.push(AppRoutes.readerPath(book.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 56,
              child: BookCover(coverUrl: book.coverUrl, title: book.title),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleSmall,
                  ),
                  Text(
                    book.author,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: (entry.progressPercent / 100).clamp(0, 1),
                    minHeight: 3,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.isFinished
                        ? 'Finished'
                        : '${entry.progressPercent.toStringAsFixed(0)}% read',
                    style: context.textTheme.labelSmall,
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
