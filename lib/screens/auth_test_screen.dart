import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ntust_auth_service.dart'; // Ensure this path is correct

class AuthTestScreen extends StatefulWidget {
  const AuthTestScreen({super.key});

  @override
  State<AuthTestScreen> createState() => _AuthTestScreenState();
}

class _AuthTestScreenState extends State<AuthTestScreen> {
  final _studentIdController = TextEditingController();
  final _passwordController = TextEditingController();
  String _testResult = '尚未測試'; // Initial state
  bool _isLoading = false;

  @override
  void dispose() {
    _studentIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _setTestResult(String result) {
    if (!mounted) return;
    setState(() {
      _testResult = result;
    });
  }

  Future<void> _testLogin() async {
    if (!mounted) return;
    
    // Basic validation
    if (_studentIdController.text.isEmpty || _passwordController.text.isEmpty) {
      _setTestResult('請輸入學號和密碼。');
      return;
    }

    setState(() {
      _isLoading = true;
      _testResult = '正在測試登入...';
    });

    try {
      // It's good practice to get the service instance once per method if not changing
      final authService = context.read<NtustAuthService>();
      final resultMessage = await authService.login(
        _studentIdController.text.trim(), // Trim input
        _passwordController.text,
      );
      if (!mounted) return;
      
      // After login, authService state (isLoggedIn, studentId) should be updated
      _setTestResult(
        '登入測試結果：$resultMessage\n'
        '學號 (來自Service)：${authService.studentId}\n'
        '登入狀態 (來自Service)：${authService.isLoggedIn}\n'
        'Cookies (數量)：${authService.sessionCookies?.length ?? 0}'
      );
    } catch (e) {
      if (!mounted) return;
      _setTestResult('登入測試失敗：\n${e.toString()}');
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testCheckSession() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _testResult = '正在檢查 Session...';
    });

    try {
      final authService = context.read<NtustAuthService>();
      // Assuming checkLocalSessionIsValid is the intended method for local check
      final isValid = await authService.checkLocalSessionIsValid(); 
      if (!mounted) return;
      
      _setTestResult(
        'Session 檢查結果：${isValid ? '有效 (本地)' : '無效 (本地)'}\n'
        '學號 (來自Service)：${authService.studentId}\n'
        '登入狀態 (來自Service)：${authService.isLoggedIn}'
      );
    } catch (e) {
      if (!mounted) return;
      _setTestResult('Session 檢查失敗：\n${e.toString()}');
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testLogout() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _testResult = '正在測試登出...';
    });

    try {
      final authService = context.read<NtustAuthService>();
      await authService.logout();
      if (!mounted) return;
      
      _setTestResult(
        '登出成功\n'
        '學號 (來自Service)：${authService.studentId}\n' // Should be null after logout
        '登入狀態 (來自Service)：${authService.isLoggedIn}' // Should be false
      );
    } catch (e) {
      if (!mounted) return;
      _setTestResult('登出失敗：\n${e.toString()}');
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use watch to rebuild when authService notifies listeners
    final authServiceState = context.watch<NtustAuthService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('台科大登入服務測試'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _studentIdController,
              decoration: const InputDecoration(
                labelText: '學號',
                hintText: '請輸入學號',
                border: OutlineInputBorder(),
              ),
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: '密碼',
                hintText: '請輸入密碼',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _testLogin,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
              child: _isLoading && _testResult.contains("登入") 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3,))
                  : const Text('測試登入'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isLoading ? null : _testCheckSession,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
              child: _isLoading && _testResult.contains("Session")
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3,))
                  : const Text('檢查 Session (本地)'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isLoading ? null : _testLogout,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
              child: _isLoading && _testResult.contains("登出")
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3,))
                  : const Text('測試登出'),
            ),
            const SizedBox(height: 24),
            Text(
              '目前狀態 (來自 Provider Watch):',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text('登入狀態: ${authServiceState.isLoggedIn}'),
            Text('學號: ${authServiceState.studentId ?? "N/A"}'),
            Text('Cookies 數量: ${authServiceState.sessionCookies?.length ?? 0}'),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '測試結果輸出：',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SelectableText( // Make it selectable for easier debugging
                    _testResult,
                    style: const TextStyle(fontFamily: 'monospace'), // Monospace for better readability of logs
                  ),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 12.0),
                      child: LinearProgressIndicator(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
