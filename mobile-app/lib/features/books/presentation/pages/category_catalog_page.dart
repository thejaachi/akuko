import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:akuko/core/error/failures.dart' show describeError;
import 'package:akuko/core/utils/result.dart';
import 'package:akuko/core/utils/extensions.dart';
import 'package:akuko/core/utils/responsive.dart';
import 'package:akuko/core/widgets/empty_view.dart';
import 'package:akuko/core/widgets/error_view.dart';
import 'package:akuko/core/widgets/loading_view.dart';
import 'package:akuko/features/books/data/curated_home_content.dart';
import 'package:akuko/features/books/presentation/controllers/book_providers.dart';
import 'package:akuko/features/books/presentation/widgets/book_card.dart';
import 'package:akuko/shared/domain/entities/book.dart';

List<Book> _filterByMasterCategory(
  List<Book> books,
  MasterContentCategory category,
) {
  final curatedIds = CuratedHomeContent.booksForMasterCategory(category)
      .map((b) => b.id)
      .toSet();
  return books.where((b) {
    if (curatedIds.contains(b.id)) return true;
    return category.defaultMatch(b);
  }).toList();
}

extension on MasterContentCategory {
  bool defaultMatch(Book book) {
    return switch (this) {
      MasterContentCategory.fiction =>
        !book.title.toLowerCase().contains('poetry'),
      MasterContentCategory.nonfiction =>
        book.title.toLowerCase().contains('history') ||
            book.author.toLowerCase().contains('achebe'),
      MasterContentCategory.poetry =>
        book.title.toLowerCase().contains('poem') ||
            book.title.toLowerCase().contains('verse'),
    };
  }
}

final catalogBooksProvider =
    FutureProvider.family<List<Book>, MasterContentCategory>((ref, category) async {
  final lang = ref.watch(selectedLanguageFilterProvider);
  final curated = CuratedHomeContent.booksForMasterCategory(category);
  final allCurated = CuratedHomeContent.toBooks(curated);

  try {
    final featured =
        (await ref.watch(bookRepositoryProvider).getFeatured()).getOrThrow();
    final trending =
        (await ref.watch(bookRepositoryProvider).getTrending()).getOrThrow();
    final releases =
        (await ref.watch(bookRepositoryProvider).getNewReleases()).getOrThrow();

    final merged = <Book>[
      ...allCurated,
      ...featured,
      ...trending,
      ...releases,
    ];

    final seen = <String>{};
    final unique = <Book>[];
    for (final b in merged) {
      final key = b.id;
      if (seen.add(key)) unique.add(b);
    }

    final filtered = _filterByMasterCategory(unique, category);
    if (lang == null || lang.isEmpty) return filtered;
    return filtered
        .where((b) => b.language.toLowerCase() == lang.toLowerCase())
        .toList();
  } catch (_) {
    return allCurated;
  }
});

class CategoryCatalogPage extends ConsumerWidget {
  const CategoryCatalogPage({required this.categorySlug, super.key});

  final String categorySlug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = MasterContentCategory.fromSlug(categorySlug);
    if (category == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyView(
          title: 'Unknown category',
          message: 'This catalogue category does not exist.',
        ),
      );
    }

    final books = ref.watch(catalogBooksProvider(category));

    return Scaffold(
      appBar: AppBar(title: Text(category.label)),
      body: books.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: describeError(e, 'Could not load ${category.label}'),
          onRetry: () => ref.invalidate(catalogBooksProvider(category)),
        ),
        data: (items) {
          if (items.isEmpty) {
            return EmptyView(
              title: 'No ${category.label} titles yet',
              message: 'Check back soon for new additions.',
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
            itemCount: items.length,
            itemBuilder: (_, i) =>
                BookCard(book: items[i], width: double.infinity),
          );
        },
      ),
    );
  }
}
