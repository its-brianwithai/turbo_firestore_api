# Implementation Plan for TurboFirestoreException in CRUD Operations (1/1)

Based on the initial request to implement `TurboFirestoreException` for streaming operations, I'll now extend this implementation to also cover CRUD (Create, Read, Update, Delete) operations throughout the package.

## Overview

1. Update the CRUD operation extensions to convert errors to `TurboFirestoreException`
2. Add exception handling to batch and transaction operations
3. Ensure proper context information is captured for each operation type
4. Update service methods to propagate the typed exceptions

## Part 1: Update Create API Extension

Let's modify the create operations in `turbo_firestore_create_api.dart`:

```dart
part of 'turbo_firestore_api.dart';

/// Extension that adds create operations to [TurboFirestoreApi]
extension TurboFirestoreCreateApi<T> on TurboFirestoreApi {
  // Existing code...

  /// Creates or writes a document to Firestore.
  Future<TurboResponse<DocumentReference>> createDoc({
    required TurboWriteable writeable,
    String? id,
    WriteBatch? writeBatch,
    TurboTimestampType createTimeStampType =
        TurboTimestampType.createdAtAndUpdatedAt,
    TurboTimestampType updateTimeStampType = TurboTimestampType.updatedAt,
    bool merge = false,
    List<FieldPath>? mergeFields,
    String? collectionPathOverride,
    Transaction? transaction,
  }) async {
    assert(
      _isCollectionGroup == (collectionPathOverride != null),
      'Firestore does not support finding a document by id when communicating with a collection group, '
      'therefore, you must specify the collectionPathOverride containing all parent collection and document ids '
      'in order to make this method work.',
    );
    try {
      // Existing validation and operation code...
    } catch (error, stackTrace) {
      if (transaction != null) {
        // Wrap and rethrow for transactions
        throw TurboFirestoreException.fromFirestoreException(
          error, 
          stackTrace, 
          path: collectionPathOverride ?? _collectionPath(),
          query: 'createDoc(id: $id, merge: $merge)',
        );
      }
      
      _log.error(
        message: 'Unable to create document',
        sensitiveData: SensitiveData(
          path: collectionPathOverride ?? _collectionPath(),
          id: id,
          isBatch: writeBatch != null,
          createTimeStampType: createTimeStampType,
          updateTimeStampType: updateTimeStampType,
          isMerge: merge,
          mergeFields: mergeFields,
          isTransaction: false,
        ),
        error: error,
        stackTrace: stackTrace,
      );
      
      // Convert to TurboFirestoreException and wrap in TurboResponse
      final exception = TurboFirestoreException.fromFirestoreException(
        error, 
        stackTrace,
        path: collectionPathOverride ?? _collectionPath(),
        query: 'createDoc(id: $id, merge: $merge)',
      );
      
      return TurboResponse.fail(error: exception);
    }
  }

  /// Creates or writes documents using a batch operation.
  Future<TurboResponse<WriteBatchWithReference<Map<String, dynamic>>>>
      createDocInBatch({
    required TurboWriteable writeable,
    String? id,
    WriteBatch? writeBatch,
    TurboTimestampType createTimeStampType =
        TurboTimestampType.createdAtAndUpdatedAt,
    TurboTimestampType updateTimeStampType = TurboTimestampType.updatedAt,
    bool merge = false,
    List<FieldPath>? mergeFields,
    String? collectionPathOverride,
  }) async {
    // Existing assertion code...
    
    try {
      // Existing operation code...
    } catch (error, stackTrace) {
      _log.error(
        message: 'Unable to create document with batch',
        sensitiveData: SensitiveData(
          path: collectionPathOverride ?? _collectionPath(),
          id: id,
          isBatch: writeBatch != null,
          createTimeStampType: createTimeStampType,
          updateTimeStampType: updateTimeStampType,
          isMerge: merge,
          mergeFields: mergeFields,
        ),
        error: error,
        stackTrace: stackTrace,
      );
      
      // Convert to TurboFirestoreException and wrap in TurboResponse
      final exception = TurboFirestoreException.fromFirestoreException(
        error, 
        stackTrace,
        path: collectionPathOverride ?? _collectionPath(),
        query: 'createDocInBatch(id: $id, merge: $merge)',
      );
      
      return TurboResponse.fail(error: exception);
    }
  }
}
```

## Part 2: Update Read API Extension

Modify the read/get operations in `turbo_firestore_get_api.dart`:

```dart
part of 'turbo_firestore_api.dart';

/// Extension that adds read/get operations to [TurboFirestoreApi]
extension TurboFirestoreGetApi<T> on TurboFirestoreApi<T> {
  // Existing code...

  /// Retrieves a document by its unique identifier
  Future<TurboResponse<Map<String, dynamic>>> getById({
    required String id,
    String? collectionPathOverride,
  }) async {
    // Existing assertion code...
    
    try {
      // Existing operation code...
    } catch (error, stackTrace) {
      _log.error(
        message: 'Unable to find document',
        sensitiveData: SensitiveData(
          path: collectionPathOverride ?? _collectionPath(),
          id: id,
        ),
        error: error,
        stackTrace: stackTrace,
      );
      
      // Convert to TurboFirestoreException and wrap in TurboResponse
      final exception = TurboFirestoreException.fromFirestoreException(
        error, 
        stackTrace,
        path: collectionPathOverride ?? _collectionPath(),
        query: 'getById(id: $id)',
      );
      
      return TurboResponse.fail(error: exception);
    }
  }

  /// Retrieves and converts a document by its unique identifier
  Future<TurboResponse<T>> getByIdWithConverter({
    required String id,
    String? collectionPathOverride,
  }) async {
    // Existing assertion code...
    
    try {
      // Existing operation code...
    } catch (error, stackTrace) {
      _log.error(
        message: 'Unable to find document',
        error: error,
        stackTrace: stackTrace,
        sensitiveData: SensitiveData(
          path: collectionPathOverride ?? _collectionPath(),
          id: id,
        ),
      );
      
      // Convert to TurboFirestoreException and wrap in TurboResponse
      final exception = TurboFirestoreException.fromFirestoreException(
        error, 
        stackTrace,
        path: collectionPathOverride ?? _collectionPath(),
        query: 'getByIdWithConverter(id: $id)',
      );
      
      return TurboResponse.fail(error: exception);
    }
  }

  // Apply similar changes to other get methods in this extension...
}
```

## Part 3: Update List API Extension

Modify the list operations in `turbo_firestore_list_api.dart`:

```dart
part of 'turbo_firestore_api.dart';

/// Extension that adds list operations to [TurboFirestoreApi]
extension TurboFirestoreListApi<T> on TurboFirestoreApi<T> {
  // Existing code...

  /// Lists documents matching a custom query
  Future<TurboResponse<List<Map<String, dynamic>>>> listByQuery({
    required CollectionReferenceDef<Map<String, dynamic>>
        collectionReferenceQuery,
    required String whereDescription,
  }) async {
    try {
      // Existing operation code...
    } catch (error, stackTrace) {
      _log.error(
        message: 'Unable to find documents with custom query',
        sensitiveData: SensitiveData(
          path: _collectionPath(),
          whereDescription: whereDescription,
        ),
        error: error,
        stackTrace: stackTrace,
      );
      
      // Convert to TurboFirestoreException and wrap in TurboResponse
      final exception = TurboFirestoreException.fromFirestoreException(
        error, 
        stackTrace,
        path: _collectionPath(),
        query: whereDescription,
      );
      
      return TurboResponse.fail(error: exception);
    }
  }

  /// Lists and converts documents matching a custom query
  Future<TurboResponse<List<T>>> listByQueryWithConverter({
    required CollectionReferenceDef<T> collectionReferenceQuery,
    required String whereDescription,
  }) async {
    try {
      // Existing operation code...
    } catch (error, stackTrace) {
      _log.error(
        message: 'Unable to find documents with custom query',
        sensitiveData: SensitiveData(
          path: _collectionPath(),
          whereDescription: whereDescription,
        ),
        error: error,
        stackTrace: stackTrace,
      );
      
      // Convert to TurboFirestoreException and wrap in TurboResponse
      final exception = TurboFirestoreException.fromFirestoreException(
        error, 
        stackTrace,
        path: _collectionPath(),
        query: whereDescription,
      );
      
      return TurboResponse.fail(error: exception);
    }
  }

  // Apply similar changes to other list methods in this extension...
}
```

## Part 4: Update Update API Extension

Modify the update operations in `turbo_firestore_update_api.dart`:

```dart
part of 'turbo_firestore_api.dart';

/// Extension that adds update operations to [TurboFirestoreApi]
extension TurboFirestoreUpdateApi<T> on TurboFirestoreApi<T> {
  // Existing code...

  /// Updates an existing document in Firestore
  Future<TurboResponse<DocumentReference>> updateDoc({
    required TurboWriteable writeable,
    required String id,
    WriteBatch? writeBatch,
    TurboTimestampType timestampType = TurboTimestampType.updatedAt,
    String? collectionPathOverride,
    Transaction? transaction,
  }) async {
    // Existing assertion code...
    
    try {
      // Existing operation code...
    } catch (error, stackTrace) {
      if (transaction != null) {
        // Wrap and rethrow for transactions
        throw TurboFirestoreException.fromFirestoreException(
          error, 
          stackTrace, 
          path: collectionPathOverride ?? _collectionPath(),
          query: 'updateDoc(id: $id)',
        );
      }
      
      _log.error(
        message: 'Unable to update document',
        sensitiveData: SensitiveData(
          path: collectionPathOverride ?? _collectionPath(),
          id: id,
          isBatch: writeBatch != null,
          updateTimeStampType: timestampType,
        ),
        error: error,
        stackTrace: stackTrace,
      );
      
      // Convert to TurboFirestoreException and wrap in TurboResponse
      final exception = TurboFirestoreException.fromFirestoreException(
        error, 
        stackTrace,
        path: collectionPathOverride ?? _collectionPath(),
        query: 'updateDoc(id: $id)',
      );
      
      return TurboResponse.fail(error: exception);
    }
  }

  /// Updates documents using a batch operation
  Future<TurboResponse<WriteBatchWithReference<Map<String, dynamic>>>>
      updateDocInBatch({
    required TurboWriteable writeable,
    required String id,
    WriteBatch? writeBatch,
    TurboTimestampType timestampType = TurboTimestampType.updatedAt,
    String? collectionPathOverride,
  }) async {
    // Existing assertion code...
    
    final TurboResponse<WriteBatchWithReference<Map<String, dynamic>>>?
        invalidResponse = writeable.validate();
    if (invalidResponse != null && invalidResponse.isFail) {
      _log.warning(
        message: 'TurboWriteable was invalid!',
        sensitiveData: null,
      );
      return invalidResponse;
    }
    
    try {
      // Existing operation code...
    } catch (error, stackTrace) {
      _log.error(
        message: 'Unable to update document with batch',
        sensitiveData: SensitiveData(
          path: collectionPathOverride ?? _collectionPath(),
          id: id,
        ),
        error: error,
        stackTrace: stackTrace,
      );
      
      // Convert to TurboFirestoreException and wrap in TurboResponse
      final exception = TurboFirestoreException.fromFirestoreException(
        error, 
        stackTrace,
        path: collectionPathOverride ?? _collectionPath(),
        query: 'updateDocInBatch(id: $id)',
      );
      
      return TurboResponse.fail(error: exception);
    }
  }
}
```

## Part 5: Update Delete API Extension

Modify the delete operations in `turbo_firestore_delete_api.dart`:

```dart
part of 'turbo_firestore_api.dart';

/// Extension that adds delete operations to [TurboFirestoreApi]
extension TurboFirestoreDeleteApi<T> on TurboFirestoreApi<T> {
  // Existing code...

  /// Deletes a document from Firestore
  Future<TurboResponse> deleteDoc({
    required String id,
    WriteBatch? writeBatch,
    String? collectionPathOverride,
    Transaction? transaction,
  }) async {
    // Existing assertion code...
    
    try {
      // Existing operation code...
    } catch (error, stackTrace) {
      if (transaction != null) {
        // Wrap and rethrow for transactions
        throw TurboFirestoreException.fromFirestoreException(
          error, 
          stackTrace, 
          path: collectionPathOverride ?? _collectionPath(),
          query: 'deleteDoc(id: $id)',
        );
      }
      
      _log.error(
          message: 'Unable to delete document',
          sensitiveData: SensitiveData(
            path: collectionPathOverride ?? _collectionPath(),
            id: id,
          ),
          error: error,
          stackTrace: stackTrace);
      
      // Convert to TurboFirestoreException and wrap in TurboResponse
      final exception = TurboFirestoreException.fromFirestoreException(
        error, 
        stackTrace,
        path: collectionPathOverride ?? _collectionPath(),
        query: 'deleteDoc(id: $id)',
      );
      
      return TurboResponse.fail(
          error: exception, 
          title: 'Error', 
          message: 'Failed to delete document');
    }
  }

  /// Deletes documents using a batch operation
  Future<TurboResponse<WriteBatchWithReference<Map<String, dynamic>>>>
      deleteDocInBatch({
    required String id,
    WriteBatch? writeBatch,
    String? collectionPathOverride,
  }) async {
    // Existing assertion code...
    
    try {
      // Existing operation code...
    } catch (error, stackTrace) {
      _log.error(
        message: 'Unable to delete document with batch',
        sensitiveData: SensitiveData(
          path: collectionPathOverride ?? _collectionPath(),
          id: id,
        ),
        error: error,
        stackTrace: stackTrace,
      );
      
      // Convert to TurboFirestoreException and wrap in TurboResponse
      final exception = TurboFirestoreException.fromFirestoreException(
        error, 
        stackTrace,
        path: collectionPathOverride ?? _collectionPath(),
        query: 'deleteDocInBatch(id: $id)',
      );
      
      return TurboResponse.fail(error: exception);
    }
  }
}
```

## Part 6: Update Search API Extension

Modify the search operations in `turbo_firestore_search_api.dart`:

```dart
part of 'turbo_firestore_api.dart';

/// Extension that adds search operations to [TurboFirestoreApi]
extension TurboFirestoreSearchApi<T> on TurboFirestoreApi<T> {
  // Existing code...

  /// Searches for documents matching a search term
  Future<TurboResponse<List<Map<String, dynamic>>>> listBySearchTerm({
    required String searchTerm,
    required String searchField,
    required TurboSearchTermType searchTermType,
    bool doSearchNumberEquivalent = false,
    int? limit,
  }) async {
    try {
      // Existing operation code...
    } catch (error, stackTrace) {
      _log.error(
        message: 'Unable to find documents',
        sensitiveData: SensitiveData(
          path: _collectionPath(),
          searchTerm: searchTerm,
          searchField: searchField,
          searchTermType: searchTermType,
        ),
        error: error,
        stackTrace: stackTrace,
      );
      
      // Convert to TurboFirestoreException and wrap in TurboResponse
      final exception = TurboFirestoreException.fromFirestoreException(
        error, 
        stackTrace,
        path: _collectionPath(),
        query: 'listBySearchTerm(searchTerm: $searchTerm, searchField: $searchField, searchTermType: $searchTermType)',
      );
      
      return TurboResponse.fail(error: exception);
    }
  }

  /// Searches for documents with type conversion
  Future<TurboResponse<List<T>>> listBySearchTermWithConverter({
    required String searchTerm,
    required String searchField,
    required TurboSearchTermType searchTermType,
    bool doSearchNumberEquivalent = false,
    int? limit,
  }) async {
    try {
      // Existing operation code...
    } catch (error, stackTrace) {
      _log.error(
          message: 'Unable to find documents',
          sensitiveData: SensitiveData(
            path: _collectionPath(),
            searchTerm: searchTerm,
            searchField: searchField,
            searchTermType: searchTermType,
          ),
          error: error,
          stackTrace: stackTrace);
      
      // Convert to TurboFirestoreException and wrap in TurboResponse
      final exception = TurboFirestoreException.fromFirestoreException(
        error, 
        stackTrace,
        path: _collectionPath(),
        query: 'listBySearchTermWithConverter(searchTerm: $searchTerm, searchField: $searchField, searchTermType: $searchTermType)',
      );
      
      return TurboResponse.fail(error: exception);
    }
  }
}
```

## Part 7: Update Transaction Handling in TurboFirestoreApi

Modify the transaction handling in the main `TurboFirestoreApi` class:

```dart
class TurboFirestoreApi<T> {
  // Existing code...

  /// Helper method to run a [Transaction] from [_firebaseFirestore].
  Future<E> runTransaction<E>(
      TransactionHandler<E> transactionHandler, {
        Duration timeout = const Duration(seconds: 30),
        int maxAttempts = 5,
      }) {
    return _firebaseFirestore.runTransaction(
      (transaction) {
        try {
          return transactionHandler(transaction);
        } catch (error, stackTrace) {
          // If error is already a TurboFirestoreException, rethrow it
          if (error is TurboFirestoreException) {
            throw error;
          }
          
          // Convert error to TurboFirestoreException
          throw TurboFirestoreException.fromFirestoreException(
            error, 
            stackTrace,
            path: _collectionPath(),
            query: 'Transaction operation',
          );
        }
      },
      timeout: timeout,
      maxAttempts: maxAttempts,
    ).catchError((error, stackTrace) {
      // If error is already a TurboFirestoreException, rethrow it
      if (error is TurboFirestoreException) {
        throw error;
      }
      
      // Convert error to TurboFirestoreException
      throw TurboFirestoreException.fromFirestoreException(
        error, 
        stackTrace,
        path: _collectionPath(),
        query: 'Transaction operation',
      );
    });
  }
}
```

## Part 8: Update Service Classes to Propagate Typed Exceptions

Modify the service classes to properly handle and propagate the typed exceptions:

1. First, update `TurboDocumentService` to handle Firestore exceptions:

```dart
// Update in lib/services/turbo_document_service.dart

abstract class TurboDocumentService<T extends TurboWriteableId<String>,
API extends TurboFirestoreApi<T>> extends TurboAuthSyncService<T?>
    with Loglytics {
  // Existing code...
  
  /// Deletes a document both locally and from Firestore.
  @protected
  Future<TurboResponse> deleteDoc({
    required String id,
    bool doNotifyListeners = true,
    Transaction? transaction,
  }) async {
    try {
      // Existing operation code...
    } catch (error, stackTrace) {
      if (transaction != null) rethrow;
      log.error(
        '$error caught while deleting doc',
        error: error,
        stackTrace: stackTrace,
      );
      
      // If error is already a TurboFirestoreException, use it
      final exception = error is TurboFirestoreException
          ? error
          : TurboFirestoreException.fromFirestoreException(
              error, 
              stackTrace,
              path: api._collectionPath(),
              query: 'deleteDoc(id: $id)',
            );
      
      // Call onError
      onError(exception);
      
      return TurboResponse.fail(error: exception);
    }
  }

  // Apply similar changes to other CRUD methods in this class...
}
```

2. Next, update `TurboCollectionService` to handle Firestore exceptions:

```dart
// Update in lib/services/turbo_collection_service.dart

abstract class TurboCollectionService<T extends TurboWriteableId<String>,
        API extends TurboFirestoreApi<T>> extends TurboAuthSyncService<List<T>>
    with Loglytics {
  // Existing code...
  
  /// Updates a document both locally and in Firestore.
  @protected
  Future<TurboResponse<T>> updateDoc({
    Transaction? transaction,
    required String id,
    required UpdateDocDef<T> doc,
    TurboWriteable Function(T doc)? remoteUpdateRequestBuilder,
    bool doNotifyListeners = true,
  }) async {
    try {
      // Existing operation code...
    } catch (error, stackTrace) {
      if (transaction != null) rethrow;
      log.error(
        '$error caught while updating doc',
        error: error,
        stackTrace: stackTrace,
      );
      
      // If error is already a TurboFirestoreException, use it
      final exception = error is TurboFirestoreException
          ? error
          : TurboFirestoreException.fromFirestoreException(
              error, 
              stackTrace,
              path: api._collectionPath(),
              query: 'updateDoc(id: $id)',
            );
      
      // Call onError
      onError(exception);
      
      return TurboResponse.fail(error: exception);
    }
  }

  // Apply similar changes to other CRUD methods in this class...
}
```

## Part 9: Update Error Handling in Documentation

Update the documentation example in an existing documentation file or README to show error handling with the new exception types for CRUD operations:

```markdown
## 🛡️ Error Handling

Turbo Firestore API provides comprehensive error handling through `TurboFirestoreException`, making it easy to handle different types of Firestore errors with both streaming and CRUD operations:

### Stream Error Handling

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
    }
  }
}
```

### CRUD Operation Error Handling

```dart
// Create a new user with error handling
final response = await usersService.createUser(name: 'John', age: 30);
response.when(
  success: (user) {
    print('User created: ${user.name}');
  },
  fail: (error) {
    if (error is TurboFirestorePermissionDeniedException) {
      print('Permission denied: ${error.message}');
      print('Path: ${error.path}');
    } else if (error is TurboFirestoreAlreadyExistsException) {
      print('User already exists: ${error.message}');
    } else if (error is TurboFirestoreException) {
      print('Firestore error: ${error.message} (${error.code})');
    } else {
      print('Unknown error: $error');
    }
  },
);
```

### Transaction Error Handling

```dart
try {
  await api.runTransaction((transaction) async {
    // Perform transaction operations
    await service.updateUserInTransaction(
      transaction: transaction,
      userId: 'user-123',
      name: 'Updated Name',
    );
    return true;
  });
  print('Transaction completed successfully');
} catch (error) {
  if (error is TurboFirestorePermissionDeniedException) {
    print('Permission denied: ${error.message}');
  } else if (error is TurboFirestoreException) {
    print('Firestore error: ${error.message} (${error.code})');
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

This implementation plan extends the `TurboFirestoreException` handling to all CRUD operations in the Turbo Firestore API, ensuring consistent error handling throughout the package. 

The implementation:
1. Catches and converts Firestore errors to typed `TurboFirestoreException` instances
2. Provides relevant context information for each error
3. Propagates errors correctly in transactions
4. Updates service classes to handle and expose the typed exceptions
5. Documents the error handling capabilities

By implementing these changes, developers will have a consistent and type-safe way to handle Firestore errors throughout all operations, improving error handling, debugging, and user experience in their applications.
