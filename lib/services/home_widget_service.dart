import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../models/course_model.dart';
import '../utils/course_time_util.dart';

class HomeWidgetService {
  static const String _coursesKey = 'courses';
  static const String _lastUpdateKey = 'last_update';
  static const String _todayCoursesKey = 'today_courses';
  static const String _upcomingCoursesKey = 'upcoming_courses';
  
  // iOS App Group ID 和 Android Widget Provider 的唯一識別碼
  static const String _iOSGroupId = 'group.com.example.tkt.TKTWidget';
  static const String _androidWidgetName = 'TKTWidgetProvider';

  static HomeWidgetService? _instance;

  HomeWidgetService._();

  static HomeWidgetService get instance {
    _instance ??= HomeWidgetService._();
    return _instance!;
  }

  /// 初始化 HomeWidget
  Future<void> initialize() async {
    try {
      // 設定 iOS App Group ID
      await HomeWidget.setAppGroupId(_iOSGroupId);
      debugPrint('HomeWidgetService 初始化成功');
    } catch (e) {
      debugPrint('HomeWidgetService 初始化失敗: $e');
    }
  }

  /// 儲存課程資料到 Widget
  Future<bool> saveCourses(List<Course> courses) async {
    try {
      debugPrint('🔄 開始儲存 ${courses.length} 門課程到 Widget');
      
      // 將課程列表轉換為 JSON 字串
      final coursesJson = courses.map((course) => course.toJson()).toList();
      final coursesJsonString = jsonEncode(coursesJson);
      
      // 儲存所有課程資料
      await HomeWidget.saveWidgetData<String>(_coursesKey, coursesJsonString);
      
      // 儲存最後更新時間
      await HomeWidget.saveWidgetData<int>(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
      
      // 計算並儲存今日課程
      final todayCourses = _getTodayCoursesFromList(courses);
      final todayCoursesJson = jsonEncode(todayCourses.map((c) => c.toJson()).toList());
      await HomeWidget.saveWidgetData<String>(_todayCoursesKey, todayCoursesJson);
      
      // 計算並儲存即將到來的課程
      final upcomingCourses = _getUpcomingCoursesFromList(todayCourses);
      final upcomingCoursesJson = jsonEncode(upcomingCourses.map((c) => c.toJson()).toList());
      await HomeWidget.saveWidgetData<String>(_upcomingCoursesKey, upcomingCoursesJson);
      
      // 通知 Widget 更新
      await _updateWidget();
      
      debugPrint('✅ 已儲存 ${courses.length} 門課程到 Widget');
      debugPrint('📋 今日課程: ${todayCourses.length} 門');
      debugPrint('⏰ 即將到來: ${upcomingCourses.length} 門');
      
      return true;
    } catch (e) {
      debugPrint('💥 儲存課程到 Widget 時發生錯誤: $e');
      return false;
    }
  }

  /// 從 Widget 載入課程資料
  Future<List<Course>> loadCourses() async {
    try {
      final coursesJsonString = await HomeWidget.getWidgetData<String>(_coursesKey);
      
      if (coursesJsonString == null || coursesJsonString.isEmpty) {
        debugPrint('📋 Widget 中沒有課程資料');
        return [];
      }
      
      final coursesJson = jsonDecode(coursesJsonString) as List;
      final courses = coursesJson
          .map((courseData) => Course.fromJson(courseData as Map<String, dynamic>))
          .toList();
      
      debugPrint('📋 從 Widget 載入 ${courses.length} 門課程');
      return courses;
    } catch (e) {
      debugPrint('❌ 從 Widget 載入課程時發生錯誤: $e');
      return [];
    }
  }

  /// 獲取最後更新時間
  Future<DateTime?> getLastUpdateTime() async {
    try {
      final timestamp = await HomeWidget.getWidgetData<int>(_lastUpdateKey);
      return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
    } catch (e) {
      debugPrint('❌ 獲取最後更新時間時發生錯誤: $e');
      return null;
    }
  }

  /// 清除所有課程資料
  Future<bool> clearCourses() async {
    try {
      await HomeWidget.saveWidgetData<String>(_coursesKey, null);
      await HomeWidget.saveWidgetData<int>(_lastUpdateKey, null);
      await HomeWidget.saveWidgetData<String>(_todayCoursesKey, null);
      await HomeWidget.saveWidgetData<String>(_upcomingCoursesKey, null);
      
      // 通知 Widget 更新
      await _updateWidget();
      
      debugPrint('✅ 已清除 Widget 中的課程資料');
      return true;
    } catch (e) {
      debugPrint('❌ 清除 Widget 課程資料時發生錯誤: $e');
      return false;
    }
  }

  /// 檢查是否有資料
  Future<bool> hasCourseData() async {
    try {
      final coursesData = await HomeWidget.getWidgetData<String>(_coursesKey);
      return coursesData != null && coursesData.isNotEmpty;
    } catch (e) {
      debugPrint('❌ 檢查課程資料時發生錯誤: $e');
      return false;
    }
  }

  /// 獲取今日課程
  Future<List<Course>> getTodayCourses() async {
    try {
      final todayCoursesJson = await HomeWidget.getWidgetData<String>(_todayCoursesKey);
      
      if (todayCoursesJson == null || todayCoursesJson.isEmpty) {
        // 如果沒有預計算的今日課程，從所有課程中計算
        final allCourses = await loadCourses();
        return _getTodayCoursesFromList(allCourses);
      }
      
      final coursesJson = jsonDecode(todayCoursesJson) as List;
      final courses = coursesJson
          .map((courseData) => Course.fromJson(courseData as Map<String, dynamic>))
          .toList();
      
      debugPrint('📋 今日課程數量：${courses.length}');
      return courses;
    } catch (e) {
      debugPrint('❌ 獲取今日課程時發生錯誤: $e');
      return [];
    }
  }

  /// 獲取即將到來的課程
  Future<List<Course>> getUpcomingCourses() async {
    try {
      final upcomingCoursesJson = await HomeWidget.getWidgetData<String>(_upcomingCoursesKey);
      
      if (upcomingCoursesJson == null || upcomingCoursesJson.isEmpty) {
        // 如果沒有預計算的即將到來課程，重新計算
        final todayCourses = await getTodayCourses();
        return _getUpcomingCoursesFromList(todayCourses);
      }
      
      final coursesJson = jsonDecode(upcomingCoursesJson) as List;
      final courses = coursesJson
          .map((courseData) => Course.fromJson(courseData as Map<String, dynamic>))
          .toList();
      
      debugPrint('⏰ 即將到來的課程數量：${courses.length}');
      return courses;
    } catch (e) {
      debugPrint('❌ 獲取即將到來課程時發生錯誤: $e');
      return [];
    }
  }

  /// 手動更新 Widget
  Future<void> updateWidget() async {
    await _updateWidget();
  }

  /// 內部方法：通知 Widget 更新
  Future<void> _updateWidget() async {
    try {
      await HomeWidget.updateWidget(
        name: _androidWidgetName, // Android Widget Provider 類別名稱
        iOSName: 'TKTWidget', // iOS Widget 名稱
      );
      debugPrint('✅ Widget 更新通知已發送');
    } catch (e) {
      debugPrint('❌ Widget 更新失敗: $e');
    }
  }

  /// 從課程列表中篩選今日課程
  List<Course> _getTodayCoursesFromList(List<Course> courses) {
    final now = DateTime.now();
    final todayCourses = courses
        .where((course) => course.dayOfWeek == now.weekday)
        .toList()
      ..sort((a, b) => a.startSlot.compareTo(b.startSlot));
    
    return todayCourses;
  }

  /// 從今日課程中篩選即將到來的課程
  List<Course> _getUpcomingCoursesFromList(List<Course> todayCourses) {
    final now = DateTime.now();
    
    final upcomingCourses = todayCourses.where((course) {
      try {
        // 使用 CourseTimeUtil 獲取課程結束時間
        final endSlot = CourseTimeUtil.getTimeSlotByIndex(course.endSlot);
        final courseEndDateTime = DateTime(
          now.year, 
          now.month, 
          now.day, 
          endSlot.endTime ~/ 60,  // 小時
          endSlot.endTime % 60    // 分鐘
        );
        
        return courseEndDateTime.isAfter(now);
      } catch (e) {
        debugPrint('❌ 計算課程結束時間時發生錯誤: $e');
        return false;
      }
    }).toList();
    
    return upcomingCourses;
  }

  /// 獲取應用程式群組 ID（供其他服務使用）
  static String get iOSGroupId => _iOSGroupId;
  
  /// 獲取 Android Widget 名稱（供其他服務使用）
  static String get androidWidgetName => _androidWidgetName;
}
