import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _accountKey = 'saved_account';
  static const String _passwordKey = 'saved_password';
  static const String _rememberMeKey = 'remember_me';
  static const String _keepLoggedInKey = 'keep_logged_in';
  static const String _darkModeKey = 'dark_mode';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  // 通用存取方法
  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  Future<String?> getString(String key) async {
    return _prefs.getString(key);
  }

  // 儲存帳號密碼
  Future<void> saveCredentials(String account, String password) async {
    await _prefs.setString(_accountKey, account);
    await _prefs.setString(_passwordKey, password);
  }

  // 清除儲存的帳號密碼
  Future<void> clearCredentials() async {
    await _prefs.remove(_accountKey);
    await _prefs.remove(_passwordKey);
  }

  // 獲取儲存的帳號
  Future<String?> getSavedAccount() async {
    return _prefs.getString(_accountKey);
  }

  // 獲取儲存的密碼
  Future<String?> getSavedPassword() async {
    return _prefs.getString(_passwordKey);
  }

  // 設置是否記住帳密
  Future<void> setRememberMe(bool value) async {
    await _prefs.setBool(_rememberMeKey, value);
  }

  // 獲取是否記住帳密的設定
  Future<bool> getRememberMe() async {
    return _prefs.getBool(_rememberMeKey) ?? false;
  }

  // 設置是否保持登入
  Future<void> setKeepLoggedIn(bool value) async {
    await _prefs.setBool(_keepLoggedInKey, value);
  }

  // 獲取是否保持登入的設定
  Future<bool> getKeepLoggedIn() async {
    return _prefs.getBool(_keepLoggedInKey) ?? false;
  }

  // 檢查是否應該自動登入
  Future<bool> shouldAutoLogin() async {
    final keepLoggedIn = await getKeepLoggedIn();
    if (!keepLoggedIn) return false;

    final account = await getSavedAccount();
    final password = await getSavedPassword();
    return account != null && password != null;
  }

  // 設置深色模式
  Future<void> setDarkMode(bool value) async {
    await _prefs.setBool(_darkModeKey, value);
  }

  // 獲取深色模式設定
  Future<bool> getDarkMode() async {
    return _prefs.getBool(_darkModeKey) ?? false;
  }
} 