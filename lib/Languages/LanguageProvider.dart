import 'package:flutter/material.dart';
import 'language_service.dart';

class LanguageProvider with ChangeNotifier {
  String _currentLanguage = 'ar';
  Locale _locale = const Locale('ar');

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    _currentLanguage = await LanguageService.getLanguage();
    _locale = Locale(_currentLanguage);
    notifyListeners();
  }

  String get currentLanguage => _currentLanguage;
  bool get isArabic => _currentLanguage == 'ar';
  bool get isEnglish => _currentLanguage == 'en';
  Locale get locale => _locale;

  Future<void> toggleLanguage() async {
    _currentLanguage = isArabic ? 'en' : 'ar';
    _locale = Locale(_currentLanguage);
    await LanguageService.setLanguage(_currentLanguage);
    notifyListeners();
  }

  Future<void> setLanguage(String languageCode) async {
    _currentLanguage = languageCode;
    _locale = Locale(languageCode);
    await LanguageService.setLanguage(languageCode);
    notifyListeners();
  }
}