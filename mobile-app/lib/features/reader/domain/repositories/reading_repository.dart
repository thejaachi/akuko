import 'package:akuko/core/utils/result.dart';
import 'package:akuko/shared/domain/entities/bookmark.dart';
import 'package:akuko/shared/domain/entities/reading_progress.dart';

/// Reading-state contract: progress sync + bookmarks. Implemented by
/// `SupabaseReadingRepository`. Method names align with `docs/API_DESIGN.md`.
abstract interface class ReadingRepository {
  /// Upserts progress for the current user + book (unique user_id+book_id).
  Future<Result<ReadingProgress>> saveProgress(ReadingProgress progress);

  /// Returns saved progress for [bookId], or null if none exists.
  Future<Result<ReadingProgress?>> getProgress(String bookId);

  Future<Result<Bookmark>> addBookmark(Bookmark bookmark);

  Future<Result<List<Bookmark>>> listBookmarks(String bookId);

  Future<Result<void>> deleteBookmark(String bookmarkId);
}
