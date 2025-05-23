// 引入我們剛剛建立的 semester_json.dart 檔案
// 請確保路徑 'package:flutter_app/src/model/common/semester_json.dart'
// 與您實際儲存 semester_json.dart 的路徑一致。
// 如果您的專案名稱不是 'flutter_app'，請替換成您的專案名稱。
import 'package:tkt/models/semester/semester_json.dart';
import 'package:json_annotation/json_annotation.dart';

// 指向將要自動產生的 .g.dart 檔案
part 'score_json.g.dart';

/// 頂層容器，儲存所有學期的成績和排名資訊。
@JsonSerializable()
class ScoreRankJson {
  /// 儲存每個學期資訊的列表。
  late List<SemesterScoreJson> info;

  /// 建構子，如果未提供 info，則初始化為空列表。
  ScoreRankJson({List<SemesterScoreJson>? info}) {
    this.info = info ?? [];
  }

  /// 添加或更新指定學期的排名資訊。
  void addRankBySemester(SemesterJson semester, RankJson rank) {
    bool add = false;
    for (var i in info) {
      // 使用覆寫過的 '==' 來比較 SemesterJson 物件
      if (i.semester == semester) {
        i.rank = rank;
        add = true;
        break;
      }
    }
    if (!add) {
      info.add(SemesterScoreJson(
        semester: semester,
        item: [], // 新增時，成績列表為空
        rank: rank,
      ));
    }
  }

  /// 獲取指定學期的所有課程 ID。
  Future<List<String>> getCourseIdBySemester(SemesterJson semester) async {
    List<String> value = [];
    for (var i in info) {
      if (i.semester == semester) {
        for (var j in i.item) {
          value.add(j.courseId);
        }
        break;
      }
    }
    return value;
  }

  /// 添加指定學期的單筆成績項目。
  void addScoreBySemester(SemesterJson semester, ScoreItemJson item) {
    bool add = false;
    for (var i in info) {
      if (i.semester == semester) {
        i.item.add(item);
        add = true;
        break;
      }
    }
    if (!add) {
      info.add(SemesterScoreJson(
        semester: semester,
        item: [item], // 新增時，包含此筆成績
        // rank 預設為 null
      ));
    }
  }

  /// 從 JSON Map 建立 ScoreRankJson 物件。
  factory ScoreRankJson.fromJson(Map<String, dynamic> srcJson) =>
      _$ScoreRankJsonFromJson(srcJson);

  /// 將 ScoreRankJson 物件轉換為 JSON Map。
  Map<String, dynamic> toJson() => _$ScoreRankJsonToJson(this);
}

/// 代表單一學期的成績和排名資訊。
@JsonSerializable()
class SemesterScoreJson {
  /// 學期資訊。
  SemesterJson semester;

  /// 該學期的成績項目列表。
  List<ScoreItemJson> item;

  /// 該學期的排名資訊 (可選)。
  RankJson? rank;

  /// 建構子。
  SemesterScoreJson({required this.semester, required this.item, this.rank});

  /// 從 JSON Map 建立 SemesterScoreJson 物件。
  factory SemesterScoreJson.fromJson(Map<String, dynamic> srcJson) =>
      _$SemesterScoreJsonFromJson(srcJson);

  /// 將 SemesterScoreJson 物件轉換為 JSON Map。
  Map<String, dynamic> toJson() => _$SemesterScoreJsonToJson(this);
}

/// 代表單一學期的排名資訊。
@JsonSerializable()
class RankJson {
  /// 班級排名。
  String classRank;

  /// 系排名。
  String departmentRank;

  /// 平均成績。
  String averageScore;

  /// 班級排名 (歷年)。
  String classRankYears;

  /// 系排名 (歷年)。
  String departmentRankYears;

  /// 平均成績 (歷年)。
  String averageYears;

  /// 建構子。
  RankJson({
    required this.classRank,
    required this.departmentRank,
    required this.averageScore,
    required this.classRankYears,
    required this.departmentRankYears,
    required this.averageYears,
  });

  /// 從 JSON Map 建立 RankJson 物件。
  factory RankJson.fromJson(Map<String, dynamic> srcJson) =>
      _$RankJsonFromJson(srcJson);

  /// 將 RankJson 物件轉換為 JSON Map。
  Map<String, dynamic> toJson() => _$RankJsonToJson(this);
}

/// 代表單門課程的成績資訊。
@JsonSerializable()
class ScoreItemJson {
  /// 課號。
  String courseId;

  /// 課程名稱。
  String name;

  /// 學分數。
  String credit;

  /// 成績。
  String score;

  /// 備註。
  String remark;

  /// 通識向度。
  String generalDimension;

  /// 建構子。
  ScoreItemJson({
    required this.courseId,
    required this.score,
    required this.name,
    required this.credit,
    required this.generalDimension,
    required this.remark,
  });

  /// 從 JSON Map 建立 ScoreItemJson 物件。
  factory ScoreItemJson.fromJson(Map<String, dynamic> srcJson) =>
      _$ScoreItemJsonFromJson(srcJson);

  /// 將 ScoreItemJson 物件轉換為 JSON Map。
  Map<String, dynamic> toJson() => _$ScoreItemJsonToJson(this);
}