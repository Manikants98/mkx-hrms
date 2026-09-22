import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:mkx_core/features/auth/state/auth_provider.dart';
import 'package:mkx_core/utils/date_utils.dart';
import 'package:mkx_core/utils/ui_helpers.dart';
import 'package:mkx_core/widgets/app_avatar.dart';
import 'package:mkx_core/widgets/mkx_app_bar.dart';
import 'package:mkx_core/widgets/section_tile.dart';
import 'package:mkx_core/widgets/status_badge.dart';
import 'package:mkx_core/theme/app_theme_settings.dart';
import 'package:mkx_core/theme/app_theme_scope.dart';
import 'package:mkx_core/widgets/theme_config_page.dart';
import 'package:provider/provider.dart';

/// HR Admin Profile, Settings, Theme Mode, and Logout Screen
class HrProfileScreen extends StatefulWidget {
  const HrProfileScreen({super.key});

  @override
  State<HrProfileScreen> createState() => _HrProfileScreenState();
}

class _HrProfileScreenState extends State<HrProfileScreen> {
  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await UiHelpers.showConfirmDialog(
      context: context,
      title: 'Sign Out',
      message: 'Are you sure you want to sign out of your HR Admin account?',
      confirmText: 'Sign Out',
      isDestructive: true,
    );

    if (confirmed == true && context.mounted) {
      final auth = context.read<AuthProvider>();
      await auth.logout();
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = M3ETheme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final colorScheme = M3ETheme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainer,
      appBar: MkxAppBar(
        title: 'Profile',
        subtitle: 'HR Admin account preferences',
        actions: [
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            color: colorScheme.onSurface,
            onPressed: () => ThemeConfigPage.push(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              M3ECard(
                variant: M3ECardVariant.filled,
                borderRadius: BorderRadius.circular(16),
                color: colorScheme.surfaceContainerLowest,
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppAvatar(
                      name: user?.name ?? 'HR Admin',
                      size: 64,
                      borderRadius: 8,
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
                                  user?.name ?? 'Admin Name',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              StatusBadge(status: user?.status ?? 'Active'),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.role ?? 'Role',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.department ?? 'Department',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              const Text(
                'Employment Details',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 10),
              SectionCard(
                isDark: isDark,
                children: [
                  _buildInfoTileContent(
                    icon: Icons.badge_outlined,
                    label: 'Employee Code',
                    value: user?.employeeId ?? 'EMP-001',
                    isDark: isDark,
                  ),
                  _buildInfoTileContent(
                    icon: Icons.alternate_email_rounded,
                    label: 'Email',
                    value: user?.email ?? '--',
                    isDark: isDark,
                  ),
                  _buildInfoTileContent(
                    icon: Icons.supervisor_account_outlined,
                    label: 'Reporting Manager',
                    value: user?.managerName ?? 'Department Head',
                    isDark: isDark,
                  ),
                  _buildInfoTileContent(
                    icon: Icons.calendar_today_outlined,
                    label: 'Joining Date',
                    value: AppDateUtils.formatDate(user?.joinDate),
                    isDark: isDark,
                  ),
                  _buildInfoTileContent(
                    icon: Icons.access_time_rounded,
                    label: 'Timezone',
                    value: 'Asia/Kolkata (IST)',
                    isDark: isDark,
                  ),
                  _buildInfoTileContent(
                    icon: Icons.schedule_outlined,
                    label: 'Work Shift',
                    value: user?.shiftName != null
                        ? '${user!.shiftName}'
                        : 'General',
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 10),

              const Text(
                'App Preferences',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 10),
              SectionTile(
                isDark: isDark,
                position: TilePosition.only,
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Theme Mode',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose between system, light, and dark zinc appearance.',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildThemeChips(
                          context, auth, isDark, AppThemeScope.of(context)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Logout Button
              M3EButton(
                style: M3EButtonStyle.filled,
                size: M3EButtonSize.sm,
                onPressed: () => _handleLogout(context),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Sign Out'),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the row content for an info tile — decoration is handled by [SectionCard].
  Widget _buildInfoTileContent({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    final colorScheme = M3ETheme.of(context).colorScheme;
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 14),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildThemeChips(
    BuildContext context,
    AuthProvider auth,
    bool isDark,
    AppThemeSettings settings,
  ) {
    final colorScheme = M3ETheme.of(context).colorScheme;
    final modes = [
      (ThemeMode.light, 'Light', Icons.light_mode_rounded),
      (ThemeMode.system, 'System', Icons.settings_brightness_rounded),
      (ThemeMode.dark, 'Dark', Icons.dark_mode_rounded),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: M3EButtonGroup(
        type: M3EButtonGroupType.connected,
        shape: M3EButtonShape.square,
        size: M3EButtonSize.sm,
        style: M3EButtonStyle.filled,
        neighborSquish: true,
        decoration: M3EToggleButtonDecoration(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.primary;
            }
            return colorScheme.surfaceContainer;
          }),
        ),
        selectedIndex: modes.indexWhere((m) => m.$1 == auth.themeMode),
        onSelectedIndexChanged: (int? index) {
          if (index != null && index >= 0 && index < modes.length) {
            final item = modes[index];
            if (item.$1 == ThemeMode.system) {
              settings.autoTheming = true;
            } else {
              settings.autoTheming = false;
            }
            auth.setThemeMode(item.$1);
          }
        },
        actions: modes.map((item) {
          return M3EButtonGroupAction(
            label: Text(item.$2),
            icon: Icon(item.$3, size: 14),
          );
        }).toList(),
      ),
    );
  }
}
