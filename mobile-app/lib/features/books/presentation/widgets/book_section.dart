import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:akuko/core/error/failures.dart' show describeError;
import 'package:akuko/core/widgets/error_view.dart';
import 'package:akuko/features/books/presentation/widgets/book_card.dart';
import 'package:akuko/shared/domain/entities/book.dart';

/// A horizontally scrolling, titled carousel of books that renders the
/// loading / error / empty / data states of an [AsyncValue].
class BookSection extends StatelessWidget {
  const BookSection({
    required this.title,
    required this.books,
    this.onRetry,
    this.height = 240,
    super.key,
  });

  final String title;
  final AsyncValue<List<Book>> books;
  final VoidCallback? onRetry;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
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
                return const Center(child: Text('Nothing here yet'));
              }
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => BookCard(book: items[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}
