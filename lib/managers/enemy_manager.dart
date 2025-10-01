import 'dart:math';
import 'package:flutter/material.dart';
import '../models/obstacle.dart';

class EnemyManager {
  final Random _random = Random();

  Obstacle createGoomba(double speed) {
    return Obstacle(
      x: 1.1,
      y: 0.75,
      speed: speed,
      width: 0.08,
      height: 0.08,
      color: Colors.brown,
      type: ObstacleType.enemy,
      isEnemy: true,
      health: 1,
      maxHealth: 1,
      isMoving: true,
    );
  }

  Obstacle createMushroom(double speed) {
    return Obstacle(
      x: 1.1,
      y: 0.75,
      speed: speed * 1.2,
      width: 0.07,
      height: 0.09,
      color: Colors.red,
      type: ObstacleType.enemy,
      isEnemy: true,
      health: 2,
      maxHealth: 2,
      isMoving: true,
    );
  }

  Obstacle createKoopa(double speed) {
    return Obstacle(
      x: 1.1,
      y: 0.75,
      speed: speed * 0.8,
      width: 0.09,
      height: 0.1,
      color: Colors.green,
      type: ObstacleType.enemy,
      isEnemy: true,
      health: 3,
      maxHealth: 3,
      isMoving: true,
    );
  }

  Obstacle createRandomEnemy(double speed, int level) {
    final enemyType = _random.nextDouble();

    if (enemyType < 0.6) {
      return createGoomba(speed);
    } else if (enemyType < 0.9) {
      return createMushroom(speed);
    } else {
      return createKoopa(speed);
    }
  }
}