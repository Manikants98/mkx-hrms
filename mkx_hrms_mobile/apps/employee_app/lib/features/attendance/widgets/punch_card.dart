import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:mkx_core/constants/app_colors.dart';
import 'package:mkx_core/utils/date_utils.dart';
import 'package:mkx_core/widgets/section_tile.dart';
import 'package:mkx_core/widgets/status_badge.dart';

import '../models/attendance_model.dart';

/// Interactive Punch In / Punch Out card with live digital clock
class PunchCard extends StatelessWidget {
  final DateTime currentTime;
  final AttendanceRecord? record;
  final bool isPunching;
  final VoidCallback onPunchIn;
  final VoidCallback onPunchOut;

  const PunchCard({
    super.key,
    required this.currentTime,
    required this.record,
    required this.isPunching,
    required this.onPunchIn,
    required this.onPunchOut,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = M3ETheme.of(context).brightness == Brightness.dark;
    final hasCheckedIn = record?.hasCheckedIn ?? false;
    final hasCheckedOut = record?.hasCheckedOut ?? false;

    return SectionTile(
      isDark: isDark,
      position: TilePosition.only,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header Date & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppDateUtils.formatFullDate(currentTime),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                ),
              ),
              StatusBadge(status: record?.status ?? 'Absent'),
            ],
          ),
          const SizedBox(height: 16),

          // Digital Live Clock
          Text(
            AppDateUtils.formatTime(currentTime),
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              color:
                  isDark ? AppColors.darkForeground : AppColors.lightForeground,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 14,
                color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
              ),
              const SizedBox(width: 4),
              Text(
                'MKX Tech Headquarters • ${record?.location ?? "Office"}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Check In & Check Out Time Badges
          M3ECard(
            variant: M3ECardVariant.filled,
            borderRadius: BorderRadius.circular(16),
            color: M3ETheme.of(context).colorScheme.surfaceContainer,
            padding: EdgeInsets.zero,
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: _buildTimeColumn(
                        context,
                        title: 'Punch In',
                        time: record?.checkIn ?? '--:--',
                        icon: Icons.login_rounded,
                        iconColor: AppColors.success,
                      ),
                    ),
                  ),
                  Container(
                    width: 2,
                    color:
                        M3ETheme.of(context).colorScheme.surfaceContainerLowest,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: _buildTimeColumn(
                        context,
                        title: 'Punch Out',
                        time: record?.checkOut ?? '--:--',
                        icon: Icons.logout_rounded,
                        iconColor: AppColors.warning,
                      ),
                    ),
                  ),
                  Container(
                    width: 2,
                    color:
                        M3ETheme.of(context).colorScheme.surfaceContainerLowest,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: _buildTimeColumn(
                        context,
                        title: 'Total Hours',
                        time: record?.workHours ?? '0h 00m',
                        icon: Icons.timer_outlined,
                        iconColor: AppColors.info,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Action Button
          if (!hasCheckedIn)
            if (isPunching)
              Center(
                  child: SizedBox(
                      width: 40,
                      height: 40,
                      child: M3EProgressIndicator.circularWavy(strokeWidth: 3)))
            else
              M3EButton(
                style: M3EButtonStyle.filled,
                size: M3EButtonSize.md,
                onPressed: onPunchIn,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.fingerprint_rounded, size: 20),
                    SizedBox(width: 8),
                    Text('Punch In Now'),
                  ],
                ),
              )
          else if (hasCheckedIn && !hasCheckedOut)
            if (isPunching)
              Center(
                  child: SizedBox(
                      width: 40,
                      height: 40,
                      child: M3EProgressIndicator.circularWavy(strokeWidth: 3)))
            else
              M3EButton(
                style: M3EButtonStyle.filled,
                size: M3EButtonSize.md,
                onPressed: onPunchOut,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.timer_off_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Punch Out Now'),
                  ],
                ),
              )
          else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              width: double.infinity,
              decoration: BoxDecoration(
                color:
                    isDark ? AppColors.successBgDark : AppColors.successBgLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Punched for Today (${record?.workHours ?? "Completed"})',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeColumn(
    BuildContext context, {
    required String title,
    required String time,
    required IconData icon,
    required Color iconColor,
  }) {
    final isDark = M3ETheme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: iconColor),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color:
                isDark ? AppColors.darkForeground : AppColors.lightForeground,
          ),
        ),
      ],
    );
  }
}
