import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:turbo_firestore_api/constants/k_error_codes.dart';

/// A sealed class for Firestore exceptions.
///
/// This class provides a type-safe way to handle different types of Firestore errors.
/// Each error type includes context-specific details about what went wrong.
sealed class TurboFirestoreException implements Exception {
  /// Creates a new Firestore exception.
  const TurboFirestoreException({
    required this.message,
    required this.code,
    this.path,
    this.query,
    this.stackTrace,
  });

  /// Factory method to create the appropriate exception from a Firestore error.
  factory TurboFirestoreException.fromFirestoreException(
    Object error,
    StackTrace stackTrace, {
    String? path,
    String? query,
  }) {
    if (error is FirebaseException) {
      switch (error.code) {
        case KErrorCodes.permissionDenied:
          return TurboFirestorePermissionDeniedException(
            message: error.message ?? KErrorCodes.permissionDeniedMessage,
            path: path,
            query: query,
            stackTrace: stackTrace,
            originalException: error,
          );
        case KErrorCodes.unavailable:
          return TurboFirestoreUnavailableException(
            message: error.message ?? KErrorCodes.unavailableMessage,
            stackTrace: stackTrace,
            originalException: error,
          );
        case KErrorCodes.notFound:
          return TurboFirestoreNotFoundException(
            message: error.message ?? KErrorCodes.notFoundMessage,
            path: path,
            stackTrace: stackTrace,
            originalException: error,
          );
        case KErrorCodes.alreadyExists:
          return TurboFirestoreAlreadyExistsException(
            message: error.message ?? KErrorCodes.alreadyExistsMessage,
            path: path,
            stackTrace: stackTrace,
            originalException: error,
          );
        case KErrorCodes.cancelled:
          return TurboFirestoreCancelledException(
            message: error.message ?? KErrorCodes.cancelledMessage,
            stackTrace: stackTrace,
            originalException: error,
          );
        case KErrorCodes.deadlineExceeded:
          return TurboFirestoreDeadlineExceededException(
            message: error.message ?? KErrorCodes.deadlineExceededMessage,
            stackTrace: stackTrace,
            originalException: error,
          );
        case KErrorCodes.invalidArgument:
          return TurboFirestoreGenericException(
            message: error.message ?? KErrorCodes.invalidArgumentMessage,
            code: error.code,
            stackTrace: stackTrace,
            originalException: error,
          );
        case KErrorCodes.failedPrecondition:
          return TurboFirestoreGenericException(
            message: error.message ?? KErrorCodes.failedPreconditionMessage,
            code: error.code,
            stackTrace: stackTrace,
            originalException: error,
          );
        case KErrorCodes.outOfRange:
          return TurboFirestoreGenericException(
            message: error.message ?? KErrorCodes.outOfRangeMessage,
            code: error.code,
            stackTrace: stackTrace,
            originalException: error,
          );
        case KErrorCodes.unauthenticated:
          return TurboFirestoreGenericException(
            message: error.message ?? KErrorCodes.unauthenticatedMessage,
            code: error.code,
            stackTrace: stackTrace,
            originalException: error,
          );
        case KErrorCodes.resourceExhausted:
          return TurboFirestoreGenericException(
            message: error.message ?? KErrorCodes.resourceExhaustedMessage,
            code: error.code,
            stackTrace: stackTrace,
            originalException: error,
          );
        case KErrorCodes.internal:
          return TurboFirestoreGenericException(
            message: error.message ?? KErrorCodes.internalMessage,
            code: error.code,
            stackTrace: stackTrace,
            originalException: error,
          );
        case KErrorCodes.unimplemented:
          return TurboFirestoreGenericException(
            message: error.message ?? KErrorCodes.unimplementedMessage,
            code: error.code,
            stackTrace: stackTrace,
            originalException: error,
          );
        case KErrorCodes.dataLoss:
          return TurboFirestoreGenericException(
            message: error.message ?? KErrorCodes.dataLossMessage,
            code: error.code,
            stackTrace: stackTrace,
            originalException: error,
          );
        default:
          return TurboFirestoreGenericException(
            message: error.message ?? KErrorCodes.unknownMessage,
            code: error.code,
            stackTrace: stackTrace,
            originalException: error,
          );
      }
    } else {
      return TurboFirestoreGenericException(
        message: error.toString(),
        code: KErrorCodes.unknown,
        stackTrace: stackTrace,
        originalException: error,
      );
    }
  }

  /// The error message.
  final String message;

  /// The error code.
  final String code;

  /// The Firestore path where the error occurred, if applicable.
  final String? path;

  /// The query that caused the error, if applicable.
  final String? query;

  /// The stack trace where the error occurred.
  final StackTrace? stackTrace;

  @override
  String toString() {
    final buffer = StringBuffer('TurboFirestoreException: $message');
    if (code.isNotEmpty) {
      buffer.write(' (code: $code)');
    }
    if (path != null) {
      buffer.write(' (path: $path)');
    }
    if (query != null) {
      buffer.write(' (query: $query)');
    }
    return buffer.toString();
  }
}

/// Exception thrown when permission is denied for a Firestore operation.
final class TurboFirestorePermissionDeniedException
    extends TurboFirestoreException {
  /// Creates a new permission denied exception.
  const TurboFirestorePermissionDeniedException({
    required super.message,
    super.path,
    super.query,
    super.stackTrace,
    required this.originalException,
  }) : super(code: KErrorCodes.permissionDenied);

  /// The original Firebase exception.
  final FirebaseException originalException;

  @override
  String toString() {
    final buffer =
        StringBuffer('TurboFirestorePermissionDeniedException: $message');
    buffer.write(' (code: $code)');
    if (path != null) {
      buffer.write(' (path: $path)');
    }
    if (query != null) {
      buffer.write(' (query: $query)');
    }
    buffer.write('\nOriginal exception: ${originalException.toString()}');
    if (stackTrace != null) {
      buffer.write('\nStack trace: $stackTrace');
    }
    return buffer.toString();
  }
}

/// Exception thrown when a Firestore service is unavailable.
final class TurboFirestoreUnavailableException extends TurboFirestoreException {
  /// Creates a new unavailable service exception.
  const TurboFirestoreUnavailableException({
    required super.message,
    super.stackTrace,
    required this.originalException,
  }) : super(code: KErrorCodes.unavailable);

  /// The original Firebase exception.
  final FirebaseException originalException;

  @override
  String toString() {
    final buffer = StringBuffer('TurboFirestoreUnavailableException: $message');
    buffer.write(' (code: $code)');
    if (path != null) {
      buffer.write(' (path: $path)');
    }
    if (query != null) {
      buffer.write(' (query: $query)');
    }
    buffer.write('\nOriginal exception: ${originalException.toString()}');
    if (stackTrace != null) {
      buffer.write('\nStack trace: $stackTrace');
    }
    return buffer.toString();
  }
}

/// Exception thrown when a document is not found.
final class TurboFirestoreNotFoundException extends TurboFirestoreException {
  /// Creates a new not found exception.
  const TurboFirestoreNotFoundException({
    required super.message,
    super.path,
    super.stackTrace,
    required this.originalException,
  }) : super(code: KErrorCodes.notFound);

  /// The original Firebase exception.
  final FirebaseException originalException;

  @override
  String toString() {
    final buffer = StringBuffer('TurboFirestoreNotFoundException: $message');
    buffer.write(' (code: $code)');
    if (path != null) {
      buffer.write(' (path: $path)');
    }
    if (query != null) {
      buffer.write(' (query: $query)');
    }
    buffer.write('\nOriginal exception: ${originalException.toString()}');
    if (stackTrace != null) {
      buffer.write('\nStack trace: $stackTrace');
    }
    return buffer.toString();
  }
}

/// Exception thrown when a document already exists.
final class TurboFirestoreAlreadyExistsException
    extends TurboFirestoreException {
  /// Creates a new already exists exception.
  const TurboFirestoreAlreadyExistsException({
    required super.message,
    super.path,
    super.stackTrace,
    required this.originalException,
  }) : super(code: KErrorCodes.alreadyExists);

  /// The original Firebase exception.
  final FirebaseException originalException;

  @override
  String toString() {
    final buffer =
        StringBuffer('TurboFirestoreAlreadyExistsException: $message');
    buffer.write(' (code: $code)');
    if (path != null) {
      buffer.write(' (path: $path)');
    }
    if (query != null) {
      buffer.write(' (query: $query)');
    }
    buffer.write('\nOriginal exception: ${originalException.toString()}');
    if (stackTrace != null) {
      buffer.write('\nStack trace: $stackTrace');
    }
    return buffer.toString();
  }
}

/// Exception thrown when an operation is cancelled.
final class TurboFirestoreCancelledException extends TurboFirestoreException {
  /// Creates a new cancelled operation exception.
  const TurboFirestoreCancelledException({
    required super.message,
    super.stackTrace,
    required this.originalException,
  }) : super(code: KErrorCodes.cancelled);

  /// The original Firebase exception.
  final FirebaseException originalException;

  @override
  String toString() {
    final buffer = StringBuffer('TurboFirestoreCancelledException: $message');
    buffer.write(' (code: $code)');
    if (path != null) {
      buffer.write(' (path: $path)');
    }
    if (query != null) {
      buffer.write(' (query: $query)');
    }
    buffer.write('\nOriginal exception: ${originalException.toString()}');
    if (stackTrace != null) {
      buffer.write('\nStack trace: $stackTrace');
    }
    return buffer.toString();
  }
}

/// Exception thrown when a deadline is exceeded.
final class TurboFirestoreDeadlineExceededException
    extends TurboFirestoreException {
  /// Creates a new deadline exceeded exception.
  const TurboFirestoreDeadlineExceededException({
    required super.message,
    super.stackTrace,
    required this.originalException,
  }) : super(code: KErrorCodes.deadlineExceeded);

  /// The original Firebase exception.
  final FirebaseException originalException;

  @override
  String toString() {
    final buffer =
        StringBuffer('TurboFirestoreDeadlineExceededException: $message');
    buffer.write(' (code: $code)');
    if (path != null) {
      buffer.write(' (path: $path)');
    }
    if (query != null) {
      buffer.write(' (query: $query)');
    }
    buffer.write('\nOriginal exception: ${originalException.toString()}');
    if (stackTrace != null) {
      buffer.write('\nStack trace: $stackTrace');
    }
    return buffer.toString();
  }
}

/// Generic Firestore exception for other error types.
final class TurboFirestoreGenericException extends TurboFirestoreException {
  /// Creates a new generic Firestore exception.
  const TurboFirestoreGenericException({
    required super.message,
    required super.code,
    super.stackTrace,
    required this.originalException,
  });

  /// The original exception.
  final Object originalException;

  @override
  String toString() {
    final buffer = StringBuffer('TurboFirestoreGenericException: $message');
    buffer.write(' (code: $code)');
    if (path != null) {
      buffer.write(' (path: $path)');
    }
    if (query != null) {
      buffer.write(' (query: $query)');
    }
    buffer.write('\nOriginal exception: ${originalException.toString()}');
    if (stackTrace != null) {
      buffer.write('\nStack trace: $stackTrace');
    }
    return buffer.toString();
  }
}
