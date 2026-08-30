import 'package:flutter/material.dart';

import '../../../domain/models/recipe.dart';

class CookingModeScreen extends StatefulWidget {
  const CookingModeScreen({required this.recipe, super.key});

  final Recipe recipe;

  @override
  State<CookingModeScreen> createState() => _CookingModeScreenState();
}

class _CookingModeScreenState extends State<CookingModeScreen> {
  var _currentStep = 0;

  int get _stepCount => widget.recipe.steps.isEmpty ? 1 : widget.recipe.steps.length;

  String get _instruction => widget.recipe.steps.isEmpty
      ? 'This recipe does not include cooking instructions.'
      : widget.recipe.steps[_currentStep];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLastStep = _currentStep == _stepCount - 1;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Close cooking mode',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
        title: const Text('Cooking mode'),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_currentStep + 1) / _stepCount,
              minHeight: 5,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.recipe.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Step ${_currentStep + 1} of $_stepCount',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Material(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(24),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _instruction,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                height: 1.35,
                                color: colorScheme.onPrimaryContainer,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      child: ExpansionTile(
                        leading: const Icon(Icons.checklist),
                        title: Text(
                          'Ingredients (${widget.recipe.ingredients.length})',
                        ),
                        subtitle: const Text('Tap to review quantities'),
                        children: widget.recipe.ingredients
                            .map(
                              (ingredient) => ListTile(
                                dense: true,
                                leading: Icon(
                                  ingredient.source == RecipeIngredientSource.shopping
                                      ? Icons.add_shopping_cart
                                      : Icons.check_circle_outline,
                                ),
                                title: Text(ingredient.displayText),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.health_and_safety_outlined, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Check allergens and cook meat, seafood, and eggs to safe temperatures.',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _currentStep == 0
                          ? null
                          : () => setState(() => _currentStep--),
                      child: const Text('Previous'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: widget.recipe.steps.isEmpty
                          ? null
                          : isLastStep
                              ? _finishCooking
                              : () => setState(() => _currentStep++),
                      icon: Icon(isLastStep ? Icons.check : Icons.arrow_forward),
                      label: Text(isLastStep ? 'Finish cooking' : 'Next step'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _finishCooking() async {
    final shouldClose = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.celebration_outlined),
        title: const Text('Meal complete!'),
        content: Text('You finished ${widget.recipe.name}. Enjoy your meal!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep cooking'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Done'),
          ),
        ],
      ),
    );
    if (shouldClose == true && mounted) Navigator.pop(context);
  }
}
