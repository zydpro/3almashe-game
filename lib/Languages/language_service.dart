// lib/services/language_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static const String _languageKey = 'app_language';
  static String _currentLanguage = 'ar';

  static Future<void> initialize() async {
    _currentLanguage = await getLanguage();
  }

  static Future<void> setLanguage(String languageCode) async {
    _currentLanguage = languageCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
  }

  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? 'ar';
  }

  static String get currentLanguage => _currentLanguage;

  static bool get isArabic => _currentLanguage == 'ar';
  static bool get isEnglish => _currentLanguage == 'en';

  static String get oppositeLanguage => isArabic ? 'en' : 'ar';
  static String get oppositeLanguageName => isArabic ? 'English' : 'العربية';
}