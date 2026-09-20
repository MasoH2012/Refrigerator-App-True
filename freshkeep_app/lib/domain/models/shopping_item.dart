class ShoppingItem {
  const ShoppingItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.checked,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String quantity;
  final bool checked;
  final DateTime createdAt;

  ShoppingItem copyWith({String? name, String? quantity, bool? checked}) =>
      ShoppingItem(
        id: id,
        name: name ?? this.name,
        quantity: quantity ?? this.quantity,
        checked: checked ?? this.checked,
        createdAt: createdAt,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'quantity': quantity,
        'checked': checked,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ShoppingItem.fromJson(Map<String, Object?> json) => ShoppingItem(
        id: json['id']! as String,
        name: json['name']! as String,
        quantity: json['quantity'] as String? ?? '',
        checked: json['checked'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt']! as String),
      );
}
