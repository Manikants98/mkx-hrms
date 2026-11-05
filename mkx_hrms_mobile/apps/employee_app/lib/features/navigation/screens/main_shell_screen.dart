import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mkx_core/network/dio_client.dart';

import '../../attendance/screens/dashboard_screen.dart';
import '../../attendance/screens/attendance_history_screen.dart';
import '../../leaves/screens/leaves_screen.dart';
import '../../payroll/screens/payroll_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../ai_assistant/screens/smart_assistant_screen.dart';
import '../../../services/shift_widget_service.dart';

/**
 * Bottom Navigation Shell housing the primary employee modules.
 * Uses Material 3's NavigationBar with expressive styling and safe back-navigation scoping.
 */
class MainShellScreen extends StatefulWidget {
  /** GlobalKey instance kept for legacy compatibility */
  static final GlobalKey<MainShellScreenState> shellKey =
      GlobalKey<MainShellScreenState>();

  /** Tab index notifier used for external navigation events like widget deep links */
  static final ValueNotifier<int> activeTabNotifier = ValueNotifier<int>(0);

  /**
   * Triggers tab change from external sources without direct widget tree coupling.
   *
   * @param index Target tab index
   */
  static void switchShellTab(int index) {
    activeTabNotifier.value = index;
    shellKey.currentState?.switchTab(index);
  }

  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => MainShellScreenState();
}

class MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;

  /**
   * Switches the active shell tab by index.
   *
   * @param index Target tab index
   */
  void switchTab(int index) {
    if (mounted && index >= 0 && index < _screens.length) {
      if (_currentIndex != index) {
        setState(() {
          _currentIndex = index;
        });
      }
      if (MainShellScreen.activeTabNotifier.value != index) {
        MainShellScreen.activeTabNotifier.value = index;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _setupPushNotifications();
    MainShellScreen.activeTabNotifier.addListener(_onActiveTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initialUri = ShiftWidgetService.consumeInitialWidgetUri();
      if (initialUri != null) {
        if (initialUri.contains('apply_leave')) {
          switchTab(1);
        } else if (initialUri.contains('shift_tracker')) {
          switchTab(0);
        }
      }
    });
  }

  void _onActiveTabChanged() {
    final target = MainShellScreen.activeTabNotifier.value;
    if (target != _currentIndex) {
      switchTab(target);
    }
  }

  @override
  void dispose() {
    MainShellScreen.activeTabNotifier.removeListener(_onActiveTabChanged);
    super.dispose();
  }

  Future<void> _setupPushNotifications() async {
    debugPrint('Starting push notification setup...');
    final messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission();
    debugPrint('Push permission status: ${settings.authorizationStatus}');

    try {
      String? token = await messaging.getToken();
      debugPrint('FCM Token fetched: $token');

      if (token != null) {
        await DioClient.instance
            .post('/auth/fcm-token', data: {'fcmToken': token});
        debugPrint('FCM Token synced successfully.');
      }
    } catch (e) {
      debugPrint('Failed to sync FCM Token: $e');
    }
  }

  final List<Widget> _screens = const [
    DashboardScreen(key: ValueKey(0)),
    LeavesScreen(key: ValueKey(1)),
    AttendanceHistoryScreen(key: ValueKey(2)),
    PayrollScreen(key: ValueKey(3)),
    ProfileScreen(key: ValueKey(4)),
  ];

  static const List<_NavItemData> _items = [
    _NavItemData(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
    ),
    _NavItemData(
      label: 'Leaves',
      icon: Icons.event_note_outlined,
      activeIcon: Icons.event_note_rounded,
    ),
    _NavItemData(
      label: 'Attendance',
      icon: Icons.calendar_month_outlined,
      activeIcon: Icons.calendar_month_rounded,
    ),
    _NavItemData(
      label: 'Payslips',
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long_rounded,
    ),
    _NavItemData(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = M3ETheme.of(context).brightness == Brightness.dark;

    final colorScheme = M3ETheme.of(context).colorScheme;
    final surfaceColor = colorScheme.surfaceContainerHigh;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentIndex != 0) {
          switchTab(0);
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: _screens[_currentIndex],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const SmartAssistantScreen(),
              ),
            );
          },
          backgroundColor: colorScheme.primary,
          child: Icon(Icons.auto_awesome, color: colorScheme.onPrimary),
        ),
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
          child: M3ETheme(
            data: M3ETheme.of(context).copyWith(
              colorScheme: colorScheme.copyWith(
                onSecondaryContainer: colorScheme.primary,
                secondaryContainer: colorScheme.primary.withValues(
                  alpha: isDark ? 0.24 : 0.14,
                ),
              ),
            ),
            child: M3ENavigationBar(
              selectedIndex: _currentIndex,
              backgroundColor: colorScheme.surfaceContainerHigh,
              onDestinationSelected: (index) =>
                  setState(() => _currentIndex = index),
              labelBehavior: M3ENavBarLabelBehavior.alwaysShow,
              destinations: _items
                  .map(
                    (item) => M3ENavigationBarDestination(
                      icon: Icon(item.icon),
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
}

class _NavItemData {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _NavItemData({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}
