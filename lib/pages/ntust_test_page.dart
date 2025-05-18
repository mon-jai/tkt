// lib/ui/pages/ntust_connector_test_page.dart
import 'package:flutter/material.dart';
// TODO: 將 'tkt' 替換為您專案的實際名稱
import 'package:tkt/connector/core/dio_connector.dart';
import 'package:tkt/connector/ntust_connector.dart';
import 'package:tkt/debug/log/log.dart'; // 您提供的 Log 類別
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

  late Future<void> _initializationFuture;

  static const String _courseSelectionUrl = "https://stuinfosys.ntust.edu.tw/StuScoreQueryServ/StuScoreQuery";


  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
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

  Future<void> _handleLoginSuccess(String loginTypeMessage) async {
    if (!mounted) return;
    setState(() {
      _statusMessage = '$loginTypeMessage 成功！Cookies 已設定。\n將開啟選課系統頁面進行目視檢查...';
      _isLoading = true; // 可以選擇在跳轉前也顯示 loading
    });
    Log.d(_statusMessage);

    // 短暫延遲讓使用者看到訊息，然後跳轉
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      // 確保 _isLoading 在跳轉前或跳轉後被正確管理
      // 如果 GeneralWebViewPage 是全螢幕推入，當前頁面的 isLoading 可能不再重要
      // 但為了清晰，我們在跳轉前解除
      setState(() {
        _isLoading = false;
      });
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const ManualLoginWebViewScreen(
            initialUrl: _courseSelectionUrl,
          ),
        ),
      ).then((_) {
        // 從 WebView 返回後的操作（可選）
        if (mounted) {
          // setState(() {
          //   _statusMessage = "$loginTypeMessage 流程結束，請自行判斷 Session 是否有效。";
          // });
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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _navigateToManualLoginAndVerify() async {
    if (!mounted) return;
    setState(() {
      _statusMessage = '轉至手動登入頁面...';
      _isLoading = true;
    });

    final result = await Navigator.of(context).push<NTUSTLoginStatus>(
      MaterialPageRoute(
        builder: (context) => ManualLoginWebViewScreen(
          initialUrl: NTUSTConnector.ntustLoginUrl,
        ),
      ),
    );

    if (!mounted) return;

    if (result == NTUSTLoginStatus.success) {
      // 手動登入頁面返回成功，意味著它已嘗試保存 Cookie
      await _handleLoginSuccess("手動登入");
    } else {
      setState(() {
        _isLoading = false;
        _statusMessage = '手動登入未完成或失敗。';
        Log.d('手動登入失敗或取消');
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget _buildTestUI(BuildContext context) {
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
            if (_statusMessage.isNotEmpty)
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _statusMessage.contains('成功') && !_statusMessage.contains('失敗')
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                  fontSize: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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