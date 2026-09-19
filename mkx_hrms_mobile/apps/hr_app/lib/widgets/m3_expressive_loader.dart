import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart' as m3e;
import 'package:mkx_core/constants/app_colors.dart';

/// Official Material 3 Expressive Loading Indicator.
///
/// Utilizes the official shape-morphing polygon animation from the
/// `material_3_expressive` package, providing both contained and standalone
/// variants for seamless M3E experience.
class M3ExpressiveLoader extends StatelessWidget {
  /// The size constraint for the loader.
  final double size;

  /// Primary color for the morphing shape.
  final Color? color;

  /// Contained container background color.
  final Color? containerColor;

  /// Variant of the loading indicator.
  final m3e.M3ELoadingIndicatorVariant variant;

  /// Optional semantic label for accessibility.
  final String semanticLabel;

  /// Creates a contained Material 3 Expressive loading indicator.
  const M3ExpressiveLoader.contained({
    super.key,
    this.size = 48.0,
    this.color,
    this.containerColor,
    this.semanticLabel = 'Loading',
  }) : variant = m3e.M3ELoadingIndicatorVariant.contained;

  /// Creates a floating morphing Material 3 Expressive loading indicator.
  const M3ExpressiveLoader.morphing({
    super.key,
    this.size = 38.0,
    this.color,
    this.semanticLabel = 'Loading',
  })  : variant = m3e.M3ELoadingIndicatorVariant.defaultStyle,
        containerColor = null;

  /// Creates a compact wavy circular progress indicator for buttons and chips.
  static Widget button({
    Color? color,
    double size = 18.0,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: m3e.M3EProgressIndicator.circularWavy(
        size: size,
        color: color ?? Colors.white,
        strokeWidth: 2.2,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = color ??
        (isDark ? AppColors.darkPrimary : AppColors.lightPrimary);
    final resolvedContainerColor = containerColor ??
        (isDark ? AppColors.darkSecondary : AppColors.lightSecondary);

    return Center(
      child: m3e.M3ELoadingIndicator(
        variant: variant,
        color: primaryColor,
        containerColor: resolvedContainerColor,
        elevation: variant == m3e.M3ELoadingIndicatorVariant.contained ? 1 : 0,
        constraints: BoxConstraints.tight(Size(size, size)),
        semanticLabel: semanticLabel,
      ),
    );
  }
}
