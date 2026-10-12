import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'package:mkx_core/theme/app_theme_scope.dart';

/// Dynamic iOS 27 Mesh Gradient Wallpaper that reacts dynamically to the chosen theme palette and seed color.
/// Provides rich luminous visual contrast behind liquid glass surfaces.
class Ios27Background extends StatelessWidget {
  /// Optional custom child widget to render inside the background layer.
  final Widget? child;

  /// Optional custom tint color to override the ambient palette.
  final Color? tintColor;

  /// Creates an iOS 27 authentic ambient mesh background.
  const Ios27Background({
    super.key,
    this.child,
    this.tintColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark =
        CupertinoTheme.of(context).brightness == Brightness.dark;

    Color primary;
    if (tintColor != null) {
      primary = tintColor!;
    } else {
      try {
        final settings = AppThemeScope.of(context);
        primary = settings.seedColor;
      } catch (_) {
        primary = CupertinoTheme.of(context).primaryColor;
      }
    }

    final HSLColor hsl = HSLColor.fromColor(primary);
    final Color secondary = hsl.withHue((hsl.hue + 32) % 360).toColor();
    final Color tertiary = hsl.withHue((hsl.hue - 28 + 360) % 360).toColor();

    final Color baseBg = isDark
        ? (Color.lerp(const Color(0xFF090D16), primary, 0.07) ??
            const Color(0xFF090D16))
        : (Color.lerp(const Color(0xFFF3F5FA), primary, 0.04) ??
            const Color(0xFFF3F5FA));

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: baseBg,
          ),
        ),
        Positioned(
          top: -80,
          right: -60,
          child: Container(
            width: 380,
            height: 380,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: isDark
                    ? [
                        primary.withValues(alpha: 0.50),
                        primary.withValues(alpha: 0.18),
                        const Color(0x00000000),
                      ]
                    : [
                        primary.withValues(alpha: 0.28),
                        primary.withValues(alpha: 0.09),
                        const Color(0x00FFFFFF),
                      ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 260,
          left: -100,
          child: Container(
            width: 340,
            height: 340,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: isDark
                    ? [
                        secondary.withValues(alpha: 0.42),
                        secondary.withValues(alpha: 0.15),
                        const Color(0x00000000),
                      ]
                    : [
                        secondary.withValues(alpha: 0.22),
                        secondary.withValues(alpha: 0.07),
                        const Color(0x00FFFFFF),
                      ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -100,
          right: -50,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: isDark
                    ? [
                        tertiary.withValues(alpha: 0.38),
                        tertiary.withValues(alpha: 0.12),
                        const Color(0x00000000),
                      ]
                    : [
                        tertiary.withValues(alpha: 0.18),
                        tertiary.withValues(alpha: 0.05),
                        const Color(0x00FFFFFF),
                      ],
              ),
            ),
          ),
        ),
        if (child != null) child!,
      ],
    );
  }
}

/// A specialized iOS 27 glass platter card with subtle specular border rim.
class Ios27GlassCard extends StatelessWidget {
  /// The content displayed inside the glass platter.
  final Widget child;

  /// Internal padding for the card content.
  final EdgeInsetsGeometry padding;

  /// Optional margin surrounding the card.
  final EdgeInsetsGeometry margin;

  /// Corner radius matching iOS continuous squircle curvature.
  final double borderRadius;

  /// Quality tier for glass shader compilation.
  final GlassQuality quality;

  /// Width of the glass card platter. Defaults to [double.infinity] to span full available width.
  final double? width;

  /// Creates a premium iOS 27 glass platter card.
  const Ios27GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin = const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
    this.borderRadius = 24.0,
    this.quality = GlassQuality.standard,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark =
        CupertinoTheme.of(context).brightness == Brightness.dark;

    return Container(
      width: width,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isDark
              ? CupertinoColors.white.withValues(alpha: 0.12)
              : CupertinoColors.white.withValues(alpha: 0.45),
          width: 0.8,
        ),
      ),
      child: GlassCard(
        width: width,
        padding: padding,
        margin: EdgeInsets.zero,
        shape: LiquidRoundedSuperellipse(borderRadius: borderRadius),
        useOwnLayer: true,
        quality: quality,
        settings: LiquidGlassSettings(
          thickness: 16,
          blur: 18,
          refractiveIndex: 1.16,
          lightIntensity: isDark ? 0.45 : 0.60,
          fresnelStrength: isDark ? 0.35 : 0.45,
          chromaticAberration: 0.04,
        ),
        child: width == double.infinity
            ? SizedBox(
                width: double.infinity,
                child: child,
              )
            : child,
      ),
    );
  }
}

/// Clean iOS 27 section header with crisp typography.
class Ios27SectionHeader extends StatelessWidget {
  /// Main headline label.
  final String title;

  /// Optional trailing action button or badge.
  final Widget? trailing;

  /// Creates a section header conforming to iOS 27 Human Interface Guidelines.
  const Ios27SectionHeader({
    super.key,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: isDark ? CupertinoColors.white : const Color(0xFF1C1C1E),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Interactive iOS 27 Liquid Glass button with specular border rim and tap response.
class Ios27GlassButton extends StatelessWidget {
  /// Callback triggered when button is tapped.
  final VoidCallback? onPressed;

  /// Child widget inside the glass button platter.
  final Widget child;

  /// Internal padding for the button content.
  final EdgeInsetsGeometry padding;

  /// Continuous squircle corner radius.
  final double borderRadius;

  /// Creates a premium iOS 27 glass button.
  const Ios27GlassButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    this.borderRadius = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark =
        CupertinoTheme.of(context).brightness == Brightness.dark;

    return GlassCard(
      padding: padding,
      shape: LiquidRoundedSuperellipse(borderRadius: borderRadius),
      useOwnLayer: true,
      clipBehavior: Clip.antiAlias,
      settings: LiquidGlassSettings(
        thickness: 14,
        blur: 16,
        refractiveIndex: 1.16,
        lightIntensity: isDark ? 0.45 : 0.60,
        fresnelStrength: isDark ? 0.35 : 0.45,
        chromaticAberration: 0.04,
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        onPressed: onPressed,
        child: child,
      ),
    );
  }
}
