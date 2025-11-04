import 'dart:math';
import '../models/Boss.dart';
import '../models/character.dart';

class BossManager {
  final Random _random = Random();

  Boss createBoss(int level, bool isRare, bool isFinal) {
    final health = _calculateBossHealth(level, isRare, isFinal);
    final attackSpeed = _calculateBossAttackSpeed(level, isRare, isFinal);
    final imagePath = _getBossImagePath(level, isRare, isFinal);

    return Boss(
      x: 0.5,
      y: 0.3,
      width: 0.10, // ✅ الحجم المصغر
      height: 0.10, // ✅ الحجم المصغر
      health: health,
      maxHealth: health,
      attackSpeed: attackSpeed,
      moveSpeed: 0.012 + (level * 0.0002), // ✅ سرعة متوازنة
      imagePath: imagePath,
      level: level,
      isRare: isRare,
      isFinalBoss: isFinal,
      // ✅ إزالة الـ parameters غير الموجودة في Boss constructor
    );
  }

  int _calculateBossHealth(int level, bool isRare, bool isFinal) {
    int baseHealth = 100 + (level * 25); // ✅ صحة متوازنة

    if (isFinal) {
      return 5000; // ✅ صحة نهائية معقولة
    } else if (isRare) {
      return (baseHealth * 1.5).toInt(); // ✅ مضاعفة معقولة
    } else {
      return baseHealth;
    }
  }

  double _calculateBossAttackSpeed(int level, bool isRare, bool isFinal) {
    double baseAttackSpeed = 1.5 - (level * 0.01); // ✅ سرعة هجوم متوازنة

    if (isFinal) {
      return 0.5; // ✅ سرعة معقولة للبوس النهائي
    } else if (isRare) {
      return baseAttackSpeed * 0.7; // ✅ تحسين معقول
    } else {
      return baseAttackSpeed.clamp(0.3, 1.5); // ✅ حدود معقولة
    }
  }

  String _getBossImagePath(int level, bool isRare, bool isFinal) {
    if (isFinal) {
      return 'assets/images/bosses/final_boss.png';
    } else if (isRare) {
      final rareIndex = _getRareBossIndex(level);
      return 'assets/images/bosses/rare_boss${rareIndex + 1}.png';
    } else {
      final normalIndex = level % 5;
      return 'assets/images/bosses/boss${normalIndex + 1}.png';
    }
  }

  int _getRareBossIndex(int level) {
    final rareLevels = [15, 25, 50, 75, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99];
    final index = rareLevels.indexOf(level);
    return index >= 0 ? index % 5 : 0;
  }

  void updateBoss(Boss boss, double deltaTime) {
    boss.move();
    boss.updateProjectiles();
  }

  bool isBossDefeated(Boss boss) {
    return boss.isDead;
  }

  double getBossHealthPercentage(Boss boss) {
    return boss.healthPercentage;
  }

  // ✅ دالة جديدة لتعيين هدف البوس
  void setBossTarget(Boss boss, Character character) {
    boss.setTarget(character);
  }

  // ✅ دالة جديدة للحصول على إحصائيات البوس
  Map<String, dynamic> getBossStats(Boss boss) {
    return {
      'health': boss.health,
      'maxHealth': boss.maxHealth,
      'healthPercentage': boss.healthPercentage,
      'level': boss.level,
      'isRare': boss.isRare,
      'isFinalBoss': boss.isFinalBoss,
      'projectileCount': boss.projectiles.length,
      'effects': boss.getEffectStatus(),
    };
  }

  // ✅ دالة جديدة لإنشاء بوس بناءً على التقدم في المستوى
  Boss createBossForProgress(int level, double progressPercentage) {
    bool isRare = _shouldSpawnRareBoss(level, progressPercentage);
    bool isFinal = level >= 100 && progressPercentage >= 0.95;

    return createBoss(level, isRare, isFinal);
  }

  bool _shouldSpawnRareBoss(int level, double progressPercentage) {
    // ✅ فرصة ظهور بوس نادر بناءً على المستوى والتقدم
    double rareChance = 0.0;

    if (level >= 90) {
      rareChance = 0.4;
    } else if (level >= 50) {
      rareChance = 0.25;
    } else if (level >= 25) {
      rareChance = 0.15;
    } else if (level >= 15) {
      rareChance = 0.1;
    }

    // ✅ زيادة الفرصة مع التقدم في المستوى
    rareChance += progressPercentage * 0.2;

    return _random.nextDouble() < rareChance;
  }

  // ✅ دالة جديدة لضبط صعوبة البوس بناءً على أداء اللاعب
  void adjustBossDifficulty(Boss boss, int playerScore, int maxScore) {
    final performanceRatio = playerScore / maxScore;

    if (performanceRatio > 0.9) {
      // ✅ اللاعب ممتاز - زيادة صعوبة البوس
      boss.health = (boss.health * 1.2).toInt();
      boss.maxHealth = (boss.maxHealth * 1.2).toInt();
      boss.attackSpeed *= 0.8; // هجوم أسرع
    } else if (performanceRatio < 0.5) {
      // ✅ اللاعب ضعيف - تقليل صعوبة البوس
      boss.health = (boss.health * 0.8).toInt();
      boss.maxHealth = (boss.maxHealth * 0.8).toInt();
      boss.attackSpeed *= 1.2; // هجوم أبطأ
    }
  }

  // ✅ دالة جديدة للتحقق من قابلية ظهور البوس
  bool canSpawnBoss(int level, double progressPercentage, int timeElapsed, int levelDuration) {
    // ✅ شروط ظهور البوس
    final minProgress = 0.7; // 70% تقدم كحد أدنى
    final minTime = levelDuration * 0.6; // 60% من الوقت المحدد

    return progressPercentage >= minProgress &&
        timeElapsed >= minTime &&
        level >= 3; // مستوى 3 كحد أدنى
  }

  // ✅ دالة جديدة للحصول على معلومات البوس للعرض
  Map<String, dynamic> getBossDisplayInfo(Boss boss) {
    return {
      'name': _getBossName(boss.level, boss.isRare, boss.isFinalBoss),
      'level': boss.level,
      'health': '${boss.health}/${boss.maxHealth}',
      'healthPercentage': boss.healthPercentage,
      'type': _getBossType(boss.isRare, boss.isFinalBoss),
      'difficulty': _getBossDifficulty(boss.level),
    };
  }

  String _getBossName(int level, bool isRare, bool isFinal) {
    if (isFinal) return 'الزعيم النهائي';
    if (isRare) return 'زعيم نادر ${level}';
    return 'زعيم ${level}';
  }

  String _getBossType(bool isRare, bool isFinal) {
    if (isFinal) return 'نهائي';
    if (isRare) return 'نادر';
    return 'عادي';
  }

  String _getBossDifficulty(int level) {
    if (level >= 80) return 'أسطوري';
    if (level >= 50) return 'صعب';
    if (level >= 25) return 'متوسط';
    return 'سهل';
  }
}