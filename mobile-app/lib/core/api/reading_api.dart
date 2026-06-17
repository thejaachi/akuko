import 'package:akuko/core/api/api_client.dart';

class ReadingApi {
  ReadingApi(this._client);

  final AkukoApiClient _client;

  Future<Map<String, dynamic>?> getProgress(String bookId) async {
    final data = await _client.get('reading/progress/$bookId', auth: true);
    if (data == null) return null;
    return _normalizeProgress(Map<String, dynamic>.from(data as Map));
  }

  Future<Map<String, dynamic>> saveProgress(
    String bookId, {
    required String position,
    required double percentage,
    String? chapter,
  }) async {
    await _client.put(
      'reading/progress/$bookId',
      auth: true,
      body: {
        'position': position,
        'percentage': percentage,
        if (chapter != null) 'chapter': chapter,
      },
    );
    final row = await getProgress(bookId);
    return row ?? {
      'book_id': bookId,
      'location': position,
      'progress_percent': percentage,
    };
  }

  Future<List<Map<String, dynamic>>> listBookmarks({String? bookId}) async {
    final data = await _client.get(
      'bookmarks',
      auth: true,
      queryParams: bookId != null ? {'book_id': bookId} : null,
    );
    return apiListOf(data).map(_normalizeBookmark).toList();
  }

  Future<Map<String, dynamic>> addBookmark({
    required String bookId,
    required String cfi,
    String? label,
  }) async {
    final data = await _client.post(
      'bookmarks',
      auth: true,
      body: {
        'book_id': bookId,
        'cfi': cfi,
        if (label != null) 'label': label,
      },
    );
    if (data is Map && data.containsKey('id')) {
      return _normalizeBookmark({
        'id': data['id'].toString(),
        'book_id': bookId,
        'location': cfi,
        if (label != null) 'label': label,
      });
    }
    final list = await listBookmarks(bookId: bookId);
    return list.isNotEmpty ? list.first : _normalizeBookmark({
          'book_id': bookId,
          'location': cfi,
          'label': label,
        });
  }

  Future<void> deleteBookmark(String id) async {
    await _client.delete(
      'bookmarks',
      auth: true,
      queryParams: {'id': id},
    );
  }

  Map<String, dynamic> _normalizeProgress(Map<String, dynamic> row) {
    final out = apiNormalizeRow(row);
    if (out.containsKey('position') && !out.containsKey('location')) {
      out['location'] = out['position'];
    }
    if (out.containsKey('percentage') && !out.containsKey('progress_percent')) {
      out['progress_percent'] = out['percentage'];
    }
    if (out.containsKey('updated_at') && !out.containsKey('last_read_at')) {
      out['last_read_at'] = out['updated_at'];
    }
    return out;
  }

  Map<String, dynamic> _normalizeBookmark(Map<String, dynamic> row) {
    final out = apiNormalizeRow(row);
    if (out.containsKey('cfi') && !out.containsKey('location')) {
      out['location'] = out['cfi'];
    }
    return out;
  }
}
