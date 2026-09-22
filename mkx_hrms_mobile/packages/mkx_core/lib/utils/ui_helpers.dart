import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../constants/app_colors.dart';

/// Helper methods for SnackBars, dialogs, and UI feedback using system fonts.
class UiHelpers {
  UiHelpers._();

  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    Color bgColor = AppColors.lightPrimary;
    Color textColor = AppColors.lightPrimaryForeground;

    if (isError) {
      bgColor = AppColors.error;
      textColor = Colors.white;
    } else if (isSuccess) {
      bgColor = AppColors.success;
      textColor = Colors.white;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
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
