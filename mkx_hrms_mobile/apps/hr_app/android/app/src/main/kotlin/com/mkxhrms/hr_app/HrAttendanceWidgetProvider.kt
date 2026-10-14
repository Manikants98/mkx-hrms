package com.mkxhrms.hr_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * AppWidgetProvider for Workforce Attendance Pulse widget in MKX HR App.
 */
class HrAttendanceWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.hr_attendance_widget_layout).apply {
                /** Open HR App and navigate to Live Attendance screen */
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("mkxhrms_hr://attendance")
                )
                setOnClickPendingIntent(R.id.widget_attendance_container, pendingIntent)
                setOnClickPendingIntent(R.id.widget_attendance_action_btn, pendingIntent)

                val presentCount = widgetData.getString("hr_present_count", "0") ?: "0"
                val lateCount = widgetData.getString("hr_late_count", "0") ?: "0"
                val leaveCount = widgetData.getString("hr_leave_count", "0") ?: "0"
                val totalStaff = widgetData.getString("hr_total_staff", "--") ?: "--"
                val rate = widgetData.getString("hr_attendance_rate", "--%") ?: "--%"

                setTextViewText(R.id.widget_present_count, presentCount)
                setTextViewText(R.id.widget_late_count, lateCount)
                setTextViewText(R.id.widget_leave_count, leaveCount)
                setTextViewText(R.id.widget_attendance_rate, "$rate Present")
                setTextViewText(R.id.widget_total_workforce, "Total Staff: $totalStaff Active")
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
