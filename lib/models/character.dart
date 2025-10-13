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

  // ✅ إعدادات الفيزياء المحسنة
  double jumpPower = -0.045;
  double gravity = 0.0018;
  double weight = 1.1;
  double groundY = 0.75;
  double groundFriction;

  // خصائص المنصات
  bool _isOnPlatform = false;
  double? _platformY;
  double _velocityY = 0.0;

  // ✅ نظام الحركة المحسن
  bool _isMovingLeft = false;
  bool _isMovingRight = false;
  bool _isMovingUp = false;
  bool _isMovingDown = false;
  double _moveSpeed = 0.025;
  double _verticalMoveSpeed = 0.02;

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

  // ✅ نظام القفز المحسن
  double _minJumpY = 0.3;
  double _maxJumpY = 0.1;
  double _currentMaxJumpHeight = 0.0;
  double _jumpForce = 0.0;
  bool _isLongJump = false;
  double _longJumpMultiplier = 1.5;

  // ✅ نظام القفز للأسفل
  bool _isDownJumping = false;
  double _downJumpForce = 0.0;
  double _downJumpMultiplier = 1.2;

  // ✅ نظام الحركة السلسة
  double _targetX = 0.0;
  double _targetY = 0.0;
  double _moveSmoothing = 0.1;

  // الخصائص العامة
  bool get isOnPlatform => _isOnPlatform;
  set isOnPlatform(bool value) => _isOnPlatform = value;

  double? get platformY => _platformY;
  set platformY(double? value) => _platformY = value;

  double get velocityY => _velocityY;
  set velocityY(double value) => _velocityY = value;

  double get currentMaxJumpHeight => _currentMaxJumpHeight;
  bool get isMovingLeft => _isMovingLeft;
  bool get isMovingRight => _isMovingRight;
  bool get isMovingUp => _isMovingUp;
  bool get isMovingDown => _isMovingDown;
  double get moveSpeed => _moveSpeed;
  bool get isLongJump => _isLongJump;
  bool get isDownJumping => _isDownJumping;

  Character({
    required this.x,
    required this.y,
    this.width = 0.1,
    this.height = 0.15,
    this.verticalSpeed = 0.0,
    this.gravity = 0.0018,
    this.isJumping = false,
    this.isDucking = false,
    this.isAttacking = false,
    this.groundY = 0.75,
    this.jumpHeight = 0.25,
    this.jumpPower = -0.045,
    this.imagePath = 'assets/images/characters/character_run.png',
    this.jumpCount = 0,
    this.weight = 1.1,
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
        lastAttackTime = 0 {
    _targetX = x;
    _targetY = y;
  }

  // ✅ نظام القفز المحسن مع مراحل متعددة
  void jump({bool isLongJump = false, bool isDownJump = false}) {
    if (!isJumping && !isDucking) {
      isJumping = true;
      _isOnPlatform = false;
      _platformY = null;

      if (isDownJump) {
        // ✅ قفز للأسفل
        _isDownJumping = true;
        _downJumpForce = jumpPower * weight * _downJumpMultiplier;
        _velocityY = _downJumpForce.abs();
      } else {
        // ✅ قفز عادي أو طويل للأعلى
        _isLongJump = isLongJump;
        double jumpMultiplier = isLongJump ? _longJumpMultiplier : 1.0;
        _jumpForce = jumpPower * weight * jumpMultiplier;
        _velocityY = _jumpForce;
      }

      jumpCount++;
      _currentMaxJumpHeight = (y - jumpHeight).clamp(0.15, 0.4);
    }
  }

  // ✅ دالة لبدء القفز مع تحديد القوة بناءً على مسافة السحب
  void startJump(double dragDistance) {
    if (!isJumping && !isDucking) {
      isJumping = true;
      _isOnPlatform = false;
      _platformY = null;

      // ✅ تحديد نوع القفز بناءً على مسافة السحب
      if (dragDistance < -30) {
        // ✅ سحب صغير للأعلى - قفزة صغيرة
        _isLongJump = false;
        _jumpForce = jumpPower * weight;
        _velocityY = _jumpForce;
      } else if (dragDistance < -100) {
        // ✅ سحب كبير للأعلى - قفزة عالية
        _isLongJump = true;
        _jumpForce = jumpPower * weight * _longJumpMultiplier;
        _velocityY = _jumpForce;
      } else if (dragDistance > 30) {
        // ✅ سحب صغير للأسفل - قفزة صغيرة للأسفل
        _isDownJumping = true;
        _downJumpForce = jumpPower * weight * 0.8;
        _velocityY = _downJumpForce.abs();
      } else if (dragDistance > 60) {
        // ✅ سحب كبير للأسفل - قفزة طويلة للأسفل
        _isDownJumping = true;
        _downJumpForce = jumpPower * weight * _downJumpMultiplier;
        _velocityY = _downJumpForce.abs();
      }

      jumpCount++;
      _currentMaxJumpHeight = (y - jumpHeight).clamp(0.15, 0.4);
    }
  }

  void setJumpBounds(double minY, double maxY) {
    _minJumpY = minY.clamp(0.1, 0.5);
    _maxJumpY = maxY.clamp(0.05, 0.2);
  }

  void duck() {
    if (!isJumping) {
      isDucking = true;
      height = duckHeight;
      y = (_isOnPlatform && _platformY != null) ? _platformY! - height : groundY - height;
    }
  }

  void stopDucking() {
    if (isDucking) {
      isDucking = false;
      height = normalHeight;
      if (!isJumping) {
        y = (_isOnPlatform && _platformY != null) ? _platformY! - height : groundY - height;
      }
    }
  }

  // ✅ دوال الحركة المحسنة مع سلاسة
  void moveLeft() {
    _isMovingLeft = true;
    _isMovingRight = false;
    _targetX = (x - _moveSpeed).clamp(0.05, 0.95);
  }

  void moveRight() {
    _isMovingRight = true;
    _isMovingLeft = false;
    _targetX = (x + _moveSpeed).clamp(0.05, 0.95);
  }

  void moveUp() {
    _isMovingUp = true;
    _isMovingDown = false;
    _targetY = (y - _verticalMoveSpeed).clamp(0.1, 0.85);
  }

  void moveDown() {
    _isMovingDown = true;
    _isMovingUp = false;
    _targetY = (y + _verticalMoveSpeed).clamp(0.1, 0.85);
  }

  void stopHorizontalMoving() {
    _isMovingLeft = false;
    _isMovingRight = false;
  }

  void stopVerticalMoving() {
    _isMovingUp = false;
    _isMovingDown = false;
  }

  void stopMoving() {
    stopHorizontalMoving();
    stopVerticalMoving();
  }

  // ✅ دالة للتحكم في الحركة من خلال السحب - محسنة وسلسة
  void handleDrag(double deltaX, double deltaY) {
    // ✅ حساسية السحب المحسنة
    double dragSensitivity = 0.0005;

    // ✅ تحديث المواقع المستهدفة للحركة السلسة
    _targetX = (x + deltaX * dragSensitivity).clamp(0.05, 0.95);

    // ✅ الحركة العمودية (فقط إذا لم يكن على الأرض)
    if (!isJumping && !_isOnPlatform) {
      _targetY = (y + deltaY * dragSensitivity).clamp(0.1, 0.85);
    }

    // ✅ تحديد نوع القفز بناءً على قوة السحب العمودي
    if (deltaY < -20) {
      bool isLongJump = deltaY.abs() > 80;
      jump(isLongJump: isLongJump);
    } else if (deltaY > 20 && isJumping) {
      // ✅ تسريع الهبوط أثناء القفز
      _velocityY += 0.005 * (deltaY / 50).abs();
    }
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
  }

  void deactivateShield() {
    hasShield = false;
    isInvincible = false;
    shieldEndTime = null;
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
  }

  void heal(int amount) {
    health += amount;
    if (health > maxHealth) health = maxHealth;
  }

  void loseLife() {
    lives--;
    health = maxHealth;
    _isOnPlatform = false;
    _platformY = null;
  }

  bool get isDead => lives <= 0;

  void addLife() {
    if (lives < 3) {
      lives++;
    }
  }

  // ✅ دالة update محسنة لنظام الحركة السلسة
  void update() {
    updateShield();
    updatePackages();

    // ✅ تطبيق الحركة السلسة
    x = x + (_targetX - x) * _moveSmoothing;

    if (!isJumping && !_isOnPlatform) {
      y = y + (_targetY - y) * _moveSmoothing;
    }

    // ✅ تحديث الفيزياء (الجاذبية والقفز)
    if (!_isOnPlatform) {
      _velocityY += gravity * weight;
      y += _velocityY;

      // ✅ التحكم في القفز للأعلى
      if (isJumping && !_isDownJumping && y <= _currentMaxJumpHeight) {
        y = _currentMaxJumpHeight;
        _velocityY = gravity * weight;
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
      _isLongJump = false;
      _isDownJumping = false;
    } else {
      if (y >= groundY) {
        y = groundY;
        _velocityY = 0.0;
        isJumping = false;
        _isLongJump = false;
        _isDownJumping = false;
        jumpCount = 0;
        _currentMaxJumpHeight = 0.0;
        _targetY = y; // ✅ تحديث الهدف العمودي عند الهبوط
      }
    }

    // ✅ تطبيق الحدود النهائية
    x = x.clamp(0.05, 0.95);
    y = y.clamp(0.1, 0.85);
  }

  // دوال المنصات
  void leavePlatform() {
    _isOnPlatform = false;
    _platformY = null;
  }

  void standOnPlatform(double platformTop) {
    _isOnPlatform = true;
    _platformY = platformTop;
    _velocityY = 0.0;
    isJumping = false;
    _isLongJump = false;
    _isDownJumping = false;
    y = platformTop - height;
    _targetY = y; // ✅ تحديث الهدف العمودي عند الوقوف على المنصة
  }

  // دوال التحقق من التصادم
  bool isAboveEnemy(Obstacle enemy) {
    if (!enemy.isEnemy) return false;

    final characterBottom = y;
    final enemyTop = enemy.y - enemy.height / 2;
    final headRegionBottom = enemyTop + enemy.height * 0.3;

    final horizontalOverlap = (x + width/2) > (enemy.x - enemy.width/2) &&
        (x - width/2) < (enemy.x + enemy.width/2);

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
}