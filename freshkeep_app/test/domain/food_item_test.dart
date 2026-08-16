import 'package:flutter_test/flutter_test.dart';
import 'package:freshkeep_app/domain/models/food_item.dart';

void main() {
  group('FoodItem', () {
    final today = DateTime(2026, 8, 1, 15);
    final item = FoodItem(
      id: '1',
      name: 'Spinach',
      expirationDate: DateTime(2026, 8, 4),
      category: FoodCategory.produce,
      quantity: '1 bag',
      zone: FridgeZone.highHumidity,
      createdAt: today,
    );

    test('calculates whole calendar days until expiration', () {
      expect(item.daysUntilExpiration(today), 3);
    });

    test('round-trips through JSON', () {
      final restored = FoodItem.fromJson(item.toJson());
      expect(restored.id, item.id);
      expect(restored.category, FoodCategory.produce);
      expect(restored.zone, FridgeZone.highHumidity);
      expect(restored.expirationDate, item.expirationDate);
    });
  });
}
