import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:flutter/cupertino.dart';

import 'ios27_glass_surface.dart';

/**
 * Dedicated iOS Liquid Glass Splash Screen for the Employee Mobile Application
 */
class EmployeeSplashScreen extends StatefulWidget {
  /**
   * Creates an authentic iOS splash screen
   */
  const EmployeeSplashScreen({super.key});

  @override
  State<EmployeeSplashScreen> createState() => _EmployeeSplashScreenState();
}

class _EmployeeSplashScreenState extends State<EmployeeSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.02).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.25, end: 0.55).animate(
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

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.transparent,
      child: Ios27Background(
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      primary.withValues(
                                        alpha: _glowAnimation.value,
                                      ),
                                      primary.withValues(alpha: 0.0),
                                    ],
                                  ),
                                ),
                              ),
                              GlassCard(
                                width: 104,
                                height: 104,
                                padding: EdgeInsets.zero,
                                shape: const LiquidRoundedSuperellipse(
                                  borderRadius: 32,
                                ),
                                useOwnLayer: true,
                                settings: LiquidGlassSettings(
                                  thickness: 20,
                                  blur: 20,
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
                                      size: 54,
                                      color: CupertinoColors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'MKX HRMS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.0,
                        color: isDark
                            ? CupertinoColors.white
                            : const Color(0xFF0B132B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Enterprise Employee Self-Service',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.2,
                        color: isDark
                            ? CupertinoColors.white.withValues(alpha: 0.55)
                            : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 48),
                    const CupertinoActivityIndicator(
                      radius: 12,
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Secured by MKX Quantum Shield',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.1,
                      color: isDark
                          ? CupertinoColors.white.withValues(alpha: 0.30)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
