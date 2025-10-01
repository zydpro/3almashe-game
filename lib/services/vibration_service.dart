import 'package:vibration/vibration.dart';

class VibrationService {
  static bool _vibrationEnabled = true;

  static Future<bool> get hasVibrator async {
    return await Vibration.hasVibrator() ?? false;
  }

  static void setVibrationEnabled(bool enabled) {
    _vibrationEnabled = enabled;
  }

  static Future<void> vibrateSuccess() async {
    if (!_vibrationEnabled) return;
    if (await hasVibrator) {
      Vibration.vibrate(duration: 100);
    }
  }

  static Future<void> vibrateCombo() async {
    if (!_vibrationEnabled) return;
    if (await hasVibrator) {
      Vibration.vibrate(pattern: [0, 50, 100, 50]);
    }
  }

  static Future<void> vibrateGameOver() async {
    if (!_vibrationEnabled) return;
    if (await hasVibrator) {
      Vibration.vibrate(pattern: [0, 200, 100, 200]);
    }
  }

  static Future<void> vibrateAchievement() async {
    if (!_vibrationEnabled) return;
    if (await hasVibrator) {
      Vibration.vibrate(pattern: [0, 100, 50, 100, 50, 100]);
    }
  }
}