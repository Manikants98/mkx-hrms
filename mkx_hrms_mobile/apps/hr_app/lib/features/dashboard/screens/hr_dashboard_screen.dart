import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:mkx_core/features/auth/state/auth_provider.dart';
import 'package:mkx_core/widgets/metric_card.dart';
import 'package:mkx_core/widgets/mkx_app_bar.dart';
import 'package:mkx_core/widgets/section_tile.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

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
        child: M3ERefreshIndicator.contained(
          onRefresh: () => context.read<DashboardProvider>().loadStats(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAttendanceSection(isDark, provider.stats),
                const SizedBox(height: 4),
                _buildMetricsGrid(isDark, provider.stats),
                const SizedBox(height: 10),
                _buildRecentActivity(isDark, provider.stats),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(bool isDark, DashboardStatsModel stats) {
    return Column(
      spacing: 4,
      children: [
        Row(
          spacing: 4,
          children: [
            Expanded(
              child: MetricCard(
                title: 'Total Employees',
                value: stats.totalEmployees.toString(),
                subtext: 'Active workforce',
                icon: Icons.people_outline_rounded,
                iconColor: M3ETheme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(3),
                  bottomRight: Radius.circular(3),
                  topRight: Radius.circular(3),
                ),
              ),
            ),
            Expanded(
              child: MetricCard(
                title: 'Present Today',
                value: stats.presentToday.toString(),
                subtext: 'On duty',
                icon: Icons.check_circle_outline_rounded,
                iconColor: Colors.green,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(10),
                  bottomLeft: Radius.circular(3),
                  bottomRight: Radius.circular(3),
                  topLeft: Radius.circular(3),
                ),
              ),
            ),
          ],
        ),
        Row(
          spacing: 4,
          children: [
            Expanded(
              child: MetricCard(
                title: 'Pending Leaves',
                value: stats.pendingLeaves.toString(),
                subtext: 'Awaiting approval',
                icon: Icons.hourglass_top_rounded,
                iconColor: Colors.orange,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(3),
                  topRight: Radius.circular(3),
                  topLeft: Radius.circular(3),
                ),
              ),
            ),
            Expanded(
              child: MetricCard(
                title: 'Open Positions',
                value: stats.openPositions.toString(),
                subtext: 'Recruitment pipelines',
                icon: Icons.work_outline_rounded,
                iconColor: const Color(0xffa855f7),
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(10),
                  bottomLeft: Radius.circular(3),
                  topRight: Radius.circular(3),
                  topLeft: Radius.circular(3),
                ),
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

    final Color presentColor = isDark ? Colors.green.shade500 : Colors.green;
    final Color lateColor = isDark ? Colors.orange.shade500 : Colors.orange;
    final Color absentColor = isDark ? Colors.red.shade500 : Colors.red;

    return M3ECard(
      variant: M3ECardVariant.filled,
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(16),
      color: colorScheme.surfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Attendance",
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? M3ETheme.of(context).colorScheme.onSurface
                  : Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              height: 220,
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SfCircularChart(
                    margin: EdgeInsets.zero,
                    series: <CircularSeries>[
                      DoughnutSeries<_ChartData, String>(
                        dataSource: [
                          _ChartData(
                              'Present', stats.presentToday, presentColor),
                          _ChartData('Late', stats.lateToday, lateColor),
                          _ChartData('Absent', stats.absentToday, absentColor),
                        ],
                        xValueMapper: (_ChartData data, _) => data.category,
                        yValueMapper: (_ChartData data, _) => data.value,
                        pointColorMapper: (_ChartData data, _) => data.color,
                        innerRadius: '60%',
                        radius: '100%',
                        animationDuration: 1000,
                        dataLabelMapper: (_ChartData data, _) {
                          if (data.value == 0) return '';
                          return data.category;
                        },
                        dataLabelSettings: DataLabelSettings(
                          isVisible: true,
                          labelPosition: ChartDataLabelPosition.outside,
                          connectorLineSettings: const ConnectorLineSettings(
                            type: ConnectorType.line,
                            length: '10%',
                          ),
                          textStyle: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    ],
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$total',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDark ? colorScheme.onSurface : Colors.black,
                        ),
                      ),
                      Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLegendDot(
                presentColor,
                'Present',
                stats.presentToday,
                isDark,
                context,
              ),
              _buildLegendDot(
                lateColor,
                'Late',
                stats.lateToday,
                isDark,
                context,
              ),
              _buildLegendDot(
                absentColor,
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
            color: M3ETheme.of(context).colorScheme.onSurfaceVariant,
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
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: M3ETheme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 10),
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
                  color: M3ETheme.of(context).colorScheme.onSurfaceVariant,
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

    final typeLower = activity.type.toLowerCase();
    final titleLower = activity.title.toLowerCase();
    final subtitleLower = activity.subtitle.toLowerCase();

    if (typeLower == 'error' || typeLower == 'deleted') {
      color = M3ETheme.of(context).colorScheme.error;
    } else if (typeLower == 'warning' || titleLower.contains('leave')) {
      color = Colors.orange;
    } else if (typeLower == 'success' || typeLower == 'hire') {
      color = Colors.green;
    } else if (typeLower == 'payroll') {
      color = M3ETheme.of(context).colorScheme.primary;
    } else {
      color = const Color(0xffa855f7);
    }

    if (titleLower.contains('attendance') ||
        subtitleLower.contains('clock') ||
        subtitleLower.contains('attendance')) {
      icon = Icons.access_time_filled_rounded;
    } else if (titleLower.contains('leave') ||
        subtitleLower.contains('leave')) {
      icon = Icons.event_note_rounded;
    } else if (titleLower.contains('payroll') ||
        subtitleLower.contains('payroll') ||
        subtitleLower.contains('pay')) {
      icon = Icons.payments_rounded;
    } else if (titleLower.contains('employee') ||
        subtitleLower.contains('profile') ||
        subtitleLower.contains('record')) {
      icon = Icons.manage_accounts_rounded;
    } else if (titleLower.contains('hire') || typeLower == 'hire') {
      icon = Icons.person_add_rounded;
    } else {
      icon = Icons.notifications_rounded;
    }

    final mutedColor = M3ETheme.of(context).colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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

class _ChartData {
  _ChartData(this.category, this.value, this.color);
  final String category;
  final int value;
  final Color color;
}
