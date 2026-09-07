import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/models/recipe_model.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/recipe_card.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/empty_state.dart';

final _searchProvider = StateProvider<String>((ref) => '');
final _selectedCategoryProvider = StateProvider<String?>((ref) => null);
final _difficultyProvider = StateProvider<String?>((ref) => null);
final _sortProvider = StateProvider<String>((ref) => 'created_at');

String _difficultyLabel(String? v) {
  switch (v) {
    case 'easy': return 'Facile';
    case 'medium': return 'Moyen';
    case 'hard': return 'Difficile';
    default: return v ?? '';
  }
}

final recipesListProvider = FutureProvider<List<RecipeModel>>((ref) {
  final search = ref.watch(_searchProvider);
  final difficulty = ref.watch(_difficultyProvider);
  final category = ref.watch(_selectedCategoryProvider);
  final sort = ref.watch(_sortProvider);
  return ref.read(supabaseServiceProvider).getRecipes(
        search: search.isEmpty ? null : search,
        difficulty: difficulty,
        categorySlug: category,
        sortBy: sort,
        limit: 40,
      );
});

class RecipesScreen extends ConsumerStatefulWidget {
  const RecipesScreen({super.key});

  @override
  ConsumerState<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends ConsumerState<RecipesScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recipesAsync = ref.watch(recipesListProvider);
    final selectedCategory = ref.watch(_selectedCategoryProvider);
    final selectedDifficulty = ref.watch(_difficultyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recettes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Publier une recette',
            onPressed: () => context.push('/recipe/create'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) =>
                  ref.read(_searchProvider.notifier).state = v,
              decoration: InputDecoration(
                hintText: 'Rechercher une recette...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          ref.read(_searchProvider.notifier).state = '';
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Category filter
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: AppStrings.categories.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                if (i == 0) {
                  return _FilterChip(
                    label: 'Toutes',
                    isSelected: selectedCategory == null,
                    onTap: () => ref
                        .read(_selectedCategoryProvider.notifier)
                        .state = null,
                  );
                }
                final cat = AppStrings.categories[i - 1];
                return _FilterChip(
                  label: '${cat['emoji']} ${cat['name']}',
                  isSelected: selectedCategory == cat['slug'],
                  onTap: () => ref
                      .read(_selectedCategoryProvider.notifier)
                      .state = cat['slug'],
                );
              },
            ),
          ),

          // Sort & difficulty row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _SmallDropdown<String>(
                  value: ref.watch(_sortProvider),
                  items: const [
                    DropdownMenuItem(
                        value: 'created_at', child: Text('Plus récentes')),
                    DropdownMenuItem(
                        value: 'average_rating', child: Text('Mieux notées')),
                    DropdownMenuItem(
                        value: 'views_count', child: Text('Populaires')),
                  ],
                  onChanged: (v) =>
                      ref.read(_sortProvider.notifier).state = v!,
                ),
                const SizedBox(width: 8),
                _SmallDropdown<String?>(
                  value: selectedDifficulty,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Difficulté')),
                    DropdownMenuItem(value: 'easy', child: Text('Facile')),
                    DropdownMenuItem(value: 'medium', child: Text('Moyen')),
                    DropdownMenuItem(value: 'hard', child: Text('Difficile')),
                  ],
                  onChanged: (v) =>
                      ref.read(_difficultyProvider.notifier).state = v,
                ),
              ],
            ),
          ),

          // Results
          Expanded(
            child: recipesAsync.when(
              data: (recipes) => recipes.isEmpty
                  ? const EmptyState(
                      title: 'Aucune recette trouvée',
                      subtitle: 'Essayez d\'autres termes de recherche',
                      icon: Icons.search_off,
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                        onTap: () => context.push('/recipe/${recipes[i].id}'),
                      ),
                    ),
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: RecipeListSkeleton(),
              ),
              error: (e, _) => Center(child: Text('Erreur : $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.divider,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: isSelected ? Colors.white : AppColors.textDark,
            ),
          ),
        ),
      );
}

class _SmallDropdown<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _SmallDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.divider),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            items: items,
            onChanged: onChanged,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              color: AppColors.textDark,
            ),
            icon: const Icon(Icons.keyboard_arrow_down,
                size: 16, color: AppColors.textLight),
            isDense: true,
          ),
        ),
      );
}
