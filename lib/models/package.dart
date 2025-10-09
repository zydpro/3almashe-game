// lib/models/package.dart
import 'package:flutter/material.dart';
import 'obstacle.dart';
import 'Boss.dart';

class Package {
  double x;
  double y;
  double width;
  double height;
  double speed;
  double direction;
  double verticalDirection;
  int damage;
  bool isActive;

  Package({
    required this.x,
    required this.y,
    this.width = 0.04,
    this.height = 0.04,
    this.speed = 0.02,
    this.direction = 1.0,
    this.verticalDirection = 0.0,
    this.damage = 10,
    this.isActive = true,
  });

  void move() {
    x += speed * direction;
    y += speed * verticalDirection * 0.5;
  }

  bool isOffScreen() => x < -0.2 || x > 1.2 || y < -0.2 || y > 1.2;

  bool collidesWith(Obstacle obstacle) {
    final packageRect = boundingBox;
    final obstacleRect = obstacle.boundingBox;
    return packageRect.overlaps(obstacleRect);
  }

  bool collidesWithBoss(Boss boss) {
    final packageRect = boundingBox;
    final bossRect = boss.boundingBox;
    return packageRect.overlaps(bossRect);
  }

  Rect get boundingBox => Rect.fromLTWH(
    x - width / 2,
    y - height / 2,
    width,
    height,
  );
}