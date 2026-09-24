import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import 'splash_illustration.dart';

/// Clean placeholder shown when a list has no data using Material 3 Expressive
class EmptyState extends StatelessWidget {
  /// Optional icon to display. If omitted or when illustration is shown,
  /// the custom empty boxes SVG illustration is rendered by default.
  final IconData? icon;

  /// Header title for the empty state
  final String title;

  /// Descriptive subtitle for the empty state
  final String description;

  /// Optional action widget, e.g. a button
  final Widget? action;

  /// Custom height for the illustration
  final double illustrationHeight;

  /// Whether to show the SVG illustration (defaults to true)
  final bool showIllustration;

  const EmptyState({
    super.key,
    this.icon,
    required this.title,
    required this.description,
    this.action,
    this.illustrationHeight = 180,
    this.showIllustration = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;

    return SizedBox(
      height: 500,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showIllustration)
                SvgPicture.string(
                  getBoxesSplashSvg(scheme),
                  height: illustrationHeight,
                )
              else if (icon != null)
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 35,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.typeScale.titleMedium.copyWith(
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                textAlign: TextAlign.center,
                style: theme.typeScale.bodyMedium.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if (action != null) ...[
                const SizedBox(height: 16),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
