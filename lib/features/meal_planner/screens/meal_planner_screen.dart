import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/models/recipe_model.dart';

final _weekStartProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return now.subtract(Duration(days: now.weekday - 1));
});

final mealPlanProvider =
    FutureProvider.family<List<Map<String, dynamic>>, DateTime>((ref, weekStart) async {
  final uid = SupabaseService.currentUserId;
  if (uid == null) return [];
  return ref.read(supabaseServiceProvider).getMealPlan(uid, weekStart);
});

final _recipesForPlanProvider = FutureProvider<List<RecipeModel>>((ref) {
  return ref.read(supabaseServiceProvider).getRecipes(limit: 40);
});

class MealPlannerScreen extends ConsumerWidget {
  const MealPlannerScreen({super.key});

  static const _mealTypes = ['breakfast', 'lunch', 'dinner'];
  static const _mealLabels = {'breakfast': 'Matin', 'lunch': 'Midi', 'dinner': 'Soir'};
  static const _dayLabels = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
  static const _dayFull = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekStart = ref.watch(_weekStartProvider);
    final planAsync = ref.watch(mealPlanProvider(weekStart));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planificateur de repas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => ref.read(_weekStartProvider.notifier).state =
                weekStart.subtract(const Duration(days: 7)),
          ),
          Center(
            child: Text(
              '${_formatDate(weekStart)} – ${_formatDate(weekStart.add(const Duration(days: 6)))}',
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 12),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => ref.read(_weekStartProvider.notifier).state =
                weekStart.add(const Duration(days: 7)),
          ),
        ],
      ),
      body: planAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (entries) {
          final planMap = <String, Map<String, dynamic>>{};
          for (final e in entries) {
            final key = '${e['plan_date']}_${e['meal_type']}';
            planMap[key] = e;
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: 7,
            itemBuilder: (_, dayIndex) {
              final date = weekStart.add(Duration(days: dayIndex));
              final dateStr = date.toIso8601String().substring(0, 10);
              final isToday = _isToday(date);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: isToday
                      ? Border.all(color: AppColors.primary, width: 1.5)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isToday
                            ? AppColors.primary.withOpacity(0.1)
                            : AppColors.background,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _dayFull[dayIndex],
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: isToday ? AppColors.primary : AppColors.textDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${date.day}/${date.month}',
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 12,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ..._mealTypes.map((mealType) {
                      final key = '${dateStr}_$mealType';
                      final entry = planMap[key];
                      return _MealSlot(
                        label: _mealLabels[mealType]!,
                        entry: entry,
                        onAdd: () => _showRecipePicker(context, ref, date, mealType, weekStart),
                        onDelete: entry != null
                            ? () async {
                                await ref
                                    .read(supabaseServiceProvider)
                                    .deleteMealPlan(entry['id'] as String);
                                ref.invalidate(mealPlanProvider(weekStart));
                              }
                            : null,
                        onTap: entry != null
                            ? () => context.push('/recipe/${entry['recipe_id']}')
                            : null,
                      );
                    }),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showRecipePicker(BuildContext context, WidgetRef ref,
      DateTime date, String mealType, DateTime weekStart) async {
    final recipes = await ref.read(_recipesForPlanProvider.future);
    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RecipePickerSheet(
        recipes: recipes,
        onSelect: (recipe) async {
          final uid = SupabaseService.currentUserId;
          if (uid == null) return;
          await ref
              .read(supabaseServiceProvider)
              .addMealPlan(uid, recipe.id, date, mealType);
          ref.invalidate(mealPlanProvider(weekStart));
        },
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}';
  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }
}

class _MealSlot extends StatelessWidget {
  final String label;
  final Map<String, dynamic>? entry;
  final VoidCallback onAdd;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const _MealSlot({
    required this.label,
    required this.entry,
    required this.onAdd,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final recipe = entry?['recipes'] as Map<String, dynamic>?;
    return InkWell(
      onTap: recipe != null ? onTap : onAdd,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: recipe != null
                  ? Row(
                      children: [
                        if (recipe['image_url'] != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              recipe['image_url'] as String,
                              width: 36,
                              height: 36,
                              fit: BoxFit.cover,
                            ),
                          ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            recipe['title'] as String? ?? '',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: AppColors.textDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        const Icon(Icons.add_circle_outline,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Ajouter un repas',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            color: AppColors.primary.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
            ),
            if (onDelete != null)
              GestureDetector(
                onTap: onDelete,
                child: const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.close, size: 16, color: AppColors.textLight),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RecipePickerSheet extends StatefulWidget {
  final List<RecipeModel> recipes;
  final Future<void> Function(RecipeModel) onSelect;

  const _RecipePickerSheet({required this.recipes, required this.onSelect});

  @override
  State<_RecipePickerSheet> createState() => _RecipePickerSheetState();
}

class _RecipePickerSheetState extends State<_RecipePickerSheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _search.isEmpty
        ? widget.recipes
        : widget.recipes
            .where((r) => r.title.toLowerCase().contains(_search.toLowerCase()))
            .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _search = v),
                decoration: const InputDecoration(
                  hintText: 'Rechercher une recette...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: ctrl,
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final r = filtered[i];
                  return ListTile(
                    leading: r.imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(r.imageUrl!,
                                width: 44, height: 44, fit: BoxFit.cover),
                          )
                        : const CircleAvatar(
                            backgroundColor: AppColors.primary,
                            child: Icon(Icons.restaurant,
                                color: Colors.white, size: 20)),
                    title: Text(r.title,
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                    subtitle: Text('${r.totalTimeMinutes} min',
                        style: const TextStyle(fontFamily: 'Nunito', fontSize: 11)),
                    onTap: () async {
                      Navigator.pop(context);
                      await widget.onSelect(r);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
