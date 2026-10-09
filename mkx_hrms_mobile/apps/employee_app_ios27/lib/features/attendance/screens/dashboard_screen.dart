import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:mkx_core/features/auth/state/auth_provider.dart';
import 'package:mkx_core/network/dio_client.dart';
import 'package:mkx_core/utils/date_utils.dart';
import 'package:mkx_core/utils/ui_helpers.dart';
import '../../../widgets/ios27_status_badge.dart';
import 'package:provider/provider.dart';

import '../../../widgets/ios27_glass_surface.dart';
import '../../../widgets/ios27_loader.dart';
import '../../../widgets/ios27_pull_to_refresh.dart';
import '../../ai_assistant/screens/smart_assistant_screen.dart';
import '../../leaves/state/leaves_provider.dart';
import '../../leaves/widgets/apply_leave_bottom_sheet.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../notifications/state/notifications_provider.dart';
import '../state/attendance_provider.dart';
import '../widgets/punch_card.dart';

/// Employee Attendance & Punch Dashboard Screen
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<dynamic> _celebrations = [];
  Map<String, dynamic>? _smartInsights;

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
    final notifications = context.read<NotificationsProvider>();
    final client = DioClient.instance;

    await Future.wait([
      attendance.loadAttendance(
        employeeId: auth.currentUser?.employeeDbId,
        employeeCode: auth.currentUser?.employeeId,
      ),
      leaves.loadLeaves(
        employeeId: auth.currentUser?.employeeDbId,
        employeeCode: auth.currentUser?.employeeId,
      ),
      notifications.fetchNotifications(),
      client.get('/dashboard/overview').then((res) {
        if (res is Map<String, dynamic> && mounted) {
          setState(() {
            _celebrations = res['celebrations'] ?? [];
            _smartInsights = res['smart_insights'];
          });
        }
      }).catchError((e) {
        debugPrint('Failed to load dashboard overview: $e');
      }),
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

  Future<void> _sendWish(Map<String, dynamic> celeb) async {
    final isBirthday = celeb['type'] == 'Birthday';
    final isNewJoiner = celeb['type'] == 'New Joiner';
    final auth = context.read<AuthProvider>();
    final userName = auth.currentUser?.name ?? "Your Colleague";

    final defaultMessage = isBirthday
        ? 'Happy Birthday! Wishing you a great day from $userName!'
        : isNewJoiner
            ? 'Welcome to the team! Wishing you a great journey ahead from $userName!'
            : 'Happy Work Anniversary! Wishing you continued success from $userName!';

    final TextEditingController messageController =
        TextEditingController(text: defaultMessage);

    final result = await showCupertinoDialog<String>(
      context: context,
      builder: (ctx) {
        return CupertinoAlertDialog(
          title:
              Text(isBirthday ? 'Send Birthday Wish' : 'Send Anniversary Wish'),
          content: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: CupertinoTextField(
              controller: messageController,
              maxLines: 3,
              placeholder: 'Enter your custom message here...',
              decoration: BoxDecoration(
                color: CupertinoColors.extraLightBackgroundGray,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: CupertinoColors.systemGrey4),
              ),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(ctx, messageController.text),
              child: const Text('Send'),
            ),
          ],
        );
      },
    );

    if (result == null || result.trim().isEmpty) return;

    try {
      await DioClient.instance.post('/dashboard/send-wish', data: {
        'employee_id': celeb['employee_id'],
        'message': result.trim(),
      });
      if (mounted) {
        UiHelpers.showSnackBar(context, 'Wish sent successfully!',
            isSuccess: true);
      }
    } catch (e) {
      if (mounted) {
        UiHelpers.showSnackBar(context, 'Failed to send wish', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        CupertinoTheme.of(context).brightness == Brightness.dark;
    final primaryColor = CupertinoTheme.of(context).primaryColor;
    final auth = context.watch<AuthProvider>();
    final attendance = context.watch<AttendanceProvider>();
    final leaves = context.watch<LeavesProvider>();
    final notifications = context.watch<NotificationsProvider>();
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
    final stats = attendance.stats;
    final presentDays = stats?.presentDays ?? 0;
    final totalDays = stats?.totalDays ?? 0;
    final attendancePercent =
        totalDays > 0 ? ((presentDays / totalDays) * 100).round() : 0;
    final lateDays = stats?.lateDays ?? 0;
    final absentDays = stats?.absentDays ?? 0;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.transparent,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Good ${_greeting()}, ${user?.name.split(" ").first ?? "Employee"}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFF8E8E93)
                              : const Color(0xFF6E6E73),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Dashboard',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                          color: isDark
                              ? CupertinoColors.white
                              : const Color(0xFF1C1C1E),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GlassIconButton(
                        icon: Icon(
                          CupertinoIcons.sparkles,
                          size: 20,
                          color: isDark
                              ? const Color(0xFF64D2FF)
                              : const Color(0xFF007AFF),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            CupertinoPageRoute<void>(
                              builder: (context) =>
                                  const SmartAssistantScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          GlassIconButton(
                            icon: Icon(
                              CupertinoIcons.bell,
                              size: 20,
                              color: isDark
                                  ? CupertinoColors.white
                                  : const Color(0xFF1C1C1E),
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                CupertinoPageRoute<void>(
                                  builder: (context) =>
                                      const NotificationsScreen(),
                                ),
                              );
                            },
                          ),
                          if (notifications.unreadCount > 0)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF3B30),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                constraints: const BoxConstraints(
                                    minWidth: 16, minHeight: 16),
                                child: Text(
                                  notifications.unreadCount.toString(),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: CupertinoColors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Ios27PageLoader(
                isLoading: attendance.isLoading && attendance.history.isEmpty,
                message: 'Loading Dashboard...',
                child: Ios27RefreshableScrollView(
                  onRefresh: _loadData,
                  padding: const EdgeInsets.only(bottom: 140),
                  children: [
                    PunchCard(
                      currentTime: attendance.currentTime,
                      record: attendance.todayRecord,
                      isPunching: attendance.isPunching,
                      onPunchIn: _handlePunchIn,
                      onPunchOut: _handlePunchOut,
                    ),
                    if (_celebrations.isNotEmpty) ...[
                      const Ios27SectionHeader(title: 'Celebrations Today'),
                      Ios27GlassCard(
                        child: Column(
                          children: _celebrations.map((celeb) {
                            final bool isBirthday =
                                celeb['type'] == 'Birthday';
                            final bool isNewJoiner =
                                celeb['type'] == 'New Joiner';
                            final bool hasAvatar = celeb['avatar'] != null &&
                                celeb['avatar'].toString().trim().isNotEmpty;

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      color: isBirthday
                                          ? const Color(0xFFFF9500)
                                              .withValues(alpha: 0.18)
                                          : isNewJoiner
                                              ? const Color(0xFF34C759)
                                                  .withValues(alpha: 0.18)
                                              : primaryColor
                                                  .withValues(alpha: 0.18),
                                      image: hasAvatar
                                          ? DecorationImage(
                                              image: NetworkImage(
                                                  celeb['avatar'].toString()),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: hasAvatar
                                        ? null
                                        : Icon(
                                            isBirthday
                                                ? CupertinoIcons.gift_fill
                                                : isNewJoiner
                                                    ? CupertinoIcons.sparkles
                                                    : CupertinoIcons.rosette,
                                            color: isBirthday
                                                ? const Color(0xFFFF9500)
                                                : isNewJoiner
                                                    ? const Color(0xFF34C759)
                                                    : primaryColor,
                                            size: 20,
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          celeb['name']?.toString() ?? '',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: isDark
                                                ? CupertinoColors.white
                                                : const Color(0xFF1C1C1E),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          isBirthday
                                              ? 'Happy Birthday!'
                                              : isNewJoiner
                                                  ? 'Welcome to the team!'
                                                  : '${celeb['years']} Years Anniversary!',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark
                                                ? const Color(0xFF8E8E93)
                                                : const Color(0xFF6E6E73),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    onPressed: () => _sendWish(
                                        celeb as Map<String, dynamic>),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: (isBirthday
                                                ? const Color(0xFFFF9500)
                                                : isNewJoiner
                                                    ? const Color(0xFF34C759)
                                                    : primaryColor)
                                            .withValues(alpha: 0.16),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        CupertinoIcons.paperplane_fill,
                                        size: 16,
                                        color: isBirthday
                                            ? const Color(0xFFFF9500)
                                            : isNewJoiner
                                                ? const Color(0xFF34C759)
                                                : primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                    const Ios27SectionHeader(title: 'Monthly Overview'),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildMetricTile(
                                  title: 'Days Present',
                                  value: '$presentDays',
                                  subtext: '$attendancePercent% Attendance',
                                  icon: CupertinoIcons.checkmark_circle_fill,
                                  color: const Color(0xFF34C759),
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildMetricTile(
                                  title: 'Late Days',
                                  value: '$lateDays',
                                  subtext: '$absentDays Absent this month',
                                  icon: CupertinoIcons.time_solid,
                                  color: const Color(0xFF007AFF),
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildMetricTile(
                                  title: 'Leave Balance',
                                  value: '$totalRemainingLeaves',
                                  subtext: 'Days Available',
                                  icon: CupertinoIcons.briefcase_fill,
                                  color: const Color(0xFFFF9500),
                                  isDark: isDark,
                                  onTap: () {
                                    showCupertinoModalPopup<void>(
                                      context: context,
                                      builder: (_) =>
                                          const ApplyLeaveBottomSheet(),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildMetricTile(
                                  title: 'Pending Leaves',
                                  value: '$pendingLeaveRequests',
                                  subtext: pendingLeaveRequests == 0
                                      ? 'No pending requests'
                                      : '$pendingLeaveRequests under review',
                                  icon: CupertinoIcons.hourglass,
                                  color: const Color(0xFFAF52DE),
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (_smartInsights != null)
                      _buildAiInsightsSection(_smartInsights!, isDark: isDark),
                    const Ios27SectionHeader(title: 'Recent Activity'),
                    if (attendance.history.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Ios27GlassCard(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.calendar,
                                size: 40,
                                color: isDark
                                    ? CupertinoColors.white
                                        .withValues(alpha: 0.4)
                                    : const Color(0xFF8E8E93),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No attendance records yet',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? CupertinoColors.white
                                      : const Color(0xFF1C1C1E),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Your shift logs will appear here after clocking in.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? CupertinoColors.white
                                          .withValues(alpha: 0.6)
                                      : const Color(0xFF6C6C70),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Ios27GlassCard(
                        child: Column(
                          children: attendance.history
                              .where((item) {
                                final date = DateTime.tryParse(item.date);
                                if (date == null) return false;
                                final now = DateTime.now();
                                final startOfWeek =
                                    DateTime(now.year, now.month, now.day)
                                        .subtract(
                                            Duration(days: now.weekday - 1));
                                return date.weekday != DateTime.sunday &&
                                    !date.isBefore(startOfWeek);
                              })
                              .take(6)
                              .map((item) {
                                String displayWorkHours = item.workHours;
                                if (item.hasCheckedIn && !item.hasCheckedOut) {
                                  try {
                                    final now = attendance.currentTime;
                                    final recordDate =
                                        DateTime.parse(item.date).toLocal();
                                    if (recordDate.year == now.year &&
                                        recordDate.month == now.month &&
                                        recordDate.day == now.day) {
                                      final format = DateFormat('hh:mm a');
                                      final checkInTime =
                                          format.parse(item.checkIn);
                                      final checkInDateTime = DateTime(
                                          now.year,
                                          now.month,
                                          now.day,
                                          checkInTime.hour,
                                          checkInTime.minute);
                                      final diff =
                                          now.difference(checkInDateTime);
                                      if (!diff.isNegative) {
                                        final h = diff.inHours;
                                        final m = diff.inMinutes % 60;
                                        displayWorkHours = '${h}h ${m}m';
                                      }
                                    }
                                  } catch (_) {}
                                }

                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? CupertinoColors.white
                                                  .withValues(alpha: 0.08)
                                              : CupertinoColors.black
                                                  .withValues(alpha: 0.04),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              AppDateUtils.formatDate(item.date)
                                                  .split(' ')[0],
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? const Color(0xFF8E8E93)
                                                    : const Color(0xFF6E6E73),
                                              ),
                                            ),
                                            Text(
                                              item.date.split('-').last,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w800,
                                                color: isDark
                                                    ? CupertinoColors.white
                                                    : const Color(0xFF1C1C1E),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${item.checkIn} - ${item.checkOut}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? CupertinoColors.white
                                                    : const Color(0xFF1C1C1E),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '$displayWorkHours • ${item.location}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isDark
                                                    ? const Color(0xFF8E8E93)
                                                    : const Color(0xFF6E6E73),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Ios27StatusBadge(status: item.status),
                                    ],
                                  ),
                                );
                              })
                              .toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a balanced iOS 27 liquid glass metric tile for the Monthly Overview grid.
  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required Color color,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          onPressed: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF151926).withValues(alpha: 0.72)
                  : CupertinoColors.white.withValues(alpha: 0.80),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? CupertinoColors.white.withValues(alpha: 0.14)
                    : CupertinoColors.white.withValues(alpha: 0.75),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? CupertinoColors.black.withValues(alpha: 0.35)
                      : const Color(0x12000000),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFF8E8E93)
                              : const Color(0xFF6E6E73),
                        ),
                      ),
                    ),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: isDark ? 0.20 : 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, size: 15, color: color),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: isDark
                        ? CupertinoColors.white
                        : const Color(0xFF1C1C1E),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtext,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFF636366)
                        : const Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the iOS 27 AI Smart Insights glass section.
  Widget _buildAiInsightsSection(
    Map<String, dynamic> insights, {
    required bool isDark,
  }) {
    final String? summary = insights['summary'] as String?;
    final List<dynamic> suggestions =
        insights['suggestions'] as List<dynamic>? ?? [];

    if (summary == null && suggestions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Ios27SectionHeader(title: 'AI Smart Insights'),
        Ios27GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (summary != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    summary,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? CupertinoColors.white
                          : const Color(0xFF1C1C1E),
                    ),
                  ),
                ),
              ...suggestions.map((s) {
                final String type = s['type']?.toString() ?? 'info';
                final String msg = s['message']?.toString() ?? '';

                IconData icon;
                Color iconColor;

                if (type == 'warning') {
                  icon = CupertinoIcons.exclamationmark_triangle_fill;
                  iconColor = const Color(0xFFFF9500);
                } else if (type == 'reminder') {
                  icon = CupertinoIcons.bell_fill;
                  iconColor = const Color(0xFF007AFF);
                } else if (type == 'success') {
                  icon = CupertinoIcons.checkmark_circle_fill;
                  iconColor = const Color(0xFF34C759);
                } else {
                  icon = CupertinoIcons.info_circle_fill;
                  iconColor = const Color(0xFF5856D6);
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, size: 14, color: iconColor),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          msg,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: isDark
                                ? const Color(0xFFD1D1D6)
                                : const Color(0xFF3A3A3C),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
