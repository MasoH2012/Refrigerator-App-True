import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/food_item.dart';
import '../../../domain/models/fridge_organization.dart';
import '../../../domain/models/refrigerator_model.dart';
import '../../auth/application/auth_controller.dart';
import '../../inventory/application/inventory_controller.dart';
import '../../household/application/household_controller.dart';
import '../data/fridge_organization_service.dart';

final fridgeOrganizationServiceProvider = Provider<FridgeOrganizationService>(
  (ref) => FridgeOrganizationService(),
);

final fridgeOrganizationProvider = AsyncNotifierProvider<
    FridgeOrganizationController, FridgeOrganizationPlan?>(
  FridgeOrganizationController.new,
);

class FridgeOrganizationController
    extends AsyncNotifier<FridgeOrganizationPlan?> {
  @override
  Future<FridgeOrganizationPlan?> build() async => null;

  Future<void> generate() async {
    final profile = ref.read(authProvider).value?.profile;
    final household = ref.read(householdProvider).value?.active;
    final modelId = household?.refrigeratorModel.isNotEmpty == true
        ? household!.refrigeratorModel
        : profile?.refrigeratorModel ?? '';
    final refrigerator = RefrigeratorCatalog.byId(modelId);
    if (refrigerator == null) {
      state = AsyncError(
        const FridgeOrganizationException(
            'Select a supported refrigerator model first.'),
        StackTrace.current,
      );
      return;
    }
    final items = (await ref.read(inventoryProvider.future))
        .where((item) => item.storageLocation == StorageLocation.fridge)
        .toList();
    if (items.isEmpty) {
      state = AsyncError(
        const FridgeOrganizationException(
            'Add food to your fridge before organizing it.'),
        StackTrace.current,
      );
      return;
    }
    state = const AsyncLoading<FridgeOrganizationPlan?>();
    try {
      final plan = await ref.read(fridgeOrganizationServiceProvider).organize(
            items: items,
            refrigerator: refrigerator,
          );
      state = AsyncData(plan);
    } on Object catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> applyPlan(FridgeOrganizationPlan plan) async {
    final assignments = {
      for (final assignment in plan.assignments)
        assignment.itemId: assignment.zone,
    };
    final current = await ref.read(inventoryProvider.future);
    final updated = current
        .map((item) => item.copyWith(zone: assignments[item.id] ?? item.zone))
        .toList();
    final inventory = ref.read(inventoryProvider.notifier);
    await inventory.replaceItems(updated);
  }
}
