import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:informers/informer.dart';
import 'package:loglytics/loglytics.dart';
import 'package:turbo_firestore_api/abstracts/turbo_writeable.dart';
import 'package:turbo_firestore_api/abstracts/turbo_writeable_id.dart';
import 'package:turbo_firestore_api/apis/turbo_firestore_api.dart';
import 'package:turbo_firestore_api/constants/k_values.dart';
import 'package:turbo_firestore_api/extensions/completer_extension.dart';
import 'package:turbo_firestore_api/models/turbo_auth_vars.dart';
import 'package:turbo_firestore_api/typedefs/create_doc_def.dart';
import 'package:turbo_firestore_api/typedefs/update_doc_def.dart';
import 'package:turbo_firestore_api/typedefs/upsert_doc_def.dart';
import 'package:turbo_response/turbo_response.dart';
import 'package:turbo_firestore_api/extensions/turbo_list_extension.dart';
import 'package:turbo_firestore_api/services/turbo_auth_sync_service.dart';
import 'package:turbo_firestore_api/exceptions/turbo_firestore_exception.dart';

part 'before_sync_turbo_collection_service.dart';
part 'after_sync_turbo_collection_service.dart';
part 'before_after_sync_turbo_collection_service.dart';

/// A service for managing a collection of Firestore documents with synchronized local state.
///
/// The [TurboCollectionService] provides a robust foundation for managing collections of documents
/// that need to be synchronized between Firestore and local state. It handles:
/// - Local state management with optimistic updates
/// - Remote state synchronization
/// - Batch operations
/// - Transaction support
/// - Error handling
/// - Automatic user authentication state sync
///
/// Type Parameters:
/// - [T] - The document type, must extend [TurboWriteableId<String>]
/// - [API] - The Firestore API type, must extend [TurboFirestoreApi<T>]
///
/// Example:
/// ```dart
/// class UserService extends TurboCollectionService<User, UserApi> {
///   UserService({required super.api});
///
///   Future<void> updateUserName(String userId, String newName) async {
///     final user = findById(userId);
///     final updated = user.copyWith(name: newName);
///     await updateDoc(doc: updated);
///   }
/// }
/// ```
///
/// Features:
/// - Automatic local state updates before remote operations
/// - Optimistic UI updates with rollback on failure
/// - Batch operations for multiple documents
/// - Transaction support for atomic operations
/// - Automatic stream update blocking during mutations
/// - Error handling and logging
/// - User authentication state synchronization
abstract class TurboCollectionService<T extends TurboWriteableId<String>,
        API extends TurboFirestoreApi<T>> extends TurboAuthSyncService<List<T>>
    with Loglytics {
  /// Creates a new [TurboCollectionService] instance.
  ///
  /// Parameters:
  /// - [api] - The Firestore API instance for remote operations
  TurboCollectionService({
    required this.api,
  });

  // 📍 LOCATOR ------------------------------------------------------------------------------- \\
  // 🧩 DEPENDENCIES -------------------------------------------------------------------------- \\

  /// The Firestore API instance used for remote operations.
  final API api;

  // 🎬 INIT & DISPOSE ------------------------------------------------------------------------ \\

  /// Disposes of the service by cleaning up resources.
  ///
  /// Disposes the [docsPerIdInformer] informer and completes the [_isReady] completer
  /// if not already completed. Then calls the parent dispose method.
  @override
  Future<void> dispose() {
    docsPerIdInformer.dispose();
    _isReady.completeIfNotComplete();
    return super.dispose();
  }

  // 👂 LISTENERS ----------------------------------------------------------------------------- \\
  // ⚡️ OVERRIDES ----------------------------------------------------------------------------- \\

  /// Handles data updates from the Firestore stream.
  ///
  /// Updates the local state when new data arrives from Firestore.
  /// If [user] is null, clears the local state.
  @override
  void Function(List<T>? value, User? user) get onData {
    return (value, user) {
      final docs = value ?? [];
      if (user != null) {
        log.debug('Updating docs for user ${user.uid}');
        docsPerIdInformer.update(
          docs.toIdMap((element) => element.id),
        );
        _isReady.completeIfNotComplete();
        log.debug('Updated ${docs.length} docs');
      } else {
        log.debug('User is null, clearing docs');
        docsPerIdInformer.update(
          {},
        );
      }
    };
  }

  /// Called when a stream error occurs.
  ///
  /// Override this method to handle specific Firestore error types.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// void onError(TurboFirestoreException error) {
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
  /// - [error] - The Firestore exception that occurred
  @override
  void onError(TurboFirestoreException error) {
    log.warning('Collection service stream error: $error');
    super.onError(error);
  }

  // 🎩 STATE --------------------------------------------------------------------------------- \\

  /// Local state for documents, indexed by their IDs.
  @protected
  final docsPerIdInformer = Informer<Map<String, T>>({}, forceUpdate: true);

  /// Completer that resolves when the service is ready.
  final _isReady = Completer();

  // 🛠 UTIL ---------------------------------------------------------------------------------- \\
  // 🧲 FETCHERS ------------------------------------------------------------------------------ \\

  /// Returns a new instance of [V] with basic variables filled in.
  V turboVars<V extends TurboAuthVars>({String? id}) => TurboAuthVars(
        id: id ?? api.genId,
        now: DateTime.now(),
        userId: cachedUserId ?? kValuesNoAuthId,
      ) as V;

  /// Value listenable for the document collection state.
  ValueListenable<Map<String, T>> get docsPerId => docsPerIdInformer;

  /// Whether the collection has any documents.
  bool get hasDocs => docsPerIdInformer.value.isNotEmpty;

  /// Whether a document with the given ID exists.
  bool exists(String id) => docsPerIdInformer.value.containsKey(id);

  /// Finds a document by its ID. Throws if not found.
  T findById(String id) => docsPerIdInformer.value[id]!;

  /// Finds a document by its ID. Returns null if not found.
  T? tryFindById(String? id) => docsPerIdInformer.value[id];

  /// Future that completes when the service is ready to use.
  Future get isReady => _isReady.future;

  /// Listenable for the document collection state.
  Listenable get listenable => docsPerIdInformer;

  // 🏗️ HELPERS ------------------------------------------------------------------------------- \\
  // ⚙️ LOCAL MUTATORS ------------------------------------------------------------------------ \\

  /// Forces a rebuild of the local state.
  void rebuild() => docsPerIdInformer.rebuild();

  /// Deletes a document from local state.
  ///
  /// Parameters:
  /// - [id] - The ID of the document to delete
  /// - [doNotifyListeners] - Whether to notify listeners of the change
  @protected
  void deleteLocalDoc({
    required String id,
    bool doNotifyListeners = true,
  }) {
    log.debug('Deleting local doc with id: $id');
    docsPerIdInformer.updateCurrent(
      (value) => value..remove(id),
      doNotifyListeners: doNotifyListeners,
    );
  }

  /// Deletes multiple documents from local state.
  ///
  /// Parameters:
  /// - [ids] - The IDs of the documents to delete
  /// - [doNotifyListeners] - Whether to notify listeners of the changes
  @protected
  void deleteLocalDocs({
    required List<String> ids,
    bool doNotifyListeners = true,
  }) {
    log.debug('Deleting ${ids.length} local docs');
    for (final id in ids) {
      deleteLocalDoc(id: id, doNotifyListeners: false);
    }
    if (doNotifyListeners) docsPerIdInformer.rebuild();
  }

  /// Updates an existing document in local state.
  ///
  /// Parameters:
  /// - [id] - The ID of the document to update
  /// - [doc] - The definition of how to update the document
  /// - [doNotifyListeners] - Whether to notify listeners of the change
  @protected
  T updateLocalDoc({
    required String id,
    required UpdateDocDef<T> doc,
    bool doNotifyListeners = true,
  }) {
    log.debug('Updating local doc with id: $id');
    final pDoc = doc(
      findById(id),
      turboVars(id: id),
    );
    docsPerIdInformer.updateCurrent(
      (value) => value
        ..update(
          pDoc.id,
          (_) => pDoc,
        ),
      doNotifyListeners: doNotifyListeners,
    );
    return pDoc;
  }

  /// Creates a new document in local state.
  ///
  /// Parameters:
  /// - [id] - The ID of the document to create
  /// - [doc] - The definition of how to create the document
  /// - [doNotifyListeners] - Whether to notify listeners of the change
  @protected
  T createLocalDoc({
    required CreateDocDef<T> doc,
    bool doNotifyListeners = true,
  }) {
    final pDoc = doc(
      turboVars(),
    );
    log.debug('Creating local doc with id: ${pDoc.id}');
    docsPerIdInformer.updateCurrent(
      (value) => value..[pDoc.id] = pDoc,
      doNotifyListeners: doNotifyListeners,
    );
    return pDoc;
  }

  /// Updates multiple existing documents in local state.
  ///
  /// Parameters:
  /// - [ids] - The IDs of the documents to update
  /// - [doc] - The definition of how to update the documents
  /// - [doNotifyListeners] - Whether to notify listeners of the changes
  @protected
  List<T> updateLocalDocs({
    required List<String> ids,
    required UpdateDocDef<T> doc,
    bool doNotifyListeners = true,
  }) {
    log.debug('Updating ${ids.length} local docs');
    final pDocs = <T>[];
    for (final id in ids) {
      final pDoc = updateLocalDoc(id: id, doc: doc, doNotifyListeners: false);
      pDocs.add(pDoc);
    }
    if (doNotifyListeners) docsPerIdInformer.rebuild();
    return pDocs;
  }

  /// Creates multiple new documents in local state.
  ///
  /// Parameters:
  /// - [ids] - The IDs of the documents to create
  /// - [docs] - The definition of how to create the documents
  /// - [doNotifyListeners] - Whether to notify listeners of the changes
  @protected
  List<T> createLocalDocs({
    required List<CreateDocDef<T>> docs,
    bool doNotifyListeners = true,
  }) {
    log.debug('Creating ${docs.length} local docs');
    final pDocs = <T>[];
    for (final doc in docs) {
      final pDoc = createLocalDoc(doc: doc, doNotifyListeners: false);
      pDocs.add(pDoc);
    }
    if (doNotifyListeners) docsPerIdInformer.rebuild();
    return pDocs;
  }

  /// Upserts (updates or inserts) multiple documents in local state.
  ///
  /// This method will either update existing documents or create new ones
  /// if they don't exist. The [doc] function receives each current document
  /// (or null if it doesn't exist) and should return the new document state.
  ///
  /// Parameters:
  /// - [ids] - The IDs of the documents to upsert
  /// - [doc] - The definition of how to upsert the documents
  /// - [doNotifyListeners] - Whether to notify listeners of the changes
  ///
  /// Returns the list of upserted documents
  @protected
  List<T> upsertLocalDocs({
    required List<String> ids,
    required UpsertDocDef<T> doc,
    bool doNotifyListeners = true,
  }) {
    log.debug('Upserting ${ids.length} local docs');
    final pDocs = <T>[];
    for (final id in ids) {
      final pDoc = upsertLocalDoc(
        id: id,
        doc: doc,
        doNotifyListeners: false,
      );
      pDocs.add(pDoc);
    }
    if (doNotifyListeners) docsPerIdInformer.rebuild();
    return pDocs;
  }

  /// Upserts (updates or inserts) a document in local state.
  ///
  /// This method will either update an existing document or create a new one
  /// if it doesn't exist. The [doc] function receives the current document
  /// (or null if it doesn't exist) and should return the new document state.
  ///
  /// Parameters:
  /// - [id] - The ID of the document to upsert
  /// - [doc] - The definition of how to upsert the document
  /// - [doNotifyListeners] - Whether to notify listeners of the change
  ///
  /// Returns the upserted document
  @protected
  T upsertLocalDoc({
    required String id,
    required UpsertDocDef<T> doc,
    bool doNotifyListeners = true,
  }) {
    log.debug('Upserting local doc with id: $id');
    final pDoc = doc(tryFindById(id), turboVars(id: id));
    docsPerIdInformer.updateCurrent(
      (value) => value..[pDoc.id] = pDoc,
      doNotifyListeners: doNotifyListeners,
    );
    return pDoc;
  }

  /// Upserts (updates or inserts) a document both locally and in Firestore.
  ///
  /// This method will either update an existing document or create a new one
  /// if it doesn't exist. The [doc] function receives the current document
  /// (or null if it doesn't exist) and should return the new document state.
  ///
  /// Performs an optimistic upsert by updating the local state first,
  /// then syncing with Firestore. If the remote upsert fails, the local
  /// state remains updated.
  ///
  /// Parameters:
  /// - [transaction] - Optional transaction for atomic operations
  /// - [id] - The ID of the document to upsert
  /// - [doc] - The definition of how to upsert the document
  /// - [remoteUpdateRequestBuilder] - Optional builder to modify the document before upserting
  /// - [doNotifyListeners] - Whether to notify listeners of the change
  ///
  /// Returns a [TurboResponse] with the upserted document reference
  @protected
  Future<TurboResponse<T>> upsertDoc({
    Transaction? transaction,
    required String id,
    required UpsertDocDef<T> doc,
    TurboWriteable Function(T doc)? remoteUpdateRequestBuilder,
    bool doNotifyListeners = true,
  }) async {
    try {
      log.debug('Upserting doc with id: $id');
      final pDoc = upsertLocalDoc(
        id: id,
        doc: doc,
        doNotifyListeners: doNotifyListeners,
      );
      final future = api.createDoc(
        writeable: remoteUpdateRequestBuilder?.call(pDoc) ?? pDoc,
        id: id,
        transaction: transaction,
        merge: true,
      );
      final turboResponse = await future;
      if (transaction != null) {
        turboResponse.throwWhenFail();
      }
      return turboResponse.mapSuccess((_) => pDoc);
    } catch (error, stackTrace) {
      if (transaction != null) rethrow;
      log.error(
        '$error caught while upserting doc',
        error: error,
        stackTrace: stackTrace,
      );
      return TurboResponse.fail(error: error);
    }
  }

  // 🕹️ LOCAL & REMOTE MUTATORS --------------------------------------------------------------- \\

  /// Updates a document both locally and in Firestore.
  ///
  /// Performs an optimistic update by updating the local state first,
  /// then syncing with Firestore. If the remote update fails, the local
  /// state remains updated.
  ///
  /// Parameters:
  /// - [transaction] - Optional transaction for atomic operations
  /// - [id] - The ID of the document to update
  /// - [doc] - The definition of how to update the document
  /// - [remoteUpdateRequestBuilder] - Optional builder to modify the document before updating
  /// - [doNotifyListeners] - Whether to notify listeners of the change
  ///
  /// Returns a [TurboResponse] with the updated document reference
  @protected
  Future<TurboResponse<T>> updateDoc({
    Transaction? transaction,
    required String id,
    required UpdateDocDef<T> doc,
    TurboWriteable Function(T doc)? remoteUpdateRequestBuilder,
    bool doNotifyListeners = true,
  }) async {
    try {
      log.debug('Updating doc with id: $id');
      final pDoc = updateLocalDoc(
        id: id,
        doc: doc,
        doNotifyListeners: doNotifyListeners,
      );
      final future = api.updateDoc(
        writeable: remoteUpdateRequestBuilder?.call(pDoc) ?? pDoc,
        id: id,
        transaction: transaction,
      );
      final turboResponse = await future;
      if (transaction != null) {
        turboResponse.throwWhenFail();
      }
      return turboResponse.mapSuccess((_) => pDoc);
    } catch (error, stackTrace) {
      if (transaction != null) rethrow;
      log.error(
        '$error caught while updating doc',
        error: error,
        stackTrace: stackTrace,
      );
      return TurboResponse.fail(error: error);
    }
  }

  /// Creates a new document both locally and in Firestore.
  ///
  /// Performs an optimistic create by updating the local state first,
  /// then syncing with Firestore. If the remote create fails, the local
  /// state remains updated.
  ///
  /// Parameters:
  /// - [transaction] - Optional transaction for atomic operations
  /// - [id] - The ID of the document to create
  /// - [doc] - The definition of how to create the document
  /// - [doNotifyListeners] - Whether to notify listeners of the change
  ///
  /// Returns a [TurboResponse] with the created document reference
  @protected
  Future<TurboResponse<T>> createDoc({
    Transaction? transaction,
    required CreateDocDef<T> doc,
    bool doNotifyListeners = true,
  }) async {
    try {
      final pDoc = createLocalDoc(
        doc: doc,
        doNotifyListeners: doNotifyListeners,
      );
      log.debug('Creating doc with id: ${pDoc.id}');
      final future = api.createDoc(
        writeable: pDoc,
        id: pDoc.id,
        transaction: transaction,
      );
      final turboResponse = await future;
      if (transaction != null) {
        turboResponse.throwWhenFail();
      }
      return turboResponse.mapSuccess((_) => pDoc);
    } catch (error, stackTrace) {
      if (transaction != null) rethrow;
      log.error(
        '$error caught while creating doc',
        error: error,
        stackTrace: stackTrace,
      );
      return TurboResponse.fail(error: error);
    }
  }

  /// Updates multiple documents both locally and in Firestore.
  ///
  /// Performs optimistic updates by updating the local state first,
  /// then syncing with Firestore. Uses a batch operation for multiple
  /// documents unless a transaction is provided.
  ///
  /// Parameters:
  /// - [transaction] - Optional transaction for atomic operations
  /// - [ids] - The IDs of the documents to update
  /// - [doc] - The definition of how to update the documents
  /// - [doNotifyListeners] - Whether to notify listeners of the changes
  ///
  /// Returns a [TurboResponse] indicating success or failure
  @protected
  Future<TurboResponse<List<T>>> updateDocs({
    Transaction? transaction,
    required List<String> ids,
    required UpdateDocDef<T> doc,
    bool doNotifyListeners = true,
  }) async {
    try {
      log.debug('Updating ${ids.length} docs');
      final pDocs = updateLocalDocs(
        ids: ids,
        doc: doc,
        doNotifyListeners: doNotifyListeners,
      );
      if (transaction != null) {
        for (final pDoc in pDocs) {
          (await api.updateDoc(
            id: pDoc.id,
            transaction: transaction,
            writeable: pDoc,
          ))
              .throwWhenFail();
        }
        return TurboResponse.success(result: pDocs);
      } else {
        final batch = api.writeBatch;
        for (final pDoc in pDocs) {
          await api.updateDocInBatch(
            id: pDoc.id,
            writeBatch: batch,
            writeable: pDoc,
          );
        }
        final future = batch.commit();
        await future;
        return TurboResponse.success(result: pDocs);
      }
    } catch (error, stackTrace) {
      if (transaction != null) rethrow;
      log.error(
        '${error.runtimeType} caught while updating docs',
        error: error,
        stackTrace: stackTrace,
      );
      return TurboResponse.fail(error: error);
    }
  }

  /// Creates multiple documents both locally and in Firestore.
  ///
  /// Performs optimistic creates by updating the local state first,
  /// then syncing with Firestore. Uses a batch operation for multiple
  /// documents unless a transaction is provided.
  ///
  /// Parameters:
  /// - [transaction] - Optional transaction for atomic operations
  /// - [ids] - The IDs of the documents to create
  /// - [doc] - The definition of how to create the documents
  /// - [doNotifyListeners] - Whether to notify listeners of the changes
  ///
  /// Returns a [TurboResponse] indicating success or failure
  @protected
  Future<TurboResponse<List<T>>> createDocs({
    Transaction? transaction,
    required List<CreateDocDef<T>> docs,
    bool doNotifyListeners = true,
  }) async {
    try {
      final pDocs = createLocalDocs(
        docs: docs,
        doNotifyListeners: doNotifyListeners,
      );
      log.debug('Creating ${pDocs.length} docs');
      if (transaction != null) {
        for (final pDoc in pDocs) {
          (await api.createDoc(
            id: pDoc.id,
            transaction: transaction,
            writeable: pDoc,
          ))
              .throwWhenFail();
        }
        return TurboResponse.success(result: pDocs);
      } else {
        final batch = api.writeBatch;
        for (final pDoc in pDocs) {
          await api.createDocInBatch(
            id: pDoc.id,
            writeBatch: batch,
            writeable: pDoc,
          );
        }
        final future = batch.commit();
        await future;
        return TurboResponse.success(result: pDocs);
      }
    } catch (error, stackTrace) {
      if (transaction != null) rethrow;
      log.error(
        '${error.runtimeType} caught while creating docs',
        error: error,
        stackTrace: stackTrace,
      );
      return TurboResponse.fail(error: error);
    }
  }

  /// Deletes a document both locally and from Firestore.
  ///
  /// Performs an optimistic delete by updating the local state first,
  /// then syncing with Firestore. If the remote delete fails, the local
  /// state remains updated.
  ///
  /// Parameters:
  /// - [transaction] - Optional transaction for atomic operations
  /// - [id] - The ID of the document to delete
  /// - [doNotifyListeners] - Whether to notify listeners of the change
  ///
  /// Returns a [TurboResponse] indicating success or failure
  @protected
  Future<TurboResponse> deleteDoc({
    required String id,
    bool doNotifyListeners = true,
    Transaction? transaction,
  }) async {
    try {
      log.debug('Deleting doc with id: $id');
      deleteLocalDoc(
        id: id,
        doNotifyListeners: doNotifyListeners,
      );
      final future = api.deleteDoc(
        id: id,
        transaction: transaction,
      );
      final turboResponse = await future;
      if (transaction != null) {
        turboResponse.throwWhenFail();
      }
      return turboResponse;
    } catch (error, stackTrace) {
      if (transaction != null) rethrow;
      log.error(
        '$error caught while deleting doc',
        error: error,
        stackTrace: stackTrace,
      );
      return TurboResponse.fail(error: error);
    }
  }

  /// Deletes multiple documents both locally and from Firestore.
  ///
  /// Performs optimistic deletes by updating the local state first,
  /// then syncing with Firestore. Uses a batch operation for multiple
  /// documents unless a transaction is provided.
  ///
  /// Parameters:
  /// - [transaction] - Optional transaction for atomic operations
  /// - [ids] - The IDs of the documents to delete
  /// - [doNotifyListeners] - Whether to notify listeners of the changes
  ///
  /// Returns a [TurboResponse] indicating success or failure
  @protected
  Future<TurboResponse> deleteDocs({
    Transaction? transaction,
    required List<String> ids,
    bool doNotifyListeners = true,
  }) async {
    try {
      log.debug('Deleting ${ids.length} docs');
      deleteLocalDocs(
        ids: ids,
        doNotifyListeners: doNotifyListeners,
      );
      if (transaction != null) {
        for (final id in ids) {
          (await api.deleteDoc(
            id: id,
            transaction: transaction,
          ))
              .throwWhenFail();
        }
        return TurboResponse.successAsBool();
      } else {
        final batch = api.writeBatch;
        for (final id in ids) {
          await api.deleteDocInBatch(
            id: id,
            writeBatch: batch,
          );
        }
        final future = batch.commit();
        await future;
        return TurboResponse.successAsBool();
      }
    } catch (error, stackTrace) {
      if (transaction != null) rethrow;
      log.error(
        '${error.runtimeType} caught while deleting docs',
        error: error,
        stackTrace: stackTrace,
      );
      return TurboResponse.fail(error: error);
    }
  }

  /// Upserts (updates or inserts) multiple documents both locally and in Firestore.
  ///
  /// This method will either update existing documents or create new ones
  /// if they don't exist. The [doc] function receives each current document
  /// (or null if it doesn't exist) and should return the new document state.
  ///
  /// Performs optimistic upserts by updating the local state first,
  /// then syncing with Firestore. Uses a batch operation for multiple
  /// documents unless a transaction is provided.
  ///
  /// Parameters:
  /// - [transaction] - Optional transaction for atomic operations
  /// - [ids] - The IDs of the documents to upsert
  /// - [doc] - The definition of how to upsert the documents
  /// - [doNotifyListeners] - Whether to notify listeners of the changes
  ///
  /// Returns a [TurboResponse] with the list of upserted documents
  @protected
  Future<TurboResponse<List<T>>> upsertDocs({
    Transaction? transaction,
    required List<String> ids,
    required UpsertDocDef<T> doc,
    bool doNotifyListeners = true,
  }) async {
    try {
      log.debug('Upserting ${ids.length} docs');
      final pDocs = upsertLocalDocs(
        ids: ids,
        doc: doc,
        doNotifyListeners: doNotifyListeners,
      );
      if (transaction != null) {
        for (final pDoc in pDocs) {
          (await api.createDoc(
            writeable: pDoc,
            id: pDoc.id,
            transaction: transaction,
            merge: true,
          ))
              .throwWhenFail();
        }
        return TurboResponse.success(result: pDocs);
      } else {
        final batch = api.writeBatch;
        for (final pDoc in pDocs) {
          await api.createDocInBatch(
            id: pDoc.id,
            writeBatch: batch,
            writeable: pDoc,
            merge: true,
          );
        }
        final future = batch.commit();
        await future;
        return TurboResponse.success(result: pDocs);
      }
    } catch (error, stackTrace) {
      if (transaction != null) rethrow;
      log.error(
        '${error.runtimeType} caught while upserting docs',
        error: error,
        stackTrace: stackTrace,
      );
      return TurboResponse.fail(error: error);
    }
  }

  // 🪄 MUTATORS ------------------------------------------------------------------------------ \\
}
