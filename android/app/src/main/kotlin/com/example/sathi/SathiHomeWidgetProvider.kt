package com.example.sathi

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import org.json.JSONObject

class SathiHomeWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.sathi_widget_layout).apply {
                val pendingIntent =
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)

                val snapshotJson = widgetData.getString("sathi_widget_snapshot", null)
                val friend = parseFirstFriend(snapshotJson)

                if (friend == null) {
                    setTextViewText(R.id.widget_name, "Sathi")
                    setViewVisibility(R.id.widget_image, View.GONE)
                    setViewVisibility(R.id.widget_keyword_container, View.GONE)
                    setViewVisibility(R.id.widget_empty, View.VISIBLE)
                    setViewVisibility(R.id.widget_suggestion, View.GONE)
                    setTextViewText(R.id.widget_empty, "Nothing to show right now")
                } else {
                    setTextViewText(R.id.widget_name, friend.displayName)
                    setViewVisibility(R.id.widget_empty, View.GONE)
                    bindKeywords(this, friend.keywords)
                    bindSuggestion(this, friend.supportSuggestion)

                    val photoPath = friend.photoPath
                    if (photoPath != null) {
                        val bitmap = decodeWidgetBitmap(photoPath)
                        if (bitmap != null) {
                            setImageViewBitmap(R.id.widget_image, bitmap)
                            setViewVisibility(R.id.widget_image, View.VISIBLE)
                        } else {
                            setViewVisibility(R.id.widget_image, View.GONE)
                        }
                    } else {
                        setViewVisibility(R.id.widget_image, View.GONE)
                    }
                }
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun parseFirstFriend(snapshotJson: String?): FriendWidgetData? {
        if (snapshotJson.isNullOrEmpty()) return null
        return try {
            val root = JSONObject(snapshotJson)
            val friends = root.optJSONArray("friends") ?: JSONArray()
            if (friends.length() == 0) return null
            val item = friends.optJSONObject(0) ?: return null
            val keywordsArray = item.optJSONArray("voiceKeywords") ?: JSONArray()
            val keywords = mutableListOf<String>()
            for (index in 0 until keywordsArray.length()) {
                keywords.add(keywordsArray.optString(index))
            }

            FriendWidgetData(
                displayName = item.optString("displayName", "Sathi friend"),
                photoPath = item.optString("photoPath").takeIf { it.isNotEmpty() },
                keywords = keywords.filter { it.isNotBlank() }.take(3),
                supportSuggestion = item.optString("supportSuggestion").takeIf { it.isNotEmpty() },
            )
        } catch (_: Exception) {
            null
        }
    }

    private fun bindKeywords(views: RemoteViews, keywords: List<String>) {
        if (keywords.isEmpty()) {
            views.setViewVisibility(R.id.widget_keyword_container, View.GONE)
            return
        }

        views.setViewVisibility(R.id.widget_keyword_container, View.VISIBLE)
        val ids = listOf(
            R.id.widget_keyword_one,
            R.id.widget_keyword_two,
            R.id.widget_keyword_three,
        )

        ids.forEachIndexed { index, id ->
            val keyword = keywords.getOrNull(index)
            if (keyword == null) {
                views.setViewVisibility(id, View.GONE)
            } else {
                views.setViewVisibility(id, View.VISIBLE)
                views.setTextViewText(id, keyword)
            }
        }

        views.setViewVisibility(
            R.id.widget_keyword_gap_one,
            if (keywords.size > 1) View.VISIBLE else View.GONE,
        )
        views.setViewVisibility(
            R.id.widget_keyword_row_two,
            if (keywords.size > 2) View.VISIBLE else View.GONE,
        )
    }

    private fun bindSuggestion(views: RemoteViews, suggestion: String?) {
        if (suggestion == null || suggestion.isBlank()) {
            views.setViewVisibility(R.id.widget_suggestion, View.GONE)
            return
        }

        views.setViewVisibility(R.id.widget_suggestion, View.VISIBLE)
        views.setTextViewText(R.id.widget_suggestion, suggestion)
    }

    private fun decodeWidgetBitmap(path: String): android.graphics.Bitmap? {
        val bounds = BitmapFactory.Options().apply {
            inJustDecodeBounds = true
        }
        BitmapFactory.decodeFile(path, bounds)

        val sampleSize = calculateInSampleSize(bounds, 420, 420)
        val options = BitmapFactory.Options().apply {
            inSampleSize = sampleSize
            inPreferredConfig = android.graphics.Bitmap.Config.RGB_565
        }
        return BitmapFactory.decodeFile(path, options)
    }

    private fun calculateInSampleSize(
        options: BitmapFactory.Options,
        reqWidth: Int,
        reqHeight: Int,
    ): Int {
        val height = options.outHeight
        val width = options.outWidth
        var inSampleSize = 1

        if (height > reqHeight || width > reqWidth) {
            val halfHeight = height / 2
            val halfWidth = width / 2

            while ((halfHeight / inSampleSize) >= reqHeight &&
                (halfWidth / inSampleSize) >= reqWidth
            ) {
                inSampleSize *= 2
            }
        }

        return inSampleSize.coerceAtLeast(1)
    }
}

private data class FriendWidgetData(
    val displayName: String,
    val photoPath: String?,
    val keywords: List<String>,
    val supportSuggestion: String?,
)
