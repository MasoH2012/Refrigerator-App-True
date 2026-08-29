import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../domain/models/recipe_filters.dart';
import '../../inventory/application/inventory_controller.dart';
import '../data/recipe_suggestion_service.dart';

const _recipeApiUrl = String.fromEnvironment('FRESHKEEP_RECIPE_API_URL');

final recipeHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final recipeSuggestionServiceProvider = Provider<RecipeSuggestionService>(
  (ref) => HybridRecipeSuggestionService(
    client: ref.watch(recipeHttpClientProvider),
    endpoint: _configuredEndpoint(),
  ),
);

Uri? _configuredEndpoint() {
  final configured = _recipeApiUrl.trim();
  if (configured.isNotEmpty) {
    final uri = Uri.tryParse(configured);
    if (uri != null &&
        {'http', 'https'}.contains(uri.scheme) &&
        uri.host.isNotEmpty) {
      return uri;
    }
  }

  if (!kDebugMode) return null;
  final host = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
      ? '10.0.2.2'
      : '127.0.0.1';
  return Uri.parse('http://$host:8787/recipe-suggestions');
}

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
    return ref.read(recipeSuggestionServiceProvider).suggest(
          items: items,
          filters: _filters,
        );
  }

  Future<void> refresh({RecipeFilters? filters}) async {
    if (filters != null) _filters = filters;
    final requestVersion = ++_requestVersion;
    final items = await ref.read(inventoryProvider.future);
    state = const AsyncLoading<RecipeSuggestionResult>();
    try {
      final result = await ref.read(recipeSuggestionServiceProvider).suggest(
            items: items,
            filters: _filters,
          );
      if (requestVersion == _requestVersion) state = AsyncData(result);
    } on Object catch (error, stackTrace) {
      if (requestVersion == _requestVersion) {
        state = AsyncError(error, stackTrace);
      }
    }
  }
}
