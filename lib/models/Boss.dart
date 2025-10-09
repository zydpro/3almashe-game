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

  // حركة متقدمة في جميع الاتجاهات
  bool isMovingRight;
  bool isMovingUp;
  double verticalMoveSpeed;
  double horizontalMoveSpeed;

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
    this.verticalMoveSpeed = 0.006,
    this.horizontalMoveSpeed = 0.008,
  })  : projectiles = [],
        lastAttackTime = 0;

  void move() {
    // حركة أفقية محسنة
    if (isMovingRight) {
      x += horizontalMoveSpeed;
      if (x > 0.85) {
        isMovingRight = false;
        horizontalMoveSpeed = 0.005 + Random().nextDouble() * 0.01;
      }
    } else {
      x -= horizontalMoveSpeed;
      if (x < 0.15) {
        isMovingRight = true;
        horizontalMoveSpeed = 0.005 + Random().nextDouble() * 0.01;
      }
    }

    // حركة عمودية محسنة
    if (isMovingUp) {
      y += verticalMoveSpeed;
      if (y > 0.65) {
        isMovingUp = false;
        verticalMoveSpeed = 0.004 + Random().nextDouble() * 0.008;
      }
    } else {
      y -= verticalMoveSpeed;
      if (y < 0.15) {
        isMovingUp = true;
        verticalMoveSpeed = 0.004 + Random().nextDouble() * 0.008;
      }
    }

    // حركة قطرية عشوائية أحياناً
    if (Random().nextDouble() < 0.02) {
      isMovingRight = Random().nextBool();
      isMovingUp = Random().nextBool();
    }
  }

  void attack(double currentTime) {
    if (currentTime - lastAttackTime > attackSpeed) {
      _createMultipleProjectiles();
      lastAttackTime = currentTime;
    }
  }

  // إطلاق مقذوفات متعددة باتجاهات مختلفة
  void _createMultipleProjectiles() {
    final random = Random();

    // مقذوفات متعددة (3-5 مقذوفات)
    int projectileCount = 3 + random.nextInt(3);

    for (int i = 0; i < projectileCount; i++) {
      double directionX = -1.0;
      double directionY = (random.nextDouble() - 0.5) * 2.0;
      double speed = 0.012 + random.nextDouble() * 0.01;

      projectiles.add(Package(
        x: x,
        y: y + (random.nextDouble() - 0.5) * 0.2,
        direction: directionX,
        verticalDirection: directionY,
        damage: (8 + level * 1).toInt(),
        speed: speed,
        width: 0.03,
        height: 0.03,
      ));
    }

    // مقذوف خاص نحو موقع اللاعب أحياناً
    if (random.nextDouble() < 0.3) {
      projectiles.add(Package(
        x: x,
        y: y,
        direction: -1.0,
        verticalDirection: 0.0,
        damage: (15 + level * 2).toInt(),
        speed: 0.02,
        width: 0.04,
        height: 0.04,
      ));
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