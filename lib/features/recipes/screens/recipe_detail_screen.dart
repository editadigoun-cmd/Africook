import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/recipe_cache_service.dart';
import '../../../shared/models/recipe_model.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/health_badge.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/skeleton_loader.dart';

String _difficultyLabel(String? v) {
  switch (v) {
    case 'easy': return 'Facile';
    case 'medium': return 'Moyen';
    case 'hard': return 'Difficile';
    default: return v ?? '-';
  }
}

final recipeDetailProvider =
    FutureProvider.family<RecipeModel?, String>((ref, id) async {
  final cache = RecipeCacheService();
  try {
    final recipe = await ref.read(supabaseServiceProvider).getRecipe(id);
    if (recipe != null) await cache.saveRecipe(recipe);
    return recipe;
  } catch (_) {
    return cache.getRecipe(id);
  }
});

class RecipeDetailScreen extends ConsumerStatefulWidget {
  final String recipeId;

  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _servings = 2;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _recordHistory();
  }

  Future<void> _recordHistory() async {
    final uid = SupabaseService.currentUserId;
    if (uid == null) return;
    try {
      await SupabaseService.client.from('recipe_history').upsert({
        'user_id': uid,
        'recipe_id': widget.recipeId,
        'viewed_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,recipe_id');
    } catch (_) {}
  }

  void _shareRecipe(RecipeModel recipe) {
    final url = 'https://editadigoun-cmd.github.io/Africook/#/recipe/${recipe.id}';
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Lien copié dans le presse-papier !'),
        backgroundColor: AppColors.primary,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite(RecipeModel recipe) async {
    final uid = SupabaseService.currentUserId;
    if (uid == null) return;
    final newVal = !_isFavorite;
    setState(() => _isFavorite = newVal);
    try {
      await ref
          .read(supabaseServiceProvider)
          .toggleFavorite(uid, recipe.id, newVal);
    } catch (_) {
      setState(() => _isFavorite = !newVal);
    }
  }

  Future<void> _addToShoppingList(RecipeModel recipe) async {
    final uid = SupabaseService.currentUserId;
    if (uid == null) return;
    final service = ref.read(supabaseServiceProvider);
    for (final ing in recipe.ingredients) {
      await service.addShoppingItem({
        'user_id': uid,
        'recipe_id': recipe.id,
        'ingredient_name': ing.name,
        'quantity': ing.quantity,
        'unit': ing.unit,
      });
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingrédients ajoutés à votre liste de courses !'),
          backgroundColor: AppColors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipeAsync = ref.watch(recipeDetailProvider(widget.recipeId));

    return recipeAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Erreur : $e')),
      ),
      data: (recipe) {
        if (recipe == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Recette introuvable')),
          );
        }
        _servings = recipe.servings;
        _isFavorite = recipe.isFavorite;

        return Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (_, __) => [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: AppColors.primary,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      _isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: _isFavorite ? Colors.red : Colors.white,
                    ),
                    onPressed: () => _toggleFavorite(recipe),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_outlined, color: Colors.white),
                    onPressed: () => _shareRecipe(recipe),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      recipe.imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: recipe.imageUrl!,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: AppColors.primary,
                              child: const Icon(Icons.restaurant,
                                  size: 80, color: Colors.white54),
                            ),
                      // Gradient overlay
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black54],
                          ),
                        ),
                      ),
                      // Recipe info overlay — bottom offset accounts for TabBar height (~48px)
                      Positioned(
                        bottom: 64,
                        left: 16,
                        right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (recipe.healthTags.isNotEmpty)
                              Wrap(
                                spacing: 6,
                                children: recipe.healthTags
                                    .take(3)
                                    .map((t) => HealthBadge(tag: t))
                                    .toList(),
                              ),
                            const SizedBox(height: 8),
                            Text(
                              recipe.title,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                                fontSize: 22,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded,
                                    color: AppColors.star, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  '${recipe.averageRating.toStringAsFixed(1)} (${recipe.ratingsCount})',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontFamily: 'Nunito',
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Icon(Icons.access_time,
                                    color: Colors.white70, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '${recipe.totalTimeMinutes} min',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontFamily: 'Nunito',
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                bottom: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  labelStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  tabs: const [
                    Tab(text: 'Ingrédients'),
                    Tab(text: 'Étapes'),
                    Tab(text: 'Vidéo'),
                    Tab(text: 'Nutrition'),
                  ],
                ),
              ),
            ],
            body: Column(
              children: [
                // Quick info row
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  color: AppColors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _InfoChip(
                          icon: Icons.schedule_rounded,
                          label: 'Prép.',
                          value: '${recipe.prepTimeMinutes ?? 0} min'),
                      _InfoChip(
                          icon: Icons.local_fire_department_rounded,
                          label: 'Cuisson',
                          value: '${recipe.cookTimeMinutes ?? 0} min'),
                      _InfoChip(
                          icon: Icons.signal_cellular_alt_rounded,
                          label: 'Niveau',
                          value: _difficultyLabel(recipe.difficulty)),
                      _InfoChip(
                          icon: Icons.people_rounded,
                          label: 'Portions',
                          value: '$_servings pers.'),
                    ],
                  ),
                ),

                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Ingredients tab
                      _IngredientsTab(
                        recipe: recipe,
                        servings: _servings,
                        onServingsChanged: (v) =>
                            setState(() => _servings = v),
                        onAddToList: () => _addToShoppingList(recipe),
                      ),
                      // Steps tab
                      _StepsTab(steps: recipe.steps),
                      // Video tab
                      _VideoTab(videoUrl: recipe.videoUrl),
                      // Nutrition tab
                      _NutritionTab(nutrition: recipe.nutrition),
                    ],
                  ),
                ),

                // Bottom actions
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  color: AppColors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          label: '🛒 Commander',
                          onPressed: () => context.push('/restaurants?recipeId=${recipe.id}'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (recipe.isCommunity && recipe.authorId != null)
                        OutlinedButton.icon(
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: const Text("Contacter l'auteur"),
                          onPressed: () async {
                            final uid = SupabaseService.currentUserId;
                            if (uid == null) return;
                            final conv = await ref
                                .read(supabaseServiceProvider)
                                .getOrCreateConversation(
                                  uid,
                                  recipe.authorId!,
                                  recipeId: recipe.id,
                                );
                            if (mounted && conv != null) {
                              context.push('/messages/${conv.id}');
                            }
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: AppColors.textDark,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 10,
              color: AppColors.textLight,
            ),
          ),
        ],
      );
}

class _IngredientsTab extends StatelessWidget {
  final RecipeModel recipe;
  final int servings;
  final ValueChanged<int> onServingsChanged;
  final VoidCallback onAddToList;

  const _IngredientsTab({
    required this.recipe,
    required this.servings,
    required this.onServingsChanged,
    required this.onAddToList,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = servings / (recipe.servings == 0 ? 1 : recipe.servings);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Servings selector
        Row(
          children: [
            const Text(
              'Portions :',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const Spacer(),
            _Counter(
              value: servings,
              onDecrement: () {
                if (servings > 1) onServingsChanged(servings - 1);
              },
              onIncrement: () => onServingsChanged(servings + 1),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...recipe.ingredients.map(
          (ing) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    ing.name + (ing.isOptional ? ' (optionnel)' : ''),
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      color: ing.isOptional
                          ? AppColors.textLight
                          : AppColors.textDark,
                    ),
                  ),
                ),
                Text(
                  ing.displayQuantity,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          icon: const Icon(Icons.shopping_cart_outlined),
          label: const Text('Ajouter à ma liste de courses'),
          onPressed: onAddToList,
        ),
      ],
    );
  }
}

class _Counter extends StatelessWidget {
  final int value;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _Counter({
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          _CounterBtn(icon: Icons.remove, onTap: onDecrement),
          SizedBox(
            width: 40,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          _CounterBtn(icon: Icons.add, onTap: onIncrement),
        ],
      );
}

class _CounterBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CounterBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
      );
}

class _StepsTab extends StatelessWidget {
  final List<RecipeStep> steps;

  const _StepsTab({required this.steps});

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) {
      return const Center(child: Text('Aucune étape disponible'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: steps.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, i) {
        final step = steps[i];
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${step.stepNumber}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (step.durationMinutes != null)
                    Text(
                      '${step.durationMinutes} min',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        color: AppColors.primary,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    step.instruction,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      color: AppColors.textDark,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _VideoTab extends StatelessWidget {
  final String? videoUrl;

  const _VideoTab({this.videoUrl});

  @override
  Widget build(BuildContext context) {
    if (videoUrl == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_off, size: 48, color: AppColors.textLight),
            SizedBox(height: 12),
            Text(
              'Aucune vidéo disponible',
              style: TextStyle(color: AppColors.textLight),
            ),
          ],
        ),
      );
    }
    return const Center(
      child: Text('Lecteur vidéo — intégrez video_player + chewie ici'),
    );
  }
}

class _NutritionTab extends StatelessWidget {
  final NutritionInfo? nutrition;

  const _NutritionTab({this.nutrition});

  @override
  Widget build(BuildContext context) {
    if (nutrition == null) {
      return const Center(
        child: Text('Informations nutritionnelles non disponibles'),
      );
    }
    final n = nutrition!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Valeurs nutritionnelles (par portion)',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 16),
        _NutritionRow(label: 'Calories', value: '${n.calories} kcal', color: AppColors.primary),
        _NutritionRow(label: 'Protéines', value: '${n.proteinsG?.toStringAsFixed(1)} g', color: AppColors.green),
        _NutritionRow(label: 'Glucides', value: '${n.carbsG?.toStringAsFixed(1)} g', color: AppColors.yellow),
        _NutritionRow(label: 'Lipides', value: '${n.fatsG?.toStringAsFixed(1)} g', color: AppColors.error),
        _NutritionRow(label: 'Fibres', value: '${n.fiberG?.toStringAsFixed(1)} g', color: AppColors.brown),
      ],
    );
  }
}

class _NutritionRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _NutritionRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
                width: 12,
                height: 12,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 12),
            Text(label,
                style: const TextStyle(
                    fontFamily: 'Nunito', fontSize: 14, color: AppColors.textDark)),
            const Spacer(),
            Text(value,
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: color)),
          ],
        ),
      );
}
