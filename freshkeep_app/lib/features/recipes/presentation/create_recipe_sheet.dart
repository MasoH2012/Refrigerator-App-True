import 'package:flutter/material.dart';

import '../../../domain/models/recipe.dart';

class CreateRecipeSheet extends StatefulWidget {
  const CreateRecipeSheet({super.key});

  @override
  State<CreateRecipeSheet> createState() => _CreateRecipeSheetState();
}

class _CreateRecipeSheetState extends State<CreateRecipeSheet> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _minutes = TextEditingController(text: '30');
  final _servings = TextEditingController(text: '2');
  final _equipment = TextEditingController(text: 'Knife\nCutting board');
  final _steps = TextEditingController();
  final _ingredients = <_IngredientFields>[_IngredientFields()];

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _minutes.dispose();
    _servings.dispose();
    _equipment.dispose();
    _steps.dispose();
    for (final ingredient in _ingredients) {
      ingredient.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            20 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: ListView(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Create your own recipe',
                        style: Theme.of(context).textTheme.headlineSmall),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Text(
                  'Save ingredients, timing, steps, and the tools you need so you can cook it again on any device.'),
              const SizedBox(height: 18),
              TextField(
                controller: _name,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Recipe name',
                  prefixIcon: Icon(Icons.restaurant_menu),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _description,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Short description',
                  hintText: 'What makes this meal special?',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minutes,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Time (minutes)',
                        prefixIcon: Icon(Icons.timer_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _servings,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Servings'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _sectionTitle(context, 'Ingredients needed'),
              const SizedBox(height: 6),
              ..._ingredients.indexed
                  .map((entry) => _ingredientRow(entry.$1, entry.$2)),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () =>
                      setState(() => _ingredients.add(_IngredientFields())),
                  icon: const Icon(Icons.add),
                  label: const Text('Add ingredient'),
                ),
              ),
              const SizedBox(height: 8),
              _sectionTitle(context, 'Materials needed'),
              const SizedBox(height: 6),
              TextField(
                controller: _equipment,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText:
                      'One tool or appliance per line (for example: Blender)',
                ),
              ),
              const SizedBox(height: 18),
              _sectionTitle(context, 'Instructions'),
              const SizedBox(height: 6),
              TextField(
                controller: _steps,
                minLines: 5,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: 'Write one step per line',
                ),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save my recipe'),
              ),
            ],
          ),
        ),
      );

  Widget _ingredientRow(int index, _IngredientFields fields) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: fields.name,
                decoration: InputDecoration(
                  labelText: 'Ingredient ${index + 1}',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: fields.quantity,
                decoration: const InputDecoration(labelText: 'Amount'),
              ),
            ),
            if (_ingredients.length > 1)
              IconButton(
                tooltip: 'Remove ingredient',
                onPressed: () => setState(() {
                  final removed = _ingredients.removeAt(index);
                  removed.dispose();
                }),
                icon: const Icon(Icons.remove_circle_outline),
              ),
          ],
        ),
      );

  Widget _sectionTitle(BuildContext context, String title) => Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      );

  void _submit() {
    final name = _name.text.trim();
    final ingredients = _ingredients
        .map((fields) => RecipeIngredient(
              name: fields.name.text.trim(),
              quantity: fields.quantity.text.trim(),
            ))
        .where((ingredient) => ingredient.name.isNotEmpty)
        .toList();
    final steps = _steps.text
        .split('\n')
        .map((step) => step.trim())
        .where((step) => step.isNotEmpty)
        .toList();
    final minutes = int.tryParse(_minutes.text.trim()) ?? 0;
    final servings = int.tryParse(_servings.text.trim()) ?? 1;
    if (name.isEmpty || ingredients.isEmpty || steps.isEmpty || minutes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Add a name, at least one ingredient, time, and one instruction.')),
      );
      return;
    }
    final equipment = _equipment.text
        .split(RegExp(r'[\n,]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    Navigator.pop(
      context,
      Recipe(
        id: 'custom-${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        description: _description.text.trim().isEmpty
            ? 'A recipe created in FreshKeep.'
            : _description.text.trim(),
        minutes: minutes,
        calories: 0,
        caloriesAreEstimated: true,
        imageUrl: '',
        ingredients: ingredients,
        steps: steps,
        equipment:
            equipment.isEmpty ? const ['Knife', 'Cutting board'] : equipment,
        servings: servings.clamp(1, 50).toInt(),
        origin: RecipeOrigin.userCreated,
        tags: const ['My recipe'],
      ),
    );
  }
}

class _IngredientFields {
  final name = TextEditingController();
  final quantity = TextEditingController();

  void dispose() {
    name.dispose();
    quantity.dispose();
  }
}
