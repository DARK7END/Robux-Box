import 'failure.dart';

/// A lightweight, dependency-free `Result` type (a.k.a. Either) used to model
/// success/failure without throwing across layer boundaries.
///
/// Repositories return `Future<Result<T>>`; controllers pattern-match on the
/// result to update UI state. Using this instead of exceptions makes the
/// success/error contract explicit and impossible to forget.
sealed class Result<T> {
  const Result();

  const factory Result.success(T value) = Success<T>;
  const factory Result.failure(Failure failure) = Err<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Err<T>;

  /// The value if successful, else null.
  T? get valueOrNull => switch (this) {
        Success<T>(:final value) => value,
        Err<T>() => null,
      };

  /// The failure if failed, else null.
  Failure? get failureOrNull => switch (this) {
        Success<T>() => null,
        Err<T>(:final failure) => failure,
      };

  /// Exhaustive fold over both branches.
  R when<R>({
    required R Function(T value) success,
    required R Function(Failure failure) failure,
  }) {
    return switch (this) {
      Success<T>(:final value) => success(value),
      Err<T>(:final failure) => failure(failure),
    };
  }

  /// Maps the success value, preserving a failure.
  Result<R> map<R>(R Function(T value) transform) {
    return switch (this) {
      Success<T>(:final value) => Success<R>(transform(value)),
      Err<T>(:final failure) => Err<R>(failure),
    };
  }

  /// Chains another result-returning operation.
  Future<Result<R>> flatMapAsync<R>(
    Future<Result<R>> Function(T value) transform,
  ) async {
    return switch (this) {
      Success<T>(:final value) => await transform(value),
      Err<T>(:final failure) => Err<R>(failure),
    };
  }
}

class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}
