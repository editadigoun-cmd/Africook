class RecipeModel {
  final String id;
  final String? authorId;
  final String title;
  final String? description;
  final int? categoryId;
  final String? imageUrl;
  final String? videoUrl;
  final int? prepTimeMinutes;
  final int? cookTimeMinutes;
  final String? difficulty;
  final int servings;
  final String? budgetRange;
  final bool isAiGenerated;
  final bool isCommunity;
  final bool isPublished;
  final List<String> healthTags;
  final double averageRating;
  final int ratingsCount;
  final int viewsCount;
  final DateTime? createdAt;
  final UserModel? author;
  final List<RecipeIngredient> ingredients;
  final List<RecipeStep> steps;
  final NutritionInfo? nutrition;
  bool isFavorite;

  RecipeModel({
    required this.id,
    this.authorId,
    required this.title,
    this.description,
    this.categoryId,
    this.imageUrl,
    this.videoUrl,
    this.prepTimeMinutes,
    this.cookTimeMinutes,
    this.difficulty,
    this.servings = 2,
    this.budgetRange,
    this.isAiGenerated = false,
    this.isCommunity = false,
    this.isPublished = true,
    this.healthTags = const [],
    this.averageRating = 0,
    this.ratingsCount = 0,
    this.viewsCount = 0,
    this.createdAt,
    this.author,
    this.ingredients = const [],
    this.steps = const [],
    this.nutrition,
    this.isFavorite = false,
  });

  int get totalTimeMinutes => (prepTimeMinutes ?? 0) + (cookTimeMinutes ?? 0);

  factory RecipeModel.fromJson(Map<String, dynamic> json) => RecipeModel(
        id: json['id'] as String,
        authorId: json['author_id'] as String?,
        title: json['title'] as String,
        description: json['description'] as String?,
        categoryId: json['category_id'] as int?,
        imageUrl: json['image_url'] as String?,
        videoUrl: json['video_url'] as String?,
        prepTimeMinutes: json['prep_time_minutes'] as int?,
        cookTimeMinutes: json['cook_time_minutes'] as int?,
        difficulty: json['difficulty'] as String?,
        servings: json['servings'] as int? ?? 2,
        budgetRange: json['budget_range'] as String?,
        isAiGenerated: json['is_ai_generated'] as bool? ?? false,
        isCommunity: json['is_community'] as bool? ?? false,
        isPublished: json['is_published'] as bool? ?? true,
        healthTags: (json['health_tags'] as List?)?.cast<String>() ?? [],
        averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0,
        ratingsCount: json['ratings_count'] as int? ?? 0,
        viewsCount: json['views_count'] as int? ?? 0,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
        author: json['users'] != null
            ? UserModel.fromJson(json['users'] as Map<String, dynamic>)
            : null,
        ingredients: json['recipe_ingredients'] != null
            ? List<dynamic>.from(json['recipe_ingredients'] as Iterable)
                .map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
                .toList()
            : [],
        steps: json['recipe_steps'] != null
            ? List<dynamic>.from(json['recipe_steps'] as Iterable)
                .map((e) => RecipeStep.fromJson(e as Map<String, dynamic>))
                .toList()
            : [],
        nutrition: () {
          final raw = json['nutrition_info'];
          if (raw == null) return null;
          final list = List<dynamic>.from(raw as Iterable);
          if (list.isEmpty) return null;
          return NutritionInfo.fromJson(list.first as Map<String, dynamic>);
        }(),
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'category_id': categoryId,
        'image_url': imageUrl,
        'video_url': videoUrl,
        'prep_time_minutes': prepTimeMinutes,
        'cook_time_minutes': cookTimeMinutes,
        'difficulty': difficulty,
        'servings': servings,
        'budget_range': budgetRange,
        'is_ai_generated': isAiGenerated,
        'is_community': isCommunity,
        'health_tags': healthTags,
      };
}

class RecipeIngredient {
  final int? id;
  final String name;
  final String? quantity;
  final String? unit;
  final bool isOptional;

  RecipeIngredient({
    this.id,
    required this.name,
    this.quantity,
    this.unit,
    this.isOptional = false,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) => RecipeIngredient(
        id: json['id'] as int?,
        name: json['name'] as String,
        quantity: json['quantity'] as String?,
        unit: json['unit'] as String?,
        isOptional: json['is_optional'] as bool? ?? false,
      );

  String get displayQuantity {
    if (quantity == null && unit == null) return '';
    if (unit == null) return quantity ?? '';
    return '${quantity ?? ''} $unit'.trim();
  }
}

class RecipeStep {
  final int? id;
  final int stepNumber;
  final String instruction;
  final String? imageUrl;
  final int? durationMinutes;

  RecipeStep({
    this.id,
    required this.stepNumber,
    required this.instruction,
    this.imageUrl,
    this.durationMinutes,
  });

  factory RecipeStep.fromJson(Map<String, dynamic> json) => RecipeStep(
        id: json['id'] as int?,
        stepNumber: json['step_number'] as int,
        instruction: json['instruction'] as String,
        imageUrl: json['image_url'] as String?,
        durationMinutes: json['duration_minutes'] as int?,
      );
}

class NutritionInfo {
  final int? calories;
  final double? proteinsG;
  final double? carbsG;
  final double? fatsG;
  final double? fiberG;

  NutritionInfo({
    this.calories,
    this.proteinsG,
    this.carbsG,
    this.fatsG,
    this.fiberG,
  });

  factory NutritionInfo.fromJson(Map<String, dynamic> json) => NutritionInfo(
        calories: json['calories'] as int?,
        proteinsG: (json['proteins_g'] as num?)?.toDouble(),
        carbsG: (json['carbs_g'] as num?)?.toDouble(),
        fatsG: (json['fats_g'] as num?)?.toDouble(),
        fiberG: (json['fiber_g'] as num?)?.toDouble(),
      );
}

class UserModel {
  final String id;
  final String? email;
  final String? phone;
  final String fullName;
  final String? avatarUrl;
  final String? bio;
  final bool isPremium;

  UserModel({
    required this.id,
    this.email,
    this.phone,
    required this.fullName,
    this.avatarUrl,
    this.bio,
    this.isPremium = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        fullName: json['full_name'] as String,
        avatarUrl: json['avatar_url'] as String?,
        bio: json['bio'] as String?,
        isPremium: json['is_premium'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'avatar_url': avatarUrl,
        'bio': bio,
      };

  String get initials {
    final parts = fullName.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U';
  }
}
