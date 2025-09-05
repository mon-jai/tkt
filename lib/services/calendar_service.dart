import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import '../models/calendar_model.dart';

class CalendarService extends ChangeNotifier {
  List<Calendar> _calendars = [];
  bool _isLoading = false;
  String? _error;

  List<Calendar> get calendars => _calendars;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchCalendars() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('https://www.academic.ntust.edu.tw/p/404-1048-78935.php?Lang=zh-tw'),
      );

      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        final calendarList = <Calendar>[];

        // 尋找所有 ICS 檔案連結
        final links = document.querySelectorAll('a');
        for (var link in links) {
          final text = link.text;
          // 尋找包含 "ics檔案" 的連結
          if (text.contains('ics檔案')) {
            // 從連結文字中提取學年度和描述
            String title = text.trim();
            
            // 移除 "(ics檔案)" 字樣並清理標題
            title = title.replaceAll('(ics檔案)', '').trim();
            title = title.replaceAll(RegExp(r'\([^)]*\)'), '').trim();
            
            // 如果標題不包含"學年度行事曆"，添加它
            if (!title.contains('行事曆')) {
              title = '${title}學年度行事曆';
            }

            final url = link.attributes['href'];
            if (url != null) {
              calendarList.add(Calendar(
                title: title,
                url: url.startsWith('http') ? url : 'https://www.academic.ntust.edu.tw${url}',
                type: 'ics',
                description: 'ICS 行事曆檔案',
              ));
            }
          }
        }

        // 根據學年度排序（從新到舊）
        calendarList.sort((a, b) {
          final yearA = int.tryParse(RegExp(r'\d+').firstMatch(a.title)?.group(0) ?? '0') ?? 0;
          final yearB = int.tryParse(RegExp(r'\d+').firstMatch(b.title)?.group(0) ?? '0') ?? 0;
          return yearB.compareTo(yearA);
        });

        _calendars = calendarList;
        _error = null;
      } else {
        _error = '無法獲取行事曆資料';
        debugPrint('CalendarService: HTTP ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _error = '獲取行事曆資料時發生錯誤';
      debugPrint('CalendarService: Error fetching calendars - $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    _calendars = [];
    notifyListeners();
    await fetchCalendars();
  }
} 