import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/recipe.dart';

abstract interface class SavedRecipeRepository {
  Future<List<Recipe>> load(String uid);
  Future<void> save(String uid, Recipe recipe);
  Future<void> delete(String uid, String recipeId);
}

/// Private user recipes live under users/{uid}/savedRecipes. Household
/// inventory is shared, but a person's original recipes remain their own.
class FirestoreSavedRecipeRepository implements SavedRecipeRepository {
  FirestoreSavedRecipeRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String uid) =>
      _firestore.collection('users').doc(uid).collection('savedRecipes');

  @override
  Future<List<Recipe>> load(String uid) async {
    final snapshot = await _collection(uid).get();
    return snapshot.docs
        .map((doc) {
          try {
            return Recipe.fromJson(
              Map<String, Object?>.from({...doc.data(), 'id': doc.id}),
            );
          } on Object {
            return null;
          }
        })
        .whereType<Recipe>()
        .toList();
  }

  @override
  Future<void> save(String uid, Recipe recipe) =>
      _collection(uid).doc(recipe.id).set(recipe.toJson());

  @override
  Future<void> delete(String uid, String recipeId) =>
      _collection(uid).doc(recipeId).delete();
}

/// Keeps the feature usable in local development before Firebase is
/// initialized. Production builds use Firestore through the provider.
class InMemorySavedRecipeRepository implements SavedRecipeRepository {
  final _recipesByUser = <String, Map<String, Recipe>>{};

  @override
  Future<List<Recipe>> load(String uid) async =>
      _recipesByUser[uid]?.values.toList() ?? const [];

  @override
  Future<void> save(String uid, Recipe recipe) async {
    (_recipesByUser[uid] ??= {})[recipe.id] = recipe;
  }

  @override
  Future<void> delete(String uid, String recipeId) async {
    _recipesByUser[uid]?.remove(recipeId);
  }
}
