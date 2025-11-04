import 'package:flutter/services.dart';

class VibrationService {
  static bool _vibrationEnabled = true;

  // خاصية للتحقق من حالة الاهتزاز
  static bool get isVibrationEnabled => _vibrationEnabled;

  // خاصية للتحقق من وجود جهاز اهتزاز
  static Future<bool> get hasVibrator async {
    // محاكاة وجود اهتزاز - يمكن تحسينه لاحقاً
    return true;
  }

  // تبديل حالة الاهتزاز
  static void toggleVibration() {
    _vibrationEnabled = !_vibrationEnabled;
    print('📳 Vibration ${_vibrationEnabled ? 'تم تفعيل الاهتزاز' : 'تم إيقاف الاهتزاز'}');
  }

  // تعيين حالة الاهتزاز
  static void setVibrationEnabled(bool enabled) {
    _vibrationEnabled = enabled;
    print('📳 Vibration ${enabled ? 'تم تفعيل الاهتزاز' : 'تم إيقاف الاهتزاز'}');
  }

  // اهتزاز النجاح
  static Future<void> vibrateSuccess() async {
    if (!_vibrationEnabled) return;
    try {
      await HapticFeedback.lightImpact();
      print('✅ Vibration: Success');
    } catch (e) {
      print('❌ Vibration error: $e');
    }
  }

  // اهتزاز الكومبو
  static Future<void> vibrateCombo() async {
    if (!_vibrationEnabled) return;
    try {
      await HapticFeedback.mediumImpact();
      print('🎯 Vibration: Combo');
    } catch (e) {
      print('❌ Vibration error: $e');
    }
  }

  // اهتزاز نهاية اللعبة
  static Future<void> vibrateGameOver() async {
    if (!_vibrationEnabled) return;
    try {
      await HapticFeedback.heavyImpact();
      print('💀 Vibration: Game Over');
    } catch (e) {
      print('❌ Vibration error: $e');
    }
  }

  // اهتزاز الإنجاز
  static Future<void> vibrateAchievement() async {
    if (!_vibrationEnabled) return;
    try {
      await HapticFeedback.selectionClick();
      print('🏆 Vibration: Achievement');
    } catch (e) {
      print('❌ Vibration error: $e');
    }
  }

  // اهتزاز الضرر
  static Future<void> vibrateDamage() async {
    if (!_vibrationEnabled) return;
    try {
      await HapticFeedback.mediumImpact();
      print('💥 Vibration: Damage');
    } catch (e) {
      print('❌ Vibration error: $e');
    }
  }

  // اهتزاز القفز
  static Future<void> vibrateJump() async {
    if (!_vibrationEnabled) return;
    try {
      await HapticFeedback.lightImpact();
      print('🦘 Vibration: Jump');
    } catch (e) {
      print('❌ Vibration error: $e');
    }
  }

  // اهتزاز جمع العملات
  static Future<void> vibrateCoin() async {
    if (!_vibrationEnabled) return;
    try {
      await HapticFeedback.selectionClick();
      print('💰 Vibration: Coin');
    } catch (e) {
      print('❌ Vibration error: $e');
    }
  }

  // اهتزاز الباور أب
  static Future<void> vibratePowerUp() async {
    if (!_vibrationEnabled) return;
    try {
      await HapticFeedback.mediumImpact();
      print('⭐ Vibration: PowerUp');
    } catch (e) {
      print('❌ Vibration error: $e');
    }
  }

  // اهتزاز ضرب الزعيم
  static Future<void> vibrateBossHit() async {
    if (!_vibrationEnabled) return;
    try {
      await HapticFeedback.heavyImpact();
      print('👹 Vibration: Boss Hit');
    } catch (e) {
      print('❌ Vibration error: $e');
    }
  }

  // اهتزاز نهاية المرحلة
  static Future<void> vibrateLevelComplete() async {
    if (!_vibrationEnabled) return;
    try {
      // اهتزاز متعدد للاحتفال
      await HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.heavyImpact();
      print('🎉 Vibration: Level Complete');
    } catch (e) {
      print('❌ Vibration error: $e');
    }
  }

  // اهتزاز مخصص
  static Future<void> customVibrate({
    Duration duration = const Duration(milliseconds: 100),
    int repeat = 1,
  }) async {
    if (!_vibrationEnabled) return;
    try {
      for (int i = 0; i < repeat; i++) {
        await HapticFeedback.mediumImpact();
        if (i < repeat - 1) {
          await Future.delayed(duration);
        }
      }
      print('🔊 Custom Vibration: $repeat times');
    } catch (e) {
      print('❌ Vibration error: $e');
    }
  }

  // الحصول على حالة الاهتزاز كـ Map
  static Map<String, dynamic> getVibrationStatus() {
    return {
      'vibrationEnabled': _vibrationEnabled,
      'hasVibrator': true, // يمكن تحسينه لاحقاً
    };
  }

  // إعادة تعيين الإعدادات
  static void reset() {
    _vibrationEnabled = true;
    // print('🔄 Vibration settings reset');
  }
}