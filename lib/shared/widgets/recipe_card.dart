import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../models/recipe_model.dart';
import '../providers/auth_provider.dart';
import '../../core/services/supabase_service.dart';

class RecipeCard extends ConsumerStatefulWidget {
  final RecipeModel recipe;
  final VoidCallback onTap;
  final bool showFavorite;

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.onTap,
    this.showFavorite = true,
  });

  @override
  ConsumerState<RecipeCard> createState() => _RecipeCardState();
}

class _RecipeCardState extends ConsumerState<RecipeCard> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.recipe.isFavorite;
  }

  Future<void> _toggleFavorite() async {
    final uid = SupabaseService.currentUserId;
    if (uid == null) return;
    final newVal = !_isFavorite;
    setState(() => _isFavorite = newVal);
    try {
      await ref
          .read(supabaseServiceProvider)
          .toggleFavorite(uid, widget.recipe.id, newVal);
    } catch (_) {
      setState(() => _isFavorite = !newVal);
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppDimensions.radiusM),
                  ),
                  child: recipe.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: recipe.imageUrl!,
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            height: 140,
                            color: AppColors.divider,
                          ),
                          errorWidget: (_, __, ___) => _placeholderImage(),
                        )
                      : _placeholderImage(),
                ),
                if (recipe.videoUrl != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_circle_fill,
                              color: Colors.white, size: 12),
                          SizedBox(width: 3),
                          Text('Vidéo',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                if (widget.showFavorite)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: _toggleFavorite,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorite ? AppColors.error : AppColors.textLight,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                // Health tags
                if (recipe.healthTags.isNotEmpty)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        recipe.healthTags.first,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.textDark,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 12, color: AppColors.textLight),
                      const SizedBox(width: 3),
                      Text(
                        '${recipe.totalTimeMinutes} min',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textLight,
                          fontFamily: 'Nunito',
                        ),
                      ),
                      const Spacer(),
                      if (recipe.averageRating > 0) ...[
                        const Icon(Icons.star_rounded,
                            size: 12, color: AppColors.star),
                        const SizedBox(width: 2),
                        Text(
                          recipe.averageRating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textLight,
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (recipe.difficulty != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: _DifficultyBadge(difficulty: recipe.difficulty!),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderImage() => Container(
        height: 140,
        width: double.infinity,
        color: AppColors.background,
        child: const Icon(
          Icons.restaurant,
          color: AppColors.primary,
          size: 40,
        ),
      );
}

class _DifficultyBadge extends StatelessWidget {
  final String difficulty;
  const _DifficultyBadge({required this.difficulty});

  String get _label {
    switch (difficulty) {
      case 'easy': return 'Facile';
      case 'medium': return 'Moyen';
      case 'hard': return 'Difficile';
      default: return difficulty;
    }
  }

  Color get _color {
    switch (difficulty) {
      case 'easy': return AppColors.green;
      case 'medium': return AppColors.yellow;
      case 'hard': return AppColors.error;
      case 'Facile': return AppColors.green;
      case 'Moyen': return AppColors.yellow;
      case 'Difficile': return AppColors.error;
      default: return AppColors.textLight;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: _color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          _label,
          style: TextStyle(
            color: _color,
            fontSize: 10,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}
