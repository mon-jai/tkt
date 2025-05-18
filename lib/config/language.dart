import 'package:flutter/material.dart';

class AppLanguage {
  static const Locale zhTW = Locale('zh', 'TW');
  static const Locale enUS = Locale('en', 'US');

  static const List<Locale> supportedLocales = [
    zhTW,
    enUS,
  ];

  static String getLanguageName(Locale locale) {
    switch (locale.toString()) {
      case 'zh_TW':
        return '繁體中文';
      case 'en_US':
        return 'English';
      default:
        return '繁體中文';
    }
  }

  static final Map<String, Map<String, String>> translations = {
    'zh_TW': {
      'app_name': '台科通',
      'login': '登入',
      'logout': '登出',
      'settings': '設定',
      'dark_mode': '深色模式',
      'language': '語言設定',
      'current_language': '目前語言',
      'student_id': '學號',
      'password': '密碼',
      'course': '課程',
      'calendar': '行事曆',
      'announcement': '公告',
      'profile': '個人資料',
      'notifications': '通知設定',
      'about': '關於',
      'login_test': '登入測試',
      'login_test_description': '測試台科大登入功能',
      // 添加更多翻譯...
    },
    'en_US': {
      'app_name': 'NTUST Connect',
      'login': 'Login',
      'logout': 'Logout',
      'settings': 'Settings',
      'dark_mode': 'Dark Mode',
      'language': 'Language Settings',
      'current_language': 'Current Language',
      'student_id': 'Student ID',
      'password': 'Password',
      'course': 'Courses',
      'calendar': 'Calendar',
      'announcement': 'Announcements',
      'profile': 'Profile',
      'notifications': 'Notifications',
      'about': 'About',
      'login_test': 'Login Test',
      'login_test_description': 'Test NTUST Login Function',
      // 添加更多翻譯...
    },
  };
} 