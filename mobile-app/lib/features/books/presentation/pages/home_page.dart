import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:akuko/core/router/routes.dart';
import 'package:akuko/core/theme/app_colors.dart';
import 'package:akuko/core/utils/extensions.dart';
import 'package:akuko/core/utils/responsive.dart';
import 'package:akuko/core/widgets/akuko_logo_mark.dart';
import 'package:akuko/core/widgets/section_spacer.dart';
import 'package:akuko/features/books/data/curated_home_content.dart';
import 'package:akuko/features/books/presentation/controllers/book_providers.dart';
import 'package:akuko/features/books/presentation/widgets/book_format_filter_tabs.dart';
import 'package:akuko/features/books/presentation/widgets/book_horizontal_section.dart';
import 'package:akuko/features/books/presentation/widgets/book_of_month_hero.dart';
import 'package:akuko/features/books/presentation/widgets/content_type_tabs.dart';
import 'package:akuko/features/books/presentation/widgets/continue_reading_card.dart';
import 'package:akuko/features/books/presentation/widgets/genre_grid_card.dart';
import 'package:akuko/features/books/presentation/widgets/home_search_bar.dart';
import 'package:akuko/features/books/presentation/widgets/language_filter_chips.dart';
import 'package:akuko/features/library/presentation/controllers/library_providers.dart';
import 'package:akuko/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:akuko/features/profile/presentation/controllers/greeting_provider.dart';
import 'package:akuko/features/reading_circles/presentation/widgets/reading_circles_home_card.dart';
import 'package:akuko/features/streaks/presentation/controllers/streak_providers.dart'
    show journeyMilestoneWatcherProvider, journeyRewardProvider, readingStreakProvider;
import 'package:akuko/features/streaks/presentation/widgets/journey_stats_card.dart';
import 'package:akuko/shared/domain/entities/category.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  ContentType _contentType = ContentType.fiction;

  @override
  Widget build(BuildContext context) {
    ref.watch(journeyMilestoneWatcherProvider);
    final greeting = ref.watch(greetingProvider);
    final continueReading = ref.watch(continueReadingProvider);
    final journey = ref.watch(journeyRewardProvider);
    final christianLiterature = ref.watch(christianLiteratureProvider);
    final formatFilter = ref.watch(bookFormatFilterProvider);
    final bestselling = ref.watch(homeBestsellingProvider);
    final newReleases = ref.watch(homeNewReleasesProvider);
    final genres = ref.watch(homeGenresProvider);

    Future<void> refresh() async {
      ref
        ..invalidate(christianBooksRawProvider)
        ..invalidate(trendingBooksRawProvider)
        ..invalidate(newReleasesRawProvider)
        ..invalidate(categoriesProvider)
        ..invalidate(continueReadingProvider)
        ..invalidate(readingStreakProvider);
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: refresh,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                  child: Row(
                    children: [
                      const AkukoLogoMark(showLabel: false),
                      const SizedBox(width: 12),
                      Expanded(
                        child: greeting.when(
                          loading: () => Text(
                            'Hello, Reader',
                            style: context.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textWarm,
                            ),
                          ),
                          error: (_, __) => Text(
                            'Hello, Reader',
                            style: context.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textWarm,
                            ),
                          ),
                          data: (text) => Text(
                            text,
                            style: context.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textWarm,
                            ),
                          ),
                        ),
                      ),
                      const NotificationBell(),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: HomeSearchBar()),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: LanguageFilterChips(),
                ),
              ),
              SliverToBoxAdapter(
                child: ContentTypeTabs(
                  selected: _contentType,
                  onSelected: (type) {
                    setState(() => _contentType = type);
                    context.push(AppRoutes.catalogCategoryPath(type.name));
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: BookFormatFilterTabs(
                  selected: formatFilter,
                  onSelected: (format) =>
                      ref.read(bookFormatFilterProvider.notifier).state = format,
                ),
              ),

              const SliverToBoxAdapter(child: SectionSpacer()),

              SliverToBoxAdapter(
                child: continueReading.maybeWhen(
                  data: (entries) {
                    if (entries.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: ContinueReadingCard(entry: entries.first),
                    );
                  },
                  orElse: () => const SizedBox.shrink(),
                ),
              ),

              const SliverToBoxAdapter(child: SectionSpacer()),

              SliverToBoxAdapter(
                child: journey.when(
                  data: (reward) => Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: JourneyStatsCard(reward: reward),
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),

              const SliverToBoxAdapter(child: SectionSpacer()),

              const SliverToBoxAdapter(child: ReadingCirclesHomeCard()),

              const SliverToBoxAdapter(child: SectionSpacer()),

              SliverToBoxAdapter(
                child: BookOfMonthHero(book: CuratedHomeContent.bookOfTheMonth),
              ),

              const SliverToBoxAdapter(child: SectionSpacer()),

              SliverToBoxAdapter(
                child: BookHorizontalSection(
                  title: CuratedHomeContent.christianLiteratureSectionTitle,
                  books: christianLiterature,
                  showGiftOnCards: true,
                  onRetry: () => ref.invalidate(christianBooksRawProvider),
                ),
              ),

              const SliverToBoxAdapter(child: SectionSpacer()),

              SliverToBoxAdapter(
                child: BookHorizontalSection(
                  title: CuratedHomeContent.bestsellingSectionTitle,
                  books: bestselling,
                  onRetry: () => ref.invalidate(trendingBooksRawProvider),
                ),
              ),

              const SliverToBoxAdapter(child: SectionSpacer()),

              SliverToBoxAdapter(
                child: BookHorizontalSection(
                  title: CuratedHomeContent.newReleasesSectionTitle,
                  books: newReleases,
                  onRetry: () => ref.invalidate(newReleasesRawProvider),
                ),
              ),

              const SliverToBoxAdapter(child: SectionSpacer()),

              SliverToBoxAdapter(
                child: genres.maybeWhen(
                  data: (cats) => _GenreGrid(categories: cats),
                  orElse: () => _GenreGrid(
                    categories: CuratedHomeContent.curatedGenres
                        .map((g) => g.toCategory())
                        .toList(),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SectionSpacer()),
            ],
          ),
        ),
      ),
    );
  }
}

class _GenreGrid extends StatelessWidget {
  const _GenreGrid({required this.categories});

  final List<Category> categories;

  GenreMotif? _motifFor(Category cat) {
    for (final g in CuratedHomeContent.curatedGenres) {
      if (g.slug == cat.slug || g.name == cat.name) return g.motif;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            CuratedHomeContent.genreSectionTitle,
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: responsiveGridCount(context).clamp(2, 4),
              childAspectRatio: 1.5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: categories.length.clamp(0, 9),
            itemBuilder: (context, i) {
              final cat = categories[i];
              return GenreGridCard(
                category: cat,
                index: i,
                motif: _motifFor(cat),
                onTap: () =>
                    context.push(AppRoutes.categoryDetailPath(cat.slug)),
              );
            },
          ),
        ),
      ],
    );
  }
}
