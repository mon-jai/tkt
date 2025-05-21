// lib/ui/pages/manual_login_webview_screen.dart
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';
// TODO: 修改 'tkt' 為您的專案名稱
import 'package:tkt/connector/core/dio_connector.dart';
import 'package:tkt/connector/ntust_connector.dart'; // 主要為了 ntustLoginUrl 和 NTUSTLoginStatus

class ManualLoginWebViewScreen extends StatefulWidget {
  final String initialUrl;

  const ManualLoginWebViewScreen({super.key, required this.initialUrl});

  @override
  State<ManualLoginWebViewScreen> createState() => _ManualLoginWebViewScreenState();
}

class _ManualLoginWebViewScreenState extends State<ManualLoginWebViewScreen> {
  InAppWebViewController? _webViewController;
  final CookieManager _cookieManager = CookieManager.instance();
  bool _isLoading = true;
  String _pageTitle = "手動登入";
  bool _cookiesExtractedAndSaved = false;
  static const String _studentIdKey = 'stored_student_id';
  static const String _passwordKey = 'stored_password';

  Future<bool> _waitForElement(String selector, {int maxAttempts = 10}) async {
    for (int i = 0; i < maxAttempts; i++) {
      final exists = await _webViewController?.evaluateJavascript(
        source: '''
          (function() {
            var element = document.querySelector('${selector}');
            console.log('檢查元素 ${selector}: ' + (element ? '存在' : '不存在'));
            return element != null;
          })()
        '''
      );
      
      if (exists == true) {
        debugPrint('找到元素: $selector');
        return true;
      }
      
      debugPrint('等待元素: $selector, 嘗試次數: ${i + 1}');
      await Future.delayed(const Duration(milliseconds: 500));
    }
    debugPrint('找不到元素: $selector, 已達最大嘗試次數');
    return false;
  }

  Future<void> _autoFillCredentials() async {
    if (_webViewController == null) return;

    try {
      debugPrint('開始自動填入流程');
      final prefs = await SharedPreferences.getInstance();
      final storedStudentId = prefs.getString(_studentIdKey);
      final storedPassword = prefs.getString(_passwordKey);

      if (storedStudentId != null && storedPassword != null) {
        debugPrint('找到儲存的帳號密碼');
        
        // 等待頁面完全載入
        await Future.delayed(const Duration(milliseconds: 500));
        
        // 檢查頁面標題，確保我們在正確的頁面
        final pageTitle = await _webViewController?.getTitle();
        debugPrint('當前頁面標題: $pageTitle');
        
        // 等待登入表單出現
        final elementExists = await _waitForElement('form.login-form-container');
        
        if (elementExists) {
          debugPrint('找到登入表單，開始填入資料');
          final result = await _webViewController?.evaluateJavascript(
            source: '''
              (function() {
                try {
                  console.log('開始執行自動填入 JavaScript');
                  
                  var userIdInput = document.querySelector('input[name="UserName"]');
                  var passwordInput = document.querySelector('input[name="Password"]');
                  var loginForm = document.querySelector('form.login-form-container');
                  
                  if (userIdInput && passwordInput) {
                    console.log('開始填入帳號密碼');
                    
                    userIdInput.value = "$storedStudentId";
                    passwordInput.value = "$storedPassword";
                    
                    userIdInput.dispatchEvent(new Event('input', { bubbles: true }));
                    passwordInput.dispatchEvent(new Event('input', { bubbles: true }));
                    
                    console.log('帳號密碼已填入');
                    
                    if (typeof grecaptcha !== 'undefined' && grecaptcha) {
                      console.log('發現 reCAPTCHA，執行驗證');
                      grecaptcha.execute();
                    } else {
                      console.log('沒有發現 reCAPTCHA，嘗試直接提交表單');
                      if (loginForm) {
                        loginForm.submit();
                      }
                    }
                    return true;
                  }
                  console.log('無法找到必要的表單元素');
                  return false;
                } catch (e) {
                  console.error('自動填入過程發生錯誤:', e);
                  return false;
                }
              })()
            '''
          );
          debugPrint('JavaScript 執行結果: $result');
        } else {
          debugPrint('等待登入表單元素超時');
        }
      } else {
        debugPrint('沒有找到儲存的帳號密碼');
      }
    } catch (e) {
      debugPrint('自動填入失敗: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              debugPrint('手動重新執行自動填入');
              await _autoFillCredentials();
            },
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(NTUSTLoginStatus.success);
            },
            child: const Text('完成', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.initialUrl)),
            initialSettings: InAppWebViewSettings(
              useShouldOverrideUrlLoading: true,
              mediaPlaybackRequiresUserGesture: false,
              javaScriptEnabled: true,
              useHybridComposition: true,
              allowsInlineMediaPlayback: true,
            ),
            onWebViewCreated: (controller) {
              _webViewController = controller;
            },
            onLoadStart: (controller, url) {
              if (mounted) setState(() => _isLoading = true);
            },
            onLoadStop: (controller, url) async {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _pageTitle = url?.toString() ?? "手動登入";
                });
                await _autoFillCredentials();
              }
            },
            onProgressChanged: (controller, progress) {
              if (progress == 100 && mounted) {
                setState(() => _isLoading = false);
              } else if (mounted && progress < 100 && !_isLoading) {
                setState(() => _isLoading = true);
              }
            },
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              return NavigationActionPolicy.ALLOW;
            },
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Future<void> _extractAndSaveCookiesAndPop(NTUSTLoginStatus status) async {
    if (_cookiesExtractedAndSaved) return; // 防止重複執行

    if (status == NTUSTLoginStatus.success && _webViewController != null) {
      try {
        // 嘗試從當前 WebView 的 URL (或特定目標 URL) 提取 Cookies
        final WebUri currentWebUri = WebUri.uri(await _webViewController!.getUrl() ?? WebUri(NTUSTConnector.ntustLoginUrl));
        final List<Cookie> cookies = await _cookieManager.getCookies(url: currentWebUri);
        final cookieJar = DioConnector.instance.cookiesManager; // 您的 DioConnector 的 CookieJar

        if (cookieJar != null) {
          List<io.Cookie> ioCookies = [];
          bool addedRelevantCookie = false;
          for (var c in cookies) {
            // logPrint("WebView Cookie: ${c.name}=${c.value}; domain=${c.domain}; path=${c.path}");
            // 您需要根據實際登入成功後臺科大設定的關鍵 Cookie 名稱來篩選
            if ([".ASPXAUTH", "ntustjwtsecret", "ntustsecret", "ASP.NET_SessionId"] // 加入更多可能的 session cookie
                .contains(c.name)) {
              io.Cookie k = io.Cookie(c.name, c.value as String); // 假設 value 是 String
              k.domain = c.domain ?? ".ntust.edu.tw"; // 使用 WebView cookie 的 domain 或預設
              k.path = c.path ?? "/";
              ioCookies.add(k);
              addedRelevantCookie = true;
            }
          }

          if (addedRelevantCookie) {
            await cookieJar.deleteAll(); // 先清除舊的，避免衝突
            await cookieJar.saveFromResponse(currentWebUri, ioCookies); // 保存新的
            // logPrint("Cookies extracted and saved to DioConnector's CookieJar.");
            _cookiesExtractedAndSaved = true; // 標記已處理
            if (mounted) Navigator.of(context).pop(NTUSTLoginStatus.success);
            return;
          } else {
            // logPrint("No relevant cookies found in WebView to save.");
          }
        } else {
          // logPrint("DioConnector's CookieJar is null.");
        }
      } catch (e) {
        // logException(e, null, reason: "Error extracting/saving cookies from WebView");
      }
    }
    // 如果沒有成功提取並保存，或者狀態不是 success，則返回失敗
    if (mounted) Navigator.of(context).pop(NTUSTLoginStatus.fail);
  }
}