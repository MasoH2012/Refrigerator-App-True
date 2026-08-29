enum RecipeIngredientSource { fridge, pantry, shopping }

enum RecipeOrigin { curated, adapted, aiGenerated }

class RecipeIngredient {
  const RecipeIngredient({
    required this.name,
    this.quantity = '',
    this.source = RecipeIngredientSource.shopping,
    this.inventoryItemId,
  });

  final String name;
  final String quantity;
  final RecipeIngredientSource source;
  final String? inventoryItemId;

  String get displayText => quantity.trim().isEmpty
      ? name
      : '${quantity.trim()} ${name.trim()}'.trim();

  RecipeIngredient copyWith({
    String? name,
    String? quantity,
    RecipeIngredientSource? source,
    String? inventoryItemId,
    bool clearInventoryItemId = false,
  }) =>
      RecipeIngredient(
        name: name ?? this.name,
        quantity: quantity ?? this.quantity,
        source: source ?? this.source,
        inventoryItemId: clearInventoryItemId
            ? null
            : inventoryItemId ?? this.inventoryItemId,
      );

  Map<String, Object?> toJson() => {
        'name': name,
        'quantity': quantity,
        'source': source.name,
        'inventoryItemId': inventoryItemId,
      };

  factory RecipeIngredient.fromJson(Map<String, Object?> json) {
    final sourceName = json['source'] as String?;
    return RecipeIngredient(
      name: json['name']! as String,
      quantity: json['quantity'] as String? ?? '',
      source: RecipeIngredientSource.values
              .where(
                (value) => value.name == sourceName,
              )
              .firstOrNull ??
          RecipeIngredientSource.shopping,
      inventoryItemId: json['inventoryItemId'] as String?,
    );
  }
}

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
    this.servings = 2,
    this.origin = RecipeOrigin.curated,
    this.sourceUrl,
    this.tags = const [],
    this.matchScore = 0,
    this.expiringMatchCount = 0,
    this.caloriesAreEstimated = false,
  });

  final String id;
  final String name;
  final String description;
  final int minutes;
  final int calories;
  final String imageUrl;
  final List<RecipeIngredient> ingredients;
  final List<String> steps;
  final int servings;
  final RecipeOrigin origin;
  final String? sourceUrl;
  final List<String> tags;
  final int matchScore;
  final int expiringMatchCount;
  final bool caloriesAreEstimated;

  int get fridgeIngredientCount => ingredients
      .where((ingredient) => ingredient.source == RecipeIngredientSource.fridge)
      .length;

  int get missingIngredientCount => ingredients
      .where(
          (ingredient) => ingredient.source == RecipeIngredientSource.shopping)
      .length;

  Set<String> get usedInventoryItemIds => ingredients
      .map((ingredient) => ingredient.inventoryItemId)
      .whereType<String>()
      .toSet();

  bool get isAiAssisted => origin != RecipeOrigin.curated;

  Recipe copyWith({
    String? id,
    String? name,
    String? description,
    int? minutes,
    int? calories,
    String? imageUrl,
    List<RecipeIngredient>? ingredients,
    List<String>? steps,
    int? servings,
    RecipeOrigin? origin,
    String? sourceUrl,
    List<String>? tags,
    int? matchScore,
    int? expiringMatchCount,
    bool? caloriesAreEstimated,
  }) =>
      Recipe(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        minutes: minutes ?? this.minutes,
        calories: calories ?? this.calories,
        imageUrl: imageUrl ?? this.imageUrl,
        ingredients: ingredients ?? this.ingredients,
        steps: steps ?? this.steps,
        servings: servings ?? this.servings,
        origin: origin ?? this.origin,
        sourceUrl: sourceUrl ?? this.sourceUrl,
        tags: tags ?? this.tags,
        matchScore: matchScore ?? this.matchScore,
        expiringMatchCount: expiringMatchCount ?? this.expiringMatchCount,
        caloriesAreEstimated: caloriesAreEstimated ?? this.caloriesAreEstimated,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'minutes': minutes,
        'calories': calories,
        'imageUrl': imageUrl,
        'ingredients': ingredients.map((item) => item.toJson()).toList(),
        'steps': steps,
        'servings': servings,
        'origin': origin.name,
        'sourceUrl': sourceUrl,
        'tags': tags,
        'matchScore': matchScore,
        'expiringMatchCount': expiringMatchCount,
        'caloriesAreEstimated': caloriesAreEstimated,
      };

  factory Recipe.fromJson(Map<String, Object?> json) {
    final originName = json['origin'] as String?;
    return Recipe(
      id: json['id']! as String,
      name: json['name']! as String,
      description: json['description']! as String,
      minutes: (json['minutes']! as num).round(),
      calories: (json['calories']! as num).round(),
      imageUrl: json['imageUrl'] as String? ?? '',
      ingredients: (json['ingredients']! as List<Object?>)
          .map(
            (item) => RecipeIngredient.fromJson(
              Map<String, Object?>.from(item! as Map),
            ),
          )
          .toList(),
      steps: (json['steps']! as List<Object?>).cast<String>(),
      servings: (json['servings'] as num?)?.round() ?? 2,
      origin: RecipeOrigin.values
              .where(
                (value) => value.name == originName,
              )
              .firstOrNull ??
          RecipeOrigin.aiGenerated,
      sourceUrl: json['sourceUrl'] as String?,
      tags: (json['tags'] as List<Object?>?)?.cast<String>() ?? const [],
      matchScore: (json['matchScore'] as num?)?.round() ?? 0,
      expiringMatchCount: (json['expiringMatchCount'] as num?)?.round() ?? 0,
      caloriesAreEstimated: json['caloriesAreEstimated'] as bool? ?? true,
    );
  }
}
