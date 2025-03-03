import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:turbo_firestore_api/models/sensitive_data.dart';

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
        case 'permission-denied':
          return TurboFirestorePermissionDeniedException(
            message: error.message ?? 'Permission denied',
            path: path,
            query: query,
            stackTrace: stackTrace,
            originalException: error,
          );
        case 'unavailable':
          return TurboFirestoreUnavailableException(
            message: error.message ?? 'Service unavailable',
            stackTrace: stackTrace,
            originalException: error,
          );
        case 'not-found':
          return TurboFirestoreNotFoundException(
            message: error.message ?? 'Document not found',
            path: path,
            stackTrace: stackTrace,
            originalException: error,
          );
        case 'already-exists':
          return TurboFirestoreAlreadyExistsException(
            message: error.message ?? 'Document already exists',
            path: path,
            stackTrace: stackTrace,
            originalException: error,
          );
        case 'cancelled':
          return TurboFirestoreCancelledException(
            message: error.message ?? 'Operation cancelled',
            stackTrace: stackTrace,
            originalException: error,
          );
        case 'deadline-exceeded':
          return TurboFirestoreDeadlineExceededException(
            message: error.message ?? 'Deadline exceeded',
            stackTrace: stackTrace,
            originalException: error,
          );
        default:
          return TurboFirestoreGenericException(
            message: error.message ?? 'Unknown Firestore error',
            code: error.code,
            stackTrace: stackTrace,
            originalException: error,
          );
      }
    } else {
      return TurboFirestoreGenericException(
        message: error.toString(),
        code: 'unknown',
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
final class TurboFirestorePermissionDeniedException extends TurboFirestoreException {
  /// Creates a new permission denied exception.
  const TurboFirestorePermissionDeniedException({
    required super.message,
    super.path,
    super.query,
    super.stackTrace,
    required this.originalException,
  }) : super(code: 'permission-denied');

  /// The original Firebase exception.
  final FirebaseException originalException;
}

/// Exception thrown when a Firestore service is unavailable.
final class TurboFirestoreUnavailableException extends TurboFirestoreException {
  /// Creates a new unavailable service exception.
  const TurboFirestoreUnavailableException({
    required super.message,
    super.stackTrace,
    required this.originalException,
  }) : super(code: 'unavailable');

  /// The original Firebase exception.
  final FirebaseException originalException;
}

/// Exception thrown when a document is not found.
final class TurboFirestoreNotFoundException extends TurboFirestoreException {
  /// Creates a new not found exception.
  const TurboFirestoreNotFoundException({
    required super.message,
    super.path,
    super.stackTrace,
    required this.originalException,
  }) : super(code: 'not-found');

  /// The original Firebase exception.
  final FirebaseException originalException;
}

/// Exception thrown when a document already exists.
final class TurboFirestoreAlreadyExistsException extends TurboFirestoreException {
  /// Creates a new already exists exception.
  const TurboFirestoreAlreadyExistsException({
    required super.message,
    super.path,
    super.stackTrace,
    required this.originalException,
  }) : super(code: 'already-exists');

  /// The original Firebase exception.
  final FirebaseException originalException;
}

/// Exception thrown when an operation is cancelled.
final class TurboFirestoreCancelledException extends TurboFirestoreException {
  /// Creates a new cancelled operation exception.
  const TurboFirestoreCancelledException({
    required super.message,
    super.stackTrace,
    required this.originalException,
  }) : super(code: 'cancelled');

  /// The original Firebase exception.
  final FirebaseException originalException;
}

/// Exception thrown when a deadline is exceeded.
final class TurboFirestoreDeadlineExceededException extends TurboFirestoreException {
  /// Creates a new deadline exceeded exception.
  const TurboFirestoreDeadlineExceededException({
    required super.message,
    super.stackTrace,
    required this.originalException,
  }) : super(code: 'deadline-exceeded');

  /// The original Firebase exception.
  final FirebaseException originalException;
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
}
