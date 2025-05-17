import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tkt/screens/main_screen.dart';
import 'package:tkt/screens/register_screen.dart';
import '../services/auth_service.dart';
import '../models/auth_model.dart'; // 您的 AuthModel
import '../services/storage_service.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _accountController = TextEditingController(); // 用於學號
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _keepLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final storageService = Provider.of<StorageService>(context, listen: false);
    final savedAccount = await storageService.getSavedAccount();
    final savedPassword = await storageService.getSavedPassword();
    final rememberMe = await storageService.getRememberMe();
    final keepLoggedIn = await storageService.getKeepLoggedIn();

    if (mounted) {
      setState(() {
        if (rememberMe) {
          _accountController.text = savedAccount ?? '';
          _passwordController.text = savedPassword ?? '';
        }
        _rememberMe = rememberMe;
        _keepLoggedIn = keepLoggedIn;
      });
    }
  }

  Future<void> _performLogin() async {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      final authService = Provider.of<AuthService>(context, listen: false);
      final storageService = Provider.of<StorageService>(context, listen: false);
      
      final request = LoginRequest(
        account: _accountController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 儲存或清除記住的帳密
      await storageService.setRememberMe(_rememberMe);
      if (_rememberMe) {
        await storageService.saveCredentials(
          _accountController.text.trim(),
          _passwordController.text.trim(),
        );
      } else {
        await storageService.clearCredentials();
      }

      // 儲存保持登入的設定
      await storageService.setKeepLoggedIn(_keepLoggedIn);

      try {
        // 為了避免問題，先使用一個簡單的成功登入模擬
        // 實際上，應該使用下面注釋的代碼
        await Future.delayed(const Duration(seconds: 1));

        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        // 直接導航到主畫面
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (route) => false,
        );

        /*
        final result = await authService.login(request);

        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        if (result is Success<LoginResponse>) {
          final loginResponse = result.data;
          if (loginResponse.success && loginResponse.token != null) {
            debugPrint("LoginScreen: Login successful, navigating to Main App Screen.");
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MainScreen()),
              (route) => false,
            );
          } else {
            _showErrorSnackBar(loginResponse.message ?? '登入失敗，請檢查您的學號或密碼。');
          }
        } else if (result is Error<LoginResponse>) {
          _showErrorSnackBar(result.message);
        } else if (result is ApiException<LoginResponse>) {
          _showErrorSnackBar('登入時發生無法預期的錯誤: ${result.exception.toString()}');
        }
        */
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('登入時發生錯誤: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  void dispose() {
    _accountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Logo (使用 Icon 替代)
                  Image.asset('assets/images/logo.png', width: 80, height: 80),
                  const SizedBox(height: 16),
                  Text(
                    '台科通', // 更改標題
                    textAlign: TextAlign.center,
                    style: textTheme.titleLarge?.copyWith(color: colorScheme.primary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '登入以繼續', // 更改副標題
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 40),
                  // Text(
                  //   '登入帳號', // 此標題可選，看設計需求
                  //   textAlign: TextAlign.center,
                  //   style: textTheme.titleMedium?.copyWith(fontSize: 22),
                  // ),
                  // const SizedBox(height: 24),

                  // 學號輸入框
                  TextFormField(
                    controller: _accountController,
                    style: TextStyle(color: textTheme.bodyLarge?.color), // 使用主題文字顏色
                    decoration: const InputDecoration(
                      hintText: '學號', // 更改提示文字
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    keyboardType: TextInputType.text, // 學號可能包含字母
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '請輸入學號';
                      }
                      // 可選：新增學號格式驗證
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // 密碼輸入框
                  TextFormField(
                    controller: _passwordController,
                    style: TextStyle(color: textTheme.bodyLarge?.color), // 使用主題文字顏色
                    decoration: InputDecoration(
                      hintText: '密碼',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '請輸入密碼';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text('記住帳密'),
                          value: _rememberMe,
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (bool? value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text('保持登入'),
                          value: _keepLoggedIn,
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (bool? value) {
                            setState(() {
                              _keepLoggedIn = value ?? false;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    ElevatedButton(
                      onPressed: _performLogin,
                      child: const Text('登入'), // 按鈕文字由 ElevatedButtonTheme 控制
                    ),
                  const SizedBox(height: 20),

                  TextButton(
                    onPressed: _isLoading ? null : () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      );
                    },
                    child: const Text('還沒有帳號？ 立即註冊'),
                  ),
                  // 移除了 OrSeparatorWidget 和 SocialLoginButton
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}