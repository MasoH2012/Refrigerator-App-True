import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/seed/seed_data.dart';
import '../../../domain/models/recipe.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});
  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  final _filters = <String>{'Expiring soon'};

  @override
  Widget build(BuildContext context) => SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'COOK SMARTER',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'Recipes for you',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const Text('Healthy ideas using what you already have.'),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        'Expiring soon',
                        'Fridge only',
                        'Under 30 min',
                        'Vegetarian',
                      ]
                          .map(
                            (label) => FilterChip(
                              label: Text(label),
                              selected: _filters.contains(label),
                              onSelected: (selected) => setState(
                                () => selected
                                    ? _filters.add(label)
                                    : _filters.remove(label),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              sliver: SliverList.separated(
                itemCount: seedRecipes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) => index == 0
                    ? _FeaturedRecipe(recipe: seedRecipes[index])
                    : _RecipeCard(recipe: seedRecipes[index]),
              ),
            ),
          ],
        ),
      );
}

class _FeaturedRecipe extends StatelessWidget {
  const _FeaturedRecipe({required this.recipe});
  final Recipe recipe;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'Open ${recipe.name}',
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => context.push('/recipe/${recipe.id}'),
          child: Ink(
            height: 230,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              image: DecorationImage(
                image: NetworkImage(recipe.imageUrl),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(18),
              alignment: Alignment.bottomLeft,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xD917352B)],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Chip(label: Text('BEST MATCH · USES 3 ITEMS')),
                  Text(
                    recipe.name,
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${recipe.minutes} min   ·   ${recipe.calories} cal',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.recipe});
  final Recipe recipe;
  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/recipe/${recipe.id}'),
          child: Row(
            children: [
              Image.network(
                recipe.imageUrl,
                width: 112,
                height: 108,
                fit: BoxFit.cover,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recipe.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${recipe.minutes} min · ${recipe.calories} cal',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
