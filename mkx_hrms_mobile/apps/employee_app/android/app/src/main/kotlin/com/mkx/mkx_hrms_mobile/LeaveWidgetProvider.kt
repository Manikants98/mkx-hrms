package com.mkx.mkx_hrms_mobile

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.net.Uri
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * AppWidgetProvider for MKX HRMS Leave Balance Glance home widget.
 */
class LeaveWidgetProvider : HomeWidgetProvider() {
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
            val views = RemoteViews(context.packageName, R.layout.leave_widget_layout).apply {
                val options = appWidgetManager.getAppWidgetOptions(widgetId)
                val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
                val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)

                /** Open App on widget click with deep link to leaves module */
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("mkxhrms://apply_leave")
                )
                setOnClickPendingIntent(R.id.widget_leave_container, pendingIntent)

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

                val hasPending = pendingRequests != "0" && pendingRequests.isNotEmpty()
                val totalText = if (hasPending) {
                    "Total: $totalLeaves"
                } else {
                    "Total: $totalLeaves Days"
                }
                setTextViewText(R.id.widget_leave_total_text, totalText)

                val pendingText = if (hasPending) {
                    "● $pendingRequests Pending"
                } else {
                    "All Leaves Approved"
                }
                setTextViewText(R.id.widget_leave_pending_hint, pendingText)
                if (hasPending) {
                    setTextColor(R.id.widget_leave_pending_hint, Color.parseColor("#F59E0B"))
                } else {
                    setTextColor(R.id.widget_leave_pending_hint, Color.parseColor("#A1A1AA"))
                }

                /** Responsive layout adaptations based on resized dimensions */
                if (minHeight in 1..90) {
                    setViewVisibility(R.id.widget_leave_header, View.GONE)
                } else {
                    setViewVisibility(R.id.widget_leave_header, View.VISIBLE)
                }

                if (minWidth in 1..120) {
                    setViewVisibility(R.id.widget_leave_employee_name, View.GONE)
                } else {
                    setViewVisibility(R.id.widget_leave_employee_name, View.VISIBLE)
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
