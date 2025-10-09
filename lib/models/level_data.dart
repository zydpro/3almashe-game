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
  final int levelDuration;
  final int bossHealth;
  final double bossAttackSpeed;
  final bool isRareBoss;
  final bool isFinalBoss;
  final String backgroundImage;

  LevelData({
    required this.levelNumber,
    required this.name,
    required this.description,
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

  static Future<List<LevelData>> getAllLevels() async {
    List<int> unlockedLevels = await GameDataService.getUnlockedLevels();
    List<LevelData> levels = [];

    List<String> levelNames = [
      'البداية', 'التحدي الأول', 'المدينة المزدحمة', 'الليل المظلم', 'العاصفة',
      'الصحراء الحارة', 'الجبال الثلجية', 'الغابة المطيرة', 'المحيط الهائج', 'الفضاء الخارجي',
      'المتاهة', 'القلعة القديمة', 'البركان', 'الوادي السري', 'المختبر',
      'المدينة المستقبلية', 'الحديقة الجوراسية', 'المعبد الضائع', 'القطب الشمالي', 'الصحراء الغامضة',
    ];

    List<String> descriptions = [
      'تعلم أساسيات اللعبة',
      'عقبات أسرع وأكثر',
      'تجنب الحشود',
      'رؤية محدودة',
      'تحدي الخبراء',
      'حرارة عالية',
      'ثلوج وبرودة',
      'أمطار وغابات',
      'أمواج عاتية',
      'انعدام الجاذبية',
      'طرق متشابكة',
      'أجواء تاريخية',
      'حمم بركانية',
      'أسرار مخفية',
      'تجارب علمية',
      'تكنولوجيا متطورة',
      'ديناصورات عملاقة',
      'كنوز قديمة',
      'جليد أبدي',
      'أساطير الصحراء',
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
    return 'Level $levelNumber: $name';
  }
}