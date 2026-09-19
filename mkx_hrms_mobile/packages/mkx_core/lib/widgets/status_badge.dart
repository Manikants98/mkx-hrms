import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Semantic pill badge showing colored status with subtle tinted background using system fonts.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final normalized = status.trim().toLowerCase();

    Color textColor;
    Color bgColor;
    Color borderColor;

    if (normalized == 'present' ||
        normalized == 'approved' ||
        normalized == 'active' ||
        normalized == 'processed') {
      textColor = AppColors.success;
      bgColor = isDark ? AppColors.successBgDark : AppColors.successBgLight;
      borderColor = AppColors.success.withValues(alpha: 0.3);
    } else if (normalized == 'late' ||
        normalized == 'pending' ||
        normalized == 'screening') {
      textColor = AppColors.warning;
      bgColor = isDark ? AppColors.warningBgDark : AppColors.warningBgLight;
      borderColor = AppColors.warning.withValues(alpha: 0.3);
    } else if (normalized == 'absent' ||
        normalized == 'rejected' ||
        normalized == 'inactive') {
      textColor = AppColors.error;
      bgColor = isDark ? AppColors.errorBgDark : AppColors.errorBgLight;
      borderColor = AppColors.error.withValues(alpha: 0.3);
    } else if (normalized == 'on hold' || normalized == 'remote') {
      textColor = AppColors.purple;
      bgColor = isDark ? AppColors.purpleBgDark : AppColors.purpleBgLight;
      borderColor = AppColors.purple.withValues(alpha: 0.3);
    } else {
      textColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;
      bgColor = isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
      borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: 1),
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
