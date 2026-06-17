import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:akuko/core/network/api_client_provider.dart';
import 'package:akuko/core/utils/result.dart';
import 'package:akuko/features/reader/data/datasources/reading_remote_datasource.dart';
import 'package:akuko/features/reader/data/repositories/supabase_reading_repository.dart';
import 'package:akuko/features/reader/domain/repositories/reading_repository.dart';
import 'package:akuko/shared/domain/entities/bookmark.dart';
import 'package:akuko/shared/domain/entities/reading_progress.dart';

final readingRemoteDataSourceProvider =
    Provider<ReadingRemoteDataSource>((ref) {
  return ReadingRemoteDataSource(
    ref.watch(readingApiProvider),
    ref.watch(authSessionManagerProvider),
  );
});

final readingRepositoryProvider = Provider<ReadingRepository>((ref) {
  return SupabaseReadingRepository(ref.watch(readingRemoteDataSourceProvider));
});

/// Saved progress for a book (null when the user has not started it).
final readingProgressProvider =
    FutureProvider.family<ReadingProgress?, String>((ref, bookId) async {
  return (await ref.watch(readingRepositoryProvider).getProgress(bookId))
      .getOrThrow();
});

/// Bookmarks for a book. Exposed as a notifier so the reader can optimistically
/// add/remove without a full refetch.
class BookmarksController
    extends FamilyAsyncNotifier<List<Bookmark>, String> {
  late String _bookId;

  @override
  Future<List<Bookmark>> build(String bookId) async {
    _bookId = bookId;
    return (await ref.read(readingRepositoryProvider).listBookmarks(bookId))
        .getOrThrow();
  }

  Future<void> add(Bookmark bookmark) async {
    final result =
        await ref.read(readingRepositoryProvider).addBookmark(bookmark);
    switch (result) {
      case Ok(:final value):
        state = AsyncData([value, ...?state.valueOrNull]);
      case Err(:final failure):
        state = AsyncError(failure, StackTrace.current);
    }
  }

  Future<void> remove(String bookmarkId) async {
    final result =
        await ref.read(readingRepositoryProvider).deleteBookmark(bookmarkId);
    if (result.isOk) {
      state = AsyncData(
        [...?state.valueOrNull]..removeWhere((b) => b.id == bookmarkId),
      );
    }
  }

  Future<void> refreshList() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () async => (await ref.read(readingRepositoryProvider).listBookmarks(_bookId))
          .getOrThrow(),
    );
  }
}

final bookmarksProvider = AsyncNotifierProvider.family<BookmarksController,
    List<Bookmark>, String>(BookmarksController.new);
