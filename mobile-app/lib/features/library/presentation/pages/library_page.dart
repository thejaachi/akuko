import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:akuko/core/error/failures.dart' show describeError;
import 'package:akuko/core/router/routes.dart';
import 'package:akuko/core/theme/app_colors.dart';
import 'package:akuko/core/utils/extensions.dart';
import 'package:akuko/core/widgets/empty_view.dart';
import 'package:akuko/core/widgets/error_view.dart';
import 'package:akuko/core/widgets/loading_view.dart';
import 'package:akuko/features/authors/presentation/controllers/author_providers.dart';
import 'package:akuko/features/authors/presentation/widgets/author_spotlight_card.dart';
import 'package:akuko/features/library/domain/entities/book_request.dart';
import 'package:akuko/features/library/domain/entities/library_entry.dart';
import 'package:akuko/features/library/presentation/controllers/book_request_providers.dart';
import 'package:akuko/features/library/presentation/controllers/library_providers.dart';
import 'package:akuko/features/library/presentation/widgets/achievements_card.dart';
import 'package:akuko/features/library/presentation/widgets/collection_tab_bar.dart';
import 'package:akuko/features/library/presentation/widgets/library_book_row.dart';
import 'package:akuko/features/streaks/presentation/controllers/streak_providers.dart';
import 'package:akuko/features/streaks/presentation/widgets/streak_pill.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  CollectionTab _tab = CollectionTab.myLibrary;

  @override
  Widget build(BuildContext context) {
    ref.watch(journeyMilestoneWatcherProvider);
    final entries = ref.watch(continueReadingProvider);
    final journey = ref.watch(journeyRewardProvider);
    final myAuthors = ref.watch(myAuthorsProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref
              ..invalidate(continueReadingProvider)
              ..invalidate(readingStreakProvider)
              ..invalidate(myAuthorsProvider);
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      Text(
                        'My Collection',
                        style: context.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      journey.maybeWhen(
                        data: (r) => StreakPill(days: r.readingStreakDays),
                        orElse: () => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: journey.when(
                  data: (reward) => AchievementsCard(reward: reward),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
              SliverToBoxAdapter(
                child: CollectionTabBar(
                  selected: _tab,
                  onSelected: (t) => setState(() => _tab = t),
                ),
              ),
              if (_tab == CollectionTab.myAuthors)
                myAuthors.when(
                  loading: () => const SliverFillRemaining(
                    child: LoadingView(),
                  ),
                  error: (e, _) => SliverFillRemaining(
                    child: ErrorView(
                      message: describeError(e, 'Could not load authors'),
                      onRetry: () => ref.invalidate(myAuthorsProvider),
                    ),
                  ),
                  data: (authors) {
                    if (authors.isEmpty) {
                      return const SliverFillRemaining(
                        hasScrollBody: false,
                        child: EmptyView(
                          icon: Icons.person_outline,
                          title: 'No authors yet',
                          message:
                              'Authors from books you read will appear here.',
                        ),
                      );
                    }
                    return SliverToBoxAdapter(
                      child: SizedBox(
                        height: 160,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.all(16),
                          itemCount: authors.length,
                          itemBuilder: (_, i) =>
                              AuthorSpotlightCard(author: authors[i]),
                        ),
                      ),
                    );
                  },
                )
              else if (_tab == CollectionTab.wishlist)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyView(
                    icon: Icons.favorite_border,
                    title: 'Wishlist is empty',
                    message: 'Save books you want to read later.',
                  ),
                )
              else if (_tab == CollectionTab.requests)
                _RequestsTab()
              else
                entries.when(
                  loading: () => const SliverFillRemaining(
                    child: LoadingView(),
                  ),
                  error: (e, _) => SliverFillRemaining(
                    child: ErrorView(
                      message: describeError(e, 'Could not load your library'),
                      onRetry: () => ref.invalidate(continueReadingProvider),
                    ),
                  ),
                  data: (items) => _LibrarySections(items: items),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LibrarySections extends StatelessWidget {
  const _LibrarySections({required this.items});

  final List<LibraryEntry> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyView(
          icon: Icons.auto_stories_outlined,
          title: 'Nothing here yet',
          message:
              'Books you start reading will appear here so you can pick up '
              'where you left off.',
        ),
      );
    }

    final recent = items.take(5).toList();
    final purchased = items.where((e) => e.book.price > 0).toList();
    final inProgress = items.where((e) => !e.isFinished).toList();

    return SliverList(
      delegate: SliverChildListDelegate([
        _SectionHeader(title: 'Recently Read'),
        for (final e in recent) LibraryBookRow(entry: e),
        if (purchased.isNotEmpty) ...[
          _SectionHeader(title: 'Purchased'),
          for (final e in purchased) LibraryBookRow(entry: e),
        ],
        if (inProgress.isNotEmpty) ...[
          _SectionHeader(title: 'In Progress'),
          for (final e in inProgress) LibraryBookRow(entry: e),
        ],
        const SizedBox(height: 24),
      ]),
    );
  }
}

class _RequestsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(bookRequestsProvider);

    return requests.when(
      loading: () => const SliverFillRemaining(child: LoadingView()),
      error: (e, _) => SliverFillRemaining(
        child: ErrorView(
          message: describeError(e, 'Could not load requests'),
          onRetry: () => ref.invalidate(bookRequestsProvider),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const EmptyView(
                  icon: Icons.request_page_outlined,
                  title: 'No requests yet',
                  message: 'Request a book you would like to see on Akuko.',
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => context.push(AppRoutes.requestBook),
                  icon: const Icon(Icons.add),
                  label: const Text('Request a Book'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.burntSienna,
                  ),
                ),
              ],
            ),
          );
        }
        return SliverList(
          delegate: SliverChildListDelegate([
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: FilledButton.icon(
                onPressed: () => context.push(AppRoutes.requestBook),
                icon: const Icon(Icons.add),
                label: const Text('Request a Book'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.burntSienna,
                ),
              ),
            ),
            for (final r in items) _RequestTile(request: r),
            const SizedBox(height: 24),
          ]),
        );
      },
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({required this.request});

  final BookRequest request;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.menu_book_outlined, color: AppColors.burntSienna),
      title: Text(request.title),
      subtitle: Text(
        [
          if (request.author != null) request.author,
          if (request.genre != null) request.genre,
          request.status,
        ].whereType<String>().join(' · '),
      ),
      trailing: request.createdAt != null
          ? Text(
              DateFormat.MMMd().format(request.createdAt!),
              style: context.textTheme.labelSmall?.copyWith(
                color: AppColors.textMuted,
              ),
            )
          : null,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: context.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.textWarm,
        ),
      ),
    );
  }
}
