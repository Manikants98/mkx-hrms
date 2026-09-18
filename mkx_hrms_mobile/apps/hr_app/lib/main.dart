import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:mkx_core/features/auth/screens/login_screen.dart';
import 'package:mkx_core/features/auth/state/auth_provider.dart';
import 'package:mkx_core/theme/app_theme.dart';

import 'features/attendance/screens/hr_attendance_screen.dart';
import 'features/attendance/state/hr_attendance_provider.dart';
import 'features/dashboard/screens/hr_dashboard_screen.dart';
import 'features/dashboard/state/dashboard_provider.dart';
import 'features/employees/screens/employee_detail_screen.dart';
import 'features/employees/screens/employees_screen.dart';
import 'features/employees/state/employees_provider.dart';
import 'features/leaves/screens/hr_leaves_screen.dart';
import 'features/leaves/state/hr_leaves_provider.dart';
import 'features/navigation/screens/hr_shell_screen.dart';
import 'features/payroll/screens/hr_payroll_screen.dart';
import 'features/payroll/state/hr_payroll_provider.dart';
import 'features/profile/screens/hr_profile_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HrApp());
}

class HrApp extends StatefulWidget {
  const HrApp({super.key});

  @override
  State<HrApp> createState() => _HrAppState();
}

class _HrAppState extends State<HrApp> {
  late final AuthProvider _authProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _router = GoRouter(
      initialLocation: '/',
      refreshListenable: _authProvider,
      redirect: (context, state) {
        final isLoggedIn = _authProvider.isAuthenticated;
        final isInitializing = _authProvider.isInitializing;
        final isGoingToLogin = state.matchedLocation == '/login';

        if (isInitializing) return null;
        if (!isLoggedIn && !isGoingToLogin) return '/login';
        if (isLoggedIn && isGoingToLogin) return '/';
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) => HrShellScreen(child: child),
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HrDashboardScreen(),
            ),
            GoRoute(
              path: '/employees',
              builder: (context, state) => const EmployeesScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) => EmployeeDetailScreen(
                    employeeId: state.pathParameters['id'] ?? '',
                  ),
                ),
              ],
            ),
            GoRoute(
              path: '/leaves',
              builder: (context, state) => const HrLeavesScreen(),
            ),
            GoRoute(
              path: '/attendance',
              builder: (context, state) => const HrAttendanceScreen(),
            ),
            GoRoute(
              path: '/payroll',
              builder: (context, state) => const HrPayrollScreen(),
            ),
            GoRoute(
              path: '/profile',
              builder: (context, state) => const HrProfileScreen(),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => EmployeesProvider()),
        ChangeNotifierProvider(create: (_) => HrLeavesProvider()),
        ChangeNotifierProvider(create: (_) => HrAttendanceProvider()),
        ChangeNotifierProvider(create: (_) => HrPayrollProvider()),
      ],
      child: DynamicColorBuilder(
        builder: (lightDynamic, darkDynamic) {
          return Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return MaterialApp.router(
                title: 'MKX HRMS Admin',
                theme: AppTheme.lightTheme(lightDynamic),
                darkTheme: AppTheme.darkTheme(darkDynamic),
                themeMode: auth.themeMode,
                routerConfig: _router,
                debugShowCheckedModeBanner: false,
              );
            },
          );
        },
      ),
    );
  }
}
