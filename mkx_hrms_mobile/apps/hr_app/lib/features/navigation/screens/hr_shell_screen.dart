import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mkx_core/constants/app_colors.dart';
import 'package:mkx_core/features/auth/state/auth_provider.dart';
import 'package:mkx_core/widgets/app_text.dart';
import 'package:provider/provider.dart';

/// Shell scaffold housing the 5-tab HR Admin navigation bar
class HrShellScreen extends StatelessWidget {
  final Widget child;

  const HrShellScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _indexForLocation(location);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: _HrAppBar(isDark: isDark),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        indicatorColor: AppColors.info.withValues(alpha: 0.12),
        onDestinationSelected: (index) => _navigate(context, index),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          _navDest(
            context,
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard_rounded,
            label: 'Dashboard',
            selected: currentIndex == 0,
          ),
          _navDest(
            context,
            icon: Icons.people_outline_rounded,
            selectedIcon: Icons.people_rounded,
            label: 'Employees',
            selected: currentIndex == 1,
          ),
          _navDest(
            context,
            icon: Icons.event_note_outlined,
            selectedIcon: Icons.event_note_rounded,
            label: 'Leaves',
            selected: currentIndex == 2,
          ),
          _navDest(
            context,
            icon: Icons.today_outlined,
            selectedIcon: Icons.today_rounded,
            label: 'Attendance',
            selected: currentIndex == 3,
          ),
          _navDest(
            context,
            icon: Icons.payments_outlined,
            selectedIcon: Icons.payments_rounded,
            label: 'Payroll',
            selected: currentIndex == 4,
          ),
        ],
      ),
    );
  }

  NavigationDestination _navDest(
    BuildContext context, {
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required bool selected,
  }) {
    final color = AppColors.info;
    return NavigationDestination(
      icon: Icon(icon),
      selectedIcon: Icon(selectedIcon, color: color),
      label: label,
    );
  }

  int _indexForLocation(String location) {
    if (location.startsWith('/employees')) return 1;
    if (location.startsWith('/leaves')) return 2;
    if (location.startsWith('/attendance')) return 3;
    if (location.startsWith('/payroll')) return 4;
    return 0;
  }

  void _navigate(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/employees');
        break;
      case 2:
        context.go('/leaves');
        break;
      case 3:
        context.go('/attendance');
        break;
      case 4:
        context.go('/payroll');
        break;
    }
  }
}

class _HrAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isDark;

  const _HrAppBar({required this.isDark});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return AppBar(
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.corporate_fare_rounded,
              size: 16,
              color: AppColors.info,
            ),
          ),
          const SizedBox(width: 8),
          const AppText('MKX HRMS', fontSize: 15, fontWeight: FontWeight.w800),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.logout_rounded,
            size: 20,
            color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
          ),
          tooltip: 'Sign out',
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const AppText.title('Sign Out'),
                content: const AppText.body(
                  'Are you sure you want to sign out?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const AppText('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const AppText(
                      'Sign Out',
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
            if (confirmed == true && context.mounted) {
              await auth.logout();
            }
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}
