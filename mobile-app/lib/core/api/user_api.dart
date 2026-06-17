import 'package:akuko/core/api/api_client.dart';

class UserApi {
  UserApi(this._client);

  final AkukoApiClient _client;

  Future<Map<String, dynamic>> me() async {
    final data = await _client.get('auth/me', auth: true);
    return apiNormalizeRow(Map<String, dynamic>.from(data as Map));
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> payload) async {
    // Profile fields are updated via PATCH-style body on /auth/me when available;
    // fall back to re-fetch after partial updates through settings.
    final data = await _client.put('auth/me', auth: true, body: payload);
    if (data is Map) return apiNormalizeRow(Map<String, dynamic>.from(data));
    return me();
  }

  Future<List<Map<String, dynamic>>> library({
    int page = 1,
    int perPage = 20,
  }) async {
    final data = await _client.get(
      'library',
      auth: true,
      queryParams: {'page': '$page', 'per_page': '$perPage'},
    );
    return apiListOf(data).map(apiNormalizeRow).toList();
  }

  Future<List<Map<String, dynamic>>> continueReading({int limit = 10}) async {
    final data = await _client.get(
      'library/continue-reading',
      auth: true,
      queryParams: {'limit': '$limit'},
    );
    return apiListOf(data).map(_normalizeContinueReading).toList();
  }

  Map<String, dynamic> _normalizeContinueReading(Map<String, dynamic> row) {
    final out = apiNormalizeRow(row);
    if (out['book'] is Map && !out.containsKey('books')) {
      out['books'] = out['book'];
    }
    if (out.containsKey('position') && !out.containsKey('location')) {
      out['location'] = out['position'];
    }
    if (out.containsKey('percentage') && !out.containsKey('progress_percent')) {
      out['progress_percent'] = out['percentage'];
    }
    return out;
  }
}
