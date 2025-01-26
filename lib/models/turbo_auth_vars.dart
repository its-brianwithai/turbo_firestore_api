import 'package:turbo_firestore_api/models/turbo_api_vars.dart';

/// An abstract class that defines the core variables required for Turbo Firestore documents.
///
/// [id] - The unique identifier for the document
/// [now] - The timestamp when the document was created/updated
/// [userId] - The ID of the user who owns/created the document
class TurboAuthVars extends TurboApiVars {
  const TurboAuthVars({
    required super.id,
    required super.now,
    required this.userId,
  });

  final String? userId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TurboAuthVars && runtimeType == other.runtimeType && userId == other.userId;

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() {
    return 'TurboAuthVars{userId: $userId}';
  }
}
