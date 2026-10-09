import 'package:flutter/cupertino.dart';

/**
 * Authentic iOS pull-to-refresh scroll view with Cupertino activity indicator and bouncing physics
 */
class Ios27RefreshableScrollView extends StatelessWidget {
  /**
   * Async callback executed when user pulls down to refresh
   */
  final Future<void> Function() onRefresh;

  /**
   * Children widgets to render sequentially in the scrollable view
   */
  final List<Widget> children;

  /**
   * Padding applied around the scrollable content
   */
  final EdgeInsetsGeometry padding;

  /**
   * Optional scroll controller
   */
  final ScrollController? controller;

  /**
   * Creates an authentic iOS refreshable scroll view
   */
  const Ios27RefreshableScrollView({
    super.key,
    required this.onRefresh,
    required this.children,
    this.padding = EdgeInsets.zero,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: controller,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: onRefresh,
        ),
        SliverPadding(
          padding: padding,
          sliver: SliverList(
            delegate: SliverChildListDelegate(children),
          ),
        ),
      ],
    );
  }
}
