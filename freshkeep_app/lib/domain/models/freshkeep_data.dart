import 'app_preferences.dart';
import 'food_item.dart';
import 'fridge_organization.dart';
import 'recipe.dart';
import 'refrigerator_model.dart';
import 'user_profile.dart';

/// The complete account snapshot consumed by authenticated app screens.
///
/// Passwords are intentionally represented by [passwordConfigured] only. A
/// UI-facing service should never expose a raw password to widgets.
class FreshKeepData {
  const FreshKeepData({
    required this.profile,
    required this.passwordConfigured,
    required this.refrigerator,
    required this.organization,
    required this.foodItems,
    required this.preferences,
    required this.savedRecipes,
    required this.loadedAt,
    this.usingPlaceholderRecipes = false,
  });

  final UserProfile profile;
  final bool passwordConfigured;
  final RefrigeratorModel? refrigerator;
  final FridgeOrganizationPlan? organization;
  final List<FoodItem> foodItems;
  final AppPreferences preferences;
  final List<Recipe> savedRecipes;
  final DateTime loadedAt;
  final bool usingPlaceholderRecipes;

  List<FoodItem> get expiringSoon => foodItems
      .where((item) =>
          item.daysUntilExpiration(DateTime.now()) <= preferences.warningDays)
      .toList();

  List<String> get allergies => preferences.allergies;
}
