import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/primary_button.dart';

class _ProfileStats {
  final int recipes;
  final int favorites;

  const _ProfileStats({required this.recipes, required this.favorites});
}

final profileStatsProvider = FutureProvider<_ProfileStats>((ref) async {
  final uid = SupabaseService.currentUserId;
  if (uid == null) return const _ProfileStats(recipes: 0, favorites: 0);
  final client = Supabase.instance.client;
  final recipesResp = await client
      .from('recipes')
      .select('id')
      .eq('author_id', uid)
      .eq('is_published', true);
  final favsResp = await client
      .from('favorites')
      .select('id')
      .eq('user_id', uid);
  return _ProfileStats(
    recipes: (recipesResp as List).length,
    favorites: (favsResp as List).length,
  );
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      body: profileAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (profile) => CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              backgroundColor: AppColors.primary,
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () => context.push('/profile/edit'),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: Colors.white,
                        backgroundImage: profile?.avatarUrl != null
                            ? CachedNetworkImageProvider(profile!.avatarUrl!)
                            : null,
                        child: profile?.avatarUrl == null
                            ? Text(
                                profile?.initials ?? 'U',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 28,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        profile?.fullName ?? 'Utilisateur',
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      if (profile?.bio != null)
                        Text(
                          profile!.bio!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontFamily: 'Nunito',
                            fontSize: 13,
                          ),
                        ),
                      if (profile?.isPremium == true)
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.yellow,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '⭐ Premium',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              color: AppColors.brown,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Quick stats
                    ref.watch(profileStatsProvider).when(
                      loading: () => const SizedBox(
                        height: 48,
                        child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (stats) => Row(
                        children: [
                          _StatBox(value: '${stats.recipes}', label: 'Recettes'),
                          _StatBox(value: '${stats.favorites}', label: 'Favoris'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Menu items
                    _MenuSection(
                      title: 'Mon compte',
                      items: [
                        _MenuItem(
                          icon: Icons.person_outline,
                          label: 'Modifier le profil',
                          onTap: () => context.push('/profile/edit'),
                        ),
                        _MenuItem(
                          icon: Icons.favorite_border,
                          label: 'Mes favoris',
                          onTap: () => context.push('/favorites'),
                        ),
                        _MenuItem(
                          icon: Icons.history,
                          label: 'Historique',
                          onTap: () {},
                        ),
                        _MenuItem(
                          icon: Icons.shopping_cart_outlined,
                          label: 'Liste de courses',
                          onTap: () => context.push('/shopping-list'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    _MenuSection(
                      title: 'Préférences',
                      items: [
                        _MenuItem(
                          icon: Icons.health_and_safety_outlined,
                          label: 'Mode santé',
                          onTap: () {},
                          trailing: const Text('Normal',
                              style: TextStyle(
                                  color: AppColors.textLight,
                                  fontFamily: 'Nunito',
                                  fontSize: 12)),
                        ),
                        _MenuItem(
                          icon: Icons.notifications_outlined,
                          label: 'Notifications',
                          onTap: () => context.push('/notifications'),
                        ),
                        _MenuItem(
                          icon: Icons.language,
                          label: 'Langue',
                          onTap: () {},
                          trailing: const Text('Français',
                              style: TextStyle(
                                  color: AppColors.textLight,
                                  fontFamily: 'Nunito',
                                  fontSize: 12)),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    if (profile?.isPremium == false)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFACC15), Color(0xFFF97316)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '⭐ Africook Premium',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Recettes illimitées, IA avancée, sans pub',
                                    style: TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                minimumSize: Size.zero,
                              ),
                              child: const Text(
                                'Souscrire',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.logout, color: AppColors.error),
                        label: const Text(
                          'Se déconnecter',
                          style: TextStyle(color: AppColors.error),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.error),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          await SupabaseService().signOut();
                          if (context.mounted) {
                            context.go('/auth/login');
                          }
                        },
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;

  const _StatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.textDark,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      );
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;

  const _MenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Column(
              children: items
                  .asMap()
                  .entries
                  .map((e) => Column(
                        children: [
                          e.value,
                          if (e.key < items.length - 1)
                            const Divider(
                                height: 1, indent: 52),
                        ],
                      ))
                  .toList(),
            ),
          ),
        ],
      );
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        title: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 14,
            color: AppColors.textDark,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailing != null) trailing!,
            const Icon(Icons.chevron_right, color: AppColors.textLight),
          ],
        ),
        onTap: onTap,
      );
}
