/// An abstract class that defines the core variables required for Turbo Firestore documents.
///
/// Every Turbo Firestore document must contain:
/// * [id] - The unique identifier for the document
/// * [now] - The timestamp when the document was created/updated
/// * [userId] - The ID of the user who owns/created the document
abstract class TurboVars {
  const TurboVars({
    required this.id,
    required this.now,
    required this.userId,
  });

  final String id;
  final DateTime now;
  final String userId;
}
