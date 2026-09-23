import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:mkx_core/constants/app_colors.dart';
import 'package:mkx_core/features/auth/state/auth_provider.dart';
import 'package:mkx_core/utils/date_utils.dart';
import 'package:mkx_core/utils/ui_helpers.dart';
import 'package:mkx_core/widgets/empty_state.dart';
import 'package:mkx_core/widgets/metric_card.dart';
import 'package:mkx_core/widgets/mkx_app_bar.dart';
import 'package:mkx_core/widgets/section_tile.dart';
import 'package:mkx_core/widgets/status_badge.dart';
import 'package:provider/provider.dart';

import '../../leaves/state/leaves_provider.dart';
import '../../leaves/widgets/apply_leave_bottom_sheet.dart';
import '../state/attendance_provider.dart';
import '../widgets/punch_card.dart';

/// Employee Attendance & Punch Dashboard Screen
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    final attendance = context.read<AttendanceProvider>();
    final leaves = context.read<LeavesProvider>();
    await Future.wait([
      attendance.loadAttendance(
        employeeId: auth.currentUser?.employeeDbId,
        employeeCode: auth.currentUser?.employeeId,
      ),
      leaves.loadLeaves(
        employeeId: auth.currentUser?.employeeDbId,
        employeeCode: auth.currentUser?.employeeId,
      ),
    ]);
  }

  Future<void> _handlePunchIn() async {
    final auth = context.read<AuthProvider>();
    final attendance = context.read<AttendanceProvider>();
    final ok = await attendance.punchIn(
      employeeId: auth.currentUser?.employeeDbId,
      location: 'Office',
    );

    if (!mounted) return;
    if (ok) {
      UiHelpers.showSnackBar(
        context,
        'Successfully punched in at ${attendance.todayRecord?.checkIn}',
        isSuccess: true,
      );
    } else {
      UiHelpers.showSnackBar(
        context,
        attendance.errorMessage ?? 'Failed to punch in',
        isError: true,
      );
    }
  }

  Future<void> _handlePunchOut() async {
    final confirmed = await UiHelpers.showConfirmDialog(
      context: context,
      title: 'Confirm Punch Out',
      message: 'Are you sure you want to end your work shift for today?',
      confirmText: 'Punch Out',
      isDestructive: true,
    );

    if (confirmed != true || !mounted) return;

    final auth = context.read<AuthProvider>();
    final attendance = context.read<AttendanceProvider>();
    final ok = await attendance.punchOut(
      employeeId: auth.currentUser?.employeeDbId,
      location: 'Office',
    );

    if (!mounted) return;
    if (ok) {
      UiHelpers.showSnackBar(
        context,
        'Shift completed! Punched out at ${attendance.todayRecord?.checkOut}',
        isSuccess: true,
      );
    } else {
      UiHelpers.showSnackBar(
        context,
        attendance.errorMessage ?? 'Failed to punch out',
        isError: true,
      );
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = M3ETheme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final attendance = context.watch<AttendanceProvider>();
    final leaves = context.watch<LeavesProvider>();
    final user = auth.currentUser;

    final totalRemainingLeaves = leaves.balances?.list.isNotEmpty == true
        ? leaves.balances!.list.fold<int>(0, (sum, q) => sum + q.remaining)
        : (leaves.masterLeaveTypes.isNotEmpty
            ? leaves.masterLeaveTypes.fold<int>(
                0,
                (sum, t) => sum + t.daysPerYear,
              )
            : 0);
    final pendingLeaveRequests = leaves.balances?.pendingRequests ?? 0;

    return Scaffold(
      backgroundColor: M3ETheme.of(context).colorScheme.surfaceContainer,
      appBar: MkxAppBar(
        title: 'Dashboard',
        subtitle: 'Good ${_greeting()}, ${user?.name ?? "Employee"}',
      ),
      body: M3ERefreshIndicator.contained(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PunchCard(
                currentTime: attendance.currentTime,
                record: attendance.todayRecord,
                isPunching: attendance.isPunching,
                onPunchIn: _handlePunchIn,
                onPunchOut: _handlePunchOut,
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'MONTHLY ATTENDANCE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: M3ETheme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      title: 'Present Days',
                      value: '${attendance.stats?.presentDays ?? 0}',
                      subtext: 'This month',
                      icon: Icons.check_circle_outline_rounded,
                      iconColor: AppColors.success,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(14),
                        topRight: Radius.circular(3),
                        bottomLeft: Radius.circular(3),
                        bottomRight: Radius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: MetricCard(
                      title: 'Late Punches',
                      value: '${attendance.stats?.lateDays ?? 0}',
                      subtext: 'After 10:00 AM',
                      icon: Icons.access_time_rounded,
                      iconColor: AppColors.warning,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(3),
                        topRight: Radius.circular(14),
                        bottomLeft: Radius.circular(3),
                        bottomRight: Radius.circular(3),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      title: 'Leave Balance',
                      value: '$totalRemainingLeaves',
                      subtext: 'Available days',
                      icon: Icons.beach_access_rounded,
                      iconColor: AppColors.info,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(3),
                        topRight: Radius.circular(3),
                        bottomLeft: Radius.circular(14),
                        bottomRight: Radius.circular(3),
                      ),
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const ApplyLeaveBottomSheet(),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: MetricCard(
                      title: 'Pending Leaves',
                      value: '$pendingLeaveRequests',
                      subtext: pendingLeaveRequests == 1
                          ? '1 awaiting review'
                          : '$pendingLeaveRequests awaiting review',
                      icon: Icons.hourglass_top_rounded,
                      iconColor: const Color(0xffa855f7),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(3),
                        topRight: Radius.circular(3),
                        bottomLeft: Radius.circular(3),
                        bottomRight: Radius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'RECENT ACTIVITY',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                          color:
                              M3ETheme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'THIS WEEK',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                              color: M3ETheme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (attendance.isLoading && attendance.history.isEmpty)
                SectionTile(
                  isDark: isDark,
                  position: TilePosition.only,
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: const SizedBox(
                        width: 36,
                        height: 36,
                        child: M3EProgressIndicator.circular()),
                  ),
                )
              else if (attendance.history.isEmpty)
                const EmptyState(
                  icon: Icons.event_busy_outlined,
                  title: 'No attendance records yet',
                  description:
                      'Your punch logs and daily records will appear here as you punch in and out.',
                )
              else
                SectionCard(
                  isDark: isDark,
                  children: attendance.history
                      .where((item) {
                        final date = DateTime.tryParse(item.date);
                        if (date == null) return false;

                        final now = DateTime.now();
                        final startOfWeek =
                            DateTime(now.year, now.month, now.day)
                                .subtract(Duration(days: now.weekday - 1));

                        return date.weekday != DateTime.sunday &&
                            !date.isBefore(startOfWeek);
                      })
                      .take(7)
                      .map((item) {
                        return Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkSecondary
                                    : AppColors.lightSecondary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    AppDateUtils.formatDate(
                                      item.date,
                                    ).split(' ')[0],
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? AppColors.darkMuted
                                          : AppColors.lightMuted,
                                    ),
                                  ),
                                  Text(
                                    item.date.split('-').last,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? AppColors.darkForeground
                                          : AppColors.lightForeground,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${item.checkIn} - ${item.checkOut}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item.workHours} • ${item.location}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? AppColors.darkMuted
                                          : AppColors.lightMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            StatusBadge(status: item.status),
                          ],
                        );
                      })
                      .toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
