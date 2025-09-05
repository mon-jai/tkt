import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:icalendar_parser/icalendar_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:html/parser.dart' as html;
import '../models/calendar_event_model.dart';

class IcsCalendarService extends ChangeNotifier {
  List<CalendarEvent> _events = [];
  bool _isLoading = false;
  String? _error;
  double _downloadProgress = 0.0;
  SharedPreferences? _prefs;
  String _currentCalendarTitle = '';
  Map<String, String> _dynamicCalendarUrls = {}; // 動態獲取的行事曆列表
  bool _isLoadingCalendarList = false; // 是否正在載入行事曆列表

  List<CalendarEvent> get events => _events;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get downloadProgress => _downloadProgress;
  String get currentCalendarTitle => _currentCalendarTitle;
  bool get isLoadingCalendarList => _isLoadingCalendarList;
  Map<String, String> get dynamicCalendarUrls => _dynamicCalendarUrls;

  static const String _cacheKey = 'cached_ics_calendar';
  static const String _cacheUrlKey = 'cached_ics_url';
  static const String _cacheTimeKey = 'cached_ics_time';

  /// 初始化 SharedPreferences
  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// 初始化並自動載入行事曆（先從緩存載入，如果沒有則自動下載）
  Future<void> initializeAndAutoLoad(String url) async {
    await _initPrefs();
    
    // 先嘗試從緩存載入
    final hasCache = await _loadFromCache();
    
    if (!hasCache) {
      // 如果沒有緩存，自動下載
      debugPrint('沒有找到緩存的行事曆，自動下載...');
      await downloadAndParseIcs(url, saveToCache: true);
    } else {
      debugPrint('成功從緩存載入 ${_events.length} 個行事曆事件');
      notifyListeners();
    }
  }

  /// 從緩存載入行事曆
  Future<bool> _loadFromCache() async {
    try {
      await _initPrefs();
      final cachedContent = _prefs?.getString(_cacheKey);
      
      if (cachedContent != null && cachedContent.isNotEmpty) {
        await _parseIcsContent(cachedContent);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('從緩存載入行事曆失敗: $e');
      return false;
    }
  }

  /// 強制重新下載並覆蓋緩存
  Future<void> forceRedownload(String url) async {
    debugPrint('強制重新下載行事曆...');
    await clearCache(); // 清除舊緩存
    await downloadAndParseIcs(url, saveToCache: true);
  }

  /// 將 ICS 內容保存到緩存
  Future<void> _saveToCache(String icsContent, String url) async {
    try {
      await _initPrefs();
      await _prefs?.setString(_cacheKey, icsContent);
      await _prefs?.setString(_cacheUrlKey, url);
      await _prefs?.setInt(_cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
      debugPrint('行事曆已保存到緩存');
    } catch (e) {
      debugPrint('保存行事曆到緩存失敗: $e');
    }
  }

  /// 清除緩存
  Future<void> clearCache() async {
    try {
      await _initPrefs();
      await _prefs?.remove(_cacheKey);
      await _prefs?.remove(_cacheUrlKey);
      await _prefs?.remove(_cacheTimeKey);
      debugPrint('行事曆緩存已清除');
    } catch (e) {
      debugPrint('清除行事曆緩存失敗: $e');
    }
  }

  /// 檢查緩存是否過期（超過 24 小時）
  Future<bool> isCacheExpired() async {
    try {
      await _initPrefs();
      final cacheTime = _prefs?.getInt(_cacheTimeKey);
      if (cacheTime == null) return true;
      
      final now = DateTime.now().millisecondsSinceEpoch;
      final diff = now - cacheTime;
      return diff > (24 * 60 * 60 * 1000); // 24 小時
    } catch (e) {
      return true;
    }
  }

  /// 從 URL 下載並解析 ICS 行事曆檔案
  Future<void> downloadAndParseIcs(String url, {bool saveToCache = false}) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    _downloadProgress = 0.0;
    notifyListeners();

    try {
      debugPrint('開始下載 ICS 檔案: $url');
      
      // 下載 ICS 檔案
      final content = await _downloadIcsFile(url);
      
      // 如果需要，先保存到緩存
      if (saveToCache) {
        await _saveToCache(content, url);
      }
      
      // 解析 ICS 內容
      await _parseIcsContent(content);
      
      _error = null;
      debugPrint('成功解析 ${_events.length} 個 ICS 事件');
    } catch (e) {
      _error = '解析 ICS 行事曆時發生錯誤: ${e.toString()}';
      debugPrint('IcsCalendarService: Error - $e');
    } finally {
      _isLoading = false;
      _downloadProgress = 0.0;
      notifyListeners();
    }
  }

  /// 下載 ICS 檔案內容
  Future<String> _downloadIcsFile(String url) async {
    final dio = Dio();
    final response = await dio.get(
      url,
      options: Options(responseType: ResponseType.plain),
      onReceiveProgress: (received, total) {
        if (total > 0) {
          _downloadProgress = received / total;
          notifyListeners();
        }
      },
    );
    
    if (response.statusCode == 200) {
      return response.data.toString();
    } else {
      throw Exception('無法下載 ICS 檔案: HTTP ${response.statusCode}');
    }
  }

  /// 解析 ICS 檔案內容
  Future<void> _parseIcsContent(String icsContent) async {
    try {
      // 使用 icalendar_parser 解析 ICS 內容
      final icsCalendar = ICalendar.fromString(icsContent);
      final events = <CalendarEvent>[];
      
      debugPrint('解析到 ${icsCalendar.data.length} 個 ICS 組件');
      
      for (final component in icsCalendar.data) {
        if (component['type'] == 'VEVENT') {
          final event = _parseIcsEvent(component);
          if (event != null) {
            events.add(event);
          }
        }
      }
      
      // 按日期排序事件
      events.sort((a, b) => a.date.compareTo(b.date));
      _events = events;
      
      debugPrint('成功解析 ${events.length} 個行事曆事件');
    } catch (e) {
      throw Exception('ICS 檔案格式錯誤: ${e.toString()}');
    }
  }

  /// 解析單個 ICS 事件
  CalendarEvent? _parseIcsEvent(Map<String, dynamic> eventData) {
    try {
      // 取得必要的事件資訊
      final summary = eventData['summary']?.toString();
      final description = eventData['description']?.toString();
      final dtStart = eventData['dtstart'];
      final dtEnd = eventData['dtend'];
      final categories = eventData['categories']?.toString();
      
      if (summary == null || dtStart == null) {
        debugPrint('跳過無效的事件: summary=$summary, dtstart=$dtStart');
        return null;
      }
      
      // 解析開始日期
      DateTime? startDate;
      try {
        if (dtStart is DateTime) {
          startDate = dtStart;
        } else if (dtStart.toString().contains('IcsDateTime')) {
          // 處理 IcsDateTime 物件
          final dateStr = _extractDateFromIcsDateTime(dtStart.toString());
          if (dateStr != null) {
            startDate = _parseIcsDate(dateStr);
          }
        } else if (dtStart is String) {
          startDate = _parseIcsDate(dtStart);
        } else {
          // 嘗試從物件中提取日期字串
          final dateStr = _extractDateFromObject(dtStart);
          if (dateStr != null) {
            startDate = _parseIcsDate(dateStr);
          }
        }
      } catch (e) {
        debugPrint('無法解析開始日期: $dtStart, 錯誤: $e');
      }
      
      if (startDate == null) {
        debugPrint('跳過無效的事件，無法解析開始日期: $dtStart');
        return null;
      }
      
      // 解析結束日期（如果有的話）
      DateTime? endDate;
      if (dtEnd != null) {
        try {
          if (dtEnd is DateTime) {
            endDate = dtEnd;
          } else if (dtEnd.toString().contains('IcsDateTime')) {
            // 處理 IcsDateTime 物件
            final dateStr = _extractDateFromIcsDateTime(dtEnd.toString());
            if (dateStr != null) {
              endDate = _parseIcsDate(dateStr);
            }
          } else if (dtEnd is String) {
            endDate = _parseIcsDate(dtEnd);
          } else {
            // 嘗試從物件中提取日期字串
            final dateStr = _extractDateFromObject(dtEnd);
            if (dateStr != null) {
              endDate = _parseIcsDate(dateStr);
            }
          }
        } catch (e) {
          debugPrint('無法解析結束日期: $dtEnd, 錯誤: $e');
        }
      }
      
      // 創建事件
      return CalendarEvent(
        title: summary,
        date: startDate,
        endDate: endDate,
        description: description,
        type: categories ?? '學校行事',
        color: _getEventColor(summary),
      );
    } catch (e) {
      debugPrint('解析事件時發生錯誤: $e');
      return null;
    }
  }

  /// 解析 ICS 日期格式
  DateTime _parseIcsDate(String dateStr) {
    // ICS 日期格式通常是：
    // YYYYMMDD 或 YYYYMMDDTHHMMSS 或 YYYYMMDDTHHMMSSZ
    dateStr = dateStr.replaceAll(RegExp(r'[TZ]'), '');
    
    if (dateStr.length >= 8) {
      final year = int.parse(dateStr.substring(0, 4));
      final month = int.parse(dateStr.substring(4, 6));
      final day = int.parse(dateStr.substring(6, 8));
      
      int hour = 0, minute = 0, second = 0;
      if (dateStr.length >= 12) {
        hour = int.parse(dateStr.substring(8, 10));
        minute = int.parse(dateStr.substring(10, 12));
        if (dateStr.length >= 14) {
          second = int.parse(dateStr.substring(12, 14));
        }
      }
      
      return DateTime(year, month, day, hour, minute, second);
    }
    
    throw FormatException('無效的 ICS 日期格式: $dateStr');
  }

  /// 從 IcsDateTime 物件字串中提取日期
  String? _extractDateFromIcsDateTime(String icsDateTimeStr) {
    // 例如：IcsDateTime{tzid: null, dt: 20260622}
    final match = RegExp(r'dt:\s*(\d{8,14})').firstMatch(icsDateTimeStr);
    return match?.group(1);
  }

  /// 從任意物件中提取日期字串
  String? _extractDateFromObject(dynamic obj) {
    if (obj == null) return null;
    
    final objStr = obj.toString();
    
    // 嘗試從物件字串中找到日期格式
    final patterns = [
      RegExp(r'dt:\s*(\d{8,14})'),           // IcsDateTime 格式
      RegExp(r'(\d{8}T?\d{0,6}Z?)'),         // 直接的日期格式
      RegExp(r'(\d{4}-\d{2}-\d{2})'),        // ISO 日期格式
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(objStr);
      if (match != null) {
        return match.group(1);
      }
    }
    
    return null;
  }

  /// 根據事件標題獲取顏色
  Color _getEventColor(String title) {
    final lowerTitle = title.toLowerCase();
    
    if (lowerTitle.contains('開學') || lowerTitle.contains('註冊') || lowerTitle.contains('開始')) {
      return Colors.green;
    } else if (lowerTitle.contains('考試') || lowerTitle.contains('期中') || lowerTitle.contains('期末')) {
      return Colors.red;
    } else if (lowerTitle.contains('放假') || lowerTitle.contains('假期') || lowerTitle.contains('休假')) {
      return Colors.blue;
    } else if (lowerTitle.contains('畢業') || lowerTitle.contains('典禮')) {
      return Colors.purple;
    } else if (lowerTitle.contains('選課') || lowerTitle.contains('加退選')) {
      return Colors.orange;
    } else if (lowerTitle.contains('截止') || lowerTitle.contains('結束')) {
      return Colors.red.shade300;
    } else if (lowerTitle.contains('會議') || lowerTitle.contains('說明會')) {
      return Colors.teal;
    } else {
      return Colors.grey.shade600;
    }
  }

  /// 行事曆資訊模型
  static const Map<String, String> _calendarUrls = {
    '114學年度行事曆': 'https://www.academic.ntust.edu.tw/var/file/48/1048/img/788923882.ics',
    '113學年度行事曆': 'https://www.academic.ntust.edu.tw/var/file/48/1048/img/NTUST113.ics',
    '112學年度行事曆': 'https://www.academic.ntust.edu.tw/var/file/48/1048/img/NTUST112_.ics',
    '111學年度行事曆': 'https://www.academic.ntust.edu.tw/var/file/48/1048/img/NTUST111.ics',
    '110學年度行事曆': 'https://www.academic.ntust.edu.tw/var/file/48/1048/img/541567461.ics',
  };

  /// 獲取可用的行事曆列表
  List<String> getAvailableCalendars() {
    // 如果動態資料可用，使用動態資料；否則回退到硬編碼列表
    if (_dynamicCalendarUrls.isNotEmpty) {
      return _dynamicCalendarUrls.keys.toList();
    }
    return _calendarUrls.keys.toList();
  }

  /// 獲取行事曆的 URL
  String? getCalendarUrl(String yearTitle) {
    // 優先使用動態資料
    if (_dynamicCalendarUrls.containsKey(yearTitle)) {
      return _dynamicCalendarUrls[yearTitle];
    }
    // 回退到硬編碼列表
    return _calendarUrls[yearTitle];
  }

  /// 載入指定學年度的行事曆
  Future<void> loadCalendarByYear(String yearTitle) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    _downloadProgress = 0.0;
    notifyListeners();

    try {
      final url = getCalendarUrl(yearTitle);
      if (url == null) {
        throw Exception('找不到 $yearTitle 的行事曆 URL');
      }
      
      _currentCalendarTitle = yearTitle;
      await initializeAndAutoLoad(url);
    } catch (e) {
      _error = '載入 $yearTitle 時發生錯誤: ${e.toString()}';
    } finally {
      _isLoading = false;
      _downloadProgress = 0.0;
      notifyListeners();
    }
  }

  /// 獲取指定日期的事件
  List<CalendarEvent> getEventsForDay(DateTime day) {
    return _events.where((event) {
      return event.getAllDates().any((eventDate) => 
          CalendarEvent.isSameDay(eventDate, day));
    }).toList();
  }

  /// 清除所有事件
  void clearEvents() {
    _events.clear();
    _error = null;
    notifyListeners();
  }

  /// 載入最新的行事曆
  Future<void> loadLatestCalendar() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    _downloadProgress = 0.0;
    notifyListeners();

    try {
      // 使用最新的行事曆 URL (114學年度)
      const latestCalendarUrl = 'https://www.academic.ntust.edu.tw/var/file/48/1048/img/788923882.ics';
      _currentCalendarTitle = '114學年度行事曆';
      
      // 載入最新的行事曆
      await initializeAndAutoLoad(latestCalendarUrl);
    } catch (e) {
      _error = '載入最新行事曆時發生錯誤: ${e.toString()}';
      debugPrint('IcsCalendarService: Error loading latest calendar - $e');
    } finally {
      _isLoading = false;
      _downloadProgress = 0.0;
      notifyListeners();
    }
  }

  /// 動態從網站抓取可用的行事曆列表
  Future<void> fetchAvailableCalendars() async {
    if (_isLoadingCalendarList) return;
    
    _isLoadingCalendarList = true;
    notifyListeners();
    
    try {
      debugPrint('開始從網站抓取行事曆列表...');
      
      final dio = Dio();
      final response = await dio.get(
        'https://www.academic.ntust.edu.tw/p/404-1048-78935.php?Lang=zh-tw',
        options: Options(
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          },
        ),
      );
      
      if (response.statusCode == 200) {
        final document = html.parse(response.data);
        final calendarMap = <String, String>{};
        
        // 尋找所有包含 ics 檔案的連結
        final links = document.querySelectorAll('a');
        
        for (final link in links) {
          final href = link.attributes['href'];
          final text = link.text.trim();
          
          // 檢查是否是 ICS 檔案連結
          if (href != null && href.contains('.ics') && text.contains('學年度')) {
            String fullUrl = href;
            if (!href.startsWith('http')) {
              fullUrl = 'https://www.academic.ntust.edu.tw$href';
            }
            
            // 清理標題
            String cleanTitle = text;
            if (text.contains('(ics檔案)')) {
              cleanTitle = text.replaceAll('(ics檔案)', '').trim();
            }
            if (!cleanTitle.contains('行事曆')) {
              cleanTitle = '${cleanTitle}行事曆';
            }
            
            calendarMap[cleanTitle] = fullUrl;
            debugPrint('找到行事曆: $cleanTitle -> $fullUrl');
          }
        }
        
        // 按學年度排序（從新到舊）
        final sortedEntries = calendarMap.entries.toList()..sort((a, b) {
          final yearA = _extractYearFromTitle(a.key);
          final yearB = _extractYearFromTitle(b.key);
          return yearB.compareTo(yearA); // 降序排列
        });
        
        _dynamicCalendarUrls = Map.fromEntries(sortedEntries);
        debugPrint('成功抓取到 ${_dynamicCalendarUrls.length} 個行事曆');
        
      } else {
        throw Exception('無法抓取網頁資料: HTTP ${response.statusCode}');
      }
      
    } catch (e) {
      debugPrint('抓取行事曆列表失敗: $e');
      // 如果抓取失敗，使用備用的硬編碼列表
      _dynamicCalendarUrls = {
        '114學年度行事曆': 'https://www.academic.ntust.edu.tw/var/file/48/1048/img/788923882.ics',
        '113學年度行事曆': 'https://www.academic.ntust.edu.tw/var/file/48/1048/img/NTUST113.ics',
        '112學年度行事曆': 'https://www.academic.ntust.edu.tw/var/file/48/1048/img/NTUST112_.ics',
      };
    } finally {
      _isLoadingCalendarList = false;
      notifyListeners();
    }
  }

  /// 從標題中提取學年度數字
  int _extractYearFromTitle(String title) {
    final match = RegExp(r'(\d{3})學年度').firstMatch(title);
    if (match != null) {
      return int.parse(match.group(1)!);
    }
    return 0; // 無法解析時返回 0
  }
}
