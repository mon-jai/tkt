import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:tkt/models/score/course_score.dart';
import 'package:tkt/models/score/credit_summary.dart';
import 'package:tkt/models/score/ranking_data.dart';
import 'package:tkt/services/score_service.dart';
import 'package:tkt/services/demo_service.dart';
import 'package:tkt/providers/demo_mode_provider.dart';
import 'package:tkt/pages/webview_screen.dart';

import 'package:tkt/connector/check_login.dart';
import 'package:tkt/widgets/ntust_login_prompt_dialog.dart';
import 'package:tkt/debug/log/log.dart';

class ScorePage extends StatefulWidget {
  const ScorePage({Key? key}) : super(key: key);

  @override
  State<ScorePage> createState() => _ScorePageState();
}

class _ScorePageState extends State<ScorePage> {
  // 成績儲存的鍵名
  static const String _rankingDataKey = 'cached_ranking_data';
  static const String _courseScoresKey = 'cached_course_scores';
  static const String _creditSummaryKey = 'cached_credit_summary';
  static const String _lastUpdateTimeKey = 'scores_last_update_time';
  
  List<RankingData> _rankingData = [];
  List<CourseScore> _courseScores = [];
  CreditSummary? _creditSummary;
  bool _isLoading = true;
  String? _error;
  bool _showWebView = false;
  DateTime? _lastUpdateTime;

  @override
  void initState() {
    super.initState();
    _loadCachedScores();
  }

  /// 載入快取的成績資料
  Future<void> _loadCachedScores() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 檢查是否為演示模式
      final isDemoMode = prefs.getBool('demo_mode') ?? false;
      
      if (isDemoMode) {
        // 演示模式：載入演示資料
        _loadDemoScores();
        return;
      }
      
      // 正常模式：載入快取的資料
      final rankingJson = prefs.getStringList(_rankingDataKey);
      final coursesJson = prefs.getStringList(_courseScoresKey);
      final creditJson = prefs.getString(_creditSummaryKey);
      final lastUpdateTimeString = prefs.getString(_lastUpdateTimeKey);
      
      if (rankingJson != null && coursesJson != null) {
        setState(() {
          _rankingData = rankingJson.map((json) => RankingData.fromJson(jsonDecode(json))).toList();
          _courseScores = coursesJson.map((json) => CourseScore.fromJson(jsonDecode(json))).toList();
          
          if (creditJson != null) {
            _creditSummary = CreditSummary.fromJson(jsonDecode(creditJson));
          }
          
          if (lastUpdateTimeString != null) {
            _lastUpdateTime = DateTime.parse(lastUpdateTimeString);
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      print('載入快取成績時發生錯誤：$e');
    }
    
    // 如果沒有快取資料，則嘗試獲取新資料（演示模式下跳過）
    if (_rankingData.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final isDemoMode = prefs.getBool('demo_mode') ?? false;
      
      if (!isDemoMode) {
        _fetchScores();
      } else {
        // 演示模式下如果沒有資料，重新載入演示資料
        _loadDemoScores();
      }
    }
  }

  /// 載入演示模式成績資料
  void _loadDemoScores() {
    try {
      _courseScores = DemoService.getDemoCourseScores();
      _creditSummary = DemoService.getDemoCreditSummary();
      
      // 將演示排名資料轉換為 RankingData 物件
      final demoRankingList = DemoService.getDemoRankingData();
      _rankingData = demoRankingList.map((data) => RankingData(
        semester: data['semester'] as String,
        classRank: data['classRank'] as int,
        departmentRank: data['departmentRank'] as int,
        averageScore: (data['averageScore'] as num).toDouble(),
        classRankHistory: data['classRankHistory'] as int,
        departmentRankHistory: data['departmentRankHistory'] as int,
        averageScoreHistory: (data['averageScoreHistory'] as num).toDouble(),
      )).toList();
      
      _lastUpdateTime = DateTime.now();
      
      setState(() {
        _isLoading = false;
      });

      Log.d('演示模式：已載入演示成績資料');
    } catch (e) {
      Log.e('載入演示成績資料時發生錯誤：$e');
      setState(() {
        _isLoading = false;
        _error = '載入演示資料失敗';
      });
    }
  }

  /// 儲存成績資料到快取
  Future<void> _saveScoresToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 將資料轉換為 JSON 並儲存
      final rankingJson = _rankingData.map((data) => jsonEncode(data.toJson())).toList();
      final coursesJson = _courseScores.map((score) => jsonEncode(score.toJson())).toList();
      
      await prefs.setStringList(_rankingDataKey, rankingJson);
      await prefs.setStringList(_courseScoresKey, coursesJson);
      
      if (_creditSummary != null) {
        await prefs.setString(_creditSummaryKey, jsonEncode(_creditSummary!.toJson()));
      }
      
      await prefs.setString(_lastUpdateTimeKey, DateTime.now().toIso8601String());
      
      print('成績已儲存到快取');
    } catch (e) {
      print('儲存成績到快取時發生錯誤：$e');
    }
  }

  /// 檢查登入狀態並獲取成績
  Future<void> _fetchScores() async {
    if (!mounted) return;
    
    // 檢查是否為演示模式
    final prefs = await SharedPreferences.getInstance();
    final isDemoMode = prefs.getBool('demo_mode') ?? false;
    
    if (isDemoMode) {
      // 演示模式：直接載入演示資料
      _loadDemoScores();
      return;
    }
    
    setState(() {
      _isLoading = true;
      _error = null;
      _showWebView = false;
    });

    // 先檢查登入狀態
    final loginStatus = await CheckLogin.ntust_login();
    Log.d('NTUST Login Status: ${loginStatus.toString()}');

    if (loginStatus == NtustConnectorStatus.loginFail) {
      if (!mounted) return;
      final shouldProceedToLogin = await _showLoginPromptDialog();
      if (shouldProceedToLogin == true) {
        // 登入成功後重新嘗試獲取成績
        if (!mounted) return;
        await _fetchScoresData();
      } else {
        // 用戶取消登入
        setState(() {
          _isLoading = false;
          _error = '需要登入才能查看成績';
        });
      }
      return;
    } else if (loginStatus == NtustConnectorStatus.unknownError) {
      if (!mounted) return;
      setState(() {
        _error = '檢查登入狀態時發生未知錯誤，請稍後再試';
        _isLoading = false;
      });
      return;
    }

    // 登入狀態正常，直接獲取成績
    await _fetchScoresData();
  }

  /// 實際獲取成績資料的方法
  Future<void> _fetchScoresData() async {
    try {
      final data = await ScoreService.fetchScores();
      
      if (!mounted) return;
      setState(() {
        _rankingData = data['rankingData'] as List<RankingData>;
        _courseScores = data['courseScores'] as List<CourseScore>;
        _creditSummary = data['creditSummary'] as CreditSummary?;
        _lastUpdateTime = DateTime.now();
        _isLoading = false;
        _error = null;
      });
      
      // 儲存到快取
      await _saveScoresToCache();
      
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _showWebView = true;
      });
    }
  }

  /// 顯示登入提示對話框
  Future<bool?> _showLoginPromptDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return const NtustLoginPromptDialog();
      },
    );
  }

  /// 格式化日期時間顯示
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return '剛剛';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分鐘前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}小時前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
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
    return Consumer<DemoModeProvider>(
      builder: (context, demoModeProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('成績查詢'),
                    if (demoModeProvider.isDemoModeEnabled) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '演示',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (_lastUpdateTime != null)
                  Text(
                    demoModeProvider.isDemoModeEnabled 
                        ? '演示資料：${_formatDateTime(_lastUpdateTime!)}'
                        : '更新：${_formatDateTime(_lastUpdateTime!)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                  ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: demoModeProvider.isDemoModeEnabled 
                    ? () {
                        _loadDemoScores();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('演示資料已重新載入'))
                        );
                      }
                    : _fetchScores,
                tooltip: demoModeProvider.isDemoModeEnabled ? '重新載入演示資料' : '重新整理成績',
              ),
            ],
          ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _showWebView
              ? WebViewScreen(
                  initialUrl: 'https://stuinfosys.ntust.edu.tw/StuScoreQueryServ/StuScoreQuery',
                  title: '成績查詢系統',
                  onLoginResult: (success) async {
                    if (success) {
                      _fetchScores();
                    }
                  },
                )
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '校園系統登入失敗或查詢失敗',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _fetchScores,
                            child: const Text('重試'),
                          ),
                        ],
                      ),
                    )
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
      },
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