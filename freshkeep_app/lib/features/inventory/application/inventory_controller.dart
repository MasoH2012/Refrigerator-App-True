import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/repositories/inventory_repository.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../domain/models/food_item.dart';
import '../../household/application/household_controller.dart';

final inventoryProvider =
    AsyncNotifierProvider<InventoryController, List<FoodItem>>(
  InventoryController.new,
);

class InventoryController extends AsyncNotifier<List<FoodItem>> {
  InventoryRepository get _repository => ref.read(inventoryRepositoryProvider);

  @override
  Future<List<FoodItem>> build() async {
    final scope = ref.watch(householdDataOwnerProvider);
    if (scope == null) return const [];
    final loaded = await _repository.loadItems(scope);
    final merged = _mergeDuplicateItems(loaded);
    if (merged.length != loaded.length) {
      await _repository.saveItems(scope, merged);
    }
    return _sorted(merged);
  }

  Future<void> addItem({
    required String name,
    required DateTime expirationDate,
    required FoodCategory category,
    required String quantity,
    required FridgeZone zone,
    StorageLocation storageLocation = StorageLocation.fridge,
  }) async {
    final current = state.value ?? const <FoodItem>[];
    final scope = ref.read(householdDataOwnerProvider);
    if (scope == null) return;
    final next = _sorted(_mergeDuplicateItems([
      ...current,
      FoodItem(
        id: const Uuid().v4(),
        name: name.trim(),
        expirationDate: expirationDate,
        category: category,
        quantity: quantity.trim(),
        zone: zone,
        storageLocation: storageLocation,
        createdAt: DateTime.now(),
      ),
    ]));
    state = AsyncData(next);
    await _repository.saveItems(scope, next);
  }

  Future<void> updateItem(FoodItem updatedItem) async {
    final scope = ref.read(householdDataOwnerProvider);
    if (scope == null) return;
    final current = state.value ?? const <FoodItem>[];
    final next = _sorted(
      _mergeDuplicateItems([
        for (final item in current)
          item.id == updatedItem.id ? updatedItem : item,
      ]),
    );
    state = AsyncData(next);
    await _repository.saveItems(scope, next);
  }

  Future<void> removeItem(String id) async {
    final scope = ref.read(householdDataOwnerProvider);
    if (scope == null) return;
    final next = (state.value ?? const <FoodItem>[])
        .where((item) => item.id != id)
        .toList();
    state = AsyncData(next);
    await _repository.saveItems(scope, next);
  }

  Future<void> removeQuantity(String id, double amount) async {
    if (amount <= 0) return;
    final scope = ref.read(householdDataOwnerProvider);
    if (scope == null) return;
    final current = state.value ?? const <FoodItem>[];
    final item = current.where((value) => value.id == id).firstOrNull;
    if (item == null) return;
    final match =
        RegExp(r'^\s*(\d+(?:\.\d+)?)\s*(.*)$').firstMatch(item.quantity);
    if (match == null) {
      await removeItem(id);
      return;
    }
    final available = double.parse(match.group(1)!);
    if (amount >= available) {
      await removeItem(id);
      return;
    }
    final remaining = available - amount;
    final formatted = remaining == remaining.roundToDouble()
        ? remaining.toInt().toString()
        : remaining.toString();
    final unit = match.group(2)!.trim();
    final updatedItem = item.copyWith(
      quantity: unit.isEmpty ? formatted : '$formatted $unit',
    );
    await replaceItems([
      for (final value in current) value.id == id ? updatedItem : value,
    ]);
  }

  Future<void> replaceItems(List<FoodItem> items) async {
    final scope = ref.read(householdDataOwnerProvider);
    if (scope == null) return;
    final next = _sorted(items);
    state = AsyncData(next);
    await _repository.saveItems(scope, next);
  }

  List<FoodItem> _sorted(List<FoodItem> items) =>
      [...items]..sort((a, b) => a.expirationDate.compareTo(b.expirationDate));

  List<FoodItem> _mergeDuplicateItems(List<FoodItem> items) {
    final merged = <String, FoodItem>{};
    for (final item in items) {
      final key = _duplicateKey(item);
      final previous = merged[key];
      if (previous == null) {
        merged[key] = item;
        continue;
      }
      merged[key] = FoodItem(
        id: previous.id,
        name: previous.name,
        expirationDate: previous.expirationDate,
        category: previous.category,
        quantity: _combineQuantities(previous.quantity, item.quantity),
        zone: previous.zone,
        imageUrl: previous.imageUrl ?? item.imageUrl,
        createdAt: previous.createdAt,
      );
    }
    return merged.values.toList();
  }

  String _duplicateKey(FoodItem item) {
    final date = item.expirationDate;
    return '${item.storageLocation.name}|${item.name.trim().toLowerCase()}|${date.year}-${date.month}-${date.day}';
  }

  String _combineQuantities(String first, String second) {
    final firstMatch = RegExp(r'^\s*(\d+(?:\.\d+)?)\s*(.*)$').firstMatch(first);
    final secondMatch =
        RegExp(r'^\s*(\d+(?:\.\d+)?)\s*(.*)$').firstMatch(second);
    if (firstMatch != null && secondMatch != null) {
      final firstUnit = firstMatch.group(2)!.trim();
      final secondUnit = secondMatch.group(2)!.trim();
      if (firstUnit.toLowerCase() == secondUnit.toLowerCase()) {
        final total = double.parse(firstMatch.group(1)!) +
            double.parse(secondMatch.group(1)!);
        final formatted = total == total.roundToDouble()
            ? total.toInt().toString()
            : total.toString();
        return firstUnit.isEmpty ? formatted : '$formatted $firstUnit';
      }
    }
    return '$first + $second';
  }
}
