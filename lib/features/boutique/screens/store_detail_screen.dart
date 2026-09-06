import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/models/order_model.dart';
import '../../../shared/providers/cart_provider.dart';

final storeProductsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, storeId) async {
  final data = await Supabase.instance.client
      .from('products')
      .select()
      .eq('store_id', storeId)
      .order('category');
  return (data as List).cast<Map<String, dynamic>>();
});

class StoreDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> store;
  const StoreDetailScreen({super.key, required this.store});

  @override
  ConsumerState<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends ConsumerState<StoreDetailScreen> {
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final storeId = widget.store['id'] as String;
    final productsAsync = ref.watch(storeProductsProvider(storeId));
    final name = widget.store['name'] as String;
    final imageUrl = widget.store['image_url'] as String?;
    final description = widget.store['description'] as String? ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (products) {
          final categories = ['Tout', ...{...products.map((p) => p['category'] as String? ?? 'Autre')}];
          final filtered = _selectedCategory == null || _selectedCategory == 'Tout'
              ? products
              : products.where((p) => p['category'] == _selectedCategory).toList();

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: AppColors.primary,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(name, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16)),
                  background: imageUrl != null
                      ? Image.network(imageUrl, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: AppColors.primary))
                      : Container(color: AppColors.primary, child: const Icon(Icons.store, size: 80, color: Colors.white54)),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (description.isNotEmpty) ...[
                        Text(description, style: const TextStyle(fontFamily: 'Nunito', fontSize: 13, color: AppColors.textLight)),
                        const SizedBox(height: 16),
                      ],
                      SizedBox(
                        height: 36,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: categories.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, i) {
                            final cat = categories[i];
                            final selected = (i == 0 && (_selectedCategory == null || _selectedCategory == 'Tout')) ||
                                cat == _selectedCategory;
                            return FilterChip(
                              label: Text(cat, style: TextStyle(fontFamily: 'Nunito', fontSize: 12,
                                  color: selected ? Colors.white : AppColors.textDark)),
                              selected: selected,
                              onSelected: (_) => setState(() => _selectedCategory = cat),
                              backgroundColor: Colors.white,
                              selectedColor: AppColors.primary,
                              checkmarkColor: Colors.white,
                              side: BorderSide(color: selected ? AppColors.primary : Colors.grey.shade300),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _ProductTile(product: filtered[i]),
                    childCount: filtered.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
            ],
          );
        },
      ),
    );
  }
}

class _ProductTile extends ConsumerWidget {
  final Map<String, dynamic> product;
  const _ProductTile({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = product['name'] as String;
    final price = (product['price'] as num?)?.toDouble() ?? 0;
    final imageUrl = product['image_url'] as String?;
    final unit = product['unit'] as String? ?? '';
    final id = product['id'] as String;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: imageUrl != null
                  ? Image.network(imageUrl, width: double.infinity, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: AppColors.background,
                          child: const Icon(Icons.shopping_basket, size: 40, color: AppColors.textLight)))
                  : Container(color: AppColors.background,
                      child: const Icon(Icons.shopping_basket, size: 40, color: AppColors.textLight)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textDark)),
                const SizedBox(height: 4),
                Text('${price.toInt()} F${unit.isNotEmpty ? " / $unit" : ""}',
                    style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary)),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(cartProvider.notifier).addItem(CartItem(
                        id: id,
                        name: name,
                        imageUrl: imageUrl,
                        price: price,
                        type: 'product',
                      ));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$name ajouté au panier'), duration: const Duration(seconds: 1)),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Ajouter', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
