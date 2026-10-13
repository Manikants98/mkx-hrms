import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'features/auth/screens/employee_login_screen.dart';
import 'package:mkx_core/features/auth/state/auth_provider.dart';
import 'package:mkx_core/theme/app_theme_scope.dart';
import 'package:mkx_core/theme/app_theme_settings.dart';
import 'package:mkx_core/utils/ui_helpers.dart';
import 'widgets/employee_splash_screen.dart';
import 'widgets/ios27_toast.dart';
import 'package:provider/provider.dart';

import 'features/ai_assistant/state/ai_provider.dart';
import 'features/attendance/state/attendance_provider.dart';
import 'features/leaves/state/leaves_provider.dart';
import 'features/navigation/screens/main_shell_screen.dart';
import 'features/notifications/state/notifications_provider.dart';
import 'features/payroll/state/payroll_provider.dart';

final GlobalKey<NavigatorState> navigatorKey = UiHelpers.rootNavigatorKey;

/// Background FCM message handler.
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  UiHelpers.customToastHandler = (
    BuildContext context,
    String message, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    Ios27Toast.show(
      context,
      message,
      isError: isError,
      isSuccess: isSuccess,
    );
  };

  await LiquidGlassWidgets.initialize();

  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        final title = message.notification?.title ??
            message.data['title'] ??
            'Notification';
        final body = message.notification?.body ??
            message.data['body'] ??
            message.data['message'] ??
            '';

        Ios27Toast.show(
          context,
          body.isNotEmpty ? '$title: $body' : title,
        );
      }
    });
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  runApp(
    LiquidGlassWidgets.wrap(
      brightnessResolver: (context) =>
          CupertinoTheme.of(context).brightness ?? Brightness.dark,
      adaptiveQuality: false,
      child: const MkxHrmsApp(),
    ),
  );
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
    _themeSettings.fontFamily = AppThemeSettings.sfPro;
    _themeSettings.loadSettings().then((_) {
      if (_themeSettings.fontFamily == null ||
          _themeSettings.fontFamily == AppThemeSettings.googleSansFlex) {
        _themeSettings.fontFamily = AppThemeSettings.sfPro;
      }
    });
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
        ChangeNotifierProvider(create: (_) => AiProvider()),
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
      ],
      child: AppThemeScope(
        settings: _themeSettings,
        child: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            final settings = AppThemeScope.of(context);
            final primaryColor = settings.seedColor;

            return Builder(
              builder: (innerContext) {
                final isDark = settings.autoTheming
                    ? MediaQuery.platformBrightnessOf(innerContext) ==
                        Brightness.dark
                    : auth.themeMode == ThemeMode.dark;

                return CupertinoApp(
                  navigatorKey: navigatorKey,
                  title: 'MKX HRMS',
                  debugShowCheckedModeBanner: false,
                  theme: CupertinoThemeData(
                    brightness: isDark ? Brightness.dark : Brightness.light,
                    primaryColor: primaryColor,
                    textTheme: CupertinoTextThemeData(
                      textStyle: TextStyle(
                        fontFamily:
                            settings.fontFamily ?? AppThemeSettings.sfPro,
                      ),
                      actionTextStyle: TextStyle(
                        fontFamily:
                            settings.fontFamily ?? AppThemeSettings.sfPro,
                        color: primaryColor,
                      ),
                      navTitleTextStyle: TextStyle(
                        fontFamily:
                            settings.fontFamily ?? AppThemeSettings.sfPro,
                        fontWeight: FontWeight.w600,
                      ),
                      navLargeTitleTextStyle: TextStyle(
                        fontFamily:
                            settings.fontFamily ?? AppThemeSettings.sfPro,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  home: _buildHome(auth),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHome(AuthProvider auth) {
    if (auth.isInitializing) return const EmployeeSplashScreen();
    if (auth.isAuthenticated) return const MainShellScreen();
    return const EmployeeLoginScreen();
  }
}
