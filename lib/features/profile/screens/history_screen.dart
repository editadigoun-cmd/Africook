import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/models/recipe_model.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/recipe_card.dart';
import '../../../shared/widgets/empty_state.dart';

final historyProvider = FutureProvider<List<RecipeModel>>((ref) async {
  final uid = SupabaseService.currentUserId;
  if (uid == null) return [];
  return ref.read(supabaseServiceProvider).getHistory(uid);
});

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Historique')),
      body: historyAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (recipes) => recipes.isEmpty
            ? const EmptyState(
                title: 'Aucun historique',
                subtitle: 'Les recettes que vous consultez apparaîtront ici',
                icon: Icons.history,
              )
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: recipes.length,
                itemBuilder: (_, i) => RecipeCard(
                  recipe: recipes[i],
                  onTap: () => context.push('/recipe/${recipes[i].id}'),
                ),
              ),
      ),
    );
  }
}
