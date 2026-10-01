import 'package:flutter_test/flutter_test.dart';

import 'package:freshkeep_app/domain/models/data_scope.dart';
import 'package:freshkeep_app/domain/models/food_item.dart';
import 'package:freshkeep_app/domain/models/household.dart';
import 'package:freshkeep_app/domain/models/shopping_item.dart';
import 'package:freshkeep_app/domain/models/user_profile.dart';

void main() {
  test('private and household scopes use UID and household IDs', () {
    final privateScope =
        DataScope.private(uid: 'firebase-uid', legacyOwnerId: 'Alex');
    final householdScope = DataScope.household(
      uid: 'firebase-uid',
      householdId: 'household-id',
      legacyOwnerId: 'Alex',
    );
    expect(privateScope.uid, 'firebase-uid');
    expect(privateScope.isHousehold, isFalse);
    expect(householdScope.householdId, 'household-id');
    expect(householdScope.isHousehold, isTrue);
  });

  test('affected models round-trip through Firestore document maps', () {
    final food = FoodItem(
      id: 'food-1',
      name: 'Milk',
      expirationDate: DateTime(2026, 10, 2),
      category: FoodCategory.dairy,
      quantity: '2 cartons',
      zone: FridgeZone.door,
      createdAt: DateTime(2026, 9, 30),
    );
    final shopping = ShoppingItem(
      id: 'shopping-1',
      name: 'Eggs',
      quantity: '12',
      checked: false,
      createdAt: DateTime(2026, 9, 30),
    );
    final household = Household(
      id: 'household-1',
      name: 'Home',
      inviteCode: 'ABC234',
      passwordHash: 'hash',
      ownerUid: 'firebase-uid',
      ownerUsername: 'Alex',
      members: const ['Alex'],
      createdAt: DateTime(2026, 9, 30),
    );
    final profile = UserProfile(
      username: 'Alex',
      refrigeratorModel: 'ge-gne27jymfs',
      createdAt: DateTime(2026, 9, 30),
      firebaseUid: 'firebase-uid',
    );

    final decodedFood = FoodItem.fromJson(food.toJson());
    expect(decodedFood.id, food.id);
    expect(decodedFood.expirationDate, food.expirationDate);
    expect(decodedFood.storageLocation, food.storageLocation);
    final decodedShopping = ShoppingItem.fromJson(shopping.toJson());
    expect(decodedShopping.id, shopping.id);
    expect(decodedShopping.checked, shopping.checked);
    final decodedHousehold = Household.fromJson(household.toJson());
    expect(decodedHousehold.ownerUid, household.ownerUid);
    expect(decodedHousehold.passwordHash, household.passwordHash);
    final decodedProfile = UserProfile.fromJson(profile.toJson());
    expect(decodedProfile.firebaseUid, profile.firebaseUid);
    expect(decodedProfile.refrigeratorModel, profile.refrigeratorModel);
  });
}
