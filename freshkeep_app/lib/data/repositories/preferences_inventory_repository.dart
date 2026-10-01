import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/food_item.dart';
import '../../domain/models/data_scope.dart';
import 'inventory_repository.dart';

class PreferencesInventoryRepository implements InventoryRepository {
  PreferencesInventoryRepository(this._preferences);

  static const _legacyKey = 'inventory.v1';
  final SharedPreferences _preferences;

  @override
  Future<List<FoodItem>> loadItems(DataScope scope) async {
    final key = _keyFor(scope);
    var encoded = _preferences.getString(key);
    if (encoded == null && scope.legacyOwnerId != null) {
      encoded = _preferences.getString(_legacyKey);
      encoded ??= _preferences.getString(_keyForLegacy(scope.legacyOwnerId!));
      if (encoded != null) await _preferences.setString(key, encoded);
    }
    if (encoded == null) return const [];
    final data = jsonDecode(encoded) as List<dynamic>;
    return data
        .map((item) => FoodItem.fromJson(item as Map<String, Object?>))
        .toList();
  }

  @override
  Future<void> saveItems(DataScope scope, List<FoodItem> items) =>
      _preferences.setString(
        _keyFor(scope),
        jsonEncode(items.map((item) => item.toJson()).toList()),
      );

  String _keyFor(DataScope scope) =>
      'inventory.v2.${(scope.householdId ?? scope.uid).trim().toLowerCase()}';

  String _keyForLegacy(String ownerId) =>
      'inventory.v2.${ownerId.trim().toLowerCase()}';
}
