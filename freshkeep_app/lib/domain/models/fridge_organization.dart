import 'food_item.dart';
import 'refrigerator_model.dart';

class FridgeOrganizationAssignment {
  const FridgeOrganizationAssignment({
    required this.itemId,
    required this.itemName,
    required this.zone,
    required this.reason,
    required this.size,
  });

  final String itemId;
  final String itemName;
  final FridgeZone zone;
  final String reason;
  final String size;

  factory FridgeOrganizationAssignment.fromJson(Map<String, Object?> json) {
    final zoneName = json['zone'] as String?;
    final zone =
        FridgeZone.values.where((value) => value.name == zoneName).firstOrNull;
    return FridgeOrganizationAssignment(
      itemId: json['itemId']! as String,
      itemName: json['itemName']! as String,
      zone: zone ?? FridgeZone.middleShelf,
      reason:
          json['reason'] as String? ?? 'Recommended for freshness and access.',
      size: json['size'] as String? ?? 'medium',
    );
  }
}

class FridgeOrganizationPlan {
  const FridgeOrganizationPlan({
    required this.assignments,
    required this.summary,
    required this.generatedAt,
  });

  final List<FridgeOrganizationAssignment> assignments;
  final String summary;
  final DateTime generatedAt;

  int get changedCount => assignments.length;

  FridgeOrganizationPlan copyWith({
    List<FridgeOrganizationAssignment>? assignments,
    String? summary,
    DateTime? generatedAt,
  }) =>
      FridgeOrganizationPlan(
        assignments: assignments ?? this.assignments,
        summary: summary ?? this.summary,
        generatedAt: generatedAt ?? this.generatedAt,
      );
}
