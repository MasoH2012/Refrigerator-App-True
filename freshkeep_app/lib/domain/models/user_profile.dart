class UserProfile {
  const UserProfile({
    required this.username,
    required this.refrigeratorModel,
    required this.createdAt,
  });

  final String username;
  final String refrigeratorModel;
  final DateTime createdAt;

  String get initials {
    final parts = username.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  Map<String, Object> toJson() => {
        'username': username,
        'refrigeratorModel': refrigeratorModel,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserProfile.fromJson(Map<String, Object?> json) => UserProfile(
        username: json['username']! as String,
        refrigeratorModel: json['refrigeratorModel']! as String,
        createdAt: DateTime.parse(json['createdAt']! as String),
      );
}
