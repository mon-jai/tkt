import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:html/parser.dart';
// TODO: 修改 'tkt' 為您的專案名稱
import 'package:tkt/connector/core/dio_connector.dart';
import 'package:tkt/connector/ntust_connector.dart';
import 'package:tkt/debug/log/log.dart';

class NTUSTLoginWebView extends StatefulWidget {
  final String? username;
  final String? password;
  final String? initialUrl;
  final String title;
  final Function(bool)? onLoginResult;
  final bool showAppBar;
  final bool showNavigationButtons;

  const NTUSTLoginWebView({
    this.username,
    this.password,
    this.initialUrl,
    this.title = '登入',
    this.onLoginResult,
    this.showAppBar = true,
    this.showNavigationButtons = false,
    super.key,
  });

  @override
  State<NTUSTLoginWebView> createState() => _NTUSTLoginWebViewState();
}

class _NTUSTLoginWebViewState extends State<NTUSTLoginWebView> {
  final cookieManager = CookieManager.instance();
  final cookieJar = DioConnector.instance.cookiesManager;
  
  InAppWebViewController? webView;
  Uri url = Uri();
  double progress = 0;
  bool _isLoginPage = false;
  bool _isLoggingIn = false;
  bool _cookiesExtractedAndSaved = false;
  bool _showLoadingDialog = false;

  late final WebUri _initialUri;

  @override
  void initState() {
    super.initState();
    _initialUri = WebUri(widget.initialUrl ?? NTUSTConnector.ntustLoginUrl);
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
        _isLoggingIn = true;
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

  /// 檢查是否為登入頁面
  Future<bool> _checkIsLoginPage() async {
    try {
      String? html = await webView?.getHtml();
      if (html == null) return false;

      // 檢查是否包含登入表單的特徵
      return html.contains('id="btnLogIn"') || 
             html.contains('name="UserName"') ||
             html.contains('name="Password"');
    } catch (e) {
      Log.e('檢查登入頁面時發生錯誤：$e');
      return false;
    }
  }

  /// 檢查登入結果
  Future<void> _checkLoginResult() async {
    try {
      // 如果不是在登入過程中，不檢查結果
      if (!_isLoggingIn) return;

      String? result = await webView?.getHtml();
      if (result == null) return;
      
      var tagNode = parse(result);
      var nodes = tagNode.getElementsByClassName("validation-summary-errors");
      
      if (nodes.length == 1) {
        // 登入失敗
        Log.d('登入失敗：${nodes[0].text.replaceAll("\\n", "")}');
        widget.onLoginResult?.call(false);
        _isLoggingIn = false;
        return;
      }
      
      // 檢查是否已經離開登入頁面
      bool isCurrentLoginPage = await _checkIsLoginPage();
      if (!isCurrentLoginPage) {
        Log.d('已離開登入頁面，準備提取 Cookies');
        await _extractAndSaveCookies();
        _isLoggingIn = false;
      }
    } catch (e) {
      Log.e('檢查登入結果時發生錯誤：$e');
      widget.onLoginResult?.call(false);
      _isLoggingIn = false;
    }
  }

  /// 將 WebView Cookie 轉換為 io.Cookie
  io.Cookie _convertToIOCookie(Cookie webViewCookie) {
    Log.d('轉換 Cookie: ${webViewCookie.name}');
    
    var ioCookie = io.Cookie(webViewCookie.name, webViewCookie.value)
      ..domain = webViewCookie.domain ?? '.ntust.edu.tw'
      ..path = webViewCookie.path ?? '/'
      ..secure = webViewCookie.isSecure ?? true
      ..httpOnly = webViewCookie.isHttpOnly ?? true;

    if (webViewCookie.expiresDate != null) {
      ioCookie.expires = DateTime.fromMillisecondsSinceEpoch(webViewCookie.expiresDate!);
    }

    return ioCookie;
  }

  /// 從 WebView 提取 Cookies 並保存到 DioConnector
  Future<void> _extractAndSaveCookies() async {
    if (_cookiesExtractedAndSaved || webView == null || cookieJar == null) return;

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
        if ([".ASPXAUTH", "ntustjwtsecret", "ntustsecret"].contains(cookie.name)) {
          var ioCookie = _convertToIOCookie(cookie);
          ioCookies.add(ioCookie);
          Log.d('已轉換並添加 Cookie: ${cookie.name}');
        }
      }

      if (ioCookies.isNotEmpty) {
        Log.d('準備保存 ${ioCookies.length} 個 Cookies 到 DioConnector');
        
        await cookieJar.deleteAll();
        Log.d('已清除 DioConnector 中的舊 Cookies');

        await cookieJar.saveFromResponse(currentUrl, ioCookies);
        Log.d('已保存新的 Cookies 到 DioConnector');

        _cookiesExtractedAndSaved = true;
        widget.onLoginResult?.call(true);
      } else {
        Log.d('沒有找到需要保存的 Cookies');
      }
    } catch (e) {
      Log.e('提取和保存 Cookies 時發生錯誤: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_showLoadingDialog) {
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: widget.showAppBar ? AppBar(
          title: Text(widget.title),
          actions: widget.showNavigationButtons ? _buildNavigationButtons() : null,
          leading: _showLoadingDialog ? null : IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ) : null,
        body: Stack(
          children: [
            Column(
              children: <Widget>[
                if (progress < 1.0)
                  LinearProgressIndicator(value: progress),
                Expanded(
                  child: InAppWebView(
                    initialUrlRequest: URLRequest(url: _initialUri),
                    initialSettings: InAppWebViewSettings(
                      useHybridComposition: true,
                      useOnDownloadStart: true,
                    ),
                    onWebViewCreated: (InAppWebViewController controller) {
                      webView = controller;
                    },
                    onLoadStart: (InAppWebViewController controller, Uri? url) async {
                      Log.d('頁面開始載入: ${url.toString()}');
                      if (url != null) {
                        setState(() {
                          this.url = url;
                        });
                      }
                    },
                    onLoadStop: (InAppWebViewController controller, Uri? url) async {
                      Log.d('頁面載入完成: ${url.toString()}');
                      if (url != null) {
                        setState(() {
                          this.url = url;
                        });

                        // 檢查是否為登入頁面
                        bool isLoginPage = await _checkIsLoginPage();
                        _isLoginPage = isLoginPage;
                        
                        if (isLoginPage && 
                            widget.username != null && 
                            widget.password != null) {
                          await _autoFillCredentials();
                        } else if (_isLoggingIn) {
                          // 只在登入過程中檢查結果
                          await _checkLoginResult();
                        }
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        '登入中，請稍候...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildNavigationButtons() {
    return [
      IconButton(
        icon: const Icon(Icons.arrow_back_ios, size: 18),
        onPressed: () async {
          if (webView != null) {
            await webView?.goBack();
          }
        },
      ),
      IconButton(
        icon: const Icon(Icons.arrow_forward_ios, size: 18),
        onPressed: () async {
          if (webView != null) {
            await webView?.goForward();
          }
        },
      ),
      IconButton(
        icon: const Icon(Icons.refresh, size: 18),
        onPressed: () async {
          if (webView != null) {
            await webView?.reload();
          }
        },
      ),
    ];
  }
} 