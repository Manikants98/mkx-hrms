import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'package:flutter/cupertino.dart';
import 'package:mkx_core/features/auth/state/auth_provider.dart';
import 'package:mkx_core/utils/date_utils.dart';
import 'package:mkx_core/utils/ui_helpers.dart';
import '../../../widgets/ios27_status_badge.dart';
import 'package:provider/provider.dart';

import '../../../widgets/ios27_app_bar.dart';
import '../../../widgets/ios27_glass_surface.dart';
import '../../../widgets/ios27_loader.dart';
import '../../../widgets/ios27_pull_to_refresh.dart';
import '../../../widgets/ios27_segmented_control.dart';
import '../models/leave_model.dart';
import '../state/leaves_provider.dart';
import '../widgets/apply_leave_bottom_sheet.dart';

/// Leaves overview, balance cards, and application history screen with iOS 27 Liquid Glass aesthetic.
class LeavesScreen extends StatefulWidget {
  /// Constructs the employee leaves screen.
  const LeavesScreen({super.key});

  @override
  State<LeavesScreen> createState() => _LeavesScreenState();
}

class _LeavesScreenState extends State<LeavesScreen> {
  static const List<String> _filterOptions = [
    'All',
    'Pending',
    'Approved',
    'Rejected',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  /// Loads leave quota balances and historical requests from backend services.
  Future<void> _loadData() async {
    final AuthProvider auth = context.read<AuthProvider>();
    final LeavesProvider leaves = context.read<LeavesProvider>();
    await leaves.loadLeaves(
      employeeId: auth.currentUser?.employeeDbId,
      employeeCode: auth.currentUser?.employeeId,
    );
  }

  /// Displays the interactive modal sheet for new leave submission.
  void _openApplyModal() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => const ApplyLeaveBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark =
        CupertinoTheme.of(context).brightness == Brightness.dark;
    final LeavesProvider leaves = context.watch<LeavesProvider>();

    final int selectedFilterIdx = _filterOptions.indexOf(leaves.selectedFilter);
    final int safeFilterIdx = selectedFilterIdx >= 0 ? selectedFilterIdx : 0;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.transparent,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Ios27AppBar(
              title: 'Leaves',
              subtitle: 'Time Off & Balances',
              trailing: Ios27GlassButton(
                onPressed: _openApplyModal,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.plus, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Apply',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Ios27PageLoader(
                isLoading: leaves.isLoading && leaves.history.isEmpty,
                message: 'Loading Leave Quotas...',
                child: Ios27RefreshableScrollView(
                  onRefresh: _loadData,
                  padding: const EdgeInsets.only(bottom: 120),
                  children: [
                    const SizedBox(height: 10),
                    _buildDynamicQuotaCards(context, leaves, isDark),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Ios27SegmentedControl(
                        segments: _filterOptions,
                        selectedIndex: safeFilterIdx,
                        onSegmentSelected: (int index) {
                          if (index >= 0 && index < _filterOptions.length) {
                            leaves.setFilter(_filterOptions[index]);
                          }
                        },
                      ),
                    ),
                    const Ios27SectionHeader(title: 'Application History'),
                    if (leaves.filteredHistory.isEmpty)
                      Ios27GlassCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.calendar_badge_plus,
                              size: 48,
                              color: isDark
                                  ? CupertinoColors.white.withValues(alpha: 0.4)
                                  : const Color(0xFF8E8E93),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'No leave records found',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? CupertinoColors.white
                                    : const Color(0xFF1C1C1E),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Tap "+ Apply" in the top bar to request time off.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? CupertinoColors.white
                                        .withValues(alpha: 0.6)
                                    : const Color(0xFF6C6C70),
                              ),
                            ),
                            const SizedBox(height: 16),
                            CupertinoButton.filled(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              onPressed: _openApplyModal,
                              child: const Text('Apply for Leave'),
                            ),
                          ],
                        ),
                      )
                    else
                      Ios27GlassCard(
                        child: Column(
                          children:
                              leaves.filteredHistory.map((LeaveRecord item) {
                            final Color statusColor = item.status == 'Approved'
                                ? const Color(0xFF34C759)
                                : (item.status == 'Pending'
                                    ? const Color(0xFFFF9500)
                                    : const Color(0xFFFF3B30));

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: statusColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          item.leaveType,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? CupertinoColors.white
                                                : const Color(0xFF1C1C1E),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Ios27StatusBadge(status: item.status),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? CupertinoColors.white
                                            .withValues(alpha: 0.06)
                                        : CupertinoColors.black
                                            .withValues(alpha: 0.03),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                CupertinoIcons.calendar,
                                                size: 13,
                                                color: isDark
                                                    ? const Color(0xFF8E8E93)
                                                    : const Color(0xFF6E6E73),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                '${AppDateUtils.formatDate(item.startDate)} - ${AppDateUtils.formatDate(item.endDate)}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark
                                                      ? const Color(0xFFD1D1D6)
                                                      : const Color(0xFF3A3A3C),
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
                                                  ? CupertinoColors.white
                                                  : const Color(0xFF1C1C1E),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (item.reason.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          item.reason,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark
                                                ? const Color(0xFF8E8E93)
                                                : const Color(0xFF6E6E73),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      item.leaveCode,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? const Color(0xFF636366)
                                            : const Color(0xFF8E8E93),
                                      ),
                                    ),
                                    Text(
                                      'Applied: ${AppDateUtils.formatDate(item.appliedOn)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark
                                            ? const Color(0xFF636366)
                                            : const Color(0xFF8E8E93),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the horizontal scrolling iOS 27 glass cards for leave quotas.
  Widget _buildDynamicQuotaCards(
    BuildContext context,
    LeavesProvider leaves,
    bool isDark,
  ) {
    final List<LeaveQuota> quotas = leaves.balances?.list ?? [];
    final List<LeaveQuota> displayQuotas = quotas.isNotEmpty
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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: displayQuotas
            .asMap()
            .entries
            .map((MapEntry<int, LeaveQuota> entry) {
          final int index = entry.key;
          final LeaveQuota quota = entry.value;
          final Color color = UiHelpers.parseHexColor(
            quota.color,
            defaultColor: index % 3 == 0
                ? CupertinoTheme.of(context).primaryColor
                : (index % 3 == 1
                    ? const Color(0xFF34C759)
                    : const Color(0xFFFF9500)),
          );

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 150),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                margin: EdgeInsets.zero,
                shape: const LiquidRoundedSuperellipse(borderRadius: 22),
                useOwnLayer: true,
                settings: LiquidGlassSettings(
                  thickness: 16,
                  blur: 16,
                  refractiveIndex: 1.16,
                  lightIntensity: isDark ? 0.45 : 0.60,
                  fresnelStrength: isDark ? 0.35 : 0.45,
                  chromaticAberration: 0.04,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: isDark ? 0.20 : 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: color.withValues(alpha: isDark ? 0.35 : 0.25),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        '${quota.remaining}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                          color: color,
                          height: 1,
                        ),
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
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: isDark
                                ? CupertinoColors.white
                                : const Color(0xFF1C1C1E),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Text(
                              '${quota.used} / ${quota.total} days',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? const Color(0xFF8E8E93)
                                    : const Color(0xFF6E6E73),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withValues(
                                    alpha: isDark ? 0.22 : 0.14),
                                borderRadius: BorderRadius.circular(6),
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
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
