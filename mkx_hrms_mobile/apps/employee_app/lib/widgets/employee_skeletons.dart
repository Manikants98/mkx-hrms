import 'package:flutter/material.dart';
import 'package:mkx_core/widgets/app_skeleton.dart';
import 'package:mkx_core/widgets/section_tile.dart';

/// Pre-built skeleton loader for the Employee Dashboard screen.
class EmployeeDashboardSkeleton extends StatelessWidget {
  final bool isDark;
  const EmployeeDashboardSkeleton({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Punch Card Skeleton (SectionTile in actual UI, which is just a card)
            SectionCard(
              isDark: isDark,
              children: [
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Date and Status badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SkeletonLine(
                            style: SkeletonLineStyle(
                              height: 14,
                              width: 140,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(4)),
                            ),
                          ),
                          SkeletonLine(
                            style: SkeletonLineStyle(
                              height: 24,
                              width: 50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Big time text
                      const SkeletonLine(
                        style: SkeletonLineStyle(
                          height: 38,
                          alignment: Alignment.center,
                          width: 180,
                          borderRadius: BorderRadius.all(Radius.circular(6)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Location text
                      const SkeletonLine(
                        style: SkeletonLineStyle(
                          height: 12,
                          alignment: Alignment.center,
                          width: 120,
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 3 small cards: Punch In, Punch Out, Total Hours
                      Row(
                        children: [
                          Expanded(
                            child: SkeletonAvatar(
                              style: SkeletonAvatarStyle(
                                width: double.infinity,
                                height: 70,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: SkeletonAvatar(
                              style: SkeletonAvatarStyle(
                                width: double.infinity,
                                height: 70,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: SkeletonAvatar(
                              style: SkeletonAvatarStyle(
                                width: double.infinity,
                                height: 70,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Big Punch button
                      const SkeletonLine(
                        style: SkeletonLineStyle(
                          height: 52,
                          width: double.infinity,
                          borderRadius: BorderRadius.all(Radius.circular(26)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 2. CELEBRATIONS TODAY Header
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: SkeletonLine(
                style: SkeletonLineStyle(
                  height: 12,
                  width: 140,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Celebrations Card
            SectionCard(
              isDark: isDark,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const SkeletonAvatar(
                        style: SkeletonAvatarStyle(
                          width: 48,
                          height: 48,
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonLine(
                              style: SkeletonLineStyle(
                                height: 14,
                                width: 140,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(4)),
                              ),
                            ),
                            SizedBox(height: 6),
                            SkeletonLine(
                              style: SkeletonLineStyle(
                                height: 12,
                                width: 100,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(4)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SkeletonAvatar(
                        style: SkeletonAvatarStyle(
                          width: 32,
                          height: 32,
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 3. MONTHLY ATTENDANCE Header
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: SkeletonLine(
                style: SkeletonLineStyle(
                  height: 12,
                  width: 160,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Monthly Attendance Grid
            Row(
              children: [
                Expanded(
                  child: _buildMetricCardSkeleton(
                    isDark,
                    const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      topRight: Radius.circular(3),
                      bottomLeft: Radius.circular(3),
                      bottomRight: Radius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildMetricCardSkeleton(
                    isDark,
                    const BorderRadius.only(
                      topLeft: Radius.circular(3),
                      topRight: Radius.circular(14),
                      bottomLeft: Radius.circular(3),
                      bottomRight: Radius.circular(3),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCardSkeleton(
                    isDark,
                    const BorderRadius.only(
                      topLeft: Radius.circular(3),
                      topRight: Radius.circular(3),
                      bottomLeft: Radius.circular(14),
                      bottomRight: Radius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildMetricCardSkeleton(
                    isDark,
                    const BorderRadius.only(
                      topLeft: Radius.circular(3),
                      topRight: Radius.circular(3),
                      bottomLeft: Radius.circular(3),
                      bottomRight: Radius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCardSkeleton(bool isDark, BorderRadius radius) {
    return SectionTile(
      isDark: isDark,
      position: TilePosition.only,
      padding: const EdgeInsets.all(16),
      customBorderRadius: radius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SkeletonLine(
                style: SkeletonLineStyle(
                  height: 12,
                  width: 80,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
              ),
              const SkeletonAvatar(
                style: SkeletonAvatarStyle(
                  width: 32,
                  height: 32,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const SkeletonLine(
            style: SkeletonLineStyle(
              height: 22,
              width: 30,
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
          ),
          const SizedBox(height: 8),
          const SkeletonLine(
            style: SkeletonLineStyle(
              height: 10,
              width: 100,
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pre-built skeleton loader for the Employee Leaves screen.
class EmployeeLeavesSkeleton extends StatelessWidget {
  final bool isDark;
  const EmployeeLeavesSkeleton({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  3,
                  (index) {
                    return Padding(
                      padding: EdgeInsets.only(right: index == 3 ? 0 : 4),
                      child: SectionTile(
                        isDark: isDark,
                        position: TilePosition.only,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 20,
                        ),
                        customBorderRadius: index == 0
                            ? const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                bottomLeft: Radius.circular(16),
                                bottomRight: Radius.circular(4),
                                topRight: Radius.circular(4),
                              )
                            : (index == 3
                                ? const BorderRadius.only(
                                    topRight: Radius.circular(16),
                                    bottomRight: Radius.circular(16),
                                    bottomLeft: Radius.circular(4),
                                    topLeft: Radius.circular(4),
                                  )
                                : BorderRadius.circular(4)),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SkeletonLine(
                              style: SkeletonLineStyle(
                                height: 32,
                                width: 24,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(4)),
                              ),
                            ),
                            SizedBox(width: 12),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SkeletonLine(
                                  style: SkeletonLineStyle(
                                    height: 13,
                                    width: 80,
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(4)),
                                  ),
                                ),
                                SizedBox(height: 6),
                                Row(
                                  children: [
                                    SkeletonLine(
                                      style: SkeletonLineStyle(
                                        height: 11,
                                        width: 40,
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(4)),
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    SkeletonLine(
                                      style: SkeletonLineStyle(
                                        height: 14,
                                        width: 30,
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(4)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: SkeletonButtonGroup(widths: [95, 100, 80, 95]),
            ),
            const SizedBox(height: 10),
            SectionCard(
              isDark: isDark,
              children: List.generate(
                5,
                (_) => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: SkeletonListTile(
                    padding: EdgeInsets.zero,
                    leadingStyle: SkeletonAvatarStyle(
                      width: 44,
                      height: 44,
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    titleStyle: SkeletonLineStyle(
                      height: 14,
                      width: 140,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                    subtitleStyle: SkeletonLineStyle(
                      height: 12,
                      width: 100,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                    hasSubtitle: true,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pre-built skeleton loader for the Employee Attendance History screen.
class EmployeeAttendanceSkeleton extends StatelessWidget {
  final bool isDark;
  const EmployeeAttendanceSkeleton({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              width: double.infinity,
              child: SkeletonButtonGroup(widths: [70, 80, 70, 80, 70]),
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
                    leadingStyle: SkeletonAvatarStyle(
                      width: 44,
                      height: 44,
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    titleStyle: SkeletonLineStyle(
                      height: 14,
                      width: 140,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                    subtitleStyle: SkeletonLineStyle(
                      height: 12,
                      width: 100,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                    hasSubtitle: true,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pre-built skeleton loader for the Employee Notifications screen.
class EmployeeNotificationsSkeleton extends StatelessWidget {
  final bool isDark;
  const EmployeeNotificationsSkeleton({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionCard(
              isDark: isDark,
              children: List.generate(
                7,
                (_) => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: SkeletonListTile(
                    padding: EdgeInsets.zero,
                    leadingStyle: SkeletonAvatarStyle(
                      width: 44,
                      height: 44,
                      shape: BoxShape.circle,
                    ),
                    titleStyle: SkeletonLineStyle(
                      height: 14,
                      width: double.infinity,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                    subtitleStyle: SkeletonLineStyle(
                      height: 12,
                      width: 200,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                    hasSubtitle: true,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pre-built skeleton loader for the Employee Payroll screen.
class EmployeePayrollSkeleton extends StatelessWidget {
  final bool isDark;
  const EmployeePayrollSkeleton({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Latest Disbursement Card
            SectionTile(
              isDark: isDark,
              position: TilePosition.only,
              padding: const EdgeInsets.all(20),
              customBorderRadius: BorderRadius.circular(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SkeletonLine(
                        style: SkeletonLineStyle(
                          height: 14,
                          width: 130,
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                        ),
                      ),
                      SkeletonLine(
                        style: SkeletonLineStyle(
                          height: 24,
                          width: 70,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const SkeletonLine(
                    style: SkeletonLineStyle(
                      height: 38,
                      width: 160,
                      borderRadius: BorderRadius.all(Radius.circular(6)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const SkeletonLine(
                    style: SkeletonLineStyle(
                      height: 12,
                      width: 200,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: SkeletonAvatar(
                          style: SkeletonAvatarStyle(
                            width: double.infinity,
                            height: 50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: SkeletonAvatar(
                          style: SkeletonAvatarStyle(
                            width: double.infinity,
                            height: 50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: SkeletonAvatar(
                          style: SkeletonAvatarStyle(
                            width: double.infinity,
                            height: 50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 2. Payslip History Header
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: SkeletonLine(
                style: SkeletonLineStyle(
                  height: 16,
                  width: 140,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 3. Payslip List
            SectionCard(
              isDark: isDark,
              children: List.generate(
                4,
                (_) => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      SkeletonAvatar(
                        style: SkeletonAvatarStyle(
                          width: 44,
                          height: 44,
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonLine(
                              style: SkeletonLineStyle(
                                height: 16,
                                width: 130,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(4)),
                              ),
                            ),
                            SizedBox(height: 6),
                            SkeletonLine(
                              style: SkeletonLineStyle(
                                height: 12,
                                width: 180,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(4)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          SkeletonLine(
                            style: SkeletonLineStyle(
                              height: 16,
                              width: 70,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(4)),
                            ),
                          ),
                          SizedBox(height: 6),
                          SkeletonLine(
                            style: SkeletonLineStyle(
                              height: 20,
                              width: 60,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(4)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pre-built skeleton loader for the Employee Profile screen.
class EmployeeProfileSkeleton extends StatelessWidget {
  final bool isDark;
  const EmployeeProfileSkeleton({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Profile Header Card
            SectionTile(
              isDark: isDark,
              position: TilePosition.only,
              padding: const EdgeInsets.all(20),
              customBorderRadius: BorderRadius.circular(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonAvatar(
                    style: SkeletonAvatarStyle(
                      width: 64,
                      height: 64,
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const SkeletonLine(
                              style: SkeletonLineStyle(
                                height: 18,
                                width: 120,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(4)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SkeletonLine(
                              style: SkeletonLineStyle(
                                height: 22,
                                width: 50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const SkeletonLine(
                          style: SkeletonLineStyle(
                            height: 12,
                            width: 80,
                            borderRadius: BorderRadius.all(Radius.circular(4)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const SkeletonLine(
                          style: SkeletonLineStyle(
                            height: 12,
                            width: 100,
                            borderRadius: BorderRadius.all(Radius.circular(4)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 2. EMPLOYMENT DETAILS Header
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: SkeletonLine(
                style: SkeletonLineStyle(
                  height: 12,
                  width: 140,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 3. Info Tiles
            SectionCard(
              isDark: isDark,
              children: List.generate(
                6,
                (_) => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      SkeletonAvatar(
                        style: SkeletonAvatarStyle(
                          width: 18,
                          height: 18,
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                        ),
                      ),
                      SizedBox(width: 14),
                      SkeletonLine(
                        style: SkeletonLineStyle(
                          height: 12,
                          width: 100,
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                        ),
                      ),
                      Spacer(),
                      SkeletonLine(
                        style: SkeletonLineStyle(
                          height: 12,
                          width: 80,
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
