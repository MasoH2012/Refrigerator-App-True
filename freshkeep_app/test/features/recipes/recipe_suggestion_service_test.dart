import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:freshkeep_app/domain/models/food_item.dart';
import 'package:freshkeep_app/domain/models/recipe_filters.dart';
import 'package:freshkeep_app/features/recipes/data/recipe_suggestion_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final today = DateTime(2026, 8, 22);

  test('does not substitute static recipes when AI is not configured',
      () async {
    final client = http.Client();
    addTearDown(client.close);
    final service = HybridRecipeSuggestionService(
      client: client,
      endpoint: null,
      now: () => today,
    );

    final result = await service.suggest(
      items: [
        _item('spinach', 'Baby spinach', today.add(const Duration(days: 1))),
      ],
      filters: const RecipeFilters(),
    );

    expect(result.source, RecipeSuggestionSource.unavailable);
    expect(result.recipes, isEmpty);
    expect(result.notice, contains('not configured'));
  });

  test('sends current fridge inventory and requests fresh AI recipes',
      () async {
    final client = MockClient((request) async {
      final body = jsonDecode(request.body) as Map<String, Object?>;
      final items = body['items']! as List<Object?>;
      expect((items.single! as Map)['name'], 'Baby spinach');
      expect(body['requestNonce'], isNotNull);
      expect(body.containsKey('curatedCandidates'), isFalse);
      return http.Response(
        jsonEncode({
          'recipes': [
            _recipeJson(
              id: 'ai-spinach-pasta',
              name: 'Creamy spinach pasta',
              ingredients: [
                _ingredientJson('Spinach', 'spinach'),
                _ingredientJson('Pasta', null, source: 'shopping'),
              ],
            ),
          ],
        }),
        200,
      );
    });
    final service = HybridRecipeSuggestionService(
      client: client,
      endpoint: Uri.parse('https://recipes.example.test/suggest'),
      now: () => today,
    );

    final result = await service.suggest(
      items: [
        _item('spinach', 'Baby spinach', today.add(const Duration(days: 1))),
      ],
      filters: const RecipeFilters(),
    );

    expect(result.source, RecipeSuggestionSource.ai);
    expect(result.recipes.single.name, 'Creamy spinach pasta');
  });

  test('reconciles AI fridge claims against real inventory IDs', () async {
    final client = MockClient((request) async => http.Response(
          jsonEncode({
            'recipes': [
              _recipeJson(
                id: 'ai-spinach-eggs',
                name: 'Spinach eggs',
                tags: const ['vegetarian'],
                ingredients: [
                  _ingredientJson('Spinach', 'made-up-id'),
                  _ingredientJson('Eggs', 'eggs'),
                ],
              ),
            ],
          }),
          200,
        ));
    final service = HybridRecipeSuggestionService(
      client: client,
      endpoint: Uri.parse('https://recipes.example.test/suggest'),
      now: () => today,
    );

    final result = await service.suggest(
      items: [
        _item('spinach', 'Baby spinach', today.add(const Duration(days: 1))),
        _item('eggs', 'Eggs', today.add(const Duration(days: 5))),
      ],
      filters: const RecipeFilters(vegetarian: true),
    );

    expect(result.source, RecipeSuggestionSource.ai);
    expect(result.recipes.single.usedInventoryItemIds, {'spinach', 'eggs'});
    expect(result.recipes.single.missingIngredientCount, 0);
  });

  test('enforces fridge-only and avoided ingredients on AI results', () async {
    final client = MockClient((request) async => http.Response(
          jsonEncode({
            'recipes': [
              _recipeJson(
                id: 'salmon-bowl',
                name: 'Salmon bowl',
                ingredients: [
                  _ingredientJson('Salmon', null, source: 'shopping'),
                  _ingredientJson('Spinach', 'spinach'),
                ],
              ),
              _recipeJson(
                id: 'green-wraps',
                name: 'Green wraps',
                tags: const ['vegetarian'],
                ingredients: [
                  _ingredientJson('Spinach', 'spinach'),
                  _ingredientJson('Greek yogurt', 'yogurt'),
                  _ingredientJson('Tortillas', 'tortilla'),
                ],
              ),
            ],
          }),
          200,
        ));
    final service = HybridRecipeSuggestionService(
      client: client,
      endpoint: Uri.parse('https://recipes.example.test/suggest'),
      now: () => today,
    );

    final result = await service.suggest(
      items: [
        _item('spinach', 'Baby spinach', today.add(const Duration(days: 1))),
        _item('yogurt', 'Greek yogurt', today.add(const Duration(days: 2))),
        _item('tortilla', 'Tortillas', today.add(const Duration(days: 10))),
      ],
      filters: const RecipeFilters(
        fridgeOnly: true,
        avoidedIngredients: {'salmon'},
      ),
    );

    expect(result.recipes.map((recipe) => recipe.id), ['green-wraps']);
  });

  test('shows unavailable state rather than static recipes on API failure',
      () async {
    final client = MockClient((request) async => http.Response('error', 503));
    final service = HybridRecipeSuggestionService(
      client: client,
      endpoint: Uri.parse('https://recipes.example.test/suggest'),
      now: () => today,
    );

    final result = await service.suggest(
      items: [
        _item('spinach', 'Baby spinach', today.add(const Duration(days: 1))),
      ],
      filters: const RecipeFilters(),
    );

    expect(result.source, RecipeSuggestionSource.unavailable);
    expect(result.recipes, isEmpty);
    expect(result.notice, contains('configured'));
  });
}

Map<String, Object?> _recipeJson({
  required String id,
  required String name,
  required List<Map<String, Object?>> ingredients,
  List<String> tags = const [],
}) =>
    {
      'id': id,
      'name': name,
      'description': 'A fresh recipe based on the current refrigerator.',
      'minutes': 20,
      'calories': 350,
      'servings': 2,
      'origin': 'aiGenerated',
      'sourceUrl': null,
      'imageUrl': '',
      'tags': tags,
      'matchScore': 0,
      'expiringMatchCount': 0,
      'caloriesAreEstimated': true,
      'ingredients': ingredients,
      'steps': ['Prepare the ingredients and cook until done.'],
    };

Map<String, Object?> _ingredientJson(
  String name,
  String? inventoryItemId, {
  String source = 'fridge',
}) =>
    {
      'name': name,
      'quantity': '1 serving',
      'source': source,
      'inventoryItemId': inventoryItemId,
    };

FoodItem _item(String id, String name, DateTime expirationDate) => FoodItem(
      id: id,
      name: name,
      expirationDate: expirationDate,
      category: FoodCategory.produce,
      quantity: '1',
      zone: FridgeZone.middleShelf,
      createdAt: DateTime(2026, 8, 20),
    );
