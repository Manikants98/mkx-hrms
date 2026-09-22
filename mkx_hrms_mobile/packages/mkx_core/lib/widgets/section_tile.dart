import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Position of a [SectionTile] within a group — kept for API compatibility,
/// but no longer affects per-tile corner radii (the [SectionCard] wrapper
/// clips the whole group).
enum TilePosition {
  /// First tile in the group.
  first,

  /// A middle tile.
  middle,

  /// Last tile in the group.
  last,

  /// The only tile in the group — all corners are rounded.
  only,
}

/// A single flat tile row.
///
/// When used **standalone** (`position == TilePosition.only`) it renders with
/// rounded corners on all sides, matching a standalone card.
///
/// When used **inside [SectionCard]** the outer [ClipRRect] provides the
/// group's rounded corners; the tile itself is flat — no side borders, no
/// per-tile corner radius — matching the Gmail / iOS Settings style where
/// only thin horizontal dividers separate rows.
class SectionTile extends StatelessWidget {
  /// Creates a [SectionTile].
  const SectionTile({
    super.key,
    required this.child,
    required this.isDark,
    this.position = TilePosition.only,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  });

  /// The widget displayed inside the tile.
  final Widget child;

  /// Whether the current theme is dark.
  final bool isDark;

  /// The position of this tile within its group.
  final TilePosition position;

  /// Internal padding of the tile.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;

    // Standalone tiles keep all-round corners; grouped tiles are flat.
    final isStandalone = position == TilePosition.only;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius:
            isStandalone ? BorderRadius.circular(14) : BorderRadius.circular(3),
      ),
      child: child,
    );
  }
}

/// Wraps a list of [children] into a vertically grouped tile list.
///
/// The entire group is clipped to rounded corners. Inside the group, each row
/// is a flat [SectionTile] with a **thin horizontal divider** between rows —
/// no side borders, matching the Gmail inbox / iOS Settings grouped list style.
class SectionCard extends StatelessWidget {
  /// Creates a [SectionCard] from a list of raw [Widget] children.
  const SectionCard({
    super.key,
    required this.children,
    required this.isDark,
    this.tilePadding,
  });

  /// The content widgets to display as individual tile rows.
  final List<Widget> children;

  /// Whether the current theme is dark.
  final bool isDark;

  /// Optional override for each tile's internal padding.
  final EdgeInsetsGeometry? tilePadding;

  TilePosition _position(int index, int total) {
    if (total == 1) return TilePosition.only;
    if (index == 0) return TilePosition.first;
    if (index == total - 1) return TilePosition.last;
    return TilePosition.middle;
  }

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final total = children.length;
    final dividerColor = scheme.surfaceContainer;
    final defaultPadding =
        tilePadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 14);

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < total; i++) ...[
            SectionTile(
              isDark: isDark,
              position: _position(i, total),
              padding: defaultPadding,
              child: children[i],
            ),
            if (i < total - 1) Container(height: 4, color: dividerColor),
          ],
        ],
      ),
    );
  }
}
