import 'dart:math';
import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../models/obstacle.dart';

class ObstacleSpawner {
  final Random _random = Random();

  // توليد عوائق متتابعة
  List<Obstacle> spawnComboSequence(double speed) {
    final obstacles = <Obstacle>[];
    final sequenceLength = _random.nextInt(3) + 2; // 2 إلى 4 عوائق

    for (int i = 0; i < sequenceLength; i++) {
      final hasGap = i < sequenceLength - 1 && _random.nextDouble() < 0.3;

      obstacles.add(Obstacle(
        x: 1.1 + (i * 0.3), // تباعد بين العوائق
        y: hasGap ? 0.6 : 0.75, // فراغ في المنتصف
        speed: speed,
        width: hasGap ? 0.06 : 0.1,
        height: hasGap ? 0.06 : 0.1,
        type: hasGap ? ObstacleType.skyShort : ObstacleType.groundLong,
        color: hasGap ? Colors.blue : Colors.red,
      ));
    }

    return obstacles;
  }

  // توليد عوائق يمكن المشي عليها
  Obstacle spawnWalkableObstacle(double speed) {
    return Obstacle(
      x: 1.1,
      y: 0.75,
      speed: speed,
      width: 0.15,
      height: 0.08,
      type: ObstacleType.groundWide,
      color: Colors.green,
      isWalkable: true,
    );
  }

  // توليد عوائق سماوية تحتاج انحناء
  Obstacle spawnSkyObstacle(double speed) {
    final obstacleType = _random.nextDouble();
    ObstacleType type;
    double width, height;

    if (obstacleType < 0.33) {
      type = ObstacleType.skyLong;
      width = 0.08;
      height = 0.08;
    } else if (obstacleType < 0.66) {
      type = ObstacleType.skyShort;
      width = 0.05;
      height = 0.05;
    } else {
      type = ObstacleType.skyWide;
      width = 0.12;
      height = 0.06;
    }

    return Obstacle(
      x: 1.1,
      y: 0.45 + _random.nextDouble() * 0.2,
      speed: speed,
      width: width,
      height: height,
      type: type,
      color: Colors.purple,
    );
  }

  // التحقق إذا كان يمكن إضافة عقبة جديدة
  bool canSpawnObstacle(List<Obstacle> currentObstacles, int maxObstacles) {
    return currentObstacles.length < maxObstacles;
  }

  // الحصول على وقت الانتظار التالي
  Duration getNextSpawnTime(int level) {
    final baseTime = 1200 - (level * 50); // يقل الوقت مع زيادة المستوى
    final randomVariation = _random.nextInt(400) - 200; // تغيير عشوائي
    final spawnTime = (baseTime + randomVariation).clamp(400, 1800);

    return Duration(milliseconds: spawnTime);
  }
}