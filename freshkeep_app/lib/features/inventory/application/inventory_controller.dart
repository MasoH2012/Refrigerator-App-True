import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/repositories/inventory_repository.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../domain/models/food_item.dart';
import '../../auth/application/auth_controller.dart';

final inventoryProvider =
    AsyncNotifierProvider<InventoryController, List<FoodItem>>(
  InventoryController.new,
);

class InventoryController extends AsyncNotifier<List<FoodItem>> {
  InventoryRepository get _repository => ref.read(inventoryRepositoryProvider);

  @override
  Future<List<FoodItem>> build() async {
    final ownerId = ref.watch(authProvider).valueOrNull?.profile?.username;
    if (ownerId == null) return const [];
    return _sorted(await _repository.loadItems(ownerId));
  }

  Future<void> addItem({
    required String name,
    required DateTime expirationDate,
    required FoodCategory category,
    required String quantity,
    required FridgeZone zone,
  }) async {
    final current = state.valueOrNull ?? const <FoodItem>[];
    final ownerId = ref.read(authProvider).valueOrNull?.profile?.username;
    if (ownerId == null) return;
    final next = _sorted([
      ...current,
      FoodItem(
        id: const Uuid().v4(),
        name: name.trim(),
        expirationDate: expirationDate,
        category: category,
        quantity: quantity.trim(),
        zone: zone,
        createdAt: DateTime.now(),
      ),
    ]);
    state = AsyncData(next);
    await _repository.saveItems(ownerId, next);
  }

  Future<void> removeItem(String id) async {
    final ownerId = ref.read(authProvider).valueOrNull?.profile?.username;
    if (ownerId == null) return;
    final next = (state.valueOrNull ?? const <FoodItem>[])
        .where((item) => item.id != id)
        .toList();
    state = AsyncData(next);
    await _repository.saveItems(ownerId, next);
  }

  List<FoodItem> _sorted(List<FoodItem> items) =>
      [...items]..sort((a, b) => a.expirationDate.compareTo(b.expirationDate));
}
