import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:mkx_core/features/auth/state/auth_provider.dart';
import 'package:mkx_core/utils/date_utils.dart';
import '../../../widgets/ios27_button.dart';
import '../../../widgets/ios27_status_badge.dart';
import 'package:provider/provider.dart';

import '../../../widgets/ios27_app_bar.dart';
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

  /**
   * Presents the iOS 27 Liquid Glass Segmented Calendar / Wheel picker modal.
   */
  Future<void> _showMonthPicker() async {
    final DateTime? joinDate = _parseJoinDate(
      context.read<AuthProvider>().currentUser?.joinDate,
    );

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext ctx) {
        return _Ios27MonthPickerSheet(
          initialMonth: _selectedMonth,
          joinDate: joinDate,
          onSelected: (DateTime? picked) {
            setState(() => _selectedMonth = picked);
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
            Ios27AppBar(
              title: 'Attendance',
              subtitle: 'Punch Records',
              trailing: Ios27GlassButton(
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
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
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
                    const Ios27SectionHeader(title: 'Shift Timings & Logs'),
                    if (filtered.isEmpty)
                      Ios27GlassCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.clock,
                              size: 44,
                              color: isDark
                                  ? CupertinoColors.white.withValues(alpha: 0.4)
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
                      )
                    else
                      Ios27GlassCard(
                        padding: EdgeInsetsGeometry.symmetric(
                            horizontal: 16, vertical: 8),
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
                              padding: const EdgeInsets.symmetric(vertical: 8),
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
                                      borderRadius: BorderRadius.circular(12),
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

/**
 * iOS 27 Liquid Glass Segmented Calendar / Wheel month selector modal sheet.
 * Features specular glass highlight bars in wheel mode and interactive glass tiles in calendar mode.
 */
class _Ios27MonthPickerSheet extends StatefulWidget {
  /**
   * Currently active selected filter date if one is active.
   */
  final DateTime? initialMonth;

  /**
   * Optional employee joining date threshold to disallow pre-employment dates.
   */
  final DateTime? joinDate;

  /**
   * Callback invoked when a date period is confirmed or cleared.
   */
  final ValueChanged<DateTime?> onSelected;

  /**
   * Constructs the iOS 27 month picker sheet.
   */
  const _Ios27MonthPickerSheet({
    required this.initialMonth,
    required this.joinDate,
    required this.onSelected,
  });

  @override
  State<_Ios27MonthPickerSheet> createState() => _Ios27MonthPickerSheetState();
}

class _Ios27MonthPickerSheetState extends State<_Ios27MonthPickerSheet> {
  int _segmentedIndex = 0;
  late int _selectedYear;
  late int _selectedMonth;
  late final List<int> _years;
  late final FixedExtentScrollController _monthWheelController;
  late final FixedExtentScrollController _yearWheelController;

  static const List<String> _monthNames = <String>[
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

  static const List<String> _fullMonthNames = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    _selectedYear = widget.initialMonth?.year ?? now.year;
    _selectedMonth = widget.initialMonth?.month ?? now.month;

    final int minYear = widget.joinDate?.year ?? (now.year - 4);
    final int startYear = minYear <= now.year ? minYear : now.year - 4;
    _years = List<int>.generate(
      now.year - startYear + 1,
      (int i) => startYear + i,
    );

    final int initialYearIndex =
        _years.indexOf(_selectedYear).clamp(0, _years.length - 1);
    _monthWheelController =
        FixedExtentScrollController(initialItem: _selectedMonth - 1);
    _yearWheelController =
        FixedExtentScrollController(initialItem: initialYearIndex);
  }

  @override
  void dispose() {
    _monthWheelController.dispose();
    _yearWheelController.dispose();
    super.dispose();
  }

  bool _isDateDisabled(int year, int month) {
    final DateTime now = DateTime.now();
    if (year > now.year || (year == now.year && month > now.month)) {
      return true;
    }
    if (widget.joinDate != null) {
      if (year < widget.joinDate!.year ||
          (year == widget.joinDate!.year && month < widget.joinDate!.month)) {
        return true;
      }
    }
    return false;
  }

  /**
   * Dual wheel roller view with centered specular glass highlight bar.
   */
  Widget _buildWheelRoller(
    BuildContext context,
    bool isDark,
    Color primaryColor,
  ) {
    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          IgnorePointer(
            child: Container(
              height: 44,
              margin: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? <Color>[
                          primaryColor.withValues(alpha: 0.22),
                          primaryColor.withValues(alpha: 0.10),
                        ]
                      : <Color>[
                          primaryColor.withValues(alpha: 0.16),
                          primaryColor.withValues(alpha: 0.08),
                        ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? CupertinoColors.white.withValues(alpha: 0.30)
                      : primaryColor.withValues(alpha: 0.45),
                  width: 1.0,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: primaryColor.withValues(alpha: isDark ? 0.25 : 0.15),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: <Widget>[
              Expanded(
                flex: 3,
                child: CupertinoPicker(
                  scrollController: _monthWheelController,
                  itemExtent: 44,
                  magnification: 1.15,
                  useMagnifier: true,
                  squeeze: 1.25,
                  selectionOverlay: const SizedBox.shrink(),
                  onSelectedItemChanged: (int index) {
                    setState(() {
                      _selectedMonth = index + 1;
                    });
                  },
                  children: List<Widget>.generate(12, (int index) {
                    final int month = index + 1;
                    final bool disabled =
                        _isDateDisabled(_selectedYear, month);
                    final bool selected = _selectedMonth == month;
                    return Center(
                      child: Text(
                        _fullMonthNames[index],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: disabled
                              ? (isDark
                                  ? CupertinoColors.white.withValues(alpha: 0.24)
                                  : CupertinoColors.black.withValues(alpha: 0.26))
                              : (selected
                                  ? (isDark
                                      ? CupertinoColors.white
                                      : primaryColor)
                                  : (isDark
                                      ? CupertinoColors.white
                                          .withValues(alpha: 0.65)
                                      : const Color(0xFF6C6C70))),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              Expanded(
                flex: 2,
                child: CupertinoPicker(
                  scrollController: _yearWheelController,
                  itemExtent: 44,
                  magnification: 1.15,
                  useMagnifier: true,
                  squeeze: 1.25,
                  selectionOverlay: const SizedBox.shrink(),
                  onSelectedItemChanged: (int index) {
                    setState(() {
                      _selectedYear = _years[index];
                    });
                  },
                  children: _years.map((int year) {
                    final bool selected = _selectedYear == year;
                    return Center(
                      child: Text(
                        '$year',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected
                              ? (isDark
                                  ? CupertinoColors.white
                                  : primaryColor)
                              : (isDark
                                  ? CupertinoColors.white.withValues(alpha: 0.65)
                                  : const Color(0xFF6C6C70)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /**
   * Calendar grid view with year stepping controls and 12-month glass capsules.
   */
  Widget _buildCalendarGrid(
    BuildContext context,
    bool isDark,
    Color primaryColor,
  ) {
    final DateTime now = DateTime.now();
    final bool canGoBack =
        widget.joinDate == null || _selectedYear > widget.joinDate!.year;
    final bool canGoForward = _selectedYear < now.year;

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(36, 36),
                onPressed: canGoBack
                    ? () {
                        setState(() {
                          _selectedYear--;
                          final int idx = _years.indexOf(_selectedYear);
                          if (idx >= 0) _yearWheelController.jumpToItem(idx);
                        });
                      }
                    : null,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark
                        ? CupertinoColors.white.withValues(alpha: 0.08)
                        : CupertinoColors.black.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? CupertinoColors.white.withValues(alpha: 0.16)
                          : CupertinoColors.black.withValues(alpha: 0.08),
                      width: 0.8,
                    ),
                  ),
                  child: Icon(
                    CupertinoIcons.chevron_left,
                    size: 16,
                    color: canGoBack
                        ? (isDark
                            ? CupertinoColors.white
                            : const Color(0xFF1C1C1E))
                        : CupertinoColors.inactiveGray,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark
                      ? CupertinoColors.white.withValues(alpha: 0.08)
                      : CupertinoColors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? CupertinoColors.white.withValues(alpha: 0.16)
                        : CupertinoColors.black.withValues(alpha: 0.08),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  '$_selectedYear',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color:
                        isDark ? CupertinoColors.white : const Color(0xFF1C1C1E),
                  ),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(36, 36),
                onPressed: canGoForward
                    ? () {
                        setState(() {
                          _selectedYear++;
                          final int idx = _years.indexOf(_selectedYear);
                          if (idx >= 0) _yearWheelController.jumpToItem(idx);
                        });
                      }
                    : null,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark
                        ? CupertinoColors.white.withValues(alpha: 0.08)
                        : CupertinoColors.black.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? CupertinoColors.white.withValues(alpha: 0.16)
                          : CupertinoColors.black.withValues(alpha: 0.08),
                      width: 0.8,
                    ),
                  ),
                  child: Icon(
                    CupertinoIcons.chevron_right,
                    size: 16,
                    color: canGoForward
                        ? (isDark
                            ? CupertinoColors.white
                            : const Color(0xFF1C1C1E))
                        : CupertinoColors.inactiveGray,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.1,
          children: List<Widget>.generate(12, (int i) {
            final int month = i + 1;
            final bool disabled = _isDateDisabled(_selectedYear, month);
            final bool selected = _selectedMonth == month;
            final bool isCurrentMonth =
                _selectedYear == now.year && month == now.month;

            return GestureDetector(
              onTap: disabled
                  ? null
                  : () {
                      setState(() {
                        _selectedMonth = month;
                        _monthWheelController.jumpToItem(month - 1);
                      });
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  gradient: selected
                      ? LinearGradient(
                          colors: <Color>[
                            primaryColor,
                            primaryColor.withValues(alpha: 0.85),
                          ],
                        )
                      : null,
                  color: selected
                      ? null
                      : (isDark
                          ? CupertinoColors.white.withValues(alpha: 0.06)
                          : CupertinoColors.black.withValues(alpha: 0.04)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? primaryColor
                        : (isCurrentMonth
                            ? primaryColor.withValues(alpha: 0.50)
                            : (isDark
                                ? CupertinoColors.white.withValues(alpha: 0.10)
                                : CupertinoColors.black.withValues(alpha: 0.06))),
                    width: selected || isCurrentMonth ? 1.4 : 0.8,
                  ),
                  boxShadow: selected
                      ? <BoxShadow>[
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  _monthNames[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w600,
                    color: disabled
                        ? (isDark
                            ? CupertinoColors.white.withValues(alpha: 0.22)
                            : CupertinoColors.black.withValues(alpha: 0.24))
                        : (selected
                            ? CupertinoColors.white
                            : (isDark
                                ? CupertinoColors.white
                                : const Color(0xFF1C1C1E))),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark =
        CupertinoTheme.of(context).brightness == Brightness.dark;
    final Color primaryColor = CupertinoTheme.of(context).primaryColor;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? <Color>[
                      const Color(0xF2121722),
                      const Color(0xFA0B0F17),
                    ]
                  : <Color>[
                      const Color(0xF7FFFFFF),
                      const Color(0xFCF2F5FB),
                    ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: isDark
                  ? CupertinoColors.white.withValues(alpha: 0.18)
                  : CupertinoColors.white.withValues(alpha: 0.85),
              width: 1.0,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: CupertinoColors.black
                    .withValues(alpha: isDark ? 0.60 : 0.18),
                blurRadius: 40,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark
                            ? CupertinoColors.white.withValues(alpha: 0.28)
                            : CupertinoColors.black.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Select Period',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                              color: isDark
                                  ? CupertinoColors.white
                                  : const Color(0xFF1C1C1E),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_monthNames[_selectedMonth - 1]} $_selectedYear',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(32, 32),
                        onPressed: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isDark
                                ? CupertinoColors.white.withValues(alpha: 0.12)
                                : CupertinoColors.black.withValues(alpha: 0.06),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? CupertinoColors.white.withValues(alpha: 0.20)
                                  : CupertinoColors.black.withValues(alpha: 0.08),
                              width: 0.8,
                            ),
                          ),
                          child: Icon(
                            CupertinoIcons.xmark,
                            size: 15,
                            color: isDark
                                ? CupertinoColors.white
                                : const Color(0xFF1C1C1E),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Ios27SegmentedControl(
                    segments: const <String>['Wheel Roller', 'Calendar Grid'],
                    selectedIndex: _segmentedIndex,
                    onSegmentSelected: (int idx) {
                      setState(() => _segmentedIndex = idx);
                    },
                  ),
                  const SizedBox(height: 16),
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 240),
                    firstCurve: Curves.easeOutCubic,
                    secondCurve: Curves.easeOutCubic,
                    crossFadeState: _segmentedIndex == 0
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    firstChild:
                        _buildWheelRoller(context, isDark, primaryColor),
                    secondChild:
                        _buildCalendarGrid(context, isDark, primaryColor),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: <Widget>[
                      if (widget.initialMonth != null) ...<Widget>[
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          minimumSize: const Size(0, 44),
                          onPressed: () {
                            widget.onSelected(null);
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            'Clear',
                            style: TextStyle(
                              color: Color(0xFFFF3B30),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 44),
                          onPressed: () {
                            final DateTime now = DateTime.now();
                            setState(() {
                              _selectedYear = now.year;
                              _selectedMonth = now.month;
                              final int idx = _years.indexOf(now.year);
                              if (idx >= 0) {
                                _yearWheelController.jumpToItem(idx);
                              }
                              _monthWheelController.jumpToItem(now.month - 1);
                            });
                          },
                          child: Container(
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? CupertinoColors.white.withValues(alpha: 0.08)
                                  : CupertinoColors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark
                                    ? CupertinoColors.white.withValues(alpha: 0.16)
                                    : CupertinoColors.black.withValues(alpha: 0.08),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              'This Month',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? CupertinoColors.white
                                    : const Color(0xFF1C1C1E),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Ios27Button(
                          label: 'Apply',
                          height: 44,
                          borderRadius: 14,
                          onPressed: () {
                            widget.onSelected(
                              DateTime(_selectedYear, _selectedMonth),
                            );
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

