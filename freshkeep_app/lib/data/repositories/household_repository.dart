import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/household.dart';

abstract interface class HouseholdRepository {
  Future<List<Household>> loadForUser(
      {required String uid, required String username});
  Future<String?> loadActiveId(String uid);
  Future<void> setActiveId(String uid, String? householdId);
  Future<Household> create(
      {required String uid,
      required String username,
      required String name,
      required String password});
  Future<Household> join(
      {required String uid,
      required String username,
      required String inviteCode,
      required String password});
  Future<void> leave(
      {required String uid,
      required String username,
      required String householdId});
  Future<void> rename(
      {required String uid,
      required String username,
      required String householdId,
      required String name});
  Future<void> changePassword({
    required String uid,
    required String username,
    required String householdId,
    required String currentPassword,
    required String newPassword,
  });
  Future<void> delete({
    required String uid,
    required String username,
    required String householdId,
  });
}

class PreferencesHouseholdRepository implements HouseholdRepository {
  PreferencesHouseholdRepository(this._preferences);

  static const _householdsKey = 'households.v1';
  final SharedPreferences _preferences;

  @override
  Future<List<Household>> loadForUser(
      {required String uid, required String username}) async {
    final normalized = _normalize(username);
    return _readAll()
        .where((household) => household.members.any(
              (member) => _normalize(member) == normalized,
            ))
        .toList();
  }

  @override
  Future<String?> loadActiveId(String uid) async =>
      _preferences.getString(_activeKey(uid));

  String? loadLegacyActiveId(String username) =>
      _preferences.getString(_activeKey(username));

  @override
  Future<void> setActiveId(String uid, String? householdId) async {
    if (householdId == null) {
      await _preferences.remove(_activeKey(uid));
    } else {
      await _preferences.setString(_activeKey(uid), householdId);
    }
  }

  @override
  Future<Household> create({
    required String uid,
    required String username,
    required String name,
    required String password,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const HouseholdException('Enter a household name.');
    }
    final trimmedPassword = password.trim();
    if (trimmedPassword.length < 4) {
      throw const HouseholdException(
          'Choose a household password with at least 4 characters.');
    }
    final households = _readAll();
    final household = Household(
      id: const Uuid().v4(),
      name: trimmedName,
      inviteCode: _newInviteCode(households),
      passwordHash: _hashPassword(trimmedPassword),
      ownerUid: uid,
      ownerUsername: username.trim(),
      members: [username.trim()],
      createdAt: DateTime.now(),
    );
    await _writeAll([...households, household]);
    await setActiveId(uid, household.id);
    return household;
  }

  @override
  Future<Household> join({
    required String uid,
    required String username,
    required String inviteCode,
    required String password,
  }) async {
    final code = inviteCode.trim().toUpperCase();
    final trimmedPassword = password.trim();
    if (trimmedPassword.length < 4) {
      throw const HouseholdException(
          'Choose a household password with at least 4 characters.');
    }
    final households = _readAll();
    final index =
        households.indexWhere((household) => household.inviteCode == code);
    if (index < 0) {
      throw const HouseholdException('That invite code was not found.');
    }
    final household = households[index];
    if (household.passwordHash.isNotEmpty &&
        household.passwordHash != _hashPassword(trimmedPassword)) {
      throw const HouseholdException('That household password is incorrect.');
    }
    final alreadyMember = household.members.any(
      (member) => _normalize(member) == _normalize(username),
    );
    final updated = alreadyMember
        ? household
        : household.copyWith(members: [...household.members, username.trim()]);
    if (!alreadyMember) {
      households[index] = updated;
      await _writeAll(households);
    }
    await setActiveId(uid, updated.id);
    return updated;
  }

  @override
  Future<void> leave(
      {required String uid,
      required String username,
      required String householdId}) async {
    final households = _readAll();
    final index =
        households.indexWhere((household) => household.id == householdId);
    if (index < 0) return;
    final household = households[index];
    if (_normalize(household.ownerUsername) == _normalize(username)) {
      throw const HouseholdException(
          'The household owner cannot leave. Transfer ownership first.');
    }
    households[index] = household.copyWith(
      members: household.members
          .where((member) => _normalize(member) != _normalize(username))
          .toList(),
    );
    await _writeAll(households);
    if (await loadActiveId(uid) == householdId) {
      await setActiveId(uid, null);
    }
  }

  @override
  Future<void> rename(
      {required String uid,
      required String username,
      required String householdId,
      required String name}) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const HouseholdException('Enter a household name.');
    }
    final households = _readAll();
    final index =
        households.indexWhere((household) => household.id == householdId);
    if (index < 0) throw const HouseholdException('Household not found.');
    final household = households[index];
    if (_normalize(household.ownerUsername) != _normalize(username)) {
      throw const HouseholdException('Only the household owner can rename it.');
    }
    households[index] = household.copyWith(name: trimmedName);
    await _writeAll(households);
  }

  @override
  Future<void> changePassword({
    required String uid,
    required String username,
    required String householdId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final current = currentPassword.trim();
    final next = newPassword.trim();
    if (current.length < 4 || next.length < 4) {
      throw const HouseholdException(
          'Household passwords must be at least 4 characters.');
    }
    final households = _readAll();
    final index =
        households.indexWhere((household) => household.id == householdId);
    if (index < 0) throw const HouseholdException('Household not found.');
    final household = households[index];
    if (_normalize(household.ownerUsername) != _normalize(username)) {
      throw const HouseholdException(
          'Only the household owner can change its password.');
    }
    if (household.passwordHash != _hashPassword(current)) {
      throw const HouseholdException(
          'The current household password is incorrect.');
    }
    households[index] = household.copyWith(passwordHash: _hashPassword(next));
    await _writeAll(households);
  }

  @override
  Future<void> delete({
    required String uid,
    required String username,
    required String householdId,
  }) async {
    final households = _readAll();
    final index =
        households.indexWhere((household) => household.id == householdId);
    if (index < 0) return;
    final household = households[index];
    if (_normalize(household.ownerUsername) != _normalize(username)) {
      throw const HouseholdException('Only the household owner can delete it.');
    }
    households.removeAt(index);
    await _writeAll(households);
    if (await loadActiveId(uid) == householdId) {
      await setActiveId(uid, null);
    }
  }

  List<Household> _readAll() {
    final encoded = _preferences.getString(_householdsKey);
    if (encoded == null) return [];
    try {
      final decoded = jsonDecode(encoded) as List<dynamic>;
      return decoded
          .map((item) =>
              Household.fromJson((item as Map).cast<String, Object?>()))
          .toList();
    } on Object {
      return [];
    }
  }

  Future<void> _writeAll(List<Household> households) => _preferences.setString(
        _householdsKey,
        jsonEncode(households.map((household) => household.toJson()).toList()),
      );

  String _newInviteCode(List<Household> households) {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    String code;
    do {
      code = List.generate(6, (_) => alphabet[random.nextInt(alphabet.length)])
          .join();
    } while (households.any((household) => household.inviteCode == code));
    return code;
  }

  String _activeKey(String username) =>
      'household.active.v1.${_normalize(username)}';

  String _normalize(String username) => username.trim().toLowerCase();

  String _hashPassword(String password) =>
      sha256.convert(utf8.encode(password)).toString();
}

class HouseholdException implements Exception {
  const HouseholdException(this.message);
  final String message;
  @override
  String toString() => message;
}
