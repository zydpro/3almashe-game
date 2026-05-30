// lib/online/services/screen_orientation_service.dart
import 'package:flutter/services.dart';

class ScreenOrientationService {
  static final ScreenOrientationService _instance = ScreenOrientationService._internal();
  factory ScreenOrientationService() => _instance;
  ScreenOrientationService._internal();

  bool _isLandscapeLocked = false;
  bool _isPermanent = false; // هل الوضع دائم؟

  // ✅ تعيين الوضع الدائم
  void setPermanentMode(bool permanent) {
    _isPermanent = permanent;
    print('🔄 وضع التوجيه الدائم: $permanent');
  }

  // ✅ قفل الشاشة في الوضع الأفقي
  Future<void> lockToLandscape() async {
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);

      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

      _isLandscapeLocked = true;
      print('🔒 Landscape locked');
    } catch (e) {
      print('❌ Failed to lock landscape: $e');
    }
  }

  // ✅ إعادة الشاشة للوضع العمودي (فقط إذا لم يكن دائماً)
  Future<void> unlockToPortrait() async {
    // إذا كان الوضع دائماً، لا تفعل شيئاً
    if (_isPermanent) {
      print('⏭️ Skipping orientation change - permanent mode is ON');
      return;
    }

    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      _isLandscapeLocked = false;
      print('🔓 Portrait unlocked');
    } catch (e) {
      print('❌ Failed to unlock portrait: $e');
    }
  }

  // ✅ إعادة تعيين القفل (فقط إذا لم يكن دائماً)
  Future<void> resetToDefault() async {
    // إذا كان الوضع دائماً، لا تفعل شيئاً
    if (_isPermanent) {
      print('⏭️ Skipping reset - permanent mode is ON');
      return;
    }

    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      _isLandscapeLocked = false;
      print('🔄 Orientation reset complete');
    } catch (e) {
      print('❌ Failed to reset orientation: $e');
    }
  }

  // ✅ التحقق من الحالة
  bool get isLandscapeLocked => _isLandscapeLocked;
  bool get isPermanent => _isPermanent;
}