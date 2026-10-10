import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/household.dart';
import '../../domain/models/data_scope.dart';
import 'household_repository.dart';
import 'firestore_inventory_repository.dart';
import 'firestore_shopping_list_repository.dart';
import 'preferences_inventory_repository.dart';
import 'shopping_list_repository.dart';

/// Firestore household storage.
///
/// Membership is authoritative in households/{id}/members/{uid}. A small
/// users/{uid}/households/{id} index makes it possible to list a user's
/// households without a collection-group query.
class FirestoreHouseholdRepository implements HouseholdRepository {
  FirestoreHouseholdRepository({
    required SharedPreferences preferences,
    FirebaseFirestore? firestore,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _preferences = preferences,
        _legacy = PreferencesHouseholdRepository(preferences),
        _legacyInventory = PreferencesInventoryRepository(preferences),
        _legacyShopping = PreferencesShoppingListRepository(preferences),
        _cloudInventory = FirestoreInventoryRepository(
          preferences: preferences,
          firestore: firestore,
        ),
        _cloudShopping = FirestoreShoppingListRepository(
          preferences: preferences,
          firestore: firestore,
        );

  final FirebaseFirestore _firestore;
  final SharedPreferences _preferences;
  final PreferencesHouseholdRepository _legacy;
  final PreferencesInventoryRepository _legacyInventory;
  final PreferencesShoppingListRepository _legacyShopping;
  final FirestoreInventoryRepository _cloudInventory;
  final FirestoreShoppingListRepository _cloudShopping;

  @override
  Future<List<Household>> loadForUser({
    required String uid,
    required String username,
  }) async {
    final index = await _userHouseholds(uid).get();
    if (index.docs.isEmpty) await _migrateLegacy(uid: uid, username: username);
    final currentIndex =
        index.docs.isEmpty ? await _userHouseholds(uid).get() : index;
    final households = <Household>[];
    for (final document in currentIndex.docs) {
      final household = await _loadHousehold(document.id);
      if (household != null) households.add(household);
    }
    return households;
  }

  @override
  Future<String?> loadActiveId(String uid) async {
    final snapshot = await _userState(uid).get();
    return snapshot.data()?['activeHouseholdId'] as String?;
  }

  @override
  Future<void> setActiveId(String uid, String? householdId) async {
    await _userState(uid).set({'activeHouseholdId': householdId});
  }

  @override
  Future<Household> create({
    required String uid,
    required String username,
    required String name,
    required String password,
  }) async {
    final trimmedName = name.trim();
    final trimmedPassword = password.trim();
    if (trimmedName.isEmpty) {
      throw const HouseholdException('Enter a household name.');
    }
    if (trimmedPassword.length < 4) {
      throw const HouseholdException(
          'Choose a household password with at least 4 characters.');
    }
    final id = const Uuid().v4();
    final inviteCode = await _newInviteCode();
    final household = Household(
      id: id,
      name: trimmedName,
      inviteCode: inviteCode,
      passwordHash: _hashPassword(trimmedPassword),
      ownerUid: uid,
      ownerUsername: username.trim(),
      members: [username.trim()],
      createdAt: DateTime.now(),
    );
    final batch = _firestore.batch();
    batch.set(_household(id), _householdJson(household));
    batch.set(_member(id, uid), _memberJson(uid, username));
    batch.set(_userHousehold(uid, id), {'householdId': id});
    batch.set(_invite(inviteCode), {
      'householdId': id,
      'passwordHash': household.passwordHash,
    });
    await batch.commit();
    await setActiveId(uid, id);
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
    final invite = await _invite(code).get();
    final inviteData = invite.data();
    if (!invite.exists || inviteData == null) {
      throw const HouseholdException('That invite code was not found.');
    }
    final householdId = inviteData['householdId'] as String?;
    final expectedHash = inviteData['passwordHash'] as String?;
    if (householdId == null || expectedHash == null) {
      throw const HouseholdException('That invite is no longer valid.');
    }
    if (expectedHash != _hashPassword(trimmedPassword)) {
      throw const HouseholdException('That household password is incorrect.');
    }
    final batch = _firestore.batch();
    batch.set(
      _member(householdId, uid),
      _memberJson(
        uid,
        username,
        inviteCode: code,
        passwordHash: expectedHash,
      ),
    );
    batch.set(_userHousehold(uid, householdId), {'householdId': householdId});
    await batch.commit();
    final household = await _loadHousehold(householdId);
    if (household == null) {
      throw const HouseholdException('That household could not be loaded.');
    }
    await setActiveId(uid, householdId);
    return household;
  }

  @override
  Future<void> leave({
    required String uid,
    required String username,
    required String householdId,
  }) async {
    final household = await _loadHousehold(householdId);
    if (household == null) return;
    if (household.ownerUid == uid) {
      throw const HouseholdException(
          'The household owner cannot leave. Transfer ownership first.');
    }
    final batch = _firestore.batch();
    batch.delete(_member(householdId, uid));
    batch.delete(_userHousehold(uid, householdId));
    await batch.commit();
    if (await loadActiveId(uid) == householdId) await setActiveId(uid, null);
  }

  @override
  Future<void> rename({
    required String uid,
    required String username,
    required String householdId,
    required String name,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const HouseholdException('Enter a household name.');
    }
    await _household(householdId).update({'name': trimmedName});
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
    final household = await _loadHousehold(householdId);
    if (household == null) {
      throw const HouseholdException('Household not found.');
    }
    if (household.ownerUid != uid) {
      throw const HouseholdException(
          'Only the household owner can change its password.');
    }
    if (household.passwordHash != _hashPassword(current)) {
      throw const HouseholdException(
          'The current household password is incorrect.');
    }
    final nextHash = _hashPassword(next);
    final batch = _firestore.batch();
    batch.update(_household(householdId), {'passwordHash': nextHash});
    batch.update(_invite(household.inviteCode), {'passwordHash': nextHash});
    await batch.commit();
  }

  @override
  Future<void> delete({
    required String uid,
    required String username,
    required String householdId,
  }) async {
    final household = await _loadHousehold(householdId);
    if (household == null) return;
    if (household.ownerUid != uid) {
      throw const HouseholdException('Only the household owner can delete it.');
    }

    // Archive instead of physically deleting shared data. This removes the
    // household from active lists and blocks access through Firestore rules,
    // while keeping data recoverable for a future restore flow.
    await _household(householdId).update({
      'archivedAt': FieldValue.serverTimestamp(),
    });
    await _userHousehold(uid, householdId).delete();
    if (await loadActiveId(uid) == householdId) {
      await setActiveId(uid, null);
    }
  }

  Future<Household?> _loadHousehold(String id) async {
    final snapshot = await _household(id).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;
    if (data['archivedAt'] != null) return null;
    final members = await _members(id).get();
    final names = members.docs
        .map((doc) => doc.data()['username'] as String? ?? doc.id)
        .toList();
    return Household.fromJson({
      ...data,
      'id': id,
      'members': names,
    }.cast<String, Object?>());
  }

  Future<void> _migrateLegacy({
    required String uid,
    required String username,
  }) async {
    final marker = 'firebase.migration.households.v1.$uid';
    if (_preferences.getBool(marker) == true) return;
    final local = await _legacy.loadForUser(uid: uid, username: username);
    final legacyActiveId = _legacy.loadLegacyActiveId(username);
    String? migratedActiveId;
    for (final household in local) {
      // A legacy member list only contains usernames, so only the legacy
      // owner can be migrated safely to a Firebase UID-owned household.
      if (household.ownerUsername.trim().toLowerCase() !=
          username.trim().toLowerCase()) {
        continue;
      }
      final migrated = household.copyWith(ownerUid: uid);
      final batch = _firestore.batch();
      batch.set(_household(migrated.id), _householdJson(migrated));
      batch.set(_member(migrated.id, uid), _memberJson(uid, username));
      batch.set(_userHousehold(uid, migrated.id), {'householdId': migrated.id});
      batch.set(_invite(migrated.inviteCode), {
        'householdId': migrated.id,
        'passwordHash': migrated.passwordHash,
      });
      await batch.commit();
      final scope = DataScope.household(
        uid: uid,
        householdId: migrated.id,
        legacyOwnerId: username,
      );
      final inventory = await _legacyInventory.loadItems(scope);
      if (inventory.isNotEmpty) {
        await _cloudInventory.saveItems(scope, inventory);
      }
      final shopping = await _legacyShopping.load(scope);
      if (shopping.isNotEmpty) {
        await _cloudShopping.save(scope, shopping);
      }
      if (legacyActiveId == household.id) migratedActiveId = migrated.id;
    }
    await _preferences.setBool(marker, true);
    if (migratedActiveId != null) await setActiveId(uid, migratedActiveId);
  }

  Map<String, Object?> _householdJson(Household household) => {
        'name': household.name,
        'inviteCode': household.inviteCode,
        'passwordHash': household.passwordHash,
        'ownerUid': household.ownerUid,
        'ownerUsername': household.ownerUsername,
        'createdAt': household.createdAt.toIso8601String(),
        if (household.archivedAt != null)
          'archivedAt': household.archivedAt!.toIso8601String(),
      };

  Map<String, Object?> _memberJson(
    String uid,
    String username, {
    String? inviteCode,
    String? passwordHash,
  }) =>
      {
        'uid': uid,
        'username': username.trim(),
        'joinedAt': FieldValue.serverTimestamp(),
        if (inviteCode != null) 'inviteCode': inviteCode,
        if (passwordHash != null) 'passwordHash': passwordHash,
      };

  CollectionReference<Map<String, dynamic>> _userHouseholds(String uid) =>
      _firestore.collection('users').doc(uid).collection('households');

  DocumentReference<Map<String, dynamic>> _userHousehold(
          String uid, String id) =>
      _userHouseholds(uid).doc(id);

  DocumentReference<Map<String, dynamic>> _userState(String uid) => _firestore
      .collection('users')
      .doc(uid)
      .collection('householdState')
      .doc('main');

  DocumentReference<Map<String, dynamic>> _household(String id) =>
      _firestore.collection('households').doc(id);

  CollectionReference<Map<String, dynamic>> _members(String id) =>
      _household(id).collection('members');

  DocumentReference<Map<String, dynamic>> _member(String id, String uid) =>
      _members(id).doc(uid);

  DocumentReference<Map<String, dynamic>> _invite(String code) =>
      _firestore.collection('householdInvites').doc(code);

  Future<String> _newInviteCode() async {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    for (;;) {
      final code =
          List.generate(6, (_) => alphabet[random.nextInt(alphabet.length)])
              .join();
      if (!(await _invite(code).get()).exists) return code;
    }
  }

  String _hashPassword(String password) =>
      sha256.convert(utf8.encode(password)).toString();
}
