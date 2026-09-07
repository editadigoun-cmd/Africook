import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/models/recipe_model.dart';
import '../../shared/models/message_model.dart';
import '../../shared/models/order_model.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;
  static User? get currentUser => client.auth.currentUser;
  static String? get currentUserId => currentUser?.id;

  // ─── AUTH ───────────────────────────────────────────────

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName, 'phone': phone},
    );
    if (response.user != null) {
      await client.from('users').insert({
        'id': response.user!.id,
        'email': email,
        'phone': phone,
        'full_name': fullName,
      });
    }
    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) =>
      client.auth.signInWithPassword(email: email, password: password);

  Future<void> signOut() => client.auth.signOut();

  Future<void> resetPassword(String email) =>
      client.auth.resetPasswordForEmail(email);

  // ─── PROFILE ────────────────────────────────────────────

  Future<UserModel?> getProfile(String userId) async {
    final data = await client.from('users').select().eq('id', userId).maybeSingle();
    if (data == null) return null;
    return UserModel.fromJson(data);
  }

  Future<void> updateProfile(String userId, Map<String, dynamic> data) =>
      client.from('users').update(data).eq('id', userId);

  // ─── RECIPES ────────────────────────────────────────────

  Future<List<RecipeModel>> getRecipes({
    String? categorySlug,
    String? search,
    String? difficulty,
    String sortBy = 'created_at',
    int limit = 20,
    int offset = 0,
  }) async {
    var query = client.from('recipes').select('''
      *,
      users!author_id(id, full_name, avatar_url),
      recipe_ingredients(*),
      recipe_steps(*),
      nutrition_info(*)
    ''').eq('is_published', true);

    if (search != null && search.isNotEmpty) {
      query = query.ilike('title', '%$search%');
    }
    if (difficulty != null) {
      query = query.eq('difficulty', difficulty);
    }
    if (categorySlug != null) {
      final catResult = await client
          .from('categories')
          .select('id')
          .eq('slug', categorySlug)
          .maybeSingle();
      if (catResult != null) {
        query = query.eq('category_id', catResult['id'] as int);
      }
    }

    final data = await query
        .order(sortBy, ascending: false)
        .range(offset, offset + limit - 1);

    return data.map(RecipeModel.fromJson).toList();
  }

  Future<RecipeModel?> getRecipe(String id) async {
    final data = await client.from('recipes').select('''
      *,
      users!author_id(id, full_name, avatar_url, bio),
      recipe_ingredients(*),
      recipe_steps(*),
      nutrition_info(*)
    ''').eq('id', id).maybeSingle();
    if (data == null) return null;
    return RecipeModel.fromJson(data);
  }

  Future<String> createRecipe(Map<String, dynamic> recipeData) async {
    final result = await client.from('recipes').insert(recipeData).select().single();
    return result['id'] as String;
  }

  Future<void> insertIngredients(
      String recipeId, List<Map<String, dynamic>> ingredients) =>
      client.from('recipe_ingredients').insert(
          ingredients.map((i) => {...i, 'recipe_id': recipeId}).toList());

  Future<void> insertSteps(
      String recipeId, List<Map<String, dynamic>> steps) =>
      client.from('recipe_steps').insert(
          steps.map((s) => {...s, 'recipe_id': recipeId}).toList());

  // ─── FAVORITES ──────────────────────────────────────────

  Future<List<String>> getFavoriteIds(String userId) async {
    final data = await client
        .from('favorites')
        .select('recipe_id')
        .eq('user_id', userId);
    return data.map((e) => e['recipe_id'] as String).toList();
  }

  Future<List<RecipeModel>> getFavorites(String userId) async {
    final data = await client.from('favorites').select('''
      recipe_id,
      recipes!recipe_id(*, users!author_id(id, full_name, avatar_url))
    ''').eq('user_id', userId).order('created_at', ascending: false);
    return data.map((e) => RecipeModel.fromJson(e['recipes'] as Map<String, dynamic>)).toList();
  }

  Future<void> toggleFavorite(String userId, String recipeId, bool add) async {
    if (add) {
      await client
          .from('favorites')
          .insert({'user_id': userId, 'recipe_id': recipeId});
    } else {
      await client
          .from('favorites')
          .delete()
          .eq('user_id', userId)
          .eq('recipe_id', recipeId);
    }
  }

  // ─── RATINGS ────────────────────────────────────────────

  Future<void> rateRecipe(
      String recipeId, String userId, int score, String? comment) async {
    await client.from('ratings').upsert({
      'recipe_id': recipeId,
      'user_id': userId,
      'score': score,
      'comment': comment,
    });
  }

  // ─── SHOPPING LIST ──────────────────────────────────────

  Future<List<RecipeModel>> getHistory(String userId) async {
    final data = await client
        .from('recipe_history')
        .select('*, recipes(*, users!author_id(id, full_name, avatar_url))')
        .eq('user_id', userId)
        .order('viewed_at', ascending: false)
        .limit(30);
    return data
        .map((e) => RecipeModel.fromJson(e['recipes'] as Map<String, dynamic>))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getMealPlan(String userId, DateTime weekStart) async {
    final end = weekStart.add(const Duration(days: 6));
    final data = await client
        .from('meal_plans')
        .select('*, recipes(id, title, image_url, prep_time_minutes, cook_time_minutes, difficulty, average_rating)')
        .eq('user_id', userId)
        .gte('plan_date', weekStart.toIso8601String().substring(0, 10))
        .lte('plan_date', end.toIso8601String().substring(0, 10))
        .order('plan_date');
    return data;
  }

  Future<void> addMealPlan(String userId, String recipeId, DateTime date, String mealType) async {
    await client.from('meal_plans').upsert({
      'user_id': userId,
      'recipe_id': recipeId,
      'plan_date': date.toIso8601String().substring(0, 10),
      'meal_type': mealType,
    }, onConflict: 'user_id,plan_date,meal_type');
  }

  Future<void> deleteMealPlan(String id) async {
    await client.from('meal_plans').delete().eq('id', id);
  }

  Future<List<Map<String, dynamic>>> getShoppingList(String userId) async {
    final data = await client
        .from('shopping_list_items')
        .select()
        .eq('user_id', userId)
        .order('category');
    return data;
  }

  Future<void> addShoppingItem(Map<String, dynamic> item) =>
      client.from('shopping_list_items').insert(item);

  Future<void> toggleShoppingItem(String id, bool checked) =>
      client.from('shopping_list_items').update({'is_checked': checked}).eq('id', id);

  Future<void> deleteShoppingItem(String id) =>
      client.from('shopping_list_items').delete().eq('id', id);

  Future<void> clearCheckedItems(String userId) => client
      .from('shopping_list_items')
      .delete()
      .eq('user_id', userId)
      .eq('is_checked', true);

  // ─── MESSAGING ──────────────────────────────────────────

  Future<ConversationModel?> getOrCreateConversation(
      String currentUserId, String otherUserId,
      {String? recipeId}) async {
    // Try to find existing conversation
    final existing = await client
        .from('conversations')
        .select('*, user_a:users!user_a_id(id,full_name,avatar_url), user_b:users!user_b_id(id,full_name,avatar_url)')
        .or('and(user_a_id.eq.$currentUserId,user_b_id.eq.$otherUserId),and(user_a_id.eq.$otherUserId,user_b_id.eq.$currentUserId)')
        .maybeSingle();

    if (existing != null) {
      return ConversationModel.fromJson(existing as Map<String, dynamic>, currentUserId);
    }

    final created = await client.from('conversations').insert({
      'user_a_id': currentUserId,
      'user_b_id': otherUserId,
      'recipe_id': recipeId,
    }).select('*, user_a:users!user_a_id(id,full_name,avatar_url), user_b:users!user_b_id(id,full_name,avatar_url)').single();

    return ConversationModel.fromJson(created as Map<String, dynamic>, currentUserId);
  }

  Future<List<ConversationModel>> getConversations(String userId) async {
    final data = await client
        .from('conversations')
        .select('*, user_a:users!user_a_id(id,full_name,avatar_url), user_b:users!user_b_id(id,full_name,avatar_url)')
        .or('user_a_id.eq.$userId,user_b_id.eq.$userId')
        .order('last_message_at', ascending: false);

    return data.map((e) => ConversationModel.fromJson(e, userId)).toList();
  }

  Future<List<MessageModel>> getMessages(String conversationId) async {
    final data = await client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);
    return data.map(MessageModel.fromJson).toList();
  }

  Future<MessageModel> sendMessage(MessageModel msg) async {
    final data = await client
        .from('messages')
        .insert(msg.toJson())
        .select()
        .single();
    await client.from('conversations').update({
      'last_message_at': DateTime.now().toIso8601String(),
    }).eq('id', msg.conversationId);
    return MessageModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> markMessagesRead(String conversationId, String userId) =>
      client
          .from('messages')
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .neq('sender_id', userId);

  RealtimeChannel subscribeToMessages(
      String conversationId, void Function(Map<String, dynamic>) onMessage) {
    return client
        .channel('messages:$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) => onMessage(payload.newRecord),
        )
        .subscribe();
  }

  // ─── COMMUNITY ──────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getComments(String recipeId) async {
    final data = await client
        .from('comments')
        .select('*, users!user_id(id, full_name, avatar_url)')
        .eq('recipe_id', recipeId)
        .isFilter('parent_id', null)
        .order('created_at', ascending: false);
    return data;
  }

  Future<void> addComment(
      String recipeId, String userId, String content, {String? parentId}) =>
      client.from('comments').insert({
        'recipe_id': recipeId,
        'user_id': userId,
        'content': content,
        'parent_id': parentId,
      });

  Future<void> toggleLike(String userId, String recipeId, bool add) async {
    if (add) {
      await client.from('recipe_likes').insert({'user_id': userId, 'recipe_id': recipeId});
    } else {
      await client
          .from('recipe_likes')
          .delete()
          .eq('user_id', userId)
          .eq('recipe_id', recipeId);
    }
  }

  Future<bool> isLiked(String userId, String recipeId) async {
    final result = await client
        .from('recipe_likes')
        .select('id')
        .eq('user_id', userId)
        .eq('recipe_id', recipeId)
        .maybeSingle();
    return result != null;
  }

  Future<List<RecipeModel>> getUserRecipes(String userId) async {
    final data = await client
        .from('recipes')
        .select('*, users!author_id(id, full_name, avatar_url)')
        .eq('author_id', userId)
        .order('created_at', ascending: false);
    return data.map(RecipeModel.fromJson).toList();
  }

  Future<List<RecipeModel>> getFollowedRecipes(String userId) async {
    final follows = await client
        .from('follows')
        .select('following_id')
        .eq('follower_id', userId);
    final ids = follows.map((f) => f['following_id'] as String).toList();
    if (ids.isEmpty) return [];
    final data = await client
        .from('recipes')
        .select('*, users!author_id(id, full_name, avatar_url)')
        .inFilter('author_id', ids)
        .order('created_at', ascending: false)
        .limit(30);
    return data.map(RecipeModel.fromJson).toList();
  }

  Future<void> toggleFollow(
      String followerId, String followingId, bool follow) async {
    if (follow) {
      await client.from('follows').insert(
          {'follower_id': followerId, 'following_id': followingId});
    } else {
      await client
          .from('follows')
          .delete()
          .eq('follower_id', followerId)
          .eq('following_id', followingId);
    }
  }

  // ─── ORDERS ─────────────────────────────────────────────

  Future<List<OrderModel>> getOrders(String userId) async {
    final data = await client
        .from('orders')
        .select('*, order_items(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return data.map(OrderModel.fromJson).toList();
  }

  Future<String> createOrder(Map<String, dynamic> orderData) async {
    final result =
        await client.from('orders').insert(orderData).select().single();
    return result['id'] as String;
  }

  Future<void> insertOrderItems(
      String orderId, List<Map<String, dynamic>> items) =>
      client.from('order_items').insert(
          items.map((i) => {...i, 'order_id': orderId}).toList());

  // ─── RESTAURANTS ────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getRestaurants({String? city}) async {
    var query = client.from('restaurants').select();
    if (city != null) query = query.eq('city', city);
    return query.order('rating', ascending: false);
  }

  Future<List<Map<String, dynamic>>> getRestaurantsForRecipe(
      String recipeId) async {
    final dishes = await client
        .from('restaurant_dishes')
        .select('restaurant_id')
        .eq('recipe_id', recipeId)
        .eq('is_available', true);
    final ids = dishes.map((d) => d['restaurant_id'] as String).toSet().toList();
    if (ids.isEmpty) return [];
    return client
        .from('restaurants')
        .select()
        .inFilter('id', ids)
        .order('rating', ascending: false);
  }

  Future<List<Map<String, dynamic>>> getRestaurantDishes(
          String restaurantId) =>
      client
          .from('restaurant_dishes')
          .select()
          .eq('restaurant_id', restaurantId)
          .eq('is_available', true);

  // ─── NOTIFICATIONS ──────────────────────────────────────

  Future<List<Map<String, dynamic>>> getNotifications(String userId) async =>
      client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

  Future<void> markNotificationsRead(String userId) =>
      client.from('notifications').update({'is_read': true}).eq('user_id', userId);

  // ─── AI HISTORY ─────────────────────────────────────────

  Future<void> saveAiGeneration({
    required String userId,
    required String ingredientsInput,
    required String promptUsed,
    required Map<String, dynamic> result,
  }) =>
      client.from('ai_generated_recipes').insert({
        'user_id': userId,
        'ingredients_input': ingredientsInput,
        'prompt_used': promptUsed,
        'result_recipe': result,
      });

  Future<List<Map<String, dynamic>>> getAiHistory(String userId) async =>
      client
          .from('ai_generated_recipes')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(20);
}
