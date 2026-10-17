import '../../../domain/models/food_item.dart';
import '../../../domain/models/fridge_organization.dart';
import '../../../domain/models/refrigerator_model.dart';

class FridgeOrganizationException implements Exception {
  const FridgeOrganizationException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class FridgeOrganizationService {
  FridgeOrganizationService();

  Future<FridgeOrganizationPlan> organize({
    required List<FoodItem> items,
    required RefrigeratorModel refrigerator,
  }) async {
    final assignments = items
        .map(
          (item) => FridgeOrganizationAssignment(
            itemId: item.id,
            itemName: item.name,
            zone: _recommendedZone(item),
            reason: _reasonFor(item),
            size: _sizeFor(item.quantity),
          ),
        )
        .toList();
    return FridgeOrganizationPlan(
      assignments: assignments,
      summary: assignments.isEmpty
          ? 'Add refrigerated food to create an organization plan.'
          : 'A quick placement plan based on food safety, humidity, and access.',
      generatedAt: DateTime.now(),
    );
  }

  FridgeZone _recommendedZone(FoodItem item) {
    final name = item.name.toLowerCase();
    if (item.category == FoodCategory.beverage) return FridgeZone.door;
    if (item.category == FoodCategory.protein) return FridgeZone.lowerShelf;
    if (item.category == FoodCategory.leftovers) return FridgeZone.topShelf;
    if (item.category == FoodCategory.dairy) return FridgeZone.middleShelf;
    if (item.category == FoodCategory.produce) {
      const fruits = {'apple', 'banana', 'berry', 'berries', 'grape', 'orange'};
      return fruits.any(name.contains)
          ? FridgeZone.lowHumidity
          : FridgeZone.highHumidity;
    }
    return FridgeZone.middleShelf;
  }

  String _reasonFor(FoodItem item) => switch (item.category) {
        FoodCategory.protein =>
          'Keep raw proteins low to reduce cross-contamination risk.',
        FoodCategory.produce =>
          'Use the crisper humidity setting to preserve freshness.',
        FoodCategory.dairy =>
          'A stable middle-shelf temperature suits dairy products.',
        FoodCategory.beverage => 'The door keeps drinks easy to reach.',
        FoodCategory.leftovers =>
          'Keep prepared food visible and easy to use first.',
        FoodCategory.pantry =>
          'Place shelf-stable items where they are easy to find.',
      };

  String _sizeFor(String quantity) {
    final amount = double.tryParse(
      RegExp(r'\d+(?:\.\d+)?').firstMatch(quantity)?.group(0) ?? '',
    );
    if (amount != null && amount <= 1) return 'small';
    if (amount != null && amount >= 4) return 'large';
    return 'medium';
  }
}
