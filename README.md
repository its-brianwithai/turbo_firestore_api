# Turbo Firestore API

A powerful, type-safe wrapper around Cloud Firestore operations for Flutter applications. This package provides a robust foundation for building scalable applications with Firestore, offering automatic type conversion, state management, and enhanced error handling.

## 🌟 Key Features

- [🔒 Type-safe Operations](#-type-safe-operations)
  - Automatic type conversion between Firestore and Dart objects
  - Built-in validation through `TurboWriteable`
  - Local ID and reference field management

- [🔄 State Management](#-state-management)
  - Optimistic UI updates with rollback
  - Local state synchronization
  - Automatic stream update blocking during mutations
  - Authentication state synchronization

- [📦 Advanced Operations](#-advanced-operations)
  - Batch operations support
  - Transaction support for atomic operations
  - Collection group queries
  - Real-time data streaming
  - Search capabilities

- [⚡ Performance](#-performance)
  - Debouncing support
  - Mutex operations
  - Optimistic updates
  - Automatic timestamp management

- [🛡️ Error Handling](#️-error-handling)
  - Comprehensive error handling
  - Detailed logging system
  - Sensitive data protection
  - Operation validation

## 📦 Quick Start

1. Create an API instance:

```dart
final api = TurboFirestoreApi<User>(
  firebaseFirestore: FirebaseFirestore.instance,
  collectionPath: () => 'users',
  fromJson: User.fromJson,
  toJson: (user) => user.toJson(),
);
```

2. Create a service:

```dart
class UsersService extends TurboCollectionService<User, UsersApi> {
  UsersService({required super.api});
  
  Future<TurboResponse<T>> createUser({
    required String name,
    required int age,
  }) async {
    return createDoc(
      createDoc: (vars) => UserDto(
        id: vars.id,
        userId: vars.userId,
        name: name,
        age: age,
        createdAt: vars.now,
        updatedAt: vars.now,
      ),
    );
  }

  Future<TurboResponse<T>> updateUser({
    required String id,
    String? name,
    int? age,
  }) async {
    return updateDoc(
      id: id,
      updateDoc: (current, vars) => UserDto(
        id: current.id,
        userId: current.userId,
        name: name ?? current.name,
        age: age ?? current.age,
        createdAt: current.createdAt,
        updatedAt: vars.now,
      ),
    );
  }
}
```

That's it! You can now use all the features of Turbo Firestore API in your application.

## 📦 Type-safe Operations

Turbo Firestore API ensures type safety throughout your Firestore interactions, providing a seamless and error-free development experience.

### 🔄 Automatic Type Conversion

The package automatically converts between Firestore documents and Dart objects, eliminating the need for manual serialization and deserialization.

```dart
final api = TurboFirestoreApi<User>(
  fromJson: User.fromJson,
  toJson: (user) => user.toJson(),
);
```

### 🛡️ Built-in Validation

Turbo Firestore API includes built-in validation through the `TurboWriteable` abstract class, ensuring data integrity and consistency. By extending `TurboWriteable`, you can implement custom validation logic, handle field-level checks, and ensure data meets your application's requirements.

```dart
import 'package:turbo_firestore_api/abstracts/turbo_writeable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:turbo_response/turbo_response.dart';

part 'user.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class User extends TurboWriteable {
  /// User's unique identifier (managed by Firestore API)
  @JsonKey(ignore: true)
  String? id;

  /// User's full name
  final String name;

  /// User's age
  final int age;

  /// User's email address
  final String email;

  User({
    this.id,
    required this.name,
    required this.age,
    required this.email,
  });

  /// Validation method to ensure data integrity
  /// Returns null if validation passes, or a TurboResponse with error details if validation fails
  @override
  TurboResponse<void>? validate() {
    // Validate name
    if (name.isEmpty) {
      return TurboResponse.fail(
        error: Exception('Name cannot be empty'),
        title: 'Invalid Name',
        message: 'Name cannot be empty',
      );
    }
    if (name.length < 2) {
      return TurboResponse.fail(
        error: Exception('Name too short'),
        title: 'Invalid Name',
        message: 'Name must be at least 2 characters long',
      );
    }

    // Validate age
    if (age < 0) {
      return TurboResponse.fail(
        error: Exception('Invalid age'),
        title: 'Invalid Age',
        message: 'Age must be non-negative',
      );
    }
    if (age > 120) {
      return TurboResponse.fail(
        error: Exception('Unrealistic age'),
        title: 'Invalid Age',
        message: 'Age seems unrealistic',
      );
    }

    // Validate email
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      return TurboResponse.fail(
        error: Exception('Invalid email format'),
        title: 'Invalid Email',
        message: 'Invalid email format',
      );
    }

    // Return null if all validations pass
    return null;
  }

  /// Convert to JSON, automatically excluding ID and other transient fields
  @override
  Map<String, dynamic> toJson() => _$UserToJson(this);

  /// Create from JSON, allowing package to inject ID if needed
  factory User.fromJson(Map<String, dynamic> json) {
    final user = _$UserFromJson(json);
    return user;
  }
}
```

#### Key Validation Features

1. **Comprehensive Validation**: The `validate()` method performs multiple checks on different fields and returns `null` if all validations pass.
2. **TurboResponse Integration**: Returns `TurboResponse.fail()` with detailed error information when validation fails.
3. **JSON Serialization**: Uses `json_annotation` to control serialization.
4. **ID Management**: Demonstrates how the package handles document IDs.

#### How Turbo Firestore API Uses Validation

```dart
final api = TurboFirestoreApi<User>(
  fromJson: User.fromJson,
  toJson: (user) => user.toJson(),
);

// Validation happens automatically during create/update operations
final response = await api.createDoc(
  createDoc: (vars) => User(
    id: vars.id,
    userId: vars.userId,
    name: 'John',
    age: 30,
    createdAt: vars.now,
  ),
);

response.fold(
  ifSuccess: (documentReference) {
    print('User created successfully');
  },
  orElse: (error) {
    print('What went wrong: ${error.message}');
  },
);
```

#### Benefits of TurboWriteable

- **Proactive Data Validation**: Catch data inconsistencies before they reach Firestore
- **Flexible Validation Logic**: Implement custom validation rules specific to your models
- **Automatic Error Handling**: Seamless integration with Turbo Firestore API's error management
- **Type-Safe Operations**: Ensure data integrity at compile-time and runtime

### 🆔 Local ID and Reference Field Management

The package simplifies local ID and `DocumentReference` field management, making it easy to work with document relationships and identifiers.

```dart
import 'package:json_annotation/json_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:turbo_firestore_api/abstracts/turbo_writeable.dart';

part 'user.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class User extends TurboWriteable {
  /// Document ID - included when reading from JSON, excluded when writing to JSON
  @JsonKey(includeFromJson: true, includeToJson: false)
  final String id;

  /// Document reference - included when reading from JSON, excluded when writing to JSON
  @JsonKey(includeFromJson: true, includeToJson: false)
  final DocumentReference documentReference;

  /// User's name
  final String name;

  /// User's age
  final int age;

  User({
    required this.id,
    required this.documentReference,
    required this.name,
    required this.age,
  });

  /// Convert to JSON - package automatically handles id and documentReference
  @override
  Map<String, dynamic> toJson() => _$UserToJson(this);

  /// Create from JSON - package automatically injects id and documentReference
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

// Configure API to handle ID and reference fields
final api = TurboFirestoreApi<User>(
  fromJson: User.fromJson,
  toJson: (user) => user.toJson(),
  tryAddLocalId: true, // Automatically adds document ID to model
  idFieldName: 'id', // Field name for ID in your model
  tryAddLocalDocumentReference: true, // Automatically adds document reference to model
  documentReferenceFieldName: 'documentReference', // Field name for reference in your model
);

// When reading, the package automatically adds ID and reference:
final response = await api.getDoc(id: 'user123');
response.fold(
  ifSuccess: (user) {
    print('User ID: ${user.id}'); // 'user123'
    print('User Ref: ${user.documentReference.path}'); // 'users/user123'
  },
  orElse: (error) => print('Error: ${error.message}'),
);

// When writing, the package automatically handles ID and reference:
final newUser = User(
  id: api.genId,
  documentReference: api.getDocRefById(id: api.genId),
  name: 'John',
  age: 30,
);
await api.createDoc(doc: newUser);
// The package automatically excludes id and documentReference when writing to Firestore
```

The package handles ID and reference fields by:
1. **Reading**: Automatically injects the document ID and reference into your model
2. **Writing**: Automatically excludes these fields when writing to Firestore
3. **Type Safety**: Uses your model's field types for proper type checking
4. **Flexibility**: Configurable field names to match your model structure

## 🔄 State Management

Turbo Firestore API provides robust state management capabilities, ensuring a smooth and responsive user experience.

### ⚡ Optimistic UI Updates with Rollback

The package supports optimistic UI updates with automatic rollback, providing instant feedback to users while maintaining data consistency.

```dart
class UsersService extends TurboCollectionService<User, UsersApi> {
  UsersService({required super.api});

  /// Updates a user's name with optimistic UI update
  Future<TurboResponse<DocumentReference>> updateUserName(User user, String newName) async {
    // Create updated user
    final updatedUser = User(
      id: user.id,
      documentReference: user.documentReference,
      name: newName,
      age: user.age,
    );

    // Update local state immediately and sync with Firestore
    return updateDoc(
      doc: updatedUser,
      doNotifyListeners: true, // Notify listeners of local state change
    );
  }
}

// Usage in UI
class UserNameField extends StatelessWidget {
  final User user;
  final UsersService service;

  @override
  Widget build(BuildContext context) {
    return TextField(
      initialValue: user.name,
      onSubmitted: (newName) async {
        // UI updates immediately due to optimistic update
        final response = await service.updateUserName(user, newName);
        
        response.fold(
          ifSuccess: (_) {
            // Update successful, local state already reflects change
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Name updated successfully')),
            );
          },
          orElse: (error) {
            // Update failed, but local state was already updated
            // Service maintains consistency
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to update name: ${error.message}')),
            );
          },
        );
      },
    );
  }
}
```

Key features of optimistic updates:
1. **Instant UI Updates**: Local state is updated immediately before Firestore operation
2. **Automatic Stream Blocking**: Prevents stream updates during mutations to avoid UI flicker
3. **Error Handling**: Maintains consistent state even if remote update fails
4. **Transaction Support**: Can be used within transactions for atomic operations
5. **Batch Operations**: Supports optimistic updates for multiple documents

### 🔄 Local State Synchronization

The package provides powerful local state synchronization with hooks for pre-processing data before state updates:

```dart
class UsersService extends BeTurboCollectionService<User, UsersApi> {
  UsersService({required super.api});

  // Maintain a sorted list of users by age
  List<User> _sortedUsers = [];
  List<User> get sortedUsers => _sortedUsers;

  // Called before local state updates
  @override
  void beforeSyncNotifyUpdate(List<User> docs) {
    // Sort users by age before updating local state
    _sortedUsers = List<User>.from(docs)
      ..sort((a, b) => b.age.compareTo(a.age));
  }

  // Direct access by ID for efficient lookups
  User? getUserById(String id) => tryFindById(id);
  
  // Check if user exists
  bool hasUser(String id) => exists(id);
}

// Usage in UI - Sorted List
class UsersByAgeList extends StatelessWidget {
  final UsersService service;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: service.listenable,
      builder: (context, child) {
        final sortedUsers = service.sortedUsers;
        if (sortedUsers.isEmpty) {
          return Text('No users found');
        }
        
        return ListView.builder(
          itemCount: sortedUsers.length,
          itemBuilder: (context, index) {
            final user = sortedUsers[index];
            return ListTile(
              title: Text(user.name),
              trailing: Text('Age: ${user.age}'),
            );
          },
        );
      },
    );
  }
}

// Usage in UI - Direct Access
class UserProfile extends StatelessWidget {
  final UsersService service;
  final String userId;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: service.listenable,
      builder: (context, child) {
        final user = service.getUserById(userId);
        if (user == null) {
          return Text('User not found');
        }

        return Column(
          children: [
            Text('Name: ${user.name}'),
            Text('Age: ${user.age}'),
          ],
        );
      },
    );
  }
}
```

Key features of local state synchronization:
1. **Pre-processing Hooks**: Process data before state updates with `beforeSyncNotifyUpdate`
2. **Efficient Access**: Direct access by ID through `tryFindById`
3. **Derived State**: Maintain sorted or filtered views of the data
4. **Real-time Updates**: All views stay in sync with Firestore changes
5. **Type Safety**: Full type safety for all operations

### 🚫 Automatic Stream Update Blocking

The package automatically blocks stream updates during mutations to prevent race conditions and UI flicker. This is especially important for optimistic updates:

```dart
class UsersService extends TurboCollectionService<User, UsersApi> {
  UsersService({required super.api});

  /// Updates multiple user ages in a batch
  Future<TurboResponse> updateUserAges(List<User> users, int newAge) async {
    final updatedUsers = users.map((user) => User(
      id: user.id,
      documentReference: user.documentReference,
      name: user.name,
      age: newAge,
    )).toList();

    // During this batch update:
    // 1. Local state updates immediately
    // 2. Stream updates are blocked
    // 3. Remote update executes
    // 4. Stream unblocks after completion
    return updateDocInBatch(
      docs: updatedUsers,
      doNotifyListeners: true,
    );
  }
}

// Usage in UI
class UserAgeUpdateButton extends StatelessWidget {
  final UsersService service;
  final List<User> selectedUsers;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        // UI updates immediately due to optimistic update
        // Stream updates are blocked until operation completes
        final response = await service.updateUserAges(selectedUsers, 25);
        
        response.fold(
          ifSuccess: (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Ages updated successfully')),
            );
          },
          orElse: (error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to update ages: ${error.message}')),
            );
          },
        );
      },
      child: Text('Set Age to 25'),
    );
  }
}
```

Key features of stream update blocking:
1. **Race Condition Prevention**: Prevents stream updates from overwriting optimistic updates
2. **UI Consistency**: Eliminates UI flicker during mutations
3. **Automatic Timing**: Blocks only for the duration of the mutation
4. **Batch Support**: Works with single operations and batch updates
5. **Transaction Support**: Compatible with Firestore transactions

### 🔐 Authentication State Synchronization

The package automatically manages state based on Firebase Authentication:

```dart
class UsersService extends TurboCollectionService<User, UsersApi> {
  UsersService({required super.api});

  // Handle data updates and auth state changes
  @override
  void Function(List<User>? value, User? user) get onData {
    return (value, user) {
      if (user != null) {
        // User is signed in, update local state
        final docs = value ?? [];
        log.debug('Updating ${docs.length} docs for user ${user.uid}');
        _docsPerId.update(docs.toIdMap((element) => element.id));
        _isReady.completeIfNotComplete();
      } else {
        // User is signed out, clear local state
        log.debug('User is null, clearing all docs');
        _docsPerId.update({});
      }
    };
  }

  // Access current user's ID (null if signed out)
  String? get currentUserId => cachedUserId;
}
```

Key features of authentication state synchronization:
1. **Automatic State Management**: 
   - Updates local state when user signs in
   - Clears local state when user signs out
2. **Efficient Data Handling**:
   - Maintains data in indexed map structure
   - Provides easy access to current user ID
3. **UI Integration**:
   - Automatic UI updates on auth state changes
   - Clean handling of signed-out state
4. **Resource Management**:
   - Proper cleanup of subscriptions
   - Memory leak prevention

## 📦 Advanced Operations

Turbo Firestore API offers a wide range of advanced operations, enabling complex and efficient data management.

### 🎯 Batch Operations

The package supports batch operations with optimistic updates, allowing you to perform multiple writes atomically while maintaining UI responsiveness:

```dart
class UsersService extends TurboCollectionService<User, UsersApi> {
  UsersService({required super.api});

  /// Deactivates multiple users in a single atomic operation
  Future<TurboResponse> deactivateUsers(List<User> users) async {
    // Create updated users with deactivated status
    final deactivatedUsers = users.map((user) => User(
      id: user.id,
      documentReference: user.documentReference,
      name: user.name,
      age: user.age,
      isActive: false,
    )).toList();

    // During this batch update:
    // 1. Local state updates immediately for all users
    // 2. Stream updates are blocked
    // 3. All updates are added to a batch
    // 4. Batch is committed atomically
    // 5. Stream unblocks after completion
    return updateDocInBatch(
      docs: deactivatedUsers,
      doNotifyListeners: true,
    );
  }
}
```

Key features of batch operations:
1. **Atomic Updates**: All operations succeed or fail together
2. **Optimistic UI**: Local state updates immediately for better UX
3. **Stream Blocking**: Prevents stream updates during batch operation
4. **Type Safety**: Full type safety for all batch operations

### 🔄 Transactions

The package supports transactions with optimistic updates, allowing you to perform atomic operations while maintaining UI responsiveness:

```dart
class UsersService extends TurboCollectionService<User, UsersApi> {
  UsersService({required super.api});

  /// Transfer points between users atomically
  Future<TurboResponse> transferPoints({
    required User fromUser,
    required User toUser,
    required int points,
  }) async {
    final updatedUsers = users.map((user) => User(
      id: user.id,
      documentReference: user.documentReference,
      name: user.name,
      age: newAge,
    )).toList();

    // During this batch update:
    // 1. Local state updates immediately
    // 2. Stream updates are blocked
    // 3. Remote update executes
    // 4. Stream unblocks after completion
    return updateDocInBatch(
      docs: updatedUsers,
      doNotifyListeners: true,
    );
  }
}
```

Key features of transactions:
1. **Atomic Operations**: All operations succeed or fail together
2. **Optimistic UI**: Local state updates immediately for better UX
3. **Fail-Fast**: Uses `tryThrowFail` to immediately abort failed transactions
4. **Type Safety**: Full type safety for all operations
5. **Error Handling**: Automatic rollback on failure

### 👥 Collection Group Queries

The package enables querying across multiple collections with the same name, regardless of their location in the document hierarchy. This is particularly useful for hierarchical data structures:

```dart
class CommentsService extends TurboCollectionService<Comment, CommentsApi> {
  CommentsService({required super.api});

  /// Finds all comments across the entire app, regardless of parent document
  Future<TurboResponse<List<Comment>>> findAllComments() async {
    return api.listByQueryWithConverter(
      collectionReferenceQuery: (ref) => ref
        .orderBy('createdAt', descending: true)
        .limit(50),
      whereDescription: 'Finding recent comments across all collections',
    );
  }

  /// Finds comments by a specific user across all collections
  Future<TurboResponse<List<Comment>>> findUserComments(String userId) async {
    return api.listByQueryWithConverter(
      collectionReferenceQuery: (ref) => ref
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true),
      whereDescription: 'Finding user comments across all collections',
    );
  }
}

// Configure API to use collection group
final api = TurboFirestoreApi<Comment>(
  firebaseFirestore: FirebaseFirestore.instance,
  collectionPath: () => 'comments', // Collection name to query across all paths
  fromJson: Comment.fromJson,
  toJson: (comment) => comment.toJson(),
  isCollectionGroup: true, // Enable collection group queries
);

// Usage in UI
class RecentCommentsView extends StatelessWidget {
  final CommentsService service;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TurboResponse<List<Comment>>>(
      future: service.findAllComments(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();
        
        return snapshot.data!.fold(
          ifSuccess: (comments) => ListView.builder(
            itemCount: comments.length,
            itemBuilder: (context, index) {
              final comment = comments[index];
              return ListTile(
                title: Text(comment.text),
                subtitle: Text('By: ${comment.userName}'),
              );
            },
          ),
          orElse: (error) => Text('Error: ${error.message}'),
        );
      },
    );
  }
}
```

Key features of collection group queries:
1. **Hierarchical Data**: Query same-named collections at any path depth
2. **Type Safety**: Full type conversion and validation
3. **Query Support**: All standard query operations (where, orderBy, limit)
4. **Performance**: Efficient querying across multiple collections
5. **Error Handling**: Proper error handling and logging

### 🔄 Real-time Data Streaming

The package provides built-in real-time data streaming through `TurboCollectionService`, with automatic state management and UI synchronization:

```dart
class UsersService extends BeTurboCollectionService<User, UsersApi> {
  UsersService({required super.api});

  // Maintain a sorted list of active users
  List<User> _activeUsers = [];
  List<User> get activeUsers => _activeUsers;

  // Process data before notifying listeners
  @override
  void beforeSyncNotifyUpdate(List<User> docs) {
    _activeUsers = docs
      .where((user) => user.isActive)
      .toList()
      ..sort((a, b) => b.lastSeen.compareTo(a.lastSeen));
  }
}

// Usage in UI with automatic state management
class ActiveUsersView extends StatelessWidget {
  const ActiveUsersView({
    super.key,
    required this.service,
    required this.viewModel,
  });

  final UsersService service;
  final UsersViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: service.listenable,
      builder: (context, _) {
        final users = service.activeUsers;
        
        if (users.isEmpty) {
          return Text('No active users');
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return ListTile(
              title: Text(user.name),
              subtitle: Text('Last seen: ${user.lastSeen}'),
              trailing: OnlineIndicator(user: user),
              onTap: () => viewModel.onUserPressed(user.id),
            );
          },
        );
      },
    );
  }
}


// View model for handling user interactions
class UsersViewModel extends ChangeNotifier {
  final UsersService _service;
  
  UsersViewModel({required UsersService service}) : _service = service;
  
  User? _selectedUser;
  User? get selectedUser => _selectedUser;

  void onUserPressed(String userId) {
    // Direct access by ID, no need for additional queries
    _selectedUser = _service.findById(userId);
    notifyListeners();
  }
}


// Selected user details view
class SelectedUserView extends StatelessWidget {
  final UsersViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final user = viewModel.selectedUser;
        if (user == null) {
          return Text('No user selected');
        }

        return Column(
          children: [
            Text('Name: ${user.name}'),
            Text('Status: ${user.isActive ? "Online" : "Offline"}'),
            Text('Last seen: ${user.lastSeen}'),
          ],
        );
      },
    );
  }
}
```

Key features of real-time streaming:
1. **Built-in State Management**: Service handles all streaming and state updates
2. **Pre-processing**: Use `BeTurboCollectionService` to process data before updates
3. **Efficient Updates**: Only rebuilds UI when data actually changes
4. **Direct Access**: Fast lookups using `findById` without additional queries
5. **Memory Efficient**: Automatic cleanup of streams and subscriptions

### 🔍 Search Capabilities

The package provides powerful search capabilities with support for both text and numeric searches:

```dart
class UsersService extends TurboCollectionService<User, UsersApi> {
  UsersService({required super.api});

  /// Search users by name prefix
  Future<TurboResponse<List<User>>> searchByName(String namePrefix) {
    return api.listBySearchTermWithConverter(
      searchTerm: namePrefix,
      searchField: 'name',
      searchTermType: TurboSearchTermType.startsWith,
      limit: 20, // Optional limit
    );
  }

  /// Search users by skills (array field)
  Future<TurboResponse<List<User>>> searchBySkills(String skill) {
    return api.listBySearchTermWithConverter(
      searchTerm: skill,
      searchField: 'skills',
      searchTermType: TurboSearchTermType.arrayContains,
    );
  }

  /// Search by age with automatic number conversion
  Future<TurboResponse<List<User>>> searchByAge(String ageInput) {
    return api.listBySearchTermWithConverter(
      searchTerm: ageInput,
      searchField: 'age',
      searchTermType: TurboSearchTermType.startsWith,
      doSearchNumberEquivalent: true, // Will also try to match numeric value
    );
  }
}

// View model for search functionality
class SearchViewModel extends ChangeNotifier {
  final UsersService _service;
  
  SearchViewModel({required UsersService service}) : _service = service;
  
  List<User> _searchResults = [];
  List<User> get searchResults => _searchResults;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String _error = '';
  String get error => _error;

  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      _error = '';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      // Try name search first
      final response = await _service.searchByName(query);
      
      response.fold(
        ifSuccess: (users) {
          _searchResults = users;
          _error = '';
        },
        orElse: (error) {
          _searchResults = [];
          _error = error.message ?? 'Search failed';
        },
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

// Usage in UI
class UserSearchView extends StatelessWidget {
  final SearchViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SearchBar(
          onChanged: (query) => viewModel.searchUsers(query),
        ),
        ListenableBuilder(
          listenable: viewModel,
          builder: (context, _) {
            if (viewModel.isLoading) {
              return CircularProgressIndicator();
            }

            if (viewModel.error.isNotEmpty) {
              return Text('Error: ${viewModel.error}');
            }

            final results = viewModel.searchResults;
            if (results.isEmpty) {
              return Text('No results found');
            }

            return ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, index) {
                final user = results[index];
                return ListTile(
                  title: Text(user.name),
                  subtitle: Text('Age: ${user.age}'),
                  trailing: Wrap(
                    children: user.skills.map((skill) => 
                      Chip(label: Text(skill))
                    ).toList(),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
```

Key features of search capabilities:
1. **Multiple Search Types**: Support for prefix matching and array containment
2. **Numeric Search**: Automatic handling of numeric values
3. **Type Safety**: Full type conversion and validation
4. **Result Limiting**: Optional limit for large result sets
5. **Error Handling**: Proper error handling with `TurboResponse`

## ⏰ Automatic Timestamp Management

Turbo Firestore API automatically manages timestamp fields, simplifying document tracking:

```dart
// Configure API with timestamp fields
final api = TurboFirestoreApi<User>(
  firebaseFirestore: FirebaseFirestore.instance,
  collectionPath: () => 'users',
  fromJson: User.fromJson,
  toJson: (user) => user.toJson(),
  // Enable automatic timestamp management
  createdAtFieldName: 'createdAt',
  updatedAtFieldName: 'updatedAt',
);

// User model with timestamp fields
class User extends TurboWriteable {
  final String id;
  final DocumentReference? documentReference;
  final String name;
  final int age;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    this.documentReference,
    required this.name,
    required this.age,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      documentReference: json['documentReference'] as DocumentReference?,
      name: json['name'] as String,
      age: json['age'] as int,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      // Timestamps are handled automatically by the API
    };
  }

  @override
  TurboResponse? validate() => null; // No validation needed
}

// Service with timestamp-aware operations
class UsersService extends TurboCollectionService<User, UsersApi> {
  UsersService({required super.api});

  /// Create a new user with automatic timestamps
  Future<TurboResponse> createUser({
    required String name,
    required int age,
  }) async {
    final user = User(
      id: api.genId,
      name: name,
      age: age,
    );

    return createDoc(
      doc: user,
      doNotifyListeners: true,
    );
  }

  /// Get recently created users
  Future<TurboResponse<List<User>>> getRecentUsers() async {
    return api.listByQueryWithConverter(
      collectionReferenceQuery: (ref) => ref
        .orderBy('createdAt', descending: true)
        .limit(10),
      whereDescription: 'Finding recently created users',
    );
  }

  /// Get recently updated users
  Future<TurboResponse<List<User>>> getRecentlyUpdatedUsers() async {
    return api.listByQueryWithConverter(
      collectionReferenceQuery: (ref) => ref
        .orderBy('updatedAt', descending: true)
        .limit(10),
      whereDescription: 'Finding recently updated users',
    );
  }
}

// Usage in UI
class RecentUsersView extends StatelessWidget {
  final UsersService service;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TurboResponse<List<User>>>(
      future: service.getRecentUsers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();

        return snapshot.data!.fold(
          ifSuccess: (users) => ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                title: Text(user.name),
                subtitle: Text('Created: ${user.createdAt?.toString() ?? 'N/A'}'),
                trailing: Text('Last updated: ${user.updatedAt?.toString() ?? 'N/A'}'),
              );
            },
          ),
          orElse: (error) => Text('Error: ${error.message}'),
        );
      },
    );
  }
}
```

Key features of automatic timestamp management:
1. **Automatic Updates**: Timestamps are managed automatically by the API
2. **Type Safety**: Full type conversion between Firestore and Dart
3. **Query Support**: Use timestamps for sorting and filtering
4. **Audit Trail**: Track document creation and modification times
5. **Zero Configuration**: No manual timestamp handling needed

## 🛡️ Error Handling

Turbo Firestore API provides comprehensive error handling through `TurboResponse`, eliminating the need for try-catch blocks and validation:

```dart
class UsersService extends TurboCollectionService<User, UsersApi> {
  UsersService({required super.api});

  /// Create a new user
  Future<TurboResponse> createUser({
    required String name,
    required int age,
  }) async {
    final user = User(
      id: api.genId,
      name: name,
      age: age,
    );

    // The API handles all validation and Firestore exceptions internally
    // and returns them wrapped in TurboResponse
    return createDoc(
      doc: user,
      doNotifyListeners: true,
    );
  }

  /// Transfer points between users using a transaction
  Future<TurboResponse> transferPoints({
    required User fromUser,
    required User toUser,
    required int points,
  }) async {
    final updatedUsers = users.map((user) => User(
      id: user.id,
      documentReference: user.documentReference,
      name: user.name,
      age: newAge,
    )).toList();

    // During this batch update:
    // 1. Local state updates immediately
    // 2. Stream updates are blocked
    // 3. Remote update executes
    // 4. Stream unblocks after completion
    return updateDocInBatch(
      docs: updatedUsers,
      doNotifyListeners: true,
    );
  }
}

// Usage in UI with simplified error handling
class CreateUserButton extends StatelessWidget {
  final UsersService service;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final response = await service.createUser(
          name: 'John',
          age: 25,
        );

        // Simple fold pattern for handling success/failure
        response.fold(
          ifSuccess: (_) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User created successfully')),
          ),
          orElse: (error) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.message ?? 'Failed to create user')),
          ),
        );
      },
      child: Text('Create User'),
    );
  }
}
```

Key features of TurboResponse error handling:
1. **No Try-Catch Needed**: All Firestore exceptions are automatically caught and wrapped
2. **Automatic Validation**: API handles all validation internally through `TurboWriteable`
3. **Type-safe Responses**: Generic type parameter for success value
4. **Convenient Fold Pattern**: Simple success/failure handling with `fold`
5. **Transaction Support**: Methods automatically throw to abort transactions on failure
6. **Manual Throwing**: Use `TurboResponse.throwException()` or `response.tryThrowFail()` for custom conditions
7. **Rich Error Context**: Includes error message, stack trace, and location
8. **Chainable Operations**: Combine multiple operations with error short-circuiting
9. **Automatic Logging**: Errors are automatically logged with proper context

## 📦 Best Practices

1. **Document Creation**
   - Use `api.genId` for new document IDs
   - Include timestamps using `gNow`
   - Add user ID for ownership tracking
   - Include parent IDs for hierarchical data

2. **Error Handling**
   - Always wrap operations in try-catch blocks
   - Use `TurboResponse` for operation results
   - Provide user-friendly error messages
   - Log errors with proper context

3. **State Management**
   - Check busy state before operations
   - Block updates during critical operations
   - Handle empty states appropriately
   - Clean up resources in dispose

4. **User Feedback**
   - Show confirmation dialogs for destructive actions
   - Display loading states during operations
   - Provide success/error notifications
   - Handle navigation after operations

## Batch Operations

```dart
// Create multiple documents in a batch
final batch = firestore.batch();
final response = await api.createDocInBatch(
  writeable: user,
  writeBatch: batch,
);

// Update multiple documents in a batch
final updateResponse = await api.updateDocInBatch(
  writeable: updatedUser,
  writeBatch: batch,
);

// Delete multiple documents in a batch
final deleteResponse = await api.deleteDocInBatch(
  id: userId,
  writeBatch: batch,
);
```

## Type Definitions

Turbo Firestore API provides type-safe definitions for document operations that automatically handle common fields like IDs, timestamps, and user IDs:

```dart
// Type definition for document creation
typedef CreateDocDef<T> = T Function(TurboAuthVars vars);
// Type definition for document updates
typedef UpdateDocDef<T> = T Function(T current, TurboAuthVars vars);

// Example usage in a service
class UsersService extends TurboCollectionService<User, UsersApi> {
  UsersService({required super.api});

  /// Creates a new user with automatic ID, timestamp and user ID
  Future<TurboResponse<User>> createUser({
    required String name,
    required int age,
  }) {
    return createDoc(
      createDoc: (vars) => User(
        id: vars.id,           // Auto-generated ID
        createdAt: vars.now,   // Current timestamp
        createdBy: vars.userId,// Current user's ID
        name: name,
        age: age,
      ),
    );
  }

  /// Updates user's last active timestamp
  Future<TurboResponse<User>> updateLastActive(String userId) {
    return updateDoc(
      id: userId,
      updateDoc: (current, vars) => User(
        id: current.id,
        createdAt: current.createdAt,
        createdBy: current.createdBy,
        name: current.name,
        age: current.age,
        lastActiveAt: vars.now,     // Current timestamp
        lastUpdatedBy: vars.userId, // Current user's ID
      ),
    );
  }
}
```

## Sync Services

Turbo Firestore API provides three types of sync services for documents:

```dart
// After-sync notifications
class UserDocumentService extends AfSyncTurboDocumentService<User, UserApi> {
  UserDocumentService({required super.api});

  Future<TurboResponse<T>> updateUserName(String id, String newName) {
    return updateDoc(
      id: id,
      updateDoc: (current, vars) => User(
        id: current.id,
        userId: current.userId,
        name: newName,
        age: current.age,
        createdAt: current.createdAt,
        updatedAt: vars.now,
      ),
    );
  }

  @override
  void afterSyncNotifyUpdate(User? doc) {
    // Handle document updates after sync
  }
}

// Before-sync notifications
class ProductDocumentService extends BeSyncTurboDocumentService<Product, ProductApi> {
  ProductDocumentService({required super.api});

  Future<TurboResponse<T>> createProduct(String name, double price) {
    return createDoc(
      createDoc: (vars) => Product(
        id: vars.id,
        userId: vars.userId,
        name: name,
        price: price,
        createdAt: vars.now,
      ),
    );
  }

  @override
  void beforeSyncNotifyUpdate(Product? doc) {
    // Handle document updates before sync
  }
}

// Before and after sync notifications
class OrderDocumentService extends BeAfSyncTurboDocumentService<Order, OrderApi> {
  OrderDocumentService({required super.api});

  Future<TurboResponse<T>> updateOrderStatus(String id, OrderStatus status) {
    return updateDoc(
      id: id,
      updateDoc: (current, vars) => Order(
        id: current.id,
        userId: current.userId,
        items: current.items,
        status: status,
        createdAt: current.createdAt,
        updatedAt: vars.now,
      ),
    );
  }

  @override
  void beforeSyncNotifyUpdate(Order? doc) {
    // Handle document updates before sync
  }

  @override
  void afterSyncNotifyUpdate(Order? doc) {
    // Handle document updates after sync
  }
}
```

## 🧩 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the [LICENSE](LICENSE) file in the root directory of this repository.
