class RankingData {
  final String semester;
  final int classRank;
  final int departmentRank;
  final double averageScore;
  final int classRankHistory;
  final int departmentRankHistory;
  final double averageScoreHistory;

  RankingData({
    required this.semester,
    required this.classRank,
    required this.departmentRank,
    required this.averageScore,
    required this.classRankHistory,
    required this.departmentRankHistory,
    required this.averageScoreHistory,
  });

  factory RankingData.fromHtml(Map<String, dynamic> data) {
    return RankingData(
      semester: data['semester']?.toString().trim() ?? '',
      classRank: int.tryParse(data['classRank']?.toString().trim() ?? '0') ?? 0,
      departmentRank: int.tryParse(data['departmentRank']?.toString().trim() ?? '0') ?? 0,
      averageScore: double.tryParse(data['averageScore']?.toString().trim() ?? '0') ?? 0.0,
      classRankHistory: int.tryParse(data['classRankHistory']?.toString().trim() ?? '0') ?? 0,
      departmentRankHistory: int.tryParse(data['departmentRankHistory']?.toString().trim() ?? '0') ?? 0,
      averageScoreHistory: double.tryParse(data['averageScoreHistory']?.toString().trim() ?? '0') ?? 0.0,
    );
  }

  factory RankingData.fromJson(Map<String, dynamic> json) {
    return RankingData(
      semester: json['semester'] ?? '',
      classRank: json['classRank'] ?? 0,
      departmentRank: json['departmentRank'] ?? 0,
      averageScore: (json['averageScore'] ?? 0.0).toDouble(),
      classRankHistory: json['classRankHistory'] ?? 0,
      departmentRankHistory: json['departmentRankHistory'] ?? 0,
      averageScoreHistory: (json['averageScoreHistory'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'semester': semester,
      'classRank': classRank,
      'departmentRank': departmentRank,
      'averageScore': averageScore,
      'classRankHistory': classRankHistory,
      'departmentRankHistory': departmentRankHistory,
      'averageScoreHistory': averageScoreHistory,
    };
  }
}