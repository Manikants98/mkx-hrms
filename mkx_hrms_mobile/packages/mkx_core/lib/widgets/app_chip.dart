import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Global unified filter and action chip adhering to MKX design standards.
class AppChip extends StatelessWidget {
  /// Display label for the chip.
  final String label;

  /// Whether the chip is actively highlighted or selected.
  final bool isSelected;

  /// Callback when the selection state changes.
  final ValueChanged<bool>? onSelected;

  /// Callback when tapped directly.
  final VoidCallback? onTap;

  /// Optional leading icon.
  final Widget? icon;

  /// Optional trailing numeric badge counter.
  final int? count;

  /// Corner radius for the chip container. Defaults to 8.0px.
  final double borderRadius;

  /// Inner padding inside the chip.
  final EdgeInsetsGeometry padding;

  /// Custom text style override if needed.
  final TextStyle? textStyle;

  /// Creates a global chip widget.
  const AppChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onSelected,
    this.onTap,
    this.icon,
    this.count,
    this.borderRadius = 8.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isSelected
        ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
        : (isDark ? AppColors.darkSecondary : AppColors.lightSecondary);

    final fgColor = isSelected
        ? (isDark
              ? AppColors.darkPrimaryForeground
              : AppColors.lightPrimaryForeground)
        : (isDark ? AppColors.darkMuted : AppColors.lightMuted);

    final borderColor = isSelected
        ? Colors.transparent
        : (isDark ? AppColors.darkBorder : AppColors.lightBorder);

    final radius = BorderRadius.circular(borderRadius);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (onTap != null) {
            onTap!();
          } else if (onSelected != null) {
            onSelected!(!isSelected);
          }
        },
        borderRadius: radius,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: padding,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: radius,
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[icon!, const SizedBox(width: 5)],
              Text(
                label,
                style:
                    textStyle ??
                    TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: fgColor,
                    ),
              ),
              if (count != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? fgColor.withValues(alpha: 0.18)
                        : (isDark ? AppColors.darkCard : AppColors.lightCard),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: fgColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
