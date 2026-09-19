import 'package:flutter/material.dart';

/// Professional avatar widget with rounded corners (default 8px) and initial fallback using system fonts.
class AppAvatar extends StatelessWidget {
  /// Full name or display label used to generate the initial letter.
  final String name;

  /// Optional remote URL for the employee profile picture.
  final String? imageUrl;

  /// Width and height of the avatar box in logical pixels.
  final double size;

  /// Corner radius of the avatar container. Defaults to 8.0px.
  final double borderRadius;

  /// Background color for the avatar box. Defaults to primary color with 12% opacity.
  final Color? backgroundColor;

  /// Text color for the initial letter. Defaults to primary color.
  final Color? foregroundColor;

  /// Custom font size for the initial text.
  final double? fontSize;

  /// Custom font weight for the initial text.
  final FontWeight fontWeight;

  /// Creates a unified rounded avatar widget.
  const AppAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 40.0,
    this.borderRadius = 8.0,
    this.backgroundColor,
    this.foregroundColor,
    this.fontSize,
    this.fontWeight = FontWeight.w700,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final effectiveBg = backgroundColor ?? primary.withValues(alpha: 0.12);
    final effectiveFg = foregroundColor ?? primary;
    final effectiveFontSize = fontSize ?? (size * 0.38);

    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

    final radius = BorderRadius.circular(borderRadius);

    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.network(
          imageUrl!.trim(),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder:
              (BuildContext context, Object error, StackTrace? stackTrace) {
                return _buildInitialContainer(
                  effectiveBg,
                  effectiveFg,
                  effectiveFontSize,
                  initial,
                  radius,
                );
              },
        ),
      );
    }

    return _buildInitialContainer(
      effectiveBg,
      effectiveFg,
      effectiveFontSize,
      initial,
      radius,
    );
  }

  Widget _buildInitialContainer(
    Color bg,
    Color fg,
    double fs,
    String initial,
    BorderRadius radius,
  ) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, borderRadius: radius),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: fs,
          fontWeight: fontWeight,
          color: fg,
        ),
      ),
    );
  }
}
