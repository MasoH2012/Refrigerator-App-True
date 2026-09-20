import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/shopping_item.dart';

class ShoppingListRepository {
  ShoppingListRepository(this._preferences);
  final SharedPreferences _preferences;

  Future<List<ShoppingItem>> load(String ownerId) async {
    final value = _preferences.getString(_keyFor(ownerId));
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

  Future<void> save(String ownerId, List<ShoppingItem> items) =>
      _preferences.setString(
        _keyFor(ownerId),
        jsonEncode(items.map((item) => item.toJson()).toList()),
      );

  String _keyFor(String ownerId) =>
      'shopping-list.v1.${ownerId.trim().toLowerCase()}';
}
