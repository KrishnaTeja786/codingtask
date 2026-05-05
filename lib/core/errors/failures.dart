import 'package:equatable/equatable.dart';

/// Typed, exhaustive failure hierarchy. Sealed so the compiler enforces
/// pattern-matching coverage at every call site that handles errors.
sealed class Failure extends Equatable {
  const Failure(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  List<Object?> get props => [message, cause];
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

final class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message = 'Request timed out']);
}

final class ServerFailure extends Failure {
  const ServerFailure(super.message, {this.statusCode});
  final int? statusCode;

  @override
  List<Object?> get props => [...super.props, statusCode];
}

final class ParseFailure extends Failure {
  const ParseFailure([super.message = 'Failed to parse response']);
}

final class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Local cache error']);
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Resource not found']);
}

final class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Something went wrong']);
}
