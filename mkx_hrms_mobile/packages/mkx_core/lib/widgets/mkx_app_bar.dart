import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Custom top app bar matching the MKX HRMS design system using system fonts.
///
/// Uses [ColorScheme.surface] (tile color) for its background so it
/// always matches the [SectionTile] and bottom nav surfaces, producing
/// a visually consistent chrome-vs-content separation.
class MkxAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Primary title displayed in the app bar.
  final String title;

  /// Optional subtitle rendered below the title in muted color.
  final String? subtitle;

  /// Optional widget placed at the leading position (defaults to back button if navigator can pop).
  final Widget? leading;

  /// Optional list of action widgets placed at the trailing end.
  final List<Widget>? actions;

  /// Whether to show the bottom divider border. Defaults to true.
  final bool showBorder;

  const MkxAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.showBorder = true,
  });

  @override
  Size get preferredSize => Size.fromHeight(subtitle != null ? 64 : 56);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    // surface = tile color (darkCard / lightCard), outline = border token
    final surfaceColor = colorScheme.surface;
    final fgColor = colorScheme.onSurface;
    final mutedColor = isDark
        ? const Color(0xFFA1A1AA)
        : const Color(0xFF6E6E73);

    SystemChrome.setSystemUIOverlayStyle(
      isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    );

    final canPop = Navigator.of(context).canPop();
    final hasLeading = leading != null || canPop;

    return Container(
      color: surfaceColor,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: preferredSize.height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (hasLeading)
                  leading ??
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 20,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        color: fgColor,
                      ),
                if (!hasLeading) const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: fgColor,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 1),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: mutedColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                ...?actions,
                if (actions == null) const SizedBox(width: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
