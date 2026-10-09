import 'dart:ui';
import 'package:flutter/cupertino.dart';

/**
 * Authentic iOS 27 Liquid Glass Loading Platter HUD with breathing ambient glow
 */
class Ios27GlassLoader extends StatefulWidget {
  /**
   * Optional loading caption message displayed beneath the activity indicator
   */
  final String? message;

  /**
   * Custom activity indicator size radius
   */
  final double radius;

  /**
   * Creates an authentic iOS 27 Liquid Glass loading platter
   */
  const Ios27GlassLoader({
    super.key,
    this.message,
    this.radius = 13.0,
  });

  @override
  State<Ios27GlassLoader> createState() => _Ios27GlassLoaderState();
}

class _Ios27GlassLoaderState extends State<Ios27GlassLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.12, end: 0.30).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cupertinoTheme = CupertinoTheme.of(context);
    final primary = cupertinoTheme.primaryColor;
    final isDark = cupertinoTheme.brightness == Brightness.dark;

    return Center(
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: _glowAnimation.value),
                  blurRadius: 28,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: child,
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 26,
                vertical: 20,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF151926).withValues(alpha: 0.72)
                    : CupertinoColors.white.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? CupertinoColors.white.withValues(alpha: 0.16)
                      : CupertinoColors.white.withValues(alpha: 0.85),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? CupertinoColors.black.withValues(alpha: 0.35)
                        : const Color(0x12000000),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CupertinoActivityIndicator(
                    radius: widget.radius,
                  ),
                  if (widget.message != null && widget.message!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      widget.message!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: isDark
                            ? CupertinoColors.white
                            : const Color(0xFF1C1C1E),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/**
 * High-performance iOS 27 loading wrapper seamlessly blending with the ambient background
 */
class Ios27PageLoader extends StatelessWidget {
  /**
   * Whether the asynchronous data is currently loading
   */
  final bool isLoading;

  /**
   * The destination page content rendered once data has loaded
   */
  final Widget child;

  /**
   * Loading status message displayed inside the glass capsule
   */
  final String? message;

  /**
   * Creates an authentic iOS 27 loading wrapper
   */
  const Ios27PageLoader({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: isLoading
          ? SizedBox.expand(
              key: const ValueKey('ios27_loading_state'),
              child: Ios27GlassLoader(
                message: message,
              ),
            )
          : KeyedSubtree(
              key: const ValueKey('ios27_loaded_content'),
              child: child,
            ),
    );
  }
}
