import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:akuko/core/error/failures.dart' show describeError;
import 'package:akuko/core/utils/responsive.dart';
import 'package:akuko/core/widgets/empty_view.dart';
import 'package:akuko/core/widgets/error_view.dart';
import 'package:akuko/core/widgets/loading_view.dart';
import 'package:akuko/features/books/presentation/controllers/book_providers.dart';
import 'package:akuko/features/books/presentation/widgets/book_card.dart';
import 'package:akuko/shared/domain/entities/category.dart';

/// Lists books in a category. Receives the category [slug] from the route and
/// resolves it to a category id via [categoriesProvider].
class CategoryPage extends ConsumerWidget {
  const CategoryPage({required this.slug, super.key});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_titleFor(categories))),
      body: categories.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: describeError(e, 'Could not load category'),
          onRetry: () => ref.invalidate(categoriesProvider),
        ),
        data: (cats) {
          final category = _findCategoryIn(cats);
          if (category == null) {
            return const EmptyView(
              title: 'Category not found',
              message: 'This category may have been removed.',
            );
          }
          return _CategoryBooks(categoryId: category.id);
        },
      ),
    );
  }

  String _titleFor(AsyncValue<List<Category>> categories) {
    final list = categories.asData?.value ?? const <Category>[];
    return _findCategoryIn(list)?.name ?? 'Category';
  }

  Category? _findCategoryIn(List<Category> cats) {
    for (final c in cats) {
      if (c.slug == slug) return c;
    }
    return null;
  }
}

class _CategoryBooks extends ConsumerWidget {
  const _CategoryBooks({required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = ref.watch(booksByCategoryProvider(categoryId));
    return books.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(
        message: describeError(e, 'Could not load books'),
        onRetry: () => ref.invalidate(booksByCategoryProvider(categoryId)),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const EmptyView(
            title: 'No books yet',
            message: 'Check back soon for new titles in this category.',
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
    );
  }
}
