import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mkx_core/constants/app_colors.dart';
import 'package:mkx_core/utils/date_utils.dart';
import 'package:mkx_core/utils/ui_helpers.dart';
import 'package:material_3_expressive/material_3_expressive.dart' as m3e;
import 'package:mkx_core/widgets/empty_state.dart';
import 'package:mkx_core/widgets/mkx_app_bar.dart';
import 'package:mkx_core/widgets/section_tile.dart';
import 'package:mkx_core/widgets/status_badge.dart';
import 'package:mkx_core/features/auth/state/auth_provider.dart';
import '../models/leave_model.dart';
import '../state/leaves_provider.dart';
import '../widgets/apply_leave_bottom_sheet.dart';

/// Leaves overview, balance cards, and application history screen
class LeavesScreen extends StatefulWidget {
  const LeavesScreen({super.key});

  @override
  State<LeavesScreen> createState() => _LeavesScreenState();
}

class _LeavesScreenState extends State<LeavesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    final leaves = context.read<LeavesProvider>();
    await leaves.loadLeaves(
      employeeId: auth.currentUser?.employeeDbId,
      employeeCode: auth.currentUser?.employeeId,
    );
  }

  void _openApplyModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ApplyLeaveBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = m3e.M3ETheme.of(context).brightness == Brightness.dark;
    final leaves = context.watch<LeavesProvider>();

    return Scaffold(
      appBar: MkxAppBar(
        title: 'Leaves',
        subtitle: 'Track balances and submit time off',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: m3e.M3EButton(
              style: m3e.M3EButtonStyle.outlined,
              size: m3e.M3EButtonSize.sm,
              onPressed: _openApplyModal,
              child: const Row(
                children: [
                  Icon(Icons.add_rounded, size: 16),
                  SizedBox(width: 4),
                  Text('Apply'),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDynamicQuotaCards(context, leaves),
                const SizedBox(height: 10),

                /// Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Pending', 'Approved', 'Rejected'].map((
                      filter,
                    ) {
                      final isSelected = leaves.selectedFilter == filter;

                      final Map<String, IconData> tabIcons = {
                        'All': Icons.layers_outlined,
                        'Pending': Icons.pending_actions_rounded,
                        'Approved': Icons.check_circle_outline_rounded,
                        'Rejected': Icons.cancel_outlined,
                      };
                      final icon =
                          tabIcons[filter] ?? Icons.label_outline_rounded;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: m3e.M3EChip(
                          label: filter,
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
                                : (isDark
                                    ? AppColors.darkMuted
                                    : AppColors.lightMuted),
                          ),
                          onPressed: () => leaves.setFilter(filter),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 10),

                /// History List
                if (leaves.isLoading && leaves.history.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: SizedBox(
                          width: 48,
                          height: 48,
                          child: m3e.M3EProgressIndicator.circularWavy(
                              strokeWidth: 3)),
                    ),
                  )
                else if (leaves.filteredHistory.isEmpty)
                  EmptyState(
                    icon: Icons.event_available_outlined,
                    title: 'No leave applications found',
                    description:
                        'Tap the "+ Apply" button above to submit your first leave application.',
                    action: m3e.M3EButton(
                      style: m3e.M3EButtonStyle.filled,
                      size: m3e.M3EButtonSize.md,
                      onPressed: _openApplyModal,
                      child: const Text('Apply for Leave'),
                    ),
                  )
                else
                  SectionCard(
                    isDark: isDark,
                    children: leaves.filteredHistory.map((item) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: item.status == 'Approved'
                                          ? AppColors.success
                                          : (item.status == 'Pending'
                                              ? AppColors.warning
                                              : AppColors.error),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    item.leaveType,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              StatusBadge(status: item.status),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSecondary
                                  : AppColors.lightSecondary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.date_range_rounded,
                                      size: 14,
                                      color: isDark
                                          ? AppColors.darkMuted
                                          : AppColors.lightMuted,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${AppDateUtils.formatDate(item.startDate)} - ${AppDateUtils.formatDate(item.endDate)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${item.daysCount} ${item.daysCount == 1 ? "day" : "days"}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppColors.darkForeground
                                        : AppColors.lightForeground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            item.reason,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.darkMuted
                                  : AppColors.lightMuted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item.leaveCode,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.darkMuted
                                      : AppColors.lightMuted,
                                ),
                              ),
                              Text(
                                'Applied: ${AppDateUtils.formatDate(item.appliedOn)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.darkMuted
                                      : AppColors.lightMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicQuotaCards(BuildContext context, LeavesProvider leaves) {
    final isDark = m3e.M3ETheme.of(context).brightness == Brightness.dark;
    final quotas = leaves.balances?.list ?? [];
    final displayQuotas = quotas.isNotEmpty
        ? quotas
        : (leaves.masterLeaveTypes.isNotEmpty
            ? leaves.masterLeaveTypes
                .map(
                  (type) => LeaveQuota(
                    id: type.id,
                    name: type.name,
                    code: type.code,
                    total: type.daysPerYear,
                    used: 0,
                    remaining: type.daysPerYear,
                    color: type.color,
                    isPaid: type.isPaid,
                  ),
                )
                .toList()
            : <LeaveQuota>[]);

    if (displayQuotas.isEmpty) {
      return const SizedBox.shrink();
    }

    return SectionCard(
      isDark: isDark,
      children: displayQuotas.asMap().entries.map((entry) {
        final index = entry.key;
        final quota = entry.value;
        final color = UiHelpers.parseHexColor(
          quota.color,
          defaultColor: index % 3 == 0
              ? AppColors.info
              : (index % 3 == 1 ? AppColors.success : AppColors.warning),
        );
        final progress =
            quota.total > 0 ? (quota.used / quota.total).clamp(0.0, 1.0) : 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      quota.name ?? 'Leave',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (quota.code != null && quota.code!.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          quota.code!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  '${quota.remaining} days left',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor:
                    isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${quota.used} used of ${quota.total} total',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                  ),
                ),
                Text(
                  quota.isPaid == false ? 'Unpaid' : 'Paid Leave',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                  ),
                ),
              ],
            ),
          ],
        );
      }).toList(),
    );
  }
}
