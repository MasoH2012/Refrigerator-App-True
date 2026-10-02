import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../data/repositories/household_repository.dart';
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
  Future<HouseholdState> build() async {
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
      // Move the pre-household personal data into the first shared household.
      if (previousDataOwner != null && !previousDataOwner.isHousehold) {
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
      await ref.read(householdRepositoryProvider).join(
            uid: userIdForProfile(profile),
            username: profile.username,
            inviteCode: code,
            password: password,
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

  Future<void> _refresh() async {
    ref.invalidate(inventoryProvider);
    ref.invalidate(shoppingListProvider);
    state = AsyncData(await build());
  }
}
