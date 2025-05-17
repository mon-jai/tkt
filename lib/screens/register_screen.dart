import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart'; // 您的 AuthService
import '../models/auth_model.dart';   // 您的 AuthModel
import 'login_screen.dart';        // 登入畫面

// 註冊階段枚舉
enum RegisterStage {
  enterDetails, // 輸入姓名、Email
  verifyOtp,    // 輸入OTP
  setPassword   // 設定密碼
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // 各階段的控制器
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  RegisterStage _currentStage = RegisterStage.enterDetails;
  bool _isLoading = false;
  bool _isOtpVerified = false;

  // OTP 倒數計時器相關
  Timer? _otpResendTimer;
  int _otpResendCooldown = 60;
  bool _canResendOtp = true;

  // 用於儲存第一階段的資料
  String _stagedFullName = "";
  String _stagedEmail = "";


  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpResendTimer?.cancel();
    super.dispose();
  }

  void _startOtpResendTimer() {
    _canResendOtp = false;
    _otpResendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_otpResendCooldown > 0) {
          _otpResendCooldown--;
        } else {
          timer.cancel();
          _canResendOtp = true;
          _otpResendCooldown = 60; // 重設
        }
      });
    });
  }

  Future<void> _requestOtp() async {
    if (_currentStage != RegisterStage.enterDetails) return;
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
        _showErrorSnackBar("請修正表單中的錯誤");
        return;
    }

    _stagedFullName = _fullNameController.text.trim();
    _stagedEmail = _emailController.text.trim();

    setState(() { _isLoading = true; });
    final authService = Provider.of<AuthService>(context, listen: false);
    // RequestOtpRequest 現在只包含 email
    final request = RequestOtpRequest(email: _stagedEmail);

    final result = await authService.requestOtp(request);
    if (!mounted) return;

    setState(() { _isLoading = false; });

    if (result is Success<RequestOtpResponse>) {
      _showSuccessSnackBar(result.data.message);
      _startOtpResendTimer();
      setState(() { _currentStage = RegisterStage.verifyOtp; });
    } else if (result is Error<RequestOtpResponse>) {
      _showErrorSnackBar(result.message);
    } else if (result is ApiException<RequestOtpResponse>) {
      _showErrorSnackBar('請求OTP時發生錯誤: ${result.exception.toString()}');
    }
  }

  Future<void> _verifyOtp() async {
    if (_currentStage != RegisterStage.verifyOtp) return;
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
        _showErrorSnackBar("請修正表單中的錯誤");
        return;
    }

    setState(() { _isLoading = true; });
    final authService = Provider.of<AuthService>(context, listen: false);
    final request = VerifyOtpRequest(
      email: _stagedEmail, // 使用第一階段輸入的Email
      otp: _otpController.text.trim(),
    );

    final result = await authService.verifyOtp(request);
    if (!mounted) return;

    setState(() { _isLoading = false; });

    if (result is Success<VerifyOtpResponse>) {
      _showSuccessSnackBar(result.data.message);
      _isOtpVerified = true;
      _otpResendTimer?.cancel();
      _canResendOtp = false; // OTP 驗證成功後，不應立即重新發送
      setState(() { _currentStage = RegisterStage.setPassword; });
    } else if (result is Error<VerifyOtpResponse>) {
      _showErrorSnackBar(result.message);
    } else if (result is ApiException<VerifyOtpResponse>) {
      _showErrorSnackBar('驗證OTP時發生錯誤: ${result.exception.toString()}');
    }
  }

  Future<void> _registerUser() async {
    if (_currentStage != RegisterStage.setPassword) return;
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
        _showErrorSnackBar("請修正表單中的錯誤");
        return;
    }
    if (!_isOtpVerified) {
      _showErrorSnackBar("Email尚未驗證，請返回上一步驟。");
      return;
    }

    setState(() { _isLoading = true; });
    final authService = Provider.of<AuthService>(context, listen: false);
    // RegisterRequest 不再包含 account
    final request = RegisterRequest(
      fullName: _stagedFullName,
      email: _stagedEmail,
      password: _passwordController.text.trim(),
    );

    final result = await authService.register(request);
    if (!mounted) return;

    setState(() { _isLoading = false; });

    if (result is Success<RegisterResponse>) {
      _showSuccessSnackBar(result.data.message + (result.data.account != null ? " 您的學號: ${result.data.account}" : ""));
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } else if (result is Error<RegisterResponse>) {
      _showErrorSnackBar(result.message);
    } else if (result is ApiException<RegisterResponse>) {
      _showErrorSnackBar('註冊時發生錯誤: ${result.exception.toString()}');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Theme.of(context).colorScheme.error),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Widget _buildStageOneForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _fullNameController,
          enabled: !_isLoading,
          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
          decoration: const InputDecoration(
            hintText: '姓名 (例如: 王小明)',
            prefixIcon: Icon(Icons.person_outline),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return '請輸入姓名';
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          enabled: !_isLoading,
          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
          decoration: const InputDecoration(
            hintText: '學校 Email',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            // 只在第一階段且欄位啟用時驗證
            if (_currentStage == RegisterStage.enterDetails && !_isLoading) {
              if (value == null || value.isEmpty) return '請輸入學校Email';
              if (!value.toLowerCase().endsWith('@mail.ntust.edu.tw')) {
                return 'Email必須是 @mail.ntust.edu.tw 結尾';
              }
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading || !_canResendOtp ? null : _requestOtp,
          child: Text(_isLoading ? "處理中..." : (_canResendOtp ? '傳送驗證碼' : '重新傳送 (${_otpResendCooldown}s)')),
        ),
      ],
    );
  }

  Widget _buildStageTwoForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('已傳送驗證碼到: $_stagedEmail', style: theme.textTheme.bodyMedium),
        // 移除了顯示 "帳號" 的部分
        const SizedBox(height: 16),
        TextFormField(
          controller: _otpController,
          enabled: !_isLoading,
          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
          decoration: const InputDecoration(
            hintText: '輸入6位數驗證碼',
            prefixIcon: Icon(Icons.pin_outlined),
          ),
          keyboardType: TextInputType.number,
          maxLength: 6,
          validator: (value) {
            if (_currentStage == RegisterStage.verifyOtp && !_isLoading) {
                if (value == null || value.isEmpty) return '請輸入驗證碼';
                if (value.length != 6) return '驗證碼應為6位數';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _verifyOtp,
          child: Text(_isLoading ? "驗證中..." : '驗證並繼續'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _isLoading || !_canResendOtp ? null : () {
            _otpController.clear(); // 清除舊的OTP輸入
            // 不需要重置階段，直接重新請求 OTP
            _requestOtp();
          },
          child: Text(_canResendOtp ? '沒有收到？重新傳送' : '重新傳送 (${_otpResendCooldown}s)'),
        )
      ],
    );
  }

  Widget _buildStageThreeForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('Email 已驗證: $_stagedEmail', style: theme.textTheme.bodyMedium),
            const SizedBox(width: 8),
            const Icon(Icons.check_circle, color: Colors.green, size: 18),
          ],
        ),
        // 移除了顯示 "帳號" 的部分
        const SizedBox(height: 24),
        TextFormField(
          controller: _passwordController,
          enabled: !_isLoading,
          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
          decoration: const InputDecoration(
            hintText: '設定密碼',
            prefixIcon: Icon(Icons.lock_outline),
          ),
          obscureText: true,
          validator: (value) {
            if (_currentStage == RegisterStage.setPassword && !_isLoading) {
                if (value == null || value.isEmpty) return '請設定密碼';
                if (value.length < 6) return '密碼長度至少6位'; // 根據您的密碼策略調整
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _confirmPasswordController,
          enabled: !_isLoading,
          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
          decoration: const InputDecoration(
            hintText: '確認密碼',
            prefixIcon: Icon(Icons.lock_clock_outlined),
          ),
          obscureText: true,
          validator: (value) {
            if (_currentStage == RegisterStage.setPassword && !_isLoading) {
                if (value == null || value.isEmpty) return '請確認密碼';
                if (value != _passwordController.text) return '兩次輸入的密碼不一致';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _registerUser,
          child: Text(_isLoading ? "建立中..." : '建立帳號'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String appBarTitle = "";
    switch (_currentStage) {
      case RegisterStage.enterDetails:
        appBarTitle = "註冊 - 輸入資料";
        break;
      case RegisterStage.verifyOtp:
        appBarTitle = "註冊 - 驗證Email";
        break;
      case RegisterStage.setPassword:
        appBarTitle = "註冊 - 設定密碼";
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        // 返回按鈕邏輯
        leading: (_currentStage == RegisterStage.enterDetails && !_isLoading)
            ? null // 在第一階段或載入中時不顯示返回按鈕 (或顯示預設返回到登入頁)
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _isLoading ? null : () {
                  if (_currentStage == RegisterStage.verifyOtp) {
                    setState(() { _currentStage = RegisterStage.enterDetails; });
                    _otpResendTimer?.cancel();
                    _canResendOtp = true;
                    _otpResendCooldown = 60;
                    _otpController.clear();
                  } else if (_currentStage == RegisterStage.setPassword) {
                    setState(() { _currentStage = RegisterStage.verifyOtp; });
                    _isOtpVerified = false; // 需要重新驗證OTP
                    _passwordController.clear();
                    _confirmPasswordController.clear();
                    // 可以選擇是否重啟OTP計時器，如果Email已驗證過但想重新發送
                    // _startOtpResendTimer(); // 或讓使用者點擊重新發送
                  }
                },
              ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0), // 調整 padding
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Image.asset('assets/images/logo.png', width: 60, height: 60), // 校務APP風格圖示
                  const SizedBox(height: 12),
                  Text(
                    '建立 台科通 帳號', // 更改標題
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary, fontSize: 22),
                  ),
                  const SizedBox(height: 32),

                  if (_currentStage == RegisterStage.enterDetails)
                    _buildStageOneForm(theme),
                  if (_currentStage == RegisterStage.verifyOtp)
                    _buildStageTwoForm(theme),
                  if (_currentStage == RegisterStage.setPassword)
                    _buildStageThreeForm(theme),

                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 24.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),

                  const SizedBox(height: 24),
                  if (!_isLoading && _currentStage == RegisterStage.enterDetails)
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // 返回上一頁 (通常是 LoginScreen)
                      },
                      child: const Text('已有帳號？ 前往登入'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}