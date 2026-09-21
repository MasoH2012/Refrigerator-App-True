import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:freshkeep_app/core/services/freshkeep_data_service.dart';
import 'package:freshkeep_app/data/repositories/preferences_inventory_repository.dart';
import 'package:freshkeep_app/data/repositories/user_preferences_repository.dart';
import 'package:freshkeep_app/domain/models/user_profile.dart';

void main() {
  test('loads a complete account snapshot with placeholder saved recipes',
      () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final service = FreshKeepDataService(
      inventoryRepository: PreferencesInventoryRepository(preferences),
      preferencesRepository: UserPreferencesRepository(preferences),
    );

    final data = await service.load(
      profile: UserProfile(
        username: 'Alex',
        refrigeratorModel: 'ge-gne27jymfs',
        createdAt: DateTime(2026),
      ),
    );

    expect(data.profile.username, 'Alex');
    expect(data.passwordConfigured, isTrue);
    expect(data.refrigerator?.brand, 'GE');
    expect(data.savedRecipes, isNotEmpty);
    expect(data.usingPlaceholderRecipes, isTrue);
  });
}
