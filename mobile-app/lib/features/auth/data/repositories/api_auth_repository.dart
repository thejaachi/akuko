import 'package:akuko/core/error/exceptions.dart' as app;
import 'package:akuko/core/error/failures.dart';
import 'package:akuko/core/utils/result.dart';
import 'package:akuko/core/auth/auth_session_manager.dart';
import 'package:akuko/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:akuko/features/auth/domain/entities/auth_user.dart';
import 'package:akuko/features/auth/domain/repositories/auth_repository.dart';

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._remote, this._session);

  final AuthRemoteDataSource _remote;
  final AuthSessionManager _session;

  static AuthUser _mapUser(Map<String, dynamic> user) => AuthUser(
        id: user['id']?.toString() ?? '',
        email: user['email'] as String?,
        emailConfirmed: user['email_confirmed'] as bool? ??
            user['email_verified'] as bool? ??
            true,
      );

  Failure _mapError(Object error) => switch (error) {
        app.AuthException(:final message) => AuthFailure(message, error),
        app.NetworkException(:final message) => NetworkFailure(message),
        app.ServerException(:final message) => ServerFailure(message, error),
        _ => UnknownFailure('Authentication error', error),
      };

  @override
  AuthUser? get currentUser => _session.currentUser;

  @override
  Stream<AuthUser?> authStateChanges() => _session.authStateChanges;

  @override
  Future<Result<AuthUser>> signInWithEmail({
    required String email,
    required String password,
  }) {
    return guardAsync<AuthUser>(
      () async {
        final data = await _remote.signInWithEmail(
          email: email,
          password: password,
        );
        _remote.notifyLogin(data);
        final userJson = data['user'] as Map<String, dynamic>?;
        if (userJson == null) throw const app.AuthException('Sign-in failed');
        return _mapUser(userJson);
      },
      onError: (e, _) => _mapError(e),
    );
  }

  @override
  Future<Result<AuthUser>> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  }) {
    return guardAsync<AuthUser>(
      () async {
        final data = await _remote.signUpWithEmail(
          email: email,
          password: password,
          fullName: fullName,
        );
        _remote.notifyLogin(data);
        final userJson = data['user'] as Map<String, dynamic>?;
        if (userJson == null) throw const app.AuthException('Sign-up failed');
        return _mapUser(userJson);
      },
      onError: (e, _) => _mapError(e),
    );
  }

  @override
  Future<Result<void>> signInWithGoogle() {
    return guardAsync<void>(
      _remote.signInWithGoogle,
      onError: (e, _) => _mapError(e),
    );
  }

  @override
  Future<Result<void>> sendPasswordReset(String email) {
    return guardAsync<void>(
      () => _remote.sendPasswordReset(email),
      onError: (e, _) => _mapError(e),
    );
  }

  @override
  Future<Result<void>> signOut() {
    return guardAsync<void>(
      _remote.signOut,
      onError: (e, _) => _mapError(e),
    );
  }
}
