import '../../domain/models/food_item.dart';

abstract interface class InventoryRepository {
  Future<List<FoodItem>> loadItems(String ownerId);
  Future<void> saveItems(String ownerId, List<FoodItem> items);
}
