import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/models/recipe_model.dart';

class RecipeCacheService {
  static const _keyPrefix = 'cached_recipe_';
  static const _keyIndex = 'cached_recipe_index';
  static const _maxCached = 20;

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<void> saveRecipe(RecipeModel recipe) async {
    try {
      final prefs = await _prefs;
      final json = _recipeToJson(recipe);
      await prefs.setString('$_keyPrefix${recipe.id}', jsonEncode(json));

      final index = prefs.getStringList(_keyIndex) ?? [];
      index.remove(recipe.id);
      index.insert(0, recipe.id);
      if (index.length > _maxCached) {
        final removed = index.removeLast();
        await prefs.remove('$_keyPrefix$removed');
      }
      await prefs.setStringList(_keyIndex, index);
    } catch (_) {}
  }

  Future<RecipeModel?> getRecipe(String id) async {
    try {
      final prefs = await _prefs;
      final raw = prefs.getString('$_keyPrefix$id');
      if (raw == null) return null;
      return RecipeModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<List<RecipeModel>> getCachedRecipes() async {
    try {
      final prefs = await _prefs;
      final index = prefs.getStringList(_keyIndex) ?? [];
      final recipes = <RecipeModel>[];
      for (final id in index) {
        final raw = prefs.getString('$_keyPrefix$id');
        if (raw != null) {
          try {
            recipes.add(RecipeModel.fromJson(
                jsonDecode(raw) as Map<String, dynamic>));
          } catch (_) {}
        }
      }
      return recipes;
    } catch (_) {
      return [];
    }
  }

  Map<String, dynamic> _recipeToJson(RecipeModel r) => {
        'id': r.id,
        'author_id': r.authorId,
        'title': r.title,
        'description': r.description,
        'image_url': r.imageUrl,
        'video_url': r.videoUrl,
        'prep_time_minutes': r.prepTimeMinutes,
        'cook_time_minutes': r.cookTimeMinutes,
        'difficulty': r.difficulty,
        'servings': r.servings,
        'budget_range': r.budgetRange,
        'is_ai_generated': r.isAiGenerated,
        'is_community': r.isCommunity,
        'is_published': r.isPublished,
        'health_tags': r.healthTags,
        'average_rating': r.averageRating,
        'ratings_count': r.ratingsCount,
        'views_count': r.viewsCount,
        'likes_count': r.likesCount,
        'created_at': r.createdAt?.toIso8601String(),
        if (r.author != null)
          'users': {
            'id': r.author!.id,
            'full_name': r.author!.fullName,
            'avatar_url': r.author!.avatarUrl,
          },
      };
}
