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
