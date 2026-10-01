import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/app_preferences.dart';
import '../../domain/models/data_scope.dart';

abstract interface class UserPreferencesRepository {
  Future<AppPreferences> load(DataScope scope);
  Future<void> save(DataScope scope, AppPreferences preferences);
}

class PreferencesUserPreferencesRepository
    implements UserPreferencesRepository {
  PreferencesUserPreferencesRepository(this._preferences);

  final SharedPreferences _preferences;

  @override
  Future<AppPreferences> load(DataScope scope) async {
    var encoded = _preferences.getString(_keyFor(scope));
    if (encoded == null && scope.legacyOwnerId != null) {
      encoded = _preferences.getString(_keyForLegacy(scope.legacyOwnerId!));
      if (encoded != null) {
        await _preferences.setString(_keyFor(scope), encoded);
      }
    }
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

  @override
  Future<void> save(DataScope scope, AppPreferences preferences) =>
      _preferences.setString(
        _keyFor(scope),
        jsonEncode({
          'notificationsEnabled': preferences.notificationsEnabled,
          'warningDays': preferences.warningDays,
          'dietaryPreference': preferences.dietaryPreference,
          'allergies': preferences.allergies,
        }),
      );

  String _keyFor(DataScope scope) =>
      'user.preferences.v1.${(scope.householdId ?? scope.uid).trim().toLowerCase()}';

  String _keyForLegacy(String username) =>
      'user.preferences.v1.${username.trim().toLowerCase()}';
}
