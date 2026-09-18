import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mkx_core/constants/app_colors.dart';
import 'package:mkx_core/utils/ui_helpers.dart';
import 'package:mkx_core/widgets/app_text.dart';
import 'package:mkx_core/widgets/empty_state.dart';
import 'package:mkx_core/widgets/status_badge.dart';
import '../models/hr_leave_model.dart';
import '../state/hr_leaves_provider.dart';

/// HR Leave Management — Pending/Approved/Rejected/All tabbed view with approve/reject
class HrLeavesScreen extends StatefulWidget {
  const HrLeavesScreen({super.key});

  @override
  State<HrLeavesScreen> createState() => _HrLeavesScreenState();
}

class _HrLeavesScreenState extends State<HrLeavesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  static const List<String> _tabs = ['Pending', 'Approved', 'Rejected', 'All'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        context.read<HrLeavesProvider>().setStatusFilter(
          _tabs[_tabController.index],
        );
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HrLeavesProvider>().loadLeaves(status: 'Pending');
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: AppText.heading('Leave Requests'),
            ),
            Container(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
                labelColor: isDark
                    ? AppColors.darkForeground
                    : AppColors.lightForeground,
                unselectedLabelColor: isDark
                    ? AppColors.darkMuted
                    : AppColors.lightMuted,
                indicatorColor: AppColors.info,
                indicatorWeight: 2,
                tabs: _tabs.map((t) => Tab(text: t)).toList(),
              ),
            ),
            Expanded(
              child: Consumer<HrLeavesProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.leaves.isEmpty) {
                    return EmptyState(
                      icon: Icons.event_note_outlined,
                      title: 'No ${provider.statusFilter} leaves',
                      description: 'All leave requests will appear here',
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => provider.loadLeaves(),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      itemCount: provider.leaves.length,
                      itemBuilder: (context, i) {
                        return _LeaveCard(
                          leave: provider.leaves[i],
                          isDark: isDark,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaveCard extends StatelessWidget {
  final HrLeaveModel leave;
  final bool isDark;

  const _LeaveCard({required this.leave, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<HrLeavesProvider>();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.info.withValues(alpha: 0.1),
                  child: AppText(
                    leave.employeeName.isNotEmpty
                        ? leave.employeeName[0].toUpperCase()
                        : '?',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.bodyBold(leave.employeeName),
                      AppText.caption(
                        '${leave.employeeCode} • ${leave.department ?? ''}',
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: leave.status),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSecondary
                    : AppColors.lightSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _DetailRow(
                    label: 'Type',
                    value: leave.leaveType,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 6),
                  _DetailRow(
                    label: 'Duration',
                    value:
                        '${leave.startDate} → ${leave.endDate} (${leave.totalDays}d)',
                    isDark: isDark,
                  ),
                  if (leave.reason.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _DetailRow(
                      label: 'Reason',
                      value: leave.reason,
                      isDark: isDark,
                    ),
                  ],
                ],
              ),
            ),
            if (leave.status.toLowerCase() == 'pending') ...[
              const SizedBox(height: 12),
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
                  const SizedBox(width: 10),
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
        ),
      ),
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 58, child: AppText.caption(label)),
        Expanded(
          child: AppText(value, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
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
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            AppText(
              label,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}
