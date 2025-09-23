part of 'turbo_document_service.dart';

/// A document service that allows notification before synchronizing data.
///
/// Extends [TurboDocumentService] to provide a hook for notifying before
/// the local state is updated with new data from Firestore.
///
/// Type Parameters:
/// - [T] - The document type, must extend [TurboWriteableId<String>]
/// - [API] - The Firestore API type, must extend [TurboFirestoreApi<T>]
abstract class BeSyncTurboDocumentService<T extends TurboWriteableId<String>,
    API extends TurboFirestoreApi<T>> extends TurboDocumentService<T, API> {
  /// Creates a new [BeSyncTurboDocumentService] instance.
  BeSyncTurboDocumentService({required super.api});

  /// Called before the local state is updated with new data.
  ///
  /// Use this method to perform any necessary operations before
  /// the document is synchronized with local state.
  ///
  /// Parameters:
  /// - [doc] - The new document from Firestore
  Future<void> beforeSyncNotifyUpdate(T? doc);

  /// Handles incoming data updates from Firestore with pre-sync notification.
  ///
  /// This callback is triggered when:
  /// - New document data is received from Firestore
  /// - The user's authentication state changes
  ///
  /// The method:
  /// - Notifies before sync via [beforeSyncNotifyUpdate] if user is authenticated
  /// - Updates local state with new document data
  /// - Marks the service as ready after first update
  /// - Clears local state if user is not authenticated
  ///
  /// Parameters:
  /// - [value] - The new document value from Firestore
  /// - [user] - The current Firebase user
  @override
  Future<void> Function(T? value, User? user) get onData {
    return (value, user) async {
      if (user != null) {
        log.debug('Updating doc for user ${user.uid}');
        if (value != null) {
          await beforeSyncNotifyUpdate(value);
          upsertLocalDoc(
            id: value.id,
            doc: (current, _) => value,
          );
          _isReady.completeIfNotComplete();
        } else {
          await beforeSyncNotifyUpdate(null);
          _doc.update(null);
        }
        log.debug('Updated doc');
      } else {
        log.debug('User is null, clearing doc');
        await beforeSyncNotifyUpdate(null);
        _doc.update(null);
      }
    };
  }
}
