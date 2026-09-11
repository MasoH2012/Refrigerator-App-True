import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/storage_providers.dart';
import 'auth_repository.dart';
import 'inventory_repository.dart';
import 'local_auth_repository.dart';
import 'preferences_inventory_repository.dart';
import 'user_preferences_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return LocalAuthRepository(ref.watch(sharedPreferencesProvider));
});

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return PreferencesInventoryRepository(ref.watch(sharedPreferencesProvider));
});

final userPreferencesRepositoryProvider =
    Provider<UserPreferencesRepository>((ref) {
  return UserPreferencesRepository(ref.watch(sharedPreferencesProvider));
});
