import 'package:akuko/core/api/api_client.dart';
import 'package:akuko/core/api/token_storage.dart';

class AuthApi {
  AuthApi(this._client, this._tokens);

  final AkukoApiClient _client;
  final TokenStorage _tokens;

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String? deviceId,
    String? deviceName,
  }) async {
    final data = await _client.post(
      'auth/login',
      body: {
        'email': email,
        'password': password,
        if (deviceId != null) 'device_id': deviceId,
        if (deviceName != null) 'device_name': deviceName,
      },
    ) as Map<String, dynamic>;

    await _persistTokens(data);
    return data;
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? deviceId,
    String? deviceName,
  }) async {
    final data = await _client.post(
      'auth/register',
      body: {
        'email': email,
        'password': password,
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (deviceId != null) 'device_id': deviceId,
        if (deviceName != null) 'device_name': deviceName,
      },
    ) as Map<String, dynamic>;

    await _persistTokens(data);
    return data;
  }

  Future<void> logout({String? refreshToken}) async {
    try {
      await _client.post(
        'auth/logout',
        auth: true,
        body: refreshToken != null ? {'refresh_token': refreshToken} : null,
      );
    } finally {
      await _tokens.clear();
    }
  }

  Future<void> forgotPassword(String email) async {
    await _client.post('auth/forgot-password', body: {'email': email});
  }

  Future<Map<String, dynamic>> refresh(String refreshToken) async {
    final data = await _client.post(
      'auth/refresh',
      body: {'refresh_token': refreshToken},
    ) as Map<String, dynamic>;
    await _persistTokens(data);
    return data;
  }

  Future<Map<String, dynamic>> me() async {
    final data = await _client.get('auth/me', auth: true);
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return data.cast<String, dynamic>();
    return {};
  }

  Future<void> _persistTokens(Map<String, dynamic> data) async {
    final access = data['access_token'] as String?;
    final refresh = data['refresh_token'] as String?;
    if (access == null || refresh == null) return;

    final user = data['user'];
    await _tokens.saveTokens(
      accessToken: access,
      refreshToken: refresh,
      userId: user is Map ? user['id']?.toString() : null,
    );
  }
}
