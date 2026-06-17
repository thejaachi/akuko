import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:akuko/core/router/routes.dart';
import 'package:akuko/core/theme/app_colors.dart';
import 'package:akuko/core/utils/share_book.dart';
import 'package:akuko/features/books/data/curated_home_content.dart';
import 'package:akuko/features/books/presentation/widgets/book_cover.dart';
import 'package:akuko/features/books/presentation/widgets/curated_book_cover.dart';
import 'package:akuko/features/gifting/presentation/widgets/gift_sheet.dart';
import 'package:akuko/features/reading_circles/presentation/controllers/reading_circle_providers.dart';
import 'package:akuko/features/reading_circles/presentation/widgets/reading_circle_sheet.dart';
import 'package:akuko/shared/domain/entities/book.dart';

/// Book tile for home carousels — supports curated covers and gift CTA.
class CuratedBookCard extends ConsumerWidget {
  const CuratedBookCard({
    required this.book,
    this.width = 130,
    this.showGiftButton = false,
    this.curatedSpec,
    super.key,
  });

  final Book book;
  final double width;
  final bool showGiftButton;
  final CuratedBookSpec? curatedSpec;

  bool get _isCurated => book.id.startsWith('curated-');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final circle = ref.watch(readingCircleForBookProvider(book.id));
    final giftEnabled = showGiftButton || (curatedSpec?.showGiftButton ?? false);

    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.push(AppRoutes.bookDetailPath(book.id)),
            child: Stack(
              children: [
                if (_isCurated && curatedSpec != null)
                  CuratedBookCover.fromSpec(curatedSpec!, compact: true)
                else if (_isCurated)
                  CuratedBookCover(
                    title: book.title,
                    author: book.author,
                    compact: true,
                  )
                else
                  BookCover(coverUrl: book.coverUrl, title: book.title),
                if (book.isPremium)
                  const Positioned(
                    top: 6,
                    right: 6,
                    child: _PremiumBadge(),
                  ),
                Positioned(
                  top: 4,
                  left: 4,
                  child: Material(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => shareBook(book),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.share_outlined,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
          if (giftEnabled) ...[
            const SizedBox(height: 6),
            _GiftButton(bookTitle: book.title),
          ],
          if (circle != null) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => ReadingCircleSheet.show(context, bookId: book.id),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.forestGreen.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.forestGreen.withOpacity(0.5),
                  ),
                ),
                child: Text(
                  circle.name.length > 18 ? 'Join Circle' : circle.name,
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
    );
  }
}

class _GiftButton extends StatelessWidget {
  const _GiftButton({required this.bookTitle});

  final String bookTitle;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => GiftSheet.show(
        context,
        type: GiftType.book,
        bookTitle: bookTitle,
      ),
      icon: const Icon(Icons.card_giftcard, size: 14),
      label: const Text('Gift this Book'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.burntSienna,
        side: const BorderSide(color: AppColors.burntSienna),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        minimumSize: const Size(0, 28),
        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
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

/// Lookup curated spec by book id for cover styling.
CuratedBookSpec? curatedSpecForBook(Book book) =>
    CuratedHomeContent.lookupById(book.id);
