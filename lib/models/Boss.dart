// lib/models/boss.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package.dart';
import 'character.dart';

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

  // حركة محسنة
  bool isMovingRight;
  bool isMovingUp;
  double verticalMoveSpeed;
  double horizontalMoveSpeed;
  final Random _random = Random();

  Boss({
    required this.x,
    required this.y,
    this.width = 0.15,
    this.height = 0.15,
    required this.health,
    required this.maxHealth,
    this.attackSpeed = 1.5,
    this.moveSpeed = 0.008,
    required this.imagePath,
    required this.level,
    this.isRare = false,
    this.isFinalBoss = false,
    this.isMovingRight = true,
    this.isMovingUp = true,
    this.verticalMoveSpeed = 0.004,
    this.horizontalMoveSpeed = 0.006,
  })  : projectiles = [],
        lastAttackTime = 0;

  void move() {
    // ✅ حركة أفقية محسنة مع حدود
    if (isMovingRight) {
      x += horizontalMoveSpeed;
      if (x > 0.8) { // ✅ حد أقصى للأفق
        isMovingRight = false;
        horizontalMoveSpeed = 0.004 + _random.nextDouble() * 0.004; // ✅ سرعة معقولة
      }
    } else {
      x -= horizontalMoveSpeed;
      if (x < 0.2) { // ✅ حد أدنى للأفق
        isMovingRight = true;
        horizontalMoveSpeed = 0.004 + _random.nextDouble() * 0.004;
      }
    }

    // ✅ حركة عمودية محسنة مع حدود
    if (isMovingUp) {
      y += verticalMoveSpeed;
      if (y > 0.6) { // ✅ حد أقصى للعمودي
        isMovingUp = false;
        verticalMoveSpeed = 0.003 + _random.nextDouble() * 0.003;
      }
    } else {
      y -= verticalMoveSpeed;
      if (y < 0.2) { // ✅ حد أدنى للعمودي
        isMovingUp = true;
        verticalMoveSpeed = 0.003 + _random.nextDouble() * 0.003;
      }
    }

    // ✅ حركة قطرية عشوائية ولكن بنسبة أقل
    if (_random.nextDouble() < 0.008) { // ✅ نسبة أقل
      isMovingRight = _random.nextBool();
      isMovingUp = _random.nextBool();

      // ✅ تحديث السرعات بحدود معقولة
      horizontalMoveSpeed = 0.004 + _random.nextDouble() * 0.004;
      verticalMoveSpeed = 0.003 + _random.nextDouble() * 0.003;
    }

    // ✅ التأكد من بقاء البوس ضمن الحدود
    x = x.clamp(0.15, 0.85);
    y = y.clamp(0.15, 0.65);
  }

  void attack(double currentTime) {
    if (currentTime - lastAttackTime > attackSpeed) {
      _createBalancedProjectiles();
      lastAttackTime = currentTime;
    }
  }

  // ✅ إطلاق مقذوفات متوازنة
  void _createBalancedProjectiles() {
    // ✅ عدد معقول من المقذوفات (1-3)
    int projectileCount = 1 + _random.nextInt(3);

    for (int i = 0; i < projectileCount; i++) {
      double directionX = -1.0; // ✅ دائماً باتجاه اللاعب
      double directionY = (_random.nextDouble() - 0.5) * 1.5; // ✅ انحراف معقول
      double speed = 0.008 + _random.nextDouble() * 0.006; // ✅ سرعة معقولة

      projectiles.add(Package(
        x: x,
        y: y + (_random.nextDouble() - 0.5) * 0.15, // ✅ انتشار معقول
        direction: directionX,
        verticalDirection: directionY,
        damage: (5 + level * 1).toInt(), // ✅ ضرر متوازن
        speed: speed,
        width: 0.025,
        height: 0.025,
      ));
    }

    // ✅ مقذوف خاص نادراً
    if (_random.nextDouble() < 0.15) { // ✅ نسبة أقل
      projectiles.add(Package(
        x: x,
        y: y,
        direction: -1.0,
        verticalDirection: 0.0,
        damage: (10 + level * 1).toInt(), // ✅ ضرر معقول
        speed: 0.015, // ✅ سرعة معقولة
        width: 0.035,
        height: 0.035,
      ));
    }
  }

  void updateProjectiles() {
    for (var projectile in projectiles) {
      projectile.move();
    }
    // ✅ تنظيف المقذوفات التي خرجت عن الشاشة
    projectiles.removeWhere((p) => p.x < -0.1 || p.x > 1.1 || p.y < -0.1 || p.y > 1.1 || !p.isActive);
  }

  void takeDamage(int damage) {
    health -= damage;
    if (health < 0) health = 0;
  }

  bool get isDead => health <= 0;

  double get healthPercentage => health / maxHealth;

  Rect get boundingBox => Rect.fromLTWH(
    x - width / 2,
    y - height / 2,
    width,
    height,
  );

  bool collidesWith(Character character) {
    final bossRect = boundingBox;
    final characterRect = character.boundingBox;
    return bossRect.overlaps(characterRect);
  }
}