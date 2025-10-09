import 'dart:math';
import '../models/Boss.dart';


class BossManager {
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
      moveSpeed: 0.008 + (level * 0.0002),
      imagePath: imagePath,
      level: level,
      isRare: isRare,
      isFinalBoss: isFinal,
      isMovingRight: Random().nextBool(),
      isMovingUp: Random().nextBool(),
      verticalMoveSpeed: 0.005 + Random().nextDouble() * 0.006,
      horizontalMoveSpeed: 0.006 + Random().nextDouble() * 0.008,
    );
  }

  int _calculateBossHealth(int level, bool isRare, bool isFinal) {
    int baseHealth = 100 + (level * 25);

    if (isFinal) {
      return 5000;
    } else if (isRare) {
      return (baseHealth * 1.8).toInt();
    } else {
      return baseHealth;
    }
  }

  double _calculateBossAttackSpeed(int level, bool isRare, bool isFinal) {
    double baseAttackSpeed = 2.0 - (level * 0.015);

    if (isFinal) {
      return 0.4;
    } else if (isRare) {
      return baseAttackSpeed * 0.6;
    } else {
      return baseAttackSpeed.clamp(0.3, 2.0);
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