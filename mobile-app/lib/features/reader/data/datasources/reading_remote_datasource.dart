import 'package:akuko/core/api/reading_api.dart';
import 'package:akuko/core/auth/auth_session_manager.dart';
import 'package:akuko/core/error/exceptions.dart';

/// Persists reading progress and bookmarks via the WordPress API.
class ReadingRemoteDataSource {
  ReadingRemoteDataSource(this._api, this._session);

  final ReadingApi _api;
  final AuthSessionManager _session;

  String get _userId {
    final id = _session.currentUser?.id;
    if (id == null) throw const AuthException('Not authenticated');
    return id;
  }

  Future<Map<String, dynamic>> upsertProgress(
    Map<String, dynamic> payload,
  ) async {
    try {
      final bookId = payload['book_id'] as String;
      return await _api.saveProgress(
        bookId,
        position: payload['location'] as String? ?? '0',
        percentage: (payload['progress_percent'] as num?)?.toDouble() ?? 0,
      )..putIfAbsent('user_id', () => _userId);
    } catch (e) {
      throw ServerException('Failed to save progress', e);
    }
  }

  Future<Map<String, dynamic>?> getProgress(String bookId) async {
    try {
      final row = await _api.getProgress(bookId);
      if (row == null) return null;
      return row..putIfAbsent('user_id', () => _userId);
    } catch (e) {
      throw ServerException('Failed to load progress', e);
    }
  }

  Future<Map<String, dynamic>> addBookmark(
    Map<String, dynamic> payload,
  ) async {
    try {
      return await _api.addBookmark(
        bookId: payload['book_id'] as String,
        cfi: payload['location'] as String? ?? '',
        label: payload['label'] as String?,
      )..putIfAbsent('user_id', () => _userId);
    } catch (e) {
      throw ServerException('Failed to add bookmark', e);
    }
  }

  Future<List<Map<String, dynamic>>> listBookmarks(String bookId) async {
    try {
      final rows = await _api.listBookmarks(bookId: bookId);
      return rows.map((r) => r..putIfAbsent('user_id', () => _userId)).toList();
    } catch (e) {
      throw ServerException('Failed to load bookmarks', e);
    }
  }

  Future<void> deleteBookmark(String bookmarkId) async {
    try {
      await _api.deleteBookmark(bookmarkId);
    } catch (e) {
      throw ServerException('Failed to delete bookmark', e);
    }
  }
}
