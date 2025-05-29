## 🚀 Version 0.8.0 (May 2025)

* **🛠️ Improvement:** Clean release with all dependencies updated and proper git state

## 🚀 Version 0.7.2 (May 2025)

* **🛠️ Improvement:** Comprehensive dependency update to latest compatible versions
* **🛠️ Improvement:** Updated loglytics dependency to version 0.16.0
* **🛠️ Improvement:** Updated repository URLs to use the correct GitHub username (its-brianwithai)
* **🛠️ Improvement:** Updated flutter_lints to version 6.0.0
* **🛠️ Improvement:** Updated all Firebase dependencies to latest versions
* **🛠️ Improvement:** Verified compatibility with Flutter 3.32.0 and Dart 3.8.0

## 🚀 Version 0.7.1 (April 2025)

* **🛠️ Improvement:** Exposed `docsPerIdInformer` as @protected in `TurboFirestoreApi` for better access control when overriding methods.
* **🛠️ Improvement:** Updated dependencies to latest versions.

## 🚀 Version 0.7.0 (March 2025)

### ✨ Features:
* Enhanced error handling using `TurboFirestoreException.fromFirestoreException` for more structured error responses across all API methods

### 🛠️ Improvements:
* Refined documentation for error handling features 
* Improved code consistency across API implementations
* Added detailed examples for exception handling

## 🚀 Version 0.6.1 (January 2025)

### 🛠️ Improvements:
* Updated sync services to use `upsertLocalDoc` instead of `updateLocalDoc` for better consistency
* Enhanced error handling across multiple API methods using `TurboFirestoreException.fromFirestoreException` for more structured error responses

## 🚀 Version 0.6.0 (January 2025)
---
### ✨ Features:
* Added `upsertLocalDocs` method for consistent batch local operations

### 🛠️ Improvements:
* Improved upsert operations to always use `createDoc` with `merge: true`
* Removed incorrect exists checks in upsert operations

### 🐛 Bug fixes:
* Fixed incorrect document creation skipping in upsert operations

## 🚀 Version 0.5.0 (January 2025)

* **💔 Breaking:** Removed `templateBlockNotify`.

## 🚀 Version 0.4.2 (January 2025)

* **🛠️ Improvement:** Add id getter.

## 🚀 Version 0.4.1 (January 2025)

* **🛠️ Improvement:** Made `TurboAuthVars.userId` non-nullable for better type safety (defaults to `kValuesNoAuthId`)
* **🛠️ Improvement:** Added `UpdateDocDef` type definition export

## 🚀 Version 0.4.0 (January 2025)

* **💔 Breaking:** Renamed `createDoc` and `updateDoc` named parameter names to doc.
* **🛠️ Improvement:** Update readme.

## 🚀 Version 0.3.0 (January 2025)
---
### 💔 Breaking:
* Renamed `vars()` to `turboVars()` for better clarity and consistency
* Renamed batch operation methods for better clarity:
    * `createDocs()` -> `createDocInBatch()`
    * `deleteDocs()` -> `deleteDocInBatch()`
    * `updateDocs()` -> `updateDocInBatch()`
* Updated method signatures to use new type definitions (`CreateDocDef<T>`, `UpdateDocDef<T>`)

### ✨ Features:
* Added sync service implementations:
    * `AfSyncTurboDocumentService` - After sync notifications
    * `BeAfSyncTurboDocumentService` - Before and after sync notifications
    * `BeSyncTurboDocumentService` - Before sync notifications
* Added type definitions for document operations:
    * `CreateDocDef<T>` - Type definition for document creation functions
    * `UpdateDocDef<T>` - Type definition for document update functions

### 🛠️ Improvements:
* Improved temporary block notify in sync services for better state management

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
