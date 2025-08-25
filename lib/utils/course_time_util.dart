class CourseTimeSlot {
  final int index;      // 節次索引（1-14）
  final String label;   // 節次標籤（1-10, A-D）
  final int startHour;  // 開始小時
  final int startMin;   // 開始分鐘
  final int duration;   // 持續時間（分鐘）

  const CourseTimeSlot({
    required this.index,
    required this.label,
    required this.startHour,
    required this.startMin,
    this.duration = 50,
  });

  int get startTime => startHour * 60 + startMin;
  int get endTime => startTime + duration;

  String get formattedStartTime => 
      '${startHour.toString().padLeft(2, '0')}:${startMin.toString().padLeft(2, '0')}';

  String get formattedEndTime {
    final endHour = (startTime + duration) ~/ 60;
    final endMin = (startTime + duration) % 60;
    return '${endHour.toString().padLeft(2, '0')}:${endMin.toString().padLeft(2, '0')}';
  }

  String get timeRangeString => '$formattedStartTime-$formattedEndTime';
}

class CourseTimeUtil {
  static const List<CourseTimeSlot> timeSlots = [
    CourseTimeSlot(index: 1, label: '1', startHour: 8, startMin: 10),
    CourseTimeSlot(index: 2, label: '2', startHour: 9, startMin: 10),
    CourseTimeSlot(index: 3, label: '3', startHour: 10, startMin: 20),
    CourseTimeSlot(index: 4, label: '4', startHour: 11, startMin: 20),
    CourseTimeSlot(index: 5, label: '5', startHour: 12, startMin: 20),
    CourseTimeSlot(index: 6, label: '6', startHour: 13, startMin: 20),
    CourseTimeSlot(index: 7, label: '7', startHour: 14, startMin: 20),
    CourseTimeSlot(index: 8, label: '8', startHour: 15, startMin: 30),
    CourseTimeSlot(index: 9, label: '9', startHour: 16, startMin: 30),
    CourseTimeSlot(index: 10, label: '10', startHour: 17, startMin: 30),
    CourseTimeSlot(index: 11, label: 'A', startHour: 18, startMin: 25),
    CourseTimeSlot(index: 12, label: 'B', startHour: 19, startMin: 20),
    CourseTimeSlot(index: 13, label: 'C', startHour: 20, startMin: 15),
    CourseTimeSlot(index: 14, label: 'D', startHour: 21, startMin: 10),
  ];

  static CourseTimeSlot getTimeSlotByIndex(int index) {
    try {
      return timeSlots.firstWhere(
        (slot) => slot.index == index,
      );
    } catch (e) {
      throw Exception('無效的課程節次：$index');
    }
  }

  static CourseTimeSlot getTimeSlotByLabel(String label) {
    try {
      return timeSlots.firstWhere(
        (slot) => slot.label == label,
      );
    } catch (e) {
      throw Exception('無效的課程節次：$label');
    }
  }

  static List<CourseTimeSlot> getTimeSlotRange(int startIndex, int endIndex) {
    if (startIndex > endIndex) throw Exception('開始節次不能大於結束節次');
    return timeSlots
        .where((slot) => slot.index >= startIndex && slot.index <= endIndex)
        .toList();
  }

  static String formatTimeSlotRange(int startIndex, int endIndex) {
    if (startIndex == endIndex) {
      try {
        return timeSlots.firstWhere((slot) => slot.index == startIndex).label;
      } catch (e) {
        return '';
      }
    }
    final slots = getTimeSlotRange(startIndex, endIndex);
    if (slots.isEmpty) return '';
    return '${slots.first.label}-${slots.last.label}';
  }
} 