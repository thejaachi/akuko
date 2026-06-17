import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:akuko/core/network/api_client_provider.dart';
import 'package:akuko/features/authors/data/datasources/author_remote_datasource.dart';
import 'package:akuko/features/authors/domain/entities/author.dart';
import 'package:akuko/features/library/presentation/controllers/library_providers.dart';

final authorRemoteDataSourceProvider = Provider<AuthorRemoteDataSource>((ref) {
  return AuthorRemoteDataSource(ref.watch(booksApiProvider));
});

/// Featured author for profile carousel — first from DB or fallback stub.
final featuredAuthorProvider = FutureProvider<Author?>((ref) async {
  try {
    final ds = ref.watch(authorRemoteDataSourceProvider);
    final authors = await ds.listAuthors(limit: 1);
    if (authors.isNotEmpty) return authors.first;
  } catch (_) {
    // Table may not exist in local dev.
  }
  return const Author(
    id: 'stub-chinua',
    name: 'Chinua Achebe',
    bio: 'Pioneer of African literature. Author of Things Fall Apart.',
    bookCount: 12,
  );
});

/// Authors derived from books the user has read (by author name join).
final myAuthorsProvider = FutureProvider<List<Author>>((ref) async {
  final entries = await ref.watch(continueReadingProvider.future);
  final names = entries.map((e) => e.book.author).where((n) => n.isNotEmpty).toList();
  if (names.isEmpty) return [];

  try {
    final ds = ref.watch(authorRemoteDataSourceProvider);
    final authors = await ds.authorsFromBookIds(names);
    if (authors.isNotEmpty) return authors;

    // Fallback: synthesize from book.author strings when authors table empty.
    return names.toSet().map((n) => Author(id: n, name: n)).toList();
  } catch (_) {
    return names.toSet().map((n) => Author(id: n, name: n)).toList();
  }
});
