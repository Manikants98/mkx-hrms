import 'package:home_widget/home_widget.dart';
import '../features/leaves/models/leave_model.dart';

/// Service to synchronize Leave Balances and Quotas to the native Home Screen Widget.
class LeaveWidgetService {
  static const String androidWidgetName = 'LeaveWidgetProvider';
  static const String iOSWidgetName = 'LeaveWidget';

  /// Updates the native Leave Balance Glance home widget with the latest quota numbers.
  ///
  /// @param balances Current leave balance summary
  /// @param employeeName Formatted name of the employee
  static Future<void> updateLeaveData({
    required LeaveBalances? balances,
    String? employeeName,
  }) async {
    try {
      final casualRemaining = balances?.casual.remaining ?? 0;
      final sickRemaining = balances?.sick.remaining ?? 0;
      final annualRemaining = balances?.annual.remaining ?? 0;

      int totalRemaining = casualRemaining + sickRemaining + annualRemaining;
      if (balances != null && balances.list.isNotEmpty) {
        final sumFromList = balances.list.fold<int>(
          0,
          (int sum, LeaveQuota q) => sum + q.remaining,
        );
        if (sumFromList > 0) {
          totalRemaining = sumFromList;
        }
      }

      final pendingRequests = balances?.pendingRequests ?? 0;

      await HomeWidget.saveWidgetData<String>(
        'leave_casual',
        casualRemaining.toString().padLeft(2, '0'),
      );
      await HomeWidget.saveWidgetData<String>(
        'leave_sick',
        sickRemaining.toString().padLeft(2, '0'),
      );
      await HomeWidget.saveWidgetData<String>(
        'leave_annual',
        annualRemaining.toString().padLeft(2, '0'),
      );
      await HomeWidget.saveWidgetData<String>(
        'leave_total',
        totalRemaining.toString(),
      );
      await HomeWidget.saveWidgetData<String>(
        'leave_pending',
        pendingRequests.toString(),
      );
      await HomeWidget.saveWidgetData<String>(
        'employee_name',
        employeeName ?? 'Employee',
      );

      await HomeWidget.updateWidget(
        name: androidWidgetName,
        androidName: androidWidgetName,
        iOSName: iOSWidgetName,
      );
    } catch (_) {}
  }
}
