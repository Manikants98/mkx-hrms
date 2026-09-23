import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart' as m3e;

import 'package:provider/provider.dart';
import 'package:mkx_core/constants/app_colors.dart';
import 'package:mkx_core/theme/app_theme.dart';
import 'features/attendance/state/attendance_provider.dart';
import 'package:mkx_core/features/auth/screens/login_screen.dart';
import 'package:mkx_core/features/auth/state/auth_provider.dart';
import 'features/leaves/state/leaves_provider.dart';
import 'features/navigation/screens/main_shell_screen.dart';
import 'features/payroll/state/payroll_provider.dart';

import 'package:mkx_core/theme/app_theme_scope.dart';
import 'package:mkx_core/theme/app_theme_settings.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MkxHrmsApp());
}

/// Root Application Widget for MKX HRMS Mobile
class MkxHrmsApp extends StatefulWidget {
  const MkxHrmsApp({super.key});

  @override
  State<MkxHrmsApp> createState() => _MkxHrmsAppState();
}

class _MkxHrmsAppState extends State<MkxHrmsApp> {
  late final AppThemeSettings _themeSettings;

  @override
  void initState() {
    super.initState();
    _themeSettings = AppThemeSettings();
    _themeSettings.loadSettings();
  }

  @override
  void dispose() {
    _themeSettings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => AttendanceProvider()),
          ChangeNotifierProvider(create: (_) => LeavesProvider()),
          ChangeNotifierProvider(create: (_) => PayrollProvider()),
        ],
        child: AppThemeScope(
          settings: _themeSettings,
          child: DynamicColorBuilder(
            builder: (lightDynamic, darkDynamic) {
              return Consumer<AuthProvider>(
                builder: (context, auth, _) {
                    final seedColor = AppThemeScope.of(context).seedColor;
                    final settings = AppThemeScope.of(context);

                    final lightScheme = settings.dynamicColoring
                        ? _toFlutterColorScheme(lightDynamic) ??
                            ColorScheme.fromSeed(
                                seedColor: seedColor,
                                brightness: Brightness.light)
                        : ColorScheme.fromSeed(
                            seedColor: seedColor, brightness: Brightness.light);

                    final darkScheme = settings.dynamicColoring
                        ? _toFlutterColorScheme(darkDynamic) ??
                            ColorScheme.fromSeed(
                                seedColor: seedColor,
                                brightness: Brightness.dark)
                        : ColorScheme.fromSeed(
                            seedColor: seedColor, brightness: Brightness.dark);

                  return MaterialApp(
                    title: 'MKX HRMS',
                    debugShowCheckedModeBanner: false,
                    theme:
                        AppTheme.lightTheme(lightScheme, settings.fontFamily),
                    darkTheme:
                        AppTheme.darkTheme(darkScheme, settings.fontFamily),
                    themeMode: settings.autoTheming
                        ? ThemeMode.system
                        : auth.themeMode,
                    builder: (context, child) {
                      final isDark =
                          Theme.of(context).brightness == Brightness.dark;
                      final primaryColor = Theme.of(context).colorScheme.primary;
                      final baseTheme = isDark
                          ? m3e.M3EThemeData.dark(seedColor: primaryColor)
                          : m3e.M3EThemeData.light(seedColor: primaryColor);

                      final m3eColorScheme = baseTheme.colorScheme.copyWith(
                        secondaryContainer: baseTheme.colorScheme.primary,
                        onSecondaryContainer: baseTheme.colorScheme.onPrimary,
                        outlineVariant: baseTheme.colorScheme.outlineVariant,
                        surfaceContainerLow:
                            baseTheme.colorScheme.surfaceContainerLow,
                      );

                      return m3e.M3ETheme(
                        data: baseTheme.copyWith(
                          colorScheme: m3eColorScheme,
                          fontFamily: settings.fontFamily,
                          loadingIndicatorTheme:
                              const m3e.M3ELoadingIndicatorTheme(
                            containerWidth: 52,
                            containerHeight: 52,
                            elevation: 1.5,
                          ),
                          chipTheme: AppM3EChipTheme(isDark: isDark),
                        ),
                        child: child ?? const SizedBox.shrink(),
                      );
                    },
                    home: _buildHome(auth),
                  );
                },
              );
            },
          ),
        ));
  }

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

  Widget _buildHome(AuthProvider auth) {
    if (auth.isInitializing) return const _SplashScreen();
    if (auth.isAuthenticated) return const MainShellScreen();
    return const LoginScreen();
  }
}

/// Branded initial splash screen while authentication status initializes
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final isDark = m3e.M3ETheme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                Icons.fingerprint_rounded,
                size: 36,
                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'MKX HRMS',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        ),
      ),
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
      return scheme.primary;
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
      return scheme.onSurfaceVariant;
    }
    if (selected) {
      return scheme.onPrimary;
    }
    return scheme.onSurfaceVariant;
  }
}
