import 'package:json_annotation/json_annotation.dart';

// 這行是必需的，指向將要自動產生的檔案
part 'semester_json.g.dart';

/// 代表一個學期的資料模型，包含學年和學期。
@JsonSerializable()
class SemesterJson {
  /// 學年度，例如 "111"。
  final String year;

  /// 學期，例如 "1" 或 "2"。
  /// 如果您的原始碼中使用 'term'，請將這裡的 'semester' 改為 'term'。
  final String semester;

  /// 建構子，需要提供學年和學期。
  SemesterJson({required this.year, required this.semester});

  /// 從 JSON Map 建立 SemesterJson 物件的工廠建構子。
  /// 它會呼叫自動產生的 `_$SemesterJsonFromJson` 函式。
  factory SemesterJson.fromJson(Map<String, dynamic> json) =>
      _$SemesterJsonFromJson(json);

  /// 將 SemesterJson 物件轉換為 JSON Map。
  /// 它會呼叫自動產生的 `_$SemesterJsonToJson` 函式。
  Map<String, dynamic> toJson() => _$SemesterJsonToJson(this);

  /// 覆寫 '==' 運算子，以便能夠比較兩個 SemesterJson 物件是否相等。
  /// 如果兩個物件的 year 和 semester 都相同，則視為相等。
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SemesterJson &&
          runtimeType == other.runtimeType &&
          year == other.year &&
          semester == other.semester;

  /// 覆寫 'hashCode'，確保相等的物件有相同的 hash code。
  /// 這對於在 Map 或 Set 中使用 SemesterJson 作為鍵值很重要。
  @override
  int get hashCode => year.hashCode ^ semester.hashCode;

  /// 提供一個易於閱讀的字串表示，方便除錯。
  @override
  String toString() {
    return 'SemesterJson{year: $year, semester: $semester}';
  }
}