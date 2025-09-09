//
//  TKTWidget.swift
//  TKTWidget
//
//  Created by Kiv on 2025/9/4.
//

import WidgetKit
import SwiftUI

// 課程資料結構
struct Course: Codable {
    let id: String
    let name: String
    let teacher: String
    let classroom: String
    let dayOfWeek: Int
    let startSlot: Int
    let endSlot: Int
    let note: String?
    
    // 支援 JSON 序列化時的字段名映射
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case teacher
        case classroom
        case dayOfWeek = "day_of_week"
        case startSlot = "start_slot"
        case endSlot = "end_slot"
        case note
    }
}

struct Provider: TimelineProvider {
    private let appGroupId = "group.com.example.tkt.TKTWidget" // 與 entitlements 中的 App Group ID 一致
    
    func placeholder(in context: Context) -> CourseEntry {
        CourseEntry(date: Date(), courses: [
            Course(id: "placeholder", name: "課程載入中...", teacher: "", classroom: "", dayOfWeek: 1, startSlot: 1, endSlot: 1, note: nil)
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (CourseEntry) -> ()) {
        let courses = loadTodayCoursesFromHomeWidget()
        let entry = CourseEntry(date: Date(), courses: courses)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let courses = loadTodayCoursesFromHomeWidget()
        let currentDate = Date()
        
        // 每15分鐘更新一次
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let entry = CourseEntry(date: currentDate, courses: courses)
        
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    /// 從 HomeWidget 載入今日課程（使用 home_widget 套件的資料格式）
    private func loadTodayCoursesFromHomeWidget() -> [Course] {
        guard let userDefaults = UserDefaults(suiteName: appGroupId) else {
            print("❌ 無法獲取 UserDefaults for App Group: \(appGroupId)")
            return []
        }
        
        // 首先嘗試載入預計算的今日課程
        if let todayCoursesJson = userDefaults.string(forKey: "today_courses"),
           !todayCoursesJson.isEmpty {
            print("📋 從 HomeWidget 載入今日課程資料")
            return parseCoursesFromJson(todayCoursesJson)
        }
        
        // 如果沒有今日課程資料，則從所有課程中篩選
        guard let coursesJson = userDefaults.string(forKey: "courses"),
              !coursesJson.isEmpty else {
            print("❌ 沒有找到課程資料")
            return []
        }
        
        let allCourses = parseCoursesFromJson(coursesJson)
        return filterTodayCourses(from: allCourses)
    }
    
    /// 解析 JSON 字串為課程陣列
    private func parseCoursesFromJson(_ jsonString: String) -> [Course] {
        guard let data = jsonString.data(using: .utf8) else {
            print("❌ 無法轉換 JSON 字串為 Data")
            return []
        }
        
        do {
            let courses = try JSONDecoder().decode([Course].self, from: data)
            print("✅ 成功解析 \(courses.count) 門課程")
            return courses
        } catch {
            print("❌ 解析課程 JSON 失敗: \(error)")
            return []
        }
    }
    
    /// 從所有課程中篩選今日課程
    private func filterTodayCourses(from courses: [Course]) -> [Course] {
        let today = Calendar.current.component(.weekday, from: Date())
        
        // Swift 的 weekday: 1=週日, 2=週一...7=週六
        // 轉換為 Flutter 的格式: 1=週一, 2=週二...7=週日
        let flutterWeekday: Int
        if today == 1 {
            flutterWeekday = 7  // 週日
        } else {
            flutterWeekday = today - 1  // 週一=1, 週二=2...週六=6
        }
        
        let todayCourses = courses.filter { course in
            course.dayOfWeek == flutterWeekday
        }.sorted { $0.startSlot < $1.startSlot }
        
        print("📅 今日(\(flutterWeekday))課程數量: \(todayCourses.count)")
        return todayCourses
    }
}

struct CourseEntry: TimelineEntry {
    let date: Date
    let courses: [Course]
}

struct TKTWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // 標題
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
                Text("今日課程")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text(formatDate(entry.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            if entry.courses.isEmpty {
                VStack(spacing: getEmptyViewSpacing()) {
                    Image(systemName: "calendar.badge.minus")
                        .font(getEmptyIconFont())
                        .foregroundColor(.gray)
                    Text("今日無課程")
                        .font(getEmptyTextFont())
                        .foregroundColor(.secondary)
                    if family != .systemSmall {
                        Text("好好享受休息時光")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                if family == .systemSmall {
                    // 小 Widget：垂直排列 3 個課程
                    VStack(alignment: .leading, spacing: getCourseSpacing()) {
                        ForEach(entry.courses.prefix(getMaxCourseCount()), id: \.id) { course in
                            CourseRowView(course: course, family: family)
                        }
                        
                        if entry.courses.count > getMaxCourseCount() {
                            Text("還有 \(entry.courses.count - getMaxCourseCount()) 門課程...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 2)
                        }
                    }
                } else {
                    // 中大型 Widget：條列式排列 4 個課程
                    VStack(alignment: .leading, spacing: getCourseSpacing()) {
                        ForEach(entry.courses.prefix(getMaxCourseCount()), id: \.id) { course in
                            CourseRowView(course: course, family: family)
                        }
                        
                        if entry.courses.count > getMaxCourseCount() {
                            Text("還有 \(entry.courses.count - getMaxCourseCount()) 門課程...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 2)
                        }
                    }
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(getPadding())
    }
    
    // 根據 Widget 大小決定最大顯示課程數量
    private func getMaxCourseCount() -> Int {
        switch family {
        case .systemSmall:
            return 3
        case .systemMedium:
            return 4
        case .systemLarge:
            return 6
        case .systemExtraLarge:
            return 8
        @unknown default:
            return 3
        }
    }
    
    // 根據 Widget 大小調整課程間距
    private func getCourseSpacing() -> CGFloat {
        switch family {
        case .systemSmall:
            return 4
        case .systemMedium:
            return 1
        case .systemLarge:
            return 4
        case .systemExtraLarge:
            return 10
        @unknown default:
            return 6
        }
    }
    
    // 根據 Widget 大小調整整體 padding
    private func getPadding() -> CGFloat {
        switch family {
        case .systemSmall:
            return 10
        case .systemMedium:
            return 10
        case .systemLarge:
            return 14
        case .systemExtraLarge:
            return 20
        @unknown default:
            return 16
        }
    }
    
    // 根據 Widget 大小調整空狀態圖標字體大小
    private func getEmptyIconFont() -> Font {
        switch family {
        case .systemSmall:
            return .title3
        case .systemMedium  :
            return .title2
        case .systemLarge:
            return .title
        case .systemExtraLarge:
            return .largeTitle
        @unknown default:
            return .title2
        }
    }
    
    // 根據 Widget 大小調整空狀態文字字體大小
    private func getEmptyTextFont() -> Font {
        switch family {
        case .systemSmall:
            return .caption
        case .systemSmall:
            return .caption
        case .systemLarge:
            return .caption
        case .systemExtraLarge:
            return .title3
        @unknown default:
            return .body
        }
    }
    
    // 根據 Widget 大小調整空狀態間距
    private func getEmptyViewSpacing() -> CGFloat {
        switch family {
        case .systemSmall:
            return 4
        case .systemMedium:
            return 6
        case .systemLarge:
            return 10
        case .systemExtraLarge:
            return 12
        @unknown default:
            return 8
        }
    }
    
    // 獲取 App Group 調試信息的方法
    private func getAppGroupDebugInfo() -> (totalCourses: Int, rawData: [String]) {
        guard let userDefaults = UserDefaults(suiteName: "group.com.example.tkt.TKTWidget") else {
            return (0, ["❌ 無法存取 App Group"])
        }
        
        guard let coursesData = userDefaults.stringArray(forKey: "courses") else {
            return (0, ["❌ 沒有課程資料"])
        }
        
        return (coursesData.count, Array(coursesData.prefix(2))) // 只取前2筆避免 Widget 太擠
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

struct CourseRowView: View {
    let course: Course
    let family: WidgetFamily
    
    var body: some View {
        if family == .systemSmall {
            // 小 Widget：單排顯示，左邊課程名，右邊節次
            HStack {
                Text(course.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(course.startSlot)-\(course.endSlot)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)
            }
            .padding(.vertical, 2)
        } else {
            // 中大型 Widget：條列式顯示
            HStack(spacing: 8) {
                // 左側顏色指示器
                RoundedRectangle(cornerRadius: 2)
                    .fill(getCourseColor())
                    .frame(width: 4, height: getIndicatorHeight())
                
                VStack(alignment: .leading, spacing: getInnerSpacing()) {
                    // 課程名稱和節次在同一排
                    HStack {
                        Text(course.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("第\(course.startSlot)-\(course.endSlot)節")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                    }
                    
                    // 教室信息（僅在大型 Widget 中顯示）
                    if shouldShowClassroom() && !course.classroom.isEmpty {
                        Text(course.classroom)
                            .font(getClassroomFont())
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.vertical, getVerticalPadding())
        }
    }
    
    // 獲取課程顏色（根據課程開始時間決定顏色）
    private func getCourseColor() -> Color {
        switch course.startSlot {
        case 1...2:
            return .blue
        case 3...5:
            return .green
        case 6...8:
            return .orange
        case 9...11:
            return .purple
        default:
            return .red
        }
    }
    
    // 根據 Widget 大小調整指示器高度
    private func getIndicatorHeight() -> CGFloat {
        switch family {
        case .systemSmall:
            return 20
        case .systemMedium:
            return 22
        case .systemLarge:
            return 35
        case .systemExtraLarge:
            return 45
        @unknown default:
            return 25
        }
    }
    
    // 根據 Widget 大小調整垂直 padding
    private func getVerticalPadding() -> CGFloat {
        switch family {
        case .systemSmall:
            return 2
        case .systemMedium:
            return 1
        case .systemLarge:
            return 2
        case .systemExtraLarge:
            return 4
        @unknown default:
            return 2
        }
    }
    
    // 決定是否顯示教室信息
    private func shouldShowClassroom() -> Bool {
        switch family {
        case .systemSmall, .systemMedium:
            return false
        case .systemLarge, .systemExtraLarge:
            return true
        @unknown default:
            return false
        }
    }
    
    // 獲取內部元素間距（課程名稱與教室信息之間）
    private func getInnerSpacing() -> CGFloat {
        switch family {
        case .systemLarge, .systemExtraLarge:
            return 2
        default:
            return 0
        }
    }
    
    // 獲取教室信息字體大小
    private func getClassroomFont() -> Font {
        switch family {
        case .systemLarge:
            return .caption2
        case .systemExtraLarge:
            return .caption
        default:
            return .caption2
        }
    }
}

// Color extension to handle hex colors
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct TKTWidget: Widget {
    let kind: String = "TKTWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                TKTWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                TKTWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("TKT 課程表")
        .description("顯示今日課程安排")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
    }
}

