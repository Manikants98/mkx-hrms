import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import '../features/attendance/models/attendance_model.dart';

/// Service to sync Live Shift and Work Hours data to the native Home Screen Widget.
class ShiftWidgetService {
  static const String androidWidgetName = 'ShiftWidgetProvider';
  static const String iOSWidgetName = 'ShiftWidget';

  /// Initializes widget listener for click events when launched from home screen.
  ///
  /// @param onWidgetLaunch Callback invoked when app is opened via home widget
  static Future<void> initialize({
    void Function(Uri? uri)? onWidgetLaunch,
  }) async {
    try {
      await HomeWidget.setAppGroupId('group.com.mkx.mkxhrms');

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

  /// Computes live work hours duration string between clock-in and current time.
  ///
  /// @param checkIn Clock in time string formatted like 'hh:mm a'
  /// @param now Current timestamp
  static String computeLiveHours(String checkIn, DateTime now) {
    try {
      final format = DateFormat('hh:mm a');
      final checkInTime = format.parse(checkIn);
      final nowTime = DateTime(1970, 1, 1, now.hour, now.minute);
      var duration = nowTime.difference(checkInTime);
      if (duration.isNegative) {
        duration += const Duration(days: 1);
      }
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    } catch (_) {
      return '0h 00m';
    }
  }

  /// Computes epoch timestamp in milliseconds from clock-in time string.
  ///
  /// @param checkIn Clock-in time string formatted like 'hh:mm a' or 'HH:mm:ss'
  /// @param recordDate Optional date string of the attendance record
  static int? computeCheckInEpoch(String? checkIn, String? recordDate) {
    if (checkIn == null || checkIn.isEmpty || checkIn == '--:--') return null;
    try {
      DateTime? parsedDate;
      if (recordDate != null && recordDate.isNotEmpty) {
        parsedDate = DateTime.tryParse(recordDate);
      }
      final today = parsedDate ?? DateTime.now();

      final formats = [
        DateFormat('hh:mm a'),
        DateFormat('h:mm a'),
        DateFormat('HH:mm:ss'),
        DateFormat('HH:mm'),
        DateFormat('hh:mm:ss a'),
      ];

      DateTime? timeOnly;
      for (final f in formats) {
        try {
          timeOnly = f.parse(checkIn.trim());
          break;
        } catch (_) {}
      }

      if (timeOnly != null) {
        final fullDateTime = DateTime(
          today.year,
          today.month,
          today.day,
          timeOnly.hour,
          timeOnly.minute,
          timeOnly.second,
        );
        return fullDateTime.millisecondsSinceEpoch;
      }
    } catch (_) {}
    return null;
  }

  /// Updates the home screen widget with the latest shift and attendance metrics.
  ///
  /// @param record Current daily attendance record
  /// @param employeeName Name of logged-in employee
  /// @param shiftName Shift designation (e.g. 'General Shift')
  /// @param currentTime Current timestamp
  static Future<void> updateShiftData({
    required AttendanceRecord? record,
    String? employeeName,
    String? shiftName,
    DateTime? currentTime,
  }) async {
    try {
      final now = currentTime ?? DateTime.now();
      final hasCheckedIn = record?.hasCheckedIn ?? false;
      final hasCheckedOut = record?.hasCheckedOut ?? false;

      String status = 'Not Clocked In';
      String workHours = '0h 00m';
      String checkInTime = '--:--';
      int checkInEpoch = 0;

      if (hasCheckedIn && !hasCheckedOut) {
        status = 'Punched In';
        checkInTime = record!.checkIn;
        workHours = computeLiveHours(record.checkIn, now);
        checkInEpoch = computeCheckInEpoch(record.checkIn, record.date) ??
            now.millisecondsSinceEpoch;
      } else if (hasCheckedOut) {
        status = 'Punched Out';
        checkInTime = record!.checkIn;
        workHours = record.workHours;
      } else if (record != null &&
          record.status.isNotEmpty &&
          record.status != 'Absent') {
        status = record.status;
      }

      final dateStr = DateFormat('EEE, d MMM').format(now);

      await HomeWidget.saveWidgetData<String>('shift_status', status);
      await HomeWidget.saveWidgetData<String>(
          'shift_name', shiftName ?? 'General Shift');
      await HomeWidget.saveWidgetData<String>('check_in_time', checkInTime);
      await HomeWidget.saveWidgetData<String>('work_hours', workHours);
      await HomeWidget.saveWidgetData<int>('check_in_epoch', checkInEpoch);
      await HomeWidget.saveWidgetData<String>(
          'check_in_epoch_str', checkInEpoch.toString());
      await HomeWidget.saveWidgetData<String>(
          'employee_name', employeeName ?? 'Employee');
      await HomeWidget.saveWidgetData<String>('shift_date', dateStr);

      await HomeWidget.updateWidget(
        name: androidWidgetName,
        androidName: androidWidgetName,
        iOSName: iOSWidgetName,
      );
    } catch (_) {}
  }
}
