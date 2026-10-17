import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../domain/models/food_item.dart';
import '../../../domain/models/recipe.dart';
import '../../../domain/models/recipe_filters.dart';
import 'recipe_suggestion_service.dart';

/// Calls the optional FreshKeep recipe service. The OpenAI credential stays on
/// the server; this client only sends the signed-in user's recipe inputs.
class AiRecipeSuggestionService implements RecipeSuggestionService {
  AiRecipeSuggestionService({
    required this.endpoint,
    http.Client? client,
    DateTime Function()? now,
    this.timeout = const Duration(seconds: 45),
  })  : _client = client ?? http.Client(),
        _ownsClient = client == null,
        _now = now ?? DateTime.now;

  final Uri endpoint;
  final Duration timeout;
  final http.Client _client;
  final bool _ownsClient;
  final DateTime Function() _now;

  Future<void> dispose() async {
    if (_ownsClient) _client.close();
  }

  @override
  Future<RecipeSuggestionResult> suggest({
    required List<FoodItem> items,
    required RecipeFilters filters,
  }) async {
    final today = _now();
    final usableItems =
        items.where((item) => item.daysUntilExpiration(today) >= 0).toList();
    if (usableItems.isEmpty) {
      throw const RecipeSuggestionException(
        'Add at least one non-expired food item before using AI recipes.',
      );
    }

    final response = await _client
        .post(
          endpoint,
          headers: const {'content-type': 'application/json'},
          body: jsonEncode({
            'items': usableItems
                .map(
                  (item) => {
                    'id': item.id,
                    'name': item.name,
                    'quantity': item.quantity,
                    'category': item.category.name,
                    'storageLocation': item.storageLocation.name,
                    'expirationDate': item.expirationDate.toIso8601String(),
                    'daysUntilExpiration': item.daysUntilExpiration(today),
                  },
                )
                .toList(),
            'filters': filters.toJson(),
            'requestNonce': '${today.microsecondsSinceEpoch}',
          }),
        )
        .timeout(timeout);

    Map<String, Object?> payload;
    try {
      payload = Map<String, Object?>.from(jsonDecode(response.body) as Map);
    } catch (_) {
      throw RecipeSuggestionException(
        'The AI recipe service returned an invalid response.',
        statusCode: response.statusCode,
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = payload['error'] as String? ??
          'The AI recipe service is temporarily unavailable.';
      throw RecipeSuggestionException(message, statusCode: response.statusCode);
    }

    final rawRecipes = payload['recipes'];
    if (rawRecipes is! List) {
      throw const RecipeSuggestionException(
        'The AI recipe service returned no recipes.',
      );
    }
    final recipes = <Recipe>[];
    for (final raw in rawRecipes) {
      if (raw is! Map) continue;
      try {
        recipes.add(Recipe.fromJson(Map<String, Object?>.from(raw)));
      } catch (_) {
        // Ignore an individual malformed recipe while keeping valid results.
      }
    }
    if (recipes.isEmpty) {
      throw const RecipeSuggestionException(
        'The AI recipe service returned no usable recipes.',
      );
    }
    final generatedAt =
        DateTime.tryParse(payload['generatedAt'] as String? ?? '') ?? today;
    return RecipeSuggestionResult(
      recipes: recipes,
      source: RecipeSuggestionSource.aiGenerated,
      generatedAt: generatedAt,
      notice:
          'AI ideas use your current inventory. Check ingredients and food safety before cooking.',
    );
  }
}
