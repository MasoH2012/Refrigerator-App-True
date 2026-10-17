import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/recipe_filters.dart';
import '../../../domain/models/app_preferences.dart';
import '../../../domain/models/data_scope.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../auth/application/auth_controller.dart';
import '../../inventory/application/inventory_controller.dart';
import '../data/ai_recipe_suggestion_service.dart';
import '../data/recipe_suggestion_service.dart';

final recipeSuggestionServiceProvider = Provider<RecipeSuggestionService>(
  (ref) => CuratedRecipeSuggestionService(now: DateTime.now),
);

final aiRecipeSuggestionServiceProvider = Provider<RecipeSuggestionService?>(
  (ref) {
    final endpoint = _recipeAiEndpoint();
    if (endpoint == null) return null;
    return AiRecipeSuggestionService(endpoint: endpoint);
  },
);

final recipeSuggestionsProvider =
    AsyncNotifierProvider<RecipeSuggestionsController, RecipeSuggestionResult>(
  RecipeSuggestionsController.new,
);

class RecipeSuggestionsController
    extends AsyncNotifier<RecipeSuggestionResult> {
  RecipeFilters _filters = const RecipeFilters();
  var _requestVersion = 0;

  RecipeFilters get filters => _filters;

  @override
  Future<RecipeSuggestionResult> build() async {
    final items = await ref.watch(inventoryProvider.future);
    final profile = ref.watch(authProvider).value?.profile;
    final preferences = profile == null
        ? const AppPreferences()
        : await ref
            .read(userPreferencesRepositoryProvider)
            .load(privateScopeForProfile(profile));
    final dietaryVegetarian = preferences.dietaryPreference == 'Vegetarian' ||
        preferences.dietaryPreference == 'Vegan';
    final filters = _filters.copyWith(
      vegetarian: _filters.vegetarian || dietaryVegetarian,
      avoidedIngredients: {
        ..._filters.avoidedIngredients,
        ...preferences.allergies,
      },
    );
    return ref.read(recipeSuggestionServiceProvider).suggest(
          items: items,
          filters: filters,
        );
  }

  Future<void> refresh({RecipeFilters? filters}) async {
    if (filters != null) _filters = filters;
    final requestVersion = ++_requestVersion;
    final items = await ref.read(inventoryProvider.future);
    final profile = ref.read(authProvider).value?.profile;
    final preferences = profile == null
        ? const AppPreferences()
        : await ref
            .read(userPreferencesRepositoryProvider)
            .load(privateScopeForProfile(profile));
    final dietaryVegetarian = preferences.dietaryPreference == 'Vegetarian' ||
        preferences.dietaryPreference == 'Vegan';
    final filtersToUse = _filters.copyWith(
      vegetarian: _filters.vegetarian || dietaryVegetarian,
      avoidedIngredients: {
        ..._filters.avoidedIngredients,
        ...preferences.allergies,
      },
    );
    state = const AsyncLoading<RecipeSuggestionResult>();
    try {
      final result = await ref.read(recipeSuggestionServiceProvider).suggest(
            items: items,
            filters: filtersToUse,
          );
      if (requestVersion == _requestVersion) state = AsyncData(result);
    } on Object catch (error, stackTrace) {
      if (requestVersion == _requestVersion) {
        state = AsyncError(error, stackTrace);
      }
    }
  }

  /// Requests the optional AI ideas without making them a dependency of the
  /// Recipes screen. If the local service is stopped or unavailable, the app
  /// keeps the curated catalog visible and explains what happened.
  Future<void> generateWithAi() async {
    final requestVersion = ++_requestVersion;
    state = const AsyncLoading<RecipeSuggestionResult>();
    try {
      final aiService = ref.read(aiRecipeSuggestionServiceProvider);
      if (aiService == null) {
        throw const RecipeSuggestionException(
          'AI recipes are not configured for this build.',
        );
      }
      final items = await ref.read(inventoryProvider.future);
      final profile = ref.read(authProvider).value?.profile;
      final preferences = profile == null
          ? const AppPreferences()
          : await ref
              .read(userPreferencesRepositoryProvider)
              .load(privateScopeForProfile(profile));
      final dietaryVegetarian = preferences.dietaryPreference == 'Vegetarian' ||
          preferences.dietaryPreference == 'Vegan';
      final filtersToUse = _filters.copyWith(
        vegetarian: _filters.vegetarian || dietaryVegetarian,
        avoidedIngredients: {
          ..._filters.avoidedIngredients,
          ...preferences.allergies,
        },
      );
      final result = await aiService.suggest(
        items: items,
        filters: filtersToUse,
      );
      if (requestVersion == _requestVersion) state = AsyncData(result);
    } on Object catch (error, stackTrace) {
      if (requestVersion != _requestVersion) return;
      try {
        final fallback = await _curatedFallback();
        state = AsyncData(
          fallback.copyWith(
            notice:
                'AI is unavailable right now, so FreshKeep is showing curated recipes instead. (${_friendlyError(error)})',
          ),
        );
      } on Object {
        state = AsyncError(error, stackTrace);
      }
    }
  }

  Future<RecipeSuggestionResult> _curatedFallback() async {
    final items = await ref.read(inventoryProvider.future);
    final profile = ref.read(authProvider).value?.profile;
    final preferences = profile == null
        ? const AppPreferences()
        : await ref
            .read(userPreferencesRepositoryProvider)
            .load(privateScopeForProfile(profile));
    final dietaryVegetarian = preferences.dietaryPreference == 'Vegetarian' ||
        preferences.dietaryPreference == 'Vegan';
    final filtersToUse = _filters.copyWith(
      vegetarian: _filters.vegetarian || dietaryVegetarian,
      avoidedIngredients: {
        ..._filters.avoidedIngredients,
        ...preferences.allergies,
      },
    );
    return ref.read(recipeSuggestionServiceProvider).suggest(
          items: items,
          filters: filtersToUse,
        );
  }

  String _friendlyError(Object error) {
    if (error is RecipeSuggestionException) return error.message;
    return 'Please check that the recipe service is running.';
  }
}

Uri? _recipeAiEndpoint() {
  const configured = String.fromEnvironment('FRESHKEEP_RECIPE_API_URL');
  if (configured.isNotEmpty) return Uri.tryParse(configured);
  if (!kDebugMode) return null;
  if (defaultTargetPlatform == TargetPlatform.android) {
    return Uri.parse('http://10.0.2.2:8787/recipe-suggestions');
  }
  return Uri.parse('http://127.0.0.1:8787/recipe-suggestions');
}
