import 'package:flutter/cupertino.dart';

/**
 * Interactive iOS 27 fluid action button with spring physics and glass styling
 */
class Ios27Button extends StatefulWidget {
  /**
   * Action trigger callback
   */
  final VoidCallback? onPressed;

  /**
   * Button title label
   */
  final String label;

  /**
   * Optional leading icon widget
   */
  final Widget? icon;

  /**
   * Whether the button is actively executing an asynchronous task
   */
  final bool isLoading;

  /**
   * Optional custom gradient colors
   */
  final List<Color>? gradientColors;

  /**
   * Total button height
   */
  final double height;

  /**
   * Corner radius matching iOS continuous squircle curvature
   */
  final double borderRadius;

  /**
   * Creates an interactive iOS 27 button
   */
  const Ios27Button({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.isLoading = false,
    this.gradientColors,
    this.height = 52,
    this.borderRadius = 16,
  });

  @override
  State<Ios27Button> createState() => _Ios27ButtonState();
}

class _Ios27ButtonState extends State<Ios27Button>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.965).animate(
      CurvedAnimation(
        parent: _pressController,
        curve: Curves.easeInOutCubic,
        reverseCurve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.isLoading && widget.onPressed != null) {
      _pressController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _pressController.reverse();
  }

  void _handleTapCancel() {
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final cupertinoTheme = CupertinoTheme.of(context);
    final primary = cupertinoTheme.primaryColor;
    final isDark = cupertinoTheme.brightness == Brightness.dark;
    final isInteractive = widget.onPressed != null && !widget.isLoading;

    final defaultGradient = [
      primary,
      HSLColor.fromColor(primary)
          .withLightness((HSLColor.fromColor(primary).lightness +
                  (isDark ? 0.10 : -0.06))
              .clamp(0.0, 1.0))
          .toColor(),
    ];

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: isInteractive ? widget.onPressed : null,
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              colors: isInteractive
                  ? (widget.gradientColors ?? defaultGradient)
                  : [
                      isDark
                          ? const Color(0xFF282E3E)
                          : const Color(0xFFD5DCE6),
                      isDark
                          ? const Color(0xFF1E2330)
                          : const Color(0xFFC4CCD8),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: CupertinoColors.white.withValues(alpha: isDark ? 0.22 : 0.35),
              width: 0.8,
            ),
            boxShadow: [
              if (isInteractive)
                BoxShadow(
                  color: primary.withValues(alpha: isDark ? 0.40 : 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? const CupertinoActivityIndicator(
                    radius: 11,
                    color: CupertinoColors.white,
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        widget.icon!,
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: CupertinoColors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
