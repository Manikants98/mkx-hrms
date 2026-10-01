import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Default light-mode shimmer gradient with smooth tonal transitions.
const LinearGradient defaultLightShimmerGradient = LinearGradient(
  colors: [
    Color(0xFFE5E7EB),
    Color(0xFFF3F4F6),
    Color(0xFFE5E7EB),
  ],
  stops: [0.0, 0.5, 1.0],
  begin: Alignment(-2.4, -0.2),
  end: Alignment(2.4, 0.2),
  tileMode: TileMode.clamp,
);

/// Default dark-mode shimmer gradient with subtle obsidian transitions.
const LinearGradient defaultDarkShimmerGradient = LinearGradient(
  colors: [
    Color(0xFF26262B),
    Color(0xFF383842),
    Color(0xFF26262B),
  ],
  stops: [0.0, 0.5, 1.0],
  begin: Alignment(-2.4, -0.2),
  end: Alignment(2.4, 0.2),
  tileMode: TileMode.clamp,
);

/// Global controller for toggling skeleton demo preview mode across all application screens.
class SkeletonConfig {
  SkeletonConfig._();

  /// Reactive notifier indicating whether skeleton preview mode is permanently active.
  static final ValueNotifier<bool> isEnabled = ValueNotifier<bool>(false);

  /// Toggles the skeleton preview state globally.
  static void toggle() {
    isEnabled.value = !isEnabled.value;
  }
}

/// Inherited widget for configuring global skeleton themes and shimmer gradients.
class SkeletonTheme extends InheritedWidget {
  /// Custom shimmer gradient for light mode.
  final LinearGradient? shimmerGradient;

  /// Custom shimmer gradient for dark mode.
  final LinearGradient? darkShimmerGradient;

  /// Overridden theme mode for skeleton rendering.
  final ThemeMode? themeMode;

  /// Creates a skeleton theme scope.
  const SkeletonTheme({
    super.key,
    required super.child,
    this.shimmerGradient,
    this.darkShimmerGradient,
    this.themeMode,
  });

  /// Retrieves the nearest [SkeletonTheme] from the widget tree.
  static SkeletonTheme? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SkeletonTheme>();

  @override
  bool updateShouldNotify(SkeletonTheme oldWidget) =>
      oldWidget.themeMode != themeMode ||
      oldWidget.shimmerGradient != shimmerGradient ||
      oldWidget.darkShimmerGradient != darkShimmerGradient;
}

/// Shimmer animation provider applying sliding gradient effects to skeleton components.
class ShimmerWidget extends StatefulWidget {
  /// Custom light shimmer gradient.
  final LinearGradient? shimmerGradient;

  /// Custom dark shimmer gradient.
  final LinearGradient? darkShimmerGradient;

  /// Explicit theme mode override.
  final ThemeMode? themeMode;

  /// Animation sweep duration.
  final Duration? duration;

  /// Child containing skeleton elements.
  final Widget child;

  /// Creates a shimmer wrapper.
  const ShimmerWidget({
    super.key,
    required this.child,
    this.shimmerGradient,
    this.darkShimmerGradient,
    this.themeMode,
    this.duration,
  });

  @override
  ShimmerState createState() => ShimmerState();
}

/// State controlling the continuous sliding sweep animation.
class ShimmerState extends State<ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(vsync: this)
      ..repeat(
        min: -2.0,
        max: 2.0,
        period: widget.duration ?? const Duration(milliseconds: 1200),
      );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Evaluates whether the active theme is dark mode.
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  /// Returns the appropriate gradient based on the brightness mode.
  LinearGradient get gradient {
    final mode = widget.themeMode ??
        SkeletonTheme.of(context)?.themeMode ??
        (_isDark ? ThemeMode.dark : ThemeMode.light);

    if (mode == ThemeMode.dark) {
      return widget.darkShimmerGradient ??
          SkeletonTheme.of(context)?.darkShimmerGradient ??
          defaultDarkShimmerGradient;
    }
    return widget.shimmerGradient ??
        SkeletonTheme.of(context)?.shimmerGradient ??
        defaultLightShimmerGradient;
  }

  /// Computes the active gradient transformed by the current animation offset.
  LinearGradient get currentGradient => LinearGradient(
        colors: gradient.colors,
        stops: gradient.stops,
        begin: gradient.begin,
        end: gradient.end,
        transform: _SlidingGradientTransform(slidePercent: _controller.value),
      );

  /// Returns true once the ancestor render box has completed layout.
  bool get isSized => context.findRenderObject() != null
      ? (context.findRenderObject() as RenderBox).hasSize
      : false;

  /// Returns the bounding size of this shimmer container.
  Size get size => (context.findRenderObject() as RenderBox).size;

  /// Computes the coordinate offset of a descendant relative to this shimmer box.
  Offset getDescendantOffset({
    required RenderBox descendant,
    Offset offset = Offset.zero,
  }) {
    final shimmerBox = context.findRenderObject() as RenderBox;
    return descendant.localToGlobal(offset, ancestor: shimmerBox);
  }

  /// Change notifier for the sweep animation ticks.
  Listenable get shimmerChanges => _controller;

  @override
  Widget build(BuildContext context) {
    return _ShimmerScope(
      shimmer: this,
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}

class _ShimmerScope extends InheritedWidget {
  final ShimmerState shimmer;

  const _ShimmerScope({
    required this.shimmer,
    required super.child,
  });

  static ShimmerState? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ShimmerScope>()?.shimmer;

  @override
  bool updateShouldNotify(_ShimmerScope oldWidget) =>
      shimmer != oldWidget.shimmer;
}

/// Atomically binds skeleton primitives to an active shimmer sweep shader.
class SkeletonItem extends StatelessWidget {
  /// The skeleton layout tree.
  final Widget child;

  /// Creates a skeleton item wrapper.
  const SkeletonItem({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (_ShimmerScope.of(context) == null) {
      return ShimmerWidget(
        child: _SkeletonMask(child: child),
      );
    }
    return _SkeletonMask(child: child);
  }
}

class _SkeletonMask extends StatefulWidget {
  final Widget child;
  const _SkeletonMask({required this.child});

  @override
  State<_SkeletonMask> createState() => _SkeletonMaskState();
}

class _SkeletonMaskState extends State<_SkeletonMask> {
  Listenable? _shimmerChanges;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _shimmerChanges?.removeListener(_onShimmerTick);
    _shimmerChanges = _ShimmerScope.of(context)?.shimmerChanges;
    _shimmerChanges?.addListener(_onShimmerTick);
  }

  @override
  void dispose() {
    _shimmerChanges?.removeListener(_onShimmerTick);
    super.dispose();
  }

  void _onShimmerTick() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final shimmer = _ShimmerScope.of(context);
    if (shimmer == null || !shimmer.isSized) {
      return Opacity(opacity: 0.6, child: widget.child);
    }

    final renderBox = context.findRenderObject();
    if (renderBox is! RenderBox || !renderBox.hasSize) {
      return Opacity(opacity: 0.6, child: widget.child);
    }

    final offset = shimmer.getDescendantOffset(descendant: renderBox);
    final shimmerSize = shimmer.size;
    final gradient = shimmer.currentGradient;

    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (bounds) {
        return gradient.createShader(
          Rect.fromLTWH(
            -offset.dx,
            -offset.dy,
            shimmerSize.width,
            shimmerSize.height,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Style definition for [SkeletonAvatar].
class SkeletonAvatarStyle {
  /// Width in logical pixels.
  final double? width;

  /// Height in logical pixels.
  final double? height;

  /// Padding around the avatar.
  final EdgeInsetsGeometry padding;

  /// Box shape (rectangle or circle).
  final BoxShape shape;

  /// Corner radius when shape is rectangular.
  final BorderRadiusGeometry? borderRadius;

  /// Creates a skeleton avatar style configuration.
  const SkeletonAvatarStyle({
    this.width = 44,
    this.height = 44,
    this.padding = EdgeInsets.zero,
    this.shape = BoxShape.rectangle,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });
}

/// Skeleton avatar widget imitating user profile pictures or icons.
class SkeletonAvatar extends StatelessWidget {
  /// Avatar layout and sizing style.
  final SkeletonAvatarStyle style;

  /// Creates a skeleton avatar placeholder.
  const SkeletonAvatar({
    super.key,
    this.style = const SkeletonAvatarStyle(),
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fillColor = colorScheme.onInverseSurface;

    return SkeletonItem(
      child: Padding(
        padding: style.padding,
        child: Container(
          width: style.width,
          height: style.height,
          decoration: BoxDecoration(
            color: fillColor,
            shape: style.shape,
            borderRadius:
                style.shape != BoxShape.circle ? style.borderRadius : null,
          ),
        ),
      ),
    );
  }
}

/// Style definition for [SkeletonLine].
class SkeletonLineStyle {
  /// Width in logical pixels or [double.infinity].
  final double? width;

  /// Height in logical pixels.
  final double height;

  /// Padding around the line.
  final EdgeInsetsGeometry padding;

  /// Alignment within its parent.
  final AlignmentGeometry alignment;

  /// Corner radius for the line.
  final BorderRadiusGeometry borderRadius;

  /// Creates a skeleton line style configuration.
  const SkeletonLineStyle({
    this.width = double.infinity,
    this.height = 14,
    this.padding = EdgeInsets.zero,
    this.alignment = AlignmentDirectional.centerStart,
    this.borderRadius = const BorderRadius.all(Radius.circular(4)),
  });
}

/// Skeleton line widget representing text lines and badges.
class SkeletonLine extends StatelessWidget {
  /// Line layout and styling options.
  final SkeletonLineStyle style;

  /// Creates a skeleton text line placeholder.
  const SkeletonLine({
    super.key,
    this.style = const SkeletonLineStyle(),
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fillColor = colorScheme.onInverseSurface;

    return SkeletonItem(
      child: Align(
        alignment: style.alignment,
        child: Padding(
          padding: style.padding,
          child: Container(
            width: style.width,
            height: style.height,
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: style.borderRadius,
            ),
          ),
        ),
      ),
    );
  }
}

/// Style definition for [SkeletonParagraph].
class SkeletonParagraphStyle {
  /// Total line count.
  final int lines;

  /// Outer padding around the paragraph.
  final EdgeInsetsGeometry padding;

  /// Vertical spacing between consecutive lines.
  final double spacing;

  /// Base style for individual lines.
  final SkeletonLineStyle lineStyle;

  /// Creates a skeleton paragraph configuration.
  const SkeletonParagraphStyle({
    this.lines = 3,
    this.padding = EdgeInsets.zero,
    this.spacing = 8,
    this.lineStyle = const SkeletonLineStyle(),
  });
}

/// Skeleton paragraph simulating multiple text rows with natural line breaks.
class SkeletonParagraph extends StatelessWidget {
  /// Paragraph style definition.
  final SkeletonParagraphStyle style;

  /// Creates a skeleton paragraph placeholder.
  const SkeletonParagraph({
    super.key,
    this.style = const SkeletonParagraphStyle(),
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonItem(
      child: Padding(
        padding: style.padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < style.lines; i++) ...[
              FractionallySizedBox(
                widthFactor: i == style.lines - 1 ? 0.65 : 1.0,
                child: SkeletonLine(style: style.lineStyle),
              ),
              if (i < style.lines - 1) SizedBox(height: style.spacing),
            ],
          ],
        ),
      ),
    );
  }
}

/// Skeleton list tile widget representing a list item with leading avatar, title, and subtitle.
class SkeletonListTile extends StatelessWidget {
  /// Whether to render a leading avatar.
  final bool hasLeading;

  /// Style for the leading avatar.
  final SkeletonAvatarStyle? leadingStyle;

  /// Style for the primary title line.
  final SkeletonLineStyle? titleStyle;

  /// Whether to render a subtitle line.
  final bool hasSubtitle;

  /// Style for the subtitle line.
  final SkeletonLineStyle? subtitleStyle;

  /// Outer padding for the tile.
  final EdgeInsetsGeometry padding;

  /// Horizontal spacing between the leading avatar and content.
  final double contentSpacing;

  /// Vertical spacing between the title and subtitle lines.
  final double verticalSpacing;

  /// Optional trailing skeleton widget.
  final Widget? trailing;

  /// Creates a skeleton list tile.
  const SkeletonListTile({
    super.key,
    this.hasLeading = true,
    this.leadingStyle,
    this.titleStyle = const SkeletonLineStyle(height: 16),
    this.hasSubtitle = true,
    this.subtitleStyle = const SkeletonLineStyle(height: 12),
    this.padding = const EdgeInsets.symmetric(vertical: 8),
    this.contentSpacing = 12,
    this.verticalSpacing = 6,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonItem(
      child: Padding(
        padding: padding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (hasLeading) ...[
              SkeletonAvatar(
                  style: leadingStyle ?? const SkeletonAvatarStyle()),
              SizedBox(width: contentSpacing),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FractionallySizedBox(
                    widthFactor: 0.85,
                    child: SkeletonLine(
                      style: titleStyle ?? const SkeletonLineStyle(height: 16),
                    ),
                  ),
                  if (hasSubtitle) ...[
                    SizedBox(height: verticalSpacing),
                    FractionallySizedBox(
                      widthFactor: 0.55,
                      child: SkeletonLine(
                        style: subtitleStyle ??
                            const SkeletonLineStyle(height: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Skeleton list view builder rendering repeated skeleton list tiles.
class SkeletonListView extends StatelessWidget {
  /// Item count to render.
  final int itemCount;

  /// Optional custom item builder.
  final Widget Function(BuildContext context, int index)? itemBuilder;

  /// List padding.
  final EdgeInsetsGeometry padding;

  /// Item spacing.
  final double spacing;

  /// Whether the list view is scrollable.
  final bool scrollable;

  /// Creates a skeleton list view.
  const SkeletonListView({
    super.key,
    this.itemCount = 6,
    this.itemBuilder,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.spacing = 8,
    this.scrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonItem(
      child: ListView.separated(
        shrinkWrap: !scrollable,
        physics: scrollable
            ? const AlwaysScrollableScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        padding: padding,
        itemCount: itemCount,
        separatorBuilder: (_, __) => SizedBox(height: spacing),
        itemBuilder: (ctx, i) {
          if (itemBuilder != null) return itemBuilder!(ctx, i);
          return const SkeletonListTile();
        },
      ),
    );
  }
}

/// Conditional switcher widget transitioning between loading skeleton and content.
class Skeleton extends StatelessWidget {
  /// Loading state indicator.
  final bool isLoading;

  /// Skeleton widget shown when [isLoading] is true.
  final Widget skeleton;

  /// Real content shown when [isLoading] is false.
  final Widget child;

  /// Creates a skeleton switcher.
  const Skeleton({
    super.key,
    required this.isLoading,
    required this.skeleton,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: isLoading ? skeleton : child,
    );
  }
}

/// A shared skeleton for horizontal filter chips/buttons.
class SkeletonButtonGroup extends StatelessWidget {
  final List<double> widths;
  const SkeletonButtonGroup({super.key, required this.widths});

  @override
  Widget build(BuildContext context) {
    final scheme = M3ETheme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(widths.length, (index) {
          final isFirst = index == 0;
          final isLast = index == widths.length - 1;
          return Container(
            margin: EdgeInsets.only(right: isLast ? 0 : 2),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isFirst ? 16 : 4),
                bottomLeft: Radius.circular(isFirst ? 16 : 4),
                topRight: Radius.circular(isLast ? 16 : 4),
                bottomRight: Radius.circular(isLast ? 16 : 4),
              ),
            ),
            height: 32,
            alignment: Alignment.center,
            child: SkeletonLine(
              style: SkeletonLineStyle(
                height: 12,
                width: widths[index] - 30,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// A shared skeleton for search bars.
class SkeletonSearchBar extends StatelessWidget {
  const SkeletonSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = M3ETheme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SkeletonAvatar(
            style: SkeletonAvatarStyle(width: 20, height: 20, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SkeletonLine(
              style: SkeletonLineStyle(height: 12, width: double.infinity, borderRadius: BorderRadius.circular(4)),
            ),
          ),
        ],
      ),
    );
  }
}

