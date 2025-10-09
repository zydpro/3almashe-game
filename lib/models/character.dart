import 'dart:ui';
import 'package:flutter/material.dart';
import 'obstacle.dart';
import 'package.dart';
import 'enums.dart';
import 'Boss.dart';

class Character {
  double x;
  double y;
  double width;
  double height;
  double verticalSpeed;
  bool isJumping;
  bool isDucking;
  bool isAttacking;
  double jumpHeight;
  double normalHeight;
  double duckHeight;
  String imagePath;
  int jumpCount;

  // إعدادات الفيزياء
  double jumpPower = -0.045;
  double gravity = 0.0018;
  double weight = 1.1;
  double groundY = 0.75;
  double groundFriction;

  // خصائص المنصات
  bool _isOnPlatform = false;
  double? _platformY;
  double _velocityY = 0.0;
  bool _isMovingLeft = false;
  bool _isMovingRight = false;
  double _moveSpeed = 0.008;

  // خصائص إضافية
  bool hasShield;
  bool isInvincible;
  DateTime? shieldEndTime;

  // نظام الصحة والهجوم
  int health;
  int maxHealth;
  List<Package> packages;
  double lastAttackTime;
  double attackCooldown;
  int lives;

  // الخصائص العامة للمنصات
  bool get isOnPlatform => _isOnPlatform;
  set isOnPlatform(bool value) => _isOnPlatform = value;

  double? get platformY => _platformY;
  set platformY(double? value) => _platformY = value;

  double get velocityY => _velocityY;
  set velocityY(double value) => _velocityY = value;

  // ✅ إضافة حدود القفز
  double _minJumpY = 0.3;  // الحد الأدنى للارتفاع (لا يقل عن 30% من الشاشة)
  double _maxJumpY = 0.1;  // الحد الأقصى للارتفاع (لا يزيد عن 10% من الشاشة)

  // ✅ إضافة متغير لتتبع الحد الأقصى للقفزة
  double _currentMaxJumpHeight = 0.0;

  double get currentMaxJumpHeight => _currentMaxJumpHeight;
  bool get isMovingLeft => _isMovingLeft;
  bool get isMovingRight => _isMovingRight;
  double get moveSpeed => _moveSpeed;

  Character({
    required this.x,
    required this.y,
    this.width = 0.1,
    this.height = 0.15,
    this.verticalSpeed = 0.0,
    this.gravity = 0.002,
    this.isJumping = false,
    this.isDucking = false,
    this.isAttacking = false,
    this.groundY = 0.75,
    this.jumpHeight = 0.25,
    this.jumpPower = -0.038,
    this.imagePath = 'assets/images/characters/character_run.png',
    this.jumpCount = 0,
    this.weight = 1.5,
    this.groundFriction = 0.98,
    this.hasShield = false,
    this.isInvincible = false,
    this.shieldEndTime,
    this.health = 100,
    this.maxHealth = 100,
    this.lives = 3,
    this.attackCooldown = 0.5,
  })  : normalHeight = height,
        duckHeight = height * 0.6,
        packages = [],
        lastAttackTime = 0;

  void jump() {
    if (!isJumping && !isDucking) {
      isJumping = true;
      _isOnPlatform = false;
      _platformY = null;
      _velocityY = jumpPower * weight;
      jumpCount++;

      // ✅ حساب الحد الأقصى للقفزة بشكل أكثر دقة
      _currentMaxJumpHeight = (y - jumpHeight).clamp(0.15, 0.4);

      print('🦘 بدأ القفز - '
          'القوة: $jumpPower, '
          'الوزن: $weight, '
          'الحد الأقصى: ${_currentMaxJumpHeight.toStringAsFixed(3)}');
    }
  }

  // ✅ دالة مساعدة لضبط حدود القفز
  void setJumpBounds(double minY, double maxY) {
    _minJumpY = minY.clamp(0.1, 0.5);
    _maxJumpY = maxY.clamp(0.05, 0.2);
    print('🎯 حدود القفز - '
        'الحد الأدنى: ${_minJumpY.toStringAsFixed(3)}, '
        'الحد الأقصى: ${_maxJumpY.toStringAsFixed(3)}');
  }

  void duck() {
    if (!isJumping) {
      isDucking = true;
      height = duckHeight;
      y = (_isOnPlatform && _platformY != null) ? _platformY! - height : groundY - height;
      print('🦆 Character ducking');
    }
  }

  void stopDucking() {
    if (isDucking) {
      isDucking = false;
      height = normalHeight;
      if (!isJumping) {
        y = (_isOnPlatform && _platformY != null) ? _platformY! - height : groundY - height;
      }
      print('🚶 Character standing');
    }
  }

  // دوال الحركة الأفقية
  void moveLeft() {
    _isMovingLeft = true;
    _isMovingRight = false;
  }

  void moveRight() {
    _isMovingRight = true;
    _isMovingLeft = false;
  }

  void stopMoving() {
    _isMovingLeft = false;
    _isMovingRight = false;
  }

  // هجوم برمي الطرد
  void attack(double currentTime) {
    if (currentTime - lastAttackTime > attackCooldown) {
      packages.add(Package(
        x: x + width / 2,
        y: y - height / 2,
        direction: 1.0,
        damage: 15,
        speed: 0.025,
      ));
      lastAttackTime = currentTime;
      isAttacking = true;

      Future.delayed(const Duration(milliseconds: 200), () {
        isAttacking = false;
      });

      print('📦 Character attacked with package!');
    }
  }

  void updatePackages() {
    for (var package in packages) {
      package.move();
    }
    packages.removeWhere((p) => p.isOffScreen() || !p.isActive);
  }

  // دوال الدرع والقوى
  void activateShield(Duration duration) {
    hasShield = true;
    isInvincible = true;
    shieldEndTime = DateTime.now().add(duration);
    print('🛡️ Shield activated for ${duration.inSeconds} seconds');
  }

  void deactivateShield() {
    hasShield = false;
    isInvincible = false;
    shieldEndTime = null;
    print('🛡️ Shield deactivated');
  }

  void updateShield() {
    if (hasShield && shieldEndTime != null) {
      if (DateTime.now().isAfter(shieldEndTime!)) {
        deactivateShield();
      }
    }
  }

  // نظام الصحة
  void takeDamage(int damage) {
    if (hasShield || isInvincible) return;

    health -= damage;
    if (health <= 0) {
      loseLife();
    }
    print('💔 Character took $damage damage. Health: $health/$maxHealth');
  }

  void heal(int amount) {
    health += amount;
    if (health > maxHealth) health = maxHealth;
    print('❤️ Character healed $amount. Health: $health/$maxHealth');
  }

  void loseLife() {
    lives--;
    health = maxHealth;
    _isOnPlatform = false;
    _platformY = null;
    print('💔 Character lost a life. Lives remaining: $lives');
  }

  bool get isDead => lives <= 0;

  void addLife() {
    if (lives < 3) {
      lives++;
      print('➕ Character gained a life. Lives: $lives');
    }
  }

  // دالة update محسنة لدعم المنصات
  void update() {
    updateShield();
    updatePackages();

    if (!_isOnPlatform) {
      _velocityY += gravity * weight;
      y += _velocityY;

      // ✅ منع تجاوز الحد الأقصى للقفزة
      if (isJumping && y <= _currentMaxJumpHeight) {
        y = _currentMaxJumpHeight;
        _velocityY = gravity * weight;
        print('⬆️ وصل للحد الأقصى للقفزة: ${y.toStringAsFixed(3)}');
      }
    }

    // ✅ حدود رأسية مطلقة
    y = y.clamp(0.1, 0.85);

    // ✅ حدود أفقية مطلقة
    x = x.clamp(0.05, 0.95);

    if (_isOnPlatform && _platformY != null) {
      y = _platformY! - height;
      _velocityY = 0.0;
      isJumping = false;
    } else {
      if (y >= groundY) {
        y = groundY;
        _velocityY = 0.0;
        isJumping = false;
        jumpCount = 0;
        _currentMaxJumpHeight = 0.0;
      }
    }

    // تحديث الحركة الأفقية
    if (_isMovingLeft) {
      x -= _moveSpeed;
    }
    if (_isMovingRight) {
      x += _moveSpeed;
    }

    // ✅ تطبيق الحدود النهائية
    x = x.clamp(0.05, 0.95);
    y = y.clamp(0.1, 0.85);

    // ❌ لا تضيف أي كود متعلق بـ _gameTime هنا
  }

  // دوال المنصات
  void leavePlatform() {
    _isOnPlatform = false;
    _platformY = null;
    print('⬇️ Character left platform');
  }

  void standOnPlatform(double platformTop) {
    _isOnPlatform = true;
    _platformY = platformTop;
    _velocityY = 0.0;
    isJumping = false;
    y = platformTop - height;
    print('🧱 Character standing on platform at Y: $y');
  }

  // دوال التحقق من التصادم
  bool isAboveEnemy(Obstacle enemy) {
    if (!enemy.isEnemy) return false;

    final characterBottom = y;
    final enemyTop = enemy.y - enemy.height / 2;
    final headRegionBottom = enemyTop + enemy.height * 0.3;

    final horizontalOverlap = (x + width/2) > (enemy.x - enemy.width/2) &&
        (x - width/2) < (enemy.x + enemy.width/2);

    // ✅ استخدام نفس منطق القفز على الرأس
    final bool isAboveEnemy = characterBottom <= headRegionBottom;
    final bool isFalling = _velocityY > 0;
    final bool isInHeadRegion = characterBottom >= enemyTop &&
        characterBottom <= headRegionBottom;
    final bool isNotTooHigh = (enemyTop - characterBottom).abs() < 0.08;

    return horizontalOverlap && isAboveEnemy && isFalling && isInHeadRegion && isNotTooHigh;
  }

  bool needsToDuckForObstacle(Obstacle obstacle) {
    if (obstacle.y >= 0.7) return false;

    final characterTop = y - height;
    final obstacleBottom = obstacle.y;
    final horizontalOverlap = (x + width/2) > (obstacle.x - obstacle.width/2) &&
        (x - width/2) < (obstacle.x + obstacle.width/2);

    return characterTop <= obstacleBottom && horizontalOverlap;
  }

  bool canStandOnPlatform(double platformTop, double platformLeft, double platformRight) {
    final characterBottom = y;
    final characterLeft = x - width / 2;
    final characterRight = x + width / 2;

    final horizontalOverlap = characterRight > platformLeft && characterLeft < platformRight;
    final verticalProximity = (characterBottom - platformTop).abs() < 0.05;
    final isFallingOntoPlatform = _velocityY > 0;

    return horizontalOverlap && verticalProximity && isFallingOntoPlatform;
  }

  // إعادة تعيين عداد القفزات
  void resetJumpCount() {
    if (jumpCount > 0) {
      print('📊 Reset jump count: $jumpCount jumps');
      jumpCount = 0;
    }
  }

  // نظام التصادم
  bool collidesWith(Obstacle obstacle) {
    if (hasShield || isInvincible) {
      return false;
    }

    final characterRect = boundingBox;
    final obstacleRect = obstacle.boundingBox;
    return characterRect.overlaps(obstacleRect);
  }

  bool collidesWithPowerUp(PowerUp powerUp) {
    final characterRect = boundingBox;
    final powerUpRect = powerUp.boundingBox;
    return characterRect.overlaps(powerUpRect);
  }

  bool collidesWithPackage(Package package) {
    final characterRect = boundingBox;
    final packageRect = package.boundingBox;
    return characterRect.overlaps(packageRect);
  }

  // دوال مساعدة للحصول على الحدود
  Rect get boundingBox => Rect.fromLTWH(
    x - width / 2,
    y - height,
    width,
    height,
  );

  double get left => x - width / 2;
  double get right => x + width / 2;
  double get top => y - height;
  double get bottom => y;

  // الحصول على الوقت المتبقي للدرع
  Duration? get remainingShieldTime {
    if (!hasShield || shieldEndTime == null) return null;
    final now = DateTime.now();
    return shieldEndTime!.isAfter(now) ? shieldEndTime!.difference(now) : Duration.zero;
  }

  // طباعة حالة الشخصية
  void printStatus() {
    print('''
🎮 Character Status:
   Position: ($x, $y)
   Size: ${width}x$height
   State: ${isJumping ? 'Jumping' : isDucking ? 'Ducking' : isAttacking ? 'Attacking' : 'Running'}
   On Platform: $_isOnPlatform
   Platform Y: $_platformY
   Velocity Y: $_velocityY
   Jump Count: $jumpCount
   Weight: $weight
   Health: $health/$maxHealth
   Lives: $lives
   Shield: $hasShield
   Invincible: $isInvincible
   Remaining Shield: ${remainingShieldTime?.inSeconds}s
   Packages: ${packages.length}
   Physics: Gravity=$gravity, Friction=$groundFriction
   Movement: Left=$_isMovingLeft, Right=$_isMovingRight, Speed=$_moveSpeed
''');
  }
}