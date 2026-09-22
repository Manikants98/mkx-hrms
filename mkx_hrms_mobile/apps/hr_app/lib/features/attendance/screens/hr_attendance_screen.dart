import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:mkx_core/constants/app_colors.dart';
import 'package:mkx_core/widgets/app_avatar.dart';
import 'package:mkx_core/widgets/empty_state.dart';
import 'package:mkx_core/widgets/mkx_app_bar.dart';
import 'package:mkx_core/widgets/section_tile.dart';
import 'package:mkx_core/widgets/status_badge.dart';
import 'package:provider/provider.dart';

import '../models/hr_attendance_model.dart';
import '../state/hr_attendance_provider.dart';

/// HR Attendance Management — matches employee_app structure and UI patterns
class HrAttendanceScreen extends StatefulWidget {
  const HrAttendanceScreen({super.key});

  @override
  State<HrAttendanceScreen> createState() => _HrAttendanceScreenState();
}

class _HrAttendanceScreenState extends State<HrAttendanceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HrAttendanceProvider>().loadAttendance();
    });
  }

  Future<void> _pickDate(
    BuildContext context,
    HrAttendanceProvider provider,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: provider.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      provider.setDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = M3ETheme.of(context).brightness == Brightness.dark;
    final provider = context.watch<HrAttendanceProvider>();
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainer,
      appBar: MkxAppBar(
        title: 'Attendance',
        subtitle: DateFormat('EEEE, d MMMM yyyy').format(provider.selectedDate),
      ),
      body: SafeArea(
        top: false,
        child: M3ERefreshIndicator.contained(
          onRefresh: () async {
            await context.read<HrAttendanceProvider>().loadAttendance();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryRow(isDark, provider),
                _buildDateFilters(isDark, provider),
                if (provider.records.isEmpty)
                  const EmptyState(
                    icon: Icons.today_outlined,
                    title: 'No attendance records',
                    description:
                        'No workforce punch data recorded for this date',
                  )
                else
                  SectionCard(
                    isDark: isDark,
                    children: provider.records.map((rec) {
                      return _AttendanceRow(record: rec, isDark: isDark);
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

  Widget _buildSummaryRow(bool isDark, HrAttendanceProvider provider) {
    return M3ECard(
      variant: M3ECardVariant.filled,
      borderRadius: BorderRadius.circular(16),
      color: M3ETheme.of(context).colorScheme.surfaceContainerLowest,
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: _buildStatCol(
                  'Total',
                  provider.records.length,
                  Colors.blue,
                ),
              ),
            ),
            Container(
              width: 4,
              color: M3ETheme.of(context).colorScheme.surfaceContainer,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: _buildStatCol(
                    'Present', provider.presentCount, Colors.green),
              ),
            ),
            Container(
              width: 4,
              color: M3ETheme.of(context).colorScheme.surfaceContainer,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: _buildStatCol('Late', provider.lateCount, Colors.orange),
              ),
            ),
            Container(
              width: 4,
              color: M3ETheme.of(context).colorScheme.surfaceContainer,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: _buildStatCol(
                    'Absent', provider.absentCount, AppColors.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCol(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildDateFilters(bool isDark, HrAttendanceProvider provider) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dates = List.generate(
      7,
      (index) => today.subtract(Duration(days: index)),
    );

    // Check if current selected date is in our quick list
    final isCustomDate = !dates.any(
      (d) =>
          d.year == provider.selectedDate.year &&
          d.month == provider.selectedDate.month &&
          d.day == provider.selectedDate.day,
    );

    int? selectedIndex;
    if (isCustomDate) {
      selectedIndex = dates.length;
    } else {
      for (int i = 0; i < dates.length; i++) {
        if (provider.selectedDate.year == dates[i].year &&
            provider.selectedDate.month == dates[i].month &&
            provider.selectedDate.day == dates[i].day) {
          selectedIndex = i;
          break;
        }
      }
    }

    final actions = <M3EButtonGroupAction>[];
    for (final date in dates) {
      String label;
      final diff = today.difference(date).inDays;
      if (diff == 0) {
        label = 'Today';
      } else if (diff == 1) {
        label = 'Yesterday';
      } else {
        label = DateFormat('MMM d').format(date);
      }
      actions.add(M3EButtonGroupAction(
        label: Text(label),
      ));
    }

    actions.add(M3EButtonGroupAction(
      label: Text(isCustomDate
          ? DateFormat('MMM d').format(provider.selectedDate)
          : 'Custom'),
      icon: const Icon(Icons.calendar_today_rounded, size: 14),
    ));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: M3EButtonGroup(
        type: M3EButtonGroupType.connected,
        shape: M3EButtonShape.square,
        size: M3EButtonSize.xs,
        style: M3EButtonStyle.filled,
        neighborSquish: true,
        decoration: M3EToggleButtonDecoration(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return M3ETheme.of(context).colorScheme.primary;
            }
            return M3ETheme.of(context).colorScheme.surfaceContainerLowest;
          }),
        ),
        selectedIndex: selectedIndex,
        onSelectedIndexChanged: (int? index) {
          if (index == null) return;
          if (index == dates.length) {
            _pickDate(context, provider);
          } else {
            provider.setDate(dates[index]);
          }
        },
        actions: actions,
      ),
    );
  }
}

class _AttendanceRow extends StatelessWidget {
  final HrAttendanceModel record;
  final bool isDark;

  const _AttendanceRow({required this.record, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final primaryColor = M3ETheme.of(context).colorScheme.primary;
    final mutedColor = M3ETheme.of(context).colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppAvatar(name: record.employeeName, size: 40, borderRadius: 8),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.employeeName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (record.role != null && record.role!.isNotEmpty)
                      record.role,
                    if (record.department != null &&
                        record.department!.isNotEmpty)
                      record.department,
                  ].join(' • '),
                  style: TextStyle(fontSize: 12, color: mutedColor),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'In: ${record.checkIn ?? "—"}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: mutedColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Out: ${record.checkOut ?? "—"}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: mutedColor,
                      ),
                    ),
                    if (record.duration != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '(${record.duration})',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusBadge(status: record.status),
        ],
      ),
    );
  }
}
