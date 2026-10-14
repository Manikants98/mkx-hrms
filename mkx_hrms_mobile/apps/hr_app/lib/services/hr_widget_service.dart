import 'package:home_widget/home_widget.dart';

/// Service to synchronize workforce attendance metrics and pending approval queues
/// from the HR App to native Android Home Screen widgets.
class HrWidgetService {
  static const String attendanceWidgetAndroidName = 'HrAttendanceWidgetProvider';
  static const String approvalsWidgetAndroidName = 'HrApprovalsWidgetProvider';

  static const String attendanceWidgetIosName = 'HrAttendanceWidget';
  static const String approvalsWidgetIosName = 'HrApprovalsWidget';

  /// Initializes home widget deep linking listeners for HR app widgets.
  ///
  /// @param onWidgetLaunch Callback invoked with intent URI when app is launched from widget
  static Future<void> initialize({
    void Function(Uri? uri)? onWidgetLaunch,
  }) async {
    try {
      await HomeWidget.setAppGroupId('group.com.mkxhrms.hrapp');

      final initialUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
      if (initialUri != null && onWidgetLaunch != null) {
        onWidgetLaunch(initialUri);
      }

      HomeWidget.widgetClicked.listen((Uri? uri) {
        if (uri != null && onWidgetLaunch != null) {
          onWidgetLaunch(uri);
        }
      });
    } catch (_) {}
  }

  /// Updates the Workforce Attendance Pulse home widget with real-time statistics.
  ///
  /// @param present Number of employees present today
  /// @param late Number of employees arriving late
  /// @param onLeave Number of employees absent or on approved leave
  /// @param totalStaff Total active workforce count
  static Future<void> updateAttendancePulse({
    required int present,
    required int late,
    required int onLeave,
    required int totalStaff,
  }) async {
    try {
      final safeTotal = totalStaff > 0 ? totalStaff : (present + late + onLeave);
      final rateNum = safeTotal > 0 ? ((present / safeTotal) * 100).toStringAsFixed(1) : '0.0';

      await HomeWidget.saveWidgetData<String>('hr_present_count', present.toString());
      await HomeWidget.saveWidgetData<String>('hr_late_count', late.toString());
      await HomeWidget.saveWidgetData<String>('hr_leave_count', onLeave.toString());
      await HomeWidget.saveWidgetData<String>('hr_total_staff', safeTotal.toString());
      await HomeWidget.saveWidgetData<String>('hr_attendance_rate', '$rateNum%');

      await HomeWidget.updateWidget(
        name: attendanceWidgetAndroidName,
        androidName: attendanceWidgetAndroidName,
        iOSName: attendanceWidgetIosName,
      );
    } catch (_) {}
  }

  /// Updates the Pending Approvals Queue home widget with current pending requests.
  ///
  /// @param pendingCount Count of pending leave applications
  /// @param latestApplicant Employee name and leave type summary
  /// @param latestDuration Date range and duration description
  /// @param latestReason Application reason or notes
  static Future<void> updatePendingApprovals({
    required int pendingCount,
    String? latestApplicant,
    String? latestDuration,
    String? latestReason,
  }) async {
    try {
      await HomeWidget.saveWidgetData<String>(
        'hr_pending_count',
        pendingCount.toString(),
      );
      await HomeWidget.saveWidgetData<String>(
        'hr_latest_applicant',
        latestApplicant ?? (pendingCount > 0 ? '$pendingCount Pending Requests' : 'No Pending Requests'),
      );
      await HomeWidget.saveWidgetData<String>(
        'hr_latest_duration',
        latestDuration ?? (pendingCount > 0 ? 'Tap to view pending approvals' : 'All leave requests are up to date'),
      );
      await HomeWidget.saveWidgetData<String>(
        'hr_latest_reason',
        latestReason ?? (pendingCount > 0 ? 'Action required by HR Manager' : 'Action queue clear'),
      );

      await HomeWidget.updateWidget(
        name: approvalsWidgetAndroidName,
        androidName: approvalsWidgetAndroidName,
        iOSName: approvalsWidgetIosName,
      );
    } catch (_) {}
  }
}
