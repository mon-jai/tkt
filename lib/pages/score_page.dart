import 'package:flutter/material.dart';
import 'package:tkt/models/score/course_score.dart';
import 'package:tkt/models/score/credit_summary.dart';
import 'package:tkt/models/score/ranking_data.dart';
import 'package:tkt/services/score_service.dart';

class ScorePage extends StatefulWidget {
  const ScorePage({Key? key}) : super(key: key);

  @override
  State<ScorePage> createState() => _ScorePageState();
}

class _ScorePageState extends State<ScorePage> {
  List<RankingData> _rankingData = [];
  List<CourseScore> _courseScores = [];
  CreditSummary? _creditSummary;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchScores();
  }

  Future<void> _fetchScores() async {
    try {
      final data = await ScoreService.fetchScores();
      setState(() {
        _rankingData = data['rankingData'] as List<RankingData>;
        _courseScores = data['courseScores'] as List<CourseScore>;
        _creditSummary = data['creditSummary'] as CreditSummary?;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showSemesterDetails(BuildContext context, String semester, List<CourseScore> scores) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$semester學期成績',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('課程名稱')),
                      DataColumn(label: Text('學分數')),
                      DataColumn(label: Text('成績')),
                    ],
                    rows: scores.map((score) {
                      return DataRow(
                        cells: [
                          DataCell(Text(score.courseName)),
                          DataCell(Text(score.credits)),
                          DataCell(Text(score.score)),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double? _getAverageScore(String semester) {
    final ranking = _rankingData.firstWhere(
      (data) => data.semester == semester,
      orElse: () => RankingData(
        semester: semester,
        classRank: 0,
        departmentRank: 0,
        averageScore: 0,
        classRankHistory: 0,
        departmentRankHistory: 0,
        averageScoreHistory: 0,
      ),
    );
    return ranking.averageScore;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('成績查詢'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('錯誤：$_error'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRankingSection(),
                      const SizedBox(height: 32),
                      _buildCreditSummarySection(),
                      const SizedBox(height: 32),
                      _buildCourseScoreSection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildRankingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '排名資料',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('學年期')),
                  DataColumn(label: Text('班排')),
                  DataColumn(label: Text('系排')),
                  DataColumn(label: Text('成績')),
                ],
                rows: _rankingData.map((data) {
                  return DataRow(
                    cells: [
                      DataCell(Text(data.semester)),
                      DataCell(Text(data.classRank.toString())),
                      DataCell(Text(data.departmentRank.toString())),
                      DataCell(Text(data.averageScore.toString())),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditSummarySection() {
    if (_creditSummary == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '學分數統計',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Table(
              border: TableBorder.all(color: Colors.grey),
              children: [
                const TableRow(
                  decoration: BoxDecoration(color: Colors.grey),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('類別',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('實體課程',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('遠距教學課程',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('合計',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    const Padding(
                        padding: EdgeInsets.all(8.0), child: Text('已實得學分數')),
                    Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(_creditSummary!.earnedCredits.toString())),
                    Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                            _creditSummary!.earnedDistanceCredits.toString())),
                    Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                            _creditSummary!.totalEarnedCredits.toString())),
                  ],
                ),
                TableRow(
                  children: [
                    const Padding(
                        padding: EdgeInsets.all(8.0), child: Text('修習中學分數')),
                    Padding(
                        padding: const EdgeInsets.all(8.0),
                        child:
                            Text(_creditSummary!.inProgressCredits.toString())),
                    Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(_creditSummary!.inProgressDistanceCredits
                            .toString())),
                    Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                            _creditSummary!.totalInProgressCredits.toString())),
                  ],
                ),
                TableRow(
                  children: [
                    const Padding(
                        padding: EdgeInsets.all(8.0), child: Text('合計')),
                    Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(_creditSummary!.totalCredits.toString())),
                    Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                            _creditSummary!.totalDistanceCredits.toString())),
                    Padding(
                        padding: const EdgeInsets.all(8.0),
                        child:
                            Text(_creditSummary!.grandTotalCredits.toString())),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '備註：採計為畢業總學分數之遠距教學課程學分數，不得超過畢業總學分數之三分之一。',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseScoreSection() {
    // 按學年期分組
    final groupedScores = <String, List<CourseScore>>{};
    for (var score in _courseScores) {
      groupedScores.putIfAbsent(score.semester, () => []).add(score);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '歷年學業成績列表',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: groupedScores.entries.map((entry) {
                final semesterScores = entry.value;
                final averageScore = _getAverageScore(entry.key);

                return GestureDetector(
                  onTap: () => _showSemesterDetails(context, entry.key, semesterScores),
                  child: SizedBox(
                    width: 160,
                    child: Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${entry.key}學期',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('修課數: ${semesterScores.length}'),
                            Text('平均分數: ${averageScore?.toStringAsFixed(1) ?? "N/A"}'),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}