import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';

class DemoModeProvider with ChangeNotifier {
  final StorageService _storageService;
  bool _isDemoModeEnabled = false;
  bool _isLoading = false;

  DemoModeProvider(this._storageService) {
    _loadDemoModeState();
  }

  bool get isDemoModeEnabled => _isDemoModeEnabled;
  bool get isLoading => _isLoading;

  Future<void> _loadDemoModeState() async {
    _isLoading = true;
    notifyListeners();

    try {
      _isDemoModeEnabled = await _storageService.getDemoMode();
      debugPrint("DemoModeProvider: 載入演示模式狀態: $_isDemoModeEnabled");
    } catch (e) {
      debugPrint("DemoModeProvider: 載入演示模式狀態時發生錯誤: $e");
      _isDemoModeEnabled = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleDemoMode() async {
    try {
      _isDemoModeEnabled = !_isDemoModeEnabled;
      await _storageService.setDemoMode(_isDemoModeEnabled);
      debugPrint("DemoModeProvider: 演示模式已${_isDemoModeEnabled ? '啟用' : '停用'}");
      notifyListeners();
    } catch (e) {
      debugPrint("DemoModeProvider: 切換演示模式時發生錯誤: $e");
      // 回滾狀態
      _isDemoModeEnabled = !_isDemoModeEnabled;
      notifyListeners();
    }
  }

  Future<void> setDemoMode(bool enabled) async {
    if (_isDemoModeEnabled == enabled) return;

    try {
      _isDemoModeEnabled = enabled;
      await _storageService.setDemoMode(enabled);
      debugPrint("DemoModeProvider: 演示模式設為: $enabled");
      notifyListeners();
    } catch (e) {
      debugPrint("DemoModeProvider: 設定演示模式時發生錯誤: $e");
      // 回滾狀態
      _isDemoModeEnabled = !enabled;
      notifyListeners();
    }
  }

  /// 重置演示模式設定
  Future<void> resetDemoMode() async {
    await setDemoMode(false);
  }
}
