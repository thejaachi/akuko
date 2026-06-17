import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:akuko/core/network/api_client_provider.dart';
import 'package:akuko/core/utils/result.dart';
import 'package:akuko/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:akuko/features/auth/data/repositories/api_auth_repository.dart';
import 'package:akuko/features/auth/domain/entities/auth_user.dart';
import 'package:akuko/features/auth/domain/repositories/auth_repository.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(
    ref.watch(authApiProvider),
    ref.watch(authSessionManagerProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return ApiAuthRepository(
    ref.watch(authRemoteDataSourceProvider),
    ref.watch(authSessionManagerProvider),
  );
});

/// Reactive current-user stream. The router watches this to drive redirects.
final currentUserProvider = StreamProvider<AuthUser?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges();
});

/// Synchronous helper used inside the GoRouter redirect.
bool isAuthenticated(Ref ref) {
  final async = ref.read(currentUserProvider);
  final user = async.asData?.value ?? ref.read(authRepositoryProvider).currentUser;
  return user != null;
}

/// Drives transient action state (loading / error) for auth forms.
class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController(this._repo) : super(const AsyncData(null));

  final AuthRepository _repo;

  Future<bool> signIn({required String email, required String password}) {
    return _run(() => _repo.signInWithEmail(email: email, password: password));
  }

  Future<bool> signUp({
    required String email,
    required String password,
    String? fullName,
  }) {
    return _run(
      () => _repo.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
      ),
    );
  }

  Future<bool> signInWithGoogle() {
    return _run(_repo.signInWithGoogle);
  }

  Future<bool> sendPasswordReset(String email) {
    return _run(() => _repo.sendPasswordReset(email));
  }

  Future<bool> signOut() {
    return _run(_repo.signOut);
  }

  Future<bool> _run(Future<Result<dynamic>> Function() action) async {
    state = const AsyncLoading();
    final result = await action();
    return result.fold(
      (failure) {
        state = AsyncError(failure, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncData(null);
        return true;
      },
    );
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});
