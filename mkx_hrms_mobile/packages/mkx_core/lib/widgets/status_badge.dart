import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../constants/app_colors.dart';

/// Semantic pill badge showing colored status using Material 3 Expressive
class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    this.borderRadius = 5.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final normalized = status.trim().toLowerCase();

    Color textColor;
    Color bgColor;

    if (normalized == 'present' ||
        normalized == 'approved' ||
        normalized == 'active' ||
        normalized == 'processed') {
      textColor = AppColors.success;
      bgColor = AppColors.success.withValues(alpha: 0.12);
    } else if (normalized == 'late' ||
        normalized == 'pending' ||
        normalized == 'screening') {
      textColor = AppColors.warning;
      bgColor = AppColors.warning.withValues(alpha: 0.12);
    } else if (normalized == 'absent' ||
        normalized == 'rejected' ||
        normalized == 'inactive') {
      textColor = AppColors.error;
      bgColor = AppColors.error.withValues(alpha: 0.12);
    } else if (normalized == 'on hold' || normalized == 'remote') {
      textColor = AppColors.purple;
      bgColor = AppColors.purple.withValues(alpha: 0.12);
    } else {
      textColor = scheme.onSurfaceVariant;
      bgColor = scheme.surfaceContainerHighest;
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
