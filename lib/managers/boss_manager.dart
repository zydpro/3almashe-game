import 'dart:math';
import '../models/Boss.dart';

class BossManager {
  final Random _random = Random();

  Boss createBoss(int level, bool isRare, bool isFinal) {
    final health = _calculateBossHealth(level, isRare, isFinal);
    final attackSpeed = _calculateBossAttackSpeed(level, isRare, isFinal);
    final imagePath = _getBossImagePath(level, isRare, isFinal);

    return Boss(
      x: 0.5,
      y: 0.3,
      health: health,
      maxHealth: health,
      attackSpeed: attackSpeed,
      moveSpeed: 0.006 + (level * 0.0001), // ✅ سرعة متوازنة
      imagePath: imagePath,
      level: level,
      isRare: isRare,
      isFinalBoss: isFinal,
      isMovingRight: _random.nextBool(),
      isMovingUp: _random.nextBool(),
      verticalMoveSpeed: 0.003 + _random.nextDouble() * 0.003, // ✅ سرعات معقولة
      horizontalMoveSpeed: 0.004 + _random.nextDouble() * 0.004,
    );
  }

  int _calculateBossHealth(int level, bool isRare, bool isFinal) {
    int baseHealth = 80 + (level * 20); // ✅ صحة متوازنة

    if (isFinal) {
      return 3000; // ✅ صحة نهائية معقولة
    } else if (isRare) {
      return (baseHealth * 1.5).toInt(); // ✅ مضاعفة معقولة
    } else {
      return baseHealth;
    }
  }

  double _calculateBossAttackSpeed(int level, bool isRare, bool isFinal) {
    double baseAttackSpeed = 2.5 - (level * 0.02); // ✅ سرعة هجوم متوازنة

    if (isFinal) {
      return 0.8; // ✅ سرعة معقولة للبوس النهائي
    } else if (isRare) {
      return baseAttackSpeed * 0.8; // ✅ تحسين معقول
    } else {
      return baseAttackSpeed.clamp(0.5, 2.5); // ✅ حدود معقولة
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
    return rareLevels.indexOf(level) % 5;
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
}