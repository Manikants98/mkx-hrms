package com.mkx.employee_app_ios27

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * AppWidgetProvider for MKX HRMS Live Shift & Work Hours Tracker home widget with iOS 27 aesthetics.
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
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("mkxhrms://shift_tracker")
                )
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)
                setOnClickPendingIntent(R.id.widget_action_btn, pendingIntent)

                val rawStatus = widgetData.getString("shift_status", "Not Clocked In") ?: "Not Clocked In"
                val shiftName = widgetData.getString("shift_name", "General Shift") ?: "General Shift"
                val checkInTime = widgetData.getString("check_in_time", "--:--") ?: "--:--"
                val workHours = widgetData.getString("work_hours", "0h 00m") ?: "0h 00m"
                val employeeName = widgetData.getString("employee_name", "Employee") ?: "Employee"
                val date = widgetData.getString("shift_date", "") ?: ""

                val isCheckedIn = rawStatus.contains("In", ignoreCase = true) ||
                        rawStatus.contains("Duty", ignoreCase = true) ||
                        rawStatus.contains("Present", ignoreCase = true) ||
                        rawStatus.contains("Active", ignoreCase = true)

                val displayStatus = if (rawStatus.startsWith("●")) rawStatus else "● $rawStatus"
                setTextViewText(R.id.widget_status_text, displayStatus)

                if (isCheckedIn) {
                    setTextColor(R.id.widget_status_text, Color.parseColor("#30D158"))
                    setTextViewText(R.id.widget_action_btn, "Punch Out")
                } else if (rawStatus.contains("Out", ignoreCase = true) || rawStatus.contains("Completed", ignoreCase = true)) {
                    setTextColor(R.id.widget_status_text, Color.parseColor("#64D2FF"))
                    setTextViewText(R.id.widget_action_btn, "Punch In")
                } else {
                    setTextColor(R.id.widget_status_text, Color.parseColor("#FF9F0A"))
                    setTextViewText(R.id.widget_action_btn, "Punch In")
                }

                setTextViewText(R.id.widget_shift_name, shiftName)
                setTextViewText(R.id.widget_check_in, "Clocked In: $checkInTime")
                setTextViewText(R.id.widget_work_hours, workHours)
                setTextViewText(R.id.widget_employee_name, employeeName)
                if (date.isNotEmpty()) {
                    setTextViewText(R.id.widget_date, date)
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
