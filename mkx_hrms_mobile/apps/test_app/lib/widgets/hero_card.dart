import 'package:flutter/cupertino.dart';

/// Apple Music Logo component with Cupertino music note and bold typography.
class AppleMusicLogo extends StatelessWidget {
  /// Constructor for AppleMusicLogo.
  const AppleMusicLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          CupertinoIcons.music_note,
          color: CupertinoColors.label.resolveFrom(context),
          size: 56,
        ),
        Text(
          'Music',
          style: TextStyle(
            color: CupertinoColors.label.resolveFrom(context),
            fontSize: 52,
            fontWeight: FontWeight.w700,
            letterSpacing: -1,
          ),
        ),
      ],
    );
  }
}

/// Hero Card component matching Apple Music iOS 27 promotional banner style.
class HeroCard extends StatelessWidget {
  /// Main title text.
  final String title;

  /// Subtitle headline text.
  final String subtitle;

  /// Subtext detail text.
  final String subtext;

  /// Optional solid color.
  final Color? color;

  /// Optional background gradient.
  final Gradient? gradient;

  /// Optional text color override.
  final Color? textColor;

  /// Child widget displayed in center.
  final Widget child;

  /// Whether to render a subtle border.
  final bool showBorder;

  /// Constructor for HeroCard.
  const HeroCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.subtext,
    required this.child,
    this.color,
    this.gradient,
    this.textColor,
    this.showBorder = false,
  }) : assert(color != null || gradient != null, 'Provide color or gradient');

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 380,
      decoration: BoxDecoration(
        color: color,
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        border: showBorder
            ? Border.all(
                color: CupertinoColors.label
                    .resolveFrom(context)
                    .withValues(alpha: 0.15),
                width: 1.0,
              )
            : null,
      ),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor ?? CupertinoColors.label.resolveFrom(context),
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: Center(child: child)),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: textColor ?? CupertinoColors.label.resolveFrom(context),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtext,
            style: TextStyle(
              color: (textColor ?? CupertinoColors.label.resolveFrom(context))
                  .withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
