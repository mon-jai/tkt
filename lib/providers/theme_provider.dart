import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  final StorageService _storageService;
  bool _isDarkMode = false;

  ThemeProvider(this._storageService) {
    _loadThemeMode();
  }

  bool get isDarkMode => _isDarkMode;

  Future<void> _loadThemeMode() async {
    _isDarkMode = await _storageService.getDarkMode();
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _storageService.setDarkMode(_isDarkMode);
    notifyListeners();
  }
} 