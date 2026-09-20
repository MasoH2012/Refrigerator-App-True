enum FoodCategory { produce, dairy, protein, pantry, beverage, leftovers }

enum FridgeZone {
  topShelf,
  middleShelf,
  lowerShelf,
  highHumidity,
  lowHumidity,
  door,
}

enum StorageLocation { fridge, outOfFridge }

class FoodItem {
  const FoodItem({
    required this.id,
    required this.name,
    required this.expirationDate,
    required this.category,
    required this.quantity,
    required this.zone,
    this.storageLocation = StorageLocation.fridge,
    this.imageUrl,
    required this.createdAt,
  });

  final String id;
  final String name;
  final DateTime expirationDate;
  final FoodCategory category;
  final String quantity;
  final FridgeZone zone;
  final StorageLocation storageLocation;
  final String? imageUrl;
  final DateTime createdAt;

  FoodItem copyWith({
    String? id,
    String? name,
    DateTime? expirationDate,
    FoodCategory? category,
    String? quantity,
    FridgeZone? zone,
    StorageLocation? storageLocation,
    String? imageUrl,
    DateTime? createdAt,
  }) =>
      FoodItem(
        id: id ?? this.id,
        name: name ?? this.name,
        expirationDate: expirationDate ?? this.expirationDate,
        category: category ?? this.category,
        quantity: quantity ?? this.quantity,
        zone: zone ?? this.zone,
        storageLocation: storageLocation ?? this.storageLocation,
        imageUrl: imageUrl ?? this.imageUrl,
        createdAt: createdAt ?? this.createdAt,
      );

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
        'storageLocation': storageLocation.name,
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
        storageLocation: StorageLocation.values
                .where((value) => value.name == json['storageLocation'])
                .firstOrNull ??
            StorageLocation.fridge,
        imageUrl: json['imageUrl'] as String?,
        createdAt: DateTime.parse(json['createdAt']! as String),
      );
}
