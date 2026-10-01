import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/app_preferences.dart';
import '../../domain/models/data_scope.dart';
import 'user_preferences_repository.dart';

class FirestoreUserPreferencesRepository implements UserPreferencesRepository {
  FirestoreUserPreferencesRepository({
    required SharedPreferences preferences,
    FirebaseFirestore? firestore,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _legacy = PreferencesUserPreferencesRepository(preferences),
        _preferences = preferences;

  final FirebaseFirestore _firestore;
  final PreferencesUserPreferencesRepository _legacy;
  final SharedPreferences _preferences;

  @override
  Future<AppPreferences> load(DataScope scope) async {
    if (scope.isHousehold) return const AppPreferences();
    final document = await _document(scope).get();
    if (document.exists && document.data() != null) {
      await _preferences.setBool(_migrationKey(scope.uid), true);
      return _fromJson(document.data()!);
    }
    final marker = _migrationKey(scope.uid);
    if (_preferences.getBool(marker) == true) return const AppPreferences();
    final local = await _legacy.load(scope);
    await _write(scope, local);
    await _preferences.setBool(marker, true);
    return local;
  }

  @override
  Future<void> save(DataScope scope, AppPreferences preferences) =>
      _write(scope, preferences);

  DocumentReference<Map<String, dynamic>> _document(DataScope scope) =>
      _firestore
          .collection('users')
          .doc(scope.uid)
          .collection('preferences')
          .doc('main');

  Future<void> _write(DataScope scope, AppPreferences preferences) async {
    if (scope.isHousehold) return;
    await _document(scope).set({
      'notificationsEnabled': preferences.notificationsEnabled,
      'warningDays': preferences.warningDays,
      'dietaryPreference': preferences.dietaryPreference,
      'allergies': preferences.allergies,
    });
  }

  AppPreferences _fromJson(Map<String, dynamic> json) {
    final warningDays = (json['warningDays'] as num?)?.round() ?? 3;
    return AppPreferences(
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      warningDays: warningDays < 0 ? 0 : warningDays,
      dietaryPreference:
          json['dietaryPreference'] as String? ?? 'No preference',
      allergies:
          (json['allergies'] as List<dynamic>?)?.whereType<String>().toList() ??
              const [],
    );
  }

  String _migrationKey(String uid) => 'firebase.migration.preferences.v1.$uid';
}
