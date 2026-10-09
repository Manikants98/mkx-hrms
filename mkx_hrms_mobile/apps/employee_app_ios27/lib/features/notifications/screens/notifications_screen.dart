import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';
import '../../../widgets/ios27_glass_surface.dart';
import '../../../widgets/ios27_loader.dart';
import '../models/notification_model.dart';
import '../state/notifications_provider.dart';

/// Notifications screen redesigned with authentic iOS 27 Liquid Glass visual language.
class NotificationsScreen extends StatefulWidget {
  /// Default constructor for [NotificationsScreen].
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

  /// Formats raw timestamp into human-readable relative time string.
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

  /// Returns standard iconography for notification domain.
  IconData _getIconForType(String? type) {
    switch (type) {
      case 'leave':
        return CupertinoIcons.calendar_today;
      case 'recruitment':
        return CupertinoIcons.briefcase;
      case 'payroll':
        return CupertinoIcons.money_dollar_circle;
      case 'attendance':
        return CupertinoIcons.time;
      case 'celebration':
      case 'birthday':
        return CupertinoIcons.gift;
      default:
        return CupertinoIcons.bell_fill;
    }
  }

  /// Returns tint color associated with the notification category.
  Color _getColorForType(String? type) {
    switch (type) {
      case 'leave':
        return const Color(0xFF34C759);
      case 'recruitment':
        return const Color(0xFF007AFF);
      case 'payroll':
        return const Color(0xFFFF9500);
      case 'attendance':
        return const Color(0xFFAF52DE);
      case 'celebration':
      case 'birthday':
        return const Color(0xFFFF2D55);
      default:
        return const Color(0xFF5856D6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        CupertinoTheme.of(context).brightness == Brightness.dark;
    final provider = context.watch<NotificationsProvider>();
    final unreadCount = provider.unreadCount;
    final notifications = provider.notifications;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.transparent,
      child: Ios27Background(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildLiquidHeader(context, isDark, unreadCount, provider),
              Expanded(
                child: provider.isLoading && notifications.isEmpty
                    ? const Ios27GlassLoader(
                        message: 'Syncing Notifications...',
                      )
                    : provider.errorMessage != null
                        ? _buildErrorState(provider.errorMessage!, isDark)
                        : notifications.isEmpty
                            ? _buildEmptyState(isDark)
                            : CustomScrollView(
                                physics: const BouncingScrollPhysics(
                                  parent: AlwaysScrollableScrollPhysics(),
                                ),
                                slivers: [
                                  CupertinoSliverRefreshControl(
                                    onRefresh: () =>
                                        provider.fetchNotifications(),
                                  ),
                                  SliverPadding(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 12, 16, 32),
                                    sliver: SliverList(
                                      delegate: SliverChildBuilderDelegate(
                                        (context, index) {
                                          final item = notifications[index];
                                          final iconColor =
                                              _getColorForType(item.type);
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 10),
                                            child: _buildNotificationCard(
                                              item: item,
                                              iconColor: iconColor,
                                              isDark: isDark,
                                              onTap: () => provider.markAsRead(
                                                item.id,
                                                item.isRead,
                                              ),
                                            ),
                                          );
                                        },
                                        childCount: notifications.length,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds top header with navigation and liquid glass action button.
  Widget _buildLiquidHeader(
    BuildContext context,
    bool isDark,
    int unreadCount,
    NotificationsProvider provider,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GlassIconButton(
            icon: Icon(
              CupertinoIcons.chevron_back,
              color: isDark ? CupertinoColors.white : const Color(0xFF1C1C1E),
              size: 22,
            ),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    color: isDark ? CupertinoColors.white : const Color(0xFF1C1C1E),
                  ),
                ),
                Text(
                  unreadCount > 0
                      ? '$unreadCount unread updates'
                      : 'All caught up',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? CupertinoColors.white.withValues(alpha: 0.6)
                        : const Color(0xFF6C6C70),
                  ),
                ),
              ],
            ),
          ),
          if (unreadCount > 0)
            Ios27GlassButton(
              onPressed: () => provider.markAllAsRead(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    CupertinoIcons.checkmark_alt,
                    size: 14,
                    color: Color(0xFF007AFF),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Read All',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? CupertinoColors.white : const Color(0xFF007AFF),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Builds an individual iOS 27 glass platter card for a notification item.
  Widget _buildNotificationCard({
    required NotificationRecord item,
    required Color iconColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final isRead = item.isRead;

    return GestureDetector(
      onTap: onTap,
      child: Ios27GlassCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(14),
        borderRadius: 18,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withValues(alpha: isDark ? 0.2 : 0.12),
                border: Border.all(
                  color: iconColor.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Icon(
                _getIconForType(item.type),
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                            letterSpacing: -0.2,
                            color: isDark ? CupertinoColors.white : const Color(0xFF1C1C1E),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatRelativeDate(item.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? CupertinoColors.white.withValues(alpha: 0.5)
                              : const Color(0xFF8E8E93),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.message,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w400,
                      color: isDark
                          ? CupertinoColors.white.withValues(alpha: 0.75)
                          : const Color(0xFF48484A),
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
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF007AFF),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x60007AFF),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds empty state glass card.
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Ios27GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.bell_slash,
              size: 48,
              color: isDark
                  ? CupertinoColors.white.withValues(alpha: 0.4)
                  : const Color(0xFF8E8E93),
            ),
            const SizedBox(height: 14),
            Text(
              'No Notifications',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isDark ? CupertinoColors.white : const Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'You have no pending updates or alerts right now.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? CupertinoColors.white.withValues(alpha: 0.6)
                    : const Color(0xFF6C6C70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds error state glass card.
  Widget _buildErrorState(String message, bool isDark) {
    return Center(
      child: Ios27GlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 42,
              color: Color(0xFFFF453A),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? CupertinoColors.white : const Color(0xFF1C1C1E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
