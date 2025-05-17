import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import '../models/announcement_model.dart';

class AnnouncementService {
  // 台科大公告頁面網址 (中文版)
  static const String _baseUrl = 'https://www.ntust.edu.tw/p/403-1000-168-{page}.php?Lang=zh-tw';
  static const String _ntustBaseUrl = 'https://www.ntust.edu.tw';

  Future<List<Announcement>> fetchAnnouncements({int page = 1}) async {
    try {
      final url = _baseUrl.replaceAll('{page}', page.toString());
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception('無法連接到台科大網站，狀態碼: ${response.statusCode}');
      }

      final document = parser.parse(response.body);
      final announcements = <Announcement>[];

      // 找到包含公告的表格
      final table = document.querySelector('table');
      if (table == null) {
        print('警告：找不到公告表格，請檢查網頁結構。');
        return announcements;
      }

      // 獲取所有的表格行（tr）
      final rows = table.querySelectorAll('tr');
      
      // 跳過表頭行
      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        final cells = row.querySelectorAll('td');
        
        if (cells.length >= 2) {
          final dateCell = cells[0];
          final titleCell = cells[1];
          final linkElement = titleCell.querySelector('a');
          
          if (dateCell != null && linkElement != null) {
            final date = dateCell.text.trim();
            final title = linkElement.text.trim();
            final rawLink = linkElement.attributes['href'] ?? '';
            
            // 處理連結
            String fullLink;
            if (rawLink.startsWith('http')) {
              fullLink = rawLink;
            } else {
              // 移除開頭的斜線（如果有）
              final cleanLink = rawLink.startsWith('/') ? rawLink.substring(1) : rawLink;
              fullLink = '$_ntustBaseUrl/$cleanLink';
            }

            announcements.add(Announcement(
              title: title,
              date: date,
              link: fullLink,
            ));
          }
        }
      }

      return announcements;
    } catch (e) {
      throw Exception('獲取公告失敗: $e');
    }
  }

  Future<String> fetchAnnouncementDetail(String url) async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception('無法載入公告內容，狀態碼: ${response.statusCode}');
      }

      final document = parser.parse(response.body);
      
      // 找到公告內容區域
      final contentElement = document.querySelector('.mcont');
      if (contentElement == null) {
        throw Exception('無法找到公告內容');
      }

      // 移除不需要的元素（如果有的話）
      contentElement.querySelectorAll('script').forEach((element) => element.remove());
      contentElement.querySelectorAll('style').forEach((element) => element.remove());

      // 獲取純文本內容
      return contentElement.innerHtml;
    } catch (e) {
      throw Exception('獲取公告詳情失敗: $e');
    }
  }
}

// 主函數範例 (用於測試)
// 在您的 Flutter/Dart 應用中，您會在其他地方調用 fetchAnnouncements
Future<void> main() async {
  final service = AnnouncementService();
  try {
    final announcements = await service.fetchAnnouncements();
    if (announcements.isEmpty) {
      print('未抓取到任何公告。');
    } else {
      print('抓取到的公告 (${announcements.length} 則):');
      for (var announcement in announcements) {
        print('  標題: ${announcement.title}');
        print('  日期: ${announcement.date}');
        print('  連結: ${announcement.link}');
        print('---');
      }
    }
  } catch (e) {
    print('發生錯誤: $e');
  }
}
