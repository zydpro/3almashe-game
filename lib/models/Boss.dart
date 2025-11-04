// lib/models/Boss.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'character.dart';
import 'attack.dart';

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
  List<Attack> projectiles;
  double lastAttackTime;

  // ✅ حركة محسنة لتتبع اللاعب
  Character? _targetCharacter;
  double _chaseTimer = 0.0;
  double _patternChangeTimer = 0.0;
  int _currentPattern = 0;
  final Random _random = Random();

  // تأثيرات
  double _slowEffect = 1.0;
  double _freezeEffect = 1.0;
  double _burnEffect = 0.0;
  double _burnDuration = 0.0;

  Boss({
    required this.x,
    required this.y,
    this.width = 0.10,
    this.height = 0.10,
    required this.health,
    required this.maxHealth,
    this.attackSpeed = 1.2,
    this.moveSpeed = 0.012,
    required this.imagePath,
    required this.level,
    this.isRare = false,
    this.isFinalBoss = false,
  })  : projectiles = [],
        lastAttackTime = 0;



  // ✅ إضافة دوال toMap و fromMap
  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'health': health,
      'maxHealth': maxHealth,
      'attackSpeed': attackSpeed,
      'moveSpeed': moveSpeed,
      'imagePath': imagePath,
      'level': level,
      'isRare': isRare,
      'isFinalBoss': isFinalBoss,
      'lastAttackTime': lastAttackTime,
      'projectiles': projectiles.map((p) => p.toMap()).toList(),
    };
  }

  factory Boss.fromMap(Map<String, dynamic> map) {
    final boss = Boss(
      x: map['x'] ?? 0.8,
      y: map['y'] ?? 0.3,
      width: map['width'] ?? 0.10,
      height: map['height'] ?? 0.10,
      health: map['health'] ?? 100,
      maxHealth: map['maxHealth'] ?? 100,
      attackSpeed: map['attackSpeed'] ?? 1.2,
      moveSpeed: map['moveSpeed'] ?? 0.012,
      imagePath: map['imagePath'] ?? '',
      level: map['level'] ?? 1,
      isRare: map['isRare'] ?? false,
      isFinalBoss: map['isFinalBoss'] ?? false,
    );

    boss.lastAttackTime = map['lastAttackTime'] ?? 0;

    // استعادة المقذوفات
    final projectilesData = map['projectiles'] as List? ?? [];
    boss.projectiles = projectilesData.map((p) => Attack.fromMap(p)).toList();

    return boss;
  }

  Boss clone() {
    // نستخدم الدوال الموجودة لإنشاء نسخة جديدة ومستقلة تمامًا
    return Boss.fromMap(this.toMap());
  }

  // ✅ تعيين الهدف (الشخصية)
  void setTarget(Character character) {
    _targetCharacter = character;
  }

  void move() {
    if (_targetCharacter == null) return;

    _chaseTimer += 0.016;
    _patternChangeTimer += 0.016;

    // ✅ تغيير نمط الحركة كل 3-5 ثواني
    if (_patternChangeTimer > 3.0 + _random.nextDouble() * 2.0) {
      _currentPattern = _random.nextInt(4);
      _patternChangeTimer = 0.0;
    }

    final effectiveSpeed = moveSpeed * _slowEffect * _freezeEffect;

    // ✅ تطبيق نمط الحركة الحالي
    switch (_currentPattern) {
      case 0:
        _chasePattern(effectiveSpeed);
        break;
      case 1:
        _circlePattern(effectiveSpeed);
        break;
      case 2:
        _zigzagPattern(effectiveSpeed);
        break;
      case 3:
        _aggressivePattern(effectiveSpeed);
        break;
    }

    _ensureBounds();
    _updateEffects();
  }

  // ✅ نمط 1: ملاحقة اللاعب مباشرة
  void _chasePattern(double effectiveSpeed) {
    if (_targetCharacter == null) return;

    final targetX = _targetCharacter!.x;
    final targetY = _targetCharacter!.y;

    final dirX = targetX - x;
    final dirY = targetY - y;
    final distance = sqrt(dirX * dirX + dirY * dirY);

    if (distance > 0.1) {
      x += (dirX / distance) * effectiveSpeed * 0.8;
      y += (dirY / distance) * effectiveSpeed * 0.6;
    }

    // ✅ حركة عشوائية طفيفة
    x += (_random.nextDouble() - 0.5) * 0.008;
    y += (_random.nextDouble() - 0.5) * 0.006;
  }

  // ✅ نمط 2: حركة دائرية حول اللاعب
  void _circlePattern(double effectiveSpeed) {
    if (_targetCharacter == null) return;

    final targetX = _targetCharacter!.x;
    final targetY = _targetCharacter!.y;

    final angle = _chaseTimer * 2.0;
    final radius = 0.3;

    x = targetX + cos(angle) * radius;
    y = targetY + sin(angle) * 0.2;

    if (_random.nextDouble() < 0.02) {
      x += (targetX - x) * 0.1;
      y += (targetY - y) * 0.1;
    }
  }

  // ✅ نمط 3: حركة متعرجة نحو اللاعب
  void _zigzagPattern(double effectiveSpeed) {
    if (_targetCharacter == null) return;

    final targetX = _targetCharacter!.x;
    final targetY = _targetCharacter!.y;

    final zigzag = sin(_chaseTimer * 4.0) * 0.15;

    if (x < targetX) {
      x += effectiveSpeed * 1.1;
    } else {
      x -= effectiveSpeed * 0.8;
    }

    y += zigzag * effectiveSpeed;

    if ((targetY - y).abs() > 0.2) {
      y += (targetY - y) * effectiveSpeed * 0.5;
    }
  }

  // ✅ نمط 4: حركة عدوانية
  void _aggressivePattern(double effectiveSpeed) {
    if (_targetCharacter == null) return;

    final targetX = _targetCharacter!.x;
    final targetY = _targetCharacter!.y;

    final dirX = targetX - x;
    final dirY = targetY - y;
    final distance = sqrt(dirX * dirX + dirY * dirY);

    if (distance > 0.05) {
      x += (dirX / distance) * effectiveSpeed * 1.3;
      y += (dirY / distance) * effectiveSpeed * 1.1;
    }

    if (_random.nextDouble() < 0.05) {
      x += (_random.nextDouble() - 0.5) * 0.2;
      y += (_random.nextDouble() - 0.5) * 0.15;
    }
  }

  void _ensureBounds() {
    x = x.clamp(0.15, 0.85);
    y = y.clamp(0.2, 0.7);
  }

  void _updateEffects() {
    if (_burnDuration > 0) {
      _burnDuration -= 0.016;
      if (_burnDuration <= 0) {
        _burnEffect = 0.0;
      } else {
        if (_random.nextDouble() < 0.016) {
          takeDamage(_burnEffect.toInt());
        }
      }
    }

    if (_slowEffect < 1.0) {
      _slowEffect += 0.01;
      if (_slowEffect > 1.0) _slowEffect = 1.0;
    }

    if (_freezeEffect < 1.0) {
      _freezeEffect += 0.02;
      if (_freezeEffect > 1.0) _freezeEffect = 1.0;
    }
  }

  void attack(double currentTime) {
    if (currentTime - lastAttackTime > attackSpeed && _targetCharacter != null) {
      _createSmartProjectiles();
      lastAttackTime = currentTime;
    }
  }

  // ✅ مقذوفات ذكية تتجه نحو اللاعب
  void _createSmartProjectiles() {
    if (_targetCharacter == null) return;

    final targetX = _targetCharacter!.x;
    final targetY = _targetCharacter!.y;

    int projectileCount = 1 + (level ~/ 20);
    projectileCount = projectileCount.clamp(1, 4);

    for (int i = 0; i < projectileCount; i++) {
      final dirX = targetX - x;
      final dirY = targetY - y;
      final distance = sqrt(dirX * dirX + dirY * dirY);

      double directionX = dirX / distance;
      double directionY = dirY / distance;

      directionX += (_random.nextDouble() - 0.5) * 0.3;
      directionY += (_random.nextDouble() - 0.5) * 0.2;

      final newDistance = sqrt(directionX * directionX + directionY * directionY);
      directionX /= newDistance;
      directionY /= newDistance;

      projectiles.add(Attack(
        x: x,
        y: y,
        direction: directionX,
        verticalDirection: directionY,
        damage: (8 + level * 1.5).toInt(),
        speed: 0.01 + (_random.nextDouble() * 0.008),
        width: 0.04,
        height: 0.04,
        type: AttackType.almashePackage,
        characterKey: 'boss',
      ));
    }

    if (_random.nextDouble() < 0.2) {
      _createSpecialAttack();
    }
  }

  void _createSpecialAttack() {
    for (int i = 0; i < 3; i++) {
      final angle = (i * 1.0) - 1.0;
      projectiles.add(Attack(
        x: x,
        y: y,
        direction: -1.0,
        verticalDirection: angle * 0.4,
        damage: (12 + level * 2).toInt(),
        speed: 0.015,
        width: 0.05,
        height: 0.05,
        type: AttackType.almashePackage,
        characterKey: 'boss',
      ));
    }
  }

  void updateProjectiles() {
    for (var projectile in projectiles) {
      projectile.move();
      projectile.updateAnimation();
    }
    projectiles.removeWhere((p) => p.isOffScreen() || !p.isActive);
  }

  void takeDamage(int damage) {
    if (isDead) {
      print('💀 الزعيم ميت بالفعل، لا يمكن أخذ ضرر');
      return;
    }

    int actualDamage = damage;
    health -= actualDamage;
    if (health < 0) health = 0;

    // ✅ إضافة طباعة مفصلة للتتبع
    print('💥 Boss took $actualDamage damage. Health: $health/$maxHealth - isDead: $isDead');

    if (isDead) {
      print('🎯 الزعيم وصل إلى صحة 0!');
    }
  }

  void applySlowEffect(double slowAmount, double duration) {
    _slowEffect = 1.0 - slowAmount;
  }

  void applyFreezeEffect(double duration) {
    _freezeEffect = 0.3;
  }

  void applyBurnEffect(int burnDamage, double duration) {
    _burnEffect = burnDamage.toDouble();
    _burnDuration = duration;
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

  Map<String, dynamic> getEffectStatus() {
    return {
      'slowEffect': _slowEffect,
      'freezeEffect': _freezeEffect,
      'burnEffect': _burnEffect,
      'burnDuration': _burnDuration,
    };
  }
}