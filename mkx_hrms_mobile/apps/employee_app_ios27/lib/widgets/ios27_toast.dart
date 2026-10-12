import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:mkx_core/utils/ui_helpers.dart';

/**
 * Authentic iOS Dynamic Island frosted glass pill HUD toast notification
 */
class Ios27Toast {
  static OverlayEntry? _currentEntry;

  /**
   * Displays an authentic top-anchored iOS glass pill HUD toast
   *
   * @param context Build context to anchor the overlay
   * @param message Text message to display
   * @param isError Whether to display an error theme
   * @param isSuccess Whether to display a success theme
   * @param duration Display duration before auto dismiss
   */
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
    bool isSuccess = false,
    Duration duration = const Duration(milliseconds: 2800),
  }) {
    try {
      if (_currentEntry != null && _currentEntry!.mounted) {
        _currentEntry!.remove();
      }
    } catch (_) {}
    _currentEntry = null;

    final overlay = Overlay.maybeOf(context, rootOverlay: true) ??
        Overlay.maybeOf(context) ??
        UiHelpers.rootNavigatorKey.currentState?.overlay;

    if (overlay == null) return;

    final directionality = Directionality.maybeOf(context) ?? TextDirection.ltr;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => Directionality(
        textDirection: directionality,
        child: _IosToastWidget(
          message: message,
          isError: isError,
          isSuccess: isSuccess,
          duration: duration,
          onDismissed: () {
            if (_currentEntry == entry) {
              try {
                if (entry.mounted) {
                  entry.remove();
                }
              } catch (_) {}
              _currentEntry = null;
            }
          },
        ),
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }
}

class _IosToastWidget extends StatefulWidget {
  final String message;
  final bool isError;
  final bool isSuccess;
  final Duration duration;
  final VoidCallback onDismissed;

  const _IosToastWidget({
    required this.message,
    required this.isError,
    required this.isSuccess,
    required this.duration,
    required this.onDismissed,
  });

  @override
  State<_IosToastWidget> createState() => _IosToastWidgetState();
}

class _IosToastWidgetState extends State<_IosToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _translateAnimation;
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      reverseDuration: const Duration(milliseconds: 280),
    );

    _translateAnimation = Tween<double>(begin: -60, end: 0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOut,
      ),
    );

    _animController.forward();

    Future.delayed(widget.duration, () {
      if (mounted) {
        _animController.reverse().then((_) {
          if (mounted) {
            widget.onDismissed();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _dismissManually() {
    _animController.reverse().then((_) {
      if (mounted) {
        widget.onDismissed();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding =
        mediaQuery.padding.top > 0 ? mediaQuery.padding.top + 8 : 24.0;
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    final Color accentColor = widget.isError
        ? CupertinoColors.systemRed
        : (widget.isSuccess
            ? const Color(0xFF34C759)
            : const Color(0xFF007AFF));

    final IconData icon = widget.isError
        ? CupertinoIcons.xmark_circle_fill
        : (widget.isSuccess
            ? CupertinoIcons.checkmark_alt_circle_fill
            : CupertinoIcons.info_circle_fill);

    return Positioned(
      top: topPadding,
      left: 16,
      right: 16,
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _translateAnimation.value),
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: child,
              ),
            ),
          );
        },
        child: GestureDetector(
          onVerticalDragUpdate: (details) {
            if (details.primaryDelta != null && details.primaryDelta! < -4) {
              _dismissManually();
            }
          },
          onTap: _dismissManually,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
                shape: const LiquidRoundedSuperellipse(borderRadius: 28),
                useOwnLayer: true,
                settings: LiquidGlassSettings(
                  thickness: 16,
                  blur: 20,
                  refractiveIndex: 1.16,
                  lightIntensity: isDark ? 0.45 : 0.60,
                  fresnelStrength: isDark ? 0.35 : 0.45,
                  chromaticAberration: 0.04,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            accentColor.withValues(alpha: isDark ? 0.20 : 0.12),
                      ),
                      child: Icon(
                        icon,
                        size: 18,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        widget.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                          color: isDark
                              ? CupertinoColors.white
                              : const Color(0xFF0F172A),
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
