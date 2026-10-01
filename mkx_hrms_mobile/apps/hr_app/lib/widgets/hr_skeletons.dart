import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:mkx_core/widgets/app_skeleton.dart';
import 'package:mkx_core/widgets/section_tile.dart';


/// Pre-built skeleton loader for the HR Dashboard screen.
class HrDashboardSkeleton extends StatelessWidget {
  /// Indicates if the application is rendered in dark mode.
  final bool isDark;

  /// Creates a dashboard skeleton loader.
  const HrDashboardSkeleton({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final cardColor = theme.colorScheme.surfaceContainerHighest;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// "Today's Attendance" Donut Card skeleton
        M3ECard(
          variant: M3ECardVariant.filled,
          borderRadius: BorderRadius.circular(14),
          padding: const EdgeInsets.all(16),
          color: cardColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SkeletonLine(
                style: SkeletonLineStyle(height: 16, width: 150),
              ),
              const SizedBox(height: 18),
              Center(
                child: SizedBox(
                  width: 190,
                  height: 250,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const SkeletonAvatar(
                        style: SkeletonAvatarStyle(
                          width: 190,
                          height: 190,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cardColor,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            SkeletonLine(
                              style: SkeletonLineStyle(
                                height: 20,
                                width: 30,
                                alignment: AlignmentDirectional.center,
                              ),
                            ),
                            SizedBox(height: 6),
                            SkeletonLine(
                              style: SkeletonLineStyle(
                                height: 10,
                                width: 40,
                                alignment: AlignmentDirectional.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: const [
                  SkeletonLine(
                    style: SkeletonLineStyle(height: 12, width: 75),
                  ),
                  SkeletonLine(
                    style: SkeletonLineStyle(height: 12, width: 65),
                  ),
                  SkeletonLine(
                    style: SkeletonLineStyle(height: 12, width: 75),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        /// 2x2 Metric Cards Grid placeholder
        Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildMetricPlaceholder(context, 'topLeft')),
                const SizedBox(width: 4),
                Expanded(child: _buildMetricPlaceholder(context, 'topRight')),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(child: _buildMetricPlaceholder(context, 'bottomLeft')),
                const SizedBox(width: 4),
                Expanded(
                    child: _buildMetricPlaceholder(context, 'bottomRight')),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),

        /// Recent Activity Header placeholder
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: SkeletonLine(
            style: SkeletonLineStyle(height: 14, width: 130),
          ),
        ),
        const SizedBox(height: 10),

        /// Recent Activity SectionCard placeholder
        SectionCard(
          isDark: isDark,
          children: List.generate(
            3,
            (_) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: SkeletonListTile(
                padding: EdgeInsets.zero,
                leadingStyle: SkeletonAvatarStyle(
                  width: 36,
                  height: 36,
                  shape: BoxShape.circle,
                ),
                titleStyle: SkeletonLineStyle(height: 14, width: 160),
                subtitleStyle: SkeletonLineStyle(height: 11, width: 100),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildMetricPlaceholder(BuildContext context, String position) {
    BorderRadius radius;
    switch (position) {
      case 'topLeft':
        radius = const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(3),
          bottomLeft: Radius.circular(3),
          bottomRight: Radius.circular(3),
        );
        break;
      case 'topRight':
        radius = const BorderRadius.only(
          topRight: Radius.circular(10),
          topLeft: Radius.circular(3),
          bottomLeft: Radius.circular(3),
          bottomRight: Radius.circular(3),
        );
        break;
      case 'bottomLeft':
        radius = const BorderRadius.only(
          bottomLeft: Radius.circular(10),
          topLeft: Radius.circular(3),
          topRight: Radius.circular(3),
          bottomRight: Radius.circular(3),
        );
        break;
      case 'bottomRight':
      default:
        radius = const BorderRadius.only(
          bottomRight: Radius.circular(10),
          bottomLeft: Radius.circular(3),
          topRight: Radius.circular(3),
          topLeft: Radius.circular(3),
        );
        break;
    }

    final cardColor = M3ETheme.of(context).colorScheme.surfaceContainerHighest;

    return M3ECard(
      variant: M3ECardVariant.filled,
      borderRadius: radius,
      color: cardColor,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              SkeletonLine(
                style: SkeletonLineStyle(height: 13, width: 90),
              ),
              SkeletonAvatar(
                style: SkeletonAvatarStyle(
                  width: 32,
                  height: 32,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const SkeletonLine(
            style: SkeletonLineStyle(height: 24, width: 36),
          ),
          const SizedBox(height: 6),
          const SkeletonLine(
            style: SkeletonLineStyle(height: 11, width: 100),
          ),
        ],
      ),
    );
  }
}

/// Pre-built skeleton loader for the Employees Directory screen.
class HrEmployeesSkeleton extends StatelessWidget {
  /// Indicates if the application is rendered in dark mode.
  final bool isDark;

  /// Creates an employees list skeleton loader.
  const HrEmployeesSkeleton({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonSearchBar(),
        const SizedBox(height: 10),
        const SkeletonButtonGroup(widths: [100, 85, 85, 100]),
        const SizedBox(height: 10),
        SectionCard(
          isDark: isDark,
          children: List.generate(
            6,
            (_) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: SkeletonListTile(
                padding: EdgeInsets.zero,
                leadingStyle: SkeletonAvatarStyle(
                  width: 40,
                  height: 40,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                titleStyle: SkeletonLineStyle(height: 15, width: 150),
                subtitleStyle: SkeletonLineStyle(height: 12, width: 110),
                trailing: SkeletonLine(
                  style: SkeletonLineStyle(
                    height: 22,
                    width: 60,
                    borderRadius: BorderRadius.all(Radius.circular(6)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Pre-built skeleton loader for the Employee Detail screen.
class HrEmployeeDetailSkeleton extends StatelessWidget {
  /// Indicates if the application is rendered in dark mode.
  final bool isDark;

  /// Creates an employee detail skeleton loader.
  const HrEmployeeDetailSkeleton({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Profile Header Card
          M3ECard(
            variant: M3ECardVariant.filled,
            borderRadius: BorderRadius.circular(16),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const SkeletonAvatar(
                  style: SkeletonAvatarStyle(
                    width: 64,
                    height: 64,
                    borderRadius: BorderRadius.all(Radius.circular(14)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SkeletonLine(
                        style: SkeletonLineStyle(height: 18, width: 140),
                      ),
                      SizedBox(height: 6),
                      SkeletonLine(
                        style: SkeletonLineStyle(height: 13, width: 100),
                      ),
                      SizedBox(height: 8),
                      SkeletonLine(
                        style: SkeletonLineStyle(
                          height: 20,
                          width: 70,
                          borderRadius: BorderRadius.all(Radius.circular(6)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          /// Work Info Section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: SkeletonLine(
              style: SkeletonLineStyle(height: 12, width: 120),
            ),
          ),
          const SizedBox(height: 10),
          SectionCard(
            isDark: isDark,
            children: List.generate(
              4,
              (_) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SkeletonLine(
                      style: SkeletonLineStyle(height: 13, width: 100),
                    ),
                    SkeletonLine(
                      style: SkeletonLineStyle(height: 13, width: 120),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          /// Contact Info Section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: SkeletonLine(
              style: SkeletonLineStyle(height: 12, width: 140),
            ),
          ),
          const SizedBox(height: 10),
          SectionCard(
            isDark: isDark,
            children: List.generate(
              3,
              (_) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SkeletonLine(
                      style: SkeletonLineStyle(height: 13, width: 90),
                    ),
                    SkeletonLine(
                      style: SkeletonLineStyle(height: 13, width: 130),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pre-built skeleton loader for the HR Leaves management screen.
class HrLeavesSkeleton extends StatelessWidget {
  /// Indicates if the application is rendered in dark mode.
  final bool isDark;

  /// Creates a leaves skeleton loader.
  const HrLeavesSkeleton({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 10),
          child: SkeletonButtonGroup(widths: [70, 95, 105, 105]),
        ),
        const SizedBox(height: 10),
        SectionCard(
          isDark: isDark,
          children: List.generate(
            5,
            (_) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SkeletonAvatar(
                        style: SkeletonAvatarStyle(
                          width: 36,
                          height: 36,
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonLine(
                              style: SkeletonLineStyle(height: 14, width: 130),
                            ),
                            SizedBox(height: 5),
                            SkeletonLine(
                              style: SkeletonLineStyle(height: 11, width: 80),
                            ),
                          ],
                        ),
                      ),
                      const SkeletonLine(
                        style: SkeletonLineStyle(
                          height: 22,
                          width: 64,
                          borderRadius: BorderRadius.all(Radius.circular(6)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const SkeletonLine(
                    style: SkeletonLineStyle(height: 12, width: 180),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Pre-built skeleton loader for the HR Attendance screen.
class HrAttendanceSkeleton extends StatelessWidget {
  /// Indicates if the application is rendered in dark mode.
  final bool isDark;

  /// Creates an attendance records skeleton loader.
  const HrAttendanceSkeleton({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final cardColor = theme.colorScheme.surfaceContainerHighest;

    Widget buildStatCol() {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SkeletonLine(
            style: SkeletonLineStyle(
              height: 18,
              width: 18,
              alignment: Alignment.center,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 6),
          SkeletonLine(
            style: SkeletonLineStyle(
              height: 11,
              width: 50,
              alignment: Alignment.center,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: M3ECard(
                variant: M3ECardVariant.filled,
                color: cardColor,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 5),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
                child: buildStatCol(),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: M3ECard(
                variant: M3ECardVariant.filled,
                color: cardColor,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 5),
                borderRadius: BorderRadius.circular(4),
                child: buildStatCol(),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: M3ECard(
                variant: M3ECardVariant.filled,
                color: cardColor,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 5),
                borderRadius: BorderRadius.circular(4),
                child: buildStatCol(),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: M3ECard(
                variant: M3ECardVariant.filled,
                color: cardColor,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 5),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                  bottomLeft: Radius.circular(4),
                  topLeft: Radius.circular(4),
                ),
                child: buildStatCol(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const SkeletonButtonGroup(widths: [80, 75, 60, 75, 80]),
        const SizedBox(height: 10),
        SectionCard(
          isDark: isDark,
          children: List.generate(
            6,
            (_) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: SkeletonListTile(
                padding: EdgeInsets.zero,
                leadingStyle: SkeletonAvatarStyle(
                  width: 38,
                  height: 38,
                  shape: BoxShape.circle,
                ),
                titleStyle: SkeletonLineStyle(height: 14, width: 140),
                subtitleStyle: SkeletonLineStyle(height: 11, width: 90),
                trailing: SkeletonLine(
                  style: SkeletonLineStyle(
                    height: 22,
                    width: 60,
                    borderRadius: BorderRadius.all(Radius.circular(6)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Pre-built skeleton loader for the HR Payroll management screen.
class HrPayrollSkeleton extends StatelessWidget {
  /// Indicates if the application is rendered in dark mode.
  final bool isDark;

  /// Creates a payroll records skeleton loader.
  const HrPayrollSkeleton({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      isDark: isDark,
      children: List.generate(
        4,
        (_) => const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: SkeletonListTile(
            padding: EdgeInsets.zero,
            leadingStyle: SkeletonAvatarStyle(
              width: 40,
              height: 40,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            titleStyle: SkeletonLineStyle(height: 15, width: 140),
            subtitleStyle: SkeletonLineStyle(height: 12, width: 100),
            trailing: SkeletonLine(
              style: SkeletonLineStyle(
                height: 24,
                width: 76,
                borderRadius: BorderRadius.all(Radius.circular(6)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pre-built skeleton loader for the Notifications screen.
class HrNotificationsSkeleton extends StatelessWidget {
  /// Indicates if the application is rendered in dark mode.
  final bool isDark;

  /// Creates a notifications skeleton loader.
  const HrNotificationsSkeleton({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      isDark: isDark,
      children: List.generate(
        6,
        (_) => const Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: SkeletonListTile(
            padding: EdgeInsets.zero,
            leadingStyle: SkeletonAvatarStyle(
              width: 40,
              height: 40,
              shape: BoxShape.circle,
            ),
            titleStyle: SkeletonLineStyle(height: 15, width: 160),
            subtitleStyle: SkeletonLineStyle(height: 12, width: 220),
            trailing: SkeletonLine(
              style: SkeletonLineStyle(
                height: 10,
                width: 40,
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pre-built skeleton loader for the HR Profile screen.
class HrProfileSkeleton extends StatelessWidget {
  /// Indicates if the application is rendered in dark mode.
  final bool isDark;

  /// Creates a profile skeleton loader.
  const HrProfileSkeleton({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          M3ECard(
            variant: M3ECardVariant.filled,
            borderRadius: BorderRadius.circular(16),
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonAvatar(
                  style: SkeletonAvatarStyle(
                    width: 64,
                    height: 64,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SkeletonLine(
                        style: SkeletonLineStyle(height: 18, width: 140),
                      ),
                      SizedBox(height: 6),
                      SkeletonLine(
                        style: SkeletonLineStyle(height: 12, width: 160),
                      ),
                      SizedBox(height: 10),
                      SkeletonLine(
                        style: SkeletonLineStyle(
                          height: 20,
                          width: 80,
                          borderRadius: BorderRadius.all(Radius.circular(6)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SectionCard(
            isDark: isDark,
            children: List.generate(
              6,
              (_) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: SkeletonListTile(
                  padding: EdgeInsets.zero,
                  hasSubtitle: false,
                  leadingStyle: SkeletonAvatarStyle(
                    width: 32,
                    height: 32,
                    borderRadius: BorderRadius.all(Radius.circular(6)),
                  ),
                  titleStyle: SkeletonLineStyle(height: 14, width: 120),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
