import 'package:share_plus/share_plus.dart';

import 'package:akuko/shared/domain/entities/book.dart';

/// Shares a book recommendation with a deep-link stub.
Future<void> shareBook(Book book) {
  final link = 'https://akuko.app/book/${book.id}';
  return Share.share(
    'Read ${book.title} by ${book.author} on Akuko.\n$link',
  );
}
