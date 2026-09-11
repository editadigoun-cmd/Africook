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
              itemCount: 10, // "Toutes" + 8 premières + "Voir +"
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                if (i == 0) {
                  return _FilterChip(
                    label: '🍽 Toutes',
                    isSelected: selectedCategory == null,
                    onTap: () => ref
                        .read(_selectedCategoryProvider.notifier)
                        .state = null,
                  );
                }
                if (i == 9) {
                  return _FilterChip(
                    label: '≡ Catégories',
                    isSelected: false,
                    onTap: () => _showCategorySheet(context, ref, selectedCategory),
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

  void _showCategorySheet(
      BuildContext context, WidgetRef ref, String? current) {
    const groups = [
      {
        'label': '🌍 Cuisine africaine',
        'slugs': ['beninoise', 'africaine', 'senegalaise', 'ivoirienne', 'ghaneenne', 'nigeriane', 'camerounaise', 'maghrebine', 'asiatique'],
      },
      {
        'label': '🥩 Protéines',
        'slugs': ['poisson', 'viande', 'volaille', 'vegetarienne', 'vegan', 'legumineuse'],
      },
      {
        'label': '🍚 Féculents & bases',
        'slugs': ['riz', 'pate-fufu', 'igname', 'plantain', 'pain'],
      },
      {
        'label': '🍳 Modes de cuisson',
        'slugs': ['soupe', 'grillade', 'mijote', 'friture', 'vapeur', 'four', 'street-food', 'beignet'],
      },
      {
        'label': '☀️ Repas du jour',
        'slugs': ['petit-dejeuner', 'bouillie', 'salade'],
      },
      {
        'label': '🥤 Boissons',
        'slugs': ['boisson-traditionnelle', 'jus-de-fruits', 'smoothie', 'boisson-chaude', 'cocktail', 'boisson-fermentee'],
      },
      {
        'label': '🍰 Desserts & sucreries',
        'slugs': ['patisserie', 'dessert', 'glace'],
      },
      {
        'label': '🩺 Santé & régimes',
        'slugs': ['sans-gluten', 'proteine', 'dietetique', 'enfant'],
      },
      {
        'label': '🎉 Occasions',
        'slugs': ['fete', 'ramadan', 'rapide', 'batch-cooking', 'economique'],
      },
      {
        'label': '🌶️ Condiments',
        'slugs': ['condiment', 'conserve'],
      },
    ];

    final catBySlug = {
      for (final c in AppStrings.categories) c['slug']!: c,
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (_, ctrl) => Column(
          children: [
            const SizedBox(height: 8),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            const Text('Choisir une catégorie',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
            const SizedBox(height: 4),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  ListTile(
                    leading: const Text('🍽', style: TextStyle(fontSize: 22)),
                    title: const Text('Toutes les recettes'),
                    selected: current == null,
                    selectedTileColor: AppColors.primary.withOpacity(0.08),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    onTap: () {
                      ref.read(_selectedCategoryProvider.notifier).state = null;
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 8),
                  for (final group in groups) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 4),
                      child: Text(group['label'] as String,
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppColors.textLight)),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        for (final slug in group['slugs'] as List<String>)
                          if (catBySlug.containsKey(slug))
                            GestureDetector(
                              onTap: () {
                                ref
                                    .read(_selectedCategoryProvider.notifier)
                                    .state = slug;
                                Navigator.pop(context);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: current == slug
                                      ? AppColors.primary
                                      : AppColors.primary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: current == slug
                                        ? AppColors.primary
                                        : AppColors.primary.withOpacity(0.2),
                                  ),
                                ),
                                child: Text(
                                  '${catBySlug[slug]!['emoji']} ${catBySlug[slug]!['name']}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'Nunito',
                                    color: current == slug
                                        ? Colors.white
                                        : AppColors.textDark,
                                    fontWeight: current == slug
                                        ? FontWeight.w700
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
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
