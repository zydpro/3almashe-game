import 'dart:ui';

import 'package:flutter/cupertino.dart';

class GameConstants {
  // === إعدادات اللعبة ===
  static const String gameName = 'عداء المنصات';
  static const String gameVersion = '1.0.0';
  static const int maxLevels = 20;
  static const int initialLives = 3;

  // === إعدادات الوقت ===
  static const int levelDuration = 120; // ثانيتين
  static const int tutorialDisplayTime = 5; // ثواني
  static const int adCooldown = 30; // ثواني

  // === إعدادات النقاط ===
  static const int baseObstacleScore = 10;
  static const int basePowerUpScore = 50;
  static const int comboBonusMultiplier = 2;

  // === إعدادات العوائق ===
  static const double minObstacleSpawnTime = 0.4; // ثواني
  static const double maxObstacleSpawnTime = 1.8; // ثواني
  static const int maxConcurrentObstacles = 5;

  // === إعدادات الباور أب ===
  static const double powerUpSpawnChance = 0.4;
  static const int powerUpDuration = 5; // ثواني
  static const int maxConcurrentPowerUps = 2;

  // === الألوان ===
  static const Color primaryColor = Color(0xFF4CAF50);
  static const Color secondaryColor = Color(0xFF2196F3);
  static const Color accentColor = Color(0xFFFFC107);
  static const Color backgroundColor = Color(0xFF121212);
  static const Color textColor = Color(0xFFFFFFFF);
  static const Color dangerColor = Color(0xFFF44336);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);

  // === الأحجام ===
  static const double characterSize = 80.0;
  static const double obstacleSize = 50.0;
  static const double powerUpSize = 40.0;
  static const double buttonHeight = 50.0;
  static const double iconSize = 24.0;

  // === الخطوط ===
  static const String arabicFont = 'Cairo';
  static const double titleFontSize = 24.0;
  static const double subtitleFontSize = 18.0;
  static const double bodyFontSize = 16.0;
  static const double captionFontSize = 14.0;

  // === الرسائل ===
  static const String jumpTutorial = 'اسحب للأعلى للقفز';
  static const String duckTutorial = 'اسحب لأسفل للانحناء';
  static const String comboMessage = 'كومبو!';
  static const String gameOverMessage = 'انتهت اللعبة!';
  static const String levelCompleteMessage = 'اكتملت المرحلة!';

  // === مسارات الصور ===
  static const String characterRunImage = 'assets/images/character_run.png';
  static const String characterJumpImage = 'assets/images/character_jump.png';
  static const String characterDuckImage = 'assets/images/character_duck.png';
  static const String obstacleImage = 'assets/images/obstacle.png';
  static const String powerUpImage = 'assets/images/power_up.png';
  static const String backgroundImage = 'assets/images/background.png';

  // === مسارات الأصوات ===
  static const String jumpSound = 'assets/audio/jump.wav';
  static const String coinSound = 'assets/audio/coin.wav';
  static const String gameOverSound = 'assets/audio/game_over.wav';
  static const String levelCompleteSound = 'assets/audio/level_complete.wav';
  static const String backgroundMusic = 'assets/audio/background_music.mp3';

  // === إعدادات الاهتزاز ===
  static const int vibrateDurationShort = 50; // مللي ثانية
  static const int vibrateDurationLong = 200; // مللي ثانية
  static const int vibratePatternGameOver = 500; // مللي ثانية

  // === دوال مساعدة ===
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static bool isTablet(BuildContext context) {
    return getScreenWidth(context) > 600;
  }

  static double responsiveSize(BuildContext context, double size) {
    return isTablet(context) ? size * 1.5 : size;
  }
}

// فئة للمستويات
class LevelConfig {
  static Map<int, Map<String, dynamic>> levels = {
    1: {
      'name': 'المستوى الأول',
      'targetScore': 100,
      'obstacleSpeed': 0.015,
      'backgroundColor': Color(0xFF87CEEB),
      'unlocked': true,
    },
    2: {
      'name': 'المستوى الثاني',
      'targetScore': 200,
      'obstacleSpeed': 0.018,
      'backgroundColor': Color(0xFF98FB98),
      'unlocked': false,
    },
    3: {
      'name': 'المستوى الثالث',
      'targetScore': 300,
      'obstacleSpeed': 0.021,
      'backgroundColor': Color(0xFFFFB6C1),
      'unlocked': false,
    },
    // يمكن إضافة المزيد من المستويات...
  };
}