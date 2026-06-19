import 'package:akuko/core/utils/result.dart';
import 'package:akuko/features/auth/domain/entities/auth_user.dart';

/// Authentication contract. Implemented by `SupabaseAuthRepository` in the
/// data layer. Method names align with `docs/API_DESIGN.md`.
abstract interface class AuthRepository {
  /// Currently authenticated user, or null if signed out.
  AuthUser? get currentUser;

  /// Emits the current [AuthUser] on sign-in / sign-out / token refresh.
  Stream<AuthUser?> authStateChanges();

  Future<Result<AuthUser>> signInWithEmail({
    required String email,
    required String password,
  });

  Future<Result<AuthUser>> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  });

  /// Launches the Google OAuth flow (native on mobile, redirect on web).
  Future<Result<AuthUser>> signInWithGoogle();

  /// Sends a password-reset email.
  Future<Result<void>> sendPasswordReset(String email);

  Future<Result<void>> signOut();
}
