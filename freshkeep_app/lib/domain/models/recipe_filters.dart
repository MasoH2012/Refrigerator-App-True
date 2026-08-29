class RecipeFilters {
  const RecipeFilters({
    this.prioritizeExpiring = true,
    this.fridgeOnly = false,
    this.underThirtyMinutes = false,
    this.vegetarian = false,
    this.mustUseItemIds = const {},
    this.avoidedIngredients = const {},
    this.servings = 2,
  });

  final bool prioritizeExpiring;
  final bool fridgeOnly;
  final bool underThirtyMinutes;
  final bool vegetarian;
  final Set<String> mustUseItemIds;
  final Set<String> avoidedIngredients;
  final int servings;

  int get activeFilterCount => [
        prioritizeExpiring,
        fridgeOnly,
        underThirtyMinutes,
        vegetarian,
        mustUseItemIds.isNotEmpty,
        avoidedIngredients.isNotEmpty,
        servings != 2,
      ].where((value) => value).length;

  RecipeFilters copyWith({
    bool? prioritizeExpiring,
    bool? fridgeOnly,
    bool? underThirtyMinutes,
    bool? vegetarian,
    Set<String>? mustUseItemIds,
    Set<String>? avoidedIngredients,
    int? servings,
  }) =>
      RecipeFilters(
        prioritizeExpiring: prioritizeExpiring ?? this.prioritizeExpiring,
        fridgeOnly: fridgeOnly ?? this.fridgeOnly,
        underThirtyMinutes: underThirtyMinutes ?? this.underThirtyMinutes,
        vegetarian: vegetarian ?? this.vegetarian,
        mustUseItemIds: mustUseItemIds ?? this.mustUseItemIds,
        avoidedIngredients: avoidedIngredients ?? this.avoidedIngredients,
        servings: servings ?? this.servings,
      );

  Map<String, Object> toJson() => {
        'prioritizeExpiring': prioritizeExpiring,
        'fridgeOnly': fridgeOnly,
        'underThirtyMinutes': underThirtyMinutes,
        'vegetarian': vegetarian,
        'mustUseItemIds': mustUseItemIds.toList(),
        'avoidedIngredients': avoidedIngredients.toList(),
        'servings': servings,
      };
}
