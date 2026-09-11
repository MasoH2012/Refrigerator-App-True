class AppPreferences {
  const AppPreferences({
    this.notificationsEnabled = true,
    this.warningDays = 3,
    this.dietaryPreference = 'No preference',
    this.allergies = const [],
  });

  final bool notificationsEnabled;
  final int warningDays;
  final String dietaryPreference;
  final List<String> allergies;

  AppPreferences copyWith({
    bool? notificationsEnabled,
    int? warningDays,
    String? dietaryPreference,
    List<String>? allergies,
  }) =>
      AppPreferences(
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        warningDays: warningDays ?? this.warningDays,
        dietaryPreference: dietaryPreference ?? this.dietaryPreference,
        allergies: allergies ?? this.allergies,
      );
}
