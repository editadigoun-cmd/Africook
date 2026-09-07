import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/recipe_cache_service.dart';
import '../../../shared/models/recipe_model.dart';
import '../../../shared/widgets/recipe_card.dart';
import '../../../shared/widgets/empty_state.dart';

final cachedRecipesProvider = FutureProvider<List<RecipeModel>>((ref) async {
  return RecipeCacheService().getCachedRecipes();
});

class OfflineScreen extends ConsumerWidget {
  const OfflineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cachedAsync = ref.watch(cachedRecipesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mode hors-ligne'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(cachedRecipesProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.yellow.withOpacity(0.15),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: const [
                Icon(Icons.wifi_off, size: 16, color: AppColors.brown),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Recettes consultées récemment — disponibles sans connexion',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      color: AppColors.brown,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: cachedAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => Center(child: Text('Erreur : $e')),
              data: (recipes) => recipes.isEmpty
                  ? const EmptyState(
                      title: 'Aucune recette en cache',
                      subtitle:
                          'Consultez des recettes en ligne pour les retrouver ici hors-ligne',
                      icon: Icons.wifi_off,
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.72,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: recipes.length,
                      itemBuilder: (_, i) => RecipeCard(
                        recipe: recipes[i],
                        onTap: () =>
                            context.push('/recipe/${recipes[i].id}'),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
