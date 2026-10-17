import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/repository_providers.dart';
import '../../../data/repositories/saved_recipe_repository.dart';
import '../../../domain/models/data_scope.dart';
import '../../../domain/models/recipe.dart';
import '../../auth/application/auth_controller.dart';

final savedRecipesProvider =
    AsyncNotifierProvider<SavedRecipesController, List<Recipe>>(
  SavedRecipesController.new,
);

class SavedRecipesController extends AsyncNotifier<List<Recipe>> {
  SavedRecipeRepository get _repository =>
      ref.read(savedRecipeRepositoryProvider);

  @override
  Future<List<Recipe>> build() async {
    final profile = ref.watch(authProvider).value?.profile;
    if (profile == null) return const [];
    return _repository.load(userIdForProfile(profile));
  }

  Future<void> save(Recipe recipe) async {
    final profile = ref.read(authProvider).value?.profile;
    if (profile == null) throw StateError('Sign in to save a recipe.');
    final uid = userIdForProfile(profile);
    await _repository.save(uid, recipe);
    final current = state.value ?? const <Recipe>[];
    state = AsyncData([
      ...current.where((item) => item.id != recipe.id),
      recipe,
    ]);
  }

  Future<void> delete(String recipeId) async {
    final profile = ref.read(authProvider).value?.profile;
    if (profile == null) return;
    await _repository.delete(userIdForProfile(profile), recipeId);
    state = AsyncData(
      (state.value ?? const <Recipe>[])
          .where((recipe) => recipe.id != recipeId)
          .toList(),
    );
  }
}
