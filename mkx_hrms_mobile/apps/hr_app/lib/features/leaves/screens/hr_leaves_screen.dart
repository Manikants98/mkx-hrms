import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:provider/provider.dart';
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
    final isDark = M3ETheme.of(context).brightness == Brightness.dark;
    final provider = context.watch<HrLeavesProvider>();
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainer,
      appBar: const MkxAppBar(
        title: 'Leave Requests',
        subtitle: 'Review and approve workforce time off',
      ),
      body: SafeArea(
        top: false,
        child: M3ERefreshIndicator.contained(
          onRefresh: () => provider.loadLeaves(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusFilters(isDark, provider),
                if (provider.isLoading && provider.leaves.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: SizedBox(
                          width: 52,
                          height: 52,
                          child: M3EProgressIndicator.circularWavy()),
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
        selectedIndex: _tabs.indexOf(provider.statusFilter),
        onSelectedIndexChanged: (int? index) {
          if (index != null && index >= 0 && index < _tabs.length) {
            provider.setStatusFilter(_tabs[index]);
          }
        },
        actions: _tabs.map((tab) {
          final icon = tabIcons[tab] ?? Icons.label_outline_rounded;
          return M3EButtonGroupAction(
            label: Text(tab),
            icon: Icon(icon, size: 14),
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
    final scheme = M3ETheme.of(context).colorScheme;
    final mutedColor = scheme.onSurfaceVariant;

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
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              _buildRow(context, 'Leave Type', leave.leaveType),
              const SizedBox(height: 4),
              _buildRow(
                context,
                'Schedule',
                '${leave.startDate} → ${leave.endDate} (${leave.totalDays}d)',
              ),
              if (leave.reason.isNotEmpty) ...[
                const SizedBox(height: 4),
                _buildRow(context, 'Reason', leave.reason),
              ],
            ],
          ),
        ),
        if (leave.status.toLowerCase() == 'pending') ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: M3EButton(
                  style: M3EButtonStyle.outlined,
                  size: M3EButtonSize.xs,
                  decoration: M3EButtonDecoration(
                    side:
                        WidgetStateProperty.all(BorderSide(color: Colors.red)),
                  ),
                  onPressed: () => _handleReject(context, provider, leave),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.close_rounded, size: 16, color: Colors.red),
                      const SizedBox(width: 6),
                      Text(
                        'Reject',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: M3EButton(
                  style: M3EButtonStyle.filled,
                  size: M3EButtonSize.xs,
                  decoration: M3EButtonDecoration(
                    backgroundColor: WidgetStateProperty.all(Colors.green),
                    foregroundColor: WidgetStateProperty.all(Colors.white),
                  ),
                  onPressed: () => _handleApprove(context, provider, leave),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_rounded,
                          size: 16, color: Colors.white),
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

  Widget _buildRow(BuildContext context, String label, String value) {
    final mutedColor = M3ETheme.of(context).colorScheme.onSurfaceVariant;
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
    HrLeaveModel leave,
  ) async {
    final confirmed = await UiHelpers.showConfirmDialog(
      context: context,
      title: 'Approve Leave',
      message:
          "Are you sure you want to approve ${leave.employeeName}'s leave request?",
      confirmText: 'Approve',
    );
    if (confirmed == true && context.mounted) {
      final ok = await provider.approveLeave(leave.id);
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
    HrLeaveModel leave,
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
      final ok = await provider.rejectLeave(leave.id);
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
