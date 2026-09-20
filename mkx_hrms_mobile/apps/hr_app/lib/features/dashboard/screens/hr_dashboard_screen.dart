import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart' as m3e;
import 'package:mkx_core/constants/app_colors.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<DashboardProvider>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: MkxAppBar(
        title: 'Dashboard',
        subtitle: 'Good ${_greeting()}, ${user?.name ?? "HR Admin"}',
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () => context.read<DashboardProvider>().loadStats(),
          color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
          child: provider.isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: SizedBox(width: 52, height: 52, child: CircularProgressIndicator(strokeWidth: 3)),
                  ),
                )
              : SingleChildScrollView(
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
                iconColor: AppColors.info,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricCard(
                title: 'Present Today',
                value: stats.presentToday.toString(),
                subtext: 'On duty',
                icon: Icons.check_circle_outline_rounded,
                iconColor: AppColors.success,
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
                iconColor: AppColors.warning,
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

    return m3e.M3ECard(
      variant: m3e.M3ECardVariant.filled,
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(16),
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
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
                    child: Container(height: 10, color: AppColors.success),
                  ),
                if (stats.lateToday > 0)
                  Expanded(
                    flex: stats.lateToday,
                    child: Container(height: 10, color: AppColors.warning),
                  ),
                if (stats.absentToday > 0)
                  Expanded(
                    flex: stats.absentToday,
                    child: Container(height: 10, color: AppColors.error),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLegendDot(
                AppColors.success,
                'Present',
                stats.presentToday,
                isDark,
              ),
              _buildLegendDot(
                AppColors.warning,
                'Late',
                stats.lateToday,
                isDark,
              ),
              _buildLegendDot(
                AppColors.error,
                'Absent',
                stats.absentToday,
                isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label, int count, bool isDark) {
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
            color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
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
              color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
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
                  color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
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
        color = AppColors.warning;
        break;
      case 'hire':
      case 'success':
        icon = Icons.person_add_rounded;
        color = AppColors.success;
        break;
      case 'payroll':
        icon = Icons.payments_rounded;
        color = AppColors.info;
        break;
      case 'error':
      case 'deleted':
        icon = Icons.delete_outline_rounded;
        color = AppColors.error;
        break;
      default:
        icon = Icons.notifications_rounded;
        color = const Color(0xffa855f7);
    }

    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;

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
