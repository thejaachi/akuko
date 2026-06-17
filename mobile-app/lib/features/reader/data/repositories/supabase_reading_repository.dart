import 'package:akuko/core/error/exceptions.dart';
import 'package:akuko/core/error/failures.dart';
import 'package:akuko/core/utils/result.dart';
import 'package:akuko/features/reader/data/datasources/reading_remote_datasource.dart';
import 'package:akuko/features/reader/data/models/bookmark_model.dart';
import 'package:akuko/features/reader/data/models/reading_progress_model.dart';
import 'package:akuko/features/reader/domain/repositories/reading_repository.dart';
import 'package:akuko/shared/domain/entities/bookmark.dart';
import 'package:akuko/shared/domain/entities/reading_progress.dart';

class SupabaseReadingRepository implements ReadingRepository {
  SupabaseReadingRepository(this._remote);

  final ReadingRemoteDataSource _remote;

  Failure _mapError(Object error) => switch (error) {
        AuthException(:final message) => AuthFailure(message, error),
        NotFoundException(:final message) => NotFoundFailure(message),
        NetworkException(:final message) => NetworkFailure(message),
        ServerException(:final message) => ServerFailure(message, error),
        _ => UnknownFailure('Reading sync failed', error),
      };

  @override
  Future<Result<ReadingProgress>> saveProgress(ReadingProgress progress) {
    return guardAsync(
      () async => ReadingProgressModel.fromJson(
        await _remote.upsertProgress(
          ReadingProgressModel.toUpsertJson(progress),
        ),
      ),
      onError: (e, _) => _mapError(e),
    );
  }

  @override
  Future<Result<ReadingProgress?>> getProgress(String bookId) {
    return guardAsync(
      () async {
        final row = await _remote.getProgress(bookId);
        return row == null ? null : ReadingProgressModel.fromJson(row);
      },
      onError: (e, _) => _mapError(e),
    );
  }

  @override
  Future<Result<Bookmark>> addBookmark(Bookmark bookmark) {
    return guardAsync(
      () async => BookmarkModel.fromJson(
        await _remote.addBookmark(BookmarkModel.toInsertJson(bookmark)),
      ),
      onError: (e, _) => _mapError(e),
    );
  }

  @override
  Future<Result<List<Bookmark>>> listBookmarks(String bookId) {
    return guardAsync(
      () async => (await _remote.listBookmarks(bookId))
          .map(BookmarkModel.fromJson)
          .toList(),
      onError: (e, _) => _mapError(e),
    );
  }

  @override
  Future<Result<void>> deleteBookmark(String bookmarkId) {
    return guardAsync(
      () => _remote.deleteBookmark(bookmarkId),
      onError: (e, _) => _mapError(e),
    );
  }
}
