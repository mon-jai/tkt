import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/course_model.dart';

class NotificationService {
  static const String _enabledKey = 'course_notification_enabled';
  static const String _minutesKey = 'notification_minutes';
  
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  static bool _isInitialized = false;

  /// 初始化通知服務
  static Future<void> initialize() async {
    if (_isInitialized) return;

    // 初始化時區
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Taipei'));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
    if (kDebugMode) {
      print('📱 NotificationService initialized');
    }
  }

  /// 請求通知權限
  static Future<bool> requestPermissions() async {
    await initialize();

    if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      final bool? granted = await androidImplementation?.requestNotificationsPermission();
      return granted ?? false;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final bool? result = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    }
    return true;
  }

  /// 處理通知被點擊
  static void _onNotificationTapped(NotificationResponse notificationResponse) {
    if (kDebugMode) {
      print('📱 Notification tapped: ${notificationResponse.payload}');
    }
    // TODO: 實現通知點擊後的導航邏輯
  }

  /// 獲取通知是否啟用
  static Future<bool> isNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? true;
  }

  /// 獲取提醒時間（分鐘）
  static Future<int> getNotificationMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_minutesKey) ?? 15;
  }

  /// 設定通知啟用狀態
  static Future<void> setNotificationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }

  /// 設定提醒時間
  static Future<void> setNotificationMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_minutesKey, minutes);
  }

  /// 計算課程的提醒時間
  static DateTime calculateNotificationTime(Course course, int minutesBefore) {
    return course.startTime.subtract(Duration(minutes: minutesBefore));
  }

  /// 檢查是否需要為課程設定提醒
  static bool shouldScheduleNotification(Course course) {
    final now = DateTime.now();
    final courseDateTime = course.startTime;

    // 只為今天和明天的課程設定提醒
    final isToday = courseDateTime.year == now.year &&
        courseDateTime.month == now.month &&
        courseDateTime.day == now.day;

    final tomorrow = now.add(const Duration(days: 1));
    final isTomorrow = courseDateTime.year == tomorrow.year &&
        courseDateTime.month == tomorrow.month &&
        courseDateTime.day == tomorrow.day;

    return (isToday || isTomorrow) && courseDateTime.isAfter(now);
  }

  /// 格式化通知內容
  static String formatNotificationTitle(Course course, int minutesBefore) {
    if (minutesBefore < 60) {
      return '課程提醒：${course.name} 將在 $minutesBefore 分鐘後開始';
    } else {
      final hours = minutesBefore ~/ 60;
      return '課程提醒：${course.name} 將在 $hours 小時後開始';
    }
  }

  /// 格式化通知詳細內容
  static String formatNotificationBody(Course course) {
    return '時間：${course.formattedTimeRange}\n'
           '地點：${course.classroom}\n'
           '授課教師：${course.teacher}';
  }

  /// 發送即時通知（測試用）
  static Future<void> sendNotification({
    required String title,
    required String body,
    required Course course,
  }) async {
    await initialize();

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'course_reminder_channel',
      '課程提醒',
      channelDescription: '課程開始前的提醒通知',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      course.id.hashCode, // 使用課程ID的hash作為通知ID
      title,
      body,
      platformChannelSpecifics,
      payload: course.id,
    );

    if (kDebugMode) {
      print('📱 即時通知已發送：');
      print('標題：$title');
      print('內容：$body');
      print('課程：${course.name}');
    }
  }

  /// 安排定時通知
  static Future<void> scheduleNotification({
    required Course course,
    required DateTime scheduledTime,
    required String title,
    required String body,
  }) async {
    await initialize();

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'course_reminder_channel',
      '課程提醒',
      channelDescription: '課程開始前的提醒通知',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    final tz.TZDateTime tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await _notificationsPlugin.zonedSchedule(
      course.id.hashCode, // 使用課程ID的hash作為通知ID
      title,
      body,
      tzScheduledTime,
      platformChannelSpecifics,
      payload: course.id,
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    if (kDebugMode) {
      print('⏰ 定時通知已安排：');
      print('課程：${course.name}');
      print('標題：$title');
      print('內容：$body');
      print('通知時間：${scheduledTime.toString()}');
      print('---');
    }
  }

  /// 為所有符合條件的課程安排通知
  static Future<void> scheduleNotificationsForCourses(List<Course> courses) async {
    final isEnabled = await isNotificationEnabled();
    if (!isEnabled) return;

    final minutesBefore = await getNotificationMinutes();

    for (final course in courses) {
      if (shouldScheduleNotification(course)) {
        final notificationTime = calculateNotificationTime(course, minutesBefore);
        
        // 檢查通知時間是否在未來
        if (notificationTime.isAfter(DateTime.now())) {
          final title = formatNotificationTitle(course, minutesBefore);
          final body = formatNotificationBody(course);
          
          await scheduleNotification(
            course: course,
            scheduledTime: notificationTime,
            title: title,
            body: body,
          );
        }
      }
    }
  }

  /// 取消所有課程通知
  static Future<void> cancelAllNotifications() async {
    await initialize();
    await _notificationsPlugin.cancelAll();
    if (kDebugMode) {
      print('🚫 已取消所有課程通知');
    }
  }

  /// 取消特定課程的通知
  static Future<void> cancelCourseNotification(Course course) async {
    await initialize();
    await _notificationsPlugin.cancel(course.id.hashCode);
    if (kDebugMode) {
      print('🚫 已取消課程通知：${course.name}');
    }
  }

  /// 檢查通知權限狀態
  static Future<bool> areNotificationsEnabled() async {
    await initialize();
    
    if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      return await androidImplementation?.areNotificationsEnabled() ?? false;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final IOSFlutterLocalNotificationsPlugin? iosImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      
      return await iosImplementation?.checkPermissions().then((permissions) =>
          permissions?.isEnabled ?? false) ?? false;
    }
    
    return false;
  }

  /// 發送測試通知
  static Future<void> sendTestNotification() async {
    await initialize();
    
    // 檢查權限
    final hasPermission = await areNotificationsEnabled();
    if (!hasPermission) {
      final granted = await requestPermissions();
      if (!granted) {
        throw Exception('通知權限被拒絕');
      }
    }

    // 創建測試課程
    final testCourse = Course(
      id: 'test_notification_${DateTime.now().millisecondsSinceEpoch}',
      name: '測試課程',
      teacher: '測試老師',
      classroom: '測試教室',
      dayOfWeek: DateTime.now().weekday <= 5 ? DateTime.now().weekday : 1,
      startSlot: 1,
      endSlot: 2,
      note: '這是一個測試通知',
    );

    final minutesBefore = await getNotificationMinutes();
    final title = formatNotificationTitle(testCourse, minutesBefore);
    final body = formatNotificationBody(testCourse);

    await sendNotification(
      title: title,
      body: body,
      course: testCourse,
    );
  }
}