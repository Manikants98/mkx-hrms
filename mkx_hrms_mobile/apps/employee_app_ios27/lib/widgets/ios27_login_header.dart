import 'dart:ui';
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
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E2438).withValues(alpha: 0.82)
                        : CupertinoColors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark
                          ? CupertinoColors.white.withValues(alpha: 0.25)
                          : CupertinoColors.white.withValues(alpha: 0.90),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: isDark ? 0.35 : 0.22),
                        blurRadius: 22,
                        offset: const Offset(0, 8),
                      ),
                    ],
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
