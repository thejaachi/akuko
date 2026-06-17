import 'package:akuko/core/error/exceptions.dart';
import 'package:akuko/core/error/failures.dart';
import 'package:akuko/core/utils/result.dart';
import 'package:akuko/features/books/data/models/book_model.dart';
import 'package:akuko/features/library/data/datasources/library_remote_datasource.dart';
import 'package:akuko/features/library/domain/entities/library_entry.dart';
import 'package:akuko/features/library/domain/repositories/library_repository.dart';

class SupabaseLibraryRepository implements LibraryRepository {
  SupabaseLibraryRepository(this._remote);

  final LibraryRemoteDataSource _remote;

  Failure _mapError(Object error) => switch (error) {
        AuthException(:final message) => AuthFailure(message, error),
        NetworkException(:final message) => NetworkFailure(message),
        ServerException(:final message) => ServerFailure(message, error),
        _ => UnknownFailure('Failed to load library', error),
      };

  LibraryEntry _mapEntry(Map<String, dynamic> row) {
    final bookJson = (row['books'] as Map).cast<String, dynamic>();
    return LibraryEntry(
      book: BookModel.fromJson(bookJson),
      location: row['location'] as String?,
      progressPercent: (row['progress_percent'] as num?)?.toDouble() ?? 0,
      lastReadAt: row['last_read_at'] == null
          ? null
          : DateTime.tryParse(row['last_read_at'].toString()),
    );
  }

  @override
  Future<Result<List<LibraryEntry>>> getContinueReading({int limit = 30}) {
    return guardAsync(
      () async {
        final rows = await _remote.getContinueReading(limit: limit);
        return rows
            .where((r) => r['books'] != null)
            .map(_mapEntry)
            .toList();
      },
      onError: (e, _) => _mapError(e),
    );
  }
}
