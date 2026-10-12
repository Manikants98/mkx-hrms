import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:flutter/cupertino.dart';

/**
 * Brand header banner for the employee login experience
 */
class Ios27LoginHeader extends StatelessWidget {
  /**
   * Title text representing corporate portal identity
   */
  final String title;

  /**
   * Subtitle text with enterprise descriptor
   */
  final String subtitle;

  /**
   * Creates an authentic brand header
   */
  const Ios27LoginHeader({
    super.key,
    this.title = 'MKX HRMS',
    this.subtitle = 'Enterprise Employee Self-Service',
  });

  @override
  Widget build(BuildContext context) {
    final cupertinoTheme = CupertinoTheme.of(context);
    final primary = cupertinoTheme.primaryColor;
    final isDark = cupertinoTheme.brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    primary.withValues(alpha: isDark ? 0.45 : 0.28),
                    primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
            GlassCard(
              width: 72,
              height: 72,
              padding: EdgeInsets.zero,
              shape: const LiquidRoundedSuperellipse(borderRadius: 24),
              useOwnLayer: true,
              settings: LiquidGlassSettings(
                thickness: 18,
                blur: 18,
                refractiveIndex: 1.18,
                lightIntensity: isDark ? 0.50 : 0.65,
                fresnelStrength: isDark ? 0.35 : 0.45,
                chromaticAberration: 0.05,
              ),
              child: Center(
                child: ShaderMask(
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      colors: [
                        primary,
                        const Color(0xFF8B5CF6),
                        const Color(0xFF06B6D4),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds);
                  },
                  child: const Icon(
                    CupertinoIcons.shield_lefthalf_fill,
                    size: 38,
                    color: CupertinoColors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: isDark ? CupertinoColors.white : const Color(0xFF0B132B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark
                ? CupertinoColors.white.withValues(alpha: 0.60)
                : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}
