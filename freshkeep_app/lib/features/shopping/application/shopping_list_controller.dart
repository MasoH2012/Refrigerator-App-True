import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/repositories/repository_providers.dart';
import '../../../domain/models/data_scope.dart';
import '../../../domain/models/shopping_item.dart';
import '../../household/application/household_controller.dart';

final shoppingListProvider =
    AsyncNotifierProvider<ShoppingListController, List<ShoppingItem>>(
  ShoppingListController.new,
);

class ShoppingListController extends AsyncNotifier<List<ShoppingItem>> {
  @override
  Future<List<ShoppingItem>> build() async {
    final scope = ref.watch(householdDataOwnerProvider);
    if (scope == null) return const [];
    return ref.read(shoppingListRepositoryProvider).load(scope);
  }

  Future<void> addItem({required String name, String quantity = '1'}) async {
    final scope = ref.read(householdDataOwnerProvider);
    if (scope == null || name.trim().isEmpty) return;
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
    await _save(scope, next);
  }

  Future<void> toggle(ShoppingItem item) async {
    final scope = ref.read(householdDataOwnerProvider);
    if (scope == null) return;
    await _save(
      scope,
      [
        for (final value in state.value ?? const <ShoppingItem>[])
          value.id == item.id ? item.copyWith(checked: !item.checked) : value,
      ],
    );
  }

  Future<void> remove(String id) async {
    final scope = ref.read(householdDataOwnerProvider);
    if (scope == null) return;
    await _save(
      scope,
      (state.value ?? const <ShoppingItem>[])
          .where((item) => item.id != id)
          .toList(),
    );
  }

  Future<void> _save(DataScope scope, List<ShoppingItem> items) async {
    state = AsyncData(items);
    await ref.read(shoppingListRepositoryProvider).save(scope, items);
  }
}
