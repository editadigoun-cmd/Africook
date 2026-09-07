import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/models/recipe_model.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/recipe_card.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/primary_button.dart';

final communityRecipesProvider = FutureProvider<List<RecipeModel>>((ref) async {
  return ref.read(supabaseServiceProvider).getRecipes(limit: 20);
});

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(communityRecipesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Communauté'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => context.push('/recipe/create'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tabs
          DefaultTabController(
            length: 3,
            child: Column(
              children: [
                const TabBar(
                  indicatorColor: AppColors.primary,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textLight,
                  tabs: [
                    Tab(text: 'Tendances'),
                    Tab(text: 'Abonnements'),
                    Tab(text: 'Mes recettes'),
                  ],
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height - 200,
                  child: TabBarView(
                    children: [
                      _RecipesFeed(recipesAsync: recipesAsync),
                      const _EmptyTab(msg: 'Abonnez-vous à des chefs'),
                      const _EmptyTab(msg: 'Publiez votre première recette'),
                    ],
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

class _RecipesFeed extends StatelessWidget {
  final AsyncValue<List<RecipeModel>> recipesAsync;

  const _RecipesFeed({required this.recipesAsync});

  @override
  Widget build(BuildContext context) => recipesAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: RecipeListSkeleton(),
        ),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (recipes) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: recipes.length,
          itemBuilder: (_, i) => _CommunityPostCard(recipe: recipes[i]),
        ),
      );
}

class _CommunityPostCard extends StatefulWidget {
  final RecipeModel recipe;

  const _CommunityPostCard({required this.recipe});

  @override
  State<_CommunityPostCard> createState() => _CommunityPostCardState();
}

class _CommunityPostCardState extends State<_CommunityPostCard> {
  bool _liked = false;
  int _likes = 0;
  bool _following = false;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author header
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      widget.recipe.author?.initials ?? 'A',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.recipe.author?.fullName ?? 'Chef',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          widget.recipe.createdAt != null
                              ? _formatDate(widget.recipe.createdAt!)
                              : '',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            color: AppColors.textLight,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.recipe.authorId != null &&
                      widget.recipe.authorId != SupabaseService.currentUserId)
                    Consumer(builder: (context, ref, _) {
                      return TextButton(
                        onPressed: () async {
                          final uid = SupabaseService.currentUserId;
                          if (uid == null) return;
                          final newVal = !_following;
                          setState(() => _following = newVal);
                          try {
                            await ref
                                .read(supabaseServiceProvider)
                                .toggleFollow(uid, widget.recipe.authorId!, newVal);
                          } catch (_) {
                            setState(() => _following = !newVal);
                          }
                        },
                        child: Text(
                          _following ? '✓ Suivi' : '+ Suivre',
                          style: TextStyle(
                            color: _following ? AppColors.textLight : AppColors.primary,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),

            // Image
            if (widget.recipe.imageUrl != null)
              GestureDetector(
                onDoubleTap: () {
                  setState(() {
                    _liked = true;
                    _likes++;
                  });
                },
                onTap: () => context.push('/recipe/${widget.recipe.id}'),
                child: Image.network(
                  widget.recipe.imageUrl!,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _liked ? Icons.favorite : Icons.favorite_border,
                      color: _liked ? AppColors.error : AppColors.textLight,
                    ),
                    onPressed: () => setState(() {
                      _liked = !_liked;
                      _likes += _liked ? 1 : -1;
                    }),
                  ),
                  Text(
                    '$_likes',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.comment_outlined,
                        color: AppColors.textLight),
                    onPressed: () => context.push('/recipe/${widget.recipe.id}'),
                  ),
                  const SizedBox(width: 8),
                  Consumer(builder: (context, ref, _) {
                    return IconButton(
                      icon: const Icon(Icons.chat_bubble_outline,
                          color: AppColors.textLight),
                      tooltip: "Contacter l'auteur",
                      onPressed: () async {
                        final uid = SupabaseService.currentUserId;
                        if (uid == null || widget.recipe.authorId == null) return;
                        final conv = await ref
                            .read(supabaseServiceProvider)
                            .getOrCreateConversation(uid, widget.recipe.authorId!,
                                recipeId: widget.recipe.id);
                        if (context.mounted && conv != null) {
                          context.push('/messages/${conv.id}');
                        }
                      },
                    );
                  }),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.share_outlined,
                        color: AppColors.textLight),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: GestureDetector(
                onTap: () => context.push('/recipe/${widget.recipe.id}'),
                child: Text(
                  widget.recipe.title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays > 0) return 'Il y a ${diff.inDays}j';
    if (diff.inHours > 0) return 'Il y a ${diff.inHours}h';
    return 'Il y a ${diff.inMinutes} min';
  }
}

class _EmptyTab extends StatelessWidget {
  final String msg;

  const _EmptyTab({required this.msg});

  @override
  Widget build(BuildContext context) => Center(
        child: Text(
          msg,
          style: const TextStyle(
            fontFamily: 'Nunito',
            color: AppColors.textLight,
          ),
        ),
      );
}
