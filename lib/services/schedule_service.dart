import 'package:html/parser.dart';
import 'package:tkt/connector/core/connector.dart';
import 'package:tkt/connector/core/connector_parameter.dart';
import 'package:tkt/debug/log/log.dart';
import 'package:tkt/models/course/schedule_model.dart';

class ScheduleService {
  static const String _courseSelectionHost =
      "https://courseselection.ntust.edu.tw/ChooseList/D01/D01";

  static Future<Schedule> fetchSchedule() async {
    try {

      Log.d('開始請求課表內容...');
      final parameter = ConnectorParameter(_courseSelectionHost);
      final response = await Connector.getDataByGet(parameter);
      final document = parse(response);
      Log.d('課表請求完成');
      Log.d('HTML 內容: ${document.outerHtml}'); // 如需詳細調試，可取消註解

      // --- 定位到主要內容區域 ---
      final printArea = document.querySelector('#PrintArea');

      if (printArea == null) {
        Log.e("找不到 #PrintArea 區塊，無法解析課表。");
        throw Exception("找不到 #PrintArea 區塊");
      }

      // --- 總學分數解析 (在 PrintArea 內找) ---
      final totalCreditsText =
          printArea.querySelector('div[style="color:red"]')?.text ?? '0';
      final totalCredits =
          int.tryParse(totalCreditsText.replaceAll('總學分數:', '').trim()) ?? 0;
      Log.d("總學分數: $totalCredits");

      // --- 在 PrintArea 內尋找所有表格 ---
      final tables = printArea.querySelectorAll('table');

      if (tables.length < 2) {
          Log.e("在 #PrintArea 中找不到足夠的表格 (需要至少2個)。找到 ${tables.length} 個。");
          // Log 所有找到的 table，幫助調試
          for(var i=0; i < tables.length; i++) {
              Log.d("找到的 Table $i: ${tables[i].outerHtml.substring(0, 100)}...");
          }
          throw Exception("找不到課表或課程列表表格");
      }

      // 假設第一個是課程列表，第二個是時間表 (根據 Log 推斷)
      final courseTable = tables[0];
      final scheduleTable = tables[1];


      // --- 課程列表解析 (使用 courseTable) ---
      final courses = <Course>[];
      final courseRows = courseTable.querySelectorAll('tbody tr');
      for (var i = 1; i < courseRows.length; i++) { // 跳過標題行
        final cells = courseRows[i].querySelectorAll('td');
        if (cells.length >= 5) {
          courses.add(Course(
            code: cells[0].text.trim(),
            name: cells[1].text.trim(),
            credits: int.tryParse(cells[2].text.trim()) ?? 0,
            // 處理 '必修' 或 '選修' 可能在 span 內的情況
            isRequired: cells[3].text.trim().contains('必修'),
            teacher: cells[4].text.trim(),
            note: cells.length > 5 ? cells[5].text.trim() : null,
          ));
        }
      }
      Log.d("解析到 ${courses.length} 門課程。");


      // --- 時間表解析 (使用 scheduleTable) ---
      final timeSlots = <TimeSlot>[];
      final scheduleRows = scheduleTable.querySelectorAll('tbody tr');
      for (var i = 1; i < scheduleRows.length; i++) { // 跳過標題行
        final cells = scheduleRows[i].querySelectorAll('td');
        // Log.d("時間表 Row $i: 找到 ${cells.length} 個儲存格。"); // 調試用
        if (cells.length >= 9) { // 確保有 9 個儲存格 (節次、時間 + 7 天)
          final period = cells[0].text.trim();

          // 優化時間解析：使用 .text 獲取，它會將 <br> 轉成 \n
          final timeText = cells[1].text.trim();
          // 使用正則表達式分割 '～' 或 '\n'，並過濾空字串
          final times = timeText.split(RegExp(r'[～\n]'))
                                .map((t) => t.trim())
                                .where((t) => t.isNotEmpty)
                                .toList();

          final startTime = (times.isNotEmpty ? times[0] : 'N/A');
          final endTime = (times.length > 1 ? times[1] : 'N/A');

          final schedule = <String, CourseInfo?>{};
          final weekdays = ['一', '二', '三', '四', '五', '六', '日'];
          for (var j = 0; j < 7; j++) {
            final cellContent = cells[j + 2].text.trim();
            if (cellContent.isNotEmpty) {
              final lines = cellContent
                  .split('\n')
                  .map((line) => line.trim())
                  .where((line) => line.isNotEmpty)
                  .toList();
              if (lines.isNotEmpty) {
                schedule[weekdays[j]] = CourseInfo(
                  name: lines[0],
                  classroom: lines.length > 1 ? lines[1] : ' ',
                );
              } else {
                schedule[weekdays[j]] = null;
              }
            } else {
              schedule[weekdays[j]] = null;
            }
          }

          timeSlots.add(TimeSlot(
            period: period,
            startTime: startTime,
            endTime: endTime,
            schedule: schedule,
          ));
        } else {
           Log.d("時間表 Row $i: 儲存格數量不足 (${cells.length})，跳過此行。");
        }
      }
       Log.d("解析到 ${timeSlots.length} 個時間段。");


      return Schedule(
        courses: courses,
        timeSlots: timeSlots,
        totalCredits: totalCredits,
      );
    } catch (e) {
      Log.e('獲取課表資料時發生錯誤：$e');
      rethrow; // 重新拋出錯誤，讓 UI 層可以捕捉到
    }
  }
}