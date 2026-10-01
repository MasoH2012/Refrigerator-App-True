import '../../domain/models/food_item.dart';
import '../../domain/models/data_scope.dart';

abstract interface class InventoryRepository {
  Future<List<FoodItem>> loadItems(DataScope scope);
  Future<void> saveItems(DataScope scope, List<FoodItem> items);
}
