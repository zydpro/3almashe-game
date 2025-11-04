import 'dart:math';
import 'package:flutter/material.dart';
import 'obstacle.dart';
import 'Boss.dart';
import 'character_model.dart';

enum AttackType {
  almashePackage,
  rainbowBeam,
  arabicFalcon,
  medievalMud,
  greekLightning,
  snowySnowball,
  fieryFireball,
  technoHack,
  vikingHammer,
  comicsPow,
  zombieSpit,
  warriorBullet
}

class Attack {
  double x;
  double y;
  double width;
  double height;
  double speed;
  double direction;
  double verticalDirection;
  int damage;
  bool isActive;
  AttackType type;
  String characterKey;
  String imagePath;
  Map<String, dynamic> effects; // ✅ إضافة الحقل المفقود

  Attack({
    required this.x,
    required this.y,
    this.width = 0.08,
    this.height = 0.08,
    this.speed = 0.03,
    this.direction = 1.0,
    this.verticalDirection = 0.0,
    this.damage = 10,
    this.isActive = true,
    required this.type,
    required this.characterKey,
    this.effects = const {}, // ✅ الآن الحقل موجود
  }) : imagePath = _getAttackImagePath(type, characterKey);

  // ✅ إضافة دوال toMap و fromMap
  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'speed': speed,
      'direction': direction,
      'verticalDirection': verticalDirection,
      'damage': damage,
      'isActive': isActive,
      'type': type.toString(),
      'characterKey': characterKey,
      'imagePath': imagePath,
      'effects': effects,
    };
  }

  factory Attack.fromMap(Map<String, dynamic> map) {
    return Attack(
      x: map['x'] ?? 0.0,
      y: map['y'] ?? 0.0,
      width: map['width'] ?? 0.08,
      height: map['height'] ?? 0.08,
      speed: map['speed'] ?? 0.03,
      direction: map['direction'] ?? 1.0,
      verticalDirection: map['verticalDirection'] ?? 0.0,
      damage: map['damage'] ?? 10,
      isActive: map['isActive'] ?? true,
      type: _parseAttackType(map['type']),
      characterKey: map['characterKey'] ?? 'almashe',
      effects: Map<String, dynamic>.from(map['effects'] ?? {}),
    );
  }

  static AttackType _parseAttackType(String typeString) {
    switch (typeString) {
      case 'AttackType.almashePackage': return AttackType.almashePackage;
      case 'AttackType.rainbowBeam': return AttackType.rainbowBeam;
      case 'AttackType.arabicFalcon': return AttackType.arabicFalcon;
      case 'AttackType.medievalMud': return AttackType.medievalMud;
      case 'AttackType.greekLightning': return AttackType.greekLightning;
      case 'AttackType.snowySnowball': return AttackType.snowySnowball;
      case 'AttackType.fieryFireball': return AttackType.fieryFireball;
      case 'AttackType.technoHack': return AttackType.technoHack;
      case 'AttackType.vikingHammer': return AttackType.vikingHammer;
      case 'AttackType.comicsPow': return AttackType.comicsPow;
      case 'AttackType.zombieSpit': return AttackType.zombieSpit;
      case 'AttackType.warriorBullet': return AttackType.warriorBullet;
      default: return AttackType.almashePackage;
    }
  }

  // ✅ دالة للحصول على مسار الصورة من characterKey
  static String _getAttackImagePath(AttackType type, String characterKey) {
    final folderName = _getAttackFolderName(characterKey);
    return 'assets/images/attacks/$folderName/${folderName}_1.png';
  }

  static String _getAttackFolderName(String characterKey) {
    switch (characterKey) {
      case 'almashe': return 'almashe';
      case 'rainbow': return 'rainbow';
      case 'arabic': return 'arabic';
      case 'medieval': return 'medieval';
      case 'greek': return 'greek';
      case 'snowy': return 'snowy';
      case 'fiery': return 'fiery';
      case 'techno': return 'techno';
      case 'viking': return 'viking';
      case 'comics': return 'comics';
      case 'zombie': return 'zombie';
      case 'warrior': return 'warrior';
      default: return 'almashe';
    }
  }

  void move() {
    // ✅ حركة الهجوم باتجاه النقر بدقة
    x += speed * direction;
    y += speed * verticalDirection;

    // ✅ حركة تموجية خفيفة للهجمات الخاصة مع الحفاظ على الاتجاه الأساسي
    switch (type) {
      case AttackType.arabicFalcon:
      // صقر يتحرك باتجاه النقر مع تموج بسيط
        y += sin(x * 10) * 0.005;
        break;
      case AttackType.vikingHammer:
      // مطرقة تتحرك باتجاه النقر مع حركة دائرية بسيطة
        final angle = x * 15;
        y += sin(angle) * 0.008;
        break;
      case AttackType.medievalMud:
      // طين يتحرك باتجاه النقر مع هبوط تدريجي
        y += 0.003;
        break;
      case AttackType.technoHack:
      // هجوم تكنولوجي سريع باتجاه النقر
        x += speed * direction * 1.3;
        y += speed * verticalDirection * 1.3;
        break;
      case AttackType.snowySnowball:
      // كرة ثلج تتحرك في خط مستقيم باتجاه النقر
        x += speed * direction;
        y += speed * verticalDirection;
        break;
      case AttackType.fieryFireball:
      // كرة نار تتحرك باتجاه النقر بسرعة متوسطة
        x += speed * direction * 1.1;
        y += speed * verticalDirection * 1.1;
        break;
      case AttackType.greekLightning:
      // برق يتحرك باتجاه النقر بسرعة عالية
        x += speed * direction * 1.4;
        y += speed * verticalDirection * 1.4;
        break;
      case AttackType.rainbowBeam:
      // شعاع قوس قزح يتحرك باتجاه النقر
        x += speed * direction;
        y += speed * verticalDirection;
        break;
      case AttackType.warriorBullet:
      // رصاصة تتحرك باتجاه النقر بسرعة ثابتة
        x += speed * direction * 1.2;
        y += speed * verticalDirection * 1.2;
        break;
      case AttackType.comicsPow:
      // هجوم كوميكس يتحرك باتجاه النقر
        x += speed * direction;
        y += speed * verticalDirection;
        break;
      case AttackType.zombieSpit:
      // بصاق زومبي يتحرك باتجاه النقر مع هبوط
        y += 0.004;
        x += speed * direction;
        break;
      default:
      // الحركة الأساسية باتجاه النقر
        x += speed * direction;
        y += speed * verticalDirection;
    }
  }

  // ✅ إزالة دوال Animation لأننا نملك صورة واحدة فقط
  void updateAnimation() {
    // لا حاجة للأنيميشن مع صورة واحدة
  }

  String getCurrentFrame() {
    return imagePath; // ✅ إرجاع الصورة مباشرة
  }

  bool isOffScreen() {
    // ✅ توسيع حدود الشاشة قليلاً لتنظيف الهجمات التي خرجت
    return x < -0.3 || x > 1.3 || y < -0.3 || y > 1.3;
  }

  bool collidesWith(Obstacle obstacle) {
    final attackRect = boundingBox;
    final obstacleRect = obstacle.boundingBox;
    return attackRect.overlaps(obstacleRect);
  }

  bool collidesWithBoss(Boss boss) {
    final attackRect = boundingBox;
    final bossRect = boss.boundingBox;
    return attackRect.overlaps(bossRect);
  }

  // تطبيق التأثيرات الخاصة على العدو
  Map<String, dynamic> applyEffects() {
    switch (type) {
      case AttackType.snowySnowball:
        return {'freeze': 1, 'slow': 0.3, 'duration': 2.0};
      case AttackType.fieryFireball:
        return {'burn': damage ~/ 2, 'duration': 3.0};
      case AttackType.medievalMud:
        return {'slow': 0.5, 'duration': 1.5};
      case AttackType.technoHack:
        return {'disable': true, 'duration': 1.0};
      case AttackType.vikingHammer:
        return {'knockback': 0.1};
      case AttackType.zombieSpit:
        return {'poison': damage ~/ 4, 'duration': 4.0};
      default:
        return {};
    }
  }

  Rect get boundingBox => Rect.fromLTWH(
    x - width / 2,
    y - height / 2,
    width,
    height,
  );

  // إنشاء هجوم بناءً على نوع الشخصية
  factory Attack.fromCharacter(GameCharacter character, double x, double y,
      {double direction = 1.0, double width = 0.05, double height = 0.05}) {
    AttackType attackType;

    switch (character.characterKey) {
      case 'almashe':
        attackType = AttackType.almashePackage;
        break;
      case 'rainbow':
        attackType = AttackType.rainbowBeam;
        break;
      case 'arabic':
        attackType = AttackType.arabicFalcon;
        break;
      case 'medieval':
        attackType = AttackType.medievalMud;
        break;
      case 'greek':
        attackType = AttackType.greekLightning;
        break;
      case 'snowy':
        attackType = AttackType.snowySnowball;
        break;
      case 'fiery':
        attackType = AttackType.fieryFireball;
        break;
      case 'techno':
        attackType = AttackType.technoHack;
        break;
      case 'viking':
        attackType = AttackType.vikingHammer;
        break;
      case 'comics':
        attackType = AttackType.comicsPow;
        break;
      case 'zombie':
        attackType = AttackType.zombieSpit;
        break;
      case 'warrior':
        attackType = AttackType.warriorBullet;
        break;
      default:
        attackType = AttackType.almashePackage;
    }

    return Attack(
      x: x,
      y: y,
      width: width, // ✅ استخدام الحجم المصغر
      height: height, // ✅ استخدام الحجم المصغر
      direction: direction,
      type: attackType,
      characterKey: character.characterKey,
      damage: _getAttackDamage(character),
      speed: _getAttackSpeed(character),
    );
  }

  static int _getAttackDamage(GameCharacter character) {
    switch (character.characterKey) {
      case 'warrior':
      case 'comics':
        return 25;
      case 'viking':
      case 'fiery':
        return 20;
      case 'greek':
      case 'zombie':
        return 18;
      case 'techno':
      case 'arabic':
        return 15;
      default:
        return 12;
    }
  }

  static double _getAttackSpeed(GameCharacter character) {
    switch (character.characterKey) {
      case 'warrior':
        return 0.035;
      case 'rainbow':
        return 0.03;
      case 'techno':
        return 0.028;
      default:
        return 0.025;
    }
  }
}