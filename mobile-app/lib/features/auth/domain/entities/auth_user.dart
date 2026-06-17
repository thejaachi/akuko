import 'package:equatable/equatable.dart';

/// Minimal authenticated-user representation used by the domain layer so that
/// Supabase's `User` type does not leak past the data boundary.
class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    this.email,
    this.emailConfirmed = false,
  });

  final String id;
  final String? email;
  final bool emailConfirmed;

  @override
  List<Object?> get props => [id, email, emailConfirmed];
}
