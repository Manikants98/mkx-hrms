import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import 'package:mkx_core/features/auth/state/auth_provider.dart';

/// Data model representing an individual onboarding slide item.
class OnboardingSlide {
  /// Asset path to the Storyset vector SVG illustration.
  final String assetPath;

  /// Header category pill text.
  final String categoryBadge;

  /// Leading icon for the category badge.
  final IconData badgeIcon;

  /// Main headline title.
  final String title;

  /// Informative explanatory description.
  final String description;

  /// Accent highlight color override if needed.
  final Color? accentColor;

  /// Creates an onboarding slide configuration.
  const OnboardingSlide({
    required this.assetPath,
    required this.categoryBadge,
    required this.badgeIcon,
    required this.title,
    required this.description,
    this.accentColor,
  });
}

/// First-launch onboarding screen for the employee application.
///
/// Features Storyset vector illustrations, interactive page sliding,
/// animated indicators, and persistent state transition.
class OnboardingScreen extends StatefulWidget {
  /// Optional callback invoked when the onboarding is finished or skipped.
  final VoidCallback? onComplete;

  /// Creates a new [OnboardingScreen] instance.
  const OnboardingScreen({
    super.key,
    this.onComplete,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  static const List<OnboardingSlide> _slides = [
    OnboardingSlide(
      assetPath: 'assets/illustrations/onboarding_company.svg',
      categoryBadge: 'DIGITAL WORKSPACE',
      badgeIcon: Icons.apartment_rounded,
      title: 'Empower Your Workday',
      description:
          'Welcome to MKX HRMS. Connect with your organization, explore corporate announcements, and access your workplace hub anytime, anywhere.',
    ),
    OnboardingSlide(
      assetPath: 'assets/illustrations/onboarding_employee.svg',
      categoryBadge: 'SMART ATTENDANCE',
      badgeIcon: Icons.schedule_rounded,
      title: 'Track Shifts in Real-Time',
      description:
          'Effortlessly punch in and out with live geolocation verification, track active daily work hours, and keep home screen widgets in continuous live sync.',
    ),
    OnboardingSlide(
      assetPath: 'assets/illustrations/onboarding_collaboration.svg',
      categoryBadge: 'LEAVES & APPROVALS',
      badgeIcon: Icons.verified_user_rounded,
      title: 'Seamless Collaboration',
      description:
          'Apply for leaves in seconds, check allowance balances, inspect payroll slips, and receive instant supervisor approvals on the go.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _handleFinish() async {
    HapticFeedback.mediumImpact();
    final auth = context.read<AuthProvider>();
    await auth.completeOnboarding();
    if (widget.onComplete != null) {
      widget.onComplete!();
    }
  }

  void _handleNext() {
    HapticFeedback.lightImpact();
    if (_currentIndex < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _handleFinish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            /// Header action bar with brand label and Skip control
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  /// Brand badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: isDark ? 0.16 : 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: scheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'MKX HRMS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: scheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// Skip action button
                  AnimatedOpacity(
                    opacity: _currentIndex < _slides.length - 1 ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: IgnorePointer(
                      ignoring: _currentIndex >= _slides.length - 1,
                      child: TextButton(
                        onPressed: _handleFinish,
                        style: TextButton.styleFrom(
                          foregroundColor: scheme.onSurfaceVariant,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// Scrollable illustration & informational slides
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: _onPageChanged,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return _buildSlideContent(
                    context: context,
                    slide: slide,
                    size: size,
                    scheme: scheme,
                    isDark: isDark,
                  );
                },
              ),
            ),

            /// Bottom navigation controls with animated dots and proceed button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// Page indicator dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (index) => _buildIndicatorDot(
                        isActive: index == _currentIndex,
                        scheme: scheme,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  /// Next or Get Started dynamic button
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.0, 0.2),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: _currentIndex == _slides.length - 1
                        ? SizedBox(
                            key: const ValueKey('get_started_btn'),
                            width: double.infinity,
                            height: 56,
                            child: FilledButton(
                              onPressed: _handleFinish,
                              style: FilledButton.styleFrom(
                                backgroundColor: scheme.primary,
                                foregroundColor: scheme.onPrimary,
                                elevation: 2,
                                shadowColor: scheme.primary.withValues(alpha: 0.35),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Get Started',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                      color: scheme.onPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 20,
                                    color: scheme.onPrimary,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SizedBox(
                            key: const ValueKey('next_btn'),
                            width: double.infinity,
                            height: 56,
                            child: FilledButton.tonal(
                              onPressed: _handleNext,
                              style: FilledButton.styleFrom(
                                backgroundColor: scheme.primaryContainer,
                                foregroundColor: scheme.onPrimaryContainer,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Next',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: scheme.onPrimaryContainer,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 18,
                                    color: scheme.onPrimaryContainer,
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the visual representation of an individual slide.
  Widget _buildSlideContent({
    required BuildContext context,
    required OnboardingSlide slide,
    required Size size,
    required ColorScheme scheme,
    required bool isDark,
  }) {
    final illustrationHeight = (size.height * 0.38).clamp(220.0, 360.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(),

          /// Illustration container with soft glow backdrop
          SizedBox(
            height: illustrationHeight,
            child: Stack(
              alignment: Alignment.center,
              children: [
                /// Radial background aura
                Container(
                  width: illustrationHeight * 0.85,
                  height: illustrationHeight * 0.85,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        scheme.primary.withValues(alpha: isDark ? 0.18 : 0.08),
                        scheme.primary.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),

                /// Storyset SVG Illustration
                SvgPicture.asset(
                  slide.assetPath,
                  package: 'mkx_core',
                  height: illustrationHeight,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),

          const Spacer(),

          /// Category badge pill
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  slide.badgeIcon,
                  size: 14,
                  color: scheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  slide.categoryBadge,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          /// Slide headline title
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              color: scheme.onSurface,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),

          /// Informational description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              slide.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: scheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }

  /// Builds a modern animated dot indicator for the carousel position.
  Widget _buildIndicatorDot({
    required bool isActive,
    required ColorScheme scheme,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 28 : 8,
      decoration: BoxDecoration(
        color: isActive
            ? scheme.primary
            : scheme.outlineVariant.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
