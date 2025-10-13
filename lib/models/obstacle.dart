// lib/models/obstacle.dart
import 'package:flutter/material.dart';
import 'enums.dart';
import 'package.dart';

class Obstacle {
  double x;
  double y;
  double width;
  double height;
  double speed;
  Color color;
  IconData icon;
  String? imagePath;
  ObstacleType type;
  bool isWalkable;
  bool isEnemy;
  bool isBoss;
  int health;
  int maxHealth;
  double attackSpeed;
  bool isMoving;

  Obstacle({
    required this.x,
    required this.y,
    this.width = 0.08,
    this.height = 0.08,
    this.speed = 0.015,
    this.color = Colors.red,
    this.icon = Icons.warning,
    this.imagePath, // ✅ إضافة هذا
    this.type = ObstacleType.groundLong,
    this.isWalkable = false,
    this.isEnemy = false,
    this.isBoss = false,
    this.health = 1,
    this.maxHealth = 1,
    this.attackSpeed = 1.0,
    this.isMoving = false,
  });

  void move() {
    x -= speed; // ✅ هذا يحرك المنصة نحو اليسار (نحو الشخصية)
    // يمكنك إضافة طباعة للتأكد من الحركة
    if (speed > 0 && x % 0.1 < 0.01) {
      // print('🔄 Platform moving - X: ${x.toStringAsFixed(3)}, Speed: $speed');
    }
  }

  bool isOffScreen() {
    // ✅ للمنصات المتحركة نحو اليسار (سرعة موجبة)
    if (speed > 0) {
      return x < -0.3;
    }
    // ✅ للمنصات المتحركة نحو اليمين (سرعة سالبة)
    else if (speed < 0) {
      return x > 1.3;
    }
    return x < -0.2;
  }

  void reset() => x = 1.2;

  bool get isSkyObstacle =>
      type == ObstacleType.skyLong ||
          type == ObstacleType.skyShort ||
          type == ObstacleType.skyWide;

  bool get isGroundObstacle =>
      type == ObstacleType.groundLong ||
          type == ObstacleType.groundShort ||
          type == ObstacleType.groundWide;

  bool get isEnemyObstacle => isEnemy;

  bool get isBossObstacle => isBoss;

  void takeDamage(int damage) {
    health -= damage;
    if (health < 0) health = 0;
    // print('💥 ${isEnemy ? 'Enemy' : 'Obstacle'} took $damage damage! Health: $health/$maxHealth');
  }

  bool get isDead => health <= 0;

  Rect get boundingBox => Rect.fromLTWH(
    x - width / 2,
    y - height / 2,
    width,
    height,
  );
}

class PowerUp {
  double x;
  double y;
  double width;
  double height;
  double speed;
  Color color;
  IconData icon;
  PowerUpType type;
  String? imagePath;

  PowerUp({
    required this.x,
    required this.y,
    this.width = 0.06,
    this.height = 0.06,
    this.speed = 0.012,
    this.color = Colors.amber,
    this.icon = Icons.star,
    this.type = PowerUpType.points,
    this.imagePath,
  });

  void move() => x -= speed;

  bool isOffScreen() => x < -0.2;

  void reset() => x = 1.2;

  Rect get boundingBox => Rect.fromLTWH(
    x - width / 2,
    y - height / 2,
    width,
    height,
  );
}

class ComboObstacle {
  final List<Obstacle> obstacles;
  final bool hasGap;
  final double gapPosition;

  ComboObstacle({
    required this.obstacles,
    this.hasGap = false,
    this.gapPosition = 0.5,
  });

  void move() {
    for (final obstacle in obstacles) {
      obstacle.move();
    }
  }

  bool isOffScreen() {
    return obstacles.every((obstacle) => obstacle.isOffScreen());
  }
}