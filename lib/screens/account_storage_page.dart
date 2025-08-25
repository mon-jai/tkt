import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountStoragePage extends StatefulWidget {
  const AccountStoragePage({super.key});

  @override
  State<AccountStoragePage> createState() => _AccountStoragePageState();
}

class _AccountStoragePageState extends State<AccountStoragePage> {
  final _formKey = GlobalKey<FormState>();
  final _studentIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  static const String _studentIdKey = 'stored_student_id';
  static const String _passwordKey = 'stored_password';

  @override
  void initState() {
    super.initState();
    _loadStoredCredentials();
  }

  Future<void> _loadStoredCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _studentIdController.text = prefs.getString(_studentIdKey) ?? '';
      _passwordController.text = prefs.getString(_passwordKey) ?? '';
    });
  }

  Future<void> _saveCredentials() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_studentIdKey, _studentIdController.text);
      await prefs.setString(_passwordKey, _passwordController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('帳號密碼已儲存')),
        );
      }
    }
  }

  Future<void> _clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_studentIdKey);
    await prefs.remove(_passwordKey);
    setState(() {
      _studentIdController.clear();
      _passwordController.clear();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('帳號密碼已清除')),
      );
    }
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('儲存校園系統帳號'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearCredentials,
            tooltip: '清除儲存的帳號密碼',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _studentIdController,
                decoration: const InputDecoration(
                  labelText: '學號',
                  hintText: '請輸入學號',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入學號';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: '密碼',
                  hintText: '請輸入密碼',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入密碼';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _saveCredentials,
                icon: const Icon(Icons.save),
                label: const Text('儲存帳號密碼'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '注意：帳號密碼將以加密形式儲存在本地裝置中，不會被上傳至雲端',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '如有疑慮請自行考慮是否使用',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 