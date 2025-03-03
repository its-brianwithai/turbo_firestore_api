/// Constants for Firestore error codes and messages.
///
/// This file contains all error codes and default error messages used
/// throughout the Turbo Firestore API for consistent error handling.
///
/// These constants ensure consistent error handling and reporting across
/// the entire API, making it easier to maintain and update error messages
/// in a single place.
class KErrorCodes {
  // Error Codes
  /// Error code for permission denied errors.
  static const String permissionDenied = 'permission-denied';

  /// Error code for service unavailable errors.
  static const String unavailable = 'unavailable';

  /// Error code for document not found errors.
  static const String notFound = 'not-found';

  /// Error code for document already exists errors.
  static const String alreadyExists = 'already-exists';

  /// Error code for cancelled operation errors.
  static const String cancelled = 'cancelled';

  /// Error code for deadline exceeded errors.
  static const String deadlineExceeded = 'deadline-exceeded';

  /// Error code for unknown errors.
  static const String unknown = 'unknown';

  /// Error code for invalid argument errors.
  static const String invalidArgument = 'invalid-argument';

  /// Error code for failed precondition errors.
  static const String failedPrecondition = 'failed-precondition';

  /// Error code for out of range errors.
  static const String outOfRange = 'out-of-range';

  /// Error code for unauthenticated errors.
  static const String unauthenticated = 'unauthenticated';

  /// Error code for resource exhausted errors.
  static const String resourceExhausted = 'resource-exhausted';

  /// Error code for internal errors.
  static const String internal = 'internal';

  /// Error code for unimplemented errors.
  static const String unimplemented = 'unimplemented';

  /// Error code for data loss errors.
  static const String dataLoss = 'data-loss';

  // Default Error Messages
  /// Default error message for permission denied errors.
  static const String permissionDeniedMessage = 'Permission denied';

  /// Default error message for service unavailable errors.
  static const String unavailableMessage = 'Service unavailable';

  /// Default error message for document not found errors.
  static const String notFoundMessage = 'Document not found';

  /// Default error message for document already exists errors.
  static const String alreadyExistsMessage = 'Document already exists';

  /// Default error message for cancelled operation errors.
  static const String cancelledMessage = 'Operation cancelled';

  /// Default error message for deadline exceeded errors.
  static const String deadlineExceededMessage = 'Deadline exceeded';

  /// Default error message for unknown errors.
  static const String unknownMessage = 'Unknown Firestore error';

  /// Default error message for invalid argument errors.
  static const String invalidArgumentMessage = 'Invalid argument';

  /// Default error message for failed precondition errors.
  static const String failedPreconditionMessage = 'Failed precondition';

  /// Default error message for out of range errors.
  static const String outOfRangeMessage = 'Value out of range';

  /// Default error message for unauthenticated errors.
  static const String unauthenticatedMessage = 'User is not authenticated';

  /// Default error message for resource exhausted errors.
  static const String resourceExhaustedMessage = 'Resource has been exhausted';

  /// Default error message for internal errors.
  static const String internalMessage = 'Internal error';

  /// Default error message for unimplemented errors.
  static const String unimplementedMessage = 'Operation not implemented';

  /// Default error message for data loss errors.
  static const String dataLossMessage = 'Unrecoverable data loss or corruption';

  // Common Error Prefixes
  /// Prefix for error messages related to streaming.
  static const String streamErrorPrefix = 'Stream error: ';

  /// Prefix for error messages related to document operations.
  static const String documentErrorPrefix = 'Document error: ';

  /// Prefix for error messages related to collection operations.
  static const String collectionErrorPrefix = 'Collection error: ';

  /// Prefix for error messages related to query operations.
  static const String queryErrorPrefix = 'Query error: ';

  /// Prefix for error messages related to batch operations.
  static const String batchOperationErrorPrefix = 'Batch operation error: ';

  /// Prefix for error messages related to transaction operations.
  static const String transactionErrorPrefix = 'Transaction error: ';
}
