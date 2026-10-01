import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/data_scope.dart';
import '../../domain/models/food_item.dart';
import 'inventory_repository.dart';
import 'preferences_inventory_repository.dart';

class FirestoreInventoryRepository implements InventoryRepository {
  FirestoreInventoryRepository({
    required SharedPreferences preferences,
    FirebaseFirestore? firestore,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _legacy = PreferencesInventoryRepository(preferences),
        _preferences = preferences;

  final FirebaseFirestore _firestore;
  final PreferencesInventoryRepository _legacy;
  final SharedPreferences _preferences;

  @override
  Future<List<FoodItem>> loadItems(DataScope scope) async {
    final snapshot = await _collection(scope).get();
    final cloudItems = snapshot.docs
        .map((doc) => FoodItem.fromJson(doc.data().cast<String, Object?>()))
        .toList();
    if (scope.isHousehold) return cloudItems;

    final marker = _migrationKey(scope.uid);
    if (_preferences.getBool(marker) == true) return cloudItems;
    if (cloudItems.isNotEmpty) {
      await _preferences.setBool(marker, true);
      return cloudItems;
    }
    final localItems = await _legacy.loadItems(scope);
    if (localItems.isNotEmpty) {
      await _write(scope, localItems);
    }
    await _preferences.setBool(marker, true);
    return localItems;
  }

  @override
  Future<void> saveItems(DataScope scope, List<FoodItem> items) =>
      _write(scope, items);

  CollectionReference<Map<String, dynamic>> _collection(DataScope scope) {
    if (scope.isHousehold) {
      return _firestore
          .collection('households')
          .doc(scope.householdId)
          .collection('inventory');
    }
    return _firestore
        .collection('users')
        .doc(scope.uid)
        .collection('inventory');
  }

  Future<void> _write(DataScope scope, List<FoodItem> items) async {
    final collection = _collection(scope);
    final existing = await collection.get();
    final nextIds = items.map((item) => item.id).toSet();
    final batch = _firestore.batch();
    for (final document in existing.docs) {
      if (!nextIds.contains(document.id)) batch.delete(document.reference);
    }
    for (final item in items) {
      batch.set(collection.doc(item.id), item.toJson());
    }
    await batch.commit();
  }

  String _migrationKey(String uid) => 'firebase.migration.inventory.v1.$uid';
}
