import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:akuko/core/error/failures.dart' show describeError;
import 'package:akuko/core/utils/responsive.dart';
import 'package:akuko/core/widgets/empty_view.dart';
import 'package:akuko/core/widgets/error_view.dart';
import 'package:akuko/core/widgets/loading_view.dart';
import 'package:akuko/features/books/presentation/controllers/book_providers.dart';
import 'package:akuko/features/books/presentation/widgets/book_card.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchResultsProvider);
    final query = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Search titles and authors',
            border: InputBorder.none,
          ),
          onChanged: (value) =>
              ref.read(searchQueryProvider.notifier).state = value,
        ),
        actions: [
          if (query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _controller.clear();
                ref.read(searchQueryProvider.notifier).state = '';
              },
            ),
        ],
      ),
      body: query.trim().isEmpty
          ? const EmptyView(
              icon: Icons.search,
              title: 'Search Akuko',
              message: 'Find books by title or author.',
            )
          : results.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(
                message: describeError(e, 'Search failed'),
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
    );
  }
}
