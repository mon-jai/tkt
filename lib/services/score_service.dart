import 'package:html/parser.dart';
import 'package:tkt/connector/core/connector.dart';
import 'package:tkt/connector/core/connector_parameter.dart';
import 'package:tkt/models/score/course_score.dart';
import 'package:tkt/models/score/credit_summary.dart';
import 'package:tkt/models/score/ranking_data.dart';

class ScoreService {
  static const String _scoreUrl = 'https://stuinfosys.ntust.edu.tw/StuScoreQueryServ/StuScoreQuery/DisplayAll';

  static Future<Map<String, dynamic>> fetchScores() async {
    try {
      final parameter = ConnectorParameter(_scoreUrl);
      final response = await Connector.getDataByGet(parameter);
      
      final document = parse(response);
      
      // 解析排名資料
      final rankingTable = document.querySelector('.box-content table');
      final rankingData = <RankingData>[];
      
      if (rankingTable != null) {
        final rows = rankingTable.querySelectorAll('tbody tr');
        for (var row in rows) {
          final cells = row.querySelectorAll('td');
          if (cells.length >= 7) {
            rankingData.add(RankingData.fromHtml({
              'semester': cells[0].text,
              'classRank': cells[1].text,
              'departmentRank': cells[2].text,
              'averageScore': cells[3].text,
              'classRankHistory': cells[4].text,
              'departmentRankHistory': cells[5].text,
              'averageScoreHistory': cells[6].text,
            }));
          }
        }
      }

      // 解析課程成績
      final scoreTable = document.querySelectorAll('.box-content table')[1];
      final courseScores = <CourseScore>[];
      
      if (scoreTable != null) {
        final rows = scoreTable.querySelectorAll('tbody tr');
        for (var row in rows) {
          final cells = row.querySelectorAll('td');
          if (cells.length >= 9) {
            courseScores.add(CourseScore.fromHtml({
              'order': cells[0].text,
              'semester': cells[1].text,
              'courseCode': cells[2].text,
              'courseName': cells[3].text,
              'credits': cells[4].text,
              'score': cells[5].text,
              'note': cells[6].text,
              'generalEducationCategory': cells[7].text,
              'isDistanceLearning': cells[8].text,
            }));
          }
        }
      }

      // 解析學分數統計
      final creditTable = document.querySelector('.dataTables_info table');
      CreditSummary? creditSummary;
      
      if (creditTable != null) {
        final rows = creditTable.querySelectorAll('tr');
        if (rows.length >= 3) {
          final earnedRow = rows[1].querySelectorAll('td');
          final inProgressRow = rows[2].querySelectorAll('td');
          final totalRow = rows[3].querySelectorAll('td');
          
          if (earnedRow.length >= 4 && inProgressRow.length >= 4 && totalRow.length >= 4) {
            creditSummary = CreditSummary.fromHtml({
              'earnedCredits': earnedRow[1].text,
              'earnedDistanceCredits': earnedRow[2].text,
              'totalEarnedCredits': earnedRow[3].text,
              'inProgressCredits': inProgressRow[1].text,
              'inProgressDistanceCredits': inProgressRow[2].text,
              'totalInProgressCredits': inProgressRow[3].text,
              'totalCredits': totalRow[1].text,
              'totalDistanceCredits': totalRow[2].text,
              'grandTotalCredits': totalRow[3].text,
            });
          }
        }
      }

      return {
        'rankingData': rankingData,
        'courseScores': courseScores,
        'creditSummary': creditSummary,
      };
    } catch (e) {
      throw Exception('無法獲取成績資料：$e');
    }
  }
}