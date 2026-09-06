import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/constants/app_colors.dart';
import '../models/message_model.dart';
import '../models/recipe_model.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final RecipeModel? sharedRecipe;
  final VoidCallback? onRecipeTap;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.sharedRecipe,
    this.onRecipeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(
          left: isMe ? 48 : 0,
          right: isMe ? 0 : 48,
          bottom: 6,
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : AppColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildContent(context),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeago.format(message.createdAt, locale: 'fr'),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textLight,
                    fontFamily: 'Nunito',
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 12,
                    color: message.isRead ? AppColors.primary : AppColors.textLight,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (message.messageType) {
      case MessageType.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CachedNetworkImage(
            imageUrl: message.imageUrl!,
            width: 200,
            height: 160,
            fit: BoxFit.cover,
          ),
        );
      case MessageType.recipeShare:
        return _RecipeShareCard(
          recipe: sharedRecipe,
          isMe: isMe,
          onTap: onRecipeTap,
        );
      default:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            message.content,
            style: TextStyle(
              color: isMe ? Colors.white : AppColors.textDark,
              fontSize: 14,
              fontFamily: 'Nunito',
            ),
          ),
        );
    }
  }
}

class _RecipeShareCard extends StatelessWidget {
  final RecipeModel? recipe;
  final bool isMe;
  final VoidCallback? onTap;

  const _RecipeShareCard({this.recipe, required this.isMe, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (recipe == null) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          '🍽️ Recette partagée',
          style: TextStyle(
            color: isMe ? Colors.white70 : AppColors.textLight,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (recipe!.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: CachedNetworkImage(
                  imageUrl: recipe!.imageUrl!,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🍽️ Recette partagée',
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe
                          ? Colors.white70
                          : AppColors.primary,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recipe!.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      color: isMe ? Colors.white : AppColors.textDark,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Appuyer pour voir la recette →',
                    style: TextStyle(
                      fontSize: 11,
                      color: isMe ? Colors.white60 : AppColors.textLight,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
