import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:mkx_core/constants/app_colors.dart';
import 'package:mkx_core/widgets/empty_state.dart';
import 'package:mkx_core/widgets/mkx_app_bar.dart';
import 'package:mkx_core/widgets/section_tile.dart';
import 'package:mkx_core/widgets/status_badge.dart';
import '../models/hr_attendance_model.dart';
import '../state/hr_attendance_provider.dart';

/// HR Attendance Management — matches employee_app structure and UI patterns
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<HrAttendanceProvider>();

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: MkxAppBar(
        title: 'Attendance',
        subtitle: DateFormat('EEEE, d MMMM yyyy').format(provider.selectedDate),
        actions: [
          IconButton(
            icon: Icon(
              Icons.calendar_today_rounded,
              size: 19,
              color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
            ),
            tooltip: 'Select Date',
            onPressed: () => _pickDate(context, provider),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () => provider.loadAttendance(),
          color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryRow(isDark, provider),
                const SizedBox(height: 10),
                _buildFilters(isDark, provider),
                const SizedBox(height: 10),
                if (provider.isLoading && provider.records.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (provider.records.isEmpty)
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
    return SectionTile(
      isDark: isDark,
      position: TilePosition.only,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatCol('Present', provider.presentCount, AppColors.success),
          _buildStatCol('Absent', provider.absentCount, AppColors.error),
          _buildStatCol('Late', provider.lateCount, AppColors.warning),
          _buildStatCol(
            'Total',
            provider.records.length,
            Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCol(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildFilters(bool isDark, HrAttendanceProvider provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _statusFilters.map((s) {
          final isSelected =
              provider.statusFilter == s ||
              (s == 'All' && provider.statusFilter.isEmpty);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                s,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? (isDark
                            ? AppColors.darkPrimaryForeground
                            : AppColors.lightPrimaryForeground)
                      : (isDark ? AppColors.darkMuted : AppColors.lightMuted),
                ),
              ),
              selected: isSelected,
              onSelected: (_) => provider.setStatusFilter(s == 'All' ? '' : s),
              backgroundColor: isDark
                  ? AppColors.darkSecondary
                  : AppColors.lightSecondary,
              selectedColor: isDark
                  ? AppColors.darkPrimary
                  : AppColors.lightPrimary,
              showCheckmark: false,
              side: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            ),
          );
        }).toList(),
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
    final primaryColor = Theme.of(context).colorScheme.primary;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: primaryColor.withValues(alpha: 0.12),
            child: Text(
              record.employeeName.isNotEmpty
                  ? record.employeeName[0].toUpperCase()
                  : '?',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.employeeName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${record.employeeCode}${record.department != null ? ' • ${record.department}' : ''}',
                  style: GoogleFonts.inter(fontSize: 12, color: mutedColor),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'In: ${record.checkIn ?? "—"}',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: mutedColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Out: ${record.checkOut ?? "—"}',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: mutedColor,
                      ),
                    ),
                    if (record.duration != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '(${record.duration})',
                        style: GoogleFonts.inter(
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
