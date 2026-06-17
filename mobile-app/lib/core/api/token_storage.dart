import 'package:shared_preferences/shared_preferences.dart';

/// Persists JWT access/refresh tokens.
///
/// Uses [SharedPreferences] (no flutter_secure_storage in pubspec). Tokens are
/// sensitive — prefer OS keystore integration in a future hardening pass.
class TokenStorage {
  TokenStorage(this._prefs);

  final SharedPreferences _prefs;

  static const _accessKey = 'akuko.api.access_token';
  static const _refreshKey = 'akuko.api.refresh_token';
  static const _userIdKey = 'akuko.api.user_id';

  String? get accessToken => _prefs.getString(_accessKey);
  String? get refreshToken => _prefs.getString(_refreshKey);
  String? get userId => _prefs.getString(_userIdKey);

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    String? userId,
  }) async {
    await _prefs.setString(_accessKey, accessToken);
    await _prefs.setString(_refreshKey, refreshToken);
    if (userId != null) {
      await _prefs.setString(_userIdKey, userId);
    }
  }

  Future<void> updateAccessToken(String accessToken) async {
    await _prefs.setString(_accessKey, accessToken);
  }

  Future<void> clear() async {
    await _prefs.remove(_accessKey);
    await _prefs.remove(_refreshKey);
    await _prefs.remove(_userIdKey);
  }

  bool get hasSession => accessToken != null && accessToken!.isNotEmpty;
}
