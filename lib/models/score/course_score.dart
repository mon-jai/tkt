class CourseScore {
  final int order;
  final String semester;
  final String courseCode;
  final String courseName;
  final String credits;
  final String score;
  final String note;
  final String generalEducationCategory;
  final bool isDistanceLearning;

  CourseScore({
    required this.order,
    required this.semester,
    required this.courseCode,
    required this.courseName,
    required this.credits,
    required this.score,
    required this.note,
    required this.generalEducationCategory,
    required this.isDistanceLearning,
  });

  factory CourseScore.fromHtml(Map<String, dynamic> data) {
    return CourseScore(
      order: int.tryParse(data['order']?.toString().trim() ?? '0') ?? 0,
      semester: data['semester']?.toString().trim() ?? '',
      courseCode: data['courseCode']?.toString().trim() ?? '',
      courseName: data['courseName']?.toString().trim() ?? '',
      credits: data['credits']?.toString().trim() ?? '',
      score: data['score']?.toString().trim() ?? '',
      note: data['note']?.toString().trim() ?? '',
      generalEducationCategory: data['generalEducationCategory']?.toString().trim() ?? '',
      isDistanceLearning: data['isDistanceLearning']?.toString().trim() == '是',
    );
  }

  factory CourseScore.fromJson(Map<String, dynamic> json) {
    return CourseScore(
      order: json['order'] ?? 0,
      semester: json['semester'] ?? '',
      courseCode: json['courseCode'] ?? '',
      courseName: json['courseName'] ?? '',
      credits: json['credits'] ?? '',
      score: json['score'] ?? '',
      note: json['note'] ?? '',
      generalEducationCategory: json['generalEducationCategory'] ?? '',
      isDistanceLearning: json['isDistanceLearning'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order': order,
      'semester': semester,
      'courseCode': courseCode,
      'courseName': courseName,
      'credits': credits,
      'score': score,
      'note': note,
      'generalEducationCategory': generalEducationCategory,
      'isDistanceLearning': isDistanceLearning,
    };
  }
}