import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:mkx_core/constants/app_colors.dart';
import 'package:mkx_core/widgets/app_text.dart';
import 'package:mkx_core/widgets/empty_state.dart';
import 'package:mkx_core/widgets/status_badge.dart';
import '../models/hr_attendance_model.dart';
import '../state/hr_attendance_provider.dart';

/// HR Attendance Management — date-filtered all-employee attendance table
class HrAttendanceScreen extends StatefulWidget {
  const HrAttendanceScreen({super.key});

  @override
  State<HrAttendanceScreen> createState() => _HrAttendanceScreenState();
}

class _HrAttendanceScreenState extends State<HrAttendanceScreen> {
  static const List<String> _statusFilters = [
    'All',
    'Present',
    'Absent',
    'Late',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HrAttendanceProvider>().loadAttendance();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isDark),
            _buildSummaryRow(isDark),
            _buildFilters(isDark),
            Expanded(child: _buildList(isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Consumer<HrAttendanceProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppText.heading('Attendance'),
                    AppText.muted(
                      DateFormat(
                        'EEEE, d MMMM yyyy',
                      ).format(provider.selectedDate),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => _pickDate(context, provider),
                icon: const Icon(Icons.calendar_today_rounded, size: 16),
                label: const AppText.label('Change'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(bool isDark) {
    return Consumer<HrAttendanceProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              _SummaryChip(
                label: 'Present',
                count: provider.presentCount,
                color: AppColors.success,
              ),
              const SizedBox(width: 8),
              _SummaryChip(
                label: 'Absent',
                count: provider.absentCount,
                color: AppColors.error,
              ),
              const SizedBox(width: 8),
              _SummaryChip(
                label: 'Late',
                count: provider.lateCount,
                color: AppColors.warning,
              ),
              const SizedBox(width: 8),
              _SummaryChip(
                label: 'Total',
                count: provider.records.length,
                color: AppColors.info,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilters(bool isDark) {
    return Consumer<HrAttendanceProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: _statusFilters.map((s) {
              final selected =
                  provider.statusFilter == s ||
                  (s == 'All' && provider.statusFilter.isEmpty);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _StatusFilterChip(
                  label: s,
                  selected: selected,
                  isDark: isDark,
                  onTap: () => provider.setStatusFilter(s == 'All' ? '' : s),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildList(bool isDark) {
    return Consumer<HrAttendanceProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.records.isEmpty) {
          return const EmptyState(
            icon: Icons.today_outlined,
            title: 'No records found',
            description: 'No attendance data for this date',
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadAttendance(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: provider.records.length,
            itemBuilder: (context, i) {
              return _AttendanceTile(
                record: provider.records[i],
                isDark: isDark,
              );
            },
          ),
        );
      },
    );
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
}

class _AttendanceTile extends StatelessWidget {
  final HrAttendanceModel record;
  final bool isDark;

  const _AttendanceTile({required this.record, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.info.withValues(alpha: 0.1),
            child: AppText(
              record.employeeName.isNotEmpty
                  ? record.employeeName[0].toUpperCase()
                  : '?',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.info,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bodyBold(record.employeeName),
                const SizedBox(height: 2),
                AppText.caption(
                  '${record.employeeCode}${record.department != null ? ' • ${record.department}' : ''}',
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _TimeChip(
                      label: 'In',
                      time: record.checkIn ?? '—',
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _TimeChip(
                      label: 'Out',
                      time: record.checkOut ?? '—',
                      isDark: isDark,
                    ),
                    if (record.duration != null) ...[
                      const SizedBox(width: 8),
                      AppText.caption(record.duration!),
                    ],
                  ],
                ),
              ],
            ),
          ),
          StatusBadge(status: record.status),
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String label;
  final String time;
  final bool isDark;

  const _TimeChip({
    required this.label,
    required this.time,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: AppText(
        '$label: $time',
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: AppText(
        '$label: $count',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _StatusFilterChip({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.info
              : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.info
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: AppText.label(
          label,
          color: selected
              ? Colors.white
              : (isDark ? AppColors.darkMuted : AppColors.lightMuted),
        ),
      ),
    );
  }
}
