import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshkeep_app/domain/models/recipe.dart';
import 'package:freshkeep_app/features/recipes/presentation/cooking_mode_screen.dart';

void main() {
  const recipe = Recipe(
    id: 'test-recipe',
    name: 'Garden Pasta',
    description: 'A test recipe.',
    minutes: 20,
    calories: 400,
    imageUrl: '',
    ingredients: [
      RecipeIngredient(
        name: 'tomatoes',
        quantity: '2',
        source: RecipeIngredientSource.fridge,
      ),
    ],
    steps: ['Chop the tomatoes.', 'Cook and serve.'],
  );

  testWidgets('walks through recipe steps and finishes cooking', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: CookingModeScreen(recipe: recipe)),
    );

    expect(find.text('Step 1 of 2'), findsOneWidget);
    expect(find.text('Chop the tomatoes.'), findsOneWidget);

    await tester.tap(find.text('Next step'));
    await tester.pumpAndSettle();

    expect(find.text('Step 2 of 2'), findsOneWidget);
    expect(find.text('Cook and serve.'), findsOneWidget);

    await tester.tap(find.text('Finish cooking'));
    await tester.pumpAndSettle();

    expect(find.text('Meal complete!'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
  });
}
