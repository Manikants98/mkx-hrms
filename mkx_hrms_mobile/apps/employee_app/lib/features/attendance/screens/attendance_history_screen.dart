import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:mkx_core/constants/app_colors.dart';
import 'package:mkx_core/features/auth/state/auth_provider.dart';
import 'package:mkx_core/utils/date_utils.dart';
import 'package:mkx_core/widgets/empty_state.dart';
import 'package:mkx_core/widgets/mkx_app_bar.dart';
import 'package:mkx_core/widgets/section_tile.dart';
import 'package:mkx_core/widgets/status_badge.dart';
import 'package:provider/provider.dart';

import '../models/attendance_model.dart';
import '../state/attendance_provider.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  int _selectedFilterIndex = 0;

  /// Currently selected month filter; null means show all months.
  DateTime? _selectedMonth;

  static const List<String> _filters = [
    'All',
    'Present',
    'Late',
    'Absent',
  ];

  static const List<String> _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  List<AttendanceRecord> _applyFilter(List<AttendanceRecord> history) {
    var result = history;

    if (_selectedMonth != null) {
      result = result.where((item) {
        final parts = item.date.split('-');
        if (parts.length < 2) return false;
        final year = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        return year == _selectedMonth!.year && month == _selectedMonth!.month;
      }).toList();
    }

    if (_selectedFilterIndex == 0) return result;
    final label = _filters[_selectedFilterIndex].toLowerCase();
    return result.where((item) => item.status.toLowerCase() == label).toList();
  }

  /// Parses the user's [joinDate] string (YYYY-MM-DD) into a [DateTime].
  DateTime? _parseJoinDate(String? raw) {
    if (raw == null) return null;
    final parts = raw.split('-');
    if (parts.length < 2) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year == null || month == null) return null;
    return DateTime(year, month);
  }

  /// Shows a bottom sheet with year navigation and a month grid picker.
  Future<void> _showMonthPicker() async {
    final now = DateTime.now();
    final joinDate = _parseJoinDate(
      context.read<AuthProvider>().currentUser?.joinDate,
    );
    int pickerYear = _selectedMonth?.year ?? now.year;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final scheme = M3ETheme.of(ctx).colorScheme;
            return Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(M3EIcons.chevron_left),
                        onPressed:
                            (joinDate != null && pickerYear <= joinDate.year)
                                ? null
                                : () => setSheetState(() => pickerYear--),
                      ),
                      Text(
                        '$pickerYear',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(M3EIcons.chevron_right),
                        onPressed: pickerYear >= now.year
                            ? null
                            : () => setSheetState(() => pickerYear++),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 2.2,
                    children: List.generate(12, (i) {
                      final month = i + 1;
                      final isFuture =
                          pickerYear == now.year && month > now.month;
                      final isBeforeJoin = joinDate != null &&
                          (pickerYear < joinDate.year ||
                              (pickerYear == joinDate.year &&
                                  month < joinDate.month));
                      final isSelected = _selectedMonth?.year == pickerYear &&
                          _selectedMonth?.month == month;

                      return GestureDetector(
                        onTap: (isFuture || isBeforeJoin)
                            ? null
                            : () {
                                setState(
                                  () => _selectedMonth =
                                      DateTime(pickerYear, month),
                                );
                                Navigator.of(ctx).pop();
                              },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? scheme.primary
                                : scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _monthNames[i],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: (isFuture || isBeforeJoin)
                                  ? scheme.onSurface.withValues(alpha: 0.3)
                                  : isSelected
                                      ? scheme.onPrimary
                                      : scheme.onSurface,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  if (_selectedMonth != null) ...[
                    SizedBox(
                      width: double.infinity,
                      child: M3EButton.text(
                        onPressed: () {
                          setState(() => _selectedMonth = null);
                          Navigator.of(ctx).pop();
                        },
                        child: const Text('Clear filter'),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = M3ETheme.of(context).brightness == Brightness.dark;
    final colorScheme = M3ETheme.of(context).colorScheme;
    final attendance = context.watch<AttendanceProvider>();
    final filtered = _applyFilter(attendance.history);

    final monthLabel = _selectedMonth != null
        ? '${_monthNames[_selectedMonth!.month - 1]} ${_selectedMonth!.year}'
        : 'Month';

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
      appBar: MkxAppBar(
        title: 'Attendance',
        subtitle: 'All your past punch records',
        actions: [
          GestureDetector(
            onTap: _showMonthPicker,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _selectedMonth != null
                    ? colorScheme.primary
                    : colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    M3EIcons.calendar_month_rounded,
                    size: 14,
                    color: _selectedMonth != null
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    monthLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _selectedMonth != null
                          ? colorScheme.onPrimary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: M3ERefreshIndicator.contained(
        onRefresh: () async {
          await context.read<AttendanceProvider>().loadAttendance();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 5, left: 10, right: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: M3EButtonGroup(
                  type: M3EButtonGroupType.connected,
                  shape: M3EButtonShape.square,
                  size: M3EButtonSize.sm,
                  style: M3EButtonStyle.filled,
                  neighborSquish: true,
                  decoration: M3EToggleButtonDecoration(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return colorScheme.primary;
                      }
                      return colorScheme.surfaceContainerLowest;
                    }),
                  ),
                  selectedIndex: _selectedFilterIndex,
                  onSelectedIndexChanged: (index) {
                    if (index == null) return;
                    setState(() => _selectedFilterIndex = index);
                  },
                  actions: _filters
                      .map((f) => M3EButtonGroupAction(label: Text(f)))
                      .toList(),
                ),
              ),
              const SizedBox(height: 5),
              if (attendance.isLoading && attendance.history.isEmpty)
                SectionTile(
                  isDark: isDark,
                  position: TilePosition.only,
                  padding: const EdgeInsets.all(24),
                  child: const Center(
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: M3EProgressIndicator.circular(),
                    ),
                  ),
                )
              else if (filtered.isEmpty)
                const EmptyState(
                  icon: M3EIcons.history_outlined,
                  title: 'No records found',
                  description:
                      'No attendance records match the selected filter.',
                )
              else
                SectionCard(
                  isDark: isDark,
                  children: filtered.map((item) {
                    String displayWorkHours = item.workHours;
                    if (item.hasCheckedIn && !item.hasCheckedOut) {
                      try {
                        final now = attendance.currentTime;
                        final recordDate = DateTime.parse(item.date).toLocal();
                        if (recordDate.year == now.year &&
                            recordDate.month == now.month &&
                            recordDate.day == now.day) {
                          final format = DateFormat('hh:mm a');
                          final checkInTime = format.parse(item.checkIn);
                          final checkInDateTime = DateTime(now.year, now.month,
                              now.day, checkInTime.hour, checkInTime.minute);
                          final diff = now.difference(checkInDateTime);
                          if (!diff.isNegative) {
                            final h = diff.inHours;
                            final m = diff.inMinutes % 60;
                            displayWorkHours = '${h}h ${m}m';
                          }
                        }
                      } catch (_) {}
                    }

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
                                AppDateUtils.formatDate(item.date)
                                    .split(' ')[0],
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
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$displayWorkHours • ${item.location}',
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
                  }).toList(),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
