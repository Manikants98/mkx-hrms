import 'package:flutter/cupertino.dart';
import 'ios27_glass_surface.dart';

/**
 * Reusable top navigation header bar featuring iOS 27 Liquid Glass aesthetic.
 * Supports eyebrow subtitles, primary titles, back button navigation, and trailing actions.
 */
class Ios27AppBar extends StatelessWidget implements PreferredSizeWidget {
  /**
   * Main title text
   */
  final String? title;

  /**
   * Custom title widget if non-text header content is needed
   */
  final Widget? titleWidget;

  /**
   * Optional eyebrow subtitle text
   */
  final String? subtitle;

  /**
   * Custom subtitle widget
   */
  final Widget? subtitleWidget;

  /**
   * Whether the subtitle is displayed below the title instead of above
   */
  final bool subtitleBelow;

  /**
   * Optional custom leading widget (takes precedence over back button)
   */
  final Widget? leading;

  /**
   * Whether to display a liquid glass back button
   */
  final bool showBackButton;

  /**
   * Callback invoked when the default back button is tapped
   */
  final VoidCallback? onBack;

  /**
   * Single trailing action widget
   */
  final Widget? trailing;

  /**
   * List of trailing action widgets
   */
  final List<Widget>? actions;

  /**
   * External padding around the app bar
   */
  final EdgeInsetsGeometry padding;

  /**
   * Custom text style override for the title
   */
  final TextStyle? titleStyle;

  /**
   * Custom text style override for the subtitle
   */
  final TextStyle? subtitleStyle;

  /**
   * Constructs an iOS 27 liquid glass header app bar
   */
  const Ios27AppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.subtitle,
    this.subtitleWidget,
    this.subtitleBelow = true,
    this.leading,
    this.showBackButton = false,
    this.onBack,
    this.trailing,
    this.actions,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    this.titleStyle,
    this.subtitleStyle,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final bool isDark =
        CupertinoTheme.of(context).brightness == Brightness.dark;

    Widget? leadingWidget = leading;
    if (leadingWidget == null && showBackButton) {
      leadingWidget = Ios27GlassIconButton(
        icon: Icon(
          CupertinoIcons.chevron_back,
          size: 20,
          color: isDark ? CupertinoColors.white : const Color(0xFF1C1C1E),
        ),
        onPressed: onBack ?? () => Navigator.of(context).maybePop(),
      );
    }

    Widget? trailingWidget = trailing;
    if (trailingWidget == null && actions != null && actions!.isNotEmpty) {
      trailingWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: actions!,
      );
    }

    final Widget? renderedSubtitle = subtitleWidget ??
        (subtitle != null
            ? Text(
                subtitle!,
                style: subtitleStyle ??
                    TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFF8E8E93)
                          : const Color(0xFF6E6E73),
                      letterSpacing: -0.2,
                    ),
              )
            : null);

    final Widget? renderedTitle = titleWidget ??
        (title != null
            ? Text(
                title!,
                style: titleStyle ??
                    TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      color: isDark
                          ? CupertinoColors.white
                          : const Color(0xFF1C1C1E),
                    ),
              )
            : null);

    final List<Widget> titleContent = <Widget>[
      if (!subtitleBelow && renderedSubtitle != null) ...<Widget>[
        renderedSubtitle,
        const SizedBox(height: 2),
      ],
      if (renderedTitle != null) renderedTitle,
      if (subtitleBelow && renderedSubtitle != null) ...<Widget>[
        const SizedBox(height: 2),
        renderedSubtitle,
      ],
    ];

    return Padding(
      padding: padding,
      child: Row(
        children: <Widget>[
          if (leadingWidget != null) ...<Widget>[
            leadingWidget,
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: titleContent,
            ),
          ),
          if (trailingWidget != null) trailingWidget,
        ],
      ),
    );
  }
}
