import 'package:akuko/core/api/books_api.dart';
import 'package:akuko/core/error/exceptions.dart';

/// Reads catalogue data via the WordPress Akuko Mobile API.
class BookRemoteDataSource {
  BookRemoteDataSource(this._api);

  final BooksApi _api;

  Future<List<Map<String, dynamic>>> getFeatured({required int limit}) =>
      _api.featured(limit: limit);

  Future<List<Map<String, dynamic>>> getTrending({required int limit}) =>
      _api.trending(limit: limit);

  Future<List<Map<String, dynamic>>> getNewReleases({required int limit}) =>
      _api.newReleases(limit: limit);

  Future<List<Map<String, dynamic>>> getByCategory(
    String categoryId, {
    required int limit,
    required int offset,
  }) async {
    final page = (offset ~/ limit) + 1;
    return _api.listBooks(page: page, perPage: limit, category: categoryId);
  }

  Future<List<Map<String, dynamic>>> getByCategorySlug(
    String slug, {
    required int limit,
    required int offset,
  }) async {
    try {
      final cats = await _api.categories();
      Map<String, dynamic>? match;
      for (final c in cats) {
        if (c['slug'] == slug) {
          match = c;
          break;
        }
      }
      if (match == null) return const [];
      return getByCategory(
        match['id'] as String,
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      throw ServerException('Failed to load category', e);
    }
  }

  Future<List<Map<String, dynamic>>> getChristianBooks({
    required int limit,
  }) async {
    final bySlug = await getByCategorySlug(
      'christian-literature',
      limit: limit,
      offset: 0,
    );
    if (bySlug.isNotEmpty) return bySlug;
    final all = await _api.listBooks(perPage: limit);
    return all.where((b) => b['is_christian'] == true).toList();
  }

  Future<List<Map<String, dynamic>>> search(
    String query, {
    required int limit,
  }) =>
      _api.search(query, perPage: limit);

  Future<Map<String, dynamic>> getById(String id) async {
    try {
      return await _api.getBook(id);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to load book', e);
    }
  }

  Future<List<Map<String, dynamic>>> listCategories() => _api.categories();
}
