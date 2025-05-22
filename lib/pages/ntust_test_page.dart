// lib/ui/pages/ntust_connector_test_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
// TODO: 將 'tkt' 替換為您專案的實際名稱
import 'package:tkt/connector/core/dio_connector.dart';
import 'package:tkt/connector/ntust_connector.dart';
import 'package:tkt/debug/log/log.dart'; // 您提供的 Log 類別
import 'package:tkt/models/ntust/ap_tree_json.dart';
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
  static const String _targetVerificationUrl = "https://ssoam.ntust.edu.tw/nidp/app/login";
  static const String _scoreQueryUrl = "https://stuinfosys.ntust.edu.tw/JudgeCourseServ/JudgeCourse/ListJudge";


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
          builder: (context) => ManualLoginWebViewScreen( // ⭐ 或者 GeneralWebViewPage
            initialUrl: _targetVerificationUrl, // 載入您指定的驗證 URL
            title: "Session 檢查 (${Uri.parse(_targetVerificationUrl).host})",
            onLoginResult: (success) {
              if (success) {
                Navigator.of(context).pop();
              }
            },
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


  Future<void> _navigateToManualLogin() async {
    if (!mounted) return;
    setState(() {
      _statusMessage = '轉至手動登入頁面...';
      _isLoading = true;
    });

    final result = await Navigator.of(context).push<NTUSTLoginStatus>(
      MaterialPageRoute(
        builder: (context) => ManualLoginWebViewScreen(
          initialUrl: NTUSTConnector.ntustLoginUrl,
          title: '手動登入',
          onLoginResult: (success) {
            if (success) {
              Navigator.of(context).pop(NTUSTLoginStatus.success);
            } else {
              Navigator.of(context).pop(NTUSTLoginStatus.fail);
            }
          },
        ),
      ),
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _statusMessage = result == NTUSTLoginStatus.success ? '手動登入成功' : '手動登入未完成或失敗';
    });

    if (result == NTUSTLoginStatus.success) {
      await _updateCookieInfo();
      await _updateSessionInfo();
    }
  }

  Future<void> _openScoreQuery() async {
    if (!mounted) return;
    setState(() {
      _statusMessage = '開啟成績查詢頁面...';
      _isLoading = true;
    });

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ManualLoginWebViewScreen(
          initialUrl: _scoreQueryUrl,
          title: '成績查詢',
          onLoginResult: (success) {
            if (success) {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        _statusMessage = '已關閉成績查詢頁面';
      });
      await _updateCookieInfo();
    }
  }

  Future<void> _clearAllCookies() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _statusMessage = '正在清除所有 Cookies...';
    });

    try {
      final cookieManager = CookieManager.instance();
      await cookieManager.deleteAllCookies();
      await DioConnector.instance.cookiesManager?.deleteAll();
      
      if (mounted) {
        setState(() {
          _statusMessage = '已清除所有 Cookies';
          _cookieInfo = '';
          _sessionInfo = '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = '清除 Cookies 時發生錯誤：$e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        await _updateCookieInfo();
      }
    }
  }

  Future<void> _updateCookieInfo() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final StringBuffer cookieText = StringBuffer();
      
      // 獲取 WebView 的 cookies
      cookieText.writeln('=== WebView Cookies ===');
      final cookieManager = CookieManager.instance();
      final webViewCookies = await cookieManager.getCookies(url: WebUri(NTUSTConnector.ntustLoginUrl));
      
      if (webViewCookies.isEmpty) {
        cookieText.writeln('無 WebView Cookies\n');
      } else {
        for (var cookie in webViewCookies) {
          cookieText.writeln('- ${cookie.name}: ${cookie.value}');
          cookieText.writeln('  Domain: ${cookie.domain}');
          cookieText.writeln('  Path: ${cookie.path}');
          cookieText.writeln('  Expires: ${cookie.expiresDate ?? "Session"}');
          cookieText.writeln('  Secure: ${cookie.isSecure}');
          cookieText.writeln('  HttpOnly: ${cookie.isHttpOnly}');
          cookieText.writeln('');
        }
      }

      // 獲取 DioConnector 的 cookies
      cookieText.writeln('\n=== DioConnector Cookies ===');
      final cookieJar = DioConnector.instance.cookiesManager;
      if (cookieJar != null) {
        final dioCookies = await cookieJar.loadForRequest(Uri.parse(NTUSTConnector.ntustLoginUrl));
        if (dioCookies.isEmpty) {
          cookieText.writeln('無 DioConnector Cookies');
        } else {
          for (var cookie in dioCookies) {
            cookieText.writeln('- ${cookie.name}: ${cookie.value}');
            cookieText.writeln('  Domain: ${cookie.domain}');
            cookieText.writeln('  Path: ${cookie.path}');
            cookieText.writeln('  Expires: ${cookie.expires?.toLocal() ?? "Session"}');
            cookieText.writeln('  Secure: ${cookie.secure}');
            cookieText.writeln('  HttpOnly: ${cookie.httpOnly}');
            cookieText.writeln('');
          }
        }
      } else {
        cookieText.writeln('DioConnector CookieJar 未初始化');
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
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _navigateToManualLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('開啟手動登入'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _openScoreQuery,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('開啟成績查詢'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _clearAllCookies,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('清除所有 Cookies'),
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
        title: const Text('NTUST 登入測試'),
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