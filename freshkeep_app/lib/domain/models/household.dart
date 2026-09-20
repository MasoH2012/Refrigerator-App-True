class Household {
  const Household({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.ownerUsername,
    required this.members,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String inviteCode;
  final String ownerUsername;
  final List<String> members;
  final DateTime createdAt;

  Household copyWith({
    String? name,
    List<String>? members,
  }) =>
      Household(
        id: id,
        name: name ?? this.name,
        inviteCode: inviteCode,
        ownerUsername: ownerUsername,
        members: members ?? this.members,
        createdAt: createdAt,
      );

  Map<String, Object> toJson() => {
        'id': id,
        'name': name,
        'inviteCode': inviteCode,
        'ownerUsername': ownerUsername,
        'members': members,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Household.fromJson(Map<String, Object?> json) => Household(
        id: json['id']! as String,
        name: json['name']! as String,
        inviteCode: json['inviteCode']! as String,
        ownerUsername: json['ownerUsername']! as String,
        members: (json['members'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .toList(),
        createdAt: DateTime.parse(json['createdAt']! as String),
      );
}

class HouseholdState {
  const HouseholdState({
    required this.households,
    required this.activeHouseholdId,
  });

  final List<Household> households;
  final String? activeHouseholdId;

  Household? get active {
    final id = activeHouseholdId;
    if (id == null) return null;
    for (final household in households) {
      if (household.id == id) return household;
    }
    return null;
  }
}
