import 'package:almashe_game/services/vibration_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'audio_service.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  static const String _soundEnabledKey = 'sound_enabled';
  static const String _musicEnabledKey = 'music_enabled';
  static const String _vibrationEnabledKey = 'vibration_enabled';
  static const String _notificationsEnabledKey = 'notifications_enabled';

  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _vibrationEnabled = true;
  bool _notificationsEnabled = true;

  // Listeners للتحديثات
  final List<Function()> _listeners = [];

  void addListener(Function() listener) {
    _listeners.add(listener);
  }

  void removeListener(Function() listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    _soundEnabled = prefs.getBool(_soundEnabledKey) ?? true;
    _musicEnabled = prefs.getBool(_musicEnabledKey) ?? true;
    _vibrationEnabled = prefs.getBool(_vibrationEnabledKey) ?? true;
    _notificationsEnabled = prefs.getBool(_notificationsEnabledKey) ?? true;

    // تطبيق الإعدادات على الخدمات الأخرى
    _applySettings();
  }

  void _applySettings() {
    // تطبيق على AudioService
    final audioService = AudioService();
    audioService.setSoundEnabled(_soundEnabled);
    audioService.setMusicEnabled(_musicEnabled);

    // تطبيق على VibrationService
    VibrationService.setVibrationEnabled(_vibrationEnabled);
  }

  // Getters
  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  bool get notificationsEnabled => _notificationsEnabled;

  // Setters
  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundEnabledKey, enabled);

    AudioService().setSoundEnabled(enabled);
    _notifyListeners();
  }

  Future<void> setMusicEnabled(bool enabled) async {
    _musicEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_musicEnabledKey, enabled);

    AudioService().setMusicEnabled(enabled);
    _notifyListeners();
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    _vibrationEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vibrationEnabledKey, enabled);

    VibrationService.setVibrationEnabled(enabled);
    _notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);

    _notifyListeners();
  }

  // تبديل الإعدادات
  Future<void> toggleSound() async => await setSoundEnabled(!_soundEnabled);
  Future<void> toggleMusic() async => await setMusicEnabled(!_musicEnabled);
  Future<void> toggleVibration() async => await setVibrationEnabled(!_vibrationEnabled);
  Future<void> toggleNotifications() async => await setNotificationsEnabled(!_notificationsEnabled);

  Map<String, dynamic> toMap() {
    return {
      'soundEnabled': _soundEnabled,
      'musicEnabled': _musicEnabled,
      'vibrationEnabled': _vibrationEnabled,
      'notificationsEnabled': _notificationsEnabled,
    };
  }
}