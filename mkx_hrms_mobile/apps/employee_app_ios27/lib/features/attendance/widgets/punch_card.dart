import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:mkx_core/utils/date_utils.dart';
import '../../../widgets/ios27_glass_surface.dart';

import '../models/attendance_model.dart';

/// iOS 27 Liquid Glass Hero Attendance Punch Platter.
/// Provides live digital clock rendering, telemetry metrics, and haptic shift actions.
class PunchCard extends StatelessWidget {
  /// The current clock tick time.
  final DateTime currentTime;

  /// Active attendance record for today.
  final AttendanceRecord? record;

  /// Indicates if a network punch operation is in flight.
  final bool isPunching;

  /// Callback executed when the user initiates punch-in.
  final VoidCallback onPunchIn;

  /// Callback executed when the user initiates punch-out.
  final VoidCallback onPunchOut;

  /// Constructs an iOS 27 authentic punch platter.
  const PunchCard({
    super.key,
    required this.currentTime,
    required this.record,
    required this.isPunching,
    required this.onPunchIn,
    required this.onPunchOut,
  });

  /// Computes the active shift elapsed duration between check-in and current clock time.
  String _computeLiveTotalHours(String checkIn, DateTime now) {
    try {
      final DateFormat format = DateFormat('hh:mm a');
      final DateTime checkInTime = format.parse(checkIn);
      final DateTime nowTime = DateTime(1970, 1, 1, now.hour, now.minute);
      Duration duration = nowTime.difference(checkInTime);
      if (duration.isNegative) {
        duration += const Duration(days: 1);
      }
      final int hours = duration.inHours;
      final int minutes = duration.inMinutes.remainder(60);
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    } catch (_) {
      return '0h 00m';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark =
        CupertinoTheme.of(context).brightness == Brightness.dark;
    final Color primary = CupertinoTheme.of(context).primaryColor;
    final bool hasCheckedIn = record?.hasCheckedIn ?? false;
    final bool hasCheckedOut = record?.hasCheckedOut ?? false;

    final String displayWorkHours = (hasCheckedIn && !hasCheckedOut)
        ? _computeLiveTotalHours(record!.checkIn, currentTime)
        : (record?.workHours ?? '0h 00m');

    final String statusText =
        record?.status ?? (hasCheckedIn ? 'On Duty' : 'Not Punched');

    return Ios27GlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.calendar_today,
                      size: 14,
                      color: isDark
                          ? const Color(0xFF98989D)
                          : const Color(0xFF6E6E73),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        AppDateUtils.formatFullDate(currentTime),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFFD1D1D6)
                              : const Color(0xFF3A3A3C),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              _buildStatusPill(
                  statusText, isDark, hasCheckedIn && !hasCheckedOut, primary),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            AppDateUtils.formatTime(currentTime),
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.5,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: isDark ? CupertinoColors.white : const Color(0xFF1C1C1E),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.location_solid,
                size: 13,
                color: isDark ? const Color(0xFF64D2FF) : primary,
              ),
              const SizedBox(width: 5),
              Text(
                record?.location ?? 'Main Office • High Precision GPS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? const Color(0xFFA1A1A6)
                      : const Color(0xFF636366),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? CupertinoColors.white.withValues(alpha: 0.05)
                  : CupertinoColors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? CupertinoColors.white.withValues(alpha: 0.07)
                    : CupertinoColors.black.withValues(alpha: 0.04),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTimeMetric(
                    title: 'Check In',
                    time: record?.checkIn ?? '--:--',
                    icon: CupertinoIcons.arrow_right_circle_fill,
                    color: const Color(0xFF34C759),
                    isDark: isDark,
                  ),
                ),
                Container(
                  height: 32,
                  width: 1,
                  color: isDark
                      ? CupertinoColors.white.withValues(alpha: 0.12)
                      : CupertinoColors.black.withValues(alpha: 0.12),
                ),
                Expanded(
                  child: _buildTimeMetric(
                    title: 'Check Out',
                    time: record?.checkOut ?? '--:--',
                    icon: CupertinoIcons.arrow_left_circle_fill,
                    color: const Color(0xFFFF9500),
                    isDark: isDark,
                  ),
                ),
                Container(
                  height: 32,
                  width: 1,
                  color: isDark
                      ? CupertinoColors.white.withValues(alpha: 0.12)
                      : CupertinoColors.black.withValues(alpha: 0.12),
                ),
                Expanded(
                  child: _buildTimeMetric(
                    title: 'Logged',
                    time: displayWorkHours,
                    icon: CupertinoIcons.stopwatch_fill,
                    color: primary,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildActionButton(
            context,
            isDark: isDark,
            hasCheckedIn: hasCheckedIn,
            hasCheckedOut: hasCheckedOut,
            primary: primary,
          ),
        ],
      ),
    );
  }

  /// Builds the iOS 27 capsule badge displaying current employee state.
  Widget _buildStatusPill(
      String status, bool isDark, bool isActiveShift, Color primary) {
    final Color tintColor = isActiveShift
        ? const Color(0xFF34C759)
        : (status.toLowerCase().contains('absent')
            ? const Color(0xFFFF453A)
            : primary);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: tintColor.withValues(alpha: isDark ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: tintColor.withValues(alpha: isDark ? 0.40 : 0.25),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tintColor,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: tintColor,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a timestamp telemetry item with iOS 27 styling.
  Widget _buildTimeMetric({
    required String title,
    required String time,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? const Color(0xFF8E8E93)
                    : const Color(0xFF6E6E73),
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
            letterSpacing: -0.3,
            color: isDark ? CupertinoColors.white : const Color(0xFF1C1C1E),
          ),
        ),
      ],
    );
  }

  /// Builds the primary shift action CTA.
  Widget _buildActionButton(
    BuildContext context, {
    required bool isDark,
    required bool hasCheckedIn,
    required bool hasCheckedOut,
    required Color primary,
  }) {
    if (isPunching) {
      return const Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CupertinoActivityIndicator(radius: 12),
        ),
      );
    }

    if (!hasCheckedIn) {
      final Color darker = HSLColor.fromColor(primary)
          .withLightness(
              (HSLColor.fromColor(primary).lightness - 0.12).clamp(0.0, 1.0))
          .toColor();
      return _buildLiquidPillButton(
        label: 'Punch In Now',
        icon: CupertinoIcons.arrow_right_circle_fill,
        gradientColors: [primary, darker],
        onTap: onPunchIn,
      );
    }

    if (hasCheckedIn && !hasCheckedOut) {
      return _buildLiquidPillButton(
        label: 'Complete Shift (Punch Out)',
        icon: CupertinoIcons.stop_circle_fill,
        gradientColors: [const Color(0xFFFF3B30), const Color(0xFFD70015)],
        onTap: onPunchOut,
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? CupertinoColors.white.withValues(alpha: 0.08)
            : CupertinoColors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? CupertinoColors.white.withValues(alpha: 0.12)
              : CupertinoColors.black.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.checkmark_seal_fill,
            color: Color(0xFF34C759),
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            'Shift Complete (${record?.workHours ?? "Done"})',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? CupertinoColors.white.withValues(alpha: 0.7)
                  : const Color(0xFF3A3A3C),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a fluid iOS pill button.
  Widget _buildLiquidPillButton({
    required String label,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        height: 52,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: CupertinoColors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
