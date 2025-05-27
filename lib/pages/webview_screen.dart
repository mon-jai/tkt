// lib/ui/pages/manual_login_webview_screen.dart
import 'dart:io' as io;
import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';
// TODO: 修改 'tkt' 為您的專案名稱
import 'package:tkt/connector/core/dio_connector.dart';
import 'package:tkt/connector/ntust_connector.dart';
import 'package:tkt/debug/log/log.dart'; // 主要為了 ntustLoginUrl 和 NTUSTLoginStatus
import 'package:html/parser.dart';

class WebViewScreen extends StatefulWidget {
  final String initialUrl;
  final String title;
  final Function(bool)? onLoginResult;
  final String? username; // 新增：可選的用戶名
  final String? password; // 新增：可選的密碼

  const WebViewScreen({
    required this.initialUrl,
    required this.title,
    this.onLoginResult,
    this.username, // 新增
    this.password, // 新增
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  // Cookie 管理器實例
  final cookieManager = CookieManager.instance();
  late final cookieJar = DioConnector.instance.cookiesManager;

  // WebView 控制器和狀態變數
  InAppWebViewController? webView;
  Uri url = Uri();
  double progress = 0;
  int onLoadStopTime = -1;
  Uri? lastLoadUri;
  bool firstLoad = true;
  bool _cookiesExtractedAndSaved = false;
  bool _showLoadingDialog = false;

  @override
  void initState() {
    super.initState();
    BackButtonInterceptor.add(myInterceptor);
    _initializeCookieJar();
  }

  @override
  void dispose() {
    BackButtonInterceptor.remove(myInterceptor);
    super.dispose();
  }

  Future<void> _initializeCookieJar() async {
    try {
      // 確保 DioConnector 已經初始化
      await DioConnector.instance.init();
      Log.d('Cookie jar 初始化完成');
    } catch (e) {
      Log.e('Cookie jar 初始化失敗: $e');
    }
  }

  // 處理返回按鈕事件
  bool myInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    if (onLoadStopTime >= 1) {
      webView?.goBack();
      onLoadStopTime -= 2;
      return true;
    }
    return false;
  }

  // 新增：從 SharedPreferences 載入儲存的帳號密碼
  Future<void> _loadStoredCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedUsername = prefs.getString('stored_student_id');
      final storedPassword = prefs.getString('stored_password');

      if (storedUsername != null && storedPassword != null) {
        Log.d('已從本地儲存讀取帳號密碼');
        await _autoFillWithCredentials(storedUsername, storedPassword);
      }
    } catch (e) {
      Log.e('載入儲存的帳號密碼時發生錯誤：$e');
    }
  }

  /// 檢查是否有 reCAPTCHA
  Future<bool> _hasReCaptcha() async {
    try {
      String? html = await webView?.getHtml();
      if (html == null) return false;

      return html.contains('g-recaptcha') ||
          html.contains('grecaptcha') ||
          html.contains('google.com/recaptcha');
    } catch (e) {
      Log.e('檢查 reCAPTCHA 時發生錯誤：$e');
      return false;
    }
  }

  /// 點擊登入按鈕
  Future<void> _clickLoginButton(String loginType) async {
    try {
      if (loginType == 'sso') {
        await webView?.evaluateJavascript(
            source: 'document.getElementById("btnLogIn").click();');
      } else {
        await webView?.evaluateJavascript(
            source: 'document.getElementById("loginButton2").click();');
      }
      Log.d('點擊登入按鈕');
    } catch (e) {
      Log.e('點擊登入按鈕時發生錯誤：$e');
    }
  }

  /// 自動填入帳號密碼並點擊登入
  Future<void> _autoFillWithCredentials(
      String username, String password) async {
    try {
      Log.d('開始自動填入帳號密碼');

      // 檢查頁面類型並使用對應的元素選擇器
      String? html = await webView?.getHtml();
      if (html == null) return;

      String loginType = '';
      if (html.contains('name="UserName"')) {
        // SSO 登入頁面
        await webView?.evaluateJavascript(
            source:
                'document.getElementsByName("UserName")[0].value = "$username";');
        await webView?.evaluateJavascript(
            source:
                'document.getElementsByName("Password")[0].value = "$password";');
        loginType = 'sso';
        Log.d('SSO 登入頁面');
      } else {
        // 資訊系統登入頁面
        await webView?.evaluateJavascript(
            source:
                'document.getElementsByName("Ecom_User_ID")[0].value = "$username";');
        await webView?.evaluateJavascript(
            source:
                'document.getElementsByName("Ecom_Password")[0].value = "$password";');
        loginType = 'info';
        Log.d('資訊系統登入頁面');
      }

      Log.d('自動填入完成，準備點擊登入按鈕');

      setState(() {
        _showLoadingDialog = true;
      });

      // 點擊登入按鈕
      await _clickLoginButton(loginType);

      // 等待頁面載入（等待可能的 reCAPTCHA）
      await Future.delayed(const Duration(seconds: 2));

      // 檢查是否出現 reCAPTCHA
      bool hasRecaptcha = await _hasReCaptcha();
      if (hasRecaptcha) {
        Log.d('檢測到 reCAPTCHA，等待使用者驗證');
        if (mounted) {
          setState(() {
            _showLoadingDialog = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('請完成圖片驗證，驗證完成後會自動繼續登入'),
              duration: Duration(seconds: 5),
            ),
          );
        }

        // 設定一個定時器，每隔一段時間檢查 reCAPTCHA 是否已完成
        bool captchaCompleted = false;
        while (!captchaCompleted) {
          await Future.delayed(const Duration(seconds: 2));
          captchaCompleted = !await _hasReCaptcha();
          if (captchaCompleted) {
            Log.d('reCAPTCHA 驗證完成，重新點擊登入');
            setState(() {
              _showLoadingDialog = true;
            });
            await _clickLoginButton(loginType);
            break;
          }
        }
      }
    } catch (e) {
      Log.e('自動填入過程發生錯誤：$e');
      if (mounted) {
        setState(() {
          _showLoadingDialog = false;
        });
      }
    }
  }

  /// 自動填入帳號密碼並點擊登入
  Future<void> _autoFillCredentials() async {
    if (widget.username == null || widget.password == null) {
      // 如果沒有傳入帳號密碼，嘗試從儲存中讀取
      final prefs = await SharedPreferences.getInstance();
      final storedUsername = prefs.getString('stored_student_id');
      final storedPassword = prefs.getString('stored_password');

      if (storedUsername != null && storedPassword != null) {
        await _autoFillWithCredentials(storedUsername, storedPassword);
      }
      return;
    }

    await _autoFillWithCredentials(widget.username!, widget.password!);
  }

  /// 檢查登入結果
  Future<void> _checkLoginResult() async {
    try {
      String? result = await webView?.getHtml();
      if (result == null) return;

      // 檢查是否有錯誤訊息
      if (result.contains('validation-summary-errors') ||
          result.contains('error-message') ||
          result.contains('alert-danger')) {
        // 登入失敗
        Log.d('登入失敗');
        widget.onLoginResult?.call(false);
        return;
      }

      // 檢查並保存 cookies
      await extractAndSaveCookies();
    } catch (e) {
      Log.e('檢查登入結果時發生錯誤：$e');
      widget.onLoginResult?.call(false);
    }
  }

  /// 將 WebView Cookie 轉換為 io.Cookie
  io.Cookie _convertToIOCookie(Cookie webViewCookie) {
    Log.d('轉換 Cookie: ${webViewCookie.name}');

    var ioCookie = io.Cookie(webViewCookie.name, webViewCookie.value)
      ..domain = '.ntust.edu.tw'
      ..path = '/';

    return ioCookie;
  }

  /// 初始化並同步 Cookies
  Future<bool> initializeCookies() async {
    Log.d('開始初始化 Cookies...');

    if (!firstLoad) {
      Log.d('非首次載入，跳過 Cookie 初始化');
      return true;
    }

    firstLoad = false;
    try {
      // 等待 cookieJar 初始化完成
      if (cookieJar == null) {
        Log.d('等待 Cookie jar 初始化...');
        await _initializeCookieJar();
      }

      // 獲取 WebView 當前的 cookies（用於檢查）
      var existCookies =
          await cookieManager.getCookies(url: WebUri(widget.initialUrl));
      final cookiesName = existCookies.map((e) => e.name).toList();
      Log.d('WebView 現有的 Cookie 名稱: $cookiesName');

      Log.d('Cookie 初始化完成');
      return true;
    } catch (e) {
      Log.e('Cookie 初始化失敗: $e');
      return false;
    }
  }

  /// 從 WebView 提取 Cookies 並保存到 DioConnector
  Future<void> extractAndSaveCookies() async {
    if (_cookiesExtractedAndSaved || webView == null || cookieJar == null)
      return;

    try {
      Log.d('開始從 WebView 提取 Cookies...');

      final currentUrl = await webView!.getUrl();
      if (currentUrl == null) {
        Log.d('無法獲取當前 URL，停止提取 Cookies');
        return;
      }

      final cookies = await cookieManager.getCookies(url: currentUrl);
      Log.d('從 WebView 獲取到 ${cookies.length} 個 Cookies');

      List<io.Cookie> ioCookies = [];
      for (var cookie in cookies) {
        var ioCookie = _convertToIOCookie(cookie);
        ioCookies.add(ioCookie);
        Log.d('已轉換並添加 Cookie: ${cookie.name}');
      }

      if (ioCookies.isNotEmpty) {
        Log.d('準備保存 ${ioCookies.length} 個 Cookies 到 DioConnector');

        // 清除舊的 cookies
        await cookieJar.deleteAll();
        Log.d('已清除 DioConnector 中的舊 Cookies');

        // 保存新的 cookies
        await cookieJar.saveFromResponse(currentUrl, ioCookies);
        Log.d('已保存新的 Cookies 到 DioConnector');

        _cookiesExtractedAndSaved = true;
        if (mounted) {
          setState(() {
            _showLoadingDialog = false;
          });
        }
        widget.onLoginResult?.call(true);
      } else {
        Log.d('沒有找到需要保存的 Cookies');
        if (mounted) {
          setState(() {
            _showLoadingDialog = false;
          });
        }
        widget.onLoginResult?.call(false);
      }
    } catch (e) {
      Log.e('提取和保存 Cookies 時發生錯誤: $e');
      if (mounted) {
        setState(() {
          _showLoadingDialog = false;
        });
      }
      widget.onLoginResult?.call(false);
    }
  }

  /// 檢查是否為登入頁面
  Future<bool> _checkIsLoginPage() async {
    try {
      String? html = await webView?.getHtml();
      if (html == null) return false;

      // 檢查是否包含登入表單的特徵
      return html.contains('name="UserName"') || // SSO 登入
          html.contains('name="Ecom_User_ID"') || // 資訊系統登入
          html.contains('name="Ecom_Password"') ||
          html.contains('id="btnLogIn"') ||
          html.contains('id="loginButton2"');
    } catch (e) {
      Log.e('檢查登入頁面時發生錯誤：$e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: actionList,
      ),
      body: FutureBuilder<bool>(
        future: initializeCookies(),
        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
          if (snapshot.hasData) {
            return SafeArea(
              child: Stack(
                children: [
                  Column(
                    children: <Widget>[
                      if (progress < 1.0)
                        LinearProgressIndicator(value: progress),
                      Expanded(
                        child: InAppWebView(
                          initialUrlRequest:
                              URLRequest(url: WebUri(widget.initialUrl)),
                          initialSettings: InAppWebViewSettings(
                            useHybridComposition: true,
                            useOnDownloadStart: true,
                          ),
                          onWebViewCreated:
                              (InAppWebViewController controller) {
                            webView = controller;
                          },
                          onLoadStart:
                              (InAppWebViewController controller, Uri? url) {
                            setState(() {
                              if (lastLoadUri != url) {
                                onLoadStopTime++;
                              }
                              lastLoadUri = url;
                              this.url = url!;
                            });
                          },
                          onLoadStop: (InAppWebViewController controller,
                              Uri? url) async {
                            if (url != null) {
                              setState(() {
                                this.url = url;
                              });

                              // 檢查是否為登入頁面
                              bool isLoginPage = await _checkIsLoginPage();
                              if (isLoginPage) {
                                await _loadStoredCredentials();
                              }

                              // 檢查登入結果
                              await _checkLoginResult();
                            }
                          },
                          onProgressChanged: (InAppWebViewController controller,
                              int progress) {
                            setState(() {
                              this.progress = progress / 100;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  if (_showLoadingDialog)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                ],
              ),
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }

  List<Widget> get actionList {
    return [
      IconButton(
        icon: const Icon(CupertinoIcons.left_chevron, size: 18),
        splashRadius: 16,
        onPressed: () async {
          if (webView != null) {
            await webView?.goBack();
          }
        },
      ),
      IconButton(
        icon: const Icon(CupertinoIcons.right_chevron, size: 18),
        splashRadius: 16,
        onPressed: () async {
          if (webView != null) {
            await webView?.goForward();
          }
        },
      ),
      IconButton(
        icon: const Icon(CupertinoIcons.refresh, size: 18),
        splashRadius: 16,
        onPressed: () async {
          if (webView != null) {
            await webView?.reload();
          }
        },
      ),
    ];
  }
}
