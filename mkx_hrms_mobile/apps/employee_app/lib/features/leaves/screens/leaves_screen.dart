import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:mkx_core/constants/app_colors.dart';
import 'package:mkx_core/features/auth/state/auth_provider.dart';
import 'package:mkx_core/utils/date_utils.dart';
import 'package:mkx_core/utils/ui_helpers.dart';
import 'package:mkx_core/widgets/empty_state.dart';
import 'package:mkx_core/widgets/mkx_app_bar.dart';
import 'package:mkx_core/widgets/section_tile.dart';
import 'package:mkx_core/widgets/status_badge.dart';
import 'package:provider/provider.dart';

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
    final isDark = M3ETheme.of(context).brightness == Brightness.dark;
    final leaves = context.watch<LeavesProvider>();

    return Scaffold(
      backgroundColor: M3ETheme.of(context).colorScheme.surfaceContainer,
      appBar: MkxAppBar(
        title: 'Leaves',
        subtitle: 'Track balances and submit time off',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: M3EButton(
              style: M3EButtonStyle.outlined,
              size: M3EButtonSize.sm,
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
      body: M3ERefreshIndicator.contained(
        onRefresh: _loadData,
        color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDynamicQuotaCards(context, leaves),

              /// Status Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Builder(builder: (context) {
                  final filters = ['All', 'Pending', 'Approved', 'Rejected'];
                  return M3EButtonGroup(
                    type: M3EButtonGroupType.connected,
                    shape: M3EButtonShape.square,
                    size: M3EButtonSize.xs,
                    style: M3EButtonStyle.filled,
                    neighborSquish: true,
                    decoration: M3EToggleButtonDecoration(
                      backgroundColor:
                          WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return M3ETheme.of(context).colorScheme.primary;
                        }
                        return M3ETheme.of(context)
                            .colorScheme
                            .surfaceContainerLowest;
                      }),
                    ),
                    selectedIndex: filters.indexOf(leaves.selectedFilter),
                    onSelectedIndexChanged: (int? index) {
                      if (index != null &&
                          index >= 0 &&
                          index < filters.length) {
                        leaves.setFilter(filters[index]);
                      }
                    },
                    actions: filters.map((filter) {
                      final Map<String, IconData> tabIcons = {
                        'All': Icons.layers_outlined,
                        'Pending': Icons.pending_actions_rounded,
                        'Approved': Icons.check_circle_outline_rounded,
                        'Rejected': Icons.cancel_outlined,
                      };
                      return M3EButtonGroupAction(
                        label: Text(filter),
                        icon: Icon(
                            tabIcons[filter] ?? Icons.label_outline_rounded,
                            size: 14),
                      );
                    }).toList(),
                  );
                }),
              ),

              /// History List
              if (leaves.isLoading && leaves.history.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: SizedBox(
                        width: 48,
                        height: 48,
                        child:
                            M3EProgressIndicator.circularWavy(strokeWidth: 3)),
                  ),
                )
              else if (leaves.filteredHistory.isEmpty)
                EmptyState(
                  icon: Icons.event_available_outlined,
                  title: 'No leave applications found',
                  description:
                      'Tap the "+ Apply" button above to submit your first leave application.',
                  action: M3EButton(
                    style: M3EButtonStyle.filled,
                    size: M3EButtonSize.md,
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
                            color: M3ETheme.of(context)
                                .colorScheme
                                .surfaceContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                            ],
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
    );
  }

  Widget _buildDynamicQuotaCards(BuildContext context, LeavesProvider leaves) {
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

    return M3ECard(
      variant: M3ECardVariant.filled,
      borderRadius: BorderRadius.circular(16),
      color: M3ETheme.of(context).colorScheme.surfaceContainerLowest,
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: IntrinsicHeight(
          child: Row(
            children: displayQuotas.asMap().entries.map((entry) {
              final index = entry.key;
              final quota = entry.value;
              final color = UiHelpers.parseHexColor(
                quota.color,
                defaultColor: index % 3 == 0
                    ? AppColors.info
                    : (index % 3 == 1 ? AppColors.success : AppColors.warning),
              );

              final statCol = Container(
                constraints: const BoxConstraints(minWidth: 160),
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${quota.remaining}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: color,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quota.name ?? quota.code ?? 'Leave',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: M3ETheme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '${quota.used} / ${quota.total}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: M3ETheme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                quota.isPaid == false ? 'Unpaid' : 'Paid',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );

              if (index == displayQuotas.length - 1) {
                return statCol;
              }

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  statCol,
                  Container(
                    width: 2,
                    color: M3ETheme.of(context).colorScheme.surfaceContainer,
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
