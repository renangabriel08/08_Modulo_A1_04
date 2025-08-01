package edu.ws2024.d01.a1

import es.antonborri.home_widget.HomeWidgetProvider
import es.antonborri.home_widget.HomeWidgetLaunchIntent

import android.content.SharedPreferences
import android.content.Context
import android.appwidget.AppWidgetManager
import android.widget.RemoteViews
import android.net.Uri

class HomeWidgetExampleProvider : HomeWidgetProvider() {
    override fun onUpdate(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetIds: IntArray,
            widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.example_layout).apply {
                val count = widgetData.getInt("counter", 0)
                setTextViewText(R.id.titulo, "Estou com saudades, volte aqui vamos jogar e aprender!")

                val pendingIntentWithData = HomeWidgetLaunchIntent.getActivity(
                        context,
                        MainActivity::class.java,
                        Uri.parse("homeWidgetExample://message?message=ola"))
                setOnClickPendingIntent(R.id.widget_message, pendingIntentWithData)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
