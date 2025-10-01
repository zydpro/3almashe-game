import 'package:flutter/material.dart';

enum ObstacleType {
  groundLong,    // عقبة أرضية طويلة
  groundShort,   // عقبة أرضية قصيرة
  groundWide,    // عقبة أرضية عريضة
  skyLong,       // عقبة سماوية طويلة
  skyShort,      // عقبة سماوية قصيرة
  skyWide,       // عقبة سماوية عريضة
  comboSequence, // سلسلة عوائق متتابعة
  enemy,         // عدو أرضي
  flyingEnemy,   // عدو طائر
  boss,          // زعيم
}

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
  bool isWalkable; // يمكن المشي عليها
  bool isEnemy; // هل هو عدو
  bool isBoss; // هل هو زعيم
  int health; // حياة العدو/الزعيم
  int maxHealth; // أقصى حياة
  double attackSpeed; // سرعة الهجوم
  bool isMoving; // هل يتحرك

  Obstacle({
    required this.x,
    required this.y,
    this.width = 0.08,
    this.height = 0.08,
    this.speed = 0.015,
    this.color = Colors.red,
    this.icon = Icons.warning,
    this.imagePath,
    this.type = ObstacleType.groundLong,
    this.isWalkable = false,
    this.isEnemy = false,
    this.isBoss = false,
    this.health = 1,
    this.maxHealth = 1,
    this.attackSpeed = 1.0,
    this.isMoving = false,
  });

  void move() => x -= speed;

  bool isOffScreen() => x < -0.2;

  void reset() => x = 1.2;

  // التحقق إذا كانت عقبة سماوية
  bool get isSkyObstacle =>
      type == ObstacleType.skyLong ||
          type == ObstacleType.skyShort ||
          type == ObstacleType.skyWide;

  // التحقق إذا كانت عقبة أرضية
  bool get isGroundObstacle =>
      type == ObstacleType.groundLong ||
          type == ObstacleType.groundShort ||
          type == ObstacleType.groundWide;

  // التحقق إذا كان عدو
  bool get isEnemyObstacle => isEnemy;

  // التحقق إذا كان زعيم
  bool get isBossObstacle => isBoss;

  // تلقي ضرر
  void takeDamage(int damage) {
    health -= damage;
    if (health < 0) health = 0;
  }

  // التحقق إذا مات
  bool get isDead => health <= 0;
}

enum PowerUpType { points, shield, slowMotion, doublePoints, health }

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
}

// === فئة جديدة للطرد الذي يرميه اللاعب ===
class Package {
  double x;
  double y;
  double width;
  double height;
  double speed;
  double direction; // اتجاه الحركة (1 لليمين، -1 لليسار)
  int damage;
  bool isActive;

  Package({
    required this.x,
    required this.y,
    this.width = 0.04,
    this.height = 0.04,
    this.speed = 0.02,
    this.direction = 1.0,
    this.damage = 10,
    this.isActive = true,
  });

  void move() {
    x += speed * direction;
  }

  bool isOffScreen() => x < -0.2 || x > 1.2;

  // التحقق من التصادم مع عدو
  bool collidesWith(Obstacle obstacle) {
    final packageRect = Rect.fromLTWH(
      x - width / 2,
      y - height,
      width,
      height,
    );

    final obstacleRect = Rect.fromLTWH(
      obstacle.x - obstacle.width / 2,
      obstacle.y - obstacle.height,
      obstacle.width,
      obstacle.height,
    );

    return packageRect.overlaps(obstacleRect);
  }
}

// === فئة جديدة للعوائق المتتابعة ===
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

// === فئة جديدة للزعيم ===
class Boss {
  double x;
  double y;
  double width;
  double height;
  int health;
  int maxHealth;
  double attackSpeed;
  double moveSpeed;
  String imagePath;
  int level;
  bool isRare;
  bool isFinalBoss;
  List<Package> projectiles;
  double lastAttackTime;
  bool isMovingRight;

  Boss({
    required this.x,
    required this.y,
    this.width = 0.15,
    this.height = 0.15,
    required this.health,
    required this.maxHealth,
    this.attackSpeed = 2.0,
    this.moveSpeed = 0.005,
    required this.imagePath,
    required this.level,
    this.isRare = false,
    this.isFinalBoss = false,
    this.isMovingRight = true,
  })  : projectiles = [],
        lastAttackTime = 0;

  void move() {
    if (isMovingRight) {
      x += moveSpeed;
      if (x > 0.8) isMovingRight = false;
    } else {
      x -= moveSpeed;
      if (x < 0.2) isMovingRight = true;
    }
  }

  void attack(double currentTime) {
    if (currentTime - lastAttackTime > attackSpeed) {
      projectiles.add(Package(
        x: x,
        y: y - height / 2,
        direction: -1.0, // يتجه نحو اللاعب
        damage: (10 + level * 2).toInt(),
        speed: 0.015 + (level * 0.001),
      ));
      lastAttackTime = currentTime;
    }
  }

  void updateProjectiles() {
    for (var projectile in projectiles) {
      projectile.move();
    }
    projectiles.removeWhere((p) => p.isOffScreen() || !p.isActive);
  }

  void takeDamage(int damage) {
    health -= damage;
    if (health < 0) health = 0;
  }

  bool get isDead => health <= 0;

  double get healthPercentage => health / maxHealth;
}