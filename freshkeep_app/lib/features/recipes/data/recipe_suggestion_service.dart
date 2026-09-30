import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../domain/models/food_item.dart';
import '../../../domain/models/recipe.dart';
import '../../../domain/models/recipe_filters.dart';

enum RecipeSuggestionSource { ai, unavailable }

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
}

abstract interface class RecipeSuggestionService {
  Future<RecipeSuggestionResult> suggest({
    required List<FoodItem> items,
    required RecipeFilters filters,
  });
}

class HybridRecipeSuggestionService implements RecipeSuggestionService {
  HybridRecipeSuggestionService({
    required http.Client client,
    required Uri? endpoint,
    DateTime Function()? now,
  })  : _client = client,
        _endpoint = endpoint,
        _now = now ?? DateTime.now;

  final http.Client _client;
  final Uri? _endpoint;
  final DateTime Function() _now;

  @override
  Future<RecipeSuggestionResult> suggest({
    required List<FoodItem> items,
    required RecipeFilters filters,
  }) async {
    final today = _now();
    final usableItems =
        items.where((item) => item.daysUntilExpiration(today) >= 0).toList();

    if (usableItems.isEmpty) {
      return RecipeSuggestionResult(
        recipes: const [],
        source: RecipeSuggestionSource.unavailable,
        generatedAt: today,
        notice:
            'Add at least one non-expired fridge item before generating recipes.',
      );
    }

    if (_endpoint == null) {
      return RecipeSuggestionResult(
        recipes: const [],
        source: RecipeSuggestionSource.unavailable,
        generatedAt: today,
        notice: 'AI recipe generation is not configured for this build.',
      );
    }

    try {
      final remoteRecipes = await _fetchRemoteSuggestions(
        items: usableItems,
        filters: filters,
      );
      return RecipeSuggestionResult(
        recipes: remoteRecipes,
        source: RecipeSuggestionSource.ai,
        generatedAt: today,
        notice: remoteRecipes.isEmpty
            ? 'The AI could not create a recipe that satisfies every selected filter.'
            : null,
      );
    } on Object catch (error) {
      return RecipeSuggestionResult(
        recipes: const [],
        source: RecipeSuggestionSource.unavailable,
        generatedAt: today,
        notice: error is RecipeSuggestionException && error.statusCode == 503
            ? 'The AI recipe server needs to be configured before it can create recipes.'
            : 'FreshKeep could not reach the AI recipe service. Try again shortly.',
      );
    }
  }

  Future<List<Recipe>> _fetchRemoteSuggestions({
    required List<FoodItem> items,
    required RecipeFilters filters,
  }) async {
    final response = await _client
        .post(
          _endpoint!,
          headers: const {'content-type': 'application/json'},
          body: jsonEncode({
            'items': items
                .map(
                  (item) => {
                    'id': item.id,
                    'name': item.name,
                    'quantity': item.quantity,
                    'category': item.category.name,
                    'storageLocation': item.storageLocation.name,
                    'expirationDate': item.expirationDate.toIso8601String(),
                    'daysUntilExpiration': item.daysUntilExpiration(_now()),
                  },
                )
                .toList(),
            'filters': filters.toJson(),
            'requestNonce': _now().microsecondsSinceEpoch,
          }),
        )
        // Recipe generation can include web search and structured output,
        // which can take longer than a normal API request.
        .timeout(const Duration(seconds: 90));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RecipeSuggestionException(
        'Recipe service returned ${response.statusCode}.',
        statusCode: response.statusCode,
      );
    }

    final payload = jsonDecode(response.body);
    if (payload is! Map<String, Object?> || payload['recipes'] is! List) {
      throw const FormatException('Invalid recipe service response.');
    }

    final parsed = <Recipe>[];
    for (final (index, value) in (payload['recipes']! as List).indexed) {
      if (value is! Map) continue;
      try {
        final json = Map<String, Object?>.from(value);
        json.putIfAbsent(
          'id',
          () => 'ai-${_now().millisecondsSinceEpoch}-$index',
        );
        json.putIfAbsent('imageUrl', () => '');
        final recipe = _reconcileRecipe(
          Recipe.fromJson(json),
          items,
          filters,
        );
        if (_passesFilters(recipe, filters)) parsed.add(recipe);
      } on Object {
        continue;
      }
    }

    parsed.sort(_compareRecipes);
    return parsed.take(8).toList();
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
