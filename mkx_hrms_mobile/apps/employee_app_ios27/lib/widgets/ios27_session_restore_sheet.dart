import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:mkx_core/features/auth/state/auth_provider.dart';
import 'package:mkx_core/utils/ui_helpers.dart';
import 'package:provider/provider.dart';

import '../features/attendance/state/attendance_provider.dart';
import '../features/leaves/state/leaves_provider.dart';
import '../features/notifications/state/notifications_provider.dart';
import 'ios27_button.dart';
import 'ios27_text_field.dart';
import 'ios27_toast.dart';

/**
 * iOS 27 Liquid Glass modal sheet for restoring expired authentication sessions in-place.
 */
class Ios27SessionRestoreSheet extends StatefulWidget {
  /**
   * Constructs the session restoration sheet.
   */
  const Ios27SessionRestoreSheet({super.key});

  static bool _isShowing = false;

  /**
   * Displays the session restoration modal sheet if not already open.
   */
  static Future<bool?> show([BuildContext? context]) async {
    if (_isShowing) {
      return null;
    }

    _isShowing = true;
    try {
      final NavigatorState? nav = UiHelpers.rootNavigatorKey.currentState;
      if (nav != null && nav.mounted) {
        return await nav.push<bool>(
          CupertinoModalPopupRoute<bool>(
            barrierDismissible: false,
            builder: (BuildContext modalContext) =>
                const Ios27SessionRestoreSheet(),
          ),
        );
      }

      final BuildContext? targetContext = context ??
          UiHelpers.rootNavigatorKey.currentState?.overlay?.context ??
          UiHelpers.rootNavigatorKey.currentContext;

      if (targetContext != null && targetContext.mounted) {
        return await showCupertinoModalPopup<bool>(
          context: targetContext,
          useRootNavigator: true,
          barrierDismissible: false,
          builder: (BuildContext modalContext) =>
              const Ios27SessionRestoreSheet(),
        );
      }

      return null;
    } catch (e) {
      debugPrint('Failed to show session restore sheet: $e');
      return null;
    } finally {
      _isShowing = false;
    }
  }

  @override
  State<Ios27SessionRestoreSheet> createState() =>
      _Ios27SessionRestoreSheetState();
}

class _Ios27SessionRestoreSheetState extends State<Ios27SessionRestoreSheet> {
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  /**
   * Attempts to re-authenticate with the server using the entered password.
   */
  Future<void> _handleRestore() async {
    final String password = _passwordController.text.trim();
    if (password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your password.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final AuthProvider auth = context.read<AuthProvider>();
    final String email = auth.currentUser?.email ?? '';

    if (email.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'User email not found. Please log in again.';
      });
      return;
    }

    final bool success = await auth.login(email, password);

    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.of(context).pop(true);
      Ios27Toast.show(
        context,
        'Session restored successfully!',
        isSuccess: true,
      );

      final BuildContext rootContext =
          UiHelpers.rootNavigatorKey.currentContext ?? context;
      if (rootContext.mounted) {
        final AttendanceProvider attendance =
            rootContext.read<AttendanceProvider>();
        final LeavesProvider leaves = rootContext.read<LeavesProvider>();
        final NotificationsProvider notifications =
            rootContext.read<NotificationsProvider>();

        attendance.loadAttendance(
          employeeId: auth.currentUser?.employeeDbId,
          employeeCode: auth.currentUser?.employeeId,
        );
        leaves.loadLeaves(
          employeeId: auth.currentUser?.employeeDbId,
          employeeCode: auth.currentUser?.employeeId,
        );
        notifications.fetchNotifications();
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = auth.errorMessage ??
            'Incorrect password. Please verify and try again.';
      });
    }
  }

  /**
   * Terminates the current session and redirects to the login screen.
   */
  Future<void> _handleLogout() async {
    Navigator.of(context).pop(false);
    final AuthProvider auth = context.read<AuthProvider>();
    await auth.logout();
    final BuildContext? rootContext = UiHelpers.rootNavigatorKey.currentContext;
    if (rootContext != null && rootContext.mounted) {
      Ios27Toast.show(
        rootContext,
        'Logged out. Please sign in again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark =
        CupertinoTheme.of(context).brightness == Brightness.dark;
    final Color primaryColor = CupertinoTheme.of(context).primaryColor;
    final AuthProvider auth = context.watch<AuthProvider>();
    final String displayName = auth.currentUser?.name ?? 'Employee';
    final String email = auth.currentUser?.email ?? '';
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 35, sigmaY: 35),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xE6141824) : const Color(0xF2F5F7FB),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(36)),
              border: Border.all(
                color: isDark
                    ? CupertinoColors.white.withValues(alpha: 0.16)
                    : CupertinoColors.black.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: isDark
                            ? CupertinoColors.white.withValues(alpha: 0.28)
                            : CupertinoColors.black.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFFFF9500).withValues(alpha: 0.25),
                            const Color(0xFFFF3B30).withValues(alpha: 0.2),
                          ],
                        ),
                        border: Border.all(
                          color:
                              const Color(0xFFFF9500).withValues(alpha: 0.45),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        CupertinoIcons.lock_shield_fill,
                        size: 32,
                        color: Color(0xFFFF9500),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Session Expired',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                      color: isDark
                          ? CupertinoColors.white
                          : const Color(0xFF1C1C1E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your login session has timed out. Enter your password to restore connection with the server.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.35,
                      color: isDark
                          ? CupertinoColors.white.withValues(alpha: 0.65)
                          : const Color(0xFF6E6E73),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? CupertinoColors.white.withValues(alpha: 0.06)
                          : CupertinoColors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? CupertinoColors.white.withValues(alpha: 0.1)
                            : CupertinoColors.black.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryColor.withValues(alpha: 0.2),
                          ),
                          child: Center(
                            child: Text(
                              displayName.isNotEmpty
                                  ? displayName[0].toUpperCase()
                                  : 'U',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                displayName,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? CupertinoColors.white
                                      : const Color(0xFF1C1C1E),
                                ),
                              ),
                              if (email.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  email,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: isDark
                                        ? CupertinoColors.white
                                            .withValues(alpha: 0.5)
                                        : const Color(0xFF8E8E93),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Ios27TextField(
                    controller: _passwordController,
                    placeholder: 'Enter your password',
                    obscureText: _obscurePassword,
                    errorText: _errorMessage,
                    prefixIcon: Icon(
                      CupertinoIcons.lock_fill,
                      size: 20,
                      color: isDark
                          ? CupertinoColors.white.withValues(alpha: 0.6)
                          : const Color(0xFF8E8E93),
                    ),
                    suffixIcon: CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(36, 36),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      child: Icon(
                        _obscurePassword
                            ? CupertinoIcons.eye_slash_fill
                            : CupertinoIcons.eye_fill,
                        size: 20,
                        color: isDark
                            ? CupertinoColors.white.withValues(alpha: 0.6)
                            : const Color(0xFF8E8E93),
                      ),
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _handleRestore(),
                  ),
                  const SizedBox(height: 20),
                  Ios27Button(
                    onPressed: _isLoading ? null : _handleRestore,
                    label: 'Restore Session',
                    isLoading: _isLoading,
                    icon: const Icon(CupertinoIcons.arrow_clockwise, size: 18),
                  ),
                  const SizedBox(height: 8),
                  CupertinoButton(
                    onPressed: _isLoading ? null : _handleLogout,
                    child: Text(
                      'Switch Account / Log Out',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFFF3B30).withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
