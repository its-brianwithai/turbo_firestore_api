## 0.3.0

* **🔄 Change:** Renamed `vars()` to `turboVars()` for better clarity and consistency
* **🔄 Change:** Renamed batch operation methods for better clarity:
  * `createDocs()` -> `createDocInBatch()`
  * `deleteDocs()` -> `deleteDocInBatch()`
  * `updateDocs()` -> `updateDocInBatch()`
* **✨ New:** Added sync service implementations:
  * `AfSyncTurboDocumentService` - After sync notifications
  * `BeAfSyncTurboDocumentService` - Before and after sync notifications
  * `BeSyncTurboDocumentService` - Before sync notifications
* **✨ New:** Added type definitions for document operations:
  * `CreateDocDef<T>` - Type definition for document creation functions
  * `UpdateDocDef<T>` - Type definition for document update functions
* **🔧 Fix:** Improved temporary block notify in sync services for better state management

## 0.2.0

* **⚠️ Breaking:** Updated dependencies to latest versions.

## 0.1.3

* **✨ New:** Added `TurboApiVars` and `TurboAuthVars` classes for standardized document variables

## 0.1.2

* **⬆️ Upgrade:** Updated turbo_response to version 0.2.6
* **🔄 Change:** Replaced tryThrowFail() with throwWhenFail() to match new TurboResponse API

## 0.1.1

* **🐛 Fix:** Remove default stream implementation in `TurboCollectionService` to enforce inheritance.

## 0.1.0+1

* **🐛 Fix:** Made `TurboResponse<T>? validate<T>()` null by default to avoid forced inheritance. 

## 0.1.0

* **✨ New:** Initial release of turbo_firestore_api
* **✨ New:** Added TurboFirestoreApi for clean Firestore operations
* **✨ New:** Implemented CRUD operations with error handling
* **✨ New:** Added search functionality
* **✨ New:** Added stream support
* **✨ New:** Added auth sync service
* **✨ New:** Added collection and document services
* **✨ New:** Added exception handling
* **📝 Docs:** Added basic documentation and examples
