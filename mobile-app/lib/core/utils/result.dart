import 'package:akuko/core/error/failures.dart';

/// A lightweight, dependency-free Either-style type used across the domain
/// layer. We deliberately use a Dart 3 `sealed` class instead of `dartz` so the
/// codebase has zero extra runtime deps and exhaustive `switch` support.
///
/// Usage:
/// ```dart
/// final result = await repo.getById(id);
/// switch (result) {
///   case Ok(:final value): use(value);
///   case Err(:final failure): show(failure.message);
/// }
/// ```
sealed class Result<T> {
  const Result();

  /// Convenience constructors.
  const factory Result.ok(T value) = Ok<T>;
  const factory Result.err(Failure failure) = Err<T>;

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  /// The value if [Ok], otherwise null.
  T? get valueOrNull => switch (this) {
        Ok<T>(:final value) => value,
        Err<T>() => null,
      };

  /// The failure if [Err], otherwise null.
  Failure? get failureOrNull => switch (this) {
        Ok<T>() => null,
        Err<T>(:final failure) => failure,
      };

  /// Transform the success value, preserving any failure.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
        Ok<T>(:final value) => Ok<R>(transform(value)),
        Err<T>(:final failure) => Err<R>(failure),
      };

  /// Fold both branches into a single value.
  R fold<R>(
    R Function(Failure failure) onErr,
    R Function(T value) onOk,
  ) =>
      switch (this) {
        Ok<T>(:final value) => onOk(value),
        Err<T>(:final failure) => onErr(failure),
      };
}

/// Success branch.
final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

/// Failure branch.
final class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}

extension ResultX<T> on Result<T> {
  /// Returns the success value or throws the [Failure].
  ///
  /// Useful inside Riverpod `FutureProvider`s so domain failures surface as
  /// `AsyncError(failure)`, which the UI renders via `ErrorView`.
  T getOrThrow() => switch (this) {
        Ok<T>(:final value) => value,
        Err<T>(:final failure) => throw failure,
      };
}

/// Run an async operation and capture thrown errors as a [Result].
///
/// [onError] maps a caught error into the appropriate [Failure].
Future<Result<T>> guardAsync<T>(
  Future<T> Function() action, {
  required Failure Function(Object error, StackTrace stackTrace) onError,
}) async {
  try {
    return Ok(await action());
  } catch (error, stackTrace) {
    return Err(onError(error, stackTrace));
  }
}
