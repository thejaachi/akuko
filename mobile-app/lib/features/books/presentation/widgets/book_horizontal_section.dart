import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:akuko/core/error/failures.dart' show describeError;
import 'package:akuko/core/theme/app_colors.dart';
import 'package:akuko/core/utils/extensions.dart';
import 'package:akuko/core/widgets/error_view.dart';
import 'package:akuko/features/books/data/curated_home_content.dart';
import 'package:akuko/features/books/presentation/widgets/curated_book_card.dart';
import 'package:akuko/features/reading_circles/presentation/widgets/reading_circle_sheet.dart';
import 'package:akuko/shared/domain/entities/book.dart';

/// Carousel row item — book plus optional curated cover spec and gift flag.
class BookCarouselItem {
  const BookCarouselItem({
    required this.book,
    this.spec,
    this.showGift = false,
  });

  final Book book;
  final CuratedBookSpec? spec;
  final bool showGift;
}

/// Titled horizontal book carousel with optional header action.
class BookHorizontalSection extends StatelessWidget {
  const BookHorizontalSection({
    required this.title,
    required this.books,
    this.onRetry,
    this.height = 290,
    this.showGiftOnCards = false,
    this.headerAction,
    super.key,
  });

  final String title;
  final AsyncValue<List<BookCarouselItem>> books;
  final VoidCallback? onRetry;
  final double height;
  final bool showGiftOnCards;
  final Widget? headerAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (headerAction != null) headerAction!,
            ],
          ),
        ),
        SizedBox(
          height: height,
          child: books.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ErrorView(
              message: describeError(error, 'Could not load $title'),
              onRetry: onRetry,
            ),
            data: (items) {
              if (items.isEmpty) {
                return Center(
                  child: Text(
                    'Nothing here yet',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                );
              }
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final item = items[i];
                  return CuratedBookCard(
                    book: item.book,
                    showGiftButton: showGiftOnCards || item.showGift,
                    curatedSpec: item.spec ?? curatedSpecForBook(item.book),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Reading Circle CTA banner for New Releases section.
class ReadingCircleBanner extends StatelessWidget {
  const ReadingCircleBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: AppColors.forestGreen.withOpacity(0.2),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => ReadingCircleSheet.show(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.forestGreen.withOpacity(0.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.forestGreen.withOpacity(0.35),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.groups_outlined,
                    color: AppColors.textWarm,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Join a Reading Circle',
                        style: context.textTheme.titleSmall?.copyWith(
                          color: AppColors.textWarm,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Read together, share notes, stay accountable',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.forestGreen,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
