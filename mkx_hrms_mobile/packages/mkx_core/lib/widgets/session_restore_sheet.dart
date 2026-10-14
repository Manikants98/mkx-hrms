import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../features/auth/state/auth_provider.dart';
import '../utils/ui_helpers.dart';

/// Modal bottom sheet widget for restoring expired authentication sessions in-place.
///
/// Conforms to the Material 3 Expressive design system with real-time feedback,
/// keyboard avoidance, and customizable refresh hooks upon re-authentication.
class SessionRestoreSheet extends StatefulWidget {
  /// Optional callback invoked after session restoration succeeds.
  final VoidCallback? onRestored;

  /// Creates a session restoration modal sheet.
  const SessionRestoreSheet({
    super.key,
    this.onRestored,
  });

  static bool _isShowing = false;

  /// Displays the session restoration bottom sheet if not already active.
  static Future<bool?> show({
    BuildContext? context,
    VoidCallback? onRestored,
  }) async {
    if (_isShowing) {
      return null;
    }

    _isShowing = true;
    try {
      final BuildContext? targetContext = context ??
          UiHelpers.rootNavigatorKey.currentContext ??
          UiHelpers.rootNavigatorKey.currentState?.overlay?.context;

      if (targetContext != null && targetContext.mounted) {
        return await showModalBottomSheet<bool>(
          context: targetContext,
          useRootNavigator: true,
          isScrollControlled: true,
          isDismissible: false,
          enableDrag: false,
          backgroundColor: Colors.transparent,
          barrierColor: Colors.black.withValues(alpha: 0.65),
          builder: (BuildContext modalContext) =>
              SessionRestoreSheet(onRestored: onRestored),
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
  State<SessionRestoreSheet> createState() => _SessionRestoreSheetState();
}

class _SessionRestoreSheetState extends State<SessionRestoreSheet> {
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  /// Attempts to re-authenticate with the server using the entered password.
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
        _errorMessage = 'User account not found. Please log in again.';
      });
      return;
    }

    final bool success = await auth.login(email, password);

    if (!mounted) {
      return;
    }

    if (success) {
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop(true);

      final BuildContext rootContext =
          UiHelpers.rootNavigatorKey.currentContext ?? context;

      if (rootContext.mounted) {
        UiHelpers.showSnackBar(
          rootContext,
          'Session restored successfully!',
          isSuccess: true,
        );

        if (widget.onRestored != null) {
          widget.onRestored!();
        }
      }
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _isLoading = false;
        _errorMessage = auth.errorMessage ??
            'Incorrect password. Please verify and try again.';
      });
    }
  }

  /// Terminates the current session and redirects to the login screen.
  Future<void> _handleLogout() async {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop(false);
    final AuthProvider auth = context.read<AuthProvider>();
    await auth.logout();

    final BuildContext? rootContext = UiHelpers.rootNavigatorKey.currentContext;
    if (rootContext != null && rootContext.mounted) {
      UiHelpers.showSnackBar(
        rootContext,
        'Logged out. Please sign in again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final AuthProvider auth = context.watch<AuthProvider>();
    final String displayName = auth.currentUser?.name ?? 'Employee';
    final String email = auth.currentUser?.email ?? '';
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E232E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.35),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              /// Top drag handle
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              /// Warning Shield Icon Badge
              Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.amber.shade700.withValues(alpha: 0.22),
                        Colors.deepOrange.shade600.withValues(alpha: 0.16),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.amber.shade600.withValues(alpha: 0.45),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.lock_clock_rounded,
                    size: 30,
                    color: isDark ? Colors.amber.shade300 : Colors.amber.shade800,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              /// Title
              Text(
                'Session Expired',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),

              /// Subtitle
              Text(
                'Your login session has timed out. Enter your password to restore connection with the server.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.35,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),

              /// Current User Account Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(
                    alpha: isDark ? 0.35 : 0.55,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scheme.primary.withValues(alpha: 0.18),
                      ),
                      child: Center(
                        child: Text(
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : 'U',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: scheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface,
                            ),
                          ),
                          if (email.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              email,
                              style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSurfaceVariant,
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

              /// Password Input Field
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _handleRestore(),
                style: TextStyle(
                  fontSize: 15,
                  color: scheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  prefixIcon: Icon(
                    Icons.lock_outline_rounded,
                    size: 20,
                    color: scheme.onSurfaceVariant,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      size: 20,
                      color: scheme.onSurfaceVariant,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest.withValues(
                    alpha: isDark ? 0.35 : 0.45,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: scheme.primary,
                      width: 1.8,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: scheme.error,
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              /// Error feedback text
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 15,
                        color: scheme.error,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: scheme.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),

              /// Restore Session Button
              SizedBox(
                height: 50,
                child: FilledButton(
                  onPressed: _isLoading ? null : _handleRestore,
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: scheme.onPrimary,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.refresh_rounded, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Restore Session',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 8),

              /// Switch Account / Log Out Button
              TextButton(
                onPressed: _isLoading ? null : _handleLogout,
                style: TextButton.styleFrom(
                  foregroundColor: scheme.error,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Switch Account / Log Out',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: scheme.error,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
