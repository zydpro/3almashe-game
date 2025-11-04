// lib/models/obstacle.dart
import 'package:almashe_game/models/power_up_system.dart';
import 'package:flutter/material.dart';
import '../services/image_service.dart';
import 'enums.dart';

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

  bool get isStandable {
    return type == ObstacleType.groundLong ||
        imagePath == ImageService.brick ||
        imagePath == ImageService.platform;
  }

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

  // ✅ إضافة دوال toMap و fromMap
  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'speed': speed,
      'color': color.value,
      'type': type.toString(),
      'isWalkable': isWalkable,
      'isEnemy': isEnemy,
      'imagePath': imagePath,
      'health': health,
      'maxHealth': maxHealth,
      'isDead': isDead,
    };
  }

  factory Obstacle.fromMap(Map<String, dynamic> map) {
    return Obstacle(
      x: map['x'] ?? 0.0,
      y: map['y'] ?? 0.0,
      width: map['width'] ?? 0.08,
      height: map['height'] ?? 0.08,
      speed: map['speed'] ?? 0.015,
      color: Color(map['color'] ?? Colors.red.value),
      type: _parseObstacleType(map['type']),
      isWalkable: map['isWalkable'] ?? false,
      isEnemy: map['isEnemy'] ?? false,
      imagePath: map['imagePath'],
      health: map['health'] ?? 1,
      maxHealth: map['maxHealth'] ?? 1,
    );
  }

  Obstacle clone() {
    return Obstacle.fromMap(this.toMap());
  }

  static ObstacleType _parseObstacleType(String typeString) {
    switch (typeString) {
      case 'ObstacleType.groundLong':
        return ObstacleType.groundLong;
      case 'ObstacleType.groundShort':
        return ObstacleType.groundShort;
      case 'ObstacleType.groundWide':
        return ObstacleType.groundWide;
      case 'ObstacleType.skyLong':
        return ObstacleType.skyLong;
      case 'ObstacleType.skyShort':
        return ObstacleType.skyShort;
      case 'ObstacleType.skyWide':
        return ObstacleType.skyWide;
      case 'ObstacleType.flyingEnemy':
        return ObstacleType.flyingEnemy;
      // case 'ObstacleType.groundEnemy':
      //   return ObstacleType.groundEnemy;
      default:
        return ObstacleType.groundLong;
    }
  }

  void move([double speedMultiplier = 1.0]) {
    x -= speed * speedMultiplier;
  }

  bool isOffScreen() {
    if (speed > 0) {
      return x < -0.3;
    } else if (speed < 0) {
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

  // ✅ إضافة خاصية isOnObstacle
  bool get isOnObstacle =>
      type == ObstacleType.groundLong ||
          type == ObstacleType.groundShort ||
          type == ObstacleType.groundWide ||
          imagePath == ImageService.brick ||
          imagePath == ImageService.pipe ||
          imagePath == ImageService.platform;

  void takeDamage(int damage) {
    health -= damage;
    if (health < 0) health = 0;
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
  PowerUpType type;
  String? imagePath;
  bool isAdvanced;
  AdvancedPowerUp? advancedData;

  PowerUp({
    required this.x,
    required this.y,
    this.width = 0.06,
    this.height = 0.06,
    this.speed = 0.012,
    this.color = Colors.amber,
    required this.type,
    this.imagePath,
    this.isAdvanced = false,
    this.advancedData,
  });



  // ✅ إضافة دوال toMap و fromMap
  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'speed': speed,
      'color': color.value,
      'type': type.toString(),
      'imagePath': imagePath,
    };
  }

  factory PowerUp.fromMap(Map<String, dynamic> map) {
    return PowerUp(
      x: map['x'] ?? 0.0,
      y: map['y'] ?? 0.0,
      width: map['width'] ?? 0.06,
      height: map['height'] ?? 0.06,
      speed: map['speed'] ?? 0.012,
      color: Color(map['color'] ?? Colors.amber.value),
      type: _parsePowerUpType(map['type']),
      imagePath: map['imagePath'],
    );
  }

  PowerUp clone() {
    return PowerUp.fromMap(this.toMap());
  }

  static PowerUpType _parsePowerUpType(String typeString) {
    switch (typeString) {
      case 'PowerUpType.health':
        return PowerUpType.health;
      case 'PowerUpType.shield':
        return PowerUpType.shield;
      case 'PowerUpType.points':
        return PowerUpType.points;
      case 'PowerUpType.doublePoints':
        return PowerUpType.doublePoints;
      case 'PowerUpType.slowMotion':
        return PowerUpType.slowMotion;
      case 'PowerUpType.speedBoost':
        return PowerUpType.speedBoost;
      case 'PowerUpType.slowEnemies':
        return PowerUpType.slowEnemies;
      case 'PowerUpType.coin':
        return PowerUpType.coin;
      case 'PowerUpType.slowCharacter':
        return PowerUpType.slowCharacter;
      default:
        return PowerUpType.points;
    }
  }

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