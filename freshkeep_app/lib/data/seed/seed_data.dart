import '../../domain/models/recipe.dart';

const seedRecipes = [
  Recipe(
    id: 'salmon-bowl',
    name: 'Roasted salmon power bowl',
    description:
        'A bright, balanced bowl that uses your salmon, spinach, and yogurt.',
    minutes: 25,
    calories: 510,
    imageUrl:
        'https://images.unsplash.com/photo-1540420773420-3366772f4999?auto=format&fit=crop&w=900&q=85',
    ingredients: [
      'Atlantic salmon',
      'Baby spinach',
      'Greek yogurt',
      'Brown rice'
    ],
    steps: [
      'Roast the salmon.',
      'Cook rice and wilt spinach.',
      'Mix yogurt dressing and assemble.'
    ],
  ),
  Recipe(
    id: 'green-wraps',
    name: 'Green goddess wraps',
    description: 'Crunchy, fresh, and protein-packed.',
    minutes: 20,
    calories: 420,
    imageUrl:
        'https://images.unsplash.com/photo-1565299507177-b0ac66763828?auto=format&fit=crop&w=900&q=85',
    ingredients: ['Baby spinach', 'Greek yogurt', 'Tortillas'],
    steps: ['Blend dressing.', 'Fill tortillas.', 'Wrap and serve.'],
  ),
  Recipe(
    id: 'yogurt-pancakes',
    name: 'Greek yogurt pancakes',
    description: 'A light, protein-rich breakfast.',
    minutes: 15,
    calories: 360,
    imageUrl:
        'https://images.unsplash.com/photo-1528207776546-365bb710ee93?auto=format&fit=crop&w=900&q=85',
    ingredients: ['Greek yogurt', 'Eggs', 'Flour'],
    steps: ['Mix batter.', 'Cook on a warm skillet.', 'Serve with fruit.'],
  ),
];
