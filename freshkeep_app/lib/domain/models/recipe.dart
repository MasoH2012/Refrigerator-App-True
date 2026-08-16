class Recipe {
  const Recipe({
    required this.id,
    required this.name,
    required this.description,
    required this.minutes,
    required this.calories,
    required this.imageUrl,
    required this.ingredients,
    required this.steps,
  });

  final String id;
  final String name;
  final String description;
  final int minutes;
  final int calories;
  final String imageUrl;
  final List<String> ingredients;
  final List<String> steps;
}
