class Household {
  const Household({
    required this.id,
    required this.name,
    required this.inviteCode,
    this.passwordHash = '',
    this.ownerUid = '',
    this.archivedAt,
    required this.ownerUsername,
    required this.members,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String inviteCode;
  final String passwordHash;
  final String ownerUid;
  final DateTime? archivedAt;
  final String ownerUsername;
  final List<String> members;
  final DateTime createdAt;

  /// A deep link that can be shared with another FreshKeep profile.
  /// The password is intentionally never embedded in this link.
  String get inviteLink => 'freshkeep://household/join?code=$inviteCode';

  Household copyWith({
    String? name,
    List<String>? members,
    String? passwordHash,
    String? ownerUid,
    DateTime? archivedAt,
  }) =>
      Household(
        id: id,
        name: name ?? this.name,
        inviteCode: inviteCode,
        passwordHash: passwordHash ?? this.passwordHash,
        ownerUid: ownerUid ?? this.ownerUid,
        archivedAt: archivedAt ?? this.archivedAt,
        ownerUsername: ownerUsername,
        members: members ?? this.members,
        createdAt: createdAt,
      );

  Map<String, Object> toJson() => {
        'id': id,
        'name': name,
        'inviteCode': inviteCode,
        'passwordHash': passwordHash,
        'ownerUid': ownerUid,
        if (archivedAt != null) 'archivedAt': archivedAt!.toIso8601String(),
        'ownerUsername': ownerUsername,
        'members': members,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Household.fromJson(Map<String, Object?> json) => Household(
        id: json['id']! as String,
        name: json['name']! as String,
        inviteCode: json['inviteCode']! as String,
        passwordHash: json['passwordHash'] as String? ?? '',
        ownerUid: json['ownerUid'] as String? ?? '',
        archivedAt: json['archivedAt'] is String
            ? DateTime.tryParse(json['archivedAt']! as String)
            : null,
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
