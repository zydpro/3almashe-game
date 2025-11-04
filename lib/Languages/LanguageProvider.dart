import 'package:flutter/material.dart';
import 'language_service.dart';

class LanguageProvider with ChangeNotifier {
  Locale _locale = const Locale('ar');

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    await LanguageService.initialize();
    _locale = Locale(LanguageService.currentLanguage);
    notifyListeners();
  }

  String get currentLanguage => LanguageService.currentLanguage;
  bool get isArabic => LanguageService.isArabic;
  bool get isEnglish => LanguageService.isEnglish;
  Locale get locale => _locale;

  Future<void> toggleLanguage() async {
    final newLanguage = LanguageService.oppositeLanguage;
    await LanguageService.setLanguage(newLanguage);
    _locale = Locale(newLanguage);
    notifyListeners();
  }

  Future<void> setLanguage(String languageCode) async {
    if (languageCode != currentLanguage) {
      await LanguageService.setLanguage(languageCode);
      _locale = Locale(languageCode);
      notifyListeners();
    }
  }
}