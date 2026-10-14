package com.mkxhrms.hr_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * AppWidgetProvider for Pending Approvals Queue widget in MKX HR App.
 */
class HrApprovalsWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.hr_approvals_widget_layout).apply {
                /** Open HR App and navigate to Pending Leaves screen */
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("mkxhrms_hr://leaves")
                )
                setOnClickPendingIntent(R.id.widget_approvals_container, pendingIntent)
                setOnClickPendingIntent(R.id.widget_approvals_action_btn, pendingIntent)

                val pendingCount = widgetData.getString("hr_pending_count", "0") ?: "0"
                val latestApplicant = widgetData.getString("hr_latest_applicant", "No Pending Requests") ?: "No Pending Requests"
                val latestDuration = widgetData.getString("hr_latest_duration", "All leave requests are up to date") ?: "All leave requests are up to date"
                val latestReason = widgetData.getString("hr_latest_reason", "Tap to view leaves ledger") ?: "Tap to view leaves ledger"

                setTextViewText(R.id.widget_pending_pill, "$pendingCount Pending")
                setTextViewText(R.id.widget_approval_applicant, latestApplicant)
                setTextViewText(R.id.widget_approval_duration, latestDuration)
                setTextViewText(R.id.widget_approval_reason, latestReason)

                val summaryText = if (pendingCount == "0" || pendingCount.isEmpty()) {
                    "Action Queue Clear"
                } else {
                    "$pendingCount Request(s) waiting for review"
                }
                setTextViewText(R.id.widget_approval_summary, summaryText)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
