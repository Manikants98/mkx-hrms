import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Material Design 3 Expressive Loading Indicator.
///
/// Implements the official M3 shape-morphing animation that smoothly oscillates
/// between a 4-point lobed squircle and an 8-point scalloped star with continuous
/// rotation and organic pulse dynamics.
///
/// Offers two standard display variants:
/// 1. Standard: Uncontained vector morphing loader.
/// 2. Contained: Morphing loader enclosed inside a circular tinted container.
class AppLoader extends StatefulWidget {
  /// Diameter of the loader widget.
  final double size;

  /// Primary fill color for the morphing shape.
  /// If null, defaults to [ColorScheme.primary].
  final Color? color;

  /// Whether the loader is wrapped in a circular tinted container.
  final bool isContained;

  /// Background color of the container circle when [isContained] is true.
  /// If null, a subtle tint of the primary [color] is computed.
  final Color? containerColor;

  /// Optional accessibility label for screen readers.
  final String? semanticLabel;

  /// Creates a standard uncontained Material 3 Expressive loading indicator.
  const AppLoader({
    super.key,
    this.size = 36.0,
    this.color,
    this.semanticLabel = 'Loading',
  })  : isContained = false,
        containerColor = null;

  /// Creates a contained Material 3 Expressive loading indicator with a circular container.
  const AppLoader.contained({
    super.key,
    this.size = 48.0,
    this.color,
    this.containerColor,
    this.semanticLabel = 'Loading',
  }) : isContained = true;

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = widget.color ?? theme.colorScheme.primary;

    final shapeWidget = Semantics(
      label: widget.semanticLabel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          final progress = _controller.value;
          final morphProgress = (1.0 - math.cos(progress * 2 * math.pi)) / 2.0;
          final rotationAngle = progress * 2 * math.pi;
          final scale = 0.94 + 0.08 * math.sin(progress * 2 * math.pi).abs();

          final shapeSize = widget.isContained ? widget.size * 0.62 : widget.size;

          return Transform.scale(
            scale: scale,
            child: SizedBox(
              width: shapeSize,
              height: shapeSize,
              child: CustomPaint(
                painter: _M3MorphingShapePainter(
                  morphProgress: morphProgress,
                  rotationAngle: rotationAngle,
                  color: effectiveColor,
                ),
              ),
            ),
          );
        },
      ),
    );

    if (!widget.isContained) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: Center(child: shapeWidget),
      );
    }

    final isDark = theme.brightness == Brightness.dark;
    final effectiveContainerColor = widget.containerColor ??
        effectiveColor.withValues(alpha: isDark ? 0.22 : 0.14);

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: effectiveContainerColor,
      ),
      alignment: Alignment.center,
      child: shapeWidget,
    );
  }
}

/// Custom painter for the Material 3 morphing curve.
class _M3MorphingShapePainter extends CustomPainter {
  final double morphProgress;
  final double rotationAngle;
  final Color color;

  _M3MorphingShapePainter({
    required this.morphProgress,
    required this.rotationAngle,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = math.min(size.width, size.height) / 2;

    final m = morphProgress;
    final a4 = (1.0 - m) * 0.21;
    final a8 = 0.03 + m * 0.11;
    final c = 0.81 - m * 0.03;

    final path = Path();
    const pointCount = 96;

    for (int i = 0; i < pointCount; i++) {
      final theta = (i * 2 * math.pi) / pointCount;
      final effectiveTheta = theta - rotationAngle;

      final rFactor = c +
          a4 * math.cos(4 * effectiveTheta) +
          a8 * math.cos(8 * effectiveTheta);
      final r = baseRadius * rFactor;

      final x = center.dx + r * math.cos(theta);
      final y = center.dy + r * math.sin(theta);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _M3MorphingShapePainter oldDelegate) {
    return oldDelegate.morphProgress != morphProgress ||
        oldDelegate.rotationAngle != rotationAngle ||
        oldDelegate.color != color;
  }
}

/// Alias for developers accustomed to the [M3Loader] name.
typedef M3Loader = AppLoader;
