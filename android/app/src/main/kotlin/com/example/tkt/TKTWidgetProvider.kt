package com.example.tkt

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.*

/**
 * TKT 課程表 Widget Provider
 * 顯示今日課程和即將到來的課程
 */
class TKTWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
        // 當第一個 Widget 被創建時調用
    }

    override fun onDisabled(context: Context) {
        // 當最後一個 Widget 被刪除時調用
    }

    companion object {
        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val views = RemoteViews(context.packageName, R.layout.tkt_widget)
            
            try {
                // 從 HomeWidget 獲取課程資料
                val widgetData = HomeWidgetPlugin.getData(context)
                val todayCoursesJson = widgetData.getString("today_courses", null)
                val upcomingCoursesJson = widgetData.getString("upcoming_courses", null)
                
                if (todayCoursesJson != null && todayCoursesJson.isNotEmpty()) {
                    val todayCourses = parseCoursesFromJson(todayCoursesJson)
                    val upcomingCourses = if (upcomingCoursesJson != null) {
                        parseCoursesFromJson(upcomingCoursesJson)
                    } else {
                        listOf()
                    }
                    
                    updateWidgetWithCourses(context, views, todayCourses, upcomingCourses)
                } else {
                    updateWidgetWithNoCourses(context, views)
                }
                
            } catch (e: Exception) {
                // 錯誤處理：顯示錯誤訊息
                views.setTextViewText(R.id.widget_title, "課程載入失敗")
                views.setTextViewText(R.id.course_list, "請檢查應用程式")
            }
            
            // 設定點擊 Widget 打開應用程式
            val intentUpdate = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
            intentUpdate.putExtra("from_widget", true)
            
            val pendingIntentUpdate = PendingIntent.getActivity(
                context, 0, intentUpdate, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_container, pendingIntentUpdate)
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
        
        private fun parseCoursesFromJson(jsonString: String): List<Course> {
            val courses = mutableListOf<Course>()
            try {
                val jsonArray = JSONArray(jsonString)
                for (i in 0 until jsonArray.length()) {
                    val courseObj = jsonArray.getJSONObject(i)
                    val course = Course(
                        id = courseObj.getString("id"),
                        name = courseObj.getString("name"),
                        teacher = courseObj.optString("teacher", ""),
                        classroom = courseObj.optString("classroom", ""),
                        dayOfWeek = courseObj.getInt("day_of_week"),
                        startSlot = courseObj.getInt("start_slot"),
                        endSlot = courseObj.getInt("end_slot"),
                        note = courseObj.optString("note", null)
                    )
                    courses.add(course)
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
            return courses
        }
        
        private fun updateWidgetWithCourses(
            context: Context, 
            views: RemoteViews, 
            todayCourses: List<Course>,
            upcomingCourses: List<Course>
        ) {
            val currentTime = Calendar.getInstance()
            val timeFormatter = SimpleDateFormat("HH:mm", Locale.getDefault())
            
            // 設定標題
            val title = if (upcomingCourses.isNotEmpty()) {
                "即將到來 (${upcomingCourses.size})"
            } else if (todayCourses.isNotEmpty()) {
                "今日課程 (${todayCourses.size})"
            } else {
                "今日無課程"
            }
            views.setTextViewText(R.id.widget_title, title)
            
            // 顯示課程列表
            val courseListText = StringBuilder()
            val coursesToShow = if (upcomingCourses.isNotEmpty()) upcomingCourses else todayCourses
            
            for ((index, course) in coursesToShow.take(3).withIndex()) {
                if (index > 0) courseListText.append("\n")
                
                val timeSlot = getTimeSlotInfo(course.startSlot)
                courseListText.append("${timeSlot.label} ${timeSlot.timeRange}")
                courseListText.append("\n${course.name}")
                
                if (course.classroom.isNotEmpty()) {
                    courseListText.append(" @ ${course.classroom}")
                }
                
                if (course.teacher.isNotEmpty()) {
                    courseListText.append("\n${course.teacher}")
                }
            }
            
            if (coursesToShow.size > 3) {
                courseListText.append("\n... 還有 ${coursesToShow.size - 3} 門課程")
            }
            
            views.setTextViewText(R.id.course_list, courseListText.toString())
            
            // 設定最後更新時間
            views.setTextViewText(R.id.last_update, 
                "更新時間: ${timeFormatter.format(currentTime.time)}")
        }
        
        private fun updateWidgetWithNoCourses(context: Context, views: RemoteViews) {
            views.setTextViewText(R.id.widget_title, "今日無課程")
            views.setTextViewText(R.id.course_list, "享受美好的一天！")
            
            val timeFormatter = SimpleDateFormat("HH:mm", Locale.getDefault())
            views.setTextViewText(R.id.last_update, 
                "更新時間: ${timeFormatter.format(Date())}")
        }
        
        private fun getTimeSlotInfo(slot: Int): TimeSlotInfo {
            return when (slot) {
                1 -> TimeSlotInfo("1", "08:10-09:00")
                2 -> TimeSlotInfo("2", "09:10-10:00")
                3 -> TimeSlotInfo("3", "10:20-11:10")
                4 -> TimeSlotInfo("4", "11:20-12:10")
                5 -> TimeSlotInfo("5", "12:20-13:10")
                6 -> TimeSlotInfo("6", "13:20-14:10")
                7 -> TimeSlotInfo("7", "14:20-15:10")
                8 -> TimeSlotInfo("8", "15:30-16:20")
                9 -> TimeSlotInfo("9", "16:30-17:20")
                10 -> TimeSlotInfo("10", "17:30-18:20")
                11 -> TimeSlotInfo("A", "18:25-19:15")
                12 -> TimeSlotInfo("B", "19:20-20:10")
                13 -> TimeSlotInfo("C", "20:15-21:05")
                14 -> TimeSlotInfo("D", "21:10-22:00")
                else -> TimeSlotInfo("?", "未知時間")
            }
        }
        
        internal fun updateWidget(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, TKTWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
            for (appWidgetId in appWidgetIds) {
                updateAppWidget(context, appWidgetManager, appWidgetId)
            }
        }
    }
}

data class Course(
    val id: String,
    val name: String,
    val teacher: String,
    val classroom: String,
    val dayOfWeek: Int,
    val startSlot: Int,
    val endSlot: Int,
    val note: String?
)

data class TimeSlotInfo(
    val label: String,
    val timeRange: String
)
