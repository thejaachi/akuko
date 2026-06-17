import 'package:akuko/core/api/auth_api.dart';
import 'package:akuko/core/auth/auth_session_manager.dart';
import 'package:akuko/core/error/exceptions.dart' as app;

/// WordPress Akuko Mobile API auth datasource.
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._authApi, this._session);

  final AuthApi _authApi;
  final AuthSessionManager _session;

  Future<Map<String, dynamic>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _authApi.login(email: email, password: password);
    } on app.AppException {
      rethrow;
    } catch (e) {
      throw app.ServerException('Unexpected sign-in error', e);
    }
  }

  Future<Map<String, dynamic>> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      final parts = _splitName(fullName);
      return await _authApi.register(
        email: email,
        password: password,
        firstName: parts.$1,
        lastName: parts.$2,
      );
    } on app.AppException {
      rethrow;
    } catch (e) {
      throw app.ServerException('Unexpected sign-up error', e);
    }
  }

  /// TODO(auth): Wire WordPress OAuth when backend endpoint is available.
  Future<void> signInWithGoogle() async {
    throw const app.AuthException(
      'Google sign-in is not yet available. Use email and password.',
    );
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _authApi.forgotPassword(email);
    } on app.AppException {
      rethrow;
    } catch (e) {
      throw app.ServerException('Failed to send reset email', e);
    }
  }

  Future<void> signOut() async {
    try {
      await _authApi.logout();
      _session.clear();
    } catch (e) {
      _session.clear();
      throw app.ServerException('Failed to sign out', e);
    }
  }

  void notifyLogin(Map<String, dynamic> loginData) {
    _session.setUserFromLogin(loginData);
  }

  (String?, String?) _splitName(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return (null, null);
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return (parts.first, null);
    return (parts.first, parts.sublist(1).join(' '));
  }
}
