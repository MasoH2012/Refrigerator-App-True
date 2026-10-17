import '../../../domain/models/food_item.dart';
import '../../../domain/models/recipe.dart';
import '../../../domain/models/recipe_filters.dart';
import 'curated_recipe_catalog.dart';

enum RecipeSuggestionSource { curated, aiGenerated, unavailable }

class RecipeSuggestionResult {
  const RecipeSuggestionResult({
    required this.recipes,
    required this.source,
    required this.generatedAt,
    this.notice,
  });

  final List<Recipe> recipes;
  final RecipeSuggestionSource source;
  final DateTime generatedAt;
  final String? notice;

  RecipeSuggestionResult copyWith({
    List<Recipe>? recipes,
    RecipeSuggestionSource? source,
    DateTime? generatedAt,
    String? notice,
    bool clearNotice = false,
  }) =>
      RecipeSuggestionResult(
        recipes: recipes ?? this.recipes,
        source: source ?? this.source,
        generatedAt: generatedAt ?? this.generatedAt,
        notice: clearNotice ? null : notice ?? this.notice,
      );
}

abstract interface class RecipeSuggestionService {
  Future<RecipeSuggestionResult> suggest({
    required List<FoodItem> items,
    required RecipeFilters filters,
  });
}

class CuratedRecipeSuggestionService implements RecipeSuggestionService {
  CuratedRecipeSuggestionService({
    // Kept as ignored compatibility parameters for existing callers/tests.
    Object? client,
    Uri? endpoint,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  @override
  Future<RecipeSuggestionResult> suggest({
    required List<FoodItem> items,
    required RecipeFilters filters,
  }) async {
    final today = _now();
    final usableItems =
        items.where((item) => item.daysUntilExpiration(today) >= 0).toList();

    // Recipe generation is intentionally local for now. This avoids network
    // failures, API keys, and timeouts while still tailoring the built-in
    // catalog to the user's inventory and filters.
    final curatedRecipes = CuratedRecipeCatalog.recipes
        .map((recipe) => _reconcileRecipe(recipe, usableItems, filters))
        .where((recipe) => _passesFilters(recipe, filters))
        .toList()
      ..sort(_compareRecipes);
    return RecipeSuggestionResult(
      recipes: curatedRecipes.take(8).toList(),
      source: RecipeSuggestionSource.curated,
      generatedAt: today,
      notice: curatedRecipes.isEmpty
          ? 'No built-in recipe matches every selected filter. Try removing a filter.'
          : items.isEmpty
              ? 'Showing starter recipes. Add food to tailor these ideas to your fridge.'
              : usableItems.isEmpty
                  ? 'Your tracked food is expired. Showing starter recipes while you refresh your inventory.'
                  : null,
    );
  }

  Recipe _reconcileRecipe(
    Recipe recipe,
    List<FoodItem> items,
    RecipeFilters filters,
  ) {
    final reconciledIngredients = recipe.ingredients
        .map((ingredient) => _reconcileIngredient(ingredient, items))
        .toList();
    final usedItemIds = reconciledIngredients
        .map((ingredient) => ingredient.inventoryItemId)
        .whereType<String>()
        .toSet();
    final expiringMatches = items.where((item) {
      final days = item.daysUntilExpiration(_now());
      return usedItemIds.contains(item.id) && days >= 0 && days <= 3;
    }).length;
    final fridgeMatches = reconciledIngredients
        .where((item) => item.source == RecipeIngredientSource.fridge)
        .length;
    final missing = reconciledIngredients
        .where((item) => item.source == RecipeIngredientSource.shopping)
        .length;
    final ingredientCount =
        reconciledIngredients.isEmpty ? 1 : reconciledIngredients.length;
    final matchScore = ((fridgeMatches / ingredientCount) * 65 +
            expiringMatches * (filters.prioritizeExpiring ? 18 : 8) -
            missing * 8)
        .clamp(0, 100)
        .round();

    return recipe.copyWith(
      ingredients: reconciledIngredients,
      servings: filters.servings,
      matchScore: matchScore,
      expiringMatchCount: expiringMatches,
      origin: recipe.origin == RecipeOrigin.curated
          ? RecipeOrigin.curated
          : recipe.origin,
    );
  }

  RecipeIngredient _reconcileIngredient(
    RecipeIngredient ingredient,
    List<FoodItem> items,
  ) {
    FoodItem? match;
    final requestedId = ingredient.inventoryItemId;
    if (requestedId != null) {
      for (final item in items) {
        if (item.id == requestedId &&
            _ingredientsMatch(ingredient.name, item.name)) {
          match = item;
          break;
        }
      }
    }
    match ??= _findIngredient(ingredient.name, items);

    if (match != null) {
      return ingredient.copyWith(
        source: match.storageLocation == StorageLocation.fridge
            ? RecipeIngredientSource.fridge
            : RecipeIngredientSource.pantry,
        inventoryItemId: match.id,
      );
    }
    if (ingredient.source == RecipeIngredientSource.fridge) {
      return ingredient.copyWith(
        source: RecipeIngredientSource.shopping,
        clearInventoryItemId: true,
      );
    }
    return ingredient.copyWith(clearInventoryItemId: true);
  }

  bool _passesFilters(Recipe recipe, RecipeFilters filters) {
    if (filters.underThirtyMinutes && recipe.minutes > 30) return false;
    if (filters.fridgeOnly &&
        recipe.ingredients.any(
          (ingredient) =>
              ingredient.source == RecipeIngredientSource.shopping ||
              (ingredient.inventoryItemId != null &&
                  ingredient.source != RecipeIngredientSource.fridge),
        )) {
      return false;
    }
    if (filters.vegetarian && !_isVegetarian(recipe)) return false;
    if (!filters.mustUseItemIds.every(recipe.usedInventoryItemIds.contains)) {
      return false;
    }

    final searchable = _normalize(
      '${recipe.name} ${recipe.ingredients.map((item) => item.name).join(' ')}',
    );
    return !filters.avoidedIngredients.any((avoided) {
      final normalized = _normalize(avoided);
      return normalized.isNotEmpty && searchable.contains(normalized);
    });
  }

  int _compareRecipes(Recipe a, Recipe b) {
    final expiring = b.expiringMatchCount.compareTo(a.expiringMatchCount);
    if (expiring != 0) return expiring;
    final score = b.matchScore.compareTo(a.matchScore);
    if (score != 0) return score;
    return a.minutes.compareTo(b.minutes);
  }

  bool _isVegetarian(Recipe recipe) {
    if (!recipe.tags.contains('vegetarian')) return false;
    final searchable = _normalize(
      '${recipe.name} ${recipe.ingredients.map((item) => item.name).join(' ')}',
    );
    const nonVegetarianTerms = {
      'beef',
      'pork',
      'chicken',
      'turkey',
      'lamb',
      'salmon',
      'tuna',
      'fish',
      'shrimp',
      'prawn',
      'crab',
      'lobster',
      'bacon',
      'ham',
      'sausage',
      'gelatin',
    };
    return !nonVegetarianTerms.any(
      (term) => RegExp('(^| )$term' r'( |$)').hasMatch(searchable),
    );
  }

  FoodItem? _findIngredient(String ingredient, List<FoodItem> items) {
    for (final item in items) {
      if (_ingredientsMatch(ingredient, item.name)) return item;
    }
    return null;
  }

  bool _ingredientsMatch(String ingredient, String itemName) {
    final ingredientName = _normalize(ingredient);
    final inventoryName = _normalize(itemName);
    if (ingredientName.isEmpty || inventoryName.isEmpty) return false;
    if (ingredientName == inventoryName ||
        ingredientName.contains(inventoryName) ||
        inventoryName.contains(ingredientName)) {
      return true;
    }
    final ingredientTokens = ingredientName.split(' ').toSet();
    final inventoryTokens = inventoryName.split(' ').toSet();
    return ingredientTokens.intersection(inventoryTokens).isNotEmpty;
  }

  String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), ' ')
      .replaceAll(RegExp(r'\b(baby|fresh|atlantic|large|small)\b'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim()
      .split(' ')
      .map((token) => token.endsWith('s') && token.length > 3
          ? token.substring(0, token.length - 1)
          : token)
      .join(' ');
}

class RecipeSuggestionException implements Exception {
  const RecipeSuggestionException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
