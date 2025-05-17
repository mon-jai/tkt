import 'dart:convert';
import '../utils/course_time_util.dart';

class Course {
  final String id;          // 課程ID
  final String name;        // 課程名稱
  final String teacher;     // 教師名稱
  final String classroom;   // 教室
  final int dayOfWeek;       // 1-7，代表週一到週日
  final int startSlot;       // 開始節次（1-14）
  final int endSlot;         // 結束節次（1-14）
  final String? note;        // 備註

  Course({
    required this.id,
    required this.name,
    required this.teacher,
    required this.classroom,
    required this.dayOfWeek,
    required this.startSlot,
    required this.endSlot,
    this.note,
  }) {
    // 驗證時間範圍
    if (startSlot < 1 || startSlot > 14 || endSlot < 1 || endSlot > 14) {
      throw ArgumentError('課程節次必須在1-14之間');
    }
    if (startSlot > endSlot) {
      throw ArgumentError('開始節次不能大於結束節次');
    }
  }

  // 從 JSON 創建課程
  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as String,
      name: json['name'] as String,
      teacher: json['teacher'] as String,
      classroom: json['classroom'] as String,
      dayOfWeek: json['day_of_week'] as int,
      startSlot: json['start_slot'] as int,
      endSlot: json['end_slot'] as int,
      note: json['note'] as String?,
    );
  }

  // 轉換為 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'teacher': teacher,
      'classroom': classroom,
      'day_of_week': dayOfWeek,
      'start_slot': startSlot,
      'end_slot': endSlot,
      'note': note,
    };
  }

  // 輔助方法：獲取星期幾的中文名稱
  String get dayOfWeekString {
    const days = ['一', '二', '三', '四', '五', '六', '日'];
    return '週${days[dayOfWeek - 1]}';
  }

  // 輔助方法：獲取課程時間範圍
  String get timeSlotString {
    return CourseTimeUtil.formatTimeSlotRange(startSlot, endSlot);
  }

  // 輔助方法：獲取格式化的時間範圍
  String get formattedTimeRange {
    final startTimeSlot = CourseTimeUtil.getTimeSlotByIndex(startSlot);
    final endTimeSlot = CourseTimeUtil.getTimeSlotByIndex(endSlot);
    return '${startTimeSlot.formattedStartTime}-${endTimeSlot.formattedEndTime}';
  }

  // 輔助方法：檢查是否與另一個課程時間衝突
  bool hasConflictWith(Course other) {
    if (dayOfWeek != other.dayOfWeek) return false;
    return !(endSlot < other.startSlot || startSlot > other.endSlot);
  }
} 