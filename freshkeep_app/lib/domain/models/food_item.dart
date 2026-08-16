enum FoodCategory { produce, dairy, protein, pantry, beverage, leftovers }

enum FridgeZone {
  topShelf,
  middleShelf,
  lowerShelf,
  highHumidity,
  lowHumidity,
  door,
}

class FoodItem {
  const FoodItem({
    required this.id,
    required this.name,
    required this.expirationDate,
    required this.category,
    required this.quantity,
    required this.zone,
    this.imageUrl,
    required this.createdAt,
  });

  final String id;
  final String name;
  final DateTime expirationDate;
  final FoodCategory category;
  final String quantity;
  final FridgeZone zone;
  final String? imageUrl;
  final DateTime createdAt;

  int daysUntilExpiration(DateTime now) => DateTime(
        expirationDate.year,
        expirationDate.month,
        expirationDate.day,
      ).difference(DateTime(now.year, now.month, now.day)).inDays;

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'expirationDate': expirationDate.toIso8601String(),
        'category': category.name,
        'quantity': quantity,
        'zone': zone.name,
        'imageUrl': imageUrl,
        'createdAt': createdAt.toIso8601String(),
      };

  factory FoodItem.fromJson(Map<String, Object?> json) => FoodItem(
        id: json['id']! as String,
        name: json['name']! as String,
        expirationDate: DateTime.parse(json['expirationDate']! as String),
        category: FoodCategory.values.byName(json['category']! as String),
        quantity: json['quantity']! as String,
        zone: FridgeZone.values.byName(json['zone']! as String),
        imageUrl: json['imageUrl'] as String?,
        createdAt: DateTime.parse(json['createdAt']! as String),
      );
}
