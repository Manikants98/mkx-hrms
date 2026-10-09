import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/**
 * Authentic iOS 27 Liquid Glass Segmented Control
 * Utilizes the official Liquid Glass engine with jelly physics, glass refraction,
 * and high-contrast color calibration for both Dark and Light modes.
 */
class Ios27SegmentedControl extends StatelessWidget {
  /**
   * The list of segment tab labels.
   */
  final List<String> segments;

  /**
   * The currently active segment index.
   */
  final int selectedIndex;

  /**
   * Callback fired when a segment is tapped.
   */
  final ValueChanged<int> onSegmentSelected;

  /**
   * Optional custom height for the segmented control.
   */
  final double height;

  /**
   * Creates an authentic iOS 27 Liquid Glass segmented control.
   */
  const Ios27SegmentedControl({
    super.key,
    required this.segments,
    required this.selectedIndex,
    required this.onSegmentSelected,
    this.height = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty) return const SizedBox.shrink();

    final bool isDark =
        CupertinoTheme.of(context).brightness == Brightness.dark;
    final int safeIndex =
        (selectedIndex >= 0 && selectedIndex < segments.length)
            ? selectedIndex
            : 0;

    if (segments.length < 2) {
      return Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF161B26).withValues(alpha: 0.70)
              : CupertinoColors.white.withValues(alpha: 0.60),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? CupertinoColors.white.withValues(alpha: 0.14)
                : CupertinoColors.white.withValues(alpha: 0.85),
            width: 0.8,
          ),
        ),
        child: Text(
          segments.first,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? CupertinoColors.white : const Color(0xFF1C1C1E),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? CupertinoColors.white.withValues(alpha: 0.14)
              : CupertinoColors.white.withValues(alpha: 0.85),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? CupertinoColors.black.withValues(alpha: 0.35)
                : const Color(0x12000000),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: GlassSegmentedControl(
        segments:
            segments.map((String label) => GlassSegment(label: label)).toList(),
        selectedIndex: safeIndex,
        onSegmentSelected: (int index) {
          HapticFeedback.selectionClick();
          onSegmentSelected(index);
        },
        height: height,
        borderRadius: 13,
        indicatorBorderRadius: 10,
        useOwnLayer: true,
        backgroundColor: isDark
            ? const Color(0xFF161B26).withValues(alpha: 0.70)
            : CupertinoColors.white.withValues(alpha: 0.60),
        indicatorColor: isDark
            ? CupertinoColors.white.withValues(alpha: 0.22)
            : CupertinoColors.white.withValues(alpha: 0.95),
        glowColor: isDark
            ? CupertinoColors.white.withValues(alpha: 0.35)
            : CupertinoColors.white.withValues(alpha: 0.80),
        selectedTextStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: isDark ? CupertinoColors.white : const Color(0xFF1C1C1E),
          letterSpacing: -0.2,
        ),
        unselectedTextStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: isDark ? const Color(0xFF98989D) : const Color(0xFF6E6E73),
          letterSpacing: -0.2,
        ),
        settings: const LiquidGlassSettings(
          thickness: 25,
          blur: 16,
          refractiveIndex: 1.25,
          lightIntensity: 1.8,
          chromaticAberration: 0.35,
        ),
        indicatorSettings: const LiquidGlassSettings(
          thickness: 20,
          blur: 12,
          refractiveIndex: 1.20,
          lightIntensity: 2.0,
          chromaticAberration: 0.30,
        ),
      ),
    );
  }
}
