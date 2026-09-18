import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mkx_core/constants/app_colors.dart';

/// Shell scaffold housing the 5-tab HR Admin navigation bar matching the employee app pattern
class HrShellScreen extends StatelessWidget {
  final Widget child;

  const HrShellScreen({super.key, required this.child});

  static const List<_HrNavItem> _items = [
    _HrNavItem(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
    ),
    _HrNavItem(
      label: 'Employees',
      icon: Icons.people_outline_rounded,
      activeIcon: Icons.people_rounded,
    ),
    _HrNavItem(
      label: 'Leaves',
      icon: Icons.event_note_outlined,
      activeIcon: Icons.event_note_rounded,
    ),
    _HrNavItem(
      label: 'Attendance',
      icon: Icons.today_outlined,
      activeIcon: Icons.today_rounded,
    ),
    _HrNavItem(
      label: 'Payroll',
      icon: Icons.payments_outlined,
      activeIcon: Icons.payments_rounded,
    ),
    _HrNavItem(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final surfaceColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final activeColor = colorScheme.primary;
    final inactiveColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final indicatorColor = colorScheme.primary.withValues(
      alpha: isDark ? 0.24 : 0.14,
    );

    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _indexForLocation(location);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Theme(
            data: Theme.of(context).copyWith(
              navigationBarTheme: NavigationBarThemeData(
                height: 68,
                backgroundColor: surfaceColor,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                indicatorColor: indicatorColor,
                indicatorShape: const StadiumBorder(),
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  final selected = states.contains(WidgetState.selected);
                  return GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? activeColor : inactiveColor,
                  );
                }),
                iconTheme: WidgetStateProperty.resolveWith((states) {
                  final selected = states.contains(WidgetState.selected);
                  return IconThemeData(
                    size: 24,
                    color: selected ? activeColor : inactiveColor,
                  );
                }),
              ),
            ),
            child: NavigationBar(
              selectedIndex: currentIndex,
              onDestinationSelected: (index) => _navigate(context, index),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: _items
                  .map(
                    (item) => NavigationDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.activeIcon),
                      label: item.label,
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  int _indexForLocation(String location) {
    if (location.startsWith('/employees')) return 1;
    if (location.startsWith('/leaves')) return 2;
    if (location.startsWith('/attendance')) return 3;
    if (location.startsWith('/payroll')) return 4;
    if (location.startsWith('/profile')) return 5;
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
      case 5:
        context.go('/profile');
        break;
    }
  }
}

class _HrNavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _HrNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}
