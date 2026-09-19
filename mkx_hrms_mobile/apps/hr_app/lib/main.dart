import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_3_expressive/material_3_expressive.dart' as m3e;
import 'package:provider/provider.dart';

import 'package:mkx_core/constants/app_colors.dart';
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
                theme: AppTheme.lightTheme(_toFlutterColorScheme(lightDynamic)),
                darkTheme: AppTheme.darkTheme(_toFlutterColorScheme(darkDynamic)),
                themeMode: auth.themeMode,
                routerConfig: _router,
                debugShowCheckedModeBanner: false,
                builder: (context, child) {
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  final primaryColor = Theme.of(context).colorScheme.primary;
                  final baseTheme = isDark
                      ? m3e.M3EThemeData.dark(seedColor: primaryColor)
                      : m3e.M3EThemeData.light(seedColor: primaryColor);

                  final m3eColorScheme = baseTheme.colorScheme.copyWith(
                    secondaryContainer:
                        isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                    onSecondaryContainer: isDark
                        ? AppColors.darkPrimaryForeground
                        : AppColors.lightPrimaryForeground,
                    outlineVariant:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    surfaceContainerLow:
                        isDark ? AppColors.darkCard : AppColors.lightCard,
                  );

                  return m3e.M3ETheme(
                    data: baseTheme.copyWith(
                      colorScheme: m3eColorScheme,
                      loadingIndicatorTheme: const m3e.M3ELoadingIndicatorTheme(
                        containerWidth: 52,
                        containerHeight: 52,
                        elevation: 1.5,
                      ),
                      chipTheme: AppM3EChipTheme(isDark: isDark),
                    ),
                    child: child ?? const SizedBox.shrink(),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  /// Converts dynamic color scheme (which might come from dynamic_color's re-exported ColorScheme)
  /// into Flutter's core Material [ColorScheme].
  static ColorScheme? _toFlutterColorScheme(dynamic scheme) {
    if (scheme == null) return null;
    return ColorScheme(
      brightness: scheme.brightness,
      primary: scheme.primary,
      onPrimary: scheme.onPrimary,
      secondary: scheme.secondary,
      onSecondary: scheme.onSecondary,
      error: scheme.error,
      onError: scheme.onError,
      surface: scheme.surface,
      onSurface: scheme.onSurface,
    );
  }
}

/// Unified Material 3 Expressive chip theme conforming to the MKX HRMS design system.
class AppM3EChipTheme extends m3e.M3EChipTheme {
  /// Indicates if the application is currently rendered in dark mode.
  final bool isDark;

  /// Creates a theme configuration for expressive chips.
  const AppM3EChipTheme({
    required this.isDark,
    super.height = 32,
    super.iconSize = 15,
    super.labelStartPadding = 12,
    super.iconStartPadding = 10,
    super.endPadding = 12,
    super.iconLabelGap = 6,
  });

  @override
  Color containerColor(
    m3e.M3EColorScheme scheme, {
    required bool enabled,
    required bool selected,
    required bool elevated,
    required m3e.M3EChipType type,
  }) {
    if (!enabled) {
      return selected
          ? (isDark ? AppColors.darkMutedBg : AppColors.lightMutedBg)
          : const Color(0x00000000);
    }
    if (selected) {
      return isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    }
    return isDark ? AppColors.darkCard : AppColors.lightCard;
  }

  @override
  Color foregroundColor(
    m3e.M3EColorScheme scheme, {
    required bool enabled,
    required bool selected,
  }) {
    if (!enabled) {
      return isDark ? AppColors.darkMuted : AppColors.lightMuted;
    }
    if (selected) {
      return isDark
          ? AppColors.darkPrimaryForeground
          : AppColors.lightPrimaryForeground;
    }
    return isDark ? AppColors.darkMuted : AppColors.lightMuted;
  }
}
