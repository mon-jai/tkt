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

        // 尋找所有行事曆連結（不包含 ics 檔案）
        final links = document.querySelectorAll('a');
        for (var link in links) {
          final text = link.text;
          if (text.contains('學年度行事曆') && !text.contains('ics檔案') && !text.contains('如何匯入')) {
            // 從連結文字中提取學年度和描述
            String title = text.trim();
            String? description;
            
            // 處理特殊情況（如110學年度的備註）
            if (title.contains('(經本校')) {
              final parts = title.split('(');
              title = parts[0].trim();
              description = '(${parts[1]}';
            }

            // 移除標題中的括號內容
            title = title.replaceAll(RegExp(r'\([^)]*\)'), '').trim();
            // 移除 "ods版" 字樣
            title = title.replaceAll('ods版', '').trim();

            final url = link.attributes['href'];
            if (url != null) {
              calendarList.add(Calendar(
                title: title,
                url: url.startsWith('http') ? url : 'https://www.academic.ntust.edu.tw${url}',
                type: 'xlsx',
                description: description,
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