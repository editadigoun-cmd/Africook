import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import 'store_detail_screen.dart';

final storesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final data = await Supabase.instance.client
      .from('stores')
      .select()
      .order('rating', ascending: false);
  return (data as List).cast<Map<String, dynamic>>();
});

class BoutiqueScreen extends ConsumerWidget {
  const BoutiqueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storesAsync = ref.watch(storesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Boutiques & Supermarchés',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.textDark),
        ),
      ),
      body: storesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (stores) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('🛒 Ingrédients frais', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white)),
                        SizedBox(height: 4),
                        Text('Commandez vos ingrédients africains\ndirectement depuis nos partenaires.',
                            style: TextStyle(fontFamily: 'Nunito', fontSize: 12, color: Colors.white70)),
                      ],
                    ),
                  ),
                  Text('🌿', style: TextStyle(fontSize: 48)),
                ],
              ),
            ),
            const Text('Nos partenaires', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textDark)),
            const SizedBox(height: 12),
            ...stores.map((store) => _StoreCard(store: store)),
          ],
        ),
      ),
    );
  }
}

class _StoreCard extends StatelessWidget {
  final Map<String, dynamic> store;
  const _StoreCard({required this.store});

  @override
  Widget build(BuildContext context) {
    final name = store['name'] as String;
    final description = store['description'] as String? ?? '';
    final imageUrl = store['image_url'] as String?;
    final rating = (store['rating'] as num?)?.toDouble() ?? 0;
    final deliveryFee = (store['delivery_fee'] as num?)?.toInt() ?? 0;
    final deliveryTime = store['delivery_time_minutes'] as int? ?? 40;
    final storeType = store['store_type'] as String? ?? 'épicerie';
    final isOpen = store['is_open'] as bool? ?? true;
    final city = store['city'] as String? ?? '';

    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => StoreDetailScreen(store: store))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: imageUrl != null
                      ? Image.network(imageUrl, height: 160, width: double.infinity, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(height: 160, color: AppColors.background, child: const Icon(Icons.store, size: 60, color: AppColors.textLight)))
                      : Container(height: 160, color: AppColors.background, child: const Icon(Icons.store, size: 60, color: AppColors.textLight)),
                ),
                Positioned(top: 12, right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: isOpen ? AppColors.green : AppColors.error, borderRadius: BorderRadius.circular(20)),
                    child: Text(isOpen ? 'Ouvert' : 'Fermé', style: const TextStyle(color: Colors.white, fontFamily: 'Nunito', fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ),
                Positioned(top: 12, left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                    child: Text(_typeLabel(storeType), style: const TextStyle(color: Colors.white, fontFamily: 'Nunito', fontSize: 11)),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textDark)),
                  const SizedBox(height: 4),
                  Text(description, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, color: AppColors.textLight)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.star, color: AppColors.star, size: 16),
                      const SizedBox(width: 4),
                      Text('$rating', style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textDark)),
                      const SizedBox(width: 16),
                      const Icon(Icons.location_on_outlined, color: AppColors.textLight, size: 15),
                      const SizedBox(width: 2),
                      Text(city, style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, color: AppColors.textLight)),
                      const Spacer(),
                      const Icon(Icons.delivery_dining, color: AppColors.primary, size: 16),
                      const SizedBox(width: 4),
                      Text('${deliveryFee == 0 ? "Gratuit" : "${deliveryFee}F"} • ${deliveryTime}min',
                          style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, color: AppColors.textLight)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'supermarché': return '🏪 Supermarché';
      case 'marché': return '🏬 Marché';
      case 'pharmacie': return '💊 Pharmacie';
      default: return '🛒 Épicerie';
    }
  }
}
