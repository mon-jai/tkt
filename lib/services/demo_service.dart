import '../models/course_model.dart';
import '../models/announcement_model.dart';
import '../models/score/course_score.dart';
import '../models/score/credit_summary.dart';
import '../models/parking_lot_model.dart';

/// 演示服務 - 提供Apple審核用的模擬數據
class DemoService {
  static const String demoStudentId = "demo123";
  static const String demoStudentName = "演示學生";
  static const String demoEmail = "demo@student.ntust.edu.tw";
  static const String demoDepartment = "資訊工程系";

  /// 獲取演示學號（台科大格式）
  static String getDemoStudentId() {
    return demoStudentId;
  }

  /// 獲取演示登入成功訊息
  static String getDemoLoginMessage() {
    return "演示模式登入成功 - 歡迎使用台科通";
  }

  /// 獲取演示課程資料 - 完整的一週課表
  static List<Course> getDemoCourses() {
    return [
      // 週一課程
      Course(
        id: "demo_course_1",
        name: "資料結構",
        teacher: "王志明教授",
        classroom: "資工系館 101",
        dayOfWeek: 1, // 週一
        startSlot: 3, // 10:20-11:10
        endSlot: 3,
        note: "必修課程",
      ),
      Course(
        id: "demo_course_2",
        name: "計算機概論",
        teacher: "陳美華教授",
        classroom: "資工系館 102",
        dayOfWeek: 1, // 週一
        startSlot: 6, // 14:20-15:10
        endSlot: 7,   // 15:20-16:10
        note: "入門課程",
      ),
      
      // 週二課程  
      Course(
        id: "demo_course_3",
        name: "演算法",
        teacher: "李大明教授",
        classroom: "資工系館 201",
        dayOfWeek: 2, // 週二
        startSlot: 2, // 9:20-10:10
        endSlot: 4,   // 10:20-12:10
        note: "核心課程",
      ),
      Course(
        id: "demo_course_4",
        name: "離散數學",
        teacher: "林小美教授", 
        classroom: "基礎大樓 B207",
        dayOfWeek: 2, // 週二
        startSlot: 8, // 16:20-17:10
        endSlot: 9,   // 17:20-18:10
        note: "數學基礎",
      ),
      
      // 週三課程
      Course(
        id: "demo_course_5",
        name: "資料庫系統",
        teacher: "張志豪教授",
        classroom: "資工系館 301",
        dayOfWeek: 3, // 週三
        startSlot: 3, // 10:20-11:10
        endSlot: 5,   // 11:20-13:10
        note: "實務課程",
      ),
      Course(
        id: "demo_course_6",
        name: "程式設計實習",
        teacher: "劉育丞教授",
        classroom: "電腦教室 A",
        dayOfWeek: 3, // 週三
        startSlot: 6, // 14:20-15:10
        endSlot: 8,   // 15:20-17:10
        note: "實習課程",
      ),
      
      // 週四課程
      Course(
        id: "demo_course_7",
        name: "軟體工程",
        teacher: "黃建國教授",
        classroom: "資工系館 401",
        dayOfWeek: 4, // 週四
        startSlot: 2, // 9:20-10:10
        endSlot: 3,   // 10:20-11:10
        note: "專業選修",
      ),
      Course(
        id: "demo_course_8",
        name: "網路程式設計",
        teacher: "吳佳玲教授",
        classroom: "資工系館 501",
        dayOfWeek: 4, // 週四
        startSlot: 6, // 14:20-15:10
        endSlot: 7,   // 15:20-16:10
        note: "網路技術",
      ),
      
      // 週五課程
      Course(
        id: "demo_course_9",
        name: "作業系統",
        teacher: "陳宏達教授",
        classroom: "資工系館 202",
        dayOfWeek: 5, // 週五
        startSlot: 3, // 10:20-11:10
        endSlot: 4,   // 11:20-12:10
        note: "系統核心",
      ),
      Course(
        id: "demo_course_10",
        name: "人工智慧導論",
        teacher: "蔡文龍教授",
        classroom: "資工系館 601",
        dayOfWeek: 5, // 週五
        startSlot: 8, // 16:20-17:10
        endSlot: 9,   // 17:20-18:10
        note: "前沿技術",
      ),
    ];
  }

  /// 獲取演示公告資料
  static List<Announcement> getDemoAnnouncements() {
    return [
      Announcement(
        title: "期中考試時間公告",
        date: "2024-03-15",
        link: "https://demo.ntust.edu.tw/announcement/1",
      ),
      Announcement(
        title: "圖書館開放時間調整",
        date: "2024-03-13",
        link: "https://demo.ntust.edu.tw/announcement/2",
      ),
      Announcement(
        title: "校園網路維護通知",
        date: "2024-03-10",
        link: "https://demo.ntust.edu.tw/announcement/3",
      ),
    ];
  }

  /// 獲取演示行事曆事件（暫時移除，因為模型不存在）
  // static List<CalendarEvent> getDemoCalendarEvents() {
  //   // TODO: 實現當行事曆模型可用時
  //   return [];
  // }

  /// 獲取演示成績資料 - 完整的學期成績
  static List<CourseScore> getDemoCourseScores() {
    return [
      // 112-1 學期
      CourseScore(
        order: 1,
        semester: "112-1",
        courseCode: "CS3001",
        courseName: "資料結構",
        credits: "3",
        score: "92",
        note: "優秀",
        generalEducationCategory: "",
        isDistanceLearning: false,
      ),
      CourseScore(
        order: 2,
        semester: "112-1",
        courseCode: "CS3002",
        courseName: "演算法",
        credits: "3",
        score: "89",
        note: "",
        generalEducationCategory: "",
        isDistanceLearning: false,
      ),
      CourseScore(
        order: 3,
        semester: "112-1",
        courseCode: "CS3003",
        courseName: "資料庫系統",
        credits: "3",
        score: "94",
        note: "優秀",
        generalEducationCategory: "",
        isDistanceLearning: false,
      ),
      CourseScore(
        order: 4,
        semester: "112-1",
        courseCode: "CS3004",
        courseName: "軟體工程",
        credits: "3",
        score: "87",
        note: "",
        generalEducationCategory: "",
        isDistanceLearning: false,
      ),
      CourseScore(
        order: 5,
        semester: "112-1",
        courseCode: "CS3005",
        courseName: "作業系統",
        credits: "3",
        score: "91",
        note: "",
        generalEducationCategory: "",
        isDistanceLearning: false,
      ),
      
      // 111-2 學期
      CourseScore(
        order: 6,
        semester: "111-2",
        courseCode: "CS2001",
        courseName: "程式設計",
        credits: "3",
        score: "95",
        note: "優秀",
        generalEducationCategory: "",
        isDistanceLearning: false,
      ),
      CourseScore(
        order: 7,
        semester: "111-2",
        courseCode: "CS2002",
        courseName: "計算機概論",
        credits: "3",
        score: "88",
        note: "",
        generalEducationCategory: "",
        isDistanceLearning: false,
      ),
      CourseScore(
        order: 8,
        semester: "111-2",
        courseCode: "MATH201",
        courseName: "離散數學",
        credits: "3",
        score: "86",
        note: "",
        generalEducationCategory: "",
        isDistanceLearning: false,
      ),
      CourseScore(
        order: 9,
        semester: "111-2",
        courseCode: "CS2003",
        courseName: "網路程式設計",
        credits: "3",
        score: "90",
        note: "",
        generalEducationCategory: "",
        isDistanceLearning: false,
      ),
      
      // 111-1 學期
      CourseScore(
        order: 10,
        semester: "111-1",
        courseCode: "MATH101",
        courseName: "微積分",
        credits: "4",
        score: "85",
        note: "",
        generalEducationCategory: "",
        isDistanceLearning: false,
      ),
      CourseScore(
        order: 11,
        semester: "111-1",
        courseCode: "PHYS101",
        courseName: "普通物理",
        credits: "3",
        score: "82",
        note: "",
        generalEducationCategory: "",
        isDistanceLearning: false,
      ),
      CourseScore(
        order: 12,
        semester: "111-1",
        courseCode: "ENG101",
        courseName: "大一英文",
        credits: "2",
        score: "88",
        note: "",
        generalEducationCategory: "語言",
        isDistanceLearning: false,
      ),
      CourseScore(
        order: 13,
        semester: "111-1",
        courseCode: "CS1001",
        courseName: "計算機程式設計",
        credits: "3",
        score: "93",
        note: "優秀",
        generalEducationCategory: "",
        isDistanceLearning: false,
      ),
      CourseScore(
        order: 14,
        semester: "111-1",
        courseCode: "PE101",
        courseName: "體育",
        credits: "1",
        score: "90",
        note: "",
        generalEducationCategory: "體育",
        isDistanceLearning: false,
      ),
    ];
  }

  /// 獲取演示學分統計
  static CreditSummary getDemoCreditSummary() {
    return CreditSummary(
      earnedCredits: 42,          // 已獲得學分
      earnedDistanceCredits: 0,   // 已獲得遠距學分
      totalEarnedCredits: 42,     // 總已獲得學分
      inProgressCredits: 15,      // 修課中學分
      inProgressDistanceCredits: 0, // 修課中遠距學分
      totalInProgressCredits: 15,  // 總修課中學分
      totalCredits: 57,           // 總學分
      totalDistanceCredits: 0,    // 總遠距學分
      grandTotalCredits: 57,      // 總計學分
    );
  }

  /// 獲取演示排名資料
  static List<dynamic> getDemoRankingData() {
    return [
      {
        'semester': '112-1',
        'classRank': 8,
        'departmentRank': 15,
        'averageScore': 90.2,
        'classRankHistory': 1, // 進步趨勢：1=進步, 0=持平, -1=退步
        'departmentRankHistory': 1,
        'averageScoreHistory': 1.5, // 分數變化
      },
      {
        'semester': '111-2',
        'classRank': 10,
        'departmentRank': 18,
        'averageScore': 89.5,
        'classRankHistory': 0, // 持平
        'departmentRankHistory': 0,
        'averageScoreHistory': 0.7,
      },
      {
        'semester': '111-1',
        'classRank': 12,
        'departmentRank': 22,
        'averageScore': 88.8,
        'classRankHistory': 0, // 首學期，無比較基準
        'departmentRankHistory': 0,
        'averageScoreHistory': 0.0,
      },
    ];
  }

  /// 獲取演示停車場資料
  static List<ParkingLot> getDemoParkingLots() {
    return [
      ParkingLot(
        site: "demo_site_1",
        name: "資工系館停車場",
        motorSlots: 23,
      ),
      ParkingLot(
        site: "demo_site_2", 
        name: "學生活動中心停車場",
        motorSlots: 45,
      ),
      ParkingLot(
        site: "demo_site_3",
        name: "圖書館停車場",
        motorSlots: 8,
      ),
    ];
  }

  /// 模擬API延遲
  static Future<void> simulateApiDelay([int milliseconds = 800]) async {
    await Future.delayed(Duration(milliseconds: milliseconds));
  }

  /// 檢查是否為演示模式相關的帳號
  static bool isDemoAccount(String? account) {
    if (account == null) return false;
    return account.toLowerCase().contains('demo') || 
           account == demoStudentId ||
           account.toLowerCase().contains('test') ||
           account.toLowerCase().contains('apple') ||
           account.toLowerCase().contains('review');
  }

  /// 獲取演示模式提示訊息
  static String getDemoModeMessage() {
    return "目前為演示模式，顯示的資料僅供展示用途。";
  }

  /// 檢查是否應該啟用演示模式（不進行真實登入）
  static Future<bool> shouldUseDemoMode() async {
    // 這裡可以添加更複雜的檢查邏輯
    // 例如檢查是否有特定的演示模式設定
    return true; // 在演示模式下總是返回true
  }

  /// 創建一個完整的演示數據包，包含所有功能的模擬資料
  static Map<String, dynamic> getCompleteDemoData() {
    return {
      'studentInfo': {
        'id': demoStudentId,
        'name': demoStudentName,
        'email': demoEmail,
        'department': demoDepartment,
      },
      'courses': getDemoCourses(),
      'announcements': getDemoAnnouncements(),
      'scores': getDemoCourseScores(),
      'creditSummary': getDemoCreditSummary(),
      'parkingLots': getDemoParkingLots(),
      'message': getDemoModeMessage(),
      'isDemo': true,
    };
  }

  /// 獲取演示模式狀態訊息
  static String getDemoStatusMessage() {
    return "演示模式已啟用 - 所有功能正常運作，資料僅供展示";
  }
}
