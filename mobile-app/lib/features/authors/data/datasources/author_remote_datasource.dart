import 'package:akuko/core/api/books_api.dart';
import 'package:akuko/features/authors/domain/entities/author.dart';

class AuthorRemoteDataSource {
  AuthorRemoteDataSource(this._api);

  final BooksApi _api;

  Future<List<Author>> listAuthors({int limit = 20}) async {
    final rows = await _api.authors(perPage: limit);
    return rows.map(_map).toList();
  }

  Future<List<Author>> authorsFromBookIds(List<String> authorNames) async {
    if (authorNames.isEmpty) return [];
    final all = await _api.authors(perPage: 100);
    final unique = authorNames.toSet();
    return all
        .where((r) => unique.contains(r['name'] as String?))
        .map(_map)
        .toList();
  }

  Future<Author?> getById(String id) async {
    final row = await _api.authorById(id);
    return row == null ? null : _map(row);
  }

  Author _map(Map<String, dynamic> json) => Author(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        bio: json['bio'] as String?,
        avatarUrl: json['avatar_url'] as String?,
      );
}
