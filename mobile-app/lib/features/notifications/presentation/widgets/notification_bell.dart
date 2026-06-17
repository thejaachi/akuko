import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:akuko/core/theme/app_colors.dart';
import 'package:akuko/features/notifications/presentation/controllers/notification_providers.dart';

class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationCountProvider);

    return IconButton(
      icon: Badge(
        isLabelVisible: unread.maybeWhen(data: (c) => c > 0, orElse: () => false),
        label: unread.maybeWhen(
          data: (c) => Text('$c'),
          orElse: () => null,
        ),
        backgroundColor: AppColors.burntSienna,
        child: const Icon(
          Icons.notifications_outlined,
          color: AppColors.warmGold,
        ),
      ),
      onPressed: () => _showNotificationsSheet(context, ref),
    );
  }

  void _showNotificationsSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.warmSurface,
      builder: (ctx) {
        final notifications = ref.watch(notificationsProvider);
        return SafeArea(
          child: notifications.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Could not load notifications'),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_none, size: 48),
                      SizedBox(height: 12),
                      Text('No notifications yet'),
                    ],
                  ),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final n = items[i];
                  return ListTile(
                    leading: Icon(
                      n.isRead
                          ? Icons.mark_email_read_outlined
                          : Icons.mark_email_unread_outlined,
                      color: n.isRead ? AppColors.textMuted : AppColors.warmGold,
                    ),
                    title: Text(n.title),
                    subtitle: n.body != null ? Text(n.body!) : null,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
