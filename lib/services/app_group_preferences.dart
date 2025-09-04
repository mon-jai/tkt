import 'package:flutter/services.dart';
import 'dart:io';

class AppGroupPreferences {
  static const MethodChannel _channel = MethodChannel('app_group_preferences');
  static String? _appGroupSuiteName;

  /// 初始化 App Group SharedPreferences
  static Future<void> initialize() async {
    if (Platform.isIOS) {
      try {
        _appGroupSuiteName = await _channel.invokeMethod('getAppGroupSuiteName');
        if (_appGroupSuiteName != null) {
          print('✅ App Group 初始化成功: $_appGroupSuiteName');
        } else {
          print('❌ 無法獲取 App Group Suite Name');
        }
      } catch (e) {
        print('❌ App Group 初始化失敗: $e');
      }
    }
  }

  /// 獲取 App Group Suite Name
  static String? get appGroupSuiteName => _appGroupSuiteName;

  /// 儲存字符串列表
  static Future<bool> setStringList(String key, List<String> value) async {
    if (Platform.isIOS) {
      try {
        final result = await _channel.invokeMethod('setStringList', {
          'key': key,
          'value': value,
        });
        print('🔧 setStringList 結果: $result for key: $key');
        return result == true;
      } catch (e) {
        print('❌ setStringList 失敗: $e');
        return false;
      }
    }
    return false;
  }

  /// 獲取字符串列表
  static Future<List<String>?> getStringList(String key) async {
    if (Platform.isIOS) {
      try {
        final result = await _channel.invokeMethod('getStringList', {'key': key});
        if (result is List) {
          // 安全地轉換，過濾掉 null 值
          final stringList = <String>[];
          for (final item in result) {
            if (item is String && item.isNotEmpty) {
              stringList.add(item);
            }
          }
          return stringList;
        }
        return null;
      } catch (e) {
        print('❌ getStringList 失敗: $e');
        return null;
      }
    }
    return null;
  }

  /// 儲存整數
  static Future<bool> setInt(String key, int value) async {
    if (Platform.isIOS) {
      try {
        final result = await _channel.invokeMethod('setInt', {
          'key': key,
          'value': value,
        });
        return result == true;
      } catch (e) {
        print('❌ setInt 失敗: $e');
        return false;
      }
    }
    return false;
  }

  /// 獲取整數
  static Future<int?> getInt(String key) async {
    if (Platform.isIOS) {
      try {
        final result = await _channel.invokeMethod('getInt', {'key': key});
        return result is int ? result : null;
      } catch (e) {
        print('❌ getInt 失敗: $e');
        return null;
      }
    }
    return null;
  }

  /// 移除鍵值
  static Future<bool> remove(String key) async {
    if (Platform.isIOS) {
      try {
        final result = await _channel.invokeMethod('remove', {'key': key});
        return result == true;
      } catch (e) {
        print('❌ remove 失敗: $e');
        return false;
      }
    }
    return false;
  }

  /// 檢查是否包含鍵值
  static Future<bool> containsKey(String key) async {
    if (Platform.isIOS) {
      try {
        final result = await _channel.invokeMethod('containsKey', {'key': key});
        return result == true;
      } catch (e) {
        print('❌ containsKey 失敗: $e');
        return false;
      }
    }
    return false;
  }
}
