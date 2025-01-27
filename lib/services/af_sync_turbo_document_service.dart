part of 'turbo_document_service.dart';

/// A document service that allows notification after synchronizing data.
///
/// Extends [TurboDocumentService] to provide a hook for notifying after
/// the local state has been updated with new data from Firestore.
///
/// Type Parameters:
/// - [T] - The document type, must extend [TurboWriteableId<String>]
/// - [API] - The Firestore API type, must extend [TurboFirestoreApi<T>]
abstract class AfSyncTurboDocumentService<T extends TurboWriteableId<String>,
    API extends TurboFirestoreApi<T>> extends TurboDocumentService<T, API> {
  /// Creates a new [AfSyncTurboDocumentService] instance.
  AfSyncTurboDocumentService({required super.api});

  /// Called after the local state has been updated with new data.
  ///
  /// Use this method to perform any necessary operations after
  /// the document has been synchronized with local state.
  ///
  /// Parameters:
  /// - [doc] - The new document from Firestore
  void afterSyncNotifyUpdate(T? doc);

  /// Handles incoming data updates from Firestore with post-sync notification.
  ///
  /// This callback is triggered when:
  /// - New document data is received from Firestore
  /// - The user's authentication state changes
  ///
  /// The method:
  /// - Updates local state with new document data if user is authenticated
  /// - Marks the service as ready after first update
  /// - Notifies after sync via [afterSyncNotifyUpdate]
  /// - Clears local state if user is not authenticated
  ///
  /// Parameters:
  /// - [value] - The new document value from Firestore
  /// - [user] - The current Firebase user
  @override
  void Function(T? value, User? user) get onData {
    return (value, user) {
      if (user != null) {
        log.debug('Updating doc for user ${user.uid}');
        final pDoc = updateLocalDoc(
          id: value?.id,
          doc: (_, __) => value,
        );
        _isReady.completeIfNotComplete();
        afterSyncNotifyUpdate(pDoc);
        log.debug('Updated doc');
      } else {
        log.debug('User is null, clearing doc');
        updateLocalDoc(
          id: null,
          doc: (_, __) => null,
        );
        afterSyncNotifyUpdate(null);
      }
    };
  }
}
