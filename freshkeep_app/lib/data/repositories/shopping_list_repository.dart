import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/shopping_item.dart';
import '../../domain/models/data_scope.dart';

abstract interface class ShoppingListRepository {
  Future<List<ShoppingItem>> load(DataScope scope);
  Future<void> save(DataScope scope, List<ShoppingItem> items);
}

class PreferencesShoppingListRepository implements ShoppingListRepository {
  PreferencesShoppingListRepository(this._preferences);
  final SharedPreferences _preferences;

  @override
  Future<List<ShoppingItem>> load(DataScope scope) async {
    var value = _preferences.getString(_keyFor(scope));
    if (value == null && scope.legacyOwnerId != null) {
      value = _preferences.getString(_keyForLegacy(scope.legacyOwnerId!));
      if (value != null) {
        await _preferences.setString(_keyFor(scope), value);
      }
    }
    if (value == null) return const [];
    try {
      return (jsonDecode(value) as List<dynamic>)
          .map((item) =>
              ShoppingItem.fromJson((item as Map).cast<String, Object?>()))
          .toList();
    } on Object {
      return const [];
    }
  }

  @override
  Future<void> save(DataScope scope, List<ShoppingItem> items) =>
      _preferences.setString(
        _keyFor(scope),
        jsonEncode(items.map((item) => item.toJson()).toList()),
      );

  String _keyFor(DataScope scope) =>
      'shopping-list.v1.${(scope.householdId ?? scope.uid).trim().toLowerCase()}';

  String _keyForLegacy(String ownerId) =>
      'shopping-list.v1.${ownerId.trim().toLowerCase()}';
}
