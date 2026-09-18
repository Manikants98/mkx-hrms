import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mkx_core/constants/app_colors.dart';
import 'package:mkx_core/features/auth/state/auth_provider.dart';
import 'package:mkx_core/widgets/app_text.dart';
import 'package:mkx_core/widgets/metric_card.dart';
import '../../dashboard/models/dashboard_stats_model.dart';
import '../../dashboard/state/dashboard_provider.dart';

/// HR Admin Dashboard — live KPI overview with recent activity feed
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

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => context.read<DashboardProvider>().loadStats(),
          child: Consumer<DashboardProvider>(
            builder: (context, provider, _) {
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader(isDark, auth)),
                  if (provider.isLoading)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else ...[
                    SliverToBoxAdapter(
                      child: _buildMetricsGrid(isDark, provider.stats),
                    ),
                    SliverToBoxAdapter(
                      child: _buildAttendanceBar(isDark, provider.stats),
                    ),
                    SliverToBoxAdapter(
                      child: _buildRecentActivity(isDark, provider.stats),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, AuthProvider auth) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: isDark
                    ? AppColors.darkSecondary
                    : AppColors.lightSecondary,
                child: AppText(
                  (auth.currentUser?.name ?? 'H').substring(0, 1).toUpperCase(),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.muted('Good ${_greeting()},'),
                    AppText.title(auth.currentUser?.name ?? 'HR Admin'),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.3),
                  ),
                ),
                child: const AppText(
                  'HR Admin',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const AppText.heading('Overview'),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(bool isDark, DashboardStatsModel stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          MetricCard(
            title: 'Total Employees',
            value: stats.totalEmployees.toString(),
            icon: Icons.groups_rounded,
            iconColor: AppColors.info,
          ),
          MetricCard(
            title: 'Present Today',
            value: stats.presentToday.toString(),
            icon: Icons.how_to_reg_rounded,
            iconColor: AppColors.success,
          ),
          MetricCard(
            title: 'Pending Leaves',
            value: stats.pendingLeaves.toString(),
            icon: Icons.pending_actions_rounded,
            iconColor: AppColors.warning,
          ),
          MetricCard(
            title: 'Open Positions',
            value: stats.openPositions.toString(),
            icon: Icons.work_outline_rounded,
            iconColor: AppColors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceBar(bool isDark, DashboardStatsModel stats) {
    final total = stats.presentToday + stats.absentToday + stats.lateToday;
    if (total == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppText.bodyBold("Today's Attendance"),
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
                ),
                _buildLegendDot(AppColors.warning, 'Late', stats.lateToday),
                _buildLegendDot(AppColors.error, 'Absent', stats.absentToday),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label, int count) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        AppText.caption('$label ($count)'),
      ],
    );
  }

  Widget _buildRecentActivity(bool isDark, DashboardStatsModel stats) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText.subtitle('Recent Activity'),
          const SizedBox(height: 10),
          if (stats.recentActivity.isEmpty)
            _buildEmptyActivity(isDark)
          else
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: stats.recentActivity.length,
                separatorBuilder: (_, r) => Divider(
                  height: 1,
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                itemBuilder: (context, i) {
                  return _ActivityTile(
                    activity: stats.recentActivity[i],
                    isDark: isDark,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyActivity(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 36,
            color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
          ),
          const SizedBox(height: 8),
          const AppText.muted('No recent activity'),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}

class _ActivityTile extends StatelessWidget {
  final RecentActivityModel activity;
  final bool isDark;

  const _ActivityTile({required this.activity, required this.isDark});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (activity.type) {
      case 'leave':
        icon = Icons.event_note_rounded;
        color = AppColors.warning;
        break;
      case 'hire':
        icon = Icons.person_add_rounded;
        color = AppColors.success;
        break;
      case 'payroll':
        icon = Icons.payments_rounded;
        color = AppColors.info;
        break;
      default:
        icon = Icons.notifications_rounded;
        color = AppColors.purple;
    }

    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: AppText.bodyBold(activity.title),
      subtitle: AppText.muted(activity.subtitle),
      trailing: AppText.caption(activity.timeAgo),
    );
  }
}
