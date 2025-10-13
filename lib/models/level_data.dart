import 'package:flutter/material.dart';
import '../services/game_data_service.dart';
import '../Languages/localization.dart';

class LevelData {
  final int levelNumber;
  final String nameKey;
  final String descriptionKey;
  final int targetScore;
  final double obstacleSpeed;
  final int obstacleFrequency;
  final Color backgroundColor;
  final bool isUnlocked;
  final int levelDuration;
  final int bossHealth;
  final double bossAttackSpeed;
  final bool isRareBoss;
  final bool isFinalBoss;
  final String backgroundImage;

  LevelData({
    required this.levelNumber,
    required this.nameKey,
    required this.descriptionKey,
    required this.targetScore,
    required this.obstacleSpeed,
    required this.obstacleFrequency,
    required this.backgroundColor,
    required this.isUnlocked,
    required this.bossHealth,
    required this.bossAttackSpeed,
    required this.backgroundImage,
    this.levelDuration = 120,
    this.isRareBoss = false,
    this.isFinalBoss = false,
  });

  // دالة للحصول على اسم المرحلة بناءً على المفتاح
  String getName(AppLocalizations l10n) {
    switch (nameKey) {
      case 'levelName1': return l10n.levelName1;
      case 'levelName2': return l10n.levelName2;
      case 'levelName3': return l10n.levelName3;
      case 'levelName4': return l10n.levelName4;
      case 'levelName5': return l10n.levelName5;
      case 'levelName6': return l10n.levelName6;
      case 'levelName7': return l10n.levelName7;
      case 'levelName8': return l10n.levelName8;
      case 'levelName9': return l10n.levelName9;
      case 'levelName10': return l10n.levelName10;
      case 'levelName11': return l10n.levelName11;
      case 'levelName12': return l10n.levelName12;
      case 'levelName13': return l10n.levelName13;
      case 'levelName14': return l10n.levelName14;
      case 'levelName15': return l10n.levelName15;
      case 'levelName16': return l10n.levelName16;
      case 'levelName17': return l10n.levelName17;
      case 'levelName18': return l10n.levelName18;
      case 'levelName19': return l10n.levelName19;
      case 'levelName20': return l10n.levelName20;
      default: return 'Level $levelNumber';
    }
  }

  // دالة للحصول على وصف المرحلة بناءً على المفتاح
  String getDescription(AppLocalizations l10n) {
    switch (descriptionKey) {
      case 'levelDesc1': return l10n.levelDesc1;
      case 'levelDesc2': return l10n.levelDesc2;
      case 'levelDesc3': return l10n.levelDesc3;
      case 'levelDesc4': return l10n.levelDesc4;
      case 'levelDesc5': return l10n.levelDesc5;
      case 'levelDesc6': return l10n.levelDesc6;
      case 'levelDesc7': return l10n.levelDesc7;
      case 'levelDesc8': return l10n.levelDesc8;
      case 'levelDesc9': return l10n.levelDesc9;
      case 'levelDesc10': return l10n.levelDesc10;
      case 'levelDesc11': return l10n.levelDesc11;
      case 'levelDesc12': return l10n.levelDesc12;
      case 'levelDesc13': return l10n.levelDesc13;
      case 'levelDesc14': return l10n.levelDesc14;
      case 'levelDesc15': return l10n.levelDesc15;
      case 'levelDesc16': return l10n.levelDesc16;
      case 'levelDesc17': return l10n.levelDesc17;
      case 'levelDesc18': return l10n.levelDesc18;
      case 'levelDesc19': return l10n.levelDesc19;
      case 'levelDesc20': return l10n.levelDesc20;
      default: return 'Complete this level to advance';
    }
  }

  static Future<List<LevelData>> getAllLevels() async {
    List<int> unlockedLevels = await GameDataService.getUnlockedLevels();
    List<LevelData> levels = [];

    // استخدام المفاتيح بدلاً من النصوص الثابتة
    List<String> levelNameKeys = [
      'levelName1', 'levelName2', 'levelName3', 'levelName4', 'levelName5',
      'levelName6', 'levelName7', 'levelName8', 'levelName9', 'levelName10',
      'levelName11', 'levelName12', 'levelName13', 'levelName14', 'levelName15',
      'levelName16', 'levelName17', 'levelName18', 'levelName19', 'levelName20',
    ];

    List<String> descriptionKeys = [
      'levelDesc1', 'levelDesc2', 'levelDesc3', 'levelDesc4', 'levelDesc5',
      'levelDesc6', 'levelDesc7', 'levelDesc8', 'levelDesc9', 'levelDesc10',
      'levelDesc11', 'levelDesc12', 'levelDesc13', 'levelDesc14', 'levelDesc15',
      'levelDesc16', 'levelDesc17', 'levelDesc18', 'levelDesc19', 'levelDesc20',
    ];

    List<Color> backgroundColors = [
      const Color(0xFF87CEEB),
      const Color(0xFF98FB98),
      const Color(0xFFDDA0DD),
      const Color(0xFF2F4F4F),
      const Color(0xFF8B4513),
      const Color(0xFFFFD700),
      const Color(0xFFE6E6FA),
      const Color(0xFF32CD32),
      const Color(0xFF1E90FF),
      const Color(0xFF000080),
      const Color(0xFF808080),
      const Color(0xFF8B0000),
      const Color(0xFFFF4500),
      const Color(0xFF2E8B57),
      const Color(0xFF4B0082),
      const Color(0xFF00CED1),
      const Color(0xFF228B22),
      const Color(0xFFDAA520),
      const Color(0xFFADD8E6),
      const Color(0xFFF0E68C),
    ];

    List<String> backgroundImages = [
      'assets/images/backgrounds/city.png',
      'assets/images/backgrounds/forest.png',
      'assets/images/backgrounds/desert.png',
      'assets/images/backgrounds/night.png',
      'assets/images/backgrounds/storm.png',
      'assets/images/backgrounds/snow.png',
      'assets/images/backgrounds/jungle.png',
      'assets/images/backgrounds/ocean.png',
      'assets/images/backgrounds/space.png',
      'assets/images/backgrounds/mountain.png',
      'assets/images/backgrounds/castle.png',
      'assets/images/backgrounds/volcano.png',
      'assets/images/backgrounds/lab.png',
      'assets/images/backgrounds/future.png',
      'assets/images/backgrounds/park.png',
      'assets/images/backgrounds/temple.png',
      'assets/images/backgrounds/arctic.png',
      'assets/images/backgrounds/mystery.png',
      'assets/images/backgrounds/cave.png',
      'assets/images/backgrounds/rainbow.png',
    ];

    for (int i = 1; i <= 100; i++) {
      final isRareBoss = _isRareBossLevel(i);
      final isFinalBoss = i == 100;

      final bossHealth = _calculateBossHealth(i, isRareBoss, isFinalBoss);
      final bossAttackSpeed = _calculateBossAttackSpeed(i, isRareBoss, isFinalBoss);

      levels.add(LevelData(
        levelNumber: i,
        nameKey: levelNameKeys[(i - 1) % levelNameKeys.length],
        descriptionKey: descriptionKeys[(i - 1) % descriptionKeys.length],
        targetScore: i * 150,
        obstacleSpeed: 0.015 + (i * 0.0015),
        obstacleFrequency: (2000 - (i * 15)).clamp(300, 2000),
        backgroundColor: backgroundColors[(i - 1) % backgroundColors.length],
        levelDuration: 120 + (i * 2),
        bossHealth: bossHealth,
        bossAttackSpeed: bossAttackSpeed,
        isRareBoss: isRareBoss,
        isFinalBoss: isFinalBoss,
        isUnlocked: unlockedLevels.contains(i),
        backgroundImage: backgroundImages[(i - 1) % backgroundImages.length],
      ));
    }

    return levels;
  }

  static Future<LevelData> getLevelData(int levelNumber) async {
    List<LevelData> levels = await getAllLevels();
    return levels.firstWhere(
          (level) => level.levelNumber == levelNumber,
      orElse: () => levels.first,
    );
  }

  static bool _isRareBossLevel(int level) {
    return level == 15 || level == 25 || level == 50 || level == 75 ||
        level == 90 || level == 91 || level == 92 || level == 93 ||
        level == 94 || level == 95 || level == 96 || level == 97 ||
        level == 98 || level == 99;
  }

  static int _calculateBossHealth(int level, bool isRareBoss, bool isFinalBoss) {
    int baseHealth = 100 + (level * 20);

    if (isFinalBoss) {
      return 5000;
    } else if (isRareBoss) {
      return (baseHealth * 1.5).toInt();
    } else {
      return baseHealth;
    }
  }

  static double _calculateBossAttackSpeed(int level, bool isRareBoss, bool isFinalBoss) {
    double baseAttackSpeed = 3.0 - (level * 0.02);

    if (isFinalBoss) {
      return 0.3;
    } else if (isRareBoss) {
      return baseAttackSpeed * 0.7;
    } else {
      return baseAttackSpeed.clamp(0.5, 3.0);
    }
  }

  String getBossImagePath() {
    if (isFinalBoss) {
      return 'assets/images/bosses/final_boss.png';
    } else if (isRareBoss) {
      final rareIndex = _getRareBossIndex(levelNumber);
      return 'assets/images/bosses/rare_boss${rareIndex + 1}.png';
    } else {
      final normalIndex = levelNumber % 5;
      return 'assets/images/bosses/boss${normalIndex + 1}.png';
    }
  }

  static int _getRareBossIndex(int level) {
    final rareLevels = [15, 25, 50, 75, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99];
    return rareLevels.indexOf(level) % 5;
  }

  @override
  String toString() {
    return 'Level $levelNumber: $nameKey';
  }
}