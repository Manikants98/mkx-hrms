import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../constants/app_colors.dart';

/// Helper methods for SnackBars, dialogs, and UI feedback using system fonts.
class UiHelpers {
  UiHelpers._();

  /// Global key used for displaying top-level SnackBars across the entire application.
  static final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// Global key used for top-level navigation operations across the application.
  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>();

  /// Displays a global SnackBar toast without requiring a local BuildContext.
  static void showGlobalSnackBar(
    String message, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    final state = rootScaffoldMessengerKey.currentState;
    if (state == null) return;
    state.hideCurrentSnackBar();

    Color bgColor = AppColors.lightPrimary;
    Color textColor = AppColors.lightPrimaryForeground;

    if (isError) {
      bgColor = AppColors.error;
      textColor = Colors.white;
    } else if (isSuccess) {
      bgColor = AppColors.success;
      textColor = Colors.white;
    }

    state.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : (isSuccess
                      ? Icons.check_circle_outline_rounded
                      : Icons.info_outline_rounded),
              color: textColor,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final topMargin = mediaQuery.padding.top > 0
        ? mediaQuery.padding.top + 10
        : 36.0;

    final Color accentColor = isError
        ? const Color(0xFFFF3B30)
        : (isSuccess ? const Color(0xFF34C759) : const Color(0xFF007AFF));

    final IconData icon = isError
        ? Icons.cancel_rounded
        : (isSuccess ? Icons.check_circle_rounded : Icons.info_rounded);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: accentColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isDark
            ? const Color(0xFF161A26).withValues(alpha: 0.94)
            : Colors.white.withValues(alpha: 0.96),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.16)
                : Colors.black.withValues(alpha: 0.08),
            width: 0.9,
          ),
        ),
        margin: EdgeInsets.only(
          bottom: mediaQuery.size.height - (topMargin + 65),
          left: 18,
          right: 18,
        ),
        duration: const Duration(milliseconds: 2800),
      ),
    );
  }

  static Future<bool?> showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
  }) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;

    return M3EDialog.show<bool>(
      context,
      dialog: Builder(
        builder: (dialogCtx) => M3EDialog(
          title: title,
          icon: isDestructive
              ? Icon(Icons.error_outline_rounded, color: Colors.red)
              : const Icon(Icons.info_outline_rounded),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: theme.typeScale.bodyMedium
                .copyWith(color: scheme.onSurfaceVariant),
          ),
          actions: [
            M3EButton(
              style: M3EButtonStyle.text,
              decoration: isDestructive
                  ? M3EButtonDecoration(
                      foregroundColor: WidgetStatePropertyAll(Colors.red),
                    )
                  : null,
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: Text(cancelText),
            ),
            M3EButton(
              style: M3EButtonStyle.filled,
              decoration: isDestructive
                  ? M3EButtonDecoration(
                      backgroundColor: WidgetStatePropertyAll(Colors.red),
                      foregroundColor: WidgetStatePropertyAll(Colors.white),
                    )
                  : null,
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: Text(confirmText),
            ),
          ],
        ),
      ),
    );
  }

  /// Parses a hex color string into a Flutter Color object with fallback
  static Color parseHexColor(
    String? hexString, {
    Color defaultColor = AppColors.info,
  }) {
    if (hexString == null || hexString.trim().isEmpty) return defaultColor;
    try {
      final clean = hexString.trim().replaceFirst('#', '');
      final buffer = StringBuffer();
      if (clean.length == 6) buffer.write('ff');
      buffer.write(clean);
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return defaultColor;
    }
  }
}
