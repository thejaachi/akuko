import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:akuko/core/error/failures.dart' show describeError;
import 'package:akuko/core/guards/subscription_guard.dart';
import 'package:akuko/core/router/routes.dart';
import 'package:akuko/core/utils/extensions.dart';
import 'package:akuko/core/utils/share_book.dart';
import 'package:akuko/core/widgets/app_button.dart';
import 'package:akuko/core/widgets/error_view.dart';
import 'package:akuko/core/widgets/loading_view.dart';
import 'package:akuko/features/auth/presentation/controllers/auth_controller.dart';
import 'package:akuko/features/books/presentation/controllers/book_providers.dart';
import 'package:akuko/features/books/presentation/widgets/book_cover.dart';
import 'package:akuko/core/theme/app_colors.dart';
import 'package:akuko/features/gifting/presentation/widgets/gift_sheet.dart';
import 'package:akuko/features/profile/presentation/controllers/profile_providers.dart';
import 'package:akuko/features/wallet/presentation/controllers/wallet_providers.dart';
import 'package:akuko/shared/domain/entities/book.dart';

class BookDetailPage extends ConsumerWidget {
  const BookDetailPage({required this.bookId, super.key});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final book = ref.watch(bookDetailProvider(bookId));

    return Scaffold(
      appBar: AppBar(
        actions: [
          book.maybeWhen(
            data: (b) => IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () => shareBook(b),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: book.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: describeError(e, 'Could not load this book'),
          onRetry: () => ref.invalidate(bookDetailProvider(bookId)),
        ),
        data: (b) => _Detail(book: b),
      ),
    );
  }
}

class _Detail extends ConsumerWidget {
  const _Detail({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final showPendingBadge =
        (profile?.isAdmin ?? false) && book.status?.isPendingReview == true;

    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          Expanded(
            child: NestedScrollView(
              headerSliverBuilder: (context, _) => [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: _Header(
                      book: book,
                      showPendingBadge: showPendingBadge,
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabBarDelegate(
                    TabBar(
                      isScrollable: true,
                      labelColor: AppColors.burntSienna,
                      unselectedLabelColor: AppColors.textMuted,
                      indicatorColor: AppColors.burntSienna,
                      tabs: const [
                        Tab(text: 'Synopsis'),
                        Tab(text: 'Author Bio'),
                        Tab(text: 'Reviews'),
                        Tab(text: 'Book Details'),
                      ],
                    ),
                  ),
                ),
              ],
              body: TabBarView(
                children: [
                  _SynopsisTab(book: book),
                  _AuthorBioTab(book: book),
                  _ReviewsTab(book: book),
                  _BookDetailsTab(book: book),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: _ReadButton(book: book)),
                  ],
                ),
                if (book.price > 0 && !book.isPremium) ...[
                  const SizedBox(height: 12),
                  _BuyWithCowriesButton(book: book),
                ],
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => GiftSheet.show(
                    context,
                    type: GiftType.book,
                    bookTitle: book.title,
                  ),
                  icon: const Icon(Icons.card_giftcard_outlined),
                  label: const Text('Gift this Book'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.burntSienna,
                    side: const BorderSide(color: AppColors.cardBorder),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.book, required this.showPendingBadge});

  final Book book;
  final bool showPendingBadge;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              child: BookCover(coverUrl: book.coverUrl, title: book.title),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(book.title, style: context.textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text(
                    book.author,
                    style: context.textTheme.titleMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Pill(
                        icon: Icons.star,
                        label: book.ratingAvg.toStringAsFixed(1),
                      ),
                      _Pill(
                        icon: book.fileType == BookFileType.pdf
                            ? Icons.picture_as_pdf
                            : Icons.menu_book,
                        label: book.deliveryFormat.label,
                      ),
                      if (book.pageCount != null)
                        _Pill(
                          icon: Icons.description_outlined,
                          label: '${book.pageCount} pp',
                        ),
                      if (book.isPremium)
                        const _Pill(
                          icon: Icons.workspace_premium,
                          label: 'Premium',
                        ),
                      if (showPendingBadge)
                        const _Pill(
                          icon: Icons.pending_actions,
                          label: 'Pending review',
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _SynopsisTab extends StatelessWidget {
  const _SynopsisTab({required this.book});
  final Book book;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Text(
        book.description?.isNotEmpty == true
            ? book.description!
            : 'No synopsis available for this title yet.',
        style: context.textTheme.bodyMedium,
      ),
    );
  }
}

class _AuthorBioTab extends StatelessWidget {
  const _AuthorBioTab({required this.book});
  final Book book;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Text(
        '${book.author} is an African writer featured on Akuko. '
        'Full author biography will appear here when available from the catalogue.',
        style: context.textTheme.bodyMedium,
      ),
    );
  }
}

class _ReviewsTab extends StatelessWidget {
  const _ReviewsTab({required this.book});
  final Book book;

  @override
  Widget build(BuildContext context) {
    if (book.ratingCount == 0) {
      return Center(
        child: Text(
          'No community reviews yet. Be the first to share your thoughts.',
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ListTile(
          leading: const Icon(Icons.star, color: AppColors.warmGold),
          title: Text('${book.ratingAvg.toStringAsFixed(1)} average'),
          subtitle: Text('${book.ratingCount} ratings'),
        ),
      ],
    );
  }
}

class _BookDetailsTab extends StatelessWidget {
  const _BookDetailsTab({required this.book});
  final Book book;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: _MetadataTable(book: book),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate(this.tabBar);
  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}

/// Premium-aware entry point to the reader. For premium books, free users are
/// routed to the paywall instead of the reader; entitlement is the guard's
/// decision (the single source of truth) and is also re-enforced server-side
/// when the reader resolves a signed URL.
class _BuyWithCowriesButton extends ConsumerStatefulWidget {
  const _BuyWithCowriesButton({required this.book});

  final Book book;

  @override
  ConsumerState<_BuyWithCowriesButton> createState() =>
      _BuyWithCowriesButtonState();
}

class _BuyWithCowriesButtonState extends ConsumerState<_BuyWithCowriesButton> {
  bool _busy = false;

  int get _cowriePrice => (widget.book.price * 10).round().clamp(100, 999999);

  Future<void> _purchase() async {
    final userId = ref.read(authRepositoryProvider).currentUser?.id;
    if (userId == null) return;

    setState(() => _busy = true);
    try {
      final result = await ref.read(walletRepositoryProvider).purchaseWithCowries(
            userId: userId,
            bookId: widget.book.id,
            amountCowries: _cowriePrice,
          );
      result.fold(
        (f) {
          if (mounted) context.showSnack(f.message);
        },
        (_) {
          ref.invalidate(cowriesBalanceProvider);
          if (mounted) {
            context.showSnack('Purchased with $_cowriePrice cowries!');
          }
        },
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _busy ? null : _purchase,
      icon: _busy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.toll_outlined),
      label: Text('Buy with Cowries ($_cowriePrice)'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.warmGold,
        side: const BorderSide(color: AppColors.warmGold),
      ),
    );
  }
}

class _ReadButton extends ConsumerWidget {
  const _ReadButton({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guard = ref.watch(subscriptionGuardProvider);
    final locked = book.isPremium && !guard.isPremium();

    return AppButton(
      label: locked ? 'Unlock with Premium' : 'Read',
      icon: locked
          ? Icons.workspace_premium
          : Icons.chrome_reader_mode_outlined,
      onPressed: () {
        if (locked) {
          context.push(AppRoutes.subscription);
        } else {
          context.push(AppRoutes.readerPath(book.id));
        }
      },
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      visualDensity: VisualDensity.compact,
      avatar: Icon(icon, size: 16),
      label: Text(label),
    );
  }
}

class _MetadataTable extends StatelessWidget {
  const _MetadataTable({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String?)>[
      ('Format', book.deliveryFormat.label),
      ('ISBN', book.isbn),
      ('Genre', book.genreName),
      ('Language', book.language),
      ('Page Count', book.pageCount?.toString()),
      ('Publisher', book.publisher),
      (
        'Publication Date',
        book.publishedDate?.readableDate,
      ),
    ].where((r) => (r.$2 ?? '').isNotEmpty).toList();

    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Details', style: context.textTheme.titleLarge),
        const SizedBox(height: 8),
        ...rows.map(
          (r) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 110,
                  child: Text(
                    r.$1,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(r.$2!, style: context.textTheme.bodyMedium),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
