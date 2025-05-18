// lib/ui/pages/ntust_connector_test_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
// TODO: 將 'tkt' 替換為您專案的實際名稱
import 'package:tkt/connector/core/dio_connector.dart';
import 'package:tkt/connector/ntust_connector.dart';
import 'package:tkt/debug/log/log.dart'; // 您提供的 Log 類別
import 'package:tkt/models/ntust/ap_tree_json.dart';

// TODO: 匯入您用於顯示目標頁面的 WebView 頁面
// 如果使用我之前提供的 GeneralWebViewPage:
import 'general_webview_page.dart';
// 或者如果您有 manual_login_webview_screen.dart 並且想用它來顯示 (雖然它的設計初衷是手動登入)
import 'manual_login_webview_screen.dart';


class NtustConnectorTestPage extends StatefulWidget {
  const NtustConnectorTestPage({super.key});

  @override
  State<NtustConnectorTestPage> createState() => _NtustConnectorTestPageState();
}

class _NtustConnectorTestPageState extends State<NtustConnectorTestPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String _statusMessage = '';
  String _cookieInfo = '';
  String _sessionInfo = '';

  late Future<void> _initializationFuture;

  // ⭐ 將要目視檢查的目標 URL 移到這裡，方便修改
  static const String _targetVerificationUrl = "https://courseselection.ntust.edu.tw/";
  // 或者，如果您先前在測試頁面中定義的是成績查詢頁面，也可以用那個：
  // static const String _targetVerificationUrl = "https://stuinfosys.ntust.edu.tw/StuScoreQueryServ/StuScoreQuery";


  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      // Log.init(); // 您 Log 類別的 init 方法是空的
      await DioConnector.instance.init();
      Log.d('DioConnector initialized successfully from test page.');
    } catch (e, s) {
      Log.eWithStack('Error during service initialization in test page: $e', s);
      if (mounted) {
        setState(() {
          _statusMessage = '核心服務初始化失敗: ${e.toString()}';
        });
      }
      rethrow;
    }
  }

  // ⭐ 修改後的 _handleLoginSuccess 方法
  // ⭐ 修改後的 _handleLoginSuccess 方法
  Future<void> _handleLoginSuccess(String loginTypeMessage) async {
    if (!mounted) return;
    setState(() {
      // 1. 更新狀態訊息，提示將要開啟 WebView 進行檢查
      _statusMessage = '$loginTypeMessage 成功！Cookies 已設定。\n將開啟目標頁面 (${Uri.parse(_targetVerificationUrl).host}) 進行目視檢查...';
      _isLoading = true; // 短暫顯示 loading
    });
    Log.d(_statusMessage); // 假設您已修復 Log.d 的問題

    await Future.delayed(const Duration(milliseconds: 1500)); // 讓使用者看到訊息

    if (mounted) {
      setState(() {
        _isLoading = false; // 在導航前解除 loading
      });
      // 2. 導航到一個 WebView 頁面 (這裡使用 ManualLoginWebViewScreen 作為範例，
      //    但您也可以替換為更通用的 GeneralWebViewPage，如果您已建立它的話)
      Navigator.of(context).push(
        MaterialPageRoute(
          // 您可以選擇使用 ManualLoginWebViewScreen 或 GeneralWebViewPage
          builder: (context) => GeneralWebViewPage( // ⭐ 或者 GeneralWebViewPage
            initialUrl: _targetVerificationUrl, // 載入您指定的驗證 URL
            // 如果是 GeneralWebViewPage，還可以傳入 title 參數，例如：
            // title: "Session 檢查 (${Uri.parse(_targetVerificationUrl).host})",
          ),
        ),
      ).then((_) {
        // 從 WebView 返回後的操作 (可選)
        if (mounted) {
          setState(() {
            // 3. 從 WebView 返回後，更新狀態訊息讓使用者自行判斷
            _statusMessage = "$loginTypeMessage 流程結束。\n請根據您在 WebView 中看到的頁面內容，自行判斷 Session 是否有效。";
          });
        }
      });
    }
  }

  Future<void> _performAutomatedLoginAndVerify() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      if (mounted) setState(() => _statusMessage = '請輸入學號和密碼');
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _statusMessage = '嘗試自動登入 (使用 HeadlessInAppWebView)...';
      });
    }

    try {
      final Map<String, dynamic> loginResult = await NTUSTConnector.login(
        _usernameController.text,
        _passwordController.text,
      );

      final loginStatus = loginResult['status'];
      final loginMessage = loginResult['message'] as String?;

      if (loginStatus == NTUSTLoginStatus.success) {
        // ⭐ 登入成功後，直接呼叫修改後的 _handleLoginSuccess
        await _handleLoginSuccess("自動登入");
      } else if (loginStatus == NTUSTLoginStatus.fail) {
        if (mounted) {
          setState(() {
            _statusMessage = '自動登入失敗：${loginMessage ?? "未知錯誤"}';
            Log.d(_statusMessage);
            if (loginMessage != null &&
                (loginMessage.toLowerCase().contains('captcha') ||
                 loginMessage.toLowerCase().contains('驗證碼') ||
                 loginMessage.contains('validation-summary-errors'))) {
              _statusMessage += '\n偵測到可能的驗證碼問題，建議嘗試手動登入。';
            }
          });
        }
      } else {
        // ... （處理未知登入狀態）
        if (mounted) {
          setState(() {
            _statusMessage = '登入狀態未知或返回結果格式不符。';
            Log.d('自動登入狀態未知: $loginStatus, message: $loginMessage');
          });
        }
      }
    } catch (e, s) {
      Log.eWithStack('自動登入過程中發生例外: ${e.toString()}', s);
      if (mounted) {
        setState(() {
          _statusMessage = '自動登入過程中發生例外：\n${e.toString()}';
        });
      }
    } finally {
      // ⭐ 注意：isLoading 的解除現在主要由 _handleLoginSuccess 或其他流程的 finally 控制
      // 但如果 _handleLoginSuccess 沒有被呼叫（例如登入直接失敗），這裡還是需要解除
      if (mounted && _isLoading) { // 只有在 _isLoading 仍為 true 時才解除
          if (!(_statusMessage.contains("將開啟目標頁面") && _statusMessage.contains("成功！Cookies 已設定"))) {
             // 如果不是即將跳轉的狀態，則解除 loading
            setState(() {
              _isLoading = false;
            });
          }
      }
    }
  }

  Future<void> _navigateToManualLoginAndVerify() async {
    if (!mounted) return;
    setState(() {
      _statusMessage = '轉至手動登入頁面...';
      _isLoading = true;
    });

    // 導航到 ManualLoginWebViewScreen 並等待結果
    final result = await Navigator.of(context).push<NTUSTLoginStatus>(
      MaterialPageRoute(
        builder: (context) => ManualLoginWebViewScreen( // 假設這個頁面您還保留
          initialUrl: NTUSTConnector.ntustLoginUrl,
        ),
      ),
    );

    if (!mounted) return;

    if (result == NTUSTLoginStatus.success) {
      // ⭐ 手動登入成功後，也呼叫修改後的 _handleLoginSuccess
      await _handleLoginSuccess("手動登入");
    } else {
      setState(() {
        _isLoading = false; // 確保解除 loading
        _statusMessage = '手動登入未完成或失敗。';
        Log.d('手動登入失敗或取消');
      });
    }
  }

  Future<void> _updateCookieInfo() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final cookieManager = CookieManager.instance();
      final cookies = await cookieManager.getCookies(url: WebUri(_targetVerificationUrl));
      
      final StringBuffer cookieText = StringBuffer();
      cookieText.writeln('目前的 Cookies:');
      for (var cookie in cookies) {
        cookieText.writeln('- ${cookie.name}: ${cookie.value}');
        cookieText.writeln('  Domain: ${cookie.domain}');
        cookieText.writeln('  Expires: ${cookie.expiresDate ?? "Session"}');
        cookieText.writeln('');
      }

      if (mounted) {
        setState(() {
          _cookieInfo = cookieText.toString();
          _statusMessage = '已更新 Cookie 資訊';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cookieInfo = '獲取 Cookie 時發生錯誤：$e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateSessionInfo() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final subSystems = await NTUSTConnector.getSubSystem();
      
      final StringBuffer sessionText = StringBuffer();
      sessionText.writeln('子系統資訊:');
      for (var system in subSystems) {
        sessionText.writeln('- ${system.serviceId}');
        if (system.apList != null) {
          for (var ap in system.apList!) {
            sessionText.writeln('  └─ ${ap.name} (${ap.url})');
          }
        }
        sessionText.writeln('');
      }

      if (mounted) {
        setState(() {
          _sessionInfo = sessionText.toString();
          _statusMessage = '已更新子系統資訊';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _sessionInfo = '獲取子系統資訊時發生錯誤：$e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget _buildTestUI(BuildContext context) {
    // ... (UI TextField 和按鈕部分與您提供的版本相同，這裡不再重複)
    // 按鈕的 onPressed 應分別指向 _performAutomatedLoginAndVerify 和 _navigateToManualLoginAndVerify
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: '學號',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: '密碼',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              ElevatedButton(
                onPressed: _performAutomatedLoginAndVerify,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('測試自動登入並檢查 Session'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _navigateToManualLoginAndVerify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('開啟手動登入並檢查 Session'),
              ),
            ],
            const SizedBox(height: 24),
            
            // Cookie 和 Session 資訊區域
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('系統資訊', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: () async {
                              await _updateCookieInfo();
                              await _updateSessionInfo();
                            },
                            tooltip: '更新資訊',
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(),
                  if (_cookieInfo.isNotEmpty) ...[
                    const Text('Cookie 資訊:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SelectableText(_cookieInfo, style: const TextStyle(fontFamily: 'monospace')),
                    const Divider(),
                  ],
                  if (_sessionInfo.isNotEmpty) ...[
                    const Text('Session 資訊:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SelectableText(_sessionInfo, style: const TextStyle(fontFamily: 'monospace')),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),
            if (_statusMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    color: _statusMessage.contains('錯誤') || _statusMessage.contains('失敗')
                        ? Colors.red
                        : Colors.green,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ... (Scaffold 和 FutureBuilder 與您提供的版本相同)
    return Scaffold(
      appBar: AppBar(
        title: const Text('NTUST Session 目視檢查'),
      ),
      body: FutureBuilder<void>(
        future: _initializationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [CircularProgressIndicator(), SizedBox(height: 10), Text("初始化核心服務...")]));
          } else if (snapshot.hasError) {
            return Center(
                child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('服務初始化失敗：\n${snapshot.error.toString()}',
                        style: TextStyle(color: Theme.of(context).colorScheme.error))));
          } else {
            return _buildTestUI(context);
          }
        },
      ),
    );
  }
}