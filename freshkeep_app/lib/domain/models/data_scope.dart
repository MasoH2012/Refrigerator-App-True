import 'user_profile.dart';

/// Identifies where user-owned data is stored.
///
/// A private scope is keyed by the authenticated Firebase UID. A household
/// scope is keyed by the household document ID, while [uid] remains available
/// for authentication and rule-aware repository operations.
class DataScope {
  const DataScope.private({required this.uid, this.legacyOwnerId})
      : householdId = null;

  const DataScope.household({
    required this.uid,
    required this.householdId,
    this.legacyOwnerId,
  });

  final String uid;
  final String? householdId;

  /// The old username key used by the pre-Firebase migration source.
  final String? legacyOwnerId;

  bool get isHousehold => householdId != null;
}

String userIdForProfile(UserProfile profile) =>
    profile.firebaseUid?.trim().isNotEmpty == true
        ? profile.firebaseUid!.trim()
        : profile.username.trim();

DataScope privateScopeForProfile(UserProfile profile) => DataScope.private(
      uid: userIdForProfile(profile),
      legacyOwnerId: profile.username,
    );
