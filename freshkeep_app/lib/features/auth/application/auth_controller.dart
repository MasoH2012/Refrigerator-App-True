import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../domain/models/food_item.dart';

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
  }) async {
    state = const AsyncLoading();
    try {
      final profile = await _authRepository.register(
        username: username,
        password: password,
        refrigeratorModel: refrigeratorModel,
      );
      await ref
          .read(inventoryRepositoryProvider)
          .saveItems(profile.username, initialItems);
      state = AsyncData(
        AuthSession(
          profile: profile,
          isAuthenticated: true,
          hasProfiles: true,
        ),
      );
      return null;
    } catch (error) {
      final restored = await _authRepository.restoreSession();
      state = AsyncData(restored);
      if (error is UsernameAlreadyExistsException) {
        return 'That username already exists. Sign in or choose another.';
      }
      return 'We could not create your profile. Please try again.';
    }
  }

  Future<String?> signIn({
    required String username,
    required String password,
  }) async {
    final previous = state.value;
    state = const AsyncLoading();
    final profile = await _authRepository.signIn(
      username: username,
      password: password,
    );
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
