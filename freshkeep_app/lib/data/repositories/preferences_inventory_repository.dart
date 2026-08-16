import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/food_item.dart';
import 'inventory_repository.dart';

class PreferencesInventoryRepository implements InventoryRepository {
  PreferencesInventoryRepository(this._preferences);

  static const _legacyKey = 'inventory.v1';
  final SharedPreferences _preferences;

  @override
  Future<List<FoodItem>> loadItems(String ownerId) async {
    final key = _keyFor(ownerId);
    var encoded = _preferences.getString(key);
    if (encoded == null) {
      encoded = _preferences.getString(_legacyKey);
      if (encoded != null) await _preferences.setString(key, encoded);
    }
    if (encoded == null) return const [];
    final data = jsonDecode(encoded) as List<dynamic>;
    return data
        .map((item) => FoodItem.fromJson(item as Map<String, Object?>))
        .toList();
  }

  @override
  Future<void> saveItems(String ownerId, List<FoodItem> items) =>
      _preferences.setString(
        _keyFor(ownerId),
        jsonEncode(items.map((item) => item.toJson()).toList()),
      );

  String _keyFor(String ownerId) =>
      'inventory.v2.${ownerId.trim().toLowerCase()}';
}
