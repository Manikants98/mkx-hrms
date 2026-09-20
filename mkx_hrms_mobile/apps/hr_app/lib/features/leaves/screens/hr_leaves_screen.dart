import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart' as m3e;
import 'package:provider/provider.dart';
import 'package:mkx_core/constants/app_colors.dart';
import 'package:mkx_core/utils/ui_helpers.dart';
import 'package:mkx_core/widgets/app_avatar.dart';
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
  static const List<String> _tabs = ['All', 'Pending', 'Approved', 'Rejected'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HrLeavesProvider>().loadLeaves();
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
                      child: SizedBox(width: 52, height: 52, child: CircularProgressIndicator(strokeWidth: 3)),
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
    final Map<String, IconData> tabIcons = {
      'All': Icons.layers_outlined,
      'Pending': Icons.pending_actions_rounded,
      'Approved': Icons.check_circle_outline_rounded,
      'Rejected': Icons.cancel_outlined,
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _tabs.map((tab) {
          final isSelected = provider.statusFilter == tab;
          final icon = tabIcons[tab] ?? Icons.label_outline_rounded;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: m3e.M3EChip(
              label: tab,
              type: m3e.M3EChipType.filter,
              selected: isSelected,
              elevated: isSelected,
              leading: Icon(
                icon,
                size: 14,
                color: isSelected
                    ? (isDark
                        ? AppColors.darkPrimaryForeground
                        : AppColors.lightPrimaryForeground)
                    : (isDark ? AppColors.darkMuted : AppColors.lightMuted),
              ),
              onPressed: () => provider.setStatusFilter(tab),
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
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppAvatar(name: leave.employeeName, size: 36, borderRadius: 8),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    leave.employeeName,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    [
                      if (leave.role != null && leave.role!.isNotEmpty)
                        leave.role,
                      if (leave.department != null &&
                          leave.department!.isNotEmpty)
                        leave.department,
                    ].join(' • '),
                    style: TextStyle(fontSize: 11.5, color: mutedColor),
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
              _buildRow('Leave Type', leave.leaveType, isDark),
              const SizedBox(height: 4),
              _buildRow(
                'Schedule',
                '${leave.startDate} → ${leave.endDate} (${leave.totalDays}d)',
                isDark,
              ),
              if (leave.reason.isNotEmpty) ...[
                const SizedBox(height: 4),
                _buildRow('Reason', leave.reason, isDark),
              ],
            ],
          ),
        ),
        if (leave.status.toLowerCase() == 'pending') ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: m3e.M3EButton(
                  style: m3e.M3EButtonStyle.outlined,
                  size: m3e.M3EButtonSize.sm,
                  onPressed: () => _handleReject(context, provider, leave.id),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.close_rounded, size: 16, color: AppColors.error),
                      const SizedBox(width: 6),
                      Text(
                        'Reject',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: m3e.M3EButton(
                  style: m3e.M3EButtonStyle.filled,
                  size: m3e.M3EButtonSize.sm,
                  onPressed: () => _handleApprove(context, provider, leave.id),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        'Approve',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
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
            style: TextStyle(fontSize: 12, color: mutedColor),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
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
