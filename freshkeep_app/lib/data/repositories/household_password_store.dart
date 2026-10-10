import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final householdPasswordStoreProvider = Provider<HouseholdPasswordStore>(
  (ref) => HouseholdPasswordStore(),
);

/// Stores household passwords only on the current device.
///
/// Firestore continues to store a one-way hash for joining and verification.
/// The raw password is never uploaded or written to SharedPreferences.
class HouseholdPasswordStore {
  HouseholdPasswordStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _prefix = 'freshkeep.householdPassword.v1';
  final FlutterSecureStorage _storage;

  Future<void> save({
    required String uid,
    required String householdId,
    required String password,
  }) {
    return _storage.write(
      key: _key(uid, householdId),
      value: password,
    );
  }

  Future<String?> read({
    required String uid,
    required String householdId,
  }) {
    return _storage.read(key: _key(uid, householdId));
  }

  Future<void> delete({
    required String uid,
    required String householdId,
  }) {
    return _storage.delete(key: _key(uid, householdId));
  }

  String _key(String uid, String householdId) =>
      '$_prefix.${uid.trim()}.$householdId';
}
