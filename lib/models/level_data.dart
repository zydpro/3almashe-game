import 'package:flutter/material.dart';
import '../services/game_data_service.dart';

class LevelData {
  final int levelNumber;
  final String name;
  final String description;
  final int targetScore;
  final double obstacleSpeed;
  final int obstacleFrequency;
  final Color backgroundColor;
  final bool isUnlocked;
  final int levelDuration; // مدة المرحلة بالثواني
  final int bossHealth; // صحة الزعيم
  final double bossAttackSpeed; // سرعة هجوم الزعيم
  final bool isRareBoss; // هل الزعيم نادر؟
  final bool isFinalBoss; // هل الزعيم النهائي؟

  LevelData({
    required this.levelNumber,
    required this.name,
    required this.description,
    required this.targetScore,
    required this.obstacleSpeed,
    required this.obstacleFrequency,
    required this.backgroundColor,
    required this.isUnlocked,
    this.levelDuration = 120, // افتراضي 2 دقيقة
    required this.bossHealth,
    required this.bossAttackSpeed,
    this.isRareBoss = false,
    this.isFinalBoss = false,
  });

  // ✅ التصحيح: جعل الدالة async
  static Future<List<LevelData>> getAllLevels() async {
    List<int> unlockedLevels = await GameDataService.getUnlockedLevels();
    List<LevelData> levels = [];

    List<String> levelNames = [
      'البداية', 'التحدي الأول', 'المدينة المزدحمة', 'الليل المظلم', 'العاصفة',
      'الصحراء الحارة', 'الجبال الثلجية', 'الغابة المطيرة', 'المحيط الهائج', 'الفضاء الخارجي',
      // ... باقي الأسماء (اختصرت للتوضيح)
    ];

    List<String> descriptions = [
      'تعلم أساسيات اللعبة', 'عقبات أسرع وأكثر', 'تجنب الحشود', 'رؤية محدودة', 'تحدي الخبراء',
      // ... باقي الأوصاف
    ];

    List<Color> backgroundColors = [
      const Color(0xFF87CEEB), const Color(0xFF98FB98), const Color(0xFFDDA0DD),
      // ... باقي الألوان
    ];

    // Generate 100 levels
    for (int i = 1; i <= 100; i++) {
      final isRareBoss = _isRareBossLevel(i);
      final isFinalBoss = i == 100;

      final bossHealth = _calculateBossHealth(i, isRareBoss, isFinalBoss);
      final bossAttackSpeed = _calculateBossAttackSpeed(i, isRareBoss, isFinalBoss);

      levels.add(LevelData(
        levelNumber: i,
        name: levelNames[(i - 1) % levelNames.length],
        description: descriptions[(i - 1) % descriptions.length],
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
      ));
    }

    return levels;
  }

  // ✅ التصحيح: جعل الدالة async
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

  // الحصول على صورة الزعيم المناسبة للمستوى
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
}