import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/food_item.dart';

import '../../features/auth/presentation/auth_gate.dart';
import '../../features/inventory/presentation/add_item_screen.dart';
import '../../features/recipes/presentation/recipe_detail_screen.dart';
import '../../features/shopping/presentation/shopping_list_screen.dart';
import '../../features/household/presentation/household_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const AuthGate()),
      GoRoute(
        path: '/add',
        builder: (context, state) => AddItemScreen(
          item: state.extra as FoodItem?,
        ),
      ),
      GoRoute(
        path: '/recipe/:id',
        builder: (context, state) =>
            RecipeDetailScreen(recipeId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/shopping',
        // The default route animation can tear down the authenticated shell
        // while its inherited Material widgets still have dependents. A
        // no-transition page keeps the shopping route lifecycle atomic.
        pageBuilder: (context, state) => const NoTransitionPage(
          child: ShoppingListScreen(),
        ),
      ),
      GoRoute(
        path: '/household',
        builder: (context, state) => const HouseholdScreen(),
      ),
    ],
  );
});
