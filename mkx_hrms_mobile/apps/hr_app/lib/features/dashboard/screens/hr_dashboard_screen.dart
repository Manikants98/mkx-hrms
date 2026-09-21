import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:mkx_core/features/auth/state/auth_provider.dart';
import 'package:mkx_core/widgets/metric_card.dart';
import 'package:mkx_core/widgets/mkx_app_bar.dart';
import 'package:mkx_core/widgets/section_tile.dart';
import 'package:provider/provider.dart';

import '../../dashboard/models/dashboard_stats_model.dart';
import '../../dashboard/state/dashboard_provider.dart';

/// HR Admin Dashboard — matches employee_app structure and UI patterns
class HrDashboardScreen extends StatefulWidget {
  const HrDashboardScreen({super.key});

  @override
  State<HrDashboardScreen> createState() => _HrDashboardScreenState();
}

class _HrDashboardScreenState extends State<HrDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = M3ETheme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<DashboardProvider>();
    final user = auth.currentUser;
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainer,
      appBar: MkxAppBar(
        title: 'Dashboard',
        subtitle: 'Good ${_greeting()}, ${user?.name ?? "HR Admin"}',
      ),
      body: SafeArea(
        top: false,
        child: M3ERefreshIndicator(
          onRefresh: () => context.read<DashboardProvider>().loadStats(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMetricsGrid(isDark, provider.stats),
                const SizedBox(height: 10),
                _buildAttendanceSection(isDark, provider.stats),
                const SizedBox(height: 12),
                _buildRecentActivity(isDark, provider.stats),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(bool isDark, DashboardStatsModel stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: MetricCard(
                title: 'Total Employees',
                value: stats.totalEmployees.toString(),
                subtext: 'Active workforce',
                icon: Icons.people_outline_rounded,
                iconColor: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricCard(
                title: 'Present Today',
                value: stats.presentToday.toString(),
                subtext: 'On duty',
                icon: Icons.check_circle_outline_rounded,
                iconColor: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                title: 'Pending Leaves',
                value: stats.pendingLeaves.toString(),
                subtext: 'Awaiting approval',
                icon: Icons.hourglass_top_rounded,
                iconColor: Colors.orange,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricCard(
                title: 'Open Positions',
                value: stats.openPositions.toString(),
                subtext: 'Recruitment pipelines',
                icon: Icons.work_outline_rounded,
                iconColor: const Color(0xffa855f7),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAttendanceSection(bool isDark, DashboardStatsModel stats) {
    final total = stats.presentToday + stats.absentToday + stats.lateToday;
    if (total == 0) return const SizedBox.shrink();
    final colorScheme = M3ETheme.of(context).colorScheme;
    return M3ECard(
      variant: M3ECardVariant.filled,
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(16),
      color: colorScheme.surfaceDim,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Attendance Ratio",
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: [
                if (stats.presentToday > 0)
                  Expanded(
                    flex: stats.presentToday,
                    child: Container(height: 10, color: Colors.green),
                  ),
                if (stats.lateToday > 0)
                  Expanded(
                    flex: stats.lateToday,
                    child: Container(height: 10, color: Colors.orange),
                  ),
                if (stats.absentToday > 0)
                  Expanded(
                    flex: stats.absentToday,
                    child: Container(
                        height: 10, color: Theme.of(context).colorScheme.error),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLegendDot(
                Colors.green,
                'Present',
                stats.presentToday,
                isDark,
                context,
              ),
              _buildLegendDot(
                Colors.orange,
                'Late',
                stats.lateToday,
                isDark,
                context,
              ),
              _buildLegendDot(
                Theme.of(context).colorScheme.error,
                'Absent',
                stats.absentToday,
                isDark,
                context,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(
      Color color, String label, int count, bool isDark, BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(bool isDark, DashboardStatsModel stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'RECENT ACTIVITIES',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 6),
        if (stats.recentActivity.isEmpty)
          SectionTile(
            isDark: isDark,
            position: TilePosition.only,
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Center(
              child: Text(
                'No recent activities recorded',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          SectionCard(
            isDark: isDark,
            children: stats.recentActivity.map((activity) {
              return _ActivityRow(activity: activity, isDark: isDark);
            }).toList(),
          ),
      ],
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}

class _ActivityRow extends StatelessWidget {
  final RecentActivityModel activity;
  final bool isDark;

  const _ActivityRow({required this.activity, required this.isDark});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (activity.type.toLowerCase()) {
      case 'leave':
        icon = Icons.event_note_rounded;
        color = Colors.orange;
        break;
      case 'hire':
      case 'success':
        icon = Icons.person_add_rounded;
        color = Colors.green;
        break;
      case 'payroll':
        icon = Icons.payments_rounded;
        color = M3ETheme.of(context).colorScheme.primary;
        break;
      case 'error':
      case 'deleted':
        icon = Icons.delete_outline_rounded;
        color = M3ETheme.of(context).colorScheme.error;
        break;
      default:
        icon = Icons.notifications_rounded;
        color = const Color(0xffa855f7);
    }

    final mutedColor = M3ETheme.of(context).colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: mutedColor),
                ),
              ],
            ),
          ),
          if (activity.timeAgo.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              activity.timeAgo,
              style: TextStyle(fontSize: 11, color: mutedColor),
            ),
          ],
        ],
      ),
    );
  }
}
