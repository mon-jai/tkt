import 'dart:ui';

class CalendarEvent {
  final String title;
  final DateTime date;
  final DateTime? endDate;
  final String? description;
  final Color? color;
  final String? type;

  CalendarEvent({
    required this.title,
    required this.date,
    this.endDate,
    this.description,
    this.color,
    this.type,
  });

  /// 是否為多日事件
  bool get isMultiDay {
    if (endDate == null) return false;
    
    // 檢查是否為同一天
    if (isSameDay(date, endDate!)) return false;
    
    // 檢查是否為隔夜的全日事件（例如：9/1 00:00 - 9/2 00:00）
    // 這種情況應該視為單日事件
    final nextDay = DateTime(date.year, date.month, date.day + 1);
    if (isSameDay(endDate!, nextDay) && 
        endDate!.hour == 0 && endDate!.minute == 0 && endDate!.second == 0) {
      return false;
    }
    
    return true;
  }

  /// 檢查兩個日期是否為同一天
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// 獲取事件的所有日期（對於多日事件）
  List<DateTime> getAllDates() {
    // 如果不是多日事件，只返回開始日期
    if (!isMultiDay) return [date];
    
    final dates = <DateTime>[];
    var current = DateTime(date.year, date.month, date.day);
    final end = DateTime(endDate!.year, endDate!.month, endDate!.day);
    
    while (!current.isAfter(end)) {
      dates.add(current);
      current = current.add(const Duration(days: 1));
    }
    
    return dates;
  }

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      title: json['title'] as String,
      date: DateTime.parse(json['date'] as String),
      endDate: json['endDate'] != null 
          ? DateTime.parse(json['endDate'] as String) 
          : null,
      description: json['description'] as String?,
      type: json['type'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'date': date.toIso8601String(),
    if (endDate != null) 'endDate': endDate!.toIso8601String(),
    if (description != null) 'description': description,
    if (type != null) 'type': type,
  };

  @override
  String toString() => title;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarEvent &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          date == other.date;

  @override
  int get hashCode => title.hashCode ^ date.hashCode;
}
