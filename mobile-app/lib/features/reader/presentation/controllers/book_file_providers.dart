import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:akuko/core/network/api_client_provider.dart';
import 'package:akuko/features/reader/data/datasources/book_file_remote_datasource.dart';

final bookFileRemoteDataSourceProvider =
    Provider<BookFileRemoteDataSource>((ref) {
  return BookFileRemoteDataSource(ref.watch(downloadsApiProvider));
});

/// Resolves a signed, readable URL for a book's file via the `signed-url` edge
/// function. The future throws [PremiumRequiredException] when the book is
/// premium and the user has no active subscription (HTTP `402`), surfacing as
/// an `AsyncError` the reader maps to a "premium required" view.
///
/// Kept as a throwing [FutureProvider] (rather than a `Result`-returning
/// repository) because the premium case needs a distinct, typed signal and the
/// core `Failure` hierarchy is `sealed` (cannot be extended outside `core`).
final signedBookUrlProvider =
    FutureProvider.family<String, String>((ref, bookId) async {
  return ref.watch(bookFileRemoteDataSourceProvider).fetchSignedUrl(bookId);
});
