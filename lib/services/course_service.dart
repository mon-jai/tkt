import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/course_model.dart';
import '../utils/course_time_util.dart';
import 'notification_service.dart';
import 'app_group_service.dart';

class CourseService with ChangeNotifier {
  static const String _coursesKey = 'courses';
  List<Course> _courses = [];
  
  List<Course> get courses => List.unmodifiable(_courses);

  CourseService() {
    _initializeService();
  }

  Future<void> _initializeService() async {
    // 初始化 App Group Service
    await AppGroupService.instance.initialize();
    // 載入課程
    await _loadCourses();
  }

  Future<void> _loadCourses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 從本地存儲載入
      final coursesJson = prefs.getStringList(_coursesKey) ?? [];
      _courses = coursesJson
          .map((json) => Course.fromJson(jsonDecode(json)))
          .toList();
      debugPrint('已載入 ${_courses.length} 門課程');
      
      // 載入課程後安排通知
      await _scheduleNotifications();
      
      notifyListeners();
    } catch (e) {
      debugPrint('載入課程時發生錯誤: $e');
      _courses = [];
    }
  }

  Future<void> _saveCourses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final coursesJson = _courses
          .map((course) => jsonEncode(course.toJson()))
          .toList();
      await prefs.setStringList(_coursesKey, coursesJson);
      debugPrint('已儲存 ${_courses.length} 門課程到本地存儲');
      
      // 同時儲存到 App Group 供 Widget 使用
      final appGroupSuccess = await AppGroupService.instance.saveCourses(_courses);
      if (appGroupSuccess) {
        debugPrint('✅ 已同步 ${_courses.length} 門課程到 App Group');
        
        // 觸發 Widget 更新
        await _triggerWidgetUpdate();
      } else {
        debugPrint('❌ App Group 同步失敗');
      }
    } catch (e) {
      debugPrint('儲存課程時發生錯誤: $e');
    }
  }
  
  /// 觸發 Widget 更新
  Future<void> _triggerWidgetUpdate() async {
    try {
      if (Platform.isIOS) {
        // 嘗試觸發 Widget 刷新（iOS 15+ 支援）
        final platform = MethodChannel('widget_update');
        await platform.invokeMethod('reloadAllTimelines');
        debugPrint('🔄 已觸發 Widget 更新');
      }
    } catch (e) {
      // Widget 更新失敗是正常的，因為這個功能不是所有 iOS 版本都支援
      debugPrint('📱 Widget 更新觸發失敗（這是正常的）: $e');
    }
  }


  Future<void> addCourse(Course course) async {
    _courses.add(course);
    debugPrint('已添加課程：${course.name}');
    await _saveCourses();
    await _scheduleNotifications();
    notifyListeners();
  }

  Future<void> removeCourse(String courseId) async {
    _courses.removeWhere((course) => course.id == courseId);
    debugPrint('已刪除課程 ID：$courseId');
    await _saveCourses();
    await _scheduleNotifications();
    notifyListeners();
  }

  Future<void> updateCourse(Course updatedCourse) async {
    final index = _courses.indexWhere((course) => course.id == updatedCourse.id);
    if (index != -1) {
      _courses[index] = updatedCourse;
      debugPrint('已更新課程：${updatedCourse.name}');
      await _saveCourses();
      await _scheduleNotifications();
      notifyListeners();
    }
  }

  List<Course> getCoursesByDay(int dayOfWeek) {
    final courses = _courses
        .where((course) => course.dayOfWeek == dayOfWeek)
        .toList()
      ..sort((a, b) => a.startSlot.compareTo(b.startSlot));
    debugPrint('星期 $dayOfWeek 的課程數量：${courses.length}');
    return courses;
  }

  List<Course> getTodayCourses() {
    final now = DateTime.now();
    final courses = getCoursesByDay(now.weekday);
    debugPrint('今日課程數量：${courses.length}');
    return courses;
  }

  List<Course> getUpcomingCourses() {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final todayCourses = getTodayCourses();
    
    debugPrint('當前時間（分鐘）: $currentMinutes');
    for (final course in todayCourses) {
      try {
        final endTimeSlot = CourseTimeUtil.getTimeSlotByIndex(course.endSlot);
        debugPrint('課程：${course.name}, 結束時間：${endTimeSlot.endTime}');
      } catch (e) {
        debugPrint('獲取課程時間時發生錯誤：$e');
      }
    }
    
    final upcomingCourses = todayCourses
        .where((course) {
          try {
            final endTimeSlot = CourseTimeUtil.getTimeSlotByIndex(course.endSlot);
            final isUpcoming = endTimeSlot.endTime > currentMinutes;
            debugPrint('課程：${course.name}, 是否即將到來：$isUpcoming');
            return isUpcoming;
          } catch (e) {
            debugPrint('處理課程時間時發生錯誤：$e');
            return false;
          }
        })
        .toList();
    
    debugPrint('即將到來的課程數量：${upcomingCourses.length}');
    return upcomingCourses;
  }

  // 檢查課程時間衝突
  List<Course> checkTimeConflicts(Course newCourse) {
    return _courses
        .where((course) => course.hasConflictWith(newCourse))
        .toList();
  }

  // 導出課表為 JSON 字符串
  String exportToJson() {
    final List<Map<String, dynamic>> coursesJson = _courses
        .map((course) => course.toJson())
        .toList();
    return jsonEncode(coursesJson);
  }

  // 從 JSON 字符串導入課表
  Future<void> importFromJson(String jsonString) async {
    try {
      final List<dynamic> coursesJson = jsonDecode(jsonString);
      _courses = coursesJson
          .map((json) => Course.fromJson(json as Map<String, dynamic>))
          .toList();
      await _saveCourses();
      await _scheduleNotifications();
      notifyListeners();
    } catch (e) {
      throw Exception('無效的課表數據格式');
    }
  }

  // 安排課程通知
  Future<void> _scheduleNotifications() async {
    await NotificationService.scheduleNotificationsForCourses(_courses);
  }

  /// 重新載入課程
  Future<void> reload() async {
    await _loadCourses();
  }

  // 重新安排所有通知（當設定改變時調用）
  Future<void> rescheduleNotifications() async {
    await NotificationService.cancelAllNotifications();
    await _scheduleNotifications();
  }

  // 獲取下次課程提醒
  Course? getNextCourseReminder() {
    final upcomingCourses = getUpcomingCourses();
    return upcomingCourses.isNotEmpty ? upcomingCourses.first : null;
  }
} 