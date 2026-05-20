/// Typed result wrapper for service calls.
/// Every service method returns either [Success] or [Failure].
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends Result<T> {
  final String message;
  final int? statusCode;
  final dynamic error;
  const Failure(this.message, {this.statusCode, this.error});
}

/// Convenience extensions on Result.
extension ResultX<T> on Result<T> {
  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get dataOrNull => this is Success<T> ? (this as Success<T>).data : null;
  String? get errorMessage =>
      this is Failure<T> ? (this as Failure<T>).message : null;

  /// Transform the success value.
  Result<R> map<R>(R Function(T data) transform) {
    return switch (this) {
      Success(data: final d) => Success(transform(d)),
      Failure(message: final m, statusCode: final c, error: final e) =>
        Failure(m, statusCode: c, error: e),
    };
  }

  /// Execute a callback on success, return the original result.
  Result<T> onSuccess(void Function(T data) action) {
    if (this is Success<T>) action((this as Success<T>).data);
    return this;
  }

  /// Execute a callback on failure, return the original result.
  Result<T> onFailure(void Function(String message) action) {
    if (this is Failure<T>) action((this as Failure<T>).message);
    return this;
  }
}
