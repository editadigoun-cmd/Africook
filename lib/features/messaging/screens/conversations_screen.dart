import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/models/message_model.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/skeleton_loader.dart';

final conversationsProvider = FutureProvider<List<ConversationModel>>((ref) async {
  final uid = SupabaseService.currentUserId;
  if (uid == null) return [];
  return ref.read(supabaseServiceProvider).getConversations(uid);
});

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final convsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(conversationsProvider),
        child: convsAsync.when(
          loading: () => ListView.builder(
            itemCount: 8,
            itemBuilder: (_, __) => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  SkeletonBox(width: 52, height: 52, radius: 26),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 140, height: 14),
                        SizedBox(height: 6),
                        SkeletonBox(width: 200, height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          error: (e, _) => Center(child: Text('Erreur : $e')),
          data: (convs) => convs.isEmpty
              ? const EmptyState(
                  title: 'Aucun message',
                  subtitle:
                      'Contactez un auteur depuis une recette pour démarrer une conversation',
                  icon: Icons.chat_bubble_outline,
                )
              : ListView.separated(
                  itemCount: convs.length,
                  separatorBuilder: (_, __) =>
                      const Divider(indent: 80, height: 1),
                  itemBuilder: (_, i) => _ConversationTile(conv: convs[i]),
                ),
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationModel conv;

  const _ConversationTile({required this.conv});

  @override
  Widget build(BuildContext context) {
    final other = conv.otherUser;
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            backgroundImage: other?.avatarUrl != null
                ? CachedNetworkImageProvider(other!.avatarUrl!)
                : null,
            child: other?.avatarUrl == null
                ? Text(
                    other?.initials ?? 'U',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          if (conv.unreadCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${conv.unreadCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        other?.fullName ?? 'Utilisateur',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight:
              conv.unreadCount > 0 ? FontWeight.w700 : FontWeight.w500,
          fontSize: 14,
          color: AppColors.textDark,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (conv.linkedRecipe != null)
            Text(
              '🍽️ ${conv.linkedRecipe!.title}',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 11,
                color: AppColors.primary,
              ),
            ),
          Text(
            conv.lastMessage?.content ?? 'Nouvelle conversation',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              color: conv.unreadCount > 0
                  ? AppColors.textDark
                  : AppColors.textLight,
              fontWeight: conv.unreadCount > 0
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      trailing: Text(
        timeago.format(conv.lastMessageAt, locale: 'fr'),
        style: TextStyle(
          fontSize: 11,
          color: conv.unreadCount > 0
              ? AppColors.primary
              : AppColors.textLight,
          fontFamily: 'Nunito',
          fontWeight: conv.unreadCount > 0
              ? FontWeight.w600
              : FontWeight.normal,
        ),
      ),
      onTap: () => context.push('/messages/${conv.id}'),
    );
  }
}
