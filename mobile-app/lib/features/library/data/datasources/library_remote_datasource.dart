import 'package:akuko/core/api/user_api.dart';
import 'package:akuko/core/error/exceptions.dart';

class LibraryRemoteDataSource {
  LibraryRemoteDataSource(this._api);

  final UserApi _api;

  Future<List<Map<String, dynamic>>> getContinueReading({
    required int limit,
  }) async {
    try {
      return await _api.continueReading(limit: limit);
    } catch (e) {
      throw ServerException('Failed to load library', e);
    }
  }
}
