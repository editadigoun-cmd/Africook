import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/models/recipe_model.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/recipe_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/skeleton_loader.dart';

final favoritesProvider = FutureProvider<List<RecipeModel>>((ref) async {
  final uid = SupabaseService.currentUserId;
  if (uid == null) return [];
  return ref.read(supabaseServiceProvider).getFavorites(uid);
});

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favsAsync = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mes Favoris')),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(favoritesProvider),
        child: favsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: RecipeListSkeleton(),
          ),
          error: (e, _) => Center(child: Text('Erreur : $e')),
          data: (recipes) => recipes.isEmpty
              ? const EmptyState(
                  title: 'Aucun favori',
                  subtitle:
                      'Appuyez sur ❤️ sur une recette pour la sauvegarder',
                  icon: Icons.favorite_border,
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
                  itemBuilder: (_, i) {
                    final r = recipes[i]..isFavorite = true;
                    return RecipeCard(
                      recipe: r,
                      onTap: () => context.push('/recipe/${r.id}'),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
