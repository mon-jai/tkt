class Course {
  final String code;        // 課碼
  final String name;        // 課程名稱
  final int credits;        // 學分數
  final bool isRequired;    // 是否必修
  final String teacher;     // 教師名稱
  final String? note;       // 備註

  Course({
    required this.code,
    required this.name,
    required this.credits,
    required this.isRequired,
    required this.teacher,
    this.note,
  });
}

class TimeSlot {
  final String period;      // 節次
  final String startTime;   // 開始時間
  final String endTime;     // 結束時間
  final Map<String, CourseInfo?> schedule; // 星期一到日的課程

  TimeSlot({
    required this.period,
    required this.startTime,
    required this.endTime,
    required this.schedule,
  });
}

class CourseInfo {
  final String name;        // 課程名稱
  final String classroom;   // 教室
  final String? color;      // 顏色標記

  CourseInfo({
    required this.name,
    required this.classroom,
    this.color,
  });
}

class Schedule {
  final List<Course> courses;           // 所有課程列表
  final List<TimeSlot> timeSlots;       // 時間表
  final int totalCredits;               // 總學分數

  Schedule({
    required this.courses,
    required this.timeSlots,
    required this.totalCredits,
  });
} 