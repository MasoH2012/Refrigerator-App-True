import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/app_preferences.dart';

class UserPreferencesRepository {
  UserPreferencesRepository(this._preferences);

  final SharedPreferences _preferences;

  AppPreferences load(String username) {
    final encoded = _preferences.getString(_keyFor(username));
    if (encoded == null) return const AppPreferences();
    try {
      final json = jsonDecode(encoded) as Map<String, dynamic>;
      final parsedWarningDays = (json['warningDays'] as num?)?.round() ?? 3;
      return AppPreferences(
        notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
        warningDays: parsedWarningDays < 0 ? 0 : parsedWarningDays,
        dietaryPreference:
            json['dietaryPreference'] as String? ?? 'No preference',
        allergies: (json['allergies'] as List<dynamic>?)
                ?.whereType<String>()
                .toList() ??
            const [],
      );
    } on Object {
      return const AppPreferences();
    }
  }

  Future<void> save(String username, AppPreferences preferences) =>
      _preferences.setString(
        _keyFor(username),
        jsonEncode({
          'notificationsEnabled': preferences.notificationsEnabled,
          'warningDays': preferences.warningDays,
          'dietaryPreference': preferences.dietaryPreference,
          'allergies': preferences.allergies,
        }),
      );

  String _keyFor(String username) =>
      'user.preferences.v1.${username.trim().toLowerCase()}';
}
