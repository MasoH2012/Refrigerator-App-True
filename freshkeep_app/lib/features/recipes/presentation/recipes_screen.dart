import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/food_item.dart';
import '../../../domain/models/recipe.dart';
import '../../../domain/models/recipe_filters.dart';
import '../../inventory/application/inventory_controller.dart';
import '../application/recipe_suggestions_controller.dart';
import '../data/recipe_suggestion_service.dart';

class RecipesScreen extends ConsumerStatefulWidget {
  const RecipesScreen({super.key});

  @override
  ConsumerState<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends ConsumerState<RecipesScreen> {
  RecipeFilters _filters = const RecipeFilters();

  @override
  Widget build(BuildContext context) {
    final inventory = ref.watch(inventoryProvider).value ?? const <FoodItem>[];
    final suggestions = ref.watch(recipeSuggestionsProvider);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
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
                                style:
                                    Theme.of(context).textTheme.headlineLarge,
                              ),
                              const Text(
                                'Healthy ideas that prioritize what expires first.',
                              ),
                            ],
                          ),
                        ),
                        IconButton.filledTonal(
                          tooltip: 'Refresh recipe suggestions',
                          onPressed: suggestions.isLoading ? null : _refresh,
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilterChip(
                          avatar: const Icon(Icons.schedule, size: 18),
                          label: const Text('Expiring soon'),
                          selected: _filters.prioritizeExpiring,
                          onSelected: (value) => _applyFilters(
                            _filters.copyWith(prioritizeExpiring: value),
                          ),
                        ),
                        FilterChip(
                          avatar: const Icon(Icons.kitchen_outlined, size: 18),
                          label: const Text('Fridge only'),
                          selected: _filters.fridgeOnly,
                          onSelected: (value) => _applyFilters(
                            _filters.copyWith(fridgeOnly: value),
                          ),
                        ),
                        FilterChip(
                          avatar: const Icon(Icons.timer_outlined, size: 18),
                          label: const Text('Under 30 min'),
                          selected: _filters.underThirtyMinutes,
                          onSelected: (value) => _applyFilters(
                            _filters.copyWith(underThirtyMinutes: value),
                          ),
                        ),
                        FilterChip(
                          avatar: const Icon(Icons.eco_outlined, size: 18),
                          label: const Text('Vegetarian'),
                          selected: _filters.vegetarian,
                          onSelected: (value) => _applyFilters(
                            _filters.copyWith(vegetarian: value),
                          ),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.tune, size: 18),
                          label: Text(
                            _filters.mustUseItemIds.isEmpty &&
                                    _filters.avoidedIngredients.isEmpty &&
                                    _filters.servings == 2
                                ? 'Customize'
                                : 'Customize · ${_customFilterCount()}',
                          ),
                          onPressed: () => _showFilters(inventory),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            ...suggestions.when(
              loading: () => const [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 14),
                        Text('Matching recipes to your fridge…'),
                      ],
                    ),
                  ),
                ),
              ],
              error: (error, stackTrace) => [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _RecipeError(onRetry: _refresh),
                ),
              ],
              data: (result) => _resultSlivers(result, inventory),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _resultSlivers(
    RecipeSuggestionResult result,
    List<FoodItem> inventory,
  ) {
    if (inventory.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _EmptyRecipes(
            icon: Icons.kitchen_outlined,
            title: 'Your fridge is empty',
            message: 'Add food on the Home tab to get tailored recipes.',
          ),
        ),
      ];
    }

    if (result.recipes.isEmpty) {
      final unavailable = result.source == RecipeSuggestionSource.unavailable;
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _EmptyRecipes(
            icon: unavailable
                ? Icons.auto_awesome_outlined
                : Icons.filter_alt_off_outlined,
            title: unavailable
                ? 'AI recipes are unavailable'
                : 'No AI recipe matches every filter',
            message: result.notice ??
                'Try allowing one shopping item or removing a must-use ingredient.',
            actionLabel: unavailable ? 'Try again' : 'Reset filters',
            onAction: unavailable
                ? _refresh
                : () => _applyFilters(const RecipeFilters()),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        sliver: SliverToBoxAdapter(
          child: _SuggestionSummary(
            result: result,
            inventoryCount: inventory.length,
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        sliver: SliverList.separated(
          itemCount: result.recipes.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == result.recipes.length) {
              return FilledButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Generate new recipe ideas'),
              );
            }
            return index == 0
                ? _FeaturedRecipe(recipe: result.recipes[index])
                : _RecipeCard(recipe: result.recipes[index]);
          },
        ),
      ),
    ];
  }

  Future<void> _refresh() =>
      ref.read(recipeSuggestionsProvider.notifier).refresh(filters: _filters);

  Future<void> _applyFilters(RecipeFilters filters) async {
    setState(() => _filters = filters);
    await ref
        .read(recipeSuggestionsProvider.notifier)
        .refresh(filters: filters);
  }

  int _customFilterCount() =>
      (_filters.mustUseItemIds.isNotEmpty ? 1 : 0) +
      (_filters.avoidedIngredients.isNotEmpty ? 1 : 0) +
      (_filters.servings == 2 ? 0 : 1);

  Future<void> _showFilters(List<FoodItem> items) async {
    final selected = await showModalBottomSheet<RecipeFilters>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _RecipeFiltersSheet(
        initial: _filters,
        items: items,
      ),
    );
    if (selected != null) await _applyFilters(selected);
  }
}

class _SuggestionSummary extends StatelessWidget {
  const _SuggestionSummary({
    required this.result,
    required this.inventoryCount,
  });

  final RecipeSuggestionResult result;
  final int inventoryCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              child: const Icon(Icons.auto_awesome),
            ),
            title: const Text(
              'FreshKeep AI recipes',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              'Created or discovered for $inventoryCount available fridge items.',
            ),
          ),
        ),
        if (result.notice != null) ...[
          const SizedBox(height: 8),
          Material(
            color: Theme.of(context).colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(result.notice!)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _FeaturedRecipe extends StatelessWidget {
  const _FeaturedRecipe({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'Open ${recipe.name}',
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.push('/recipe/${recipe.id}'),
            child: SizedBox(
              height: 238,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _RecipeArtwork(recipe: recipe),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xE017352B)],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _RecipeBadge(recipe: recipe),
                        const SizedBox(height: 8),
                        Text(
                          recipe.name,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _recipeMetadata(recipe),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
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
              SizedBox(
                width: 112,
                height: 124,
                child: _RecipeArtwork(recipe: recipe),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              recipe.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          if (recipe.isAiAssisted)
                            const Icon(Icons.auto_awesome, size: 18),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recipe.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _recipeMetadata(recipe),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      if (recipe.missingIngredientCount > 0)
                        Text(
                          '${recipe.missingIngredientCount} item${recipe.missingIngredientCount == 1 ? '' : 's'} to buy',
                          style: Theme.of(context).textTheme.bodySmall,
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

class _RecipeBadge extends StatelessWidget {
  const _RecipeBadge({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final label = recipe.expiringMatchCount > 0
        ? 'USES ${recipe.expiringMatchCount} EXPIRING SOON'
        : 'USES ${recipe.fridgeIngredientCount} FRIDGE ITEMS';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        recipe.isAiAssisted ? 'AI · $label' : 'BEST MATCH · $label',
        style: const TextStyle(
          color: Color(0xFF17352B),
          fontWeight: FontWeight.w800,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _RecipeArtwork extends StatelessWidget {
  const _RecipeArtwork({required this.recipe});

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
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
}

class _RecipeFiltersSheet extends StatefulWidget {
  const _RecipeFiltersSheet({
    required this.initial,
    required this.items,
  });

  final RecipeFilters initial;
  final List<FoodItem> items;

  @override
  State<_RecipeFiltersSheet> createState() => _RecipeFiltersSheetState();
}

class _RecipeFiltersSheetState extends State<_RecipeFiltersSheet> {
  late Set<String> _mustUseItemIds;
  late int _servings;
  late final TextEditingController _avoidController;

  @override
  void initState() {
    super.initState();
    _mustUseItemIds = {...widget.initial.mustUseItemIds};
    _servings = widget.initial.servings;
    _avoidController = TextEditingController(
      text: widget.initial.avoidedIngredients.join(', '),
    );
  }

  @override
  void dispose() {
    _avoidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          14,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Customize recipes',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Text(
              'FreshKeep checks these preferences again after AI responds.',
            ),
            const SizedBox(height: 20),
            Text('Servings', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('1')),
                ButtonSegment(value: 2, label: Text('2')),
                ButtonSegment(value: 4, label: Text('4')),
                ButtonSegment(value: 6, label: Text('6')),
              ],
              selected: {_servings},
              onSelectionChanged: (values) =>
                  setState(() => _servings = values.single),
            ),
            const SizedBox(height: 22),
            Text(
              'Ingredients that must be used',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text('Choose any food you especially want to use up.'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.items
                  .map(
                    (item) => FilterChip(
                      label: Text(item.name),
                      selected: _mustUseItemIds.contains(item.id),
                      onSelected: (selected) => setState(
                        () => selected
                            ? _mustUseItemIds.add(item.id)
                            : _mustUseItemIds.remove(item.id),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 22),
            Text(
              'Avoid ingredients',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _avoidController,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                hintText: 'Example: peanuts, shellfish, mushrooms',
                prefixIcon: Icon(Icons.block_outlined),
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.check),
              label: const Text('Apply recipe preferences'),
            ),
          ],
        ),
      );

  void _submit() {
    final avoided = _avoidController.text
        .split(',')
        .map((value) => value.trim().toLowerCase())
        .where((value) => value.isNotEmpty)
        .toSet();
    Navigator.pop(
      context,
      widget.initial.copyWith(
        mustUseItemIds: _mustUseItemIds,
        avoidedIngredients: avoided,
        servings: _servings,
      ),
    );
  }
}

class _RecipeError extends StatelessWidget {
  const _RecipeError({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => _EmptyRecipes(
        icon: Icons.cloud_off_outlined,
        title: 'Recipes could not be loaded',
        message: 'Check your connection and try again.',
        actionLabel: 'Try again',
        onAction: onRetry,
      );
}

class _EmptyRecipes extends StatelessWidget {
  const _EmptyRecipes({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 52,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(message, textAlign: TextAlign.center),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 18),
                FilledButton.tonal(
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      );
}

String _recipeMetadata(Recipe recipe) {
  final calories = recipe.caloriesAreEstimated
      ? '~${recipe.calories} cal'
      : '${recipe.calories} cal';
  return '${recipe.minutes} min · $calories · ${recipe.fridgeIngredientCount} from fridge';
}
