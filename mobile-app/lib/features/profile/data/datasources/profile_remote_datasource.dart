import 'package:akuko/core/api/user_api.dart';
import 'package:akuko/core/error/exceptions.dart';

class ProfileRemoteDataSource {
  ProfileRemoteDataSource(this._api);

  final UserApi _api;

  Future<Map<String, dynamic>> getProfile(String userId) async {
    try {
      final row = await _api.me();
      if (row.isEmpty) throw NotFoundException('Profile not found');
      return row;
    } on NotFoundException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to load profile', e);
    }
  }

  Future<Map<String, dynamic>> updateProfile(
    String userId,
    Map<String, dynamic> payload,
  ) async {
    try {
      return await _api.updateProfile(payload);
    } catch (e) {
      throw ServerException('Failed to update profile', e);
    }
  }

  Future<void> updateReadingPreferences(
    String userId,
    Map<String, dynamic> preferences,
  ) async {
    try {
      await _api.updateProfile({'reading_preferences': preferences});
    } catch (e) {
      throw ServerException('Failed to update preferences', e);
    }
  }
}
