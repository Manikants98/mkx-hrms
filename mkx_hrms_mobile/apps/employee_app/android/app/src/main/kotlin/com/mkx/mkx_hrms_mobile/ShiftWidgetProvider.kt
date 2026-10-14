package com.mkx.mkx_hrms_mobile

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * AppWidgetProvider for MKX HRMS Live Shift & Work Hours Tracker home widget
 */
class ShiftWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.shift_widget_layout).apply {
                /** Open App on widget click with deep link */
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("mkxhrms://shift_tracker")
                )
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)
                setOnClickPendingIntent(R.id.widget_action_btn, pendingIntent)

                val status = widgetData.getString("shift_status", "Not Clocked In") ?: "Not Clocked In"
                val shiftName = widgetData.getString("shift_name", "General Shift") ?: "General Shift"
                val checkInTime = widgetData.getString("check_in_time", "--:--") ?: "--:--"
                val workHours = widgetData.getString("work_hours", "0h 00m") ?: "0h 00m"
                val employeeName = widgetData.getString("employee_name", "Employee") ?: "Employee"
                val date = widgetData.getString("shift_date", "") ?: ""

                setTextViewText(R.id.widget_status_text, status)
                setTextViewText(R.id.widget_shift_name, shiftName)
                setTextViewText(R.id.widget_check_in, "Clocked In: $checkInTime")
                setTextViewText(R.id.widget_employee_name, employeeName)
                if (date.isNotEmpty()) {
                    setTextViewText(R.id.widget_date, date)
                }

                val isCheckedIn = status.contains("In", ignoreCase = true) ||
                        status.contains("Duty", ignoreCase = true) ||
                        status.contains("Present", ignoreCase = true) ||
                        status.contains("Active", ignoreCase = true)

                setTextViewText(R.id.widget_action_btn, if (isCheckedIn) "Punch Out" else "Punch In")

                /**
                 * When clocked in, use Android's native Chronometer to tick live continuously
                 * on the home screen even when the app is completely closed.
                 */
                val checkInEpoch = try {
                    val epochLong = widgetData.getLong("check_in_epoch", 0L)
                    if (epochLong > 0L) epochLong
                    else widgetData.getString("check_in_epoch_str", null)?.toLongOrNull() ?: 0L
                } catch (e: Exception) {
                    widgetData.getString("check_in_epoch_str", null)?.toLongOrNull() ?: 0L
                }

                val nowWall = System.currentTimeMillis()
                val nowElapsed = SystemClock.elapsedRealtime()

                if (isCheckedIn && checkInEpoch > 0L && checkInEpoch <= nowWall) {
                    val elapsedSinceCheckIn = nowWall - checkInEpoch
                    val chronometerBase = nowElapsed - elapsedSinceCheckIn
                    setChronometer(R.id.widget_chronometer, chronometerBase, null, true)
                    setViewVisibility(R.id.widget_chronometer, View.VISIBLE)
                    setViewVisibility(R.id.widget_work_hours, View.GONE)
                } else {
                    setChronometer(R.id.widget_chronometer, 0L, null, false)
                    setViewVisibility(R.id.widget_chronometer, View.GONE)
                    setViewVisibility(R.id.widget_work_hours, View.VISIBLE)
                    setTextViewText(R.id.widget_work_hours, workHours)
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
