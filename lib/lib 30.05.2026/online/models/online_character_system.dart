import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import '../animation/advanced_animation_system.dart';
import '../animation/animation_loader.dart';
import '../animation/animation_manager.dart';
import '../animation/animation_state_machine.dart';
import '../services/online_audio_service.dart';
import '../services/online_game_service.dart';

enum OnlineWeaponType {
  sword, hammer, bow, spear, katars, gauntlets, blasters, orb, staff, axe, dagger,
}

enum OnlineAttackType {
  light, heavy, aerial, special, signature,
}

class OnlineWeapon {
  final OnlineWeaponType type;
  final String name;
  final String nameEn;
  final int damage;
  final double speed;
  final double range;
  final String imagePath;
  final Color attackColor;

  const OnlineWeapon({
    required this.type,
    required this.name,
    required this.nameEn,
    required this.damage,
    required this.speed,
    required this.range,
    required this.imagePath,
    required this.attackColor,
  });

  OnlineBattleAttack createAttack(OnlineAttackType attackType, double x, double y, bool isFacingRight) {
    final directionX = isFacingRight ? 1.0 : -1.0;

    switch (attackType) {
      case OnlineAttackType.light:
        return OnlineBattleAttack(
          type: attackType,
          x: x + (directionX * 0.05),
          y: y,
          directionX: directionX,
          damage: damage,
          speed: speed * 1.5,
          range: range * 0.7,
          color: attackColor,
          weaponImagePath: imagePath,
        );
      case OnlineAttackType.heavy:
        return OnlineBattleAttack(
          type: attackType,
          x: x + (directionX * 0.03),
          y: y,
          directionX: directionX,
          damage: (damage * 1.8).round(),
          speed: speed * 0.8,
          range: range * 1.2,
          color: attackColor.withOpacity(0.9),
          weaponImagePath: imagePath,
        );
      case OnlineAttackType.aerial:
        return OnlineBattleAttack(
          type: attackType,
          x: x + (directionX * 0.04),
          y: y - 0.05,
          directionX: directionX,
          damage: (damage * 1.2).round(),
          speed: speed * 1.3,
          range: range * 0.8,
          color: attackColor.withBlue(200),
          weaponImagePath: imagePath,
        );
      case OnlineAttackType.special:
        return OnlineBattleAttack(
          type: attackType,
          x: x + (directionX * 0.06),
          y: y,
          directionX: directionX,
          damage: (damage * 1.5).round(),
          speed: speed * 1.1,
          range: range * 1.1,
          color: attackColor.withGreen(200),
          weaponImagePath: imagePath,
        );
      case OnlineAttackType.signature:
        return OnlineBattleAttack(
          type: attackType,
          x: x + (directionX * 0.07),
          y: y,
          directionX: directionX,
          damage: (damage * 2.2).round(),
          speed: speed * 0.9,
          range: range * 1.4,
          color: attackColor.withRed(200),
          weaponImagePath: imagePath,
        );
    }
  }
}

class OnlineBattleAttack {
  final OnlineAttackType type;
  double x, y;
  final double directionX;
  bool isActive;
  int damage;
  final double speed;
  final double range;
  final Color color;
  int lifetime;
  final String weaponImagePath;

  OnlineBattleAttack({
    required this.type,
    required this.x,
    required this.y,
    required this.directionX,
    this.isActive = true,
    required this.damage,
    required this.speed,
    required this.range,
    required this.color,
    this.lifetime = 30,
    required this.weaponImagePath,
  });

  // ✅ دالة لتحويل الهجوم لـ Map
  Map<String, dynamic> toMap() {
    return {
      'type': type.toString(),
      'x': x,
      'y': y,
      'directionX': directionX,
      'isActive': isActive,
      'damage': damage,
      'speed': speed,
      'range': range,
      'color': color.value,
      'lifetime': lifetime,
      'weaponImagePath': weaponImagePath,
    };
  }

  // ✅ دالة للتحديث
  void update() {
    if (isActive) {
      x += directionX * speed;
      lifetime--;
      if (lifetime <= 0) {
        isActive = false;
      }
    }
  }
  @override
  String toString() {
    return 'OnlineBattleAttack($type, damage: $damage, pos: ($x, $y))';
  }
  // ✅ التحقق مما إذا كان الهزال نشطاً
  bool get isValid => isActive && lifetime > 0 && !x.isNaN && !y.isNaN;
}

class OnlineWeaponLibrary {
  static final Map<OnlineWeaponType, OnlineWeapon> weapons = {
    OnlineWeaponType.sword: OnlineWeapon(
      type: OnlineWeaponType.sword,
      name: 'سيف',
      nameEn: 'Sword',
      damage: 20,
      speed: 1.2,
      range: 0.12,
      imagePath: 'assets/online/weapons/sword.png',
      attackColor: Colors.blue,
    ),
    OnlineWeaponType.hammer: OnlineWeapon(
      type: OnlineWeaponType.hammer,
      name: 'مطرقة',
      nameEn: 'Hammer',
      damage: 28,
      speed: 0.8,
      range: 0.15,
      imagePath: 'assets/online/weapons/hammer.png',
      attackColor: Colors.orange,
    ),
    OnlineWeaponType.bow: OnlineWeapon(
      type: OnlineWeaponType.bow,
      name: 'قوس',
      nameEn: 'Bow',
      damage: 18,
      speed: 1.8,
      range: 0.25,
      imagePath: 'assets/online/weapons/bow.png',
      attackColor: Colors.green,
    ),
    OnlineWeaponType.spear: OnlineWeapon(
      type: OnlineWeaponType.spear,
      name: 'رمح',
      nameEn: 'Spear',
      damage: 22,
      speed: 1.3,
      range: 0.18,
      imagePath: 'assets/online/weapons/spear.png',
      attackColor: Colors.yellow,
    ),
    OnlineWeaponType.katars: OnlineWeapon(
      type: OnlineWeaponType.katars,
      name: 'مخالب',
      nameEn: 'Katars',
      damage: 16,
      speed: 2.0,
      range: 0.08,
      imagePath: 'assets/online/weapons/katars.png',
      attackColor: Colors.purple,
    ),
    OnlineWeaponType.gauntlets: OnlineWeapon(
      type: OnlineWeaponType.gauntlets,
      name: 'قفازات',
      nameEn: 'Gauntlets',
      damage: 24,
      speed: 1.1,
      range: 0.09,
      imagePath: 'assets/online/weapons/gauntlets.png',
      attackColor: Colors.red,
    ),
    OnlineWeaponType.blasters: OnlineWeapon(
      type: OnlineWeaponType.blasters,
      name: 'مسدسات',
      nameEn: 'Blasters',
      damage: 19,
      speed: 1.6,
      range: 0.20,
      imagePath: 'assets/online/weapons/blasters.png',
      attackColor: Colors.cyan,
    ),
    OnlineWeaponType.orb: OnlineWeapon(
      type: OnlineWeaponType.orb,
      name: 'كرة',
      nameEn: 'Orb',
      damage: 21,
      speed: 1.4,
      range: 0.14,
      imagePath: 'assets/online/weapons/orb.png',
      attackColor: Colors.pink,
    ),
    OnlineWeaponType.staff: OnlineWeapon(
      type: OnlineWeaponType.staff,
      name: 'عصا سحرية',
      nameEn: 'Staff',
      damage: 23,
      speed: 1.2,
      range: 0.16,
      imagePath: 'assets/online/weapons/staff.png',
      attackColor: Colors.deepPurple,
    ),
    OnlineWeaponType.axe: OnlineWeapon(
      type: OnlineWeaponType.axe,
      name: 'فأس',
      nameEn: 'Axe',
      damage: 26,
      speed: 0.9,
      range: 0.13,
      imagePath: 'assets/online/weapons/axe.png',
      attackColor: Colors.brown,
    ),
    OnlineWeaponType.dagger: OnlineWeapon(
      type: OnlineWeaponType.dagger,
      name: 'خنجر',
      nameEn: 'dagger',
      damage: 26,
      speed: 0.9,
      range: 0.13,
      imagePath: 'assets/online/weapons/dagger.png',
      attackColor: Colors.tealAccent,
    ),
  };

  // ✅ دالة ترحيب لطباعة جميع الأسلحة
  static void debugWeapons() {
    print('🔫 === مكتبة الأسلحة ===');
    weapons.forEach((type, weapon) {
      print('   ${weapon.name} (${type.toString().split('.').last})');
      print('     🎯 ضرر: ${weapon.damage}');
      print('     🏃 سرعة: ${weapon.speed}');
      print('     📏 مدى: ${weapon.range}');
      print('     📁 مسار: ${weapon.imagePath}');
    });
    print('========================');
  }

  static OnlineWeapon getWeapon(OnlineWeaponType type) => weapons[type]!;
}

class OnlineCharacter {
  final int id;
  final String name;
  final String nameEn;
  final String type;
  final String imagePath;
  final String iconPath;
  final bool isLocked;
  final int price;
  final OnlineWeaponType primaryWeapon;
  final OnlineWeaponType secondaryWeapon;
  final String specialAbility;
  final double specialAbilityCooldown;
  final Color characterColor;
  final String animationConfigPath;

  OnlineCharacter({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.type,
    required this.imagePath,
    required this.iconPath,
    this.isLocked = false,
    this.price = 0,
    required this.primaryWeapon,
    required this.secondaryWeapon,
    required this.specialAbility,
    this.specialAbilityCooldown = 10.0,
    required this.characterColor,
    this.animationConfigPath = 'assets/animations/default_animations.json',
  });

  static List<OnlineCharacter> getAllOnlineCharacters() {
    return [
      OnlineCharacter(
        id: 1,
        name: 'عالماشي',
        nameEn: '3almaShe',
        type: 'أساسي',
        imagePath: 'assets/images/characters/almashe/almashe_idle_1.png',
        iconPath: 'assets/images/characters/almashe/almashe_icon.png',
        primaryWeapon: OnlineWeaponType.sword,
        secondaryWeapon: OnlineWeaponType.bow,
        specialAbility: 'صندوق عالماشي',
        characterColor: Colors.blue,
        animationConfigPath: 'assets/animations/almashe_animations.json',
      ),
      OnlineCharacter(
        id: 2,
        name: 'ألوان الطيف',
        nameEn: 'Rainbow Colors',
        type: 'ألوان',
        imagePath: 'assets/images/characters/rainbow/rainbow_idle_1.png',
        iconPath: 'assets/images/characters/rainbow/rainbow_icon.png',
        isLocked: true,
        price: 1499,
        primaryWeapon: OnlineWeaponType.bow,
        secondaryWeapon: OnlineWeaponType.spear,
        specialAbility: 'شعاع قوس قزح',
        characterColor: Colors.pink,
        animationConfigPath: 'assets/animations/rainbow_animations.json',
      ),
      OnlineCharacter(
        id: 3,
        name: 'عربي',
        nameEn: 'Arabic',
        type: 'تراثي',
        imagePath: 'assets/images/characters/arabic/arabic_idle_1.png',
        iconPath: 'assets/images/characters/arabic/arabic_icon.png',
        isLocked: true,
        price: 1699,
        primaryWeapon: OnlineWeaponType.spear,
        secondaryWeapon: OnlineWeaponType.sword,
        specialAbility: 'الصقر العربي',
        characterColor: Colors.green,
        animationConfigPath: 'assets/animations/arabic_animations.json',
      ),
      OnlineCharacter(
        id: 4,
        name: 'العصور وسطى',
        nameEn: 'Medieval',
        type: 'تاريخي',
        imagePath: 'assets/images/characters/medieval/medieval_idle_1.png',
        iconPath: 'assets/images/characters/medieval/medieval_icon.png',
        isLocked: true,
        price: 999,
        primaryWeapon: OnlineWeaponType.hammer,
        secondaryWeapon: OnlineWeaponType.gauntlets,
        specialAbility: 'كرات الطين',
        characterColor: Colors.orange,
        animationConfigPath: 'assets/animations/medieval_animations.json',
      ),
      OnlineCharacter(
        id: 5,
        name: 'أغريقي',
        nameEn: 'Greek',
        type: 'تاريخي',
        imagePath: 'assets/images/characters/greek/greek_idle_1.png',
        iconPath: 'assets/images/characters/greek/greek_icon.png',
        isLocked: true,
        price: 1499,
        primaryWeapon: OnlineWeaponType.spear,
        secondaryWeapon: OnlineWeaponType.orb,
        specialAbility: 'صاعقة زيوس',
        characterColor: Colors.blue.shade800,
        animationConfigPath: 'assets/animations/greek_animations.json',
      ),
      OnlineCharacter(
        id: 6,
        name: 'ثلجي',
        nameEn: 'Snowy',
        type: 'طبيعي',
        imagePath: 'assets/images/characters/snowy/snowy_idle_1.png',
        iconPath: 'assets/images/characters/snowy/snowy_icon.png',
        isLocked: true,
        price: 1799,
        primaryWeapon: OnlineWeaponType.orb,
        secondaryWeapon: OnlineWeaponType.dagger,
        specialAbility: 'كرة الثلج',
        characterColor: Colors.cyan,
        animationConfigPath: 'assets/animations/snowy_animations.json',
      ),
      OnlineCharacter(
        id: 7,
        name: 'ناري',
        nameEn: 'Fiery',
        type: 'عنصري',
        imagePath: 'assets/images/characters/fiery/fiery_idle_1.png',
        iconPath: 'assets/images/characters/fiery/fiery_icon.png',
        isLocked: true,
        price: 1899,
        primaryWeapon: OnlineWeaponType.gauntlets,
        secondaryWeapon: OnlineWeaponType.axe,
        specialAbility: 'كرات النار',
        characterColor: Colors.orange,
        animationConfigPath: 'assets/animations/fiery_animations.json',
      ),
      OnlineCharacter(
        id: 8,
        name: 'تقني',
        nameEn: 'Techno',
        type: 'مستقبلي',
        imagePath: 'assets/images/characters/techno/techno_idle_1.png',
        iconPath: 'assets/images/characters/techno/techno_icon.png',
        isLocked: true,
        price: 1999,
        primaryWeapon: OnlineWeaponType.blasters,
        secondaryWeapon: OnlineWeaponType.staff,
        specialAbility: 'موجة التهكير',
        characterColor: Colors.purple,
        animationConfigPath: 'assets/animations/techno_animations.json',
      ),
      OnlineCharacter(
        id: 9,
        name: 'محاربي الفايكنج',
        nameEn: 'Viking Warrior',
        type: 'محارب',
        imagePath: 'assets/images/characters/viking/viking_idle_1.png',
        iconPath: 'assets/images/characters/viking/viking_icon.png',
        isLocked: true,
        price: 2199,
        primaryWeapon: OnlineWeaponType.hammer,
        secondaryWeapon: OnlineWeaponType.axe,
        specialAbility: 'مطرقة ثور',
        characterColor: Colors.brown,
        animationConfigPath: 'assets/animations/viking_animations.json',
      ),
      OnlineCharacter(
        id: 10,
        name: 'كوميكس',
        nameEn: 'Comics',
        type: 'كوميكس',
        imagePath: 'assets/images/characters/comics/comics_idle_1.png',
        iconPath: 'assets/images/characters/comics/comics_icon.png',
        isLocked: true,
        price: 2299,
        primaryWeapon: OnlineWeaponType.gauntlets,
        secondaryWeapon: OnlineWeaponType.katars,
        specialAbility: 'POW!',
        characterColor: Colors.red,
        animationConfigPath: 'assets/animations/comics_animations.json',
      ),
      OnlineCharacter(
        id: 11,
        name: 'زومبي',
        nameEn: 'Zombie',
        type: 'رعب',
        imagePath: 'assets/images/characters/zombie/zombie_idle_1.png',
        iconPath: 'assets/images/characters/zombie/zombie_icon.png',
        isLocked: true,
        price: 2499,
        primaryWeapon: OnlineWeaponType.dagger,
        secondaryWeapon: OnlineWeaponType.katars,
        specialAbility: 'كرة اللعاب',
        characterColor: Colors.green.shade800,
        animationConfigPath: 'assets/animations/zombie_animations.json',
      ),
      OnlineCharacter(
        id: 12,
        name: 'مُطلق النار',
        nameEn: 'Shooter',
        type: 'تكتيكي',
        imagePath: 'assets/images/characters/warrior/warrior_idle_1.png',
        iconPath: 'assets/images/characters/warrior/warrior_icon.png',
        isLocked: true,
        price: 2999,
        primaryWeapon: OnlineWeaponType.blasters,
        secondaryWeapon: OnlineWeaponType.sword,
        specialAbility: 'رصاصة M4',
        characterColor: Colors.grey.shade700,
        animationConfigPath: 'assets/animations/warrior_animations.json',
      ),
    ];
  }

  static OnlineCharacter getDefaultCharacter() {
    return getAllOnlineCharacters().first;
  }

  static List<OnlineCharacter> getFreeCharacters() {
    return getAllOnlineCharacters().where((char) => char.price == 0).toList();
  }

  bool get isFree => price == 0;

  List<OnlineWeaponType> get weapons => [primaryWeapon, secondaryWeapon];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nameEn': nameEn,
      'type': type,
      'imagePath': imagePath,
      'iconPath': iconPath,
      'isLocked': isLocked,
      'price': price,
      'primaryWeapon': primaryWeapon.toString(),
      'secondaryWeapon': secondaryWeapon.toString(),
      'specialAbility': specialAbility,
      'specialAbilityCooldown': specialAbilityCooldown,
      'characterColor': characterColor.value,
      'animationConfigPath': animationConfigPath,
    };
  }

  static OnlineCharacter fromJson(Map<String, dynamic> json) {
    return OnlineCharacter(
      id: json['id'],
      name: json['name'],
      nameEn: json['nameEn'],
      type: json['type'],
      imagePath: json['imagePath'],
      iconPath: json['iconPath'] ?? json['imagePath'],
      isLocked: json['isLocked'],
      price: json['price'],
      primaryWeapon: OnlineWeaponType.values.firstWhere(
            (e) => e.toString() == json['primaryWeapon'],
      ),
      secondaryWeapon: OnlineWeaponType.values.firstWhere(
            (e) => e.toString() == json['secondaryWeapon'],
      ),
      specialAbility: json['specialAbility'],
      specialAbilityCooldown: json['specialAbilityCooldown'],
      characterColor: Color(json['characterColor']),
      animationConfigPath: json['animationConfigPath'] ?? 'assets/animations/default_animations.json',
    );
  }
}

enum PlayerState {
  idle,
  running,
  jumping,
  falling,
  attacking_light,   // ✅ هجوم خفيف
  attacking_heavy,   // ✅ هجوم ثقيل
  hurt,              // ✅ حالة الضرر (تأثير واحد)
  death,             // ✅ حالة الموت
  dodge,             // ✅ مراوغة (اختياري)
}

class OnlinePlayer {
  String playerId;
  OnlineCharacter character;
  double x, y;
  double velocityX = 0.0;
  double velocityY = 0.0;
  double health;
  bool isFacingRight;
  List<OnlineWeapon> weapons;
  List<OnlineWeapon> backupWeapons = [];
  int currentWeaponIndex;
  int attackCooldown = 0;
  int damageCooldown = 0;
  bool canMove = true;
  int deathCount = 0;

  // متغيرات السقوط
  bool hasUsedDoubleJump = false;
  double fallStartY = 0.0;
  bool isInFallDeathZone = false;
  int fallDeathCooldown = 0;
  bool _mounted = true;

  OnlineAttackType currentAttackType = OnlineAttackType.light;
  String _lastFramePath = '';

  // النظام الجديد للأنيميشن
  late AdvancedAnimationController _animationController;
  late AnimationStateMachine _stateMachine;
  String _currentFramePath = '';

  // ✅ متغير واحد فقط للحالة
  late PlayerState _state;

  // ✅ متغير واحد فقط لـ isGrounded
  bool _isGrounded = false;

  bool _canDoubleJump = true;
  bool _hasDoubleJumped = false;

  // ✅ متغيرات التوقيت
  int _lastStateChangeTime = 0;
  static const int STATE_CHANGE_DELAY = 100; // 100ms بين تغييرات الحالة
  int _frameCheckCounter = 0;

  bool _isRespawning = false;
  bool _isFinalDeath = false;

  bool get isRespawning => _isRespawning;
  bool get isFinalDeath => _isFinalDeath;

  AdvancedAnimationController get animationController => _animationController;

  // ✅ Constructor
  OnlinePlayer({
    required this.playerId,
    required this.character,
    this.x = 0.5,
    this.y = 0.7,
    this.health = 100.0,
    this.isFacingRight = true,
    PlayerState initialState = PlayerState.idle,
    required this.weapons,
    this.currentWeaponIndex = 0,
  }) : _state = initialState {
    _initializeAnimationSystem();
  }

  // ✅ Getter للحالة
  PlayerState get state => _state;

  // ✅ Setter للحالة مع منع التغيير السريع
  set state(PlayerState newState) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final oldState = _state; // ✅ تعريف المتغير في البداية

    // ✅ منع تغيير الحالة من dead إلى أي شيء آخر إذا كان الموت نهائياً
    if (_state == PlayerState.death && newState != PlayerState.death) {
      // ✅ التحقق: هل هذا موت نهائي أم مؤقت؟
      if (_isFinalDeath) {
        // موت نهائي - ممنوع تغيير الحالة
        print('⏸️ [STATE] منع تغيير الحالة - موت نهائي (من $oldState إلى $newState)');
        return;
      } else if (_animationController.isDying) {
        // لا يزال في أنيميشن الموت - ننتظر
        print('⏸️ [STATE] منع تغيير الحالة - لا يزال في أنيميشن الموت');
        return;
      } else {
        // موت مؤقت وانتهى الأنيميشن - مسموح بالتغيير
        print('🔄 [STATE] موت مؤقت انتهى - مسموح بالتغيير إلى $newState');
        // نستمر للأسفل
      }
    }

    // ✅ منع تغيير الحالة أثناء أنيميشن الموت (تأكيد إضافي)
    if (_animationController.isDying && newState != PlayerState.death) {
      print('⏸️ [STATE] منع تغيير الحالة أثناء أنيميشن الموت');
      return;
    }

    if (now - _lastStateChangeTime < STATE_CHANGE_DELAY) {
      return;
    }

    if (_state == newState) return;

    _state = newState;
    _lastStateChangeTime = now;

    print('🔄 تغيير حالة اللاعب: $oldState → $newState');

    // تحديث الأنيميشن
    AnimationState targetAnimState = _mapPlayerStateToAnimationState(_state);
    _animationController.transitionToState(
      targetAnimState,
      reason: "player_state_change",
    );
  }

  // ✅ Getter لـ isGrounded
  bool get isGrounded => _isGrounded;

  // ✅ Setter لـ isGrounded بسيط
  set isGrounded(bool value) {
    if (_isGrounded == value) return;

    print('🔄 تغيير isGrounded: $_isGrounded → $value للاعب $playerId');
    print('   📍 الموقع: (${x.toStringAsFixed(3)}, ${y.toStringAsFixed(3)})');

    _isGrounded = value;

    // إذا لمس الأرض، أعد تعيين القفز المزدوج
    if (value) {
      resetDoubleJump();
    }
  }

  void _initializeAnimationSystem() {
    try {
      final characterId = _getCharacterAnimationId();
      final animationManager = AnimationManager();

      _animationController = animationManager.createController(characterId, playerId);

      _animationController.transitionToState(
        _mapPlayerStateToAnimationState(_state),
        reason: "initialization",
      );

      // إنشاء State Machine
      _stateMachine = animationManager.createStateMachine(
        playerId,
        _getDefaultStateConfigs(),
        AnimationState.idle,
      );

      print('✅ نظام الأنيميشن مهيئ للاعب: $playerId');
    } catch (e) {
      print('❌ فشل تهيئة نظام الأنيميشن: $e');
    }
  }

  // ✅ دالة تحديث الحالة من الفيزياء
  void updateStateFromPhysics() {
    if (_isFinalDeath) return;
    if (_state == PlayerState.death) return;
    if (_animationController.isDying) return;

    // ✅ لا تغير الحالة أثناء الهجوم أو الضرر
    if (_state == PlayerState.attacking_light ||
        _state == PlayerState.attacking_heavy ||
        _state == PlayerState.hurt) {
      return;
    }

    PlayerState suggestedState = _state;

    if (!_isGrounded) {
      if (velocityY < -0.008) {
        suggestedState = PlayerState.jumping;
      } else if (velocityY > 0.008) {
        suggestedState = PlayerState.falling;
      } else {
        if (suggestedState != PlayerState.jumping && suggestedState != PlayerState.falling) {
          suggestedState = PlayerState.falling;
        }
      }
    } else {
      if (velocityX.abs() > 0.012) {
        suggestedState = PlayerState.running;
      } else {
        suggestedState = PlayerState.idle;
      }
    }

    if (suggestedState != _state) {
      state = suggestedState;
    }
  }

  // ✅ تحديث الأنيميشن
  void updateAnimation(double deltaTimeMs) {
    _animationController.update(deltaTimeMs);
    _currentFramePath = _animationController.getCurrentFramePath(AnimationLayer.fullBody);
  }

  // ✅ تحديث الأنيميشن فقط (للخصم)
  void updateAnimationOnly(double deltaTimeMs) {
    _animationController.update(deltaTimeMs);
    _currentFramePath = _animationController.getCurrentFramePath(AnimationLayer.fullBody);
  }

// ✅ تحويل PlayerState إلى AnimationState
  AnimationState _mapPlayerStateToAnimationState(PlayerState playerState) {
    switch (playerState) {
      case PlayerState.attacking_light:
        return AnimationState.attacking_light;

      case PlayerState.attacking_heavy:
        return AnimationState.attacking_heavy;

      case PlayerState.hurt:      // ✅ استخدم hurt فقط
        return AnimationState.damaged;  // أو AnimationState.hurt

      case PlayerState.death:
        return AnimationState.death;

      case PlayerState.jumping:
        return AnimationState.jumping;

      case PlayerState.falling:
        return AnimationState.falling;

      case PlayerState.running:
        return AnimationState.running;

      case PlayerState.dodge:
        return AnimationState.dodge;

      case PlayerState.idle:
      default:
        return AnimationState.idle;
    }
  }

  // ✅ دوال مساعدة
  String getCharacterAnimationId() => _getCharacterAnimationId();

  String getAnimationStateKey(AnimationState state) {
    switch (state) {
      case AnimationState.idle:
        return 'idle';
      case AnimationState.running:
        return 'run';
      case AnimationState.jumping:
        return 'jump';
      case AnimationState.falling:
        return 'fall';
      case AnimationState.attacking_light:
        return 'light_attack';
      case AnimationState.attacking_heavy:
        return 'heavy_attack';
      case AnimationState.attacking_aerial:
        return 'aerial_attack';
      case AnimationState.dodge:
        return 'dodge';
      case AnimationState.damaged:
        return 'hurt';     // ✅ مهم: في مجلدات الصور هي 'hurt'
      case AnimationState.hurt:
        return 'hurt';     // ✅ نفس المسار
      case AnimationState.death:
        return 'death';
    }
  }

  String _getCharacterAnimationId() {
    switch (character.id) {
      case 1: return 'almashe';
      case 2: return 'rainbow';
      case 3: return 'arabic';
      case 4: return 'medieval';
      case 5: return 'greek';
      case 6: return 'snowy';
      case 7: return 'fiery';
      case 8: return 'techno';
      case 9: return 'viking';
      case 10: return 'comics';
      case 11: return 'zombie';
      case 12: return 'warrior';
      default: return 'almashe';
    }
  }

  AnimationState getCorrectAnimationState() {
    return _mapPlayerStateToAnimationState(_state);
  }

  String get currentFramePath {
    return _currentFramePath.isNotEmpty ? _currentFramePath : character.imagePath;
  }

  void updateAnimationFrame(String framePath) {
    _currentFramePath = framePath;
  }

  Map<AnimationState, AnimationStateConfig> _getDefaultStateConfigs() {
    return {
      AnimationState.idle: AnimationStateConfig(state: AnimationState.idle, canBeInterrupted: true),
      AnimationState.running: AnimationStateConfig(state: AnimationState.running, canBeInterrupted: true),
      AnimationState.jumping: AnimationStateConfig(state: AnimationState.jumping, canBeInterrupted: false),
      AnimationState.falling: AnimationStateConfig(state: AnimationState.falling, canBeInterrupted: false),
      AnimationState.attacking_light: AnimationStateConfig(state: AnimationState.attacking_light, canBeInterrupted: false),
      AnimationState.attacking_heavy: AnimationStateConfig(state: AnimationState.attacking_heavy, canBeInterrupted: false),
      AnimationState.dodge: AnimationStateConfig(state: AnimationState.dodge, canBeInterrupted: false),
      AnimationState.damaged: AnimationStateConfig(state: AnimationState.damaged, canBeInterrupted: false),
      AnimationState.death: AnimationStateConfig(state: AnimationState.death, canBeInterrupted: false),
    };
  }

  // ✅ دوال الهجوم
  void performLightAttack() {
    if (attackCooldown > 0 || _state == PlayerState.death || !canMove) return;
    state = PlayerState.attacking_light;  // ✅ مباشرة
    attackCooldown = 15;
  }

  void performHeavyAttack() {
    if (attackCooldown > 0 || _state == PlayerState.death || !canMove) return;
    state = PlayerState.attacking_heavy;  // ✅ مباشرة
    attackCooldown = 30;
  }

  void performPunch() {
    if (attackCooldown > 0 || _state == PlayerState.death || !canMove) return;
    state = PlayerState.attacking_light;  // ✅ الملاكمة = هجوم خفيف
    attackCooldown = 15;
  }

  void _launchWeaponAttack() {
    if (weapons.isNotEmpty && currentWeapon != null) {
      final weapon = currentWeapon!;
      final attackX = x + (isFacingRight ? 0.08 : -0.08);
      final attackY = y - 0.02;

      final attack = weapon.createAttack(
        currentAttackType,
        attackX,
        attackY,
        isFacingRight,
      );

      _addWeaponAttackToGame(attack);
    }
  }

  void _addWeaponAttackToGame(OnlineBattleAttack attack) {
    try {
      OnlineGameService.instance.addPlayerAttack(attack, playerId);
    } catch (e) {
      print('❌ خطأ في إضافة الهجوم: $e');
    }
  }

  void _performPunchAttack() {
    print('👊 ملاكمة');
    OnlineAudioService().playPunchSound();
  }

  void _checkPunchCollision() {
    // ستتم معالجتها في OnlineGameService
  }

  // ✅ دوال القفز والسلاح
  void performJump() {
    if (_state == PlayerState.death || !canMove) return;

    if (_isGrounded) {
      // القفزة الأولى
      velocityY = -0.04;
      state = PlayerState.jumping;
      isGrounded = false;
      fallStartY = y;
      _canDoubleJump = true;
      _hasDoubleJumped = false;
      print('🦘 قفزة أولى');
    } else if (_canDoubleJump && !_hasDoubleJumped) {
      // القفزة المزدوجة
      velocityY = -0.032;
      _hasDoubleJumped = true;
      print('🦘🦘 قفزة مزدوجة');
    }
  }

  // ✅ إعادة تعيين القفز المزدوج عند لمس الأرض
  void resetDoubleJump() {
    _canDoubleJump = true;
    _hasDoubleJumped = false;
  }

  void pickUpWeapon(OnlineWeapon weapon) {
    if (weapons.length >= 2) weapons.removeAt(0);
    weapons.add(weapon);
    currentWeaponIndex = weapons.length - 1;
  }

  OnlineWeapon? get currentWeapon =>
      weapons.isNotEmpty ? weapons[currentWeaponIndex] : null;

  void switchWeapon() {
    if (weapons.length > 1) {
      currentWeaponIndex = (currentWeaponIndex + 1) % weapons.length;
    }
  }

  // ✅ دالة لبدء الموت
  void startDeath(bool isFinal) {
    _isFinalDeath = isFinal;
    _isRespawning = !isFinal;
    state = PlayerState.death;
    canMove = false;
    _animationController.startDeathAnimation(isFinal: isFinal);
  }

  // ✅ دالة لبدء الإحياء
  void startRespawn() {
    _isRespawning = true;
    _isFinalDeath = false;

    // ✅ إعادة تعيين الحالة أولاً
    health = 100;
    canMove = true;
    velocityX = 0;
    velocityY = -0.01;
    isGrounded = false;

    // ✅ تغيير PlayerState إلى idle أولاً
    _state = PlayerState.idle;

    // ✅ إنهاء أنيميشن الموت بالقوة
    _animationController.endDeathAnimation();

    // ✅ إعادة تعيين الأنيميشن بالقوة
    forceAnimationReset();

    // ✅ ✅ ✅ استخدام character.imagePath كحل آمن
    _currentFramePath = character.imagePath;

    print('✨ تم إحياء اللاعب $playerId');
  }

  void _addRespawnEffect() {
    // يمكن إضافة تأثيرات بصرية هنا
    print('✨ تم إحياء اللاعب $playerId');
  }

  // ✅ دالة للتحقق مما إذا كان يمكن تغيير الحالة
  bool canChangeState() {
    // ✅ لا يمكن تغيير الحالة أثناء أنيميشن الموت
    if (_animationController.isDying) {
      return false;
    }
    // ✅ لا يمكن تغيير الحالة إذا كان ميتاً نهائياً
    if (_isFinalDeath) {
      return false;
    }
    return true;
  }

  // ✅ دوال الضرر والموت
  void takeDamage(int damage) {
    health -= damage;
    state = PlayerState.hurt;  // ✅ استخدم hurt بدلاً من damaged
    damageCooldown = 20;
    canMove = false;

    if (health <= 0) {
      health = 0;
      state = PlayerState.death;
      deathCount++;
      _loseWeaponsOnDeath();
    }
  }

  void _loseWeaponsOnDeath() {
    if (weapons.isNotEmpty) {
      backupWeapons = List.from(weapons);
      weapons.clear();
      currentWeaponIndex = 0;
    }
  }

  void restoreWeaponsAfterRespawn() {
    if (backupWeapons.isNotEmpty) {
      final random = Random();
      final weaponsToRestore = random.nextInt(backupWeapons.length) + 1;
      weapons.addAll(backupWeapons.take(weaponsToRestore));
      backupWeapons.clear();
    } else {
      weapons.add(OnlineWeaponLibrary.getWeapon(character.primaryWeapon));
    }
    currentWeaponIndex = 0;
  }

  bool checkForFallDeath() {
    if (y > 1.2) return true;
    return false;
  }

  void resetMovement() {
    canMove = true;
  }

  // ✅ تحويل إلى Map
  Map<String, dynamic> toMap() {
    return {
      'playerId': playerId,
      'character': character.toJson(),
      'position': {'x': x, 'y': y},
      'velocity': {'x': velocityX, 'y': velocityY},
      'health': health,
      'isFacingRight': isFacingRight,
      'state': _state.toString(),
      'animationState': _animationController.currentState.toString(),
      'currentWeaponIndex': currentWeaponIndex,
      'currentFramePath': _currentFramePath,
      'isGrounded': _isGrounded,
      'attackCooldown': attackCooldown,
      'canMove': canMove,
      'deathCount': deathCount,
    };
  }

  static OnlinePlayer fromMap(Map<String, dynamic> map) {
    final player = OnlinePlayer(
      playerId: map['playerId'],
      character: OnlineCharacter.fromJson(map['character']),
      x: map['position']['x'],
      y: map['position']['y'],
      health: map['health'],
      isFacingRight: map['isFacingRight'],
      weapons: (map['weapons'] as List).map((w) =>
      OnlineWeaponLibrary.weapons[OnlineWeaponType.values.firstWhere(
            (e) => e.toString() == w['type'],
      )]!).toList(),
      currentWeaponIndex: map['currentWeaponIndex'],
    );

    player.velocityX = map['velocity']['x'];
    player.velocityY = map['velocity']['y'];
    player._isGrounded = map['isGrounded'] ?? false;
    player.attackCooldown = map['attackCooldown'] ?? 0;
    player.canMove = map['canMove'] ?? true;
    player._currentFramePath = map['currentFramePath'] ?? '';
    player.deathCount = map['deathCount'] ?? 0;

    if (map['animationState'] != null) {
      try {
        final animState = AnimationState.values.firstWhere(
              (e) => e.toString() == map['animationState'],
        );
        player._animationController.transitionToState(animState, reason: "from_map");
      } catch (e) {}
    }

    return player;
  }

   // ✅ دالة الهجوم (للبوت)
  void performAttack(OnlineAttackType attackType) {
    if (attackCooldown > 0 || _state == PlayerState.death || !canMove) return;

    currentAttackType = attackType;

    // ✅ تحديد نوع الهجوم بناءً على attackType
    if (attackType == OnlineAttackType.light) {
      state = PlayerState.attacking_light;
    } else if (attackType == OnlineAttackType.heavy) {
      state = PlayerState.attacking_heavy;
    } else if (attackType == OnlineAttackType.aerial) {
      state = PlayerState.attacking_light; // أو يمكنك إضافة حالة attacking_aerial
    } else {
      state = PlayerState.attacking_light; // افتراضي
    }

    attackCooldown = 25; // تبريد مناسب للهجوم

    print('⚔️ [ATTACK] البوت يهاجم: $attackType -> ${state}');

    // إطلاق الهجوم بعد تأخير بسيط
    Timer(Duration(milliseconds: 100), () {
      if (_state == PlayerState.attacking_light || _state == PlayerState.attacking_heavy) {
        _launchWeaponAttack();
      }
    });
  }

// ✅ دالة إعادة تعيين الأنيميشن بالقوة (للطوارئ)
  void forceAnimationReset() {
    print('🔄 🔥 إعادة تعيين قوية للأنيميشن!');
    try {
      final targetState = _getCorrectAnimationState();

      // إعادة تعيين المتحكم
      _animationController.resetState(targetState, resetFrame: true);

      // الحصول على الإطار الجديد
      _currentFramePath = _animationController.getCurrentFramePath(AnimationLayer.fullBody);

      print('✅ تم إعادة تعيين الأنيميشن');
    } catch (e) {
      print('❌ فشل إعادة تعيين الأنيميشن: $e');
      _currentFramePath = character.imagePath;
    }
  }

// ✅ دالة للحصول على الحالة الصحيحة للأنيميشن
  AnimationState _getCorrectAnimationState() {
    return _mapPlayerStateToAnimationState(_state);
  }

  void dispose() {
    _mounted = false;
    AnimationManager().disposeController(playerId);
  }
}

// ============ نظام المنصات العشوائية ============
enum PlatformType {
  ground,
  main,
  floating,
  small,
  maze,
  tower,
  bridge,
  extra,
}

class PlatformPattern {
  final String name;
  final String description;
  final Color primaryColor;
  final Color secondaryColor;
  final List<Map<String, dynamic>> platformConfigs;
  final int platformCount;

  PlatformPattern({
    required this.name,
    required this.description,
    required this.primaryColor,
    required this.secondaryColor,
    required this.platformConfigs,
    this.platformCount = 5,
  });
}

// ✅ المنصات
class PlatformGenerator {
  static final Random _random = Random();

  // ✅ ألوان متناسقة وجميلة للمنصات
  static final List<Color> _platformColors = [
    Color(0xFF8B4513), // خشبي غامق
    Color(0xFFA0522D), // خشبي فاتح
    Color(0xFFCD853F), // برتقالي ترابي
    Color(0xFFD2691E), // شوكولاتة
    Color(0xFFB8860B), // ذهبي داكن
    Color(0xFF9ACD32), // أخضر فاتح
    Color(0xFF6B8E23), // أخضر زيتوني
    Color(0xFF4682B4), // أزرق فولاذي
    Color(0xFF5F9EA0), // أزرق مخضر
    Color(0xFF9370DB), // بنفسجي متوسط
  ];

  // ✅ ثوابت المسافات
  static const double MIN_HORIZONTAL_GAP = 0.18;  // المسافة الأفقية الدنيا بين المنصات
  static const double MIN_VERTICAL_GAP = 0.12;    // المسافة العمودية الدنيا بين المنصات
  static const double PLATFORM_WIDTH_RANGE = 0.20; // نطاق عرض المنصة (0.15-0.35)
  static const double PLATFORM_HEIGHT = 0.035;    // ارتفاع ثابت وجميل للمنصات

  // ✅ أنماط المنصات المحسنة
  static final List<PlatformPattern> _patterns = [
    PlatformPattern(
      name: 'كلاسيكي متوازن',
      description: 'منصات متباعدة بشكل جيد مع مسافات مناسبة للقفز',
      primaryColor: Color(0xFF8B4513),
      secondaryColor: Color(0xFFCD853F),
      platformConfigs: [
        // ✅ منصة أرضية رئيسية
        {'type': 'ground', 'x': 0.5, 'y': 1.48, 'w': 2.2, 'h': 0.08},
        // ✅ منصات متوسطة متباعدة بشكل جيد
        {'type': 'main_left', 'x': 0.22, 'y': 0.92, 'w': 0.28, 'h': 0.04},
        {'type': 'main_right', 'x': 0.78, 'y': 0.92, 'w': 0.28, 'h': 0.04},
        // ✅ منصات علوية
        {'type': 'upper_left', 'x': 0.15, 'y': 0.65, 'w': 0.22, 'h': 0.035},
        {'type': 'upper_center', 'x': 0.5, 'y': 0.68, 'w': 0.25, 'h': 0.035},
        {'type': 'upper_right', 'x': 0.85, 'y': 0.65, 'w': 0.22, 'h': 0.035},
        // ✅ منصة مركزية مرتفعة
        {'type': 'center_high', 'x': 0.5, 'y': 0.48, 'w': 0.22, 'h': 0.03},
      ],
    ),
    PlatformPattern(
      name: 'أبراج متباعدة',
      description: 'أبراج منفصلة مع مسافات عمودية مناسبة',
      primaryColor: Color(0xFF4682B4),
      secondaryColor: Color(0xFF5F9EA0),
      platformConfigs: [
        {'type': 'ground', 'x': 0.5, 'y': 1.48, 'w': 2.2, 'h': 0.08},
        // ✅ البرج الأيسر - منصات متباعدة عمودياً
        {'type': 'tower_left_1', 'x': 0.2, 'y': 0.92, 'w': 0.22, 'h': 0.04},
        {'type': 'tower_left_2', 'x': 0.2, 'y': 0.68, 'w': 0.22, 'h': 0.035},
        {'type': 'tower_left_3', 'x': 0.2, 'y': 0.45, 'w': 0.2, 'h': 0.03},
        // ✅ البرج الأيمن - منصات متباعدة عمودياً
        {'type': 'tower_right_1', 'x': 0.8, 'y': 0.92, 'w': 0.22, 'h': 0.04},
        {'type': 'tower_right_2', 'x': 0.8, 'y': 0.68, 'w': 0.22, 'h': 0.035},
        {'type': 'tower_right_3', 'x': 0.8, 'y': 0.45, 'w': 0.2, 'h': 0.03},
        // ✅ منصة مركزية
        {'type': 'center', 'x': 0.5, 'y': 0.56, 'w': 0.2, 'h': 0.03},
      ],
    ),
    PlatformPattern(
      name: 'جسر معلق',
      description: 'جسور متصلة مع مسافات آمنة للقفز',
      primaryColor: Color(0xFFD2691E),
      secondaryColor: Color(0xFFCD853F),
      platformConfigs: [
        {'type': 'ground', 'x': 0.5, 'y': 1.48, 'w': 2.2, 'h': 0.08},
        // ✅ جسر سفلي
        {'type': 'bridge_low_left', 'x': 0.25, 'y': 0.92, 'w': 0.28, 'h': 0.04},
        {'type': 'bridge_low_right', 'x': 0.75, 'y': 0.92, 'w': 0.28, 'h': 0.04},
        // ✅ جسر علوي متصل
        {'type': 'bridge_high_left', 'x': 0.18, 'y': 0.68, 'w': 0.25, 'h': 0.035},
        {'type': 'bridge_high_center', 'x': 0.5, 'y': 0.68, 'w': 0.3, 'h': 0.035},
        {'type': 'bridge_high_right', 'x': 0.82, 'y': 0.68, 'w': 0.25, 'h': 0.035},
        // ✅ منصة نهائية
        {'type': 'final_platform', 'x': 0.5, 'y': 0.48, 'w': 0.24, 'h': 0.03},
      ],
    ),
    PlatformPattern(
      name: 'عشوائي متقدم',
      description: 'منصات عشوائية مع ضمان مسافات آمنة',
      primaryColor: Color(0xFF9370DB),
      secondaryColor: Color(0xFFBA55D3),
      platformCount: 6,
      platformConfigs: [],
    ),
  ];

  static PlatformPattern getRandomPattern() {
    return _patterns[_random.nextInt(_patterns.length)];
  }

  static PlatformPattern? getPatternByName(String name) {
    try {
      return _patterns.firstWhere((pattern) => pattern.name == name);
    } catch (e) {
      print('⚠️ لم يتم العثور على النمط "$name"');
      return null;
    }
  }

  static List<BattlePlatform> generatePlatformsFromPattern(PlatformPattern pattern) {
    final List<BattlePlatform> platforms = [];

    if (pattern.platformConfigs.isNotEmpty) {
      for (var config in pattern.platformConfigs) {
        final platform = _createPlatformFromConfig(config, pattern);
        platforms.add(platform);
      }
    } else {
      final count = pattern.platformCount > 0 ? pattern.platformCount : 5;
      platforms.addAll(_generateRandomPlatformsWithGaps(count, pattern));
    }

    // ✅ التحقق من المسافات وتصحيحها
    return _validatePlatformSpacing(platforms);
  }

  static BattlePlatform _createPlatformFromConfig(
      Map<String, dynamic> config,
      PlatformPattern pattern) {
    final type = config['type'] as String;
    double x = config['x'] as double;
    double y = config['y'] as double;
    double width = config['w'] as double;
    double height = config['h'] as double;

    Color platformColor;

    if (type == 'ground') {
      platformColor = pattern.primaryColor;
    } else if (type.contains('main') || type.contains('bridge')) {
      platformColor = pattern.primaryColor.withOpacity(0.9);
    } else {
      platformColor = pattern.secondaryColor;
    }

    // ✅ تباين بسيط في الألوان
    if (_random.nextDouble() < 0.2) {
      platformColor = _platformColors[_random.nextInt(_platformColors.length)];
    }

    return BattlePlatform(
      x: x,
      y: y,
      width: width * (0.95 + _random.nextDouble() * 0.1),
      height: height,
      type: type,
      color: platformColor,
    );
  }

  // ✅ دالة جديدة لتوليد منصات عشوائية مع مسافات آمنة
  static List<BattlePlatform> _generateRandomPlatformsWithGaps(
      int count,
      PlatformPattern pattern) {
    final List<BattlePlatform> platforms = [];
    final List<Rect> existingBounds = [];

    // ✅ منصة الأرضية الرئيسية
    final groundPlatform = BattlePlatform(
      x: 0.5,
      y: 1.48,
      width: 2.0 + _random.nextDouble() * 0.8,
      height: 0.08,
      type: 'ground',
      color: pattern.primaryColor,
    );
    platforms.add(groundPlatform);
    existingBounds.add(groundPlatform.bounds);

    // ✅ تقسيم المنصات إلى مناطق مختلفة لضمان التوزيع الجيد
    final zones = [
      {'xRange': [0.1, 0.35], 'yRange': [0.45, 0.75]},   // المنطقة اليسرى
      {'xRange': [0.65, 0.9], 'yRange': [0.45, 0.75]},    // المنطقة اليمنى
      {'xRange': [0.35, 0.65], 'yRange': [0.35, 0.65]},    // المنطقة الوسطى
      {'xRange': [0.2, 0.4], 'yRange': [0.75, 0.95]},      // اليسار السفلي
      {'xRange': [0.6, 0.8], 'yRange': [0.75, 0.95]},      // اليمين السفلي
      {'xRange': [0.3, 0.7], 'yRange': [0.25, 0.45]},      // المنطقة العلوية
    ];

    int generatedCount = 0;
    int attempts = 0;
    final maxAttempts = 50;

    while (generatedCount < count && attempts < maxAttempts) {
      attempts++;

      // ✅ اختيار منطقة عشوائية
      final zone = zones[generatedCount % zones.length];
      final x = zone['xRange']![0] + _random.nextDouble() *
          (zone['xRange']![1] - zone['xRange']![0]);
      final y = zone['yRange']![0] + _random.nextDouble() *
          (zone['yRange']![1] - zone['yRange']![0]);

      final width = 0.18 + _random.nextDouble() * PLATFORM_WIDTH_RANGE;
      final height = PLATFORM_HEIGHT * (0.9 + _random.nextDouble() * 0.2);

      Color color = pattern.secondaryColor;
      if (_random.nextDouble() < 0.4) {
        color = _platformColors[_random.nextInt(_platformColors.length)];
      }

      final tempPlatform = BattlePlatform(
        x: x,
        y: y,
        width: width,
        height: height,
        type: 'floating_${generatedCount + 1}',
        color: color,
      );

      // ✅ التحقق من عدم التداخل مع المنصات الموجودة
      bool hasCollision = false;
      for (final bounds in existingBounds) {
        if (tempPlatform.bounds.overlaps(bounds)) {
          hasCollision = true;
          break;
        }
      }

      // ✅ التحقق من المسافة الأفقية والعمودية
      bool tooClose = false;
      for (final platform in platforms) {
        final horizontalDist = (tempPlatform.x - platform.x).abs();
        final verticalDist = (tempPlatform.y - platform.y).abs();

        if (horizontalDist < MIN_HORIZONTAL_GAP && verticalDist < MIN_VERTICAL_GAP) {
          tooClose = true;
          break;
        }
      }

      if (!hasCollision && !tooClose) {
        platforms.add(tempPlatform);
        existingBounds.add(tempPlatform.bounds);
        generatedCount++;
      }
    }

    // ✅ إذا لم نتمكن من توليد العدد المطلوب، نضيف منصات احتياطية في مواقع آمنة
    if (generatedCount < count) {
      final safePositions = [
        Offset(0.25, 0.85), Offset(0.75, 0.85),
        Offset(0.4, 0.6), Offset(0.6, 0.6),
        Offset(0.3, 0.45), Offset(0.7, 0.45),
      ];

      for (int i = generatedCount; i < count && i < safePositions.length; i++) {
        final pos = safePositions[i];
        final backupPlatform = BattlePlatform(
          x: pos.dx,
          y: pos.dy,
          width: 0.22,
          height: 0.035,
          type: 'backup_$i',
          color: pattern.secondaryColor,
        );

        // ✅ التحقق من عدم التداخل
        bool collision = false;
        for (final bounds in existingBounds) {
          if (backupPlatform.bounds.overlaps(bounds)) {
            collision = true;
            break;
          }
        }

        if (!collision) {
          platforms.add(backupPlatform);
          existingBounds.add(backupPlatform.bounds);
        }
      }
    }

    return platforms;
  }

  // ✅ دالة للتحقق من المسافات بين المنصات وتصحيحها
  static List<BattlePlatform> _validatePlatformSpacing(List<BattlePlatform> platforms) {
    final List<BattlePlatform> validated = [];

    // ✅ فصل الأرضية عن باقي المنصات
    final ground = platforms.firstWhere((p) => p.type == 'ground', orElse: () => platforms.first);
    validated.add(ground);

    final otherPlatforms = platforms.where((p) => p != ground).toList();

    for (int i = 0; i < otherPlatforms.length; i++) {
      var platform = otherPlatforms[i];
      bool needsAdjustment = false;

      // ✅ التحقق من المسافة مع الأرضية
      final groundDist = (platform.y - ground.y).abs();
      if (groundDist < MIN_VERTICAL_GAP && platform.y < 1.2) {
        platform = platform.copyWith(y: platform.y - 0.08);
        needsAdjustment = true;
      }

      // ✅ التحقق من المسافة مع المنصات الأخرى
      for (final existing in validated) {
        if (existing == ground) continue;

        final horizontalDist = (platform.x - existing.x).abs();
        final verticalDist = (platform.y - existing.y).abs();

        if (horizontalDist < MIN_HORIZONTAL_GAP && verticalDist < MIN_VERTICAL_GAP) {
          // ✅ إزاحة المنصة
          if (platform.x < existing.x) {
            platform = platform.copyWith(x: platform.x - 0.12);
          } else {
            platform = platform.copyWith(x: platform.x + 0.12);
          }
          needsAdjustment = true;
        }
      }

      validated.add(platform);

      if (needsAdjustment) {
        print('🔧 تم تعديل موقع منصة: ${platform.type} إلى (${platform.x.toStringAsFixed(2)}, ${platform.y.toStringAsFixed(2)})');
      }
    }

    return validated;
  }

  static List<Map<String, dynamic>> generateStrategicGaps(List<BattlePlatform> platforms) {
    final List<Map<String, dynamic>> gaps = [];

    final sortedPlatforms = List<BattlePlatform>.from(platforms)
      ..sort((a, b) => a.x.compareTo(b.x));

    for (int i = 0; i < sortedPlatforms.length - 1; i++) {
      final current = sortedPlatforms[i];
      final next = sortedPlatforms[i + 1];

      final gapStart = current.right;
      final gapEnd = next.left;
      final gapWidth = gapEnd - gapStart;
      final yDifference = (current.y - next.y).abs();

      // ✅ فجوة آمنة للقفز (ليست واسعة جداً ولا ضيقة جداً)
      if (gapWidth > 0.12 && gapWidth < 0.35 && yDifference < 0.15) {
        gaps.add({
          'left': gapStart,
          'right': gapEnd,
          'name': 'فجوة ${i + 1}',
          'dangerLevel': gapWidth > 0.25 ? 'high' : 'medium',
          'yLevel': (current.y + next.y) / 2,
          'recommendedJump': gapWidth > 0.2 ? 'double' : 'single',
        });
      }
    }

    return gaps;
  }
}

// ✅ منصة القتال
class BattlePlatform {
  final double x, y, width, height;
  final String type;
  final Color color;

  // ✅ متغيرات محسوبة مرة واحدة فقط
  late final Rect _bounds;
  late final double _top;
  late final double _bottom;
  late final double _left;
  late final double _right;

  BattlePlatform({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.type = 'main',
    this.color = const Color(0xFF8B4513),
  }) {
    // ✅ حساب كل الحدود عند الإنشاء فقط
    _bounds = Rect.fromCenter(
      center: Offset(x, y),
      width: width,
      height: height,
    );
    _top = y - height / 2;
    _bottom = y + height / 2;
    _left = x - width / 2;
    _right = x + width / 2;
  }

  // ✅ Getter للمعلومات المحسوبة
  Rect get bounds => _bounds;
  double get top => _top;
  double get bottom => _bottom;
  double get left => _left;
  double get right => _right;

  // ✅ تحديث الموقع مع إعادة حساب الحدود
  BattlePlatform copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
  }) {
    return BattlePlatform(
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      type: type,
      color: color,
    );
  }

  // ✅ التحقق من التداخل مع منصة أخرى
  bool overlaps(BattlePlatform other) {
    return _bounds.overlaps(other._bounds);
  }

  // ✅ التحقق من المسافة الدنيا
  bool isTooCloseTo(BattlePlatform other, {double minDistance = 0.15}) {
    final centerDistance = sqrt(pow(x - other.x, 2) + pow(y - other.y, 2));
    return centerDistance < minDistance;
  }

  // ✅ هل اللاعب على هذه المنصة؟
  bool isPlayerOnPlatform(double playerX, double playerY, double playerBottom) {
    final playerLeft = playerX - 0.025;
    final playerRight = playerX + 0.025;

    final isAbove = playerBottom >= _top - 0.02 && playerBottom <= _top + 0.05;
    final isWithin = playerRight > _left && playerLeft < _right;

    return isAbove && isWithin;
  }
}