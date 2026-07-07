import 'package:equatable/equatable.dart';
import 'domain_exceptions.dart';

/// Result type for handling success/failure in a type-safe way
abstract class Result<T> extends Equatable {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get value => isSuccess ? (this as Success<T>).value : null;
  DomainException? get error => isFailure ? (this as Failure<T>).error : null;

  /// Fold over the result to handle both cases
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(DomainException error) onFailure,
  }) {
    if (this is Success<T>) {
      return onSuccess((this as Success<T>).value);
    } else {
      return onFailure((this as Failure<T>).error);
    }
  }

  /// Map success value
  Result<R> map<R>(R Function(T value) transform) {
    if (this is Success<T>) {
      return Success(transform((this as Success<T>).value));
    } else {
      return Failure((this as Failure).error);
    }
  }

  /// Map failure error
  Result<T> mapError(DomainException Function(DomainException error) transform) {
    if (this is Failure<T>) {
      return Failure(transform((this as Failure<T>).error));
    } else {
      return this as Success<T>;
    }
  }
}

/// Success case containing a value
class Success<T> extends Result<T> {
  final T value;

  const Success(this.value);

  @override
  List<Object?> get props => [value];
}

/// Failure case containing an error
class Failure<T> extends Result<T> {
  final DomainException error;

  const Failure(this.error);

  @override
  List<Object?> get props => [error];
}
