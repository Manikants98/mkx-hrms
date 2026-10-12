import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:mkx_core/features/auth/state/auth_provider.dart';
import 'package:mkx_core/utils/date_utils.dart';
import 'package:mkx_core/widgets/app_avatar.dart';
import '../../../widgets/ios27_status_badge.dart';
import '../../../widgets/ios27_theme_mode_selector.dart';
import 'ios27_theme_config_screen.dart';
import 'package:provider/provider.dart';

import '../../../widgets/ios27_glass_surface.dart';
import '../../../widgets/ios27_loader.dart';
import '../../leaves/models/leave_model.dart';
import '../../leaves/state/leaves_provider.dart';

/// Personal Employee Profile, Settings, Theme Mode, and Logout Screen with iOS 27 Liquid Glass aesthetic.
class ProfileScreen extends StatefulWidget {
  /// Constructs the employee profile and preferences screen.
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final LeavesProvider leaves = context.read<LeavesProvider>();
      if (leaves.balances == null) {
        final AuthProvider auth = context.read<AuthProvider>();
        leaves.loadLeaves(
          employeeId: auth.currentUser?.employeeDbId,
          employeeCode: auth.currentUser?.employeeId,
        );
      }
    });
  }

  /// Prompts for confirmation and terminates the active session.
  Future<void> _handleLogout(BuildContext context) async {
    final bool? confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Sign Out'),
        content: const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text(
              'Are you sure you want to sign out of your employee account?'),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final AuthProvider auth = context.read<AuthProvider>();
      await auth.logout();
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark =
        CupertinoTheme.of(context).brightness == Brightness.dark;
    final AuthProvider auth = context.watch<AuthProvider>();
    final LeavesProvider leaves = context.watch<LeavesProvider>();
    final user = auth.currentUser;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.transparent,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Account & Preferences',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFF8E8E93)
                              : const Color(0xFF6E6E73),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Profile',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                          color: isDark
                              ? CupertinoColors.white
                              : const Color(0xFF1C1C1E),
                        ),
                      ),
                    ],
                  ),
                  GlassIconButton(
                    icon: Icon(
                      CupertinoIcons.paintbrush_fill,
                      size: 19,
                      color: isDark
                          ? CupertinoColors.white
                          : const Color(0xFF1C1C1E),
                    ),
                    onPressed: () => Ios27ThemeConfigScreen.push(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Ios27PageLoader(
                isLoading: auth.isLoading,
                message: 'Loading Profile...',
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 120,top:10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Ios27GlassCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            AppAvatar(
                              name: user?.name ?? 'Employee',
                              imageUrl: user?.avatar,
                              size: 68,
                              borderRadius: 20,
                              backgroundColor: CupertinoTheme.of(context)
                                  .primaryColor
                                  .withValues(alpha: 0.14),
                              foregroundColor:
                                  CupertinoTheme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          user?.name ?? 'Employee Name',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.4,
                                            color: isDark
                                                ? CupertinoColors.white
                                                : const Color(0xFF1C1C1E),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Ios27StatusBadge(
                                          status: user?.status ?? 'Active'),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user?.role ?? 'Role',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: CupertinoTheme.of(context)
                                          .primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    user?.department ?? 'Department',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? const Color(0xFF8E8E93)
                                          : const Color(0xFF6E6E73),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Ios27SectionHeader(title: 'Employment Information'),
                      Ios27GlassCard(
                        child: Column(
                          children: [
                            _buildInfoRow(
                              icon: CupertinoIcons.person_badge_plus_fill,
                              label: 'Employee Code',
                              value: user?.employeeId ?? 'EMP-001',
                              isDark: isDark,
                            ),
                            _buildDivider(isDark),
                            _buildInfoRow(
                              icon: CupertinoIcons.mail_solid,
                              label: 'Corporate Email',
                              value: user?.email ?? '--',
                              isDark: isDark,
                            ),
                            _buildDivider(isDark),
                            _buildInfoRow(
                              icon: CupertinoIcons.person_2_fill,
                              label: 'Reporting Manager',
                              value: user?.managerName ?? 'Department Head',
                              isDark: isDark,
                            ),
                            _buildDivider(isDark),
                            _buildInfoRow(
                              icon: CupertinoIcons.calendar_today,
                              label: 'Joining Date',
                              value: AppDateUtils.formatDate(user?.joinDate),
                              isDark: isDark,
                            ),
                            _buildDivider(isDark),
                            _buildInfoRow(
                              icon: CupertinoIcons.time_solid,
                              label: 'Assigned Shift',
                              value: user?.shiftName ??
                                  'General Standard (9AM - 6PM)',
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                      const Ios27SectionHeader(title: 'Leave Balances'),
                      _buildLeaveBalancesCard(context, leaves, isDark),
                      const Ios27SectionHeader(title: 'System Preferences'),
                      Ios27GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Theme Appearance',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? CupertinoColors.white
                                    : const Color(0xFF1C1C1E),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Configure visual mode to match device daylight or ambient glass settings.',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? const Color(0xFF8E8E93)
                                    : const Color(0xFF6E6E73),
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Ios27ThemeModeSelector(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => _handleLogout(context),
                          child: Container(
                            height: 50,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF3B30)
                                  .withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: const Color(0xFFFF3B30)
                                    .withValues(alpha: 0.35),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(CupertinoIcons.square_arrow_right,
                                    size: 18, color: Color(0xFFFF3B30)),
                                SizedBox(width: 8),
                                Text(
                                  'Sign Out of Account',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFFF3B30),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a glass divider inside platter cards.
  Widget _buildDivider(bool isDark) {
    return Container(
      height: 0.6,
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: isDark ? const Color(0x1AFFFFFF) : const Color(0x14000000),
    );
  }

  /// Builds an employment data item with Cupertino icon and label.
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: CupertinoTheme.of(context).primaryColor,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? CupertinoColors.white : const Color(0xFF1C1C1E),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the leave summary glass card with quota pills.
  Widget _buildLeaveBalancesCard(
    BuildContext context,
    LeavesProvider leaves,
    bool isDark,
  ) {
    final List<LeaveQuota> quotas = leaves.balances?.list ?? [];

    if (quotas.isEmpty) {
      return Ios27GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            'No leave balances loaded.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
            ),
          ),
        ),
      );
    }

    return Ios27GlassCard(
      child: Column(
        children: quotas.map((LeaveQuota quota) {
          final double progress = quota.total > 0
              ? (quota.used / quota.total).clamp(0.0, 1.0)
              : 0.0;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      quota.name ?? quota.code ?? 'Leave',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? CupertinoColors.white
                            : const Color(0xFF1C1C1E),
                      ),
                    ),
                    Text(
                      '${quota.remaining} remaining',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: CupertinoTheme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    height: 6,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0x22FFFFFF)
                          : const Color(0x18000000),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: CupertinoTheme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
