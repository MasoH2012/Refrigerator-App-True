import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/recipe.dart';
import '../application/recipe_suggestions_controller.dart';

class RecipeDetailScreen extends ConsumerWidget {
  const RecipeDetailScreen({required this.recipeId, super.key});

  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggested =
        ref.watch(recipeSuggestionsProvider).valueOrNull?.recipes ?? const [];
    final recipe = suggested.where((item) => item.id == recipeId).firstOrNull;
    if (recipe == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Recipe')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'This generated recipe is no longer available. Return to Recipes and generate a new set.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    final calories = recipe.caloriesAreEstimated
        ? '~${recipe.calories} cal'
        : '${recipe.calories} cal';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _RecipeHero(recipe: recipe),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList.list(
              children: [
                Row(
                  children: [
                    Icon(
                      recipe.isAiAssisted
                          ? Icons.auto_awesome
                          : Icons.verified_outlined,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _originLabel(recipe),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  recipe.name,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  '${recipe.minutes} min   ·   $calories   ·   ${recipe.servings} servings',
                ),
                const SizedBox(height: 14),
                Text(recipe.description),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      avatar: const Icon(Icons.kitchen_outlined, size: 18),
                      label: Text(
                        '${recipe.fridgeIngredientCount} from your fridge',
                      ),
                    ),
                    if (recipe.expiringMatchCount > 0)
                      Chip(
                        avatar: const Icon(Icons.schedule, size: 18),
                        label: Text(
                          '${recipe.expiringMatchCount} expiring soon',
                        ),
                      ),
                    if (recipe.missingIngredientCount > 0)
                      Chip(
                        avatar:
                            const Icon(Icons.shopping_bag_outlined, size: 18),
                        label: Text(
                          '${recipe.missingIngredientCount} to buy',
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Ingredients',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                ...recipe.ingredients.map(
                  (ingredient) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      _ingredientIcon(ingredient.source),
                      color: _ingredientColor(context, ingredient.source),
                    ),
                    title: Text(ingredient.displayText),
                    subtitle: Text(_ingredientLabel(ingredient.source)),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Method', style: Theme.of(context).textTheme.titleLarge),
                ...recipe.steps.indexed.map(
                  (step) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 14,
                      child: Text('${step.$1 + 1}'),
                    ),
                    title: Text(step.$2),
                  ),
                ),
                if (recipe.isAiAssisted || recipe.caloriesAreEstimated) ...[
                  const SizedBox(height: 16),
                  Material(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(16),
                    child: const Padding(
                      padding: EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'AI-created recipes and calorie values are estimates. Check labels for allergens and follow safe cooking guidance.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (_sourceUri(recipe) case final source?) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => _copySource(context, source),
                    icon: const Icon(Icons.link),
                    label: const Text('Copy original recipe link'),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cooking mode started')),
                  ),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start cooking'),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipeHero extends StatelessWidget {
  const _RecipeHero({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    if (recipe.imageUrl.isNotEmpty) {
      return Image.network(
        recipe.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(context),
      );
    }
    return _fallback(context);
  }

  Widget _fallback(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.tertiaryContainer,
            ],
          ),
        ),
        child: Center(
          child: Icon(
            recipe.isAiAssisted ? Icons.auto_awesome : Icons.restaurant,
            size: 72,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
}

String _originLabel(Recipe recipe) => switch (recipe.origin) {
      RecipeOrigin.curated => 'CURATED RECIPE',
      RecipeOrigin.adapted => 'AI-ADAPTED RECIPE',
      RecipeOrigin.aiGenerated => 'AI-CREATED RECIPE',
    };

IconData _ingredientIcon(RecipeIngredientSource source) => switch (source) {
      RecipeIngredientSource.fridge => Icons.check_circle,
      RecipeIngredientSource.pantry => Icons.inventory_2_outlined,
      RecipeIngredientSource.shopping => Icons.add_shopping_cart,
    };

Color _ingredientColor(
  BuildContext context,
  RecipeIngredientSource source,
) =>
    switch (source) {
      RecipeIngredientSource.fridge => Theme.of(context).colorScheme.primary,
      RecipeIngredientSource.pantry => Theme.of(context).colorScheme.secondary,
      RecipeIngredientSource.shopping => Theme.of(context).colorScheme.error,
    };

String _ingredientLabel(RecipeIngredientSource source) => switch (source) {
      RecipeIngredientSource.fridge => 'In your fridge',
      RecipeIngredientSource.pantry => 'Pantry staple',
      RecipeIngredientSource.shopping => 'Add to shopping list',
    };

Uri? _sourceUri(Recipe recipe) {
  final uri = Uri.tryParse(recipe.sourceUrl ?? '');
  if (uri == null || !{'http', 'https'}.contains(uri.scheme)) return null;
  return uri;
}

Future<void> _copySource(BuildContext context, Uri source) async {
  await Clipboard.setData(ClipboardData(text: source.toString()));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Recipe source link copied.')),
  );
}
