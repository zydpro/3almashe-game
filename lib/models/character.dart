import 'dart:ui';
import 'package:flutter/material.dart';
import 'obstacle.dart';
import 'package.dart';
import 'enums.dart';
import 'Boss.dart';
import '../models/character_model.dart';
import '../services/game_data_service.dart';

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

  // نظام الشخصيات
  GameCharacter? currentCharacter;
  Map<String, String> characterAnimations = {};
  String currentAnimationState = 'run';

  // خصائص المنصات
  bool _isOnPlatform = false;
  double? _platformY;
  double _velocityY = 0.0;

  // نظام الحركة
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

  // نظام القفز
  double _minJumpY = 0.3;
  double _maxJumpY = 0.1;
  double _currentMaxJumpHeight = 0.0;
  double _jumpForce = 0.0;
  bool _isLongJump = false;
  double _longJumpMultiplier = 1.5;

  // نظام القفز للأسفل
  bool _isDownJumping = false;
  double _downJumpForce = 0.0;
  double _downJumpMultiplier = 1.2;

  // نظام الحركة السلسة
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
    this.imagePath = 'assets/images/characters/almashe_run.png',
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

    // تحميل الشخصية المختارة تلقائياً
    _loadSelectedCharacter();
  }

  // ✅ دالة محسنة لتحميل الشخصية المختارة
  void _loadSelectedCharacter() async {
    try {
      final selectedCharacter = await GameDataService.getSelectedCharacter();
      setCharacter(selectedCharacter);
      print('🎮 تم تحميل الشخصية للعبة: ${selectedCharacter.name}');
    } catch (e) {
      print('❌ خطأ في تحميل الشخصية: $e');
      setCharacter(GameCharacter.getDefaultCharacter());
    }
  }

  // ✅ إضافة مستمع لتحديثات الشخصية
  void initializeCharacterListener() {
    GameDataService().addUpdateListener(() {
      print('🔄 استلام تحديث - إعادة تحميل الشخصية في اللعبة');
      _loadSelectedCharacter();
    });
  }

  // ✅ إزالة المستمع عند التدمير
  void disposeCharacterListener() {
    GameDataService().removeUpdateListener(() {});
  }

  // ✅ دالة تعيين الشخصية الجديدة
  void setCharacter(GameCharacter character) {
    currentCharacter = character;

    print('🎮 تم تحميل الشخصية: ${character.name}');
    print('🖼️ صور الشخصية: ${character.animations}');

    // تعيين الحركات بناءً على الشخصية المختارة
    characterAnimations = {
      'run': character.animations[0],
      'jump': character.animations[1],
      'attack': character.animations[2],
      'duck': character.animations[3],
      'idle': character.animations[4],
    };

    // تحديث مسار الصورة الحالي
    imagePath = getCurrentImage();

    // تطبيق خصائص الشخصية الخاصة
    _applyCharacterAttributes(character);
  }

  // ✅ تطبيق خصائص الشخصية الخاصة
  void _applyCharacterAttributes(GameCharacter character) {
    // إعادة تعيين جميع الخصائص أولاً
    _resetCharacterAttributes();

    switch (character.type) {
      case 'ألوان':
      // شخصية الألوان الطيف - قفز أعلى
        jumpPower = -0.05;
        _longJumpMultiplier = 1.8;
        break;
      case 'تراثي':
      // الشخصية العربية - تحمل أعلى
        maxHealth = 120;
        health = 120;
        break;
      case 'تاريخي':
      // الشخصية الإغريقية - قوة هجوم أعلى
        attackCooldown = 0.4;
        break;
      case 'طبيعي':
      // الشخصية الثلجية - احتكاك أقل
        groundFriction = 0.95;
        break;
      case 'عنصري':
      // الشخصية النارية - سرعة أعلى
        _moveSpeed = 0.03;
        break;
      case 'مستقبلي':
      // الشخصية التقنية - دقة أعلى
        _moveSmoothing = 0.05;
        break;
      case 'محارب':
      // الشخصية المحاربة - قوة دفاع
        hasShield = true;
        break;
      case 'كوميكس':
      // شخصية الكوميكس - قفزات مرنة
        jumpPower = -0.04;
        gravity = 0.0015;
        break;
      case 'رعب':
      // شخصية الزومبي - مقاومة عالية
        maxHealth = 150;
        health = 150;
        break;
      default:
      // الإعدادات الافتراضية
        break;
    }
  }

  // ✅ إعادة تعيين الخصائص إلى القيم الافتراضية
  void _resetCharacterAttributes() {
    jumpPower = -0.045;
    gravity = 0.0018;
    weight = 1.1;
    groundFriction = 0.98;
    _moveSpeed = 0.025;
    _verticalMoveSpeed = 0.02;
    _moveSmoothing = 0.1;
    _longJumpMultiplier = 1.5;
    attackCooldown = 0.5;
    hasShield = false;
    maxHealth = 100;
  }

  // ✅ تحديث صورة الشخصية بناءً على الحالة
  void _updateCharacterImage() {
    imagePath = getCurrentImage();

    // تحديث حالة الأنيميشن
    if (isAttacking) {
      currentAnimationState = 'idle';
    } else if (isDucking) {
      currentAnimationState = 'attack';
    }else if (isDucking) {
      currentAnimationState = 'duck';
    } else if (isJumping) {
      currentAnimationState = 'jump';
    } else {
      currentAnimationState = 'run';
    }
  }

  // ✅ نظام القفز المحسن
  void jump({bool isLongJump = false, bool isDownJump = false}) {
    if (!isJumping && !isDucking) {
      isJumping = true;
      _isOnPlatform = false;
      _platformY = null;

      if (isDownJump) {
        // قفز للأسفل
        _isDownJumping = true;
        _downJumpForce = jumpPower * weight * _downJumpMultiplier;
        _velocityY = _downJumpForce.abs();
      } else {
        // قفز عادي أو طويل للأعلى
        _isLongJump = isLongJump;
        double jumpMultiplier = isLongJump ? _longJumpMultiplier : 1.0;
        _jumpForce = jumpPower * weight * jumpMultiplier;
        _velocityY = _jumpForce;
      }

      jumpCount++;
      _currentMaxJumpHeight = (y - jumpHeight).clamp(0.15, 0.4);

      // تحديث صورة القفز
      _updateCharacterImage();
    }
  }

  // ✅ دالة لبدء القفز مع تحديد القوة بناءً على مسافة السحب
  void startJump(double dragDistance) {
    if (!isJumping && !isDucking) {
      isJumping = true;
      _isOnPlatform = false;
      _platformY = null;

      // تحديد نوع القفز بناءً على مسافة السحب
      if (dragDistance < -30) {
        // سحب صغير للأعلى - قفزة صغيرة
        _isLongJump = false;
        _jumpForce = jumpPower * weight;
        _velocityY = _jumpForce;
      } else if (dragDistance < -100) {
        // سحب كبير للأعلى - قفزة عالية
        _isLongJump = true;
        _jumpForce = jumpPower * weight * _longJumpMultiplier;
        _velocityY = _jumpForce;
      } else if (dragDistance > 30) {
        // سحب صغير للأسفل - قفزة صغيرة للأسفل
        _isDownJumping = true;
        _downJumpForce = jumpPower * weight * 0.8;
        _velocityY = _downJumpForce.abs();
      } else if (dragDistance > 60) {
        // سحب كبير للأسفل - قفزة طويلة للأسفل
        _isDownJumping = true;
        _downJumpForce = jumpPower * weight * _downJumpMultiplier;
        _velocityY = _downJumpForce.abs();
      }

      jumpCount++;
      _currentMaxJumpHeight = (y - jumpHeight).clamp(0.15, 0.4);

      // تحديث صورة القفز
      _updateCharacterImage();
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
      _updateCharacterImage();
    }
  }

  void stopDucking() {
    if (isDucking) {
      isDucking = false;
      height = normalHeight;
      if (!isJumping) {
        y = (_isOnPlatform && _platformY != null) ? _platformY! - height : groundY - height;
      }
      _updateCharacterImage();
    }
  }

  // ✅ دوال الحركة المحسنة
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

  // ✅ دالة للتحكم في الحركة من خلال السحب
  void handleDrag(double deltaX, double deltaY) {
    double dragSensitivity = 0.0005;

    _targetX = (x + deltaX * dragSensitivity).clamp(0.05, 0.95);

    if (!isJumping && !_isOnPlatform) {
      _targetY = (y + deltaY * dragSensitivity).clamp(0.1, 0.85);
    }

    if (deltaY < -20) {
      bool isLongJump = deltaY.abs() > 80;
      jump(isLongJump: isLongJump);
    } else if (deltaY > 20 && isJumping) {
      _velocityY += 0.005 * (deltaY / 50).abs();
    }
  }

  // ✅ هجوم برمي الطرد
  void attack(double currentTime) {
    if (currentTime - lastAttackTime > attackCooldown) {
      packages.add(Package(
        x: x + width / 2,
        y: y - height / 2,
        direction: 1.0,
        damage: _getAttackDamage(),
        speed: 0.025,
      ));
      lastAttackTime = currentTime;
      isAttacking = true;

      _updateCharacterImage();

      Future.delayed(const Duration(milliseconds: 200), () {
        isAttacking = false;
        _updateCharacterImage();
      });
    }
  }

  // ✅ حساب ضرر الهجوم بناءً على الشخصية
  int _getAttackDamage() {
    if (currentCharacter == null) return 15;

    switch (currentCharacter!.type) {
      case 'محارب':
      case 'رعب':
        return 20;
      case 'عنصري':
        return 18;
      case 'تاريخي':
        return 17;
      default:
        return 15;
    }
  }

  void updatePackages() {
    for (var package in packages) {
      package.move();
    }
    packages.removeWhere((p) => p.isOffScreen() || !p.isActive);
  }

  // ✅ دوال الدرع والقوى
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

  // ✅ نظام الصحة
  void takeDamage(int damage) {
    if (hasShield || isInvincible) return;

    int finalDamage = _calculateReducedDamage(damage);
    health -= finalDamage;

    if (health <= 0) {
      loseLife();
    }
  }

  // ✅ حساب الضرر المخفض بناءً على الشخصية
  int _calculateReducedDamage(int baseDamage) {
    if (currentCharacter == null) return baseDamage;

    switch (currentCharacter!.type) {
      case 'رعب':
        return (baseDamage * 0.7).toInt();
      case 'تراثي':
        return (baseDamage * 0.8).toInt();
      case 'محارب':
        return (baseDamage * 0.85).toInt();
      default:
        return baseDamage;
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

  // ✅ دالة update محسنة
  void update() {
    updateShield();
    updatePackages();
    _updateCharacterImage();

    // تطبيق الحركة السلسة
    x = x + (_targetX - x) * _moveSmoothing;

    if (!isJumping && !_isOnPlatform) {
      y = y + (_targetY - y) * _moveSmoothing;
    }

    // تحديث الفيزياء
    if (!_isOnPlatform) {
      _velocityY += gravity * weight;
      y += _velocityY;

      if (isJumping && !_isDownJumping && y <= _currentMaxJumpHeight) {
        y = _currentMaxJumpHeight;
        _velocityY = gravity * weight;
      }
    }

    // حدود الحركة
    y = y.clamp(0.1, 0.85);
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
        _targetY = y;
      }
    }

    x = x.clamp(0.05, 0.95);
    y = y.clamp(0.1, 0.85);
  }

  // ✅ دوال المنصات
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
    _targetY = y;
  }

  // ✅ دوال التحقق من التصادم
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

  void resetJumpCount() {
    if (jumpCount > 0) {
      jumpCount = 0;
    }
  }

  // ✅ نظام التصادم
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

  // ✅ دوال مساعدة للحصول على الحدود
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

  Duration? get remainingShieldTime {
    if (!hasShield || shieldEndTime == null) return null;
    final now = DateTime.now();
    return shieldEndTime!.isAfter(now) ? shieldEndTime!.difference(now) : Duration.zero;
  }

  // ✅ الحصول على معلومات الشخصية الحالية
  String get characterName => currentCharacter?.name ?? 'المحارب';
  String get characterType => currentCharacter?.type ?? 'محارب';
  Color get characterColor => currentCharacter?.color ?? Colors.blue;

  String getCharacterImage() {
    return getCurrentImage(); // ✅ استخدام الدالة الجديدة
  }

  // ✅ إعادة تعيين الشخصية إلى الافتراضية
  void resetToDefault() {
    setCharacter(GameCharacter.getDefaultCharacter());
    health = maxHealth;
    lives = 3;
    isJumping = false;
    isDucking = false;
    isAttacking = false;
    _velocityY = 0.0;
  }

  // ✅ دالة للتحديث الفوري للشخصية المختارة
  void refreshCharacter() async {
    try {
      final selectedCharacter = await GameDataService.getSelectedCharacter();
      setCharacter(selectedCharacter);
    } catch (e) {
      setCharacter(GameCharacter.getDefaultCharacter());
    }
  }
  // ✅ دالة للحصول على الشخصية الحالية
  GameCharacter? get currentGameCharacter => currentCharacter;

// ✅ دالة للحصول على الصورة المناسبة للحالة الحالية
  String getCurrentImage() {
    if (currentCharacter == null) {
      return _getFallbackImage();
    }

    try {
      if (isAttacking) {
        return currentCharacter!.animations[4]; // صورة الركل
      } else if (isDucking) {
        return currentCharacter!.animations[3]; // صورة الهجوم
      }else if (isDucking) {
        return currentCharacter!.animations[2]; // صورة الانحناء
      } else if (isJumping) {
        return currentCharacter!.animations[1]; // صورة القفز
      } else {
        return currentCharacter!.animations[0]; // صورة الجري/الوقوف
      }
    } catch (e) {
      return _getFallbackImage();
    }
  }

// ✅ الصور الاحتياطية
  String _getFallbackImage() {
    if (isAttacking) {
      return 'assets/images/characters/almashe_idle.png';
    } else if (isDucking) {
      return 'assets/images/characters/almashe_attack.png';
    }else if (isDucking) {
      return 'assets/images/characters/almashe_duck.png';
    } else if (isJumping) {
      return 'assets/images/characters/almashe_jump.png';
    } else {
      return 'assets/images/characters/almashe_run.png';
    }
  }
}