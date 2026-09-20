import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/repositories/repository_providers.dart';
import '../../../domain/models/shopping_item.dart';
import '../../household/application/household_controller.dart';

final shoppingListProvider =
    AsyncNotifierProvider<ShoppingListController, List<ShoppingItem>>(
  ShoppingListController.new,
);

class ShoppingListController extends AsyncNotifier<List<ShoppingItem>> {
  @override
  Future<List<ShoppingItem>> build() async {
    final owner = ref.watch(householdDataOwnerProvider);
    if (owner == null) return const [];
    return ref.read(shoppingListRepositoryProvider).load(owner);
  }

  Future<void> addItem({required String name, String quantity = '1'}) async {
    final owner = ref.read(householdDataOwnerProvider);
    if (owner == null || name.trim().isEmpty) return;
    final current = state.value ?? const <ShoppingItem>[];
    final existingIndex = current.indexWhere(
      (item) =>
          item.name.trim().toLowerCase() == name.trim().toLowerCase() &&
          !item.checked,
    );
    final next = [...current];
    if (existingIndex >= 0) {
      final existing = next[existingIndex];
      next[existingIndex] = existing.copyWith(
        quantity: '${existing.quantity} + ${quantity.trim()}',
      );
    } else {
      next.add(
        ShoppingItem(
          id: const Uuid().v4(),
          name: name.trim(),
          quantity: quantity.trim(),
          checked: false,
          createdAt: DateTime.now(),
        ),
      );
    }
    await _save(owner, next);
  }

  Future<void> toggle(ShoppingItem item) async {
    final owner = ref.read(householdDataOwnerProvider);
    if (owner == null) return;
    await _save(
      owner,
      [
        for (final value in state.value ?? const <ShoppingItem>[])
          value.id == item.id ? item.copyWith(checked: !item.checked) : value,
      ],
    );
  }

  Future<void> remove(String id) async {
    final owner = ref.read(householdDataOwnerProvider);
    if (owner == null) return;
    await _save(
      owner,
      (state.value ?? const <ShoppingItem>[])
          .where((item) => item.id != id)
          .toList(),
    );
  }

  Future<void> _save(String owner, List<ShoppingItem> items) async {
    state = AsyncData(items);
    await ref.read(shoppingListRepositoryProvider).save(owner, items);
  }
}
