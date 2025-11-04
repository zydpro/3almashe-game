import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import 'attack.dart';
import 'obstacle.dart';
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

  // === إعدادات الفيزياء المعدلة ===
  double jumpPower = -0.045;
  double gravity = 0.0009; // ✅ تقليل الجاذبية لجعل السقوط أبطأ
  double weight = 1.05; // ✅ تقليل الوزن
  double groundY = 0.75;
  double groundFriction;

  // نظام الشخصيات
  GameCharacter? currentCharacter;
  Map<String, List<String>> characterAnimationFrames = {};
  String currentAnimationState = 'run';
  int currentFrameIndex = 0;
  int animationCounter = 0;
  int framesPerAnimation = 8;

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
  List<Attack> attacks = [];
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

  // ✅ اتجاهات الهجوم
  double _attackDirectionX = 1.0; // الافتراضي لليمين
  double _attackDirectionY = 0.0;

  // إضافة خاصية speed boost
  bool _isSpeedBoostActive = false;
  bool _isCharacterSlowed = false;

  // خاصية للتحقق من الباور أب النشط
  bool get isSpeedBoostActive => _isSpeedBoostActive;
  bool get isCharacterSlowed => _isCharacterSlowed;

  double get currentMoveSpeed {
    if (_isSpeedBoostActive) return _moveSpeed * 1.5;
    if (_isCharacterSlowed) return _moveSpeed * 0.6;
    return _moveSpeed;
  }

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
    this.gravity = 0.0009, // ✅ تحديث القيمة الافتراضية
    this.isJumping = false,
    this.isDucking = false,
    this.isAttacking = false,
    this.groundY = 0.75,
    this.jumpHeight = 0.25,
    this.jumpPower = -0.045,
    this.imagePath = 'assets/images/characters/almashe/almashe_run_1.png',
    this.jumpCount = 0,
    this.weight = 1.05, // ✅ تحديث القيمة الافتراضية
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
        lastAttackTime = 0 {
    _targetX = x;
    _targetY = y;
    _loadSelectedCharacter();
  }

  void setAttackDirection(double deltaX, double deltaY) {
    if (deltaX.abs() > 10 || deltaY.abs() > 10) {
      // تحديد الاتجاه بناءً على السحب
      _attackDirectionX = deltaX > 0 ? 1.0 : -1.0;
      _attackDirectionY = deltaY > 0 ? 0.3 : -0.3; // إضافة مرونة للاتجاه الرأسي
    }
  }

  void activateSpeedBoost() {
    _isSpeedBoostActive = true;
    _moveSpeed = 0.035; // زيادة السرعة
  }

  void deactivateSpeedBoost() {
    _isSpeedBoostActive = false;
    _moveSpeed = 0.025; // العودة للسرعة الطبيعية
  }

  void _loadSelectedCharacter() async {
    try {
      final selectedCharacter = await GameDataService.getSelectedCharacter();
      setCharacter(selectedCharacter);
    } catch (e) {
      setCharacter(GameCharacter.getDefaultCharacter());
    }
  }

  void activateSlowCharacter() {
    _isCharacterSlowed = true;
    _moveSpeed = 0.015;
    _verticalMoveSpeed = 0.012;
  }

  void deactivateSlowCharacter() {
    _isCharacterSlowed = false;
    _moveSpeed = 0.025;
    _verticalMoveSpeed = 0.02;
  }

  void initializeCharacterListener() {
    GameDataService().addUpdateListener(() {
      _loadSelectedCharacter();
    });
  }

  void disposeCharacterListener() {
    GameDataService().removeUpdateListener(() {});
  }

  void setCharacter(GameCharacter character) {
    currentCharacter = character;
    _loadAllAnimationFrames(character);
    imagePath = getCurrentImage();
    _applyCharacterAttributes(character);
  }

  void _loadAllAnimationFrames(GameCharacter character) {
    characterAnimationFrames.clear();

    for (var animation in character.animations) {
      characterAnimationFrames[animation] = character.getAnimationFrames(animation);
    }

    characterAnimationFrames.forEach((key, value) {
    });
  }

  String getCurrentImage() {
    if (currentCharacter == null || !characterAnimationFrames.containsKey(currentAnimationState)) {
      return _getFallbackImage();
    }

    try {
      final frames = characterAnimationFrames[currentAnimationState]!;
      if (frames.isEmpty) return _getFallbackImage();

      final frameIndex = currentFrameIndex % frames.length;
      return frames[frameIndex];

    } catch (e) {
      return _getFallbackImage();
    }
  }

  void _updateCharacterImage() {
    if (isAttacking) {
      currentAnimationState = 'attack';
    } else if (isDucking) {
      currentAnimationState = 'duck';
    } else if (isJumping) {
      currentAnimationState = 'jump';
    } else {
      currentAnimationState = 'run';
    }

    _updateAnimationFrame();
    imagePath = getCurrentImage();
  }

  void _updateAnimationFrame() {
    animationCounter++;
    if (animationCounter >= framesPerAnimation) {
      animationCounter = 0;
      currentFrameIndex = (currentFrameIndex + 1) % 4;
    }
  }

  String _getFallbackImage() {
    // ✅ استخدام الخصائص الموجودة في كلاس Character
    if (isAttacking) {
      return 'assets/images/characters/almashe/almashe_attack_1.png';
    } else if (isDucking) {
      return 'assets/images/characters/almashe/almashe_duck_1.png';
    } else if (isJumping) {
      return 'assets/images/characters/almashe/almashe_jump_1.png';
    } else {
      return 'assets/images/characters/almashe/almashe_run_1.png';
    }
  }

  void _applyCharacterAttributes(GameCharacter character) {
    _resetCharacterAttributes();

    switch (character.type) {
      case 'ألوان':
        jumpPower = -0.05;
        _longJumpMultiplier = 1.8;
        gravity = 0.0008; // ✅ جاذبية أقل للشخصيات الخفيفة
        break;
      case 'تراثي':
        maxHealth = 120;
        health = 120;
        break;
      case 'تاريخي':
        attackCooldown = 0.4;
        break;
      case 'طبيعي':
        groundFriction = 0.95;
        gravity = 0.0008; // ✅ جاذبية أقل للطبيعة
        break;
      case 'عنصري':
        _moveSpeed = 0.03;
        break;
      case 'مستقبلي':
        _moveSmoothing = 0.05;
        gravity = 0.0007; // ✅ جاذبية أقل للمستقبل
        break;
      case 'محارب':
        hasShield = true;
        break;
      case 'كوميكس':
        jumpPower = -0.04;
        gravity = 0.0006; // ✅ جاذبية أقل للكوميكس
        break;
      case 'رعب':
        maxHealth = 150;
        health = 150;
        break;
      case 'تكتيكي': // ✅ إضافة للشخصية الجديدة
        attackCooldown = 0.3;
        _moveSpeed = 0.028;
        gravity = 0.0008; // ✅ جاذبية متوسطة
        break;
      default:
        break;
    }
  }

  void _resetCharacterAttributes() {
    jumpPower = -0.045;
    gravity = 0.0009; // ✅ تحديث القيمة الأساسية
    weight = 1.05; // ✅ تحديث الوزن الأساسي
    groundFriction = 0.98;
    _moveSpeed = 0.025;
    _verticalMoveSpeed = 0.02;
    _moveSmoothing = 0.1;
    _longJumpMultiplier = 1.5;
    attackCooldown = 0.5;
    hasShield = false;
    maxHealth = 100;
  }

  void jump({bool isLongJump = false}) {
    if (!isJumping && !isDucking) {
      isJumping = true;
      _isOnPlatform = false;
      _platformY = null;

      // ✅ قفز بسيط بدون تعقيد
      double jumpMultiplier = isLongJump ? 1.8 : 1.0;
      _jumpForce = jumpPower * weight * jumpMultiplier;
      _velocityY = _jumpForce;

      jumpCount++;
      _currentMaxJumpHeight = (y - jumpHeight).clamp(0.15, 0.4);
      _updateCharacterImage();
    }
  }

  void startJump(double dragDistance) {
    if (!isJumping && !isDucking) {
      isJumping = true;
      _isOnPlatform = false;
      _platformY = null;

      if (dragDistance < -30) {
        _isLongJump = false;
        _jumpForce = jumpPower * weight;
        _velocityY = _jumpForce;
      } else if (dragDistance < -100) {
        _isLongJump = true;
        _jumpForce = jumpPower * weight * _longJumpMultiplier;
        _velocityY = _jumpForce;
      } else if (dragDistance > 30) {
        _isDownJumping = true;
        _downJumpForce = jumpPower * weight * 0.8;
        _velocityY = _downJumpForce.abs();
      } else if (dragDistance > 60) {
        _isDownJumping = true;
        _downJumpForce = jumpPower * weight * _downJumpMultiplier;
        _velocityY = _downJumpForce.abs();
      }

      jumpCount++;
      _currentMaxJumpHeight = (y - jumpHeight).clamp(0.15, 0.4);
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

  void moveLeft() {
    _isMovingLeft = true;
    _isMovingRight = false;
    _targetX = (x - currentMoveSpeed).clamp(0.05, 0.95);
  }

  void moveRight() {
    _isMovingRight = true;
    _isMovingLeft = false;
    _targetX = (x + currentMoveSpeed).clamp(0.05, 0.95);
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

  void attackWithDirection(double currentTime, double directionX, double directionY) {
    if (currentTime - lastAttackTime > attackCooldown && currentCharacter != null) {
      isAttacking = true;

      // ✅ استخدام الاتجاه المحدد من النقر
      final attackDirX = directionX;
      final attackDirY = directionY;

      // ✅ إنشاء الهجوم باتجاه النقر
      attacks.add(Attack.fromCharacter(
        currentCharacter!,
        x + (attackDirX > 0 ? width / 2 : -width / 2),
        y - height / 2,
        direction: attackDirX,
        width: 0.05,
        height: 0.05,
      ));

      // ✅ تعيين الاتجاه الرأسي للهجوم
      attacks.last.verticalDirection = attackDirY;

      lastAttackTime = currentTime;
      _playAttackSound(currentCharacter!);
      _updateCharacterImage();

      Future.delayed(const Duration(milliseconds: 300), () {
        isAttacking = false;
        _updateCharacterImage();
      });
    }
  }

  void attackAtPosition(double currentTime, double tapX, double tapY) {
    if (currentTime - lastAttackTime > attackCooldown && currentCharacter != null) {
      isAttacking = true;

      // ✅ حساب اتجاه الهجوم بناءً على موقع النقر وموقع الشخصية
      final double directionX = tapX - x;
      final double directionY = tapY - y;

      // ✅ تطبيع الاتجاه للحفاظ على سرعة ثابتة
      final double length = sqrt(directionX * directionX + directionY * directionY);
      final double normalizedX = length > 0 ? directionX / length : 1.0;
      final double normalizedY = length > 0 ? directionY / length : 0.0;

      // ✅ إنشاء الهجوم من موقع الشخصية باتجاه النقر
      final attack = Attack.fromCharacter(
        currentCharacter!,
        x, // ✅ بدء الهجوم من مركز الشخصية
        y - height / 2, // ✅ تعديل الارتفاع قليلاً
        direction: normalizedX,
        width: 0.05,
        height: 0.05,
      );

      // ✅ تعيين الاتجاه الرأسي للهجوم
      attack.verticalDirection = normalizedY;

      attacks.add(attack);

      lastAttackTime = currentTime;
      _playAttackSound(currentCharacter!);
      _updateCharacterImage();

      Future.delayed(const Duration(milliseconds: 300), () {
        isAttacking = false;
        _updateCharacterImage();
      });
    }
  }

  void handleDrag(double deltaX, double deltaY) {
    double dragSensitivity = 0.0005;

    // ✅ حركة أفقية كاملة - بدون قيود
    _targetX = (x + deltaX * dragSensitivity).clamp(0.05, 0.95);

    // ✅ حركة رأسية كاملة - بدون قيود (إلا إذا كان على منصة)
    if (!isJumping && !_isOnPlatform) {
      _targetY = (y + deltaY * dragSensitivity).clamp(0.1, 0.85);
    }

    // ✅ نظام القفز البسيط - يعمل في جميع الأحوال
    if (deltaY < -25 && !isJumping && !isDucking) {
      jump();
    }

    // ✅ نظام الـ Duck البسيط - يعمل في جميع الأحوال
    if (deltaY > 50 && !isJumping) {
      duck();
    } else if (deltaY <= 0 && isDucking) {
      stopDucking();
    }
  }

  // تحديث دالة الهجوم
  void attack(double currentTime, {double? directionX, double? directionY}) {
    if (currentTime - lastAttackTime > attackCooldown && currentCharacter != null) {
      isAttacking = true;

      // ✅ استخدام الاتجاه المحدد أو الافتراضي
      final attackDirX = directionX ?? _attackDirectionX;
      final attackDirY = directionY ?? _attackDirectionY;

      attacks.add(Attack.fromCharacter(
        currentCharacter!,
        x + (attackDirX > 0 ? width : -width), // ✅ تعديل نقطة البداية حسب الاتجاه
        y - height / 2 + attackDirY,
        direction: attackDirX,
        // ✅ إزالة verticalDirection واستخدام direction فقط
        width: 0.05,
        height: 0.05,
      ));

      lastAttackTime = currentTime;
      _playAttackSound(currentCharacter!);
      _updateCharacterImage();

      Future.delayed(const Duration(milliseconds: 300), () {
        isAttacking = false;
        _updateCharacterImage();
      });
    }
  }

  void _playAttackSound(GameCharacter character) {
    switch (character.characterKey) {
      case 'warrior':
        AudioService().playWarriorShotSound();
        break;
      case 'snowy':
        AudioService().playSnowballSound();
        break;
      case 'fiery':
        AudioService().playFireballSound();
        break;
      case 'greek':
        AudioService().playLightningSound();
        break;
      case 'arabic':
        AudioService().playFalconSound();
        break;
      case 'viking':
        AudioService().playHammerSound();
        break;
      case 'comics':
        AudioService().playPowSound();
        break;
      case 'zombie':
        AudioService().playZombieSpitSound();
        break;
      case 'techno':
        AudioService().playHackSound();
        break;
      case 'rainbow':
        AudioService().playRainbowSound();
        break;
      case 'medieval':
        AudioService().playMudSound();
        break;
      default:
        AudioService().playPackageThrowSound();
    }
  }

  void updateAttacks() {
    final attacksToRemove = <Attack>[];

    for (var attack in attacks) {
      if (attack.isActive) {
        attack.move();

        // ✅ تنظيف الهجمات التي خرجت عن الشاشة
        if (attack.isOffScreen()) {
          attacksToRemove.add(attack);
        }
      } else {
        attacksToRemove.add(attack);
      }
    }

    attacks.removeWhere((a) => attacksToRemove.contains(a));
  }

  int getAttackDamage() {
    if (currentCharacter == null) return 15;

    switch (currentCharacter!.type) {
      case 'محارب':
      case 'رعب':
        return 25;
      case 'عنصري':
        return 22;
      case 'تاريخي':
        return 20;
      case 'تكتيكي':
        return 28;
      default:
        return 18;
    }
  }

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
      case 'تكتيكي': // ✅ إضافة للشخصية الجديدة
        return 22;
      default:
        return 15;
    }
  }

  void updatePackages() {
    updateAttacks(); // ✅ تحويل الدالة القديمة للجديدة
  }

  void activateShield(Duration duration) {
    hasShield = true;
    isInvincible = true;
    shieldEndTime = DateTime.now().add(duration);
  }

  bool collidesWithAttack(Attack attack) {
    final characterRect = boundingBox;
    final attackRect = attack.boundingBox;
    return characterRect.overlaps(attackRect);
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

  void takeDamage(int damage) {
    if (hasShield || isInvincible) return;

    int finalDamage = _calculateReducedDamage(damage);
    health -= finalDamage;

    if (health <= 0) {
      loseLife();
    }
  }

  // ... (بعد دالة takeDamage أو أي مكان مناسب آخر داخل الكلاس)

  /// <summary>
  /// يعيد إحياء الشخصية بعد موتها (عند الاستمرار بعد مشاهدة إعلان).
  /// </summary>
  void revive() {
    // 1. إعادة ملء الصحة بالكامل
    health = maxHealth;

    // 2. أهم خطوة: إعادة تعيين حالة الموت
    isDead = false;

    // 3. إعادة تعيين أي متغيرات أخرى متعلقة بالحالة
    isInvincible = false; // إذا كان الموت يزيل الحصانة
    // يمكنك إضافة أي إعادة تعيين أخرى هنا إذا لزم الأمر

    print('💪 الشخصية عادت إلى الحياة!');

    // 4. تحديث صورة الشخصية لتعود إلى حالة "الجري" بدلاً من الموت
    _updateCharacterImage();
  }

  // ... (باقي كود الكلاس)


  int _calculateReducedDamage(int baseDamage) {
    if (currentCharacter == null) return baseDamage;

    switch (currentCharacter!.type) {
      case 'رعب':
        return (baseDamage * 0.7).toInt();
      case 'تراثي':
        return (baseDamage * 0.8).toInt();
      case 'محارب':
        return (baseDamage * 0.85).toInt();
      case 'تكتيكي': // ✅ إضافة للشخصية الجديدة
        return (baseDamage * 0.75).toInt();
      default:
        return baseDamage;
    }
  }

  void heal(int amount) {
    health += amount;
    if (health > maxHealth) health = maxHealth;
  }

  void loseLife() {
    if (isDead) return; // لا تفعل شيئًا إذا كان اللاعب ميتًا بالفعل

    lives--;

    if (lives <= 0) {
      lives = 0; // لضمان عدم نزول العدد تحت الصفر
      isDead = true; // ✅ هنا نُعلن أن اللاعب قد مات
      print('Player is now officially dead.');
    } else {
      // إذا خسر حياة ولكنه لم يمت بعد
      health = maxHealth; // أعد ملء الصحة للحياة الجديدة
      // يمكنك إضافة تأثير حصانة مؤقت هنا إذا أردت
    }

    _isOnPlatform = false;
    _platformY = null;
  }


  bool isDead = false;

  void addLife() {
    if (lives < 3) {
      lives++;
    }
  }

  void update() {
    updateShield();
    updatePackages();
    _updateCharacterImage();

    x = x + (_targetX - x) * _moveSmoothing;

    if (!isJumping && !_isOnPlatform) {
      y = y + (_targetY - y) * _moveSmoothing;
    }

    if (!_isOnPlatform) {
      // ✅ تطبيق الجاذبية المخففة للسقوط الأبطأ
      _velocityY += gravity * weight;
      y += _velocityY;

      if (isJumping && !_isDownJumping && y <= _currentMaxJumpHeight) {
        y = _currentMaxJumpHeight;
        _velocityY = gravity * weight;
      }
    }

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

  Rect get boundingBox {
    // ✅ استخدام المربع المحيط الحقيقي للشخصية بدون توسعة
    return Rect.fromLTWH(
      x - width / 2,
      y - height,
      width,
      height,
    );
  }

  // ✅ إضافة دالة للحصول على منطقة دمج مصغرة (اختياري)
  Rect get reducedBoundingBox {
    final reduction = 0.1; // 10% تقليص من جميع الجوانب
    final reducedWidth = width * (1 - reduction);
    final reducedHeight = height * (1 - reduction);

    return Rect.fromCenter(
      center: Offset(x, y - height / 2),
      width: reducedWidth,
      height: reducedHeight,
    );
  }

  double get left => x - width / 2;
  double get right => x + width / 2;
  double get top => y - height;
  double get bottom => y;

  Duration? get remainingShieldTime {
    if (!hasShield || shieldEndTime == null) return null;
    final now = DateTime.now();
    return shieldEndTime!.isAfter(now) ? shieldEndTime!.difference(now) : Duration.zero;
  }

  String get characterName => currentCharacter?.name ?? 'المحارب';
  String get characterType => currentCharacter?.type ?? 'محارب';
  Color get characterColor => currentCharacter?.color ?? Colors.blue;

  String getCharacterImage() {
    return getCurrentImage();
  }

  void resetToDefault() {
    setCharacter(GameCharacter.getDefaultCharacter());
    health = maxHealth;
    lives = 3;
    isJumping = false;
    isDucking = false;
    isAttacking = false;
    _velocityY = 0.0;
    currentFrameIndex = 0;
    animationCounter = 0;
  }

  void refreshCharacter() async {
    try {
      final selectedCharacter = await GameDataService.getSelectedCharacter();
      setCharacter(selectedCharacter);
    } catch (e) {
      setCharacter(GameCharacter.getDefaultCharacter());
    }
  }

  GameCharacter? get currentGameCharacter => currentCharacter;

  // ✅ إضافة دالة reset
  void reset() {
    // إعادة تعيين الموضع والحالة الأساسية
    x = 0.2;
    y = 0.7;
    _targetX = 0.2;
    _targetY = 0.7;

    // إعادة تعيين الفيزياء
    _velocityY = 0.0;
    isJumping = false;
    isDucking = false;
    isAttacking = false;
    _isOnPlatform = false;
    _platformY = null;

    // إعادة تعيين الحركة
    _isMovingLeft = false;
    _isMovingRight = false;
    _isMovingUp = false;
    _isMovingDown = false;

    // إعادة تعيين القفز
    _isLongJump = false;
    _isDownJumping = false;
    _currentMaxJumpHeight = 0.0;
    _jumpForce = 0.0;
    _downJumpForce = 0.0;
    jumpCount = 0;

    // إعادة تعيين الصحة والحياة
    health = maxHealth;
    lives = 3;

    // تنظيف الهجمات
    attacks.clear();

    // إعادة تعيين المؤقتات
    lastAttackTime = 0.0;

    // إعادة تعيين الحماية والباور أب
    hasShield = false;
    isInvincible = false;
    shieldEndTime = null;
    _isSpeedBoostActive = false;
    _isCharacterSlowed = false;

    // إعادة تعيين الرسوم المتحركة
    currentAnimationState = 'run';
    currentFrameIndex = 0;
    animationCounter = 0;

    // إعادة تعيين اتجاه الهجوم
    _attackDirectionX = 1.0;
    _attackDirectionY = 0.0;

    // إعادة تحميل الصورة
    _updateCharacterImage();

    print('🔄 تم إعادة تعيين الشخصية');
  }

  // ✅ إضافة دالة reset بسيطة كبديل
  void resetSimple() {
    x = 0.2;
    y = 0.7;
    health = maxHealth;
    lives = 3;
    attacks.clear();
    isJumping = false;
    isDucking = false;
    isAttacking = false;
    hasShield = false;
    isInvincible = false;
    _isOnPlatform = false;
    _platformY = null;
    _velocityY = 0.0;
  }
}