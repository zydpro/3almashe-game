// lib/managers/enemy_manager.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/obstacle.dart';
import '../models/attack.dart';
import '../models/enums.dart';
import '../services/image_service.dart';

class EnemyManager {
  final Random _random = Random();
  double _gameTime = 0.0;

  // تحديث الوقت للحركات التموجية
  void updateGameTime(double deltaTime) {
    _gameTime += deltaTime;
  }

  // إنشاء عدو Goomba (عدو أرضي عادي)
  Obstacle createGoomba(double speed, int level) {
    return Obstacle(
      x: 1.1 + _random.nextDouble() * 0.2,
      y: 0.75,
      width: 0.08,
      height: 0.08,
      speed: speed * (0.9 + _random.nextDouble() * 0.3),
      color: Colors.brown,
      icon: Icons.person,
      imagePath: ImageService.enemyGoomba,
      type: ObstacleType.enemy,
      isWalkable: false,
      isEnemy: true,
      isBoss: false,
      health: 1,
      maxHealth: 1,
      attackSpeed: 1.0,
      isMoving: true,
    );
  }

  // إنشاء عدو Mushroom (عدو أرضي قوي)
  Obstacle createMushroom(double speed, int level) {
    return Obstacle(
      x: 1.1 + _random.nextDouble() * 0.2,
      y: 0.75,
      width: 0.07,
      height: 0.09,
      speed: speed * (1.0 + _random.nextDouble() * 0.4),
      color: Colors.red,
      icon: Icons.psychology,
      imagePath: ImageService.enemyMushroom,
      type: ObstacleType.enemy,
      isWalkable: false,
      isEnemy: true,
      isBoss: false,
      health: 2 + (level ~/ 5), // يزداد صحة مع المستوى
      maxHealth: 2 + (level ~/ 5),
      attackSpeed: 0.8,
      isMoving: true,
    );
  }

  // إنشاء عدو Koopa (عدو أرضي قوي جداً)
  Obstacle createKoopa(double speed, int level) {
    return Obstacle(
      x: 1.1 + _random.nextDouble() * 0.2,
      y: 0.75,
      width: 0.09,
      height: 0.1,
      speed: speed * (0.7 + _random.nextDouble() * 0.3),
      color: Colors.green,
      icon: Icons.security,
      imagePath: ImageService.enemyKoopa,
      type: ObstacleType.enemy,
      isWalkable: false,
      isEnemy: true,
      isBoss: false,
      health: 3 + (level ~/ 3), // يزداد صحة مع المستوى
      maxHealth: 3 + (level ~/ 3),
      attackSpeed: 0.6,
      isMoving: true,
    );
  }

// إنشاء عدو طائر (Flying Enemy) - مصححة
  Obstacle createFlyingEnemy(double speed, int level) {
    // ✅ تحديد مناطق ارتفاع مختلفة بشكل عشوائي مع الأنواع الصحيحة
    final List<Map<String, dynamic>> heightZones = [
      {'min': 0.3, 'max': 0.45, 'name': 'منخفض'},    // منطقة منخفضة
      {'min': 0.45, 'max': 0.65, 'name': 'متوسط'},  // منطقة متوسطة
      {'min': 0.65, 'max': 0.8, 'name': 'مرتفع'},   // منطقة مرتفعة
    ];

    // ✅ اختيار منطقة عشوائية
    final zone = heightZones[_random.nextInt(heightZones.length)];

    // ✅ تحويل القيم إلى double بشكل صريح
    final double minHeight = (zone['min'] as num).toDouble();
    final double maxHeight = (zone['max'] as num).toDouble();
    final String zoneName = zone['name'] as String;

    final flyingHeight = minHeight + _random.nextDouble() * (maxHeight - minHeight);
    final startX = 1.1 + _random.nextDouble() * 0.3;

    print('🦅 العدو الطائر ظهر في المنطقة $zoneName - '
        'الارتفاع: ${flyingHeight.toStringAsFixed(3)}');

    return Obstacle(
      x: startX,
      y: flyingHeight,
      width: 0.07,
      height: 0.07,
      speed: speed * (1.2 + _random.nextDouble() * 0.4),
      color: Colors.purple,
      icon: Icons.flight,
      imagePath: ImageService.enemyFlying,
      type: ObstacleType.flyingEnemy,
      isWalkable: false,
      isEnemy: true,
      isBoss: false,
      health: 1 + (level ~/ 7),
      maxHealth: 1 + (level ~/ 7),
      attackSpeed: 1.5,
      isMoving: true,
    );
  }

  // إنشاء عدو عشوائي بناءً على المستوى
  Obstacle createRandomEnemy(double speed, int level) {
    final enemyChance = _random.nextDouble();

    // ✅ زيادة فرصة ظهور العدو الطائر مع المستوى
    double flyingChance = 0.0;
    if (level >= 15) flyingChance = 0.5;
    else if (level >= 10) flyingChance = 0.4;
    else if (level >= 7) flyingChance = 0.3;
    else if (level >= 5) flyingChance = 0.2;
    else if (level >= 3) flyingChance = 0.15;

    // ✅ تحقق من ظهور عدو طائر
    if (flyingChance > 0 && enemyChance < flyingChance) {
      return createFlyingEnemy(speed, level);
    }

    // أعداء أرضية عادية مع توزيع مختلف حسب المستوى
    final groundEnemyType = _random.nextDouble();
    double goombaChance = 0.6;
    double mushroomChance = 0.3;
    double koopaChance = 0.1;

    // تعديل التوزيع مع زيادة المستوى
    if (level >= 8) {
      goombaChance = 0.4;
      mushroomChance = 0.4;
      koopaChance = 0.2;
    } else if (level >= 5) {
      goombaChance = 0.5;
      mushroomChance = 0.35;
      koopaChance = 0.15;
    }

    if (groundEnemyType < goombaChance) {
      return createGoomba(speed, level);
    } else if (groundEnemyType < goombaChance + mushroomChance) {
      return createMushroom(speed, level);
    } else {
      return createKoopa(speed, level);
    }
  }

  // تحديث كل الأعداء
  void updateEnemies(List<Obstacle> enemies, double characterX, double characterY) {
    for (var enemy in enemies) {
      if (enemy.isMoving) {
        enemy.move();
      }

      // تحريك الأعداء الطائرين بشكل تموجي
      if (enemy.type == ObstacleType.flyingEnemy) {
        _updateFlyingEnemy(enemy);
      }

      // تحريك الأعداء الذكية نحو اللاعب (للمستويات المتقدمة)
      if (enemy.health > 2 && _random.nextDouble() < 0.02) {
        _updateSmartEnemy(enemy, characterX, characterY);
      }
    }
  }

// تحديث حركة العدو الطائر بشكل تموجي - محسنة
  void _updateFlyingEnemy(Obstacle enemy) {
    // ✅ تحديد نطاق الحركة بناءً على الارتفاع الحالي
    double minY, maxY;

    if (enemy.y < 0.5) {
      // المنطقة المنخفضة: حركة محدودة
      minY = 0.3;
      maxY = 0.5;
    } else if (enemy.y < 0.7) {
      // المنطقة المتوسطة: حركة متوسطة
      minY = 0.45;
      maxY = 0.65;
    } else {
      // المنطقة المرتفعة: حركة واسعة
      minY = 0.6;
      maxY = 0.8;
    }

    // ✅ حركة تموجية باستخدام دالة الجيب
    final wave = sin(_gameTime * 3 + enemy.x * 10) * 0.02;
    final newY = enemy.y + wave;

    // ✅ التأكد من بقاء العدو في نطاق منطقته
    enemy.y = newY.clamp(minY, maxY);

    // ✅ حركة أفقية متغيرة لمزيد من التحدي - مصححة
    if (_random.nextDouble() < 0.05) {
      final speedVariation = 0.8 + _random.nextDouble() * 0.4;
      // ✅ استخدام السرعة الأساسية للعدو بدلاً من متغير غير معرف
      final baseSpeed = enemy.speed.abs();
      enemy.speed = baseSpeed * speedVariation;

      // ✅ طباعة تغيير السرعة (للتصحيح)
      if (_random.nextDouble() < 0.3) {
        print('🦅 تغيير سرعة العدو الطائر: '
            'من ${baseSpeed.toStringAsFixed(3)} إلى ${enemy.speed.toStringAsFixed(3)}');
      }
    }

    // ✅ طباعة معلومات الحركة (للتصحيح)
    if (_random.nextDouble() < 0.01) {
      print('🦅 العدو الطائر يتحرك - '
          'Y: ${enemy.y.toStringAsFixed(3)}, '
          'النطاق: ${minY.toStringAsFixed(2)}-${maxY.toStringAsFixed(2)}, '
          'السرعة: ${enemy.speed.toStringAsFixed(3)}');
    }
  }

  // تحديث حركة الأعداء الذكية (للمستويات المتقدمة)
  void _updateSmartEnemy(Obstacle enemy, double characterX, double characterY) {
    // 10% فرصة لتغيير الاتجاه نحو اللاعب
    if (characterX > enemy.x && _random.nextDouble() < 0.1) {
      enemy.speed = enemy.speed.abs() * -1; // التحرك نحو اليمين
    } else if (characterX < enemy.x && _random.nextDouble() < 0.1) {
      enemy.speed = enemy.speed.abs(); // التحرك نحو اليسار
    }
  }


  void checkAttackCollisions(List<Attack> attacks, List<Obstacle> enemies) {
    final attacksToRemove = <Attack>[];
    final enemiesToRemove = <Obstacle>[];

    for (var attack in attacks) {
      if (!attack.isActive) continue;

      for (var enemy in enemies) {
        if (checkAttackEnemyCollision(attack, enemy)) { // ✅ استخدام الدالة العامة
          // تطبيق الضرر على العدو
          enemy.takeDamage(attack.damage);
          attack.isActive = false;
          attacksToRemove.add(attack);

          print('🎯 ${_getAttackName(attack)} hit ${getEnemyName(enemy)} for ${attack.damage} damage! '
              'Health: ${enemy.health}/${enemy.maxHealth}');

          // إذا مات العدو، أضفه لقائمة الإزالة
          if (enemy.isDead) {
            enemiesToRemove.add(enemy);
            print('💀 ${getEnemyName(enemy)} defeated!');
          }

          break; // توقف عن التحقق مع هذا الهجوم
        }
      }
    }

    // إزالة الهجمات المستهلكة
    attacks.removeWhere((attack) => attacksToRemove.contains(attack));

    // إزالة الأعداء الميتين
    enemies.removeWhere((enemy) => enemiesToRemove.contains(enemy));
  }

// ✅ تحديث دالة التحقق من التصادم
  bool checkAttackEnemyCollision(Attack attack, Obstacle enemy) {
    final attackRect = attack.boundingBox;
    final enemyRect = enemy.boundingBox;

    return attackRect.overlaps(enemyRect);
  }

  // ✅ دالة مساعدة للحصول على اسم الهجوم
  String _getAttackName(Attack attack) {
    switch (attack.type) {
      case AttackType.almashePackage:
        return 'صندوق عالماشي';
      case AttackType.rainbowBeam:
        return 'شعاع قوس قزح';
      case AttackType.arabicFalcon:
        return 'الصقر العربي';
      case AttackType.medievalMud:
        return 'كرات الطين';
      case AttackType.greekLightning:
        return 'صاعقة زيوس';
      case AttackType.snowySnowball:
        return 'كرة الثلج';
      case AttackType.fieryFireball:
        return 'كرات النار';
      case AttackType.technoHack:
        return 'موجة التهكير';
      case AttackType.vikingHammer:
        return 'مطرقة ثور';
      case AttackType.comicsPow:
        return 'POW!';
      case AttackType.zombieSpit:
        return 'كرة اللعاب';
      case AttackType.warriorBullet:
        return 'رصاصة M4';
      default:
        return 'هجوم';
    }
  }


  // تنظيف الأعداء الميتين أو خارج الشاشة
  void cleanupEnemies(List<Obstacle> enemies) {
    enemies.removeWhere((enemy) => enemy.isDead || enemy.isOffScreen());
  }

  // الحصول على نقاط للعدو المهزوم
  int getEnemyPoints(Obstacle enemy) {
    switch (enemy.type) {
      case ObstacleType.flyingEnemy:
        return 10; // نقاط أكثر للعدو الطائر
      case ObstacleType.enemy:
        if (enemy.color == Colors.brown) return 5; // Goomba
        if (enemy.color == Colors.red) return 5;   // Mushroom
        if (enemy.color == Colors.green) return 5; // Koopa
        return 10;
      default:
        return 5;
    }
  }

  // الحصول على اسم العدو للنصوص
  String getEnemyName(Obstacle enemy) {
    switch (enemy.type) {
      case ObstacleType.flyingEnemy:
        return 'عدو طائر';
      case ObstacleType.enemy:
        if (enemy.color == Colors.brown) return 'جومبا';
        if (enemy.color == Colors.red) return 'فطر';
        if (enemy.color == Colors.green) return 'كوبا';
        return 'عدو';
      default:
        return 'عدو';
    }
  }

  // الحصول على إيموجي للعدو (للاستخدام في الواجهة)
  String getEnemyEmoji(Obstacle enemy) {
    switch (enemy.type) {
      case ObstacleType.flyingEnemy:
        return '🦅';
      case ObstacleType.enemy:
        if (enemy.color == Colors.brown) return '👹';
        if (enemy.color == Colors.red) return '🍄';
        if (enemy.color == Colors.green) return '🐢';
        return '👾';
      default:
        return '👾';
    }
  }

  // دالة لتصحيح الأعداء العالقة
  void fixStuckEnemies(List<Obstacle> enemies) {
    for (var enemy in enemies) {
      // إذا كان العدو خارج الحدود، أعد تعيينه
      if (enemy.x < -0.5 || enemy.x > 1.5) {
        enemy.x = 1.1;
        print('🔧 Fixed stuck enemy: ${getEnemyName(enemy)}');
      }

      // تأكد من أن الأعداء الطائرين في السماء
      if (enemy.type == ObstacleType.flyingEnemy && enemy.y > 0.7) {
        enemy.y = 0.5;
      }
    }
  }

  // الحصول على إحصائيات عن الأعداء
  Map<String, int> getEnemyStats(List<Obstacle> enemies) {
    int flyingCount = 0;
    int groundCount = 0;
    int totalHealth = 0;

    for (var enemy in enemies) {
      if (enemy.type == ObstacleType.flyingEnemy) {
        flyingCount++;
      } else {
        groundCount++;
      }
      totalHealth += enemy.health;
    }

    return {
      'flying': flyingCount,
      'ground': groundCount,
      'total': enemies.length,
      'totalHealth': totalHealth,
    };
  }

  // دالة لتصحيح أي مشاكل في الأعداء
  void debugEnemies(List<Obstacle> enemies) {
    print('🐛 Enemy Debug:');
    print('   - Total enemies: ${enemies.length}');

    final stats = getEnemyStats(enemies);
    print('   - Flying enemies: ${stats['flying']}');
    print('   - Ground enemies: ${stats['ground']}');
    print('   - Total health: ${stats['totalHealth']}');

    for (int i = 0; i < enemies.length; i++) {
      final enemy = enemies[i];
      print('   - Enemy $i: ${getEnemyName(enemy)}, '
          'X: ${enemy.x.toStringAsFixed(2)}, '
          'Y: ${enemy.y.toStringAsFixed(2)}, '
          'Health: ${enemy.health}/${enemy.maxHealth}');
    }
  }
}