import 'dart:ui';
import 'package:flutter/cupertino.dart';

/// iOS 27 Liquid Glass semantic status badge with translucent frosted pill styling.
class Ios27StatusBadge extends StatelessWidget {
  /// The textual status to display.
  final String status;

  /// Font size for the badge text.
  final double fontSize;

  /// Inner padding of the badge pill.
  final EdgeInsetsGeometry padding;

  /// Border radius of the pill capsule.
  final double borderRadius;

  /// Whether to display a tiny glowing indicator dot alongside the label.
  final bool showDot;

  /// Creates an iOS 27 styled glass status pill badge.
  const Ios27StatusBadge({
    super.key,
    required this.status,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
    this.borderRadius = 100.0,
    this.showDot = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark =
        CupertinoTheme.of(context).brightness == Brightness.dark;
    final String normalized = status.trim().toLowerCase();

    Color accentColor;

    if (normalized == 'present' ||
        normalized == 'approved' ||
        normalized == 'active' ||
        normalized == 'processed' ||
        normalized == 'paid' ||
        normalized == 'completed') {
      accentColor = const Color(0xFF34C759);
    } else if (normalized == 'late' ||
        normalized == 'pending' ||
        normalized == 'screening' ||
        normalized == 'in progress') {
      accentColor = const Color(0xFFFF9500);
    } else if (normalized == 'absent' ||
        normalized == 'rejected' ||
        normalized == 'inactive' ||
        normalized == 'failed' ||
        normalized == 'cancelled') {
      accentColor = const Color(0xFFFF3B30);
    } else if (normalized == 'on hold' ||
        normalized == 'remote' ||
        normalized == 'half day') {
      accentColor = const Color(0xFFAF52DE);
    } else if (normalized == 'holiday' ||
        normalized == 'weekend' ||
        normalized == 'leave') {
      accentColor = const Color(0xFF007AFF);
    } else {
      accentColor = isDark ? const Color(0xFF98989D) : const Color(0xFF636366);
    }

    final Color bgColor = accentColor.withValues(
      alpha: isDark ? 0.16 : 0.10,
    );
    final Color borderColor = accentColor.withValues(
      alpha: isDark ? 0.32 : 0.22,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor,
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (showDot) ...[
                Container(
                  width: 5.5,
                  height: 5.5,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.6),
                        blurRadius: 3,
                        spreadRadius: 0.5,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
              ],
              Text(
                status,
                style: TextStyle(
                  color: accentColor,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
