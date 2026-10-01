import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/storage_providers.dart';
import 'auth_repository.dart';
import 'inventory_repository.dart';
import 'local_auth_repository.dart';
import 'preferences_inventory_repository.dart';
import 'firestore_inventory_repository.dart';
import 'user_preferences_repository.dart';
import 'shopping_list_repository.dart';
import 'firestore_shopping_list_repository.dart';
import 'household_repository.dart';
import 'firestore_household_repository.dart';
import 'firestore_user_preferences_repository.dart';
import 'firebase_auth_repository.dart';
import 'package:firebase_core/firebase_core.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (Firebase.apps.isNotEmpty) {
    return FirebaseAuthRepository(
      preferences: ref.watch(sharedPreferencesProvider),
    );
  }
  return LocalAuthRepository(ref.watch(sharedPreferencesProvider));
});

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  if (Firebase.apps.isNotEmpty) {
    return FirestoreInventoryRepository(
      preferences: ref.watch(sharedPreferencesProvider),
    );
  }
  return PreferencesInventoryRepository(ref.watch(sharedPreferencesProvider));
});

final userPreferencesRepositoryProvider =
    Provider<UserPreferencesRepository>((ref) {
  if (Firebase.apps.isNotEmpty) {
    return FirestoreUserPreferencesRepository(
      preferences: ref.watch(sharedPreferencesProvider),
    );
  }
  return PreferencesUserPreferencesRepository(
      ref.watch(sharedPreferencesProvider));
});

final shoppingListRepositoryProvider = Provider<ShoppingListRepository>((ref) {
  if (Firebase.apps.isNotEmpty) {
    return FirestoreShoppingListRepository(
      preferences: ref.watch(sharedPreferencesProvider),
    );
  }
  return PreferencesShoppingListRepository(
      ref.watch(sharedPreferencesProvider));
});

final householdRepositoryProvider = Provider<HouseholdRepository>((ref) {
  if (Firebase.apps.isNotEmpty) {
    return FirestoreHouseholdRepository(
      preferences: ref.watch(sharedPreferencesProvider),
    );
  }
  return PreferencesHouseholdRepository(ref.watch(sharedPreferencesProvider));
});
