import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:mkx_core/constants/app_colors.dart';
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

  static const List<String> _filters = [
    'All',
    'Present',
    'Late',
    'Absent',
  ];

  List<AttendanceRecord> _applyFilter(List<AttendanceRecord> history) {
    if (_selectedFilterIndex == 0) return history;
    final label = _filters[_selectedFilterIndex].toLowerCase();
    return history.where((item) => item.status.toLowerCase() == label).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = M3ETheme.of(context).brightness == Brightness.dark;
    final colorScheme = M3ETheme.of(context).colorScheme;
    final attendance = context.watch<AttendanceProvider>();
    final filtered = _applyFilter(attendance.history);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
      appBar: const MkxAppBar(
        title: 'Attendance History',
        subtitle: 'All your past punch records',
      ),
      body: SafeArea(
        top: false,
        child: M3ERefreshIndicator.contained(
          onRefresh: () async {
            await context.read<AttendanceProvider>().loadAttendance();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: M3EButtonGroup(
                    type: M3EButtonGroupType.connected,
                    shape: M3EButtonShape.square,
                    size: M3EButtonSize.xs,
                    style: M3EButtonStyle.filled,
                    neighborSquish: true,
                    decoration: M3EToggleButtonDecoration(
                      backgroundColor:
                          WidgetStateProperty.resolveWith((states) {
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
                const SizedBox(height: 10),
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
                    icon: Icons.history_outlined,
                    title: 'No records found',
                    description:
                        'No attendance records match the selected filter.',
                  )
                else
                  SectionCard(
                    isDark: isDark,
                    children: filtered.map((item) {
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
                    }).toList(),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
