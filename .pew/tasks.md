# Implementation Plan for TurboFirestoreException in Streaming

After reviewing the codebase, I'll create an implementation plan to add a `TurboFirestoreException` sealed class for handling Firestore stream errors and add error handling mechanisms to streaming classes.

This plan can be executed in a single part as the implementation involves focused changes to specific areas of the codebase.

## Overview

1. Create a `TurboFirestoreException` sealed class hierarchy
2. Modify streaming APIs to catch Firestore errors and convert them to `TurboFirestoreException`
3. Add `onError` methods to streaming service classes
4. Update documentation and examples

## Part 1: Create TurboFirestoreException Class Hierarchy

Let's create a sealed class called `TurboFirestoreException` with implementations for different Firestore error types:

```dart
// lib/exceptions/turbo_firestore_exception.dart

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
```

## Part 2: Update Streaming APIs to Use TurboFirestoreException

Next, let's modify the streaming API extension in `turbo_firestore_stream_api.dart` to catch Firestore errors and convert them to our new exception type:

```dart
// Modify lib/apis/turbo_firestore_stream_api.dart

part of 'turbo_firestore_api.dart';

extension TurboFirestoreStreamApi<T> on TurboFirestoreApi<T> {
  // Existing methods...
  
  /// Streams all documents from a collection with exception handling
  ///
  /// Returns real-time updates for all documents with error conversion
  /// Provides raw Firestore data without conversion
  ///
  /// Returns [Stream] of [QuerySnapshot] containing:
  /// - Document data
  /// - Document metadata
  /// - Document changes
  /// Errors are caught and transformed to [TurboFirestoreException]
  ///
  /// Example:
  /// ```dart
  /// final stream = api.streamAll();
  /// stream.listen(
  ///   (snapshot) {
  ///     for (var doc in snapshot.docs) {
  ///       print('User data: ${doc.data()}');
  ///     }
  ///   },
  ///   onError: (error) {
  ///     if (error is TurboFirestorePermissionDeniedException) {
  ///       print('Permission denied: ${error.message}');
  ///     }
  ///   }
  /// );
  /// ```
  Stream<QuerySnapshot<Map<String, dynamic>>> streamAll() {
    final path = _collectionPath();
    _log.debug(
      message: 'Finding stream..',
      sensitiveData: SensitiveData(
        path: path,
      ),
    );
    return listCollectionReference().snapshots().handleError(
      (error, stackTrace) {
        _log.error(
          message: 'Error streaming collection',
          sensitiveData: SensitiveData(
            path: path,
          ),
          error: error,
          stackTrace: stackTrace,
        );
        throw TurboFirestoreException.fromFirestoreException(
          error,
          stackTrace,
          path: path,
        );
      },
    );
  }
  
  // Update all other streaming methods similarly
  Stream<List<T>> streamAllWithConverter() {
    final path = _collectionPath();
    _log.debug(
      message: 'Finding stream with converter..',
      sensitiveData: SensitiveData(
        path: path,
      ),
    );
    return listCollectionReferenceWithConverter().snapshots().map(
          (event) => event.docs.map((e) => e.data()).toList(),
        ).handleError(
      (error, stackTrace) {
        _log.error(
          message: 'Error streaming collection with converter',
          sensitiveData: SensitiveData(
            path: path,
          ),
          error: error,
          stackTrace: stackTrace,
        );
        throw TurboFirestoreException.fromFirestoreException(
          error,
          stackTrace,
          path: path,
        );
      },
    );
  }
  
  Stream<List<Map<String, dynamic>>> streamByQuery({
    required CollectionReferenceDef<Map<String, dynamic>>?
        collectionReferenceQuery,
    required String whereDescription,
  }) {
    final path = _collectionPath();
    _log.debug(
      message: 'Finding stream by query..',
      sensitiveData: SensitiveData(
        path: path,
        whereDescription: whereDescription,
      ),
    );
    final query = collectionReferenceQuery?.call(listCollectionReference()) ??
        listCollectionReference();
    return query.snapshots().map(
          (event) => event.docs.map((e) => e.data()).toList(),
        ).handleError(
      (error, stackTrace) {
        _log.error(
          message: 'Error streaming collection by query',
          sensitiveData: SensitiveData(
            path: path,
            whereDescription: whereDescription,
          ),
          error: error,
          stackTrace: stackTrace,
        );
        throw TurboFirestoreException.fromFirestoreException(
          error,
          stackTrace,
          path: path,
          query: whereDescription,
        );
      },
    );
  }
  
  // Update other streaming methods similarly...
}
```

## Part 3: Add onError Handler to TurboAuthSyncService

Let's modify the `TurboAuthSyncService` class to include an `onError` callback:

```dart
// Update lib/services/turbo_auth_sync_service.dart

class TurboAuthSyncService<StreamValue> with TurboExceptionHandler {
  /// Creates a new [TurboAuthSyncService] instance.
  ///
  /// Parameters:
  /// - [initialiseStream] - Whether to start the stream immediately
  TurboAuthSyncService({
    bool initialiseStream = true,
  }) {
    if (initialiseStream) {
      tryInitialiseStream();
    }
  }
  
  // Existing methods and fields...
  
  /// Called when a stream error occurs.
  ///
  /// Override this method to handle specific error types.
  /// Parameters:
  /// - [error] - The error that occurred, typically a [TurboFirestoreException]
  void onError(Object error) {
    // Default implementation logs the error
    _log.warning('Stream error occurred (onError not overridden): $error');
  }
  
  /// Initializes the authentication state stream and data synchronization.
  ///
  /// Sets up listeners for user authentication changes and manages the data stream.
  Future<void> tryInitialiseStream() async {
    _log.info('Initialising TurboAuthSyncService stream..');
    try {
      _userSubscription ??= FirebaseAuth.instance.userChanges().listen(
        (user) async {
          final userId = user?.uid;
          if (userId != null) {
            this.cachedUserId = userId;
            await onAuth?.call(user!);
            _subscription ??= (await stream(user!)).listen(
              (value) {
                onData(value, user);
              },
              onError: (error, stackTrace) {
                _log.error(
                  'Stream error occurred inside of stream!',
                  error: error,
                  stackTrace: stackTrace,
                );
                
                // Convert error to TurboFirestoreException if needed
                final exception = error is TurboFirestoreException
                    ? error
                    : TurboFirestoreException.fromFirestoreException(
                        error,
                        stackTrace,
                      );
                
                // Call onError handler
                onError(exception);
                
                _tryRetry();
              },
              onDone: () => onDone(_nrOfRetry, _maxNrOfRetry),
            );
          } else {
            cachedUserId = null;
            await _subscription?.cancel();
            _subscription = null;
            onData(null, null);
          }
        },
      );
    } catch (error, stack) {
      _log.error('Stream error occurred while setting up stream!',
          error: error, stackTrace: stack);
      
      // Convert error to TurboFirestoreException if needed
      final exception = error is TurboFirestoreException
          ? error
          : TurboFirestoreException.fromFirestoreException(
              error,
              stack,
            );
      
      // Call onError handler
      onError(exception);
      
      _tryRetry();
    }
  }
  
  // Existing methods...
}
```

## Part 4: Update Derived Service Classes

Update `TurboDocumentService` and `TurboCollectionService` classes to inherit the `onError` method and provide better documentation:

```dart
// Update in lib/services/turbo_document_service.dart

abstract class TurboDocumentService<T extends TurboWriteableId<String>,
API extends TurboFirestoreApi<T>> extends TurboAuthSyncService<T?>
    with Loglytics {
  // Existing code...
  
  /// Called when a stream error occurs.
  ///
  /// Override this method to handle specific Firestore error types.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// void onError(Object error) {
  ///   if (error is TurboFirestorePermissionDeniedException) {
  ///     // Handle permission errors
  ///     showPermissionErrorDialog();
  ///   } else {
  ///     // Handle other errors
  ///     showGenericErrorMessage();
  ///   }
  /// }
  /// ```
  ///
  /// Parameters:
  /// - [error] - The error that occurred, typically a [TurboFirestoreException]
  @override
  void onError(Object error) {
    log.warning('Document service stream error: $error');
    super.onError(error);
  }
  
  // Existing code...
}
```

Similarly, update the `TurboCollectionService` class:

```dart
// Update in lib/services/turbo_collection_service.dart

abstract class TurboCollectionService<T extends TurboWriteableId<String>,
        API extends TurboFirestoreApi<T>> extends TurboAuthSyncService<List<T>>
    with Loglytics {
  // Existing code...
  
  /// Called when a stream error occurs.
  ///
  /// Override this method to handle specific Firestore error types.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// void onError(Object error) {
  ///   if (error is TurboFirestorePermissionDeniedException) {
  ///     // Handle permission errors
  ///     showPermissionErrorDialog();
  ///   } else if (error is TurboFirestoreUnavailableException) {
  ///     // Handle service unavailability
  ///     showOfflineMessage();
  ///   } else {
  ///     // Handle other errors
  ///     showGenericErrorMessage();
  ///   }
  /// }
  /// ```
  ///
  /// Parameters:
  /// - [error] - The error that occurred, typically a [TurboFirestoreException]
  @override
  void onError(Object error) {
    log.warning('Collection service stream error: $error');
    super.onError(error);
  }
  
  // Existing code...
}
```

## Part 5: Export the Exception Class in Library

Update the main library file to export our new exception class:

```dart
// Update lib/turbo_firestore_api.dart

// Existing exports...

/// Exception types for error handling
export 'exceptions/turbo_firestore_exception.dart';
export 'exceptions/invalid_json_exception.dart';

// Existing exports...
```

## Part 6: Document Usage in README.md

Add documentation on using the new exception handling in the README.md:

```markdown
## 🛡️ Error Handling

Turbo Firestore API provides comprehensive error handling through `TurboFirestoreException`, making it easy to handle different types of Firestore errors:

```dart
class UsersService extends TurboCollectionService<User, UsersApi> {
  UsersService({required super.api});

  /// Handle different types of stream errors
  @override
  void onError(Object error) {
    if (error is TurboFirestorePermissionDeniedException) {
      print('Permission denied: ${error.message}');
      print('Path: ${error.path}');
      print('Query: ${error.query}');
    } else if (error is TurboFirestoreUnavailableException) {
      print('Service unavailable: ${error.message}');
    } else if (error is TurboFirestoreException) {
      print('Firestore error: ${error.message} (${error.code})');
    } else {
      print('Unknown error: $error');
    }
  }
}
```

The `TurboFirestoreException` class hierarchy includes:
- `TurboFirestorePermissionDeniedException`: Access denied to documents
- `TurboFirestoreUnavailableException`: Service temporarily unavailable
- `TurboFirestoreNotFoundException`: Document not found
- `TurboFirestoreAlreadyExistsException`: Document already exists
- `TurboFirestoreCancelledException`: Operation cancelled
- `TurboFirestoreDeadlineExceededException`: Operation took too long
- `TurboFirestoreGenericException`: Other Firestore errors
```

## Conclusion

This implementation plan introduces a comprehensive exception handling system for Firestore streams:

1. A sealed class hierarchy for different Firestore error types
2. Exception capture and conversion in streaming APIs
3. Error handling callbacks in service classes
4. Documentation and examples

By implementing these changes, developers will have better error handling capabilities with context-rich exceptions and the ability to provide custom error handling logic in their services.
