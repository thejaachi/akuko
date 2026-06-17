import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:akuko/core/theme/app_colors.dart';
import 'package:akuko/core/utils/responsive.dart';
import 'package:akuko/core/widgets/african_pattern_painter.dart';
import 'package:akuko/core/widgets/empty_view.dart';
import 'package:akuko/core/widgets/error_view.dart';
import 'package:akuko/core/widgets/loading_view.dart';
import 'package:akuko/features/books/presentation/controllers/book_providers.dart';
import 'package:akuko/features/books/presentation/widgets/book_card.dart';

class HomeSearchBar extends ConsumerStatefulWidget {
  const HomeSearchBar({super.key});

  @override
  ConsumerState<HomeSearchBar> createState() => _HomeSearchBarState();
}

class _HomeSearchBarState extends ConsumerState<HomeSearchBar> {
  final _controller = TextEditingController();
  bool _expanded = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    ref.read(searchQueryProvider.notifier).state = value;
    setState(() => _expanded = value.trim().isNotEmpty);
  }

  void _clear() {
    _controller.clear();
    ref.read(searchQueryProvider.notifier).state = '';
    setState(() => _expanded = false);
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchResultsProvider);
    final query = ref.watch(searchQueryProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                // Subtle tone-on-tone geometric pattern inside search field.
                Positioned.fill(
                  child: CustomPaint(
                    painter: AfricanPatternPainter(
                      tier: PatternTier.standard,
                      color: AppColors.warmGold,
                      opacity: 0.06,
                    ),
                  ),
                ),
                TextField(
                  controller: _controller,
                  onChanged: _onQueryChanged,
                  textInputAction: TextInputAction.search,
                  style: const TextStyle(color: AppColors.textWarm),
                  decoration: InputDecoration(
                    hintText: 'Search titles, authors, genres…',
                    hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.8)),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                    suffixIcon: query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppColors.textMuted),
                            onPressed: _clear,
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surfaceElevated.withOpacity(0.92),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.burntSienna),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.45,
            child: query.trim().isEmpty
                ? const SizedBox.shrink()
                : results.when(
                    loading: () => const LoadingView(),
                    error: (e, _) => ErrorView(
                      message: 'Search failed',
                      onRetry: () => ref.invalidate(searchResultsProvider),
                    ),
                    data: (books) {
                      if (books.isEmpty) {
                        return EmptyView(
                          title: 'No results',
                          message: 'Nothing matched "$query".',
                        );
                      }
                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: responsiveGridCount(context),
                          childAspectRatio: 0.52,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: books.length,
                        itemBuilder: (_, i) =>
                            BookCard(book: books[i], width: double.infinity),
                      );
                    },
                  ),
          ),
      ],
    );
  }
}
