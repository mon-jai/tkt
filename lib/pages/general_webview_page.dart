// lib/ui/pages/general_webview_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
// TODO: 替換 'tkt' 為您的專案名
import 'package:tkt/debug/log/log.dart'; // 使用您自己的 Log

class GeneralWebViewPage extends StatefulWidget {
  final String initialUrl;

  const GeneralWebViewPage({
    super.key,
    required this.initialUrl,
  });

  @override
  State<GeneralWebViewPage> createState() => _GeneralWebViewPageState();
}

class _GeneralWebViewPageState extends State<GeneralWebViewPage> {
  InAppWebViewController? _webViewController;
  String _pageTitle = '';
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _pageTitle = widget.initialUrl;
  }

  @override
  void dispose() {
    _webViewController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitle, style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _webViewController?.reload();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_progress < 1.0)
            LinearProgressIndicator(value: _progress, color: Theme.of(context).colorScheme.secondary),
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(widget.initialUrl)),
              initialSettings: InAppWebViewSettings(
                useShouldOverrideUrlLoading: true,
                mediaPlaybackRequiresUserGesture: false,
                javaScriptEnabled: true,
                useHybridComposition: true,
                allowsInlineMediaPlayback: true,
                // 重要的 UserAgent，確保與您登入時使用的 UserAgent 一致或相容
                userAgent: "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Mobile Safari/537.36",
                // 添加 CSP 相關設定
                allowContentAccess: true,
                allowFileAccess: true,
                allowFileAccessFromFileURLs: true,
                allowUniversalAccessFromFileURLs: true,
              ),
              onWebViewCreated: (controller) {
                _webViewController = controller;
              },
              onLoadStart: (controller, url) {
                if (mounted) {
                  setState(() {
                    _pageTitle = url?.toString() ?? widget.initialUrl;
                    _progress = 0;
                  });
                }
                Log.d("GeneralWebViewPage onLoadStart: $url");
              },
              onLoadStop: (controller, url) {
                _updatePageTitle(controller, url);
                Log.d("GeneralWebViewPage onLoadStop: $url");
              },
              onProgressChanged: (controller, progress) {
                if (mounted) {
                  setState(() {
                    _progress = progress / 100;
                  });
                }
              },
              onReceivedHttpError: (controller, request, errorResponse) {
                Log.e("GeneralWebViewPage HTTP Error: Status ${errorResponse.statusCode} for ${request.url}");
              },
              onLoadError: (controller, url, code, message) {
                Log.e("GeneralWebViewPage Load Error: Code $code, Message: $message for $url");
              },
               onConsoleMessage: (controller, consoleMessage) {
                Log.d("GeneralWebViewPage Console: [${consoleMessage.messageLevel}] ${consoleMessage.message}");
              },
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                return NavigationActionPolicy.ALLOW;
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updatePageTitle(InAppWebViewController controller, WebUri? url) async {
    if (!mounted) return;
    
    try {
      final title = await controller.getTitle();
      if (mounted) {
        setState(() {
          _progress = 1.0;
          _pageTitle = title ?? url?.host ?? widget.initialUrl;
        });
      }
    } catch (e) {
      Log.e("Error updating page title: $e");
      if (mounted) {
        setState(() {
          _progress = 1.0;
          _pageTitle = url?.host ?? widget.initialUrl;
        });
      }
    }
  }
}
