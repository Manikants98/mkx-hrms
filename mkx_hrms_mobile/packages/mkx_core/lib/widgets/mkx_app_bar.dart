import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_3_expressive/components/app_bars/m3e_app_bars.dart';
import 'package:material_3_expressive/foundations/theme/m3e_theme.dart';
import 'app_skeleton.dart';

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

  /// Whether to automatically imply a back button. Defaults to true.
  final bool automaticallyImplyLeading;

  /// Whether to include the skeleton toggle action in the app bar. Defaults to true.
  final bool showSkeletonToggle;

  const MkxAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.showBorder = true,
    this.automaticallyImplyLeading = true,
    this.showSkeletonToggle = true,
  });

  @override
  Size get preferredSize => Size.fromHeight(subtitle != null ? 64 : 56);

  @override
  Widget build(BuildContext context) {
    final colorScheme = M3ETheme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    final fgColor = colorScheme.onSurface;
    final mutedColor =
        isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6E6E73);

    SystemChrome.setSystemUIOverlayStyle(
      isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    );

    Widget titleWidget = Text(
      title,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: fgColor,
      ),
    );

    if (subtitle != null) {
      titleWidget = Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            titleWidget,
            const SizedBox(height: 1),
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: mutedColor,
              ),
            ),
          ],
        ),
      );
    }

    Widget? effectiveLeading = leading;
    if (automaticallyImplyLeading && effectiveLeading == null) {
      final ModalRoute<dynamic>? parentRoute = ModalRoute.of(context);
      if (parentRoute?.canPop ?? false) {
        effectiveLeading = IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: colorScheme.onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
        );
      }
    }

    final List<Widget> effectiveActions = [
      if (showSkeletonToggle)
        ValueListenableBuilder<bool>(
          valueListenable: SkeletonConfig.isEnabled,
          builder: (context, enabled, _) {
            return IconButton(
              icon: Icon(
                enabled ? Icons.auto_awesome : Icons.auto_awesome_outlined,
              ),
              tooltip: enabled ? 'Show Real Data' : 'Show Skeleton',
              color: colorScheme.onSurface,
              onPressed: SkeletonConfig.toggle,
            );
          },
        ),
      if (actions != null) ...actions!,
    ];

    return M3EAppBar.top(
      title: titleWidget,
      leading: effectiveLeading,
      actions: effectiveActions.isEmpty ? null : effectiveActions,
    );
  }
}
