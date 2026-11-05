package com.mkx.mkx_hrms_mobile

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.net.Uri
import android.os.Bundle
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * AppWidgetProvider for MKX HRMS Live Shift & Work Hours Tracker home widget
 */
class ShiftWidgetProvider : HomeWidgetProvider() {
    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        onUpdate(context, appWidgetManager, intArrayOf(appWidgetId))
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.shift_widget_layout).apply {
                val options = appWidgetManager.getAppWidgetOptions(widgetId)
                val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
                val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)

                /** Open App on widget click with deep link */
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("mkxhrms://shift_tracker")
                )
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)

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

                /** Responsive layout adaptations based on resized dimensions */
                if (minHeight in 1..90) {
                    setViewVisibility(R.id.widget_employee_name, View.GONE)
                    setViewVisibility(R.id.widget_worked_today_label, View.GONE)
                } else {
                    setViewVisibility(R.id.widget_employee_name, View.VISIBLE)
                    setViewVisibility(R.id.widget_worked_today_label, View.VISIBLE)
                }

                if (minWidth in 1..120) {
                    setViewVisibility(R.id.widget_date, View.GONE)
                } else {
                    if (date.isNotEmpty()) {
                        setViewVisibility(R.id.widget_date, View.VISIBLE)
                    }
                }

                val isCheckedIn = status.contains("In", ignoreCase = true) ||
                        status.contains("Duty", ignoreCase = true) ||
                        status.contains("Present", ignoreCase = true) ||
                        status.contains("Active", ignoreCase = true)

                if (isCheckedIn) {
                    setTextColor(R.id.widget_status_text, Color.parseColor("#10B981"))
                    setInt(R.id.widget_status_text, "setBackgroundResource", R.drawable.widget_status_pill_present)
                } else if (status.contains("Out", ignoreCase = true) || status.contains("Completed", ignoreCase = true)) {
                    setTextColor(R.id.widget_status_text, Color.parseColor("#0EA5E9"))
                    setInt(R.id.widget_status_text, "setBackgroundResource", R.drawable.widget_status_pill_out)
                } else {
                    setTextColor(R.id.widget_status_text, Color.parseColor("#F59E0B"))
                    setInt(R.id.widget_status_text, "setBackgroundResource", R.drawable.widget_status_pill_absent)
                }

                /**
                 * When clocked in, use Android's native Chronometer to tick live continuously
                 * on the home screen even when the app is completely closed.
                 * A 16-hour maximum window prevents the chronometer from ticking indefinitely
                 * when the app remains inactive for days or weeks.
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
                val maxShiftDurationMs = 16L * 60 * 60 * 1000
                val elapsedSinceCheckIn = if (checkInEpoch > 0L) nowWall - checkInEpoch else 0L

                val isShiftActive = isCheckedIn &&
                        checkInEpoch > 0L &&
                        checkInEpoch <= nowWall &&
                        elapsedSinceCheckIn < maxShiftDurationMs

                if (isShiftActive) {
                    val chronometerBase = nowElapsed - elapsedSinceCheckIn
                    setChronometer(R.id.widget_chronometer, chronometerBase, null, true)
                    setViewVisibility(R.id.widget_chronometer, View.VISIBLE)
                    setViewVisibility(R.id.widget_work_hours, View.GONE)
                } else {
                    setChronometer(R.id.widget_chronometer, 0L, null, false)
                    setViewVisibility(R.id.widget_chronometer, View.GONE)
                    setViewVisibility(R.id.widget_work_hours, View.VISIBLE)
                    if (isCheckedIn && elapsedSinceCheckIn >= maxShiftDurationMs) {
                        setTextViewText(R.id.widget_status_text, "Shift Ended")
                        setTextViewText(R.id.widget_work_hours, "--:--")
                    } else {
                        setTextViewText(R.id.widget_work_hours, workHours)
                    }
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
