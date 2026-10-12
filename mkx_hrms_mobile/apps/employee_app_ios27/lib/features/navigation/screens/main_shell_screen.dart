import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mkx_core/network/dio_client.dart';

import '../../../widgets/ios27_glass_surface.dart';
import '../../attendance/screens/dashboard_screen.dart';
import '../../attendance/screens/attendance_history_screen.dart';
import '../../leaves/screens/leaves_screen.dart';
import '../../payroll/screens/payroll_screen.dart';
import '../../profile/screens/profile_screen.dart';

/// iOS 27 Liquid Glass Main Navigation Shell.
/// Uses [GlassScaffold] with a continuous refractive bottom bar [GlassTabBar.bottom],
/// ambient mesh background, and a liquid action button for AI smart features.
class MainShellScreen extends StatefulWidget {
  /// Constructs the primary employee application shell.
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _setupPushNotifications();
  }

  /// Registers and syncs Firebase Cloud Messaging token with the backend service.
  Future<void> _setupPushNotifications() async {
    final messaging = FirebaseMessaging.instance;
    final NotificationSettings settings = await messaging.requestPermission();
    debugPrint('Push permission status: ${settings.authorizationStatus}');

    try {
      final String? token = await messaging.getToken();
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
    DashboardScreen(key: ValueKey<int>(0)),
    LeavesScreen(key: ValueKey<int>(1)),
    AttendanceHistoryScreen(key: ValueKey<int>(2)),
    PayrollScreen(key: ValueKey<int>(3)),
    ProfileScreen(key: ValueKey<int>(4)),
  ];

  static const List<GlassTab> _tabs = [
    GlassTab(
      // label: 'Home',
      icon: Icon(CupertinoIcons.square_grid_2x2, size: 28),
      activeIcon: Icon(CupertinoIcons.square_grid_2x2_fill, size: 28),
    ),
    GlassTab(
      // label: 'Leaves',
      icon: Icon(CupertinoIcons.calendar, size: 28),
      activeIcon: Icon(CupertinoIcons.calendar_today, size: 28),
    ),
    GlassTab(
      // label: 'Time',
      icon: Icon(CupertinoIcons.clock, size: 28),
      activeIcon: Icon(CupertinoIcons.clock_fill, size: 28),
    ),
    GlassTab(
      // label: 'Payslips',
      icon: Icon(CupertinoIcons.doc_text, size: 28),
      activeIcon: Icon(CupertinoIcons.doc_text_fill, size: 28),
    ),
    GlassTab(
      // label: 'Profile',
      icon: Icon(CupertinoIcons.person_crop_circle, size: 28),
      activeIcon: Icon(CupertinoIcons.person_crop_circle_fill, size: 28),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      background: const Ios27Background(),
      contentAwareBrightness: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: _screens[_currentIndex],
      ),
      bottomBar: GlassTabBar.bottom(
        selectedIndex: _currentIndex,
        onTabSelected: (index) => setState(() => _currentIndex = index),
        tabs: _tabs,
      ),
    );
  }
}
