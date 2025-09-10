import 'package:flutter/services.dart';
import 'dart:io' show Platform;

class AlarmPermissionService {
  static const platform = MethodChannel('com.tkt.app/alarm_permission');

  /// 檢查是否有 Exact Alarm 權限（僅適用於 Android 12 及以上版本）
  static Future<bool> checkExactAlarmPermission() async {
    if (!Platform.isAndroid) {
      return true; // 非 Android 平台直接返回 true
    }

    try {
      final int sdkVersion = await platform.invokeMethod('getAndroidSDKVersion');
      if (sdkVersion < 31) {
        // Android 12 (API 31) 以下版本不需要此權限
        return true;
      }

      final bool hasPermission = await platform.invokeMethod('checkExactAlarmPermission');
      return hasPermission;
    } on PlatformException catch (e) {
      print('檢查 Exact Alarm 權限時發生錯誤: ${e.message}');
      return false;
    }
  }

  /// 打開系統設置頁面讓用戶授予權限
  static Future<void> openAlarmPermissionSettings() async {
    if (!Platform.isAndroid) {
      return;
    }

    try {
      // 使用 Future.delayed 來確保設置頁面有時間打開
      await Future.delayed(const Duration(milliseconds: 500));
      await platform.invokeMethod('openAlarmPermissionSettings');
      // 等待用戶操作
      await Future.delayed(const Duration(seconds: 2));
    } on PlatformException catch (e) {
      print('打開權限設置頁面時發生錯誤: ${e.message}');
    }
  }
}
