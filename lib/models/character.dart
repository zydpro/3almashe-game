import 'dart:ui';
import 'obstacle.dart';

class Character {
  double x;
  double y;
  double width;
  double height;
  double verticalSpeed;
  double gravity;
  bool isJumping;
  bool isDucking;
  double groundY;
  double jumpHeight;
  double normalHeight;
  double duckHeight;
  String imagePath;
  double jumpPower;
  int jumpCount;

  // === إعدادات الفيزياء الجديدة ===
  double weight; // وزن الشخصية
  double groundFriction; // احتكاك الأرض

  // === الخصائص الجديدة ===
  bool hasShield; // هل لدى الشخصية درع؟
  bool isInvincible; // هل هي غير قابلة للضرر؟
  DateTime? shieldEndTime; // وقت انتهاء الدرع

  // === نظام الصحة والهجوم ===
  int health;
  int maxHealth;
  List<Package> packages;
  double lastAttackTime;
  double attackCooldown;
  bool isAttacking;
  int lives; // عدد المحاولات

  Character({
    required this.x,
    required this.y,
    this.width = 0.1,
    this.height = 0.15,
    this.verticalSpeed = 0.0,
    this.gravity = 0.002,
    this.isJumping = false,
    this.isDucking = false,
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
    this.isAttacking = false,
  })  : normalHeight = height,
        duckHeight = height * 0.6,
        packages = [],
        lastAttackTime = 0;

  void jump() {
    if (!isJumping && !isDucking) {
      isJumping = true;
      verticalSpeed = jumpPower * weight;
      jumpCount++;
      print('🦘 Character jumping - Power: $jumpPower, Weight: $weight, Count: $jumpCount');
    }
  }

  void duck() {
    if (!isJumping) {
      isDucking = true;
      height = duckHeight;
      y = groundY - height;
      print('🦆 Character ducking');
    }
  }

  void stopDucking() {
    if (isDucking) {
      isDucking = false;
      height = normalHeight;
      if (!isJumping) y = groundY - height;
      print('🚶 Character standing');
    }
  }

  // === هجوم برمي الطرد ===
  void attack(double currentTime) {
    if (currentTime - lastAttackTime > attackCooldown) {
      packages.add(Package(
        x: x + width / 2,
        y: y - height / 2,
        direction: 1.0, // يتجه نحو الأعداء
        damage: 15,
        speed: 0.025,
      ));
      lastAttackTime = currentTime;
      isAttacking = true;

      // إعادة تعيين حالة الهجوم بعد فترة
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

  // === دوال جديدة للدرع والقوى ===
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

  // === نظام الصحة ===
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
    health = maxHealth; // إعادة تعيين الصحة
    print('💔 Character lost a life. Lives remaining: $lives');
  }

  bool get isDead => lives <= 0;

  void addLife() {
    if (lives < 3) {
      lives++;
      print('➕ Character gained a life. Lives: $lives');
    }
  }

  void update() {
    // تحديث حالة الدرع
    updateShield();

    // تحديث الطرود
    updatePackages();

    // حركة القفز المحسنة مع الوزن
    if (isJumping) {
      y += verticalSpeed;
      verticalSpeed += gravity * weight;

      // التحقق من الوصول للأرض مع التحسينات
      if (y >= groundY - height) {
        y = groundY - height;
        isJumping = false;
        verticalSpeed = 0.0;
        print('🏁 Character landed with realistic physics');
      }
    }

    // تطبيق الاحتكاك عند الهبوط
    if (!isJumping && !isDucking) {
      verticalSpeed *= groundFriction;
    }

    // التأكد من بقاء الشخصية على الأرض عندما لا تقفز
    if (!isJumping && !isDucking && y < groundY - height) {
      y = groundY - height;
      verticalSpeed = 0.0;
    }
  }

  // دالة محسنة للتحقق إذا كانت الشخصية فوق عدو
  bool isAboveEnemy(Obstacle enemy) {
    if (!enemy.isEnemy) return false;

    final characterBottom = y;
    final enemyTop = enemy.y - enemy.height;
    final horizontalOverlap = (x + width/2) > (enemy.x - enemy.width/2) &&
        (x - width/2) < (enemy.x + enemy.width/2);

    return characterBottom <= enemyTop && horizontalOverlap && isJumping;
  }

  // دالة محسنة للتحقق إذا كانت هناك عقبة في السماء تحتاج انحناء
  bool needsToDuckForObstacle(Obstacle obstacle) {
    // العقبات السماوية فقط تحتاج انحناء
    if (obstacle.y >= 0.7) return false;

    final characterTop = y - height;
    final obstacleBottom = obstacle.y;
    final horizontalOverlap = (x + width/2) > (obstacle.x - obstacle.width/2) &&
        (x - width/2) < (obstacle.x + obstacle.width/2);

    return characterTop <= obstacleBottom && horizontalOverlap;
  }

  // دالة جديدة: التحقق إذا كانت الشخصية يمكنها المشي على عقبة
  bool canWalkOnObstacle(Obstacle obstacle) {
    // يمكن المشي فقط على العقبات الأرضية المسطحة
    if (obstacle.type != ObstacleType.groundLong &&
        obstacle.type != ObstacleType.groundWide) {
      return false;
    }

    final characterBottom = y;
    final obstacleTop = obstacle.y - obstacle.height;
    final horizontalOverlap = (x + width/2) > (obstacle.x - obstacle.width/2) &&
        (x - width/2) < (obstacle.x + obstacle.width/2);

    // يجب أن تكون الشخصية فوق العقبة مباشرة
    return (characterBottom - obstacleTop).abs() < 0.02 && horizontalOverlap;
  }

  // إعادة تعيين عداد القفزات
  void resetJumpCount() {
    if (jumpCount > 0) {
      print('📊 Reset jump count: $jumpCount jumps');
      jumpCount = 0;
    }
  }

  // نظام تصادم محسن باستخدام Rect
  bool collidesWith(Obstacle obstacle) {
    // إذا كانت الشخصية لديها درع، لا تتعارض مع العوائق
    if (hasShield || isInvincible) {
      return false;
    }

    final characterRect = Rect.fromLTWH(
      x - width / 2,
      y - height,
      width,
      height,
    );

    final obstacleRect = Rect.fromLTWH(
      obstacle.x - obstacle.width / 2,
      obstacle.y - obstacle.height,
      obstacle.width,
      obstacle.height,
    );

    return characterRect.overlaps(obstacleRect);
  }

  bool collidesWithPowerUp(PowerUp powerUp) {
    final characterRect = Rect.fromLTWH(
      x - width / 2,
      y - height,
      width,
      height,
    );

    final powerUpRect = Rect.fromLTWH(
      powerUp.x - powerUp.width / 2,
      powerUp.y - powerUp.height,
      powerUp.width,
      powerUp.height,
    );

    return characterRect.overlaps(powerUpRect);
  }

  bool collidesWithPackage(Package package) {
    final characterRect = Rect.fromLTWH(
      x - width / 2,
      y - height,
      width,
      height,
    );

    final packageRect = Rect.fromLTWH(
      package.x - package.width / 2,
      package.y - package.height,
      package.width,
      package.height,
    );

    return characterRect.overlaps(packageRect);
  }

  // دوال مساعدة للحصول على حدود الشخصية الرئيسية
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

  // طباعة حالة الشخصية (للت debug)
  void printStatus() {
    print('''
🎮 Character Status:
   Position: ($x, $y)
   Size: ${width}x$height
   State: ${isJumping ? 'Jumping' : isDucking ? 'Ducking' : isAttacking ? 'Attacking' : 'Running'}
   Vertical Speed: $verticalSpeed
   Jump Count: $jumpCount
   Weight: $weight
   Health: $health/$maxHealth
   Lives: $lives
   Shield: $hasShield
   Invincible: $isInvincible
   Remaining Shield: ${remainingShieldTime?.inSeconds}s
   Packages: ${packages.length}
   Physics: Gravity=$gravity, Friction=$groundFriction
''');
  }
}