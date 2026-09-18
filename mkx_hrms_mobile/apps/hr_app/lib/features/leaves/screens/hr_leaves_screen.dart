import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:mkx_core/constants/app_colors.dart';
import 'package:mkx_core/utils/ui_helpers.dart';
import 'package:mkx_core/widgets/empty_state.dart';
import 'package:mkx_core/widgets/mkx_app_bar.dart';
import 'package:mkx_core/widgets/section_tile.dart';
import 'package:mkx_core/widgets/status_badge.dart';
import '../models/hr_leave_model.dart';
import '../state/hr_leaves_provider.dart';

/// HR Leave Management — matches employee_app structure and UI patterns
class HrLeavesScreen extends StatefulWidget {
  const HrLeavesScreen({super.key});

  @override
  State<HrLeavesScreen> createState() => _HrLeavesScreenState();
}

class _HrLeavesScreenState extends State<HrLeavesScreen> {
  static const List<String> _tabs = ['Pending', 'Approved', 'Rejected', 'All'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HrLeavesProvider>().loadLeaves(status: 'Pending');
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<HrLeavesProvider>();

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: const MkxAppBar(
        title: 'Leave Requests',
        subtitle: 'Review and approve workforce time off',
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () => provider.loadLeaves(),
          color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusFilters(isDark, provider),
                const SizedBox(height: 10),
                if (provider.isLoading && provider.leaves.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (provider.leaves.isEmpty)
                  EmptyState(
                    icon: Icons.event_note_outlined,
                    title: 'No ${provider.statusFilter} leave requests',
                    description: 'All employee leave requests will appear here',
                  )
                else
                  SectionCard(
                    isDark: isDark,
                    children: provider.leaves.map((leave) {
                      return _LeaveTile(leave: leave, isDark: isDark);
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

  Widget _buildStatusFilters(bool isDark, HrLeavesProvider provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _tabs.map((tab) {
          final isSelected = provider.statusFilter == tab;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                tab,
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
              onSelected: (_) => provider.setStatusFilter(tab),
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

class _LeaveTile extends StatelessWidget {
  final HrLeaveModel leave;
  final bool isDark;

  const _LeaveTile({required this.leave, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<HrLeavesProvider>();
    final primaryColor = Theme.of(context).colorScheme.primary;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: primaryColor.withValues(alpha: 0.12),
              child: Text(
                leave.employeeName.isNotEmpty
                    ? leave.employeeName[0].toUpperCase()
                    : '?',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    leave.employeeName,
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    '${leave.employeeCode} • ${leave.department ?? "General"}',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: mutedColor,
                    ),
                  ),
                ],
              ),
            ),
            StatusBadge(status: leave.status),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              _buildRow(
                'Leave Type',
                leave.leaveType,
                isDark,
              ),
              const SizedBox(height: 4),
              _buildRow(
                'Schedule',
                '${leave.startDate} → ${leave.endDate} (${leave.totalDays}d)',
                isDark,
              ),
              if (leave.reason.isNotEmpty) ...[
                const SizedBox(height: 4),
                _buildRow(
                  'Reason',
                  leave.reason,
                  isDark,
                ),
              ],
            ],
          ),
        ),
        if (leave.status.toLowerCase() == 'pending') ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Reject',
                  color: AppColors.error,
                  icon: Icons.close_rounded,
                  onTap: () => _handleReject(context, provider, leave.id),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  label: 'Approve',
                  color: AppColors.success,
                  icon: Icons.check_rounded,
                  onTap: () => _handleApprove(context, provider, leave.id),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildRow(String label, String value, bool isDark) {
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: mutedColor,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleApprove(
    BuildContext context,
    HrLeavesProvider provider,
    int leaveId,
  ) async {
    final confirmed = await UiHelpers.showConfirmDialog(
      context: context,
      title: 'Approve Leave',
      message:
          "Are you sure you want to approve ${leave.employeeName}'s leave request?",
      confirmText: 'Approve',
    );
    if (confirmed == true && context.mounted) {
      final ok = await provider.approveLeave(leaveId);
      if (context.mounted) {
        UiHelpers.showSnackBar(
          context,
          ok
              ? 'Leave approved successfully'
              : (provider.errorMessage ?? 'Failed'),
          isSuccess: ok,
          isError: !ok,
        );
      }
    }
  }

  Future<void> _handleReject(
    BuildContext context,
    HrLeavesProvider provider,
    int leaveId,
  ) async {
    final confirmed = await UiHelpers.showConfirmDialog(
      context: context,
      title: 'Reject Leave',
      message:
          "Are you sure you want to reject ${leave.employeeName}'s leave request?",
      confirmText: 'Reject',
      isDestructive: true,
    );
    if (confirmed == true && context.mounted) {
      final ok = await provider.rejectLeave(leaveId);
      if (context.mounted) {
        UiHelpers.showSnackBar(
          context,
          ok ? 'Leave rejected' : (provider.errorMessage ?? 'Failed'),
          isSuccess: ok,
          isError: !ok,
        );
      }
    }
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
