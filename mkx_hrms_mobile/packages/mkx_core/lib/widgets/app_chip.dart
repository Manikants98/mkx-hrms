import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Global unified filter and action chip using Material 3 Expressive.
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

  /// Corner radius for the chip container (kept for backward compatibility).
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
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;

    final chipContent = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          icon!,
          const SizedBox(width: 5),
        ],
        Text(
          label,
          style: textStyle ??
              TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color:
                    isSelected ? scheme.onPrimaryContainer : scheme.onSurface,
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
                  ? scheme.onPrimaryContainer.withValues(alpha: 0.18)
                  : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );

    return M3ETappable(
      onTap: () {
        if (onTap != null) {
          onTap!();
        } else if (onSelected != null) {
          onSelected!(!isSelected);
        }
      },
      haptic: M3EHapticFeedback.light,
      builder: (context, state) {
        return Container(
          padding: padding,
          decoration: BoxDecoration(
            color: isSelected
                ? scheme.primaryContainer
                : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: isSelected ? Colors.transparent : scheme.outlineVariant,
              width: 1,
            ),
          ),
          child: chipContent,
        );
      },
    );
  }
}
