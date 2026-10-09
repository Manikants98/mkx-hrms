import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:mkx_core/features/auth/state/auth_provider.dart';
import 'package:mkx_core/utils/date_utils.dart';
import '../../../widgets/ios27_status_badge.dart';
import 'package:provider/provider.dart';

import '../../../widgets/ios27_glass_surface.dart';
import '../../../widgets/ios27_loader.dart';
import '../../../widgets/ios27_pull_to_refresh.dart';
import '../../../widgets/ios27_segmented_control.dart';
import '../models/attendance_model.dart';
import '../state/attendance_provider.dart';

/// Employee historical punch logs and month filtering screen with iOS 27 Liquid Glass design.
class AttendanceHistoryScreen extends StatefulWidget {
  /// Constructs the attendance history screen.
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  int _selectedFilterIndex = 0;

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

  /// Filters raw attendance records by month and status criteria.
  List<AttendanceRecord> _applyFilter(List<AttendanceRecord> history) {
    List<AttendanceRecord> result = history;

    if (_selectedMonth != null) {
      result = result.where((AttendanceRecord item) {
        final List<String> parts = item.date.split('-');
        if (parts.length < 2) return false;
        final int? year = int.tryParse(parts[0]);
        final int? month = int.tryParse(parts[1]);
        return year == _selectedMonth!.year && month == _selectedMonth!.month;
      }).toList();
    }

    if (_selectedFilterIndex == 0) return result;
    final String label = _filters[_selectedFilterIndex].toLowerCase();
    return result
        .where((AttendanceRecord item) => item.status.toLowerCase() == label)
        .toList();
  }

  /// Parses an ISO join date string to a DateTime instance.
  DateTime? _parseJoinDate(String? raw) {
    if (raw == null) return null;
    final List<String> parts = raw.split('-');
    if (parts.length < 2) return null;
    final int? year = int.tryParse(parts[0]);
    final int? month = int.tryParse(parts[1]);
    if (year == null || month == null) return null;
    return DateTime(year, month);
  }

  /// Presents an iOS 27 glass-styled modal sheet for month selection.
  Future<void> _showMonthPicker() async {
    final DateTime now = DateTime.now();
    final DateTime? joinDate = _parseJoinDate(
      context.read<AuthProvider>().currentUser?.joinDate,
    );
    int pickerYear = _selectedMonth?.year ?? now.year;

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext ctx) {
        final bool isDark =
            CupertinoTheme.of(ctx).brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setSheetState) {
            return GlassCard(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 34),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: isDark
                            ? CupertinoColors.white.withValues(alpha: 0.24)
                            : CupertinoColors.black.withValues(alpha: 0.26),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed:
                              (joinDate != null && pickerYear <= joinDate.year)
                                  ? null
                                  : () => setSheetState(() => pickerYear--),
                          child:
                              const Icon(CupertinoIcons.chevron_left, size: 20),
                        ),
                        Text(
                          '$pickerYear',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            color: isDark
                                ? CupertinoColors.white
                                : const Color(0xFF1C1C1E),
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: pickerYear >= now.year
                              ? null
                              : () => setSheetState(() => pickerYear++),
                          child: const Icon(CupertinoIcons.chevron_right,
                              size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 2.1,
                      children: List.generate(12, (int i) {
                        final int month = i + 1;
                        final bool isFuture =
                            pickerYear == now.year && month > now.month;
                        final bool isBeforeJoin = joinDate != null &&
                            (pickerYear < joinDate.year ||
                                (pickerYear == joinDate.year &&
                                    month < joinDate.month));
                        final bool isSelected =
                            _selectedMonth?.year == pickerYear &&
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
                                  ? const Color(0xFF007AFF)
                                  : (isDark
                                      ? CupertinoColors.white
                                          .withValues(alpha: 0.08)
                                      : CupertinoColors.black
                                          .withValues(alpha: 0.05)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _monthNames[i],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: (isFuture || isBeforeJoin)
                                    ? (isDark
                                        ? CupertinoColors.white
                                            .withValues(alpha: 0.24)
                                        : CupertinoColors.black
                                            .withValues(alpha: 0.26))
                                    : (isSelected
                                        ? CupertinoColors.white
                                        : (isDark
                                            ? CupertinoColors.white
                                                .withValues(alpha: 0.70)
                                            : const Color(0xFF1C1C1E))),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    if (_selectedMonth != null) ...[
                      const SizedBox(height: 16),
                      CupertinoButton(
                        onPressed: () {
                          setState(() => _selectedMonth = null);
                          Navigator.of(ctx).pop();
                        },
                        child: const Text('Clear Filter',
                            style: TextStyle(color: Color(0xFFFF3B30))),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark =
        CupertinoTheme.of(context).brightness == Brightness.dark;
    final AttendanceProvider attendance = context.watch<AttendanceProvider>();
    final List<AttendanceRecord> filtered = _applyFilter(attendance.history);

    final String monthLabel = _selectedMonth != null
        ? '${_monthNames[_selectedMonth!.month - 1]} ${_selectedMonth!.year}'
        : 'All Months';

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.transparent,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Punch Records',
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
                        'Attendance',
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
                  Ios27GlassButton(
                    onPressed: _showMonthPicker,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.calendar,
                          size: 15,
                          color: _selectedMonth != null
                              ? const Color(0xFF007AFF)
                              : (isDark
                                  ? CupertinoColors.white
                                      .withValues(alpha: 0.70)
                                  : const Color(0xFF3A3A3C)),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          monthLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _selectedMonth != null
                                ? const Color(0xFF007AFF)
                                : (isDark
                                    ? CupertinoColors.white
                                        .withValues(alpha: 0.70)
                                    : const Color(0xFF3A3A3C)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Ios27PageLoader(
                isLoading: attendance.isLoading && attendance.history.isEmpty,
                message: 'Loading Shift Logs...',
                child: Ios27RefreshableScrollView(
                  onRefresh: () async {
                    await context.read<AttendanceProvider>().loadAttendance();
                  },
                  padding: const EdgeInsets.only(bottom: 120),
                  children: [
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Ios27SegmentedControl(
                        segments: _filters,
                        selectedIndex: _selectedFilterIndex,
                        onSegmentSelected: (int index) {
                          if (index >= 0 && index < _filters.length) {
                            setState(() => _selectedFilterIndex = index);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Ios27SectionHeader(title: 'Shift Timings & Logs'),
                    if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 24),
                        child: Ios27GlassCard(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.clock,
                                size: 44,
                                color: isDark
                                    ? CupertinoColors.white
                                        .withValues(alpha: 0.4)
                                    : const Color(0xFF8E8E93),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No attendance records',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? CupertinoColors.white
                                      : const Color(0xFF1C1C1E),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'No punch logs match the selected filter criteria.',
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
                          children: filtered.map((AttendanceRecord item) {
                            String displayWorkHours = item.workHours;
                            if (item.hasCheckedIn && !item.hasCheckedOut) {
                              try {
                                final DateTime now = attendance.currentTime;
                                final DateTime recordDate =
                                    DateTime.parse(item.date).toLocal();
                                if (recordDate.year == now.year &&
                                    recordDate.month == now.month &&
                                    recordDate.day == now.day) {
                                  final DateFormat format =
                                      DateFormat('hh:mm a');
                                  final DateTime checkInTime =
                                      format.parse(item.checkIn);
                                  final DateTime checkInDateTime = DateTime(
                                      now.year,
                                      now.month,
                                      now.day,
                                      checkInTime.hour,
                                      checkInTime.minute);
                                  final Duration diff =
                                      now.difference(checkInDateTime);
                                  if (!diff.isNegative) {
                                    final int h = diff.inHours;
                                    final int m = diff.inMinutes % 60;
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
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: -0.2,
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
                          }).toList(),
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
}
