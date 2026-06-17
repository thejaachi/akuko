import 'package:akuko/core/utils/result.dart';
import 'package:akuko/shared/domain/entities/book.dart';
import 'package:akuko/shared/domain/entities/category.dart';

/// Catalogue / discovery contract. Implemented by `SupabaseBookRepository`.
/// Method names align with `docs/API_DESIGN.md`.
abstract interface class BookRepository {
  Future<Result<List<Book>>> getFeatured({int limit = 10});

  Future<Result<List<Book>>> getTrending({int limit = 10});

  Future<Result<List<Book>>> getNewReleases({int limit = 10});

  Future<Result<List<Book>>> getByCategory(
    String categoryId, {
    int limit = 20,
    int offset = 0,
  });

  Future<Result<List<Book>>> getByCategorySlug(
    String slug, {
    int limit = 20,
    int offset = 0,
  });

  Future<Result<List<Book>>> getChristianBooks({int limit = 10});

  Future<Result<List<Book>>> search(String query, {int limit = 30});

  Future<Result<Book>> getById(String id);

  Future<Result<List<Category>>> listCategories();
}
