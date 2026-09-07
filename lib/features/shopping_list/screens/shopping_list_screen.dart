import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/primary_button.dart';

final shoppingListProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final uid = SupabaseService.currentUserId;
  if (uid == null) return [];
  return ref.read(supabaseServiceProvider).getShoppingList(uid);
});

class ShoppingListScreen extends ConsumerStatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  ConsumerState<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends ConsumerState<ShoppingListScreen> {
  final _itemCtrl = TextEditingController();

  @override
  void dispose() {
    _itemCtrl.dispose();
    super.dispose();
  }

  Future<void> _addItem() async {
    final uid = SupabaseService.currentUserId;
    if (uid == null || _itemCtrl.text.isEmpty) return;

    await ref.read(supabaseServiceProvider).addShoppingItem({
      'user_id': uid,
      'ingredient_name': _itemCtrl.text.trim(),
    });
    _itemCtrl.clear();
    ref.invalidate(shoppingListProvider);
  }

  Future<void> _toggle(int id, bool checked) async {
    await ref
        .read(supabaseServiceProvider)
        .toggleShoppingItem(id, checked);
    ref.invalidate(shoppingListProvider);
  }

  Future<void> _clearChecked() async {
    final uid = SupabaseService.currentUserId;
    if (uid == null) return;
    await ref.read(supabaseServiceProvider).clearCheckedItems(uid);
    ref.invalidate(shoppingListProvider);
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(shoppingListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste de courses'),
        actions: [
          TextButton(
            onPressed: _clearChecked,
            child: const Text('Effacer cochés',
                style: TextStyle(color: AppColors.error, fontSize: 12)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Add item
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _itemCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Ajouter un ingrédient...',
                      prefixIcon: Icon(Icons.add_shopping_cart_outlined),
                    ),
                    onSubmitted: (_) => _addItem(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _addItem,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.add, color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: listAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => Center(child: Text('Erreur : $e')),
              data: (items) {
                if (items.isEmpty) {
                  return const EmptyState(
                    title: 'Liste vide',
                    subtitle: 'Ajoutez des ingrédients ou générez-les depuis une recette',
                    icon: Icons.shopping_cart_outlined,
                  );
                }

                // Group by category
                final grouped = <String, List<Map<String, dynamic>>>{};
                for (final item in items) {
                  final cat = item['category'] as String? ?? 'Autres';
                  grouped.putIfAbsent(cat, () => []).add(item);
                }

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: grouped.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppColors.textLight,
                            ),
                          ),
                        ),
                        ...entry.value.map((item) => _ShoppingItem(
                              item: item,
                              onToggle: (v) => _toggle(item['id'], v),
                              onDelete: () async {
                                await ref
                                    .read(supabaseServiceProvider)
                                    .deleteShoppingItem(item['id']);
                                ref.invalidate(shoppingListProvider);
                              },
                            )),
                      ],
                    );
                  }).toList(),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: PrimaryButton(
              label: '🛒 Commander tout',
              onPressed: () => context.push('/restaurants'),
              outlined: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShoppingItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  const _ShoppingItem({
    required this.item,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final checked = item['is_checked'] as bool? ?? false;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: checked
            ? AppColors.green.withOpacity(0.05)
            : AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: checked ? AppColors.green.withOpacity(0.3) : AppColors.divider,
        ),
      ),
      child: ListTile(
        dense: true,
        leading: Checkbox(
          value: checked,
          onChanged: (v) => onToggle(v ?? false),
          activeColor: AppColors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        title: Text(
          '${item['ingredient_name']} ${item['quantity'] ?? ''} ${item['unit'] ?? ''}',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 14,
            decoration: checked ? TextDecoration.lineThrough : null,
            color: checked ? AppColors.textLight : AppColors.textDark,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline,
              color: AppColors.error, size: 18),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
