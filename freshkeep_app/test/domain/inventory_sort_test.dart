import 'package:flutter_test/flutter_test.dart';
import 'package:freshkeep_app/domain/models/food_item.dart';
import 'package:freshkeep_app/features/inventory/application/inventory_sort.dart';

void main() {
  final now = DateTime(2026, 8, 16);
  final items = [
    _item('Milk', FoodCategory.dairy, now.add(const Duration(days: 5))),
    _item('Apple', FoodCategory.produce, now.add(const Duration(days: 2))),
    _item('Chicken', FoodCategory.protein, now.add(const Duration(days: 1))),
  ];

  test('sorts by soonest and latest expiration', () {
    expect(
      sortFoodItems(items, InventorySortOrder.expirationSoonest)
          .map((item) => item.name),
      ['Chicken', 'Apple', 'Milk'],
    );
    expect(
      sortFoodItems(items, InventorySortOrder.expirationLatest)
          .map((item) => item.name),
      ['Milk', 'Apple', 'Chicken'],
    );
  });

  test('sorts by name and category', () {
    expect(
      sortFoodItems(items, InventorySortOrder.nameAscending)
          .map((item) => item.name),
      ['Apple', 'Chicken', 'Milk'],
    );
    expect(
      sortFoodItems(items, InventorySortOrder.categoryAscending)
          .map((item) => item.name),
      ['Milk', 'Apple', 'Chicken'],
    );
  });
}

FoodItem _item(String name, FoodCategory category, DateTime expirationDate) {
  return FoodItem(
    id: name,
    name: name,
    expirationDate: expirationDate,
    category: category,
    quantity: '1',
    zone: FridgeZone.middleShelf,
    createdAt: DateTime(2026, 8, 1),
  );
}
