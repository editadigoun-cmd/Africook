import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/empty_state.dart';

final notificationsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final uid = SupabaseService.currentUserId;
  if (uid == null) return [];
  return ref.read(supabaseServiceProvider).getNotifications(uid);
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  IconData _iconForType(String type) {
    switch (type) {
      case 'new_message':
        return Icons.chat_bubble;
      case 'new_comment':
        return Icons.comment;
      case 'new_recipe':
        return Icons.restaurant_menu;
      case 'promo':
        return Icons.local_offer;
      default:
        return Icons.notifications;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'new_message':
        return AppColors.primary;
      case 'new_comment':
        return AppColors.green;
      case 'promo':
        return AppColors.yellow;
      default:
        return AppColors.brown;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              final uid = SupabaseService.currentUserId;
              if (uid == null) return;
              await ref
                  .read(supabaseServiceProvider)
                  .markNotificationsRead(uid);
              ref.invalidate(notificationsProvider);
            },
            child: const Text('Tout lire',
                style: TextStyle(color: AppColors.primary, fontSize: 12)),
          ),
        ],
      ),
      body: notifAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (notifs) => notifs.isEmpty
            ? const EmptyState(
                title: 'Aucune notification',
                subtitle: 'Vous serez notifié des nouveautés ici',
                icon: Icons.notifications_none,
              )
            : ListView.separated(
                itemCount: notifs.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 72),
                itemBuilder: (_, i) {
                  final n = notifs[i];
                  final isRead = n['is_read'] as bool? ?? false;
                  final type = n['type'] as String? ?? '';

                  return ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _colorForType(type).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _iconForType(type),
                        color: _colorForType(type),
                        size: 22,
                      ),
                    ),
                    title: Text(
                      n['title'] as String? ?? '',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight:
                            isRead ? FontWeight.normal : FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(
                      n['body'] as String? ?? '',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        color: AppColors.textLight,
                      ),
                    ),
                    tileColor: isRead
                        ? null
                        : AppColors.primary.withOpacity(0.03),
                  );
                },
              ),
      ),
    );
  }
}
