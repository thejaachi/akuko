import 'package:akuko/core/error/exceptions.dart';
import 'package:akuko/core/error/failures.dart';
import 'package:akuko/core/utils/result.dart';
import 'package:akuko/features/books/data/datasources/book_remote_datasource.dart';
import 'package:akuko/features/books/data/models/book_model.dart';
import 'package:akuko/features/books/data/models/category_model.dart';
import 'package:akuko/features/books/domain/repositories/book_repository.dart';
import 'package:akuko/shared/domain/entities/book.dart';
import 'package:akuko/shared/domain/entities/category.dart';

class SupabaseBookRepository implements BookRepository {
  SupabaseBookRepository(this._remote);

  final BookRemoteDataSource _remote;

  Failure _mapError(Object error) => switch (error) {
        NotFoundException(:final message) => NotFoundFailure(message),
        NetworkException(:final message) => NetworkFailure(message),
        ServerException(:final message) => ServerFailure(message, error),
        _ => UnknownFailure('Failed to load catalogue', error),
      };

  List<Book> _mapBooks(List<Map<String, dynamic>> rows) =>
      rows.map(BookModel.fromJson).toList();

  @override
  Future<Result<List<Book>>> getFeatured({int limit = 10}) {
    return guardAsync(
      () async => _mapBooks(await _remote.getFeatured(limit: limit)),
      onError: (e, _) => _mapError(e),
    );
  }

  @override
  Future<Result<List<Book>>> getTrending({int limit = 10}) {
    return guardAsync(
      () async => _mapBooks(await _remote.getTrending(limit: limit)),
      onError: (e, _) => _mapError(e),
    );
  }

  @override
  Future<Result<List<Book>>> getNewReleases({int limit = 10}) {
    return guardAsync(
      () async => _mapBooks(await _remote.getNewReleases(limit: limit)),
      onError: (e, _) => _mapError(e),
    );
  }

  @override
  Future<Result<List<Book>>> getByCategory(
    String categoryId, {
    int limit = 20,
    int offset = 0,
  }) {
    return guardAsync(
      () async => _mapBooks(
        await _remote.getByCategory(categoryId, limit: limit, offset: offset),
      ),
      onError: (e, _) => _mapError(e),
    );
  }

  @override
  Future<Result<List<Book>>> getByCategorySlug(
    String slug, {
    int limit = 20,
    int offset = 0,
  }) {
    return guardAsync(
      () async => _mapBooks(
        await _remote.getByCategorySlug(slug, limit: limit, offset: offset),
      ),
      onError: (e, _) => _mapError(e),
    );
  }

  @override
  Future<Result<List<Book>>> getChristianBooks({int limit = 10}) {
    return guardAsync(
      () async => _mapBooks(await _remote.getChristianBooks(limit: limit)),
      onError: (e, _) => _mapError(e),
    );
  }

  @override
  Future<Result<List<Book>>> search(String query, {int limit = 30}) {
    return guardAsync(
      () async => _mapBooks(await _remote.search(query, limit: limit)),
      onError: (e, _) => _mapError(e),
    );
  }

  @override
  Future<Result<Book>> getById(String id) {
    return guardAsync(
      () async => BookModel.fromJson(await _remote.getById(id)),
      onError: (e, _) => _mapError(e),
    );
  }

  @override
  Future<Result<List<Category>>> listCategories() {
    return guardAsync(
      () async => (await _remote.listCategories())
          .map(CategoryModel.fromJson)
          .toList(),
      onError: (e, _) => _mapError(e),
    );
  }
}
