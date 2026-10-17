import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/household_password_store.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../domain/models/food_item.dart';
import '../../../domain/models/data_scope.dart';
import '../../../domain/models/user_profile.dart';

final authProvider = AsyncNotifierProvider<AuthController, AuthSession>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<AuthSession> {
  AuthRepository get _authRepository => ref.read(authRepositoryProvider);

  @override
  Future<AuthSession> build() => _authRepository.restoreSession();

  Future<String?> register({
    required String username,
    required String password,
    required String refrigeratorModel,
    required List<FoodItem> initialItems,
    String? householdInviteCode,
    String? householdPassword,
  }) async {
    state = const AsyncLoading();
    UserProfile? profile;
    try {
      profile = await _authRepository.register(
        username: username,
        password: password,
        refrigeratorModel: refrigeratorModel,
      );
      await ref
          .read(inventoryRepositoryProvider)
          .saveItems(privateScopeForProfile(profile), initialItems);

      // A new account can join an existing household during setup. Keep this
      // separate from account creation so a bad invite never deletes or
      // invalidates the Firebase account that was just created.
      String? householdWarning;
      final code = householdInviteCode?.trim();
      final householdSecret = householdPassword?.trim();
      if (code != null &&
          code.isNotEmpty &&
          householdSecret != null &&
          householdSecret.isNotEmpty) {
        try {
          final uid = userIdForProfile(profile);
          final household = await ref.read(householdRepositoryProvider).join(
                uid: uid,
                username: profile.username,
                inviteCode: code,
                password: householdSecret,
              );
          await ref.read(householdPasswordStoreProvider).save(
                uid: uid,
                householdId: household.id,
                password: householdSecret,
              );
          if (household.refrigeratorModel.isNotEmpty) {
            profile = await _authRepository.updateRefrigeratorModel(
              username: profile.username,
              refrigeratorModel: household.refrigeratorModel,
            );
          }
          // Make the starter inventory visible to the shared household. Read
          // the existing shared list first so a new member cannot overwrite
          // food already owned by the household.
          if (initialItems.isNotEmpty) {
            final sharedScope = DataScope.household(
              uid: uid,
              householdId: household.id,
              legacyOwnerId: profile.username,
            );
            final inventoryRepository = ref.read(inventoryRepositoryProvider);
            // saveItems synchronizes a complete scope and removes documents
            // that are not in the provided list. Load the existing shared
            // inventory first so a new member's starter items are appended
            // instead of replacing the household's food.
            final existingSharedItems =
                await inventoryRepository.loadItems(sharedScope);
            await inventoryRepository.saveItems(
              sharedScope,
              [...existingSharedItems, ...initialItems],
            );
            await inventoryRepository.saveItems(
              privateScopeForProfile(profile),
              const [],
            );
          }
        } on Object catch (error) {
          householdWarning =
              'Profile created, but we could not join that household: $error';
        }
      }
      state = AsyncData(
        AuthSession(
          profile: profile,
          isAuthenticated: true,
          hasProfiles: true,
        ),
      );
      return householdWarning;
    } catch (error) {
      final restored = await _authRepository.restoreSession();
      state = AsyncData(restored);
      if (error is UsernameAlreadyExistsException) {
        return 'That username already exists. Sign in or choose another.';
      }
      if (error is AuthRepositoryException) return error.message;
      return 'We could not create your profile. Please try again.';
    }
  }

  Future<String?> signIn({
    required String username,
    required String password,
  }) async {
    final previous = state.value;
    state = const AsyncLoading();
    UserProfile? profile;
    try {
      profile = await _authRepository.signIn(
        username: username,
        password: password,
      );
    } on AuthRepositoryException catch (error) {
      state = AsyncData(
        AuthSession(
          profile: null,
          isAuthenticated: false,
          hasProfiles: previous?.hasProfiles ?? true,
        ),
      );
      return error.message;
    }
    if (profile == null) {
      state = AsyncData(
        AuthSession(
          profile: null,
          isAuthenticated: false,
          hasProfiles: previous?.hasProfiles ?? true,
        ),
      );
      return 'Username or password is incorrect.';
    }
    state = AsyncData(
      AuthSession(
        profile: profile,
        isAuthenticated: true,
        hasProfiles: true,
      ),
    );
    return null;
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
    state = const AsyncData(
      AuthSession(profile: null, isAuthenticated: false, hasProfiles: true),
    );
  }

  Future<String?> updateRefrigeratorModel(String refrigeratorModel) async {
    final profile = state.value?.profile;
    if (profile == null) return 'Sign in before changing your refrigerator.';
    try {
      final updated = await _authRepository.updateRefrigeratorModel(
        username: profile.username,
        refrigeratorModel: refrigeratorModel,
      );
      state = AsyncData(
        AuthSession(
          profile: updated,
          isAuthenticated: true,
          hasProfiles: true,
        ),
      );
      return null;
    } on Object catch (error) {
      return error.toString();
    }
  }
}
