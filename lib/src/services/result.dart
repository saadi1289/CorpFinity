/// Result type for handling success/failure states
sealed class Result<T> {
  const Result();

  /// Creates a success result
  factory Result.success(T data) => Success<T>(data);

  /// Creates a failure result
  factory Result.failure(String message, [Object? error]) => Failure<T>(message, error);

  /// Returns true if this is a success result
  bool get isSuccess => this is Success<T>;

  /// Returns true if this is a failure result
  bool get isFailure => this is Failure<T>;

  /// Gets the data if success, throws if failure
  T get data {
    if (this is Success<T>) {
      return (this as Success<T>).value;
    }
    throw StateError('Cannot get data from failure result');
  }

  /// Gets the data if success, returns null if failure
  T? getDataOrNull() {
    if (this is Success<T>) {
      return (this as Success<T>).value;
    }
    return null;
  }
  
  /// Alias for getDataOrNull for backward compatibility
  T? get dataOrNull => getDataOrNull();

  /// Gets the error message if failure, returns null if success
  String? get errorMessage {
    if (this is Failure<T>) {
      return (this as Failure<T>).message;
    }
    return null;
  }

  /// Maps the result to another type
  Result<R> map<R>(R Function(T data) mapper) {
    if (this is Success<T>) {
      return Result.success(mapper((this as Success<T>).value));
    }
    final failure = this as Failure<T>;
    return Result.failure(failure.message, failure.error);
  }

  /// Executes callback based on result type
  R when<R>({
    required R Function(T data) success,
    required R Function(String message, Object? error) failure,
  }) {
    if (this is Success<T>) {
      return success((this as Success<T>).value);
    }
    final f = this as Failure<T>;
    return failure(f.message, f.error);
  }
}

/// Success result containing data
class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

/// Failure result containing error info
class Failure<T> extends Result<T> {
  final String message;
  final Object? error;
  const Failure(this.message, [this.error]);
}

/// Extension for async operations with error handling
extension FutureResultExtension<T> on Future<T> {
  /// Wraps a future in a Result, catching any errors
  Future<Result<T>> toResult({String? errorMessage}) async {
    try {
      final data = await this;
      return Result.success(data);
    } catch (e) {
      return Result.failure(
        errorMessage ?? 'An unexpected error occurred',
        e,
      );
    }
  }
}
