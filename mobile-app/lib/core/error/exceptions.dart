/// Low-level exceptions thrown by the data layer (datasources). These are
/// caught inside repository implementations and translated into `Failure`s.
library;

class AppException implements Exception {
  const AppException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown for non-2xx API errors from the remote backend.
class ServerException extends AppException {
  const ServerException([super.message = 'Server error', super.cause]);
}

/// Thrown when the server denies access (HTTP 403).
class AccessDeniedException extends AppException {
  const AccessDeniedException([super.message = 'Access denied', super.cause]);
}

/// Thrown for auth-specific failures (invalid credentials, expired session).
class AuthException extends AppException {
  const AuthException([super.message = 'Authentication error', super.cause]);
}

/// Thrown when a requested entity does not exist.
class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Not found', super.cause]);
}

/// Thrown for connectivity problems.
class NetworkException extends AppException {
  const NetworkException([super.message = 'Network error', super.cause]);
}

/// Thrown for local persistence problems (shared_preferences, files).
class CacheException extends AppException {
  const CacheException([super.message = 'Cache error', super.cause]);
}
