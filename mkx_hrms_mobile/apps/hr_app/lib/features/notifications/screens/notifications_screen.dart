import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:provider/provider.dart';
import 'package:mkx_core/widgets/mkx_app_bar.dart';
import 'package:mkx_core/widgets/section_tile.dart';
import '../state/notifications_provider.dart';

/// Notifications screen displaying system and activity notifications.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsProvider>().fetchNotifications();
    });
  }

  String _formatRelativeDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }

  Widget _getIconForType(String? type) {
    switch (type) {
      case 'leave':
        return const Icon(Icons.event_available, color: Colors.green, size: 20);
      case 'recruitment':
        return const Icon(Icons.work_outline, color: Colors.blue, size: 20);
      case 'payroll':
        return const Icon(Icons.payment, color: Colors.orange, size: 20);
      case 'attendance':
        return const Icon(Icons.notifications_none,
            color: Colors.purple, size: 20);
      case 'celebration':
      case 'birthday':
        return const Icon(Icons.cake_outlined,
            color: Colors.pinkAccent, size: 20);
      default:
        return const Icon(Icons.card_giftcard, color: Colors.amber, size: 20);
    }
  }

  Color _getColorForType(String? type) {
    switch (type) {
      case 'leave':
        return Colors.green;
      case 'recruitment':
        return Colors.blue;
      case 'payroll':
        return Colors.orange;
      case 'attendance':
        return Colors.purple;
      case 'celebration':
      case 'birthday':
        return Colors.pinkAccent;
      default:
        return Colors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = M3ETheme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    final provider = context.watch<NotificationsProvider>();
    final unreadCount = provider.unreadCount;
    final notifications = provider.notifications;

    return Scaffold(
      backgroundColor: M3ETheme.of(context).colorScheme.surface,
      appBar: MkxAppBar(
        title: 'Notifications',
        actions: [
          if (unreadCount > 0)
            TextButton.icon(
              onPressed: () => provider.markAllAsRead(),
              icon: const Icon(Icons.done_all, size: 14),
              label: const Text('Mark all read'),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.primary,
                textStyle:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      body: M3ERefreshIndicator.contained(
        onRefresh: () => provider.fetchNotifications(),
        child: provider.isLoading
            ? const Center(child: M3EProgressIndicator.circularWavy())
            : provider.errorMessage != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: Center(
                          child: Text(
                            provider.errorMessage!,
                            style: TextStyle(color: colorScheme.error),
                          ),
                        ),
                      ),
                    ],
                  )
                : notifications.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: Center(
                              child: Text(
                                'No notifications at this time',
                                style: TextStyle(
                                    color: colorScheme.onSurfaceVariant),
                              ),
                            ),
                          ),
                        ],
                      )
                    : SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(10),
                        child: SectionCard(
                          isDark: isDark,
                          children: notifications.map((n) {
                            final isRead = n.isRead;
                            return InkWell(
                              onTap: () => provider.markAsRead(n.id, isRead),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _getColorForType(n.type)
                                          .withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: _getIconForType(n.type),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                n.title,
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: isRead
                                                      ? FontWeight.w500
                                                      : FontWeight.w700,
                                                  color: colorScheme.onSurface,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _formatRelativeDate(n.createdAt),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          n.message,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: colorScheme.onSurfaceVariant,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!isRead) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(top: 6),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
    );
  }
}
