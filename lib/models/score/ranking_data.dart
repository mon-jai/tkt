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
}