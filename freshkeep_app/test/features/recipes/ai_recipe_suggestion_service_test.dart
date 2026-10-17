import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:freshkeep_app/domain/models/food_item.dart';
import 'package:freshkeep_app/domain/models/recipe_filters.dart';
import 'package:freshkeep_app/features/recipes/data/ai_recipe_suggestion_service.dart';
import 'package:freshkeep_app/features/recipes/data/recipe_suggestion_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('parses AI recipes and sends inventory filters to the server', () async {
    final client = MockClient((request) async {
      final body = jsonDecode(request.body) as Map<String, Object?>;
      expect((body['items']! as List).single['name'], 'Spinach');
      expect((body['filters']! as Map)['vegetarian'], true);
      return http.Response(
        jsonEncode({
          'generatedAt': '2026-08-22T12:00:00.000Z',
          'recipes': [
            {
              'id': 'ai-spinach-eggs',
              'name': 'Spinach Eggs',
              'description': 'A quick skillet breakfast.',
              'minutes': 15,
              'calories': 300,
              'servings': 2,
              'origin': 'aiGenerated',
              'sourceUrl': '',
              'imageUrl': '',
              'tags': ['vegetarian'],
              'ingredients': [
                {
                  'name': 'Spinach',
                  'quantity': '1 cup',
                  'source': 'fridge',
                  'inventoryItemId': 'spinach',
                },
              ],
              'steps': ['Cook the spinach and eggs.'],
            },
          ],
        }),
        200,
      );
    });
    final service = AiRecipeSuggestionService(
      endpoint: Uri.parse('http://localhost:8787/recipe-suggestions'),
      client: client,
      now: () => DateTime(2026, 8, 22),
    );

    final result = await service.suggest(
      items: [_item()],
      filters: const RecipeFilters(vegetarian: true),
    );

    expect(result.source, RecipeSuggestionSource.aiGenerated);
    expect(result.recipes.single.name, 'Spinach Eggs');
  });

  test('turns a service error into a typed exception', () async {
    final service = AiRecipeSuggestionService(
      endpoint: Uri.parse('http://localhost:8787/recipe-suggestions'),
      client: MockClient(
        (_) async => http.Response(jsonEncode({'error': 'Unavailable'}), 503),
      ),
      now: () => DateTime(2026, 8, 22),
    );

    expect(
      () => service.suggest(items: [_item()], filters: const RecipeFilters()),
      throwsA(isA<RecipeSuggestionException>()),
    );
  });
}

FoodItem _item() => FoodItem(
      id: 'spinach',
      name: 'Spinach',
      expirationDate: DateTime(2026, 8, 24),
      category: FoodCategory.produce,
      quantity: '1 bag',
      zone: FridgeZone.highHumidity,
      createdAt: DateTime(2026, 8, 22),
    );
