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

class ManualLoginWebViewScreen extends StatefulWidget {
  final String initialUrl;
  final String title;
  final Function(bool)? onLoginResult;
  final String? username;  // 新增：可選的用戶名
  final String? password;  // 新增：可選的密碼

  const ManualLoginWebViewScreen({
    required this.initialUrl,
    required this.title,
    this.onLoginResult,
    this.username,  // 新增
    this.password,  // 新增
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _ManualLoginWebViewScreenState();
}

class _ManualLoginWebViewScreenState extends State<ManualLoginWebViewScreen> {
  // Cookie 管理器實例
  final cookieManager = CookieManager.instance();
  final cookieJar = DioConnector.instance.cookiesManager;
  
  // WebView 控制器和狀態變數
  InAppWebViewController? webView;
  Uri url = Uri();
  double progress = 0;
  int onLoadStopTime = -1;
  Uri? lastLoadUri;
  bool firstLoad = true;
  bool _cookiesExtractedAndSaved = false;
  bool _showLoadingDialog = false;  // 新增：是否顯示載入對話框

  @override
  void initState() {
    super.initState();
    BackButtonInterceptor.add(myInterceptor);
  }

  @override
  void dispose() {
    BackButtonInterceptor.remove(myInterceptor);
    super.dispose();
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

  /// 自動填入帳號密碼並點擊登入
  Future<void> _autoFillCredentials() async {
    if (widget.username == null || widget.password == null) return;
    
    try {
      Log.d('開始自動填入帳號密碼');
      await webView?.evaluateJavascript(
        source: 'document.getElementsByName("UserName")[0].value = "${widget.username}";'
      );
      await webView?.evaluateJavascript(
        source: 'document.getElementsByName("Password")[0].value = "${widget.password}";'
      );
      await webView?.evaluateJavascript(
        source: 'document.getElementById("btnLogIn").click();'
      );
      Log.d('自動填入完成並點擊登入按鈕');
      
      setState(() {
        _showLoadingDialog = true;
      });
      
      // 5秒後自動隱藏載入對話框
      await Future.delayed(const Duration(seconds: 5));
      if (mounted) {
        setState(() {
          _showLoadingDialog = false;
        });
      }
    } catch (e) {
      Log.e('自動填入過程發生錯誤：$e');
    }
  }

  /// 檢查登入結果
  Future<void> _checkLoginResult() async {
    try {
      String? result = await webView?.getHtml();
      if (result == null) return;
      
      var tagNode = parse(result);
      var nodes = tagNode.getElementsByClassName("validation-summary-errors");
      
      if (nodes.length == 1) {
        // 登入失敗
        Log.d('登入失敗：${nodes[0].text.replaceAll("\\n", "")}');
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
  /// 並設置必要的屬性
  io.Cookie _convertToIOCookie(Cookie webViewCookie) {
    Log.d('轉換 Cookie: ${webViewCookie.name}');
    
    // 創建新的 io.Cookie
    var ioCookie = io.Cookie(webViewCookie.name, webViewCookie.value)
      ..domain = webViewCookie.domain ?? '.ntust.edu.tw'
      ..path = webViewCookie.path ?? '/'
      ..secure = webViewCookie.isSecure ?? true
      ..httpOnly = webViewCookie.isHttpOnly ?? true;

    // 設置過期時間
    if (webViewCookie.expiresDate != null) {
      ioCookie.expires = DateTime.fromMillisecondsSinceEpoch(webViewCookie.expiresDate!);
    }

    Log.d('Cookie 轉換完成: ${ioCookie.name} = ${ioCookie.value}');
    Log.d('  Domain: ${ioCookie.domain}');
    Log.d('  Path: ${ioCookie.path}');
    Log.d('  Secure: ${ioCookie.secure}');
    Log.d('  HttpOnly: ${ioCookie.httpOnly}');
    Log.d('  Expires: ${ioCookie.expires}');

    return ioCookie;
  }

  /// 初始化並同步 Cookies
  /// 在 WebView 首次載入時執行
  Future<bool> initializeCookies() async {
    Log.d('開始初始化 Cookies...');
    
    if (!firstLoad) {
      Log.d('非首次載入，跳過 Cookie 初始化');
      return true;
    }
    
    firstLoad = false;
    try {
      // 從 DioConnector 讀取已存在的 cookies
      final cookies = await cookieJar?.loadForRequest(Uri.parse(widget.initialUrl)) ?? [];
      Log.d('從 DioConnector 讀取到 ${cookies.length} 個 Cookies');

      // 清除 WebView 現有的 cookies
      await cookieManager.deleteAllCookies();
      Log.d('已清除 WebView 現有的 Cookies');

      // 獲取 WebView 當前的 cookies（用於檢查）
      var existCookies = await cookieManager.getCookies(url: WebUri(widget.initialUrl));
      final cookiesName = existCookies.map((e) => e.name).toList();
      Log.d('WebView 現有的 Cookie 名稱: $cookiesName');

      // 將 DioConnector 的 cookies 注入到 WebView
      for (var cookie in cookies) {
        if (!cookiesName.contains(cookie.name)) {
          Log.d('注入 Cookie: ${cookie.name}');
          cookiesName.add(cookie.name);
          await cookieManager.setCookie(
            url: WebUri(widget.initialUrl),
            name: cookie.name,
            value: cookie.value,
            domain: cookie.domain,
            path: cookie.path ?? "/",
            maxAge: cookie.maxAge,
            isSecure: cookie.secure,
            isHttpOnly: cookie.httpOnly,
          );
        }
      }
      
      Log.d('Cookie 初始化完成');
      return true;
    } catch (e) {
      Log.e('Cookie 初始化失敗: $e');
      return false;
    }
  }

  /// 從 WebView 提取 Cookies 並保存到 DioConnector
  Future<void> extractAndSaveCookies() async {
    if (_cookiesExtractedAndSaved || webView == null || cookieJar == null) return;

    try {
      Log.d('開始從 WebView 提取 Cookies...');
      
      // 獲取當前頁面的所有 cookies
      final currentUrl = await webView!.getUrl();
      if (currentUrl == null) {
        Log.d('無法獲取當前 URL，停止提取 Cookies');
        return;
      }

      final cookies = await cookieManager.getCookies(url: currentUrl);
      Log.d('從 WebView 獲取到 ${cookies.length} 個 Cookies');

      // 轉換並過濾需要的 cookies
      List<io.Cookie> ioCookies = [];
      for (var cookie in cookies) {
        // 只保存特定的 cookies
        if ([".ASPXAUTH", "ntustjwtsecret", "ntustsecret"].contains(cookie.name)) {
          var ioCookie = _convertToIOCookie(cookie);
          ioCookies.add(ioCookie);
          Log.d('已轉換並添加 Cookie: ${cookie.name}');
        }
      }

      if (ioCookies.isNotEmpty) {
        Log.d('準備保存 ${ioCookies.length} 個 Cookies 到 DioConnector');
        
        // 清除舊的 cookies
        await cookieJar.deleteAll();
        Log.d('已清除 DioConnector 中的舊 Cookies');

        // 保存新的 cookies
        await cookieJar.saveFromResponse(currentUrl, ioCookies);
        Log.d('已保存新的 Cookies 到 DioConnector');

        // 驗證保存是否成功
        final savedCookies = await cookieJar.loadForRequest(currentUrl);
        Log.d('驗證：從 DioConnector 讀取到 ${savedCookies.length} 個 Cookies');
        for (var cookie in savedCookies) {
          Log.d('- ${cookie.name}: ${cookie.value}');
        }

        _cookiesExtractedAndSaved = true;
        widget.onLoginResult?.call(true);
      } else {
        Log.d('沒有找到需要保存的 Cookies');
        widget.onLoginResult?.call(false);
      }
    } catch (e) {
      Log.e('提取和保存 Cookies 時發生錯誤: $e');
      widget.onLoginResult?.call(false);
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
                          initialUrlRequest: URLRequest(url: WebUri(widget.initialUrl)),
                          initialSettings: InAppWebViewSettings(
                            useHybridComposition: true,
                            useOnDownloadStart: true,
                          ),
                          onWebViewCreated: (InAppWebViewController controller) {
                            webView = controller;
                          },
                          onLoadStart: (InAppWebViewController controller, Uri? url) {
                            setState(() {
                              if (lastLoadUri != url) {
                                onLoadStopTime++;
                              }
                              lastLoadUri = url;
                              this.url = url!;
                            });
                          },
                          onLoadStop: (InAppWebViewController controller, Uri? url) async {
                            if (url != null) {
                              setState(() {
                                this.url = url;
                              });
                              
                              // 如果是登入頁面且有帳號密碼，自動填入
                              if (url.toString() == widget.initialUrl && 
                                  widget.username != null && 
                                  widget.password != null) {
                                await _autoFillCredentials();
                              }
                              
                              // 檢查登入結果
                              await _checkLoginResult();
                            }
                          },
                          onProgressChanged: (InAppWebViewController controller, int progress) {
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
