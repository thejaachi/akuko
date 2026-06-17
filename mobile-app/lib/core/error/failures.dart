import 'package:equatable/equatable.dart';

/// Base type for all recoverable, user-facing errors flowing through the
/// domain layer. Repositories convert low-level [Exception]s into [Failure]s
/// and return them inside a `Result`.
sealed class Failure extends Equatable {
  const Failure(this.message, {this.cause});

  /// Human-readable, presentation-friendly message.
  final String message;

  /// Optional underlying error for logging/debugging.
  final Object? cause;

  @override
  List<Object?> get props => [message, cause];

  @override
  String toString() => '$runtimeType(message: $message)';
}

/// Network / connectivity related failure.
class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'No internet connection. Please try again.',
  ]) : super();
}

/// Remote server failure (non-2xx API error, etc.).
class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'Something went wrong on the server.',
    Object? cause,
  ]) : super(cause: cause);
}

/// Access denied (HTTP 403 — no purchase/premium).
class AccessDeniedFailure extends Failure {
  const AccessDeniedFailure([
    super.message = 'You do not have access to this resource.',
    Object? cause,
  ]) : super(cause: cause);
}

/// Authentication / authorization failure.
class AuthFailure extends Failure {
  const AuthFailure([
    super.message = 'Authentication failed.',
    Object? cause,
  ]) : super(cause: cause);
}

/// Requested resource was not found.
class NotFoundFailure extends Failure {
  const NotFoundFailure([
    super.message = 'The requested item could not be found.',
  ]) : super();
}

/// Local cache / persistence failure.
class CacheFailure extends Failure {
  const CacheFailure([
    super.message = 'Failed to read or write local data.',
  ]) : super();
}

/// Input validation failure.
class ValidationFailure extends Failure {
  const ValidationFailure([
    super.message = 'Please check your input and try again.',
  ]) : super();
}

/// Fallback for anything not otherwise classified.
class UnknownFailure extends Failure {
  const UnknownFailure([
    super.message = 'An unexpected error occurred.',
    Object? cause,
  ]) : super(cause: cause);
}

/// Extracts a user-facing message from any error object (used by `AsyncValue`
/// error builders where the error is typed as `Object`).
String describeError(Object error, [String fallback = 'Something went wrong']) {
  if (error is Failure) return error.message;
  return fallback;
}
