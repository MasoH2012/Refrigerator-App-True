import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../data/repositories/household_repository.dart';
import '../../../domain/models/household.dart';
import '../../auth/application/auth_controller.dart';
import '../../inventory/application/inventory_controller.dart';
import '../../shopping/application/shopping_list_controller.dart';

final householdProvider =
    AsyncNotifierProvider<HouseholdController, HouseholdState>(
  HouseholdController.new,
);

final householdDataOwnerProvider = Provider<String?>((ref) {
  final profile = ref.watch(authProvider).value?.profile;
  if (profile == null) return null;
  final household = ref.watch(householdProvider).value?.active;
  return household?.id ?? profile.username;
});

class HouseholdController extends AsyncNotifier<HouseholdState> {
  @override
  Future<HouseholdState> build() async {
    final username = ref.watch(authProvider).value?.profile?.username;
    if (username == null) {
      return const HouseholdState(households: [], activeHouseholdId: null);
    }
    final repository = ref.read(householdRepositoryProvider);
    final households = repository.loadForUser(username);
    final storedActive = repository.loadActiveId(username);
    final activeId = households.any((household) => household.id == storedActive)
        ? storedActive
        : null;
    if (activeId == null && storedActive != null) {
      await repository.setActiveId(username, null);
    }
    return HouseholdState(
      households: households,
      activeHouseholdId: activeId,
    );
  }

  Future<String?> create(String name, String password) async {
    final username = ref.read(authProvider).value?.profile?.username;
    if (username == null) return 'Sign in before creating a household.';
    try {
      final previousDataOwner = ref.read(householdDataOwnerProvider);
      final household = await ref.read(householdRepositoryProvider).create(
            username: username,
            name: name,
            password: password,
          );
      // Move the pre-household personal data into the first shared household.
      if (previousDataOwner == username) {
        final inventory =
            await ref.read(inventoryRepositoryProvider).loadItems(username);
        if (inventory.isNotEmpty) {
          await ref
              .read(inventoryRepositoryProvider)
              .saveItems(household.id, inventory);
        }
        final shopping =
            await ref.read(shoppingListRepositoryProvider).load(username);
        if (shopping.isNotEmpty) {
          await ref
              .read(shoppingListRepositoryProvider)
              .save(household.id, shopping);
        }
      }
      await _refresh();
      return null;
    } on HouseholdException catch (error) {
      return error.message;
    }
  }

  Future<String?> join(String code, String password) async {
    final username = ref.read(authProvider).value?.profile?.username;
    if (username == null) return 'Sign in before joining a household.';
    try {
      await ref.read(householdRepositoryProvider).join(
            username: username,
            inviteCode: code,
            password: password,
          );
      await _refresh();
      return null;
    } on HouseholdException catch (error) {
      return error.message;
    }
  }

  Future<String?> switchTo(String householdId) async {
    final username = ref.read(authProvider).value?.profile?.username;
    if (username == null) return 'Sign in before switching households.';
    final exists =
        state.value?.households.any((item) => item.id == householdId) ?? false;
    if (!exists) return 'That household is no longer available.';
    await ref
        .read(householdRepositoryProvider)
        .setActiveId(username, householdId);
    await _refresh();
    return null;
  }

  Future<String?> leave(String householdId) async {
    final username = ref.read(authProvider).value?.profile?.username;
    if (username == null) return 'Sign in before leaving a household.';
    try {
      await ref.read(householdRepositoryProvider).leave(
            username: username,
            householdId: householdId,
          );
      await _refresh();
      return null;
    } on HouseholdException catch (error) {
      return error.message;
    }
  }

  Future<String?> rename(String householdId, String name) async {
    final username = ref.read(authProvider).value?.profile?.username;
    if (username == null) return 'Sign in before renaming a household.';
    try {
      await ref.read(householdRepositoryProvider).rename(
            username: username,
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
