package com.mkx.mkx_hrms_mobile

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * AppWidgetProvider for MKX HRMS Leave Balance Glance home widget.
 */
class LeaveWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.leave_widget_layout).apply {
                /** Open App on widget click with deep link to leaves module */
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("mkxhrms://apply_leave")
                )
                setOnClickPendingIntent(R.id.widget_leave_container, pendingIntent)
                setOnClickPendingIntent(R.id.widget_leave_action_btn, pendingIntent)

                val employeeName = widgetData.getString("employee_name", "Employee") ?: "Employee"
                val casualLeaves = widgetData.getString("leave_casual", "0") ?: "0"
                val sickLeaves = widgetData.getString("leave_sick", "0") ?: "0"
                val annualLeaves = widgetData.getString("leave_annual", "0") ?: "0"
                val totalLeaves = widgetData.getString("leave_total", "--") ?: "--"
                val pendingRequests = widgetData.getString("leave_pending", "0") ?: "0"

                setTextViewText(R.id.widget_leave_employee_name, employeeName)
                setTextViewText(R.id.widget_leave_casual, casualLeaves)
                setTextViewText(R.id.widget_leave_sick, sickLeaves)
                setTextViewText(R.id.widget_leave_annual, annualLeaves)

                val totalText = if (pendingRequests != "0" && pendingRequests.isNotEmpty()) {
                    "Total: $totalLeaves • Pending: $pendingRequests"
                } else {
                    "Total Available: $totalLeaves Days"
                }
                setTextViewText(R.id.widget_leave_total_text, totalText)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
