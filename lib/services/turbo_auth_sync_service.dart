import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:loglytics/loglytics.dart';
import 'package:turbo_firestore_api/mixins/turbo_exception_handler.dart';
import 'package:turbo_firestore_api/exceptions/turbo_firestore_exception.dart';

/// A service that synchronizes data with Firebase Authentication state changes.
///
/// Provides automatic data synchronization based on user authentication state:
/// - Starts streaming data when a user signs in
/// - Clears data when user signs out
/// - Handles stream errors with automatic retries
/// - Manages stream lifecycle
///
/// Type Parameters:
/// - [StreamValue] - The type of data being streamed
abstract class TurboAuthSyncService<StreamValue> with TurboExceptionHandler {
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

  // 📍 LOCATOR ------------------------------------------------------------------------------- \\
  // 🧩 DEPENDENCIES -------------------------------------------------------------------------- \\
  // 🎬 INIT & DISPOSE ------------------------------------------------------------------------ \\

  /// Called when a stream error occurs.
  ///
  /// Override this method to handle specific error types.
  /// Parameters:
  /// - [error] - The Firestore exception that occurred
  void onError(TurboFirestoreException error) {
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
            cachedUserId = userId;
            await onAuth?.call(user!);
            _subscription ??= (await stream(user!)).listen(
              (value) async {
                await onData(value, user);
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
            await onData(null, null);
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

  /// Cleans up resources and resets the service state.
  @mustCallSuper
  Future<void> dispose() async {
    _log.warning('Disposing TurboAuthSyncService!');
    await _resetStream();
    _resetRetryTimer();
    _nrOfRetry = 0;
  }

  // 👂 LISTENERS ----------------------------------------------------------------------------- \\
  // ⚡️ OVERRIDES ----------------------------------------------------------------------------- \\
  // 🎩 STATE --------------------------------------------------------------------------------- \\

  /// The ID of the currently authenticated user.
  String? cachedUserId;

  /// Subscription to the data stream.
  StreamSubscription? _subscription;

  /// Subscription to the authentication state stream.
  StreamSubscription? _userSubscription;

  /// Timer for retry attempts.
  Timer? _retryTimer;

  /// Maximum number of retry attempts.
  final _maxNrOfRetry = 20;

  /// Current number of retry attempts.
  int _nrOfRetry = 0;

  // 🛠 UTIL ---------------------------------------------------------------------------------- \\

  /// Logger instance for this service.
  late final _log = Log(location: runtimeType.toString());

  // 🧲 FETCHERS ------------------------------------------------------------------------------ \\
  // 🏗️ HELPERS ------------------------------------------------------------------------------- \\
  // 🪄 MUTATORS ------------------------------------------------------------------------------ \\

  // 🎩 STATE --------------------------------------------------------------------------------- \\

  // 🛠 UTIL ---------------------------------------------------------------------------------- \\

  // 🧲 FETCHERS ------------------------------------------------------------------------------ \\

  /// Returns a stream of data for the authenticated user.
  FutureOr<Stream<StreamValue?>> Function(User user) get stream;

  /// Handles data updates from the stream.
  Future<void> Function(StreamValue? value, User? user) get onData;

  /// Called when a user is authenticated.
  FutureOr<void> Function(User user)? onAuth;

  // 🪄 MUTATORS ------------------------------------------------------------------------------ \\

  /// Resets and reinitialized the stream.
  Future<void> resetAndTryInitialiseStream() async {
    await _resetStream();
    await tryInitialiseStream();
  }

  /// Called when the stream is done.
  void onDone(int nrOfRetry, int maxNrOfRetry) {
    _log.warning('TurboAuthSyncService stream is done!');
  }

  // 🏗️ HELPERS ------------------------------------------------------------------------------- \\

  /// Resets the stream subscriptions.
  Future<void> _resetStream() async {
    await _userSubscription?.cancel();
    _userSubscription = null;
    await _subscription?.cancel();
    _subscription = null;
  }

  /// Resets the retry timer.
  void _resetRetryTimer() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  /// Attempts to retry stream initialization after an error.
  void _tryRetry() {
    if (_nrOfRetry < _maxNrOfRetry) {
      if (_retryTimer?.isActive ?? false) {
        _resetRetryTimer();
        _log.info('Retry reset!');
      }
      _log.info(
        'Initiating stream retry $_nrOfRetry/$_maxNrOfRetry for TurboAuthSyncService in 10 seconds..',
      );
      _retryTimer = Timer(
        const Duration(seconds: 10),
        () {
          _nrOfRetry++;
          _resetStream();
          tryInitialiseStream();
          _retryTimer = null;
        },
      );
    } else {
      _resetStream();
    }
  }

// 📍 LOCATOR ------------------------------------------------------------------------------- \\
}
