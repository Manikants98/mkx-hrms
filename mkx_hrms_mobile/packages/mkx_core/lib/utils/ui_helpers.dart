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

  /// Optional custom handler for displaying toasts or notifications in environments
  /// without ScaffoldMessenger (such as Cupertino apps).
  static void Function(
    BuildContext context,
    String message, {
    bool isError,
    bool isSuccess,
  })? customToastHandler;

  static OverlayEntry? _overlayFallbackEntry;

  /// Top-anchored overlay toast HUD used for alert notifications.
  static void _showOverlayFallback(
    BuildContext context,
    String message, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    try {
      if (_overlayFallbackEntry != null && _overlayFallbackEntry!.mounted) {
        _overlayFallbackEntry!.remove();
      }
    } catch (_) {}
    _overlayFallbackEntry = null;

    final overlay = Overlay.maybeOf(context, rootOverlay: true) ??
        Overlay.maybeOf(context) ??
        rootNavigatorKey.currentState?.overlay;

    if (overlay == null) {
      final messenger = ScaffoldMessenger.maybeOf(context) ??
          rootScaffoldMessengerKey.currentState;
      if (messenger != null) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  isError
                      ? Icons.error_outline_rounded
                      : (isSuccess
                          ? Icons.check_circle_outline_rounded
                          : Icons.info_outline_rounded),
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: isError
                ? AppColors.error
                : (isSuccess ? AppColors.success : const Color(0xFF1E293B)),
            behavior: SnackBarBehavior.fixed,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    final mediaQuery = MediaQuery.maybeOf(context);
    final topPadding = (mediaQuery?.padding.top ?? 0) > 0
        ? (mediaQuery!.padding.top + 10)
        : 40.0;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color accentColor = isError
        ? const Color(0xFFFF3B30)
        : (isSuccess ? const Color(0xFF34C759) : const Color(0xFF007AFF));

    final IconData icon = isError
        ? Icons.cancel_rounded
        : (isSuccess ? Icons.check_circle_rounded : Icons.info_rounded);

    final directionality = Directionality.maybeOf(context) ?? TextDirection.ltr;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => Directionality(
        textDirection: directionality,
        child: Positioned(
          top: topPadding,
          left: 20,
          right: 20,
          child: Material(
            type: MaterialType.transparency,
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF161A26).withValues(alpha: 0.94)
                      : Colors.white.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.16)
                        : Colors.black.withValues(alpha: 0.08),
                    width: 0.9,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: accentColor, size: 20),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    _overlayFallbackEntry = entry;
    overlay.insert(entry);

    Future.delayed(const Duration(milliseconds: 2800), () {
      if (_overlayFallbackEntry == entry) {
        try {
          if (entry.mounted) {
            entry.remove();
          }
        } catch (_) {}
        _overlayFallbackEntry = null;
      }
    });
  }

  /// Displays a global toast without requiring a local BuildContext.
  ///
  /// @param message Text message to display
  /// @param isError Denotes whether message is an error alert
  /// @param isSuccess Denotes whether message is a success alert
  static void showGlobalSnackBar(
    String message, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    if (customToastHandler != null && rootNavigatorKey.currentContext != null) {
      customToastHandler!(
        rootNavigatorKey.currentContext!,
        message,
        isError: isError,
        isSuccess: isSuccess,
      );
      return;
    }

    if (rootNavigatorKey.currentContext != null) {
      _showOverlayFallback(
        rootNavigatorKey.currentContext!,
        message,
        isError: isError,
        isSuccess: isSuccess,
      );
      return;
    }

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
        behavior: SnackBarBehavior.fixed,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Displays a toast notification within the given BuildContext or delegates to customToastHandler/overlay.
  ///
  /// @param context BuildContext used to locate Overlay/Theme/Directionality
  /// @param message Text message to present
  /// @param isError Displays red error accent icon
  /// @param isSuccess Displays green success accent icon
  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    if (customToastHandler != null) {
      customToastHandler!(
        context,
        message,
        isError: isError,
        isSuccess: isSuccess,
      );
      return;
    }

    _showOverlayFallback(
      context,
      message,
      isError: isError,
      isSuccess: isSuccess,
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
