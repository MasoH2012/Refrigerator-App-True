import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../data/repositories/household_repository.dart';
import '../../../data/repositories/household_password_store.dart';
import '../../../domain/models/household.dart';
import '../../../domain/models/data_scope.dart';
import '../../auth/application/auth_controller.dart';
import '../../inventory/application/inventory_controller.dart';
import '../../shopping/application/shopping_list_controller.dart';

final householdProvider =
    AsyncNotifierProvider<HouseholdController, HouseholdState>(
  HouseholdController.new,
);

final householdDataOwnerProvider = Provider<DataScope?>((ref) {
  final profile = ref.watch(authProvider).value?.profile;
  if (profile == null) return null;
  final household = ref.watch(householdProvider).value?.active;
  final uid = userIdForProfile(profile);
  if (household == null) return privateScopeForProfile(profile);
  return DataScope.household(
    uid: uid,
    householdId: household.id,
    legacyOwnerId: profile.username,
  );
});

class HouseholdController extends AsyncNotifier<HouseholdState> {
  @override
  Future<HouseholdState> build() => _loadState();

  Future<HouseholdState> _loadState() async {
    final profile = ref.watch(authProvider).value?.profile;
    if (profile == null) {
      return const HouseholdState(households: [], activeHouseholdId: null);
    }
    final uid = userIdForProfile(profile);
    final repository = ref.read(householdRepositoryProvider);
    final households =
        await repository.loadForUser(uid: uid, username: profile.username);
    final storedActive = await repository.loadActiveId(uid);
    final activeId = households.any((household) => household.id == storedActive)
        ? storedActive
        : null;
    if (activeId == null && storedActive != null) {
      await repository.setActiveId(uid, null);
    }
    return HouseholdState(
      households: households,
      activeHouseholdId: activeId,
    );
  }

  Future<String?> create(String name, String password) async {
    final profile = ref.read(authProvider).value?.profile;
    if (profile == null) return 'Sign in before creating a household.';
    final uid = userIdForProfile(profile);
    try {
      // Do not read householdDataOwnerProvider here: that provider watches
      // householdProvider, so reading it while this notifier is creating a
      // household would create a Riverpod circular dependency.
      final previousHousehold = state.value?.active;
      final previousDataOwner = previousHousehold == null
          ? privateScopeForProfile(profile)
          : DataScope.household(
              uid: uid,
              householdId: previousHousehold.id,
              legacyOwnerId: profile.username,
            );
      final household = await ref.read(householdRepositoryProvider).create(
            uid: uid,
            username: profile.username,
            name: name,
            password: password,
          );
      await _savePassword(uid, household.id, password);
      // Move the pre-household personal data into the first shared household.
      if (!previousDataOwner.isHousehold) {
        final inventory = await ref
            .read(inventoryRepositoryProvider)
            .loadItems(previousDataOwner);
        if (inventory.isNotEmpty) {
          await ref.read(inventoryRepositoryProvider).saveItems(
                DataScope.household(
                  uid: uid,
                  householdId: household.id,
                  legacyOwnerId: profile.username,
                ),
                inventory,
              );
        }
        final shopping = await ref
            .read(shoppingListRepositoryProvider)
            .load(previousDataOwner);
        if (shopping.isNotEmpty) {
          await ref.read(shoppingListRepositoryProvider).save(
                DataScope.household(
                  uid: uid,
                  householdId: household.id,
                  legacyOwnerId: profile.username,
                ),
                shopping,
              );
        }
      }
      await _refresh();
      return null;
    } on HouseholdException catch (error) {
      return error.message;
    } on Object catch (error) {
      return 'Could not create household: $error';
    }
  }

  Future<String?> join(String code, String password) async {
    final profile = ref.read(authProvider).value?.profile;
    if (profile == null) return 'Sign in before joining a household.';
    try {
      final joinedHousehold = await ref.read(householdRepositoryProvider).join(
            uid: userIdForProfile(profile),
            username: profile.username,
            inviteCode: code,
            password: password,
          );
      await _savePassword(
        userIdForProfile(profile),
        joinedHousehold.id,
        password,
      );
      await _refresh();
      return null;
    } on HouseholdException catch (error) {
      return error.message;
    } on Object catch (error) {
      return 'Could not join household: $error';
    }
  }

  Future<String?> switchTo(String householdId) async {
    final profile = ref.read(authProvider).value?.profile;
    if (profile == null) return 'Sign in before switching households.';
    final uid = userIdForProfile(profile);
    final exists =
        state.value?.households.any((item) => item.id == householdId) ?? false;
    if (!exists) return 'That household is no longer available.';
    await ref.read(householdRepositoryProvider).setActiveId(uid, householdId);
    await _refresh();
    return null;
  }

  Future<String?> leave(String householdId) async {
    final profile = ref.read(authProvider).value?.profile;
    if (profile == null) return 'Sign in before leaving a household.';
    try {
      await ref.read(householdRepositoryProvider).leave(
            uid: userIdForProfile(profile),
            username: profile.username,
            householdId: householdId,
          );
      await _refresh();
      return null;
    } on HouseholdException catch (error) {
      return error.message;
    }
  }

  Future<String?> rename(String householdId, String name) async {
    final profile = ref.read(authProvider).value?.profile;
    if (profile == null) return 'Sign in before renaming a household.';
    try {
      await ref.read(householdRepositoryProvider).rename(
            uid: userIdForProfile(profile),
            username: profile.username,
            householdId: householdId,
            name: name,
          );
      await _refresh();
      return null;
    } on HouseholdException catch (error) {
      return error.message;
    }
  }

  Future<String?> changePassword(
    String householdId, {
    required String currentPassword,
    required String newPassword,
  }) async {
    final profile = ref.read(authProvider).value?.profile;
    if (profile == null) return 'Sign in before changing a household password.';
    try {
      await ref.read(householdRepositoryProvider).changePassword(
            uid: userIdForProfile(profile),
            username: profile.username,
            householdId: householdId,
            currentPassword: currentPassword,
            newPassword: newPassword,
          );
      await _savePassword(
        userIdForProfile(profile),
        householdId,
        newPassword,
      );
      await _refresh();
      return null;
    } on HouseholdException catch (error) {
      return error.message;
    } on Object catch (error) {
      return 'Could not change the household password: $error';
    }
  }

  Future<String?> delete(String householdId) async {
    final profile = ref.read(authProvider).value?.profile;
    if (profile == null) return 'Sign in before deleting a household.';
    try {
      await ref.read(householdRepositoryProvider).delete(
            uid: userIdForProfile(profile),
            username: profile.username,
            householdId: householdId,
          );
      await _deleteSavedPassword(userIdForProfile(profile), householdId);
      await _refresh();
      return null;
    } on HouseholdException catch (error) {
      return error.message;
    } on Object catch (error) {
      return 'Could not delete the household: $error';
    }
  }

  Future<String?> loadSavedPassword(String householdId) async {
    final profile = ref.read(authProvider).value?.profile;
    if (profile == null) return null;
    try {
      return await ref.read(householdPasswordStoreProvider).read(
            uid: userIdForProfile(profile),
            householdId: householdId,
          );
    } on Object {
      return null;
    }
  }

  Future<void> _savePassword(
      String uid, String householdId, String password) async {
    try {
      await ref.read(householdPasswordStoreProvider).save(
            uid: uid,
            householdId: householdId,
            password: password.trim(),
          );
    } on Object {
      // Cloud household creation/joining must still succeed if secure storage
      // is temporarily unavailable. The password remains protected by its
      // Firestore hash and can be entered again later.
    }
  }

  Future<void> _deleteSavedPassword(String uid, String householdId) async {
    try {
      await ref.read(householdPasswordStoreProvider).delete(
            uid: uid,
            householdId: householdId,
          );
    } on Object {
      // The household is already archived remotely; a local cleanup failure
      // should not turn a successful delete into a visible error.
    }
  }

  Future<void> _refresh() async {
    // Complete the household provider's own state transition first. If the
    // inventory provider is invalidated while this notifier is still loading,
    // inventory -> householdDataOwner -> household can be evaluated again
    // before the current household operation has finished. Riverpod then sees
    // that as a circular dependency. Refreshing the household state first and
    // scheduling dependent refreshes for the next event-loop turn avoids that
    // re-entrant evaluation.
    state = AsyncData(await _loadState());
    Future<void>.microtask(() {
      ref.invalidate(inventoryProvider);
      ref.invalidate(shoppingListProvider);
    });
  }
}
