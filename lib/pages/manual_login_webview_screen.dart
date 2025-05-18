// lib/ui/pages/manual_login_webview_screen.dart
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
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

  // 標記是否已成功提取並保存 Cookie
  bool _cookiesExtractedAndSaved = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            // 讓使用者在認為登入成功後，手動觸發 Cookie 提取和頁面關閉
            onPressed: _cookiesExtractedAndSaved
                ? null // 如果已經提取過，則禁用
                : () async {
                    await _extractAndSaveCookiesAndPop(NTUSTLoginStatus.success);
                  },
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
              useHybridComposition: true, // 根據需要調整
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
              }
              // 自動檢查是否登入成功 (可選，但較難判斷)
              // 例如，檢查 URL 是否已跳轉到登入後的某個特定頁面
              // String currentUrl = url.toString();
              // if (currentUrl.contains("ntust.edu.tw/student") && !currentUrl.contains("Login")) {
              //   // 假設跳轉到學生主頁表示成功
              //   await _extractAndSaveCookiesAndPop(NTUSTLoginStatus.success);
              // }
            },
            onProgressChanged: (controller, progress) {
              if (progress == 100 && mounted) {
                setState(() => _isLoading = false);
              } else if (mounted && progress < 100 && !_isLoading) {
                setState(() => _isLoading = true);
              }
            },
            onReceivedHttpError: (controller, request, errorResponse) {
              // logPrint("HTTP Error: ${errorResponse.statusCode} for ${request.url}");
            },
            onLoadError: (controller, url, code, message) {
              // logPrint("WebView Error: $code, $message for $url");
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