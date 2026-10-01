import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/inventory_repository.dart';
import '../../data/repositories/repository_providers.dart';
import '../../data/repositories/user_preferences_repository.dart';
import '../../domain/models/freshkeep_data.dart';
import '../../domain/models/food_item.dart';
import '../../domain/models/fridge_organization.dart';
import '../../domain/models/recipe.dart';
import '../../domain/models/refrigerator_model.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/models/data_scope.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/inventory/application/inventory_controller.dart';

final freshKeepDataServiceProvider = Provider<FreshKeepDataService>((ref) {
  return FreshKeepDataService(
    inventoryRepository: ref.read(inventoryRepositoryProvider),
    preferencesRepository: ref.read(userPreferencesRepositoryProvider),
  );
});

final freshKeepDataProvider =
    AsyncNotifierProvider<FreshKeepDataController, FreshKeepData>(
  FreshKeepDataController.new,
);

class FreshKeepDataController extends AsyncNotifier<FreshKeepData> {
  @override
  Future<FreshKeepData> build() async {
    final profile = ref.watch(authProvider).value?.profile;
    if (profile == null) {
      throw const FreshKeepDataException(
          'Sign in to load your FreshKeep data.');
    }

    // Watching inventory keeps the aggregate fresh when items are added,
    // edited, removed, or when the active household changes.
    final items = await ref.watch(inventoryProvider.future);
    return ref.read(freshKeepDataServiceProvider).load(
          profile: profile,
          foodItems: items,
        );
  }

  Future<void> refresh() async {
    state = const AsyncLoading<FreshKeepData>();
    state = await AsyncValue.guard(build);
  }
}

class FreshKeepDataService {
  FreshKeepDataService({
    required InventoryRepository inventoryRepository,
    required UserPreferencesRepository preferencesRepository,
  })  : _inventoryRepository = inventoryRepository,
        _preferencesRepository = preferencesRepository;

  final InventoryRepository _inventoryRepository;
  final UserPreferencesRepository _preferencesRepository;

  Future<FreshKeepData> load({
    required UserProfile profile,
    List<FoodItem>? foodItems,
  }) async {
    // Simulates a remote/account data request until the cloud data source is
    // connected. Local repositories remain the source of truth for now.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final items = foodItems ??
        await _inventoryRepository.loadItems(privateScopeForProfile(profile));
    final preferences =
        await _preferencesRepository.load(privateScopeForProfile(profile));
    final refrigerator = RefrigeratorCatalog.byId(profile.refrigeratorModel);

    return FreshKeepData(
      profile: profile,
      // Authentication only exposes a successful sign-in, never the raw
      // password. This flag is safe for account/settings UI.
      passwordConfigured: true,
      refrigerator: refrigerator,
      organization: _placeholderOrganization(refrigerator, items),
      foodItems: items,
      preferences: preferences,
      savedRecipes: _placeholderSavedRecipes(items),
      loadedAt: DateTime.now(),
      usingPlaceholderRecipes: true,
    );
  }

  FridgeOrganizationPlan? _placeholderOrganization(
    RefrigeratorModel? refrigerator,
    List<FoodItem> items,
  ) {
    if (refrigerator == null) return null;
    final refrigerated = items
        .where((item) => item.storageLocation == StorageLocation.fridge)
        .toList();
    return FridgeOrganizationPlan(
      assignments: refrigerated
          .map(
            (item) => FridgeOrganizationAssignment(
              itemId: item.id,
              itemName: item.name,
              zone: item.zone,
              reason: 'Current saved placement for ${refrigerator.shortName}.',
              size: 'medium',
            ),
          )
          .toList(),
      summary: refrigerated.isEmpty
          ? 'Add food to generate a refrigerator organization plan.'
          : 'Placeholder plan based on your saved refrigerator zones.',
      generatedAt: DateTime.now(),
    );
  }

  List<Recipe> _placeholderSavedRecipes(List<FoodItem> items) {
    final ingredientNames = items.take(3).map((item) => item.name).toList();
    final ingredients = ingredientNames.isEmpty
        ? const [
            RecipeIngredient(
              name: 'Seasonal vegetables',
              quantity: '2 cups',
              source: RecipeIngredientSource.fridge,
            ),
            RecipeIngredient(
              name: 'Olive oil',
              quantity: '1 tbsp',
              source: RecipeIngredientSource.pantry,
            ),
          ]
        : ingredientNames
            .map(
              (name) => RecipeIngredient(
                name: name,
                quantity: '1 serving',
                source: RecipeIngredientSource.fridge,
              ),
            )
            .toList();
    return [
      Recipe(
        id: 'placeholder-saved-recipe',
        name: 'FreshKeep house bowl',
        description:
            'A placeholder recipe built from ingredients in your account snapshot.',
        minutes: 20,
        calories: 420,
        imageUrl:
            'https://images.unsplash.com/photo-1547592180-85f173990554?auto=format&fit=crop&w=1200&q=80',
        ingredients: ingredients,
        steps: const [
          'Wash and prepare the ingredients.',
          'Cook or assemble until tender and well combined.',
          'Season to taste and serve immediately.',
        ],
        servings: 2,
        origin: RecipeOrigin.aiGenerated,
        tags: const ['placeholder', 'use what you have'],
        caloriesAreEstimated: true,
      ),
    ];
  }
}

class FreshKeepDataException implements Exception {
  const FreshKeepDataException(this.message);
  final String message;

  @override
  String toString() => message;
}
