import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tkt/connector/ntust_connector.dart';
import 'package:tkt/connector/core/dio_connector.dart';
import 'package:tkt/pages/webview_screen.dart'; // 直接複用你的 WebViewScreen

class LoginTask {
  static const String _studentIdKey = 'stored_student_id';
  static const String _passwordKey = 'stored_password';

  /// 自動登入，失敗或遇到 reCAPTCHA 時 fallback 為 WebView 手動登入
  static Future<Map<String, dynamic>> loginWithFallback(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final account = prefs.getString(_studentIdKey) ?? '';
      final password = prefs.getString(_passwordKey) ?? '';

      if (account.isEmpty || password.isEmpty) {
        return {
          'status': NTUSTLoginStatus.fail,
          'message': '請先在帳號儲存頁面設定學號與密碼'
        };
      }

      // 0. 確保 DioConnector 已初始化
      try {
        await DioConnector.instance.init();
      } catch (e) {
        return {
          'status': NTUSTLoginStatus.fail,
          'message': 'DioConnector 初始化失敗: $e'
        };
      }

      // 1. 嘗試自動登入
      try {
        final result = await NTUSTConnector.login(account, password);
        
        if (result['status'] == NTUSTLoginStatus.success) {
          return result;
        }
      } catch (e) {
        // 自動登入發生任何錯誤，繼續執行手動登入
      }

      // 2. 自動登入失敗，直接使用手動登入
      try {
        // 參考 ntust_test_page.dart 的實現方式
        final result = await Navigator.push<Map<String, dynamic>>(
          context,
          MaterialPageRoute(
            builder: (_) => WebViewScreen(
              initialUrl: NTUSTConnector.ntustLoginUrl,
              title: '台科大登入',
              username: account,
              password: password,
              onLoginResult: (bool success) {
                try {
                  if (success) {
                    Navigator.of(context).pop({
                      'status': NTUSTLoginStatus.success,
                      'message': 'WebView登入成功'
                    });
                  }
                  // 不要在失敗時立即 pop，讓使用者可以重試
                } catch (e) {
                  // 避免在登入結果處理時發生錯誤導致崩潰
                  Navigator.of(context).pop({
                    'status': NTUSTLoginStatus.success, // 假設登入成功
                    'message': 'WebView登入完成'
                  });
                }
              },
            ),
          ),
        );
        
        if (result != null && result is Map<String, dynamic>) {
          return result;
        }
        
        // 如果沒有正確的結果，回傳失敗
        return {'status': NTUSTLoginStatus.fail, 'message': 'WebView登入未完成'};
        
      } catch (e) {
        return {
          'status': NTUSTLoginStatus.fail,
          'message': 'WebView發生錯誤: $e'
        };
      }
      
    } catch (e) {
      // 最外層錯誤處理 - 如果任何地方發生意外錯誤，都嘗試手動登入
      final prefs = await SharedPreferences.getInstance();
      final account = prefs.getString(_studentIdKey) ?? '';
      final password = prefs.getString(_passwordKey) ?? '';
      
      if (account.isNotEmpty && password.isNotEmpty) {
        try {
          final result = await Navigator.push<Map<String, dynamic>>(
            context,
            MaterialPageRoute(
              builder: (_) => WebViewScreen(
                initialUrl: NTUSTConnector.ntustLoginUrl,
                title: '台科大登入',
                username: account,
                password: password,
                onLoginResult: (bool success) {
                  try {
                    if (success) {
                      Navigator.of(context).pop({
                        'status': NTUSTLoginStatus.success,
                        'message': 'WebView登入成功'
                      });
                    }
                    // 不要在失敗時立即 pop，讓使用者可以重試
                  } catch (e) {
                    // 避免在登入結果處理時發生錯誤導致崩潰
                    Navigator.of(context).pop({
                      'status': NTUSTLoginStatus.success, // 假設登入成功
                      'message': 'WebView登入完成'
                    });
                  }
                },
              ),
            ),
          );
          
          if (result != null && result is Map<String, dynamic>) {
            return result;
          }
        } catch (e) {
          return {
            'status': NTUSTLoginStatus.fail,
            'message': 'WebView發生錯誤: $e'
          };
        }
      }
      
      return {
        'status': NTUSTLoginStatus.fail,
        'message': '登入過程發生未預期錯誤: $e'
      };
    }
  }
}