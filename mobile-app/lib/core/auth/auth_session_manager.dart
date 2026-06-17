import 'dart:async';

import 'package:akuko/core/api/auth_api.dart';
import 'package:akuko/core/api/token_storage.dart';
import 'package:akuko/features/auth/domain/entities/auth_user.dart';

/// Manages authenticated session state and broadcasts auth changes.
class AuthSessionManager {
  AuthSessionManager(this._tokens);

  final TokenStorage _tokens;

  AuthUser? _currentUser;
  final _controller = StreamController<AuthUser?>.broadcast();

  AuthUser? get currentUser => _currentUser;

  Stream<AuthUser?> get authStateChanges => _controller.stream;

  /// Restore session from stored tokens on cold start.
  Future<void> bootstrap(AuthApi authApi) async {
    if (!_tokens.hasSession) {
      _emit(null);
      return;
    }
    try {
      final me = await authApi.me();
      _currentUser = _mapUser(me);
      _emit(_currentUser);
    } catch (_) {
      await _tokens.clear();
      _emit(null);
    }
  }

  void setUserFromLogin(Map<String, dynamic> loginData) {
    final userJson = loginData['user'] as Map<String, dynamic>?;
    if (userJson != null) {
      _currentUser = _mapUser(userJson);
      _emit(_currentUser);
    }
  }

  void clear() {
    _currentUser = null;
    _emit(null);
  }

  AuthUser _mapUser(Map<String, dynamic> json) => AuthUser(
        id: json['id']?.toString() ?? '',
        email: json['email'] as String?,
        emailConfirmed: json['email_confirmed'] as bool? ??
            json['email_verified'] as bool? ??
            true,
      );

  void _emit(AuthUser? user) {
    _currentUser = user;
    if (!_controller.isClosed) {
      _controller.add(user);
    }
  }

  void dispose() => _controller.close();
}
