import 'package:akuko/core/api/api_client.dart';

class BooksApi {
  BooksApi(this._client);

  final AkukoApiClient _client;

  Future<List<Map<String, dynamic>>> listBooks({
    int page = 1,
    int perPage = 20,
    String? category,
  }) async {
    final data = await _client.get(
      'books',
      queryParams: {
        'page': '$page',
        'per_page': '$perPage',
        if (category != null) 'category': category,
      },
    );
    return apiListOf(data).map(apiNormalizeRow).toList();
  }

  Future<Map<String, dynamic>> getBook(String id) async {
    final data = await _client.get('books/$id');
    return apiNormalizeRow(Map<String, dynamic>.from(data as Map));
  }

  Future<List<Map<String, dynamic>>> featured({int limit = 10}) async {
    final data = await _client.get(
      'books/featured',
      queryParams: {'limit': '$limit'},
    );
    return apiListOf(data).map(apiNormalizeRow).toList();
  }

  Future<List<Map<String, dynamic>>> trending({int limit = 10}) async {
    final data = await _client.get('books/trending');
    final list = apiListOf(data);
    return list.take(limit).map(apiNormalizeRow).toList();
  }

  Future<List<Map<String, dynamic>>> newReleases({int limit = 10}) async {
    final data = await _client.get('books/new-releases');
    final list = apiListOf(data);
    return list.take(limit).map(apiNormalizeRow).toList();
  }

  Future<List<Map<String, dynamic>>> related(String bookId) async {
    final data = await _client.get('books/$bookId/related');
    return apiListOf(data).map(apiNormalizeRow).toList();
  }

  Future<List<Map<String, dynamic>>> categories() async {
    final data = await _client.get('categories');
    return apiListOf(data).map(apiNormalizeRow).toList();
  }

  Future<List<Map<String, dynamic>>> authors({
    int page = 1,
    int perPage = 20,
  }) async {
    final data = await _client.get(
      'authors',
      queryParams: {'page': '$page', 'per_page': '$perPage'},
    );
    return apiListOf(data).map(apiNormalizeRow).toList();
  }

  Future<Map<String, dynamic>?> authorById(String id) async {
    try {
      final data = await _client.get('authors/$id');
      return apiNormalizeRow(Map<String, dynamic>.from(data as Map));
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> search(
    String query, {
    int page = 1,
    int perPage = 20,
  }) async {
    final data = await _client.get(
      'search',
      queryParams: {
        'q': query,
        'page': '$page',
        'per_page': '$perPage',
      },
    );
    return apiListOf(data).map(apiNormalizeRow).toList();
  }
}
