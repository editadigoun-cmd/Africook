import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/empty_state.dart';

final restaurantsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.read(supabaseServiceProvider).getRestaurants();
});

class RestaurantsScreen extends ConsumerWidget {
  const RestaurantsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restAsync = ref.watch(restaurantsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Restaurants partenaires')),
      body: restAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (restaurants) => restaurants.isEmpty
            ? const EmptyState(
                title: 'Aucun restaurant disponible',
                subtitle: 'Les restaurants partenaires arrivent bientôt !',
                icon: Icons.restaurant_outlined,
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: restaurants.length,
                itemBuilder: (_, i) {
                  final r = restaurants[i];
                  return GestureDetector(
                    onTap: () => context.push('/restaurant/${r['id']}'),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16)),
                            child: r['cover_url'] != null
                                ? CachedNetworkImage(
                                    imageUrl: r['cover_url'],
                                    height: 140,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    height: 140,
                                    color: AppColors.primary.withOpacity(0.2),
                                    child: const Icon(Icons.restaurant,
                                        size: 48, color: AppColors.primary),
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        r['name'] ?? '',
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        r['city'] ?? '',
                                        style: const TextStyle(
                                          fontFamily: 'Nunito',
                                          color: AppColors.textLight,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.star_rounded,
                                            color: AppColors.star, size: 16),
                                        const SizedBox(width: 3),
                                        Text(
                                          '${r['rating'] ?? 0}',
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${r['delivery_time_minutes'] ?? 30} min',
                                      style: const TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 11,
                                        color: AppColors.textLight,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (r['is_open'] == true
                                            ? AppColors.green
                                            : AppColors.error)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    r['is_open'] == true ? 'Ouvert' : 'Fermé',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w600,
                                      color: r['is_open'] == true
                                          ? AppColors.green
                                          : AppColors.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
