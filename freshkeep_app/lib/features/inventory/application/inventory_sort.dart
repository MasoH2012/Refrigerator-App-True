import '../../../domain/models/food_item.dart';

enum InventorySortOrder {
  expirationSoonest,
  expirationLatest,
  nameAscending,
  categoryAscending,
}

extension InventorySortOrderLabel on InventorySortOrder {
  String get label => switch (this) {
        InventorySortOrder.expirationSoonest => 'Expiration: soonest first',
        InventorySortOrder.expirationLatest => 'Expiration: latest first',
        InventorySortOrder.nameAscending => 'Name: A–Z',
        InventorySortOrder.categoryAscending => 'Category: A–Z',
      };

  String get shortLabel => switch (this) {
        InventorySortOrder.expirationSoonest => 'soonest expiration',
        InventorySortOrder.expirationLatest => 'latest expiration',
        InventorySortOrder.nameAscending => 'name A–Z',
        InventorySortOrder.categoryAscending => 'category A–Z',
      };
}

List<FoodItem> sortFoodItems(
  Iterable<FoodItem> items,
  InventorySortOrder order,
) {
  final result = items.toList();
  result.sort((left, right) {
    final comparison = switch (order) {
      InventorySortOrder.expirationSoonest =>
        left.expirationDate.compareTo(right.expirationDate),
      InventorySortOrder.expirationLatest =>
        right.expirationDate.compareTo(left.expirationDate),
      InventorySortOrder.nameAscending =>
        left.name.toLowerCase().compareTo(right.name.toLowerCase()),
      InventorySortOrder.categoryAscending =>
        left.category.name.compareTo(right.category.name),
    };
    if (comparison != 0) return comparison;
    return left.name.toLowerCase().compareTo(right.name.toLowerCase());
  });
  return result;
}
