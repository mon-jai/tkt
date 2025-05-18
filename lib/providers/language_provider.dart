import 'package:flutter/material.dart';
import 'package:tkt/config/language.dart';
import 'package:tkt/services/storage_service.dart';

class LanguageProvider extends ChangeNotifier {
  final StorageService _storageService;
  static const String _localeKey = 'app_locale';

  Locale _currentLocale;

  LanguageProvider(this._storageService) : _currentLocale = AppLanguage.zhTW {
    _loadSavedLocale();
  }

  Locale get currentLocale => _currentLocale;

  Future<void> _loadSavedLocale() async {
    final savedLocale = await _storageService.getString(_localeKey);
    if (savedLocale != null) {
      final parts = savedLocale.split('_');
      if (parts.length == 2) {
        _currentLocale = Locale(parts[0], parts[1]);
        notifyListeners();
      }
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (_currentLocale == locale) return;
    
    if (AppLanguage.supportedLocales.contains(locale)) {
      _currentLocale = locale;
      await _storageService.setString(_localeKey, locale.toString().replaceAll('-', '_'));
      notifyListeners();
    }
  }

  String translate(String key) {
    final localeString = '${_currentLocale.languageCode}_${_currentLocale.countryCode}';
    return AppLanguage.translations[localeString]?[key] ?? key;
  }
} 