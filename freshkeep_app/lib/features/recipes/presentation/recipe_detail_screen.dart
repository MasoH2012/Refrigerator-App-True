import 'package:flutter/material.dart';

import '../../../data/seed/seed_data.dart';

class RecipeDetailScreen extends StatelessWidget {
  const RecipeDetailScreen({required this.recipeId, super.key});
  final String recipeId;

  @override
  Widget build(BuildContext context) {
    final recipe = seedRecipes.firstWhere(
      (item) => item.id == recipeId,
      orElse: () => seedRecipes.first,
    );
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(recipe.imageUrl, fit: BoxFit.cover),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList.list(
              children: [
                Text(
                  'BEST MATCH · HEALTHY',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  recipe.name,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  '${recipe.minutes} min   ·   ${recipe.calories} cal   ·   2 servings',
                ),
                const SizedBox(height: 14),
                Text(recipe.description),
                const SizedBox(height: 24),
                Text(
                  'Ingredients',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                ...recipe.ingredients.map(
                  (ingredient) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.check_circle_outline),
                    title: Text(ingredient),
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
