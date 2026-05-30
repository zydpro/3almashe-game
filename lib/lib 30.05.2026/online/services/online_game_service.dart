import 'dart:async';
import 'dart:math';
import 'dart:ui';
import '../animation/advanced_animation_system.dart';
import '../animation/animation_manager.dart';
import '../models/online_character_system.dart';
import 'online_audio_service.dart';
import 'package:flutter/material.dart';

class OnlineGameService {

  static OnlineGameService? _instance;

  static OnlineGameService get instance {
    _instance ??= OnlineGameService._internal();
    return _instance!;
  }
  OnlineGameService._internal() {
    // ✅ تهيئة القيم عند إنشاء الـ instance
    isGameRunning = false;
    gameTimer = 180.0;
    localPlayerScore = 0;
    remotePlayerScore = 0;
    platforms = [];
    activeAttacks = [];
    activeEffects = [];
    localPlayerDeaths = 0;
    remotePlayerDeaths = 0;
  }

  OnlinePlayer? localPlayer;
  OnlinePlayer? remotePlayer;
  bool isGameRunning = false;
  int localPlayerScore = 0;
  int remotePlayerScore = 0;
  double gameTimer = 180.0;

  int localPlayerDeaths = 0;
  int remotePlayerDeaths = 0;
  bool isGameEnded = false;
  String? gameWinner;
  String? endGameReason;

  final double _punchDamage = 10.0;
  final Map<String, int> _lastHitDamage = {'local': 0, 'remote': 0};
  final Map<String, int> _consecutiveHits = {'local': 0, 'remote': 0};
  List<Map<String, dynamic>> activeEffects = [];
  List<OnlineBattleAttack> activeAttacks = [];
  List<BattlePlatform> platforms = [];

  final double gravity = 0.0015;
  final double moveSpeed = 0.055;
  final double jumpForce = -0.055;
  final double maxFallSpeed = 0.045;
  final double airControl = 0.028;

  Timer? _gameTimer;
  Random random = Random();

  bool _isRealPlayerMatch = false; // ✅ أضف هذا السطر

  // ✅ خريطة لتخزين حدود المنصات
  final Map<String, Rect> _platformBounds = {};
  final Map<String, BattlePlatform> _platformsById = {};
  List<BattlePlatform> _currentRandomPlatforms = [];
  String _currentPlatformPatternName = 'كلاسيكي';
  // ✅ معالجة الانتقال بين الحالات لمنع التذبذب
  final Map<String, int> _lastGroundedChange = {};
  final Map<String, bool> _pendingGroundedState = {};

  // ✅ تهيئة نظام الأنيميشن
  Future<void> initializeAnimationSystem() async {
    try {
      final animationManager = AnimationManager();

      final characters = OnlineCharacter.getAllOnlineCharacters();
      for (final character in characters) {
        await animationManager.loadCharacterAnimationsFromJson(
          _getCharacterId(character.id),
          character.animationConfigPath,
        );
      }

      print('✅ Animation system initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize animation system: $e');
    }
  }

  String _getCharacterId(int characterId) {
    switch (characterId) {
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
      default: return 'default';
    }
  }

  void updateRemotePlayerFromLiveKit(double x, double y, double health) {
    if (remotePlayer == null) return;
    remotePlayer!.x = x;
    remotePlayer!.y = y;
    remotePlayer!.health = health;
  }

  Map<String, dynamic> initializeBattleRoom({
    required OnlineCharacter localCharacter,
    required Map<String, dynamic> opponent,
    List<BattlePlatform>? customPlatforms,
    String? platformPatternName,
    required String localPlayerId, // ✅ معرف اللاعب المحلي (يُمرر من الشاشة)
  }) {
    // ✅ إعادة تعيين جميع المتغيرات أولاً
    isGameRunning = false;
    gameTimer = 180.0;
    localPlayerScore = 0;
    remotePlayerScore = 0;
    localPlayerDeaths = 0;
    remotePlayerDeaths = 0;
    isGameEnded = false;
    gameWinner = null;
    endGameReason = null;
    activeAttacks.clear();
    activeEffects.clear();
    platforms.clear();
    _currentRandomPlatforms.clear();

    print('🎮 === بدء تهيئة غرفة القتال ===');
    print('📱 [initializeBattleRoom] معرف اللاعب المحلي المستلم: $localPlayerId');

    // ⭐⭐ حل المشكلة الرئيسية: تحويل الأسلحة إلى ترميز صحيح
    final localWeapons = [
      OnlineWeaponLibrary.getWeapon(localCharacter.primaryWeapon),
      OnlineWeaponLibrary.getWeapon(localCharacter.secondaryWeapon),
    ];

    // ✅ معالجة محسنة لشخصية الخصم
    OnlineCharacter opponentCharacter;

    if (opponent['character'] is OnlineCharacter) {
      opponentCharacter = opponent['character'] as OnlineCharacter;
    } else if (opponent['character'] != null && opponent['character'] is Map) {
      try {
        opponentCharacter = OnlineCharacter.fromJson(opponent['character']);
        print('✅ تم تحويل Map إلى OnlineCharacter للخصم');
      } catch (e) {
        print('❌ فشل تحويل Map: $e');
        opponentCharacter = OnlineCharacter.getDefaultCharacter();
      }
    } else {
      print('⚠️ لا توجد بيانات شخصية للخصم، استخدام الشخصية الافتراضية');
      opponentCharacter = OnlineCharacter.getDefaultCharacter();
    }

    final opponentWeapons = [
      OnlineWeaponLibrary.getWeapon(opponentCharacter.primaryWeapon),
      OnlineWeaponLibrary.getWeapon(opponentCharacter.secondaryWeapon),
    ];

    // ✅ منطق توليد المنصات المعدل
    if (customPlatforms != null && customPlatforms.isNotEmpty) {
      platforms = customPlatforms;
      _currentRandomPlatforms = customPlatforms;
      _currentPlatformPatternName = platformPatternName ?? 'مخصص';
      print('🎮 استخدام منصات مخصصة: ${customPlatforms.length} منصة');
      print('🎮 نمط المنصات: $_currentPlatformPatternName');
    } else {
      final pattern = PlatformGenerator.getRandomPattern();
      _currentRandomPlatforms = PlatformGenerator.generatePlatformsFromPattern(pattern);
      _currentPlatformPatternName = pattern.name;
      platforms = _currentRandomPlatforms;

      print('🎲 تم توليد منصات عشوائية بنمط: $_currentPlatformPatternName');
      print('🏔️ عدد المنصات: ${platforms.length}');
    }

    // ✅ حفظ معلومة هل الخصم حقيقي
    _isRealPlayerMatch = opponent['isRealPlayer'] == true;

    print('🎮 === حفظ حالة الخصم ===');
    print('   👤 _isRealPlayerMatch = $_isRealPlayerMatch');

    // ✅ التأكد من أن الأسلحة محملة
    print('🗡️ أسلحة اللاعب المحلي: ${localWeapons.length}');
    print('🗡️ أسلحة الخصم: ${opponentWeapons.length}');

    // ✅ إنشاء اللاعب المحلي باستخدام المعرف المُمرر
    localPlayer = OnlinePlayer(
      playerId: localPlayerId, // ✅ استخدام المعرف المُمرر
      character: localCharacter,
      x: 0.3,
      y: 0.7,
      weapons: localWeapons,
      currentWeaponIndex: 0,
    );

    // ✅ استخدام معرف الخصم من البيانات إذا كان متاحاً
    final opponentPlayerId = opponent['playerId'] as String? ??
        'opponent_${DateTime.now().millisecondsSinceEpoch}';

    remotePlayer = OnlinePlayer(
      playerId: opponentPlayerId,
      character: opponentCharacter,
      x: 0.7,
      y: 0.7,
      isFacingRight: false,
      weapons: opponentWeapons,
      currentWeaponIndex: 0,
    );

    print('✅ تم تهيئة اللاعبين:');
    print('   👤 اللاعب المحلي: ${localPlayer!.playerId}');
    print('   🗡️ سلاحه: ${localPlayer!.currentWeapon?.name ?? "لا يوجد"}');
    print('   👥 الخصم: ${remotePlayer!.playerId}');
    print('   🗡️ سلاحه: ${remotePlayer!.currentWeapon?.name ?? "لا يوجد"}');
    print('   🎭 شخصية الخصم: ${opponentCharacter.name}');

    // في نهاية الدالة، قبل الـ return
    print('🎮 === التحقق النهائي من نوع الخصم ===');
    print('   🆔 remotePlayer: ${remotePlayer?.playerId}');
    print('   🤖 isBot: ${opponent['isBot']}');
    print('   👤 isRealPlayer: ${opponent['isRealPlayer']}');

    // تأكد من أن remotePlayer ليس بوتاً إذا كان isRealPlayer = true
    if (opponent['isRealPlayer'] == true && remotePlayer != null) {
      print('✅ تأكيد: الخصم لاعب حقيقي');
    }

    isGameRunning = true;

    print('🏟️ تم إنشاء ${platforms.length} منصة');
    print('⏱️ المؤقت: $gameTimer ثانية');
    print('🎮 === غرفة القتال جاهزة ===');

    // ⭐⭐ إرجاع البيانات المصححة مع تضمين localPlayerId
    return {
      'roomId': 'brawl_${DateTime.now().millisecondsSinceEpoch}',
      'localPlayer': _playerToMap(localPlayer!),
      'opponent': _playerToMap(remotePlayer!),
      'platforms': platforms.map((p) => _platformToMap(p)).toList(),
      'gameTime': gameTimer,
      'isGameRunning': isGameRunning,
      'hasWeapons': true,
      'platformPattern': _currentPlatformPatternName,
      'isRealPlayerMatch': opponent['isRealPlayer'] == true,
      'localPlayerId': localPlayerId, // ✅ تضمين المعرف في النتيجة
    };
  }

  // ✅ دالة لتصحيح الأنيميشن أثناء الموت
  void _fixDeathAnimation(OnlinePlayer player) {
    if (player.state == PlayerState.death) {
      // ✅ الانتقال المباشر لأنيميشن الموت
      player.animationController.transitionToState(
          AnimationState.death,
          reason: "death_by_fall"
      );

      // ✅ إعادة تعيين إطار الموت
      final deathFrame = 'assets/images/characters/${_getCharacterId(player.character.id)}/${_getCharacterId(player.character.id)}_death_1.png';
      player.updateAnimationFrame(deathFrame);

      print('💀 [ANIMATION FIX] تعيين أنيميشن الموت للاعب ${player.playerId}');
    }
  }

  // وأضف هذه الدالة لتعيين القيمة
  void setRealPlayerMatch(bool value) {
    _isRealPlayerMatch = value;
    print('🎮 [GameService] تعيين _isRealPlayerMatch = $value');
  }

  // ✅ تعيين حدود المنصات
  void setPlatformBounds(List<BattlePlatform> platforms) {
    _platformBounds.clear();
    _platformsById.clear();

    for (final platform in platforms) {
      final id = '${platform.type}_${platform.x}_${platform.y}';
      _platformBounds[id] = platform.bounds;
      _platformsById[id] = platform;
    }

    print('🗺️ تم تحديث حدود ${_platformBounds.length} منصة');
  }

// ✅ دالة محسنة للتحقق من التصادم مع المنصات
  bool checkPlayerPlatformCollision(OnlinePlayer player) {
    if (player.state == PlayerState.death) return false;

    bool foundPlatform = false;
    double? closestPlatformTop;

    for (var platform in platforms) {
      // حساب حدود اللاعب
      final playerBottom = player.y + 0.04;
      final playerLeft = player.x - 0.03;
      final playerRight = player.x + 0.03;

      // حساب حدود المنصة
      final platformTop = platform.top;
      final platformLeft = platform.left;
      final platformRight = platform.right;

      // التحقق من أن اللاعب فوق المنصة
      final isAbovePlatform = playerBottom >= platformTop - 0.02 &&
          playerBottom <= platformTop + 0.03;

      // التحقق من أن اللاعب داخل حدود المنصة أفقياً
      final isWithinHorizontal = playerRight > platformLeft &&
          playerLeft < platformRight;

      // التحقق من أن اللاعب يسقط
      final isFalling = player.velocityY >= 0;

      if (isFalling && isAbovePlatform && isWithinHorizontal) {
        // إذا كانت هذه المنصة أعلى من المنصات الأخرى
        if (closestPlatformTop == null || platformTop < closestPlatformTop) {
          closestPlatformTop = platformTop;
          foundPlatform = true;
        }
      }
    }

    if (foundPlatform && closestPlatformTop != null) {
      player.isGrounded = true;
      player.velocityY = 0;
      // وضع اللاعب فوق المنصة مباشرة
      player.y = closestPlatformTop - 0.035;

      // إذا كان في حالة سقوط، اجعله idle
      if (player.state == PlayerState.falling) {
        player.state = PlayerState.idle;
      }
      return true;
    }

    player.isGrounded = false;
    return false;
  }

  // ✅ تحديث حدود منصة معينة
  void updatePlatformBounds(String platformId, Rect newBounds) {
    if (_platformBounds.containsKey(platformId)) {
      _platformBounds[platformId] = newBounds;
    }
  }
  // ✅ دالة لتعيين المنصات العشوائية
  void setRandomPlatforms(List<BattlePlatform> randomPlatforms, String patternName) {
    _currentRandomPlatforms = List.from(randomPlatforms);
    _currentPlatformPatternName = patternName;

    if (isGameRunning) {
      platforms = _currentRandomPlatforms;
      print('🔄 تحديث المنصات أثناء اللعبة');
    }
  }

  // ✅ دالة للحصول على معلومات النمط
  Map<String, dynamic> getPlatformPatternInfo() {
    return {
      'patternName': _currentPlatformPatternName,
      'platformCount': platforms.length,
      'hasRandomPlatforms': _currentRandomPlatforms.isNotEmpty,
    };
  }

  void debugPlatformCollision() {
    if (localPlayer != null) {
      bool onPlatform = false;
      for (var platform in platforms) {
        if (_isPlayerOnPlatform(localPlayer!, platform)) {
          onPlatform = true;
          print('📍 اللاعب على المنصة: ${platform.type} في (${platform.x}, ${platform.y})');
          break;
        }
      }
      if (!onPlatform) {
        print('⚠️ اللاعب ليس على أي منصة! الموقع: (${localPlayer!.x}, ${localPlayer!.y})');
      }
    }
  }

  Map<String, dynamic> _playerToMap(OnlinePlayer player) {
    return {
      'playerId': player.playerId,
      'character': player.character.toJson(),
      'health': player.health,
      'position': {'x': player.x, 'y': player.y},
      'velocity': {'x': player.velocityX, 'y': player.velocityY},
      'isFacingRight': player.isFacingRight,
      'state': player.state.toString(),
      'weapons': player.weapons.map((w) => _weaponToMap(w)).toList(), // ⭐ هنا
      'currentWeaponIndex': player.currentWeaponIndex,
      'currentFramePath': player.currentFramePath,
      'isGrounded': player.isGrounded,
      'attackCooldown': player.attackCooldown,
      'canMove': player.canMove,
    };
  }

  Map<String, dynamic> _weaponToMap(OnlineWeapon weapon) {
    return {
      'type': weapon.type.toString(), // ⭐ تحويل OnlineWeaponType إلى String
      'name': weapon.name,
      'nameEn': weapon.nameEn,
      'damage': weapon.damage,
      'speed': weapon.speed,
      'range': weapon.range,
      'imagePath': weapon.imagePath,
      'attackColor': weapon.attackColor.value,
    };
  }

  Map<String, dynamic> _platformToMap(BattlePlatform platform) {
    return {
      'x': platform.x,
      'y': platform.y,
      'width': platform.width,
      'height': platform.height,
      'type': platform.type,
      'color': platform.color.value,
    };
  }

  OnlineBattleAttack createAttack({
    required OnlineAttackType type,
    required OnlineWeapon weapon,
    required double x,
    required double y,
    required bool isFacingRight,
  }) {
    final directionX = isFacingRight ? 1.0 : -1.0;

    // ✅ إنشاء الهجوم مع weaponImagePath
    final attack = OnlineBattleAttack(
      type: type,
      x: x + (directionX * 0.05),
      y: y,
      directionX: directionX,
      damage: _calculateAttackDamage(weapon, type),
      speed: _calculateAttackSpeed(weapon, type),
      range: _calculateAttackRange(weapon, type),
      color: weapon.attackColor,
      weaponImagePath: weapon.imagePath, // ✅ أضف هذا السطر
      isActive: true,
    );

    // ✅ ضبط lifetime
    attack.lifetime = 40;

    activeAttacks.add(attack);
    _playAttackSound(type);

    print('🎯 [GAME SERVICE] هجوم جديد من: ${weapon.name}');
    print('   📍 الموقع: ($x, $y)');
    print('   🗡️ مسار الصورة: ${weapon.imagePath}'); // ✅ أضف هذا
    print('   ⚔️ النوع: $type - ضرر: ${attack.damage}');
    print('   ➡️ الاتجاه: $directionX');
    print('   ⏱️ العمر: ${attack.lifetime} frames');

    return attack;
  }

  // ✅ دالة للتأكد من تطابق معرف الخصم
  void ensureRemotePlayerId(String expectedId) {
    if (remotePlayer != null && remotePlayer!.playerId != expectedId) {
      print('🔄 تصحيح معرف الخصم في GameService');
      remotePlayer!.playerId = expectedId;
    }
  }

  // ✅ دالة مساعدة لحساب الضرر
  int _calculateAttackDamage(OnlineWeapon weapon, OnlineAttackType type) {
    switch (type) {
      case OnlineAttackType.light:
        return weapon.damage;
      case OnlineAttackType.heavy:
        return (weapon.damage * 1.8).round();
      case OnlineAttackType.aerial:
        return (weapon.damage * 1.2).round();
      case OnlineAttackType.special:
        return (weapon.damage * 1.5).round();
      case OnlineAttackType.signature:
        return (weapon.damage * 2.2).round();
      default:
        return weapon.damage;
    }
  }

  // ✅ دالة مساعدة لحساب السرعة
  double _calculateAttackSpeed(OnlineWeapon weapon, OnlineAttackType type) {
    switch (type) {
      case OnlineAttackType.light:
        return weapon.speed * 1.5;
      case OnlineAttackType.heavy:
        return weapon.speed * 0.8;
      case OnlineAttackType.aerial:
        return weapon.speed * 1.3;
      case OnlineAttackType.special:
        return weapon.speed * 1.1;
      case OnlineAttackType.signature:
        return weapon.speed * 0.9;
      default:
        return weapon.speed;
    }
  }

  // ✅ دالة مساعدة لحساب المدى
  double _calculateAttackRange(OnlineWeapon weapon, OnlineAttackType type) {
    switch (type) {
      case OnlineAttackType.light:
        return weapon.range * 0.7;
      case OnlineAttackType.heavy:
        return weapon.range * 1.2;
      case OnlineAttackType.aerial:
        return weapon.range * 0.8;
      case OnlineAttackType.special:
        return weapon.range * 1.1;
      case OnlineAttackType.signature:
        return weapon.range * 1.4;
      default:
        return weapon.range;
    }
  }

  void _playAttackSound(OnlineAttackType type) {
    try {
      final audioService = OnlineAudioService();
      switch (type) {
        case OnlineAttackType.light:
          audioService.playLightAttackSound();
          break;
        case OnlineAttackType.heavy:
          audioService.playHeavyAttackSound();
          break;
        case OnlineAttackType.aerial:
          audioService.playAerialAttackSound();
          break;
        case OnlineAttackType.special:
        case OnlineAttackType.signature:
          audioService.playSpecialAttackSound();
          break;
      }
    } catch (e) {
      print('❌ خطأ في تشغيل صوت الهجوم: $e');
    }
  }

  void addPlayerAttack(OnlineBattleAttack attack, String playerId) {
    try {
      print('🎯 [GAME SERVICE] إضافة هجوم لاعب: $playerId');
      print('   📍 الموقع: (${attack.x.toStringAsFixed(3)}, ${attack.y.toStringAsFixed(3)})');
      print('   ⚔️ النوع: ${attack.type} - ضرر: ${attack.damage}');

      // ✅ التأكد من أن الهجوم نشط
      attack.isActive = true;
      attack.lifetime = 30; // ✅ زيادة عمر الهجوم

      // ✅ إضافة الهجوم
      activeAttacks.add(attack);

      // ✅ تشغيل الصوت
      _playAttackSound(attack.type);

      print('✅ تم إضافة الهجوم - إجمالي الهجمات النشطة: ${activeAttacks.length}');

    } catch (e) {
      print('❌ خطأ في إضافة هجوم اللاعب: $e');
    }
  }

  void switchWeapon(OnlinePlayer player) {
    player.switchWeapon();
  }

  OnlineWeapon getCurrentWeapon(OnlinePlayer player) {
    return player.currentWeapon!;
  }

  // ✅ التحديث الرئيسي مع دعم الأنيميشن الجديد والتحقق الإضافي
  Map<String, dynamic> updateGameState({
    required Map<String, dynamic> gameState,
    required Duration deltaTime,
  }) {
    try {
      if (!isGameRunning || isGameEnded) return gameState;

      final deltaTimeMs = deltaTime.inMilliseconds.toDouble();

      // ✅ 1. تحديث الفيزياء للاعب المحلي فقط
      if (localPlayer != null) {
        _updatePlayerPhysics(localPlayer!);
        _validatePlayerAnimation(localPlayer!);
        localPlayer!.updateAnimation(deltaTimeMs);
      }

      // ✅ 2. للخصم الحقيقي - تحديث الأنيميشن فقط، بدون أي فيزياء
      if (remotePlayer != null) {
        if (_isRealPlayerMatch) {
          // ✅ للخصم الحقيقي: تحديث الأنيميشن فقط
          // لا نغير الموقع، لا نغير السرعات، لا نطبق جاذبية
          remotePlayer!.updateAnimation(deltaTimeMs);
          _validatePlayerAnimation(remotePlayer!);

          // ✅ لا نغير أي شيء في الفيزياء!
          // remotePlayer!.isGrounded لا نغيره هنا
          // remotePlayer!.velocityX/Y لا نغيرهما هنا
          // remotePlayer!.x/y لا نغيرهما هنا (يتم تحديثها من Firestore فقط)
        } else {
          // ✅ للبوت: نطبق الفيزياء كاملة
          _updatePlayerPhysics(remotePlayer!);
          _validatePlayerAnimation(remotePlayer!);
          remotePlayer!.updateAnimation(deltaTimeMs);
        }
      }

      // ✅ 3. تحديث الهجمات والتصادمات (للجميع)
      _updateActiveAttacks();
      _checkCollisions();
      _checkPlayerCollisions();

      // ✅ 4. تحديث حالة الخصم (فقط للبوت)
      if (!_isRealPlayerMatch) {
        _updateRemotePlayer(); // هذه للبوت فقط
      }

      // ✅ 5. تحديث المؤقت والشروط
      gameTimer -= deltaTimeMs / 1000.0;
      if (gameTimer <= 0) {
        gameTimer = 0;
        _endGameByTime();
      }

      // ✅ 6. التحقق من صحة اللعبة
      _checkGameValidity();

      return {
        ...gameState,
        'gameTime': gameTimer,
        'activeAttacks': activeAttacks.map((attack) => _attackToMap(attack)).toList(),
        'localPlayer': localPlayer != null ? _playerToMap(localPlayer!) : null,
        'opponent': remotePlayer != null ? _playerToMap(remotePlayer!) : null,
        'localScore': localPlayerScore,
        'remoteScore': remotePlayerScore,
        'isGameEnded': isGameEnded,
      };

    } catch (e) {
      print('❌ خطأ في updateGameState: $e');
      return _getFallbackGameState(gameState);
    }
  }

  // ✅ التحقق من صحة أنيميشن اللاعب
  void _validatePlayerAnimation(OnlinePlayer player) {
    try {
      final currentFrame = player.currentFramePath.split('/').last;
      final expectedState = player.getCorrectAnimationState();
      final expectedKey = player.getAnimationStateKey(expectedState);

      // إذا كان اللاعب ميتًا (PlayerState.dead) ولكن الإطار لا يحتوي على 'death'
      if (player.state == PlayerState.death && !currentFrame.contains('death')) {
        print('⚠️ [FIX] لاعب ميت ولكن الإطار ليس death. إصلاح...');
        player.forceAnimationReset();
      }
      // إذا كان اللاعب مصابًا (damaged) والإطار لا يحتوي على 'hurt'، ربما نحتاج إصلاحًا
      else if (player.state == PlayerState.hurt && !currentFrame.contains('hurt')) {
        print('⚠️ [WARN] لاعب مصاب لكن الإطار ليس hurt. قد تكون الحالة تغيرت.');
        // يمكن أن نطلب إعادة تعيين هنا إذا تكررت المشكلة
        // player.forceAnimationReset();
      }
    } catch (e) {
      print('❌ خطأ في التحقق من الأنيميشن: $e');
    }
  }

  // ✅ التحقق من صحة اللعبة الشاملة
  void _checkGameValidity() {
    try {
      if (localPlayer == null || remotePlayer == null) {
        print('⚠️ تحذير: أحد اللاعبين مفقود');
        return;
      }

      // ✅ التحقق من صلاحية الهجمات النشطة
      for (var attack in List.from(activeAttacks)) {
        if (attack.x.isNaN || attack.y.isNaN || attack.damage <= 0 || attack.lifetime <= 0) {
          print('⚠️ هجوم غير صالح تم إزالته: ${attack.type}');
          activeAttacks.remove(attack);
        }
      }

      // ✅ التحقق من مواقع اللاعبين
      if (localPlayer!.x.isNaN || localPlayer!.y.isNaN ||
          remotePlayer!.x.isNaN || remotePlayer!.y.isNaN) {
        print('❌ 🔥 مواقع لاعبيين غير صالحة - إعادة تعيين');
        _resetPlayerPositions();
      }

      // ✅ فحص دوري كل 5 ثوانٍ
      if (DateTime.now().second % 5 == 0) {
        debugActiveAttacks();
      }

    } catch (e) {
      print('❌ خطأ في التحقق من صحة اللعبة: $e');
    }
  }

  // ✅ إعادة تعيين مواقع اللاعبين في حالة الطوارئ
  void _resetPlayerPositions() {
    if (localPlayer != null) {
      localPlayer!.x = 0.3;
      localPlayer!.y = 0.7;
      localPlayer!.velocityX = 0.0;
      localPlayer!.velocityY = 0.0;
    }

    if (remotePlayer != null) {
      remotePlayer!.x = 0.7;
      remotePlayer!.y = 0.7;
      remotePlayer!.velocityX = 0.0;
      remotePlayer!.velocityY = 0.0;
    }

    print('🔄 تم إعادة تعيين مواقع اللاعبين للطوارئ');
  }

  // ✅ حالة احتياطية للعبة في حالة الخطأ
  Map<String, dynamic> _getFallbackGameState(Map<String, dynamic> gameState) {
    return {
      ...gameState,
      'gameTime': gameTimer,
      'activeAttacks': [],
      'localPlayer': localPlayer != null ? _playerToMap(localPlayer!) : null,
      'opponent': remotePlayer != null ? _playerToMap(remotePlayer!) : null,
      'localScore': localPlayerScore,
      'remoteScore': remotePlayerScore,
      'isGameEnded': isGameEnded,
      'hasError': true,
    };
  }

  Map<String, dynamic> _attackToMap(OnlineBattleAttack attack) {
    return {
      'type': attack.type.toString(),
      'x': attack.x,
      'y': attack.y,
      'directionX': attack.directionX,
      'isActive': attack.isActive,
      'damage': attack.damage,
      'speed': attack.speed,
      'range': attack.range,
      'color': attack.color.value,
      'lifetime': attack.lifetime,
    };
  }

  void _checkPlayerHealth() {
    if (localPlayer != null && localPlayer!.health <= 0 && localPlayer!.state != PlayerState.death) {
      localPlayer!.state = PlayerState.death;
      localPlayerDeaths++;
    }

    if (remotePlayer != null && remotePlayer!.health <= 0 && remotePlayer!.state != PlayerState.death) {
      remotePlayer!.state = PlayerState.death;
      remotePlayerDeaths++;
    }
  }

  void _checkPlayerCollisions() {
    final localPlayer = this.localPlayer;
    final remotePlayer = this.remotePlayer;

    if (localPlayer == null || remotePlayer == null) return;

    final distance = sqrt(pow(localPlayer.x - remotePlayer.x, 2) + pow(localPlayer.y - remotePlayer.y, 2));
    final punchDistance = 0.08;

    if (distance < punchDistance) {
      // ✅ تغيير من attacking إلى attacking_light أو attacking_heavy
      if ((localPlayer.state == PlayerState.attacking_light ||
          localPlayer.state == PlayerState.attacking_heavy) &&
          localPlayer.attackCooldown > 0) {
        int damage = 10;

        if (localPlayer.weapons.isNotEmpty && localPlayer.currentWeapon != null) {
          damage = (localPlayer.currentWeapon!.damage * 0.5).round();
          print('🎯 هجوم قريب بالسلاح: ${localPlayer.currentWeapon!.name} - ضرر: $damage');
        } else {
          print('👊 ملاكمة - ضرر: $damage');
        }

        remotePlayer.health -= damage;
        remotePlayer.state = PlayerState.hurt;  // ✅ تغيير من damaged إلى hurt
        remotePlayer.canMove = false;

        final direction = (localPlayer.x - remotePlayer.x).sign;
        remotePlayer.velocityX = direction * 0.02;
        remotePlayer.velocityY = -0.01;

        _addVisualEffect('punch_hit',
            (localPlayer.x + remotePlayer.x) / 2,
            (localPlayer.y + remotePlayer.y) / 2,
            duration: 200
        );

        OnlineAudioService().playPunchSound();
        _recordHit('local');

        if (localPlayer.playerId == this.localPlayer!.playerId) {
          localPlayerScore += damage;
        }
      }
    }
  }

  void _recordHit(String playerType) {
    _consecutiveHits[playerType] = (_consecutiveHits[playerType] ?? 0) + 1;

    if (_consecutiveHits[playerType]! >= 5) {
      _instantKO(playerType == 'local' ? 'remote' : 'local');
      _consecutiveHits[playerType] = 0;
    }
  }

  void _instantKO(String playerType) {
    final player = playerType == 'local' ? localPlayer : remotePlayer;
    if (player != null) {
      player.health = 0;
    }
  }

  void _addVisualEffect(String type, double x, double y, {Color color = Colors.white, int duration = 1000}) {
    activeEffects.add({
      'type': type,
      'x': x,
      'y': y,
      'color': color,
      'startTime': DateTime.now().millisecondsSinceEpoch,
      'duration': duration,
    });
  }

  void _checkBoundaries() {
    if (localPlayer != null && localPlayer!.y > 1.2) { // مستوى الموت الجديد
      if (localPlayer!.state != PlayerState.death) {
        localPlayer!.state = PlayerState.death;
        localPlayerDeaths++;
        remotePlayerScore++;
        print('💀 اللاعب المحلي مات بالسقوط خارج الحدود');

        // ✅ إضافة تأثيرات
        _addVisualEffect('fall_death', localPlayer!.x, localPlayer!.y,
            color: Colors.red, duration: 1000);
      }
    }

    if (remotePlayer != null && remotePlayer!.y > 1.2) { // مستوى الموت الجديد
      if (remotePlayer!.state != PlayerState.death) {
        remotePlayer!.state = PlayerState.death;
        remotePlayerDeaths++;
        localPlayerScore++;
        print('💀 الخصم مات بالسقوط خارج الحدود');

        _addVisualEffect('fall_death', remotePlayer!.x, remotePlayer!.y,
            color: Colors.red, duration: 1000);
      }
    }

    // ✅ الحدود الأفقية
    if (localPlayer != null) {
      if (localPlayer!.x < -2.0) localPlayer!.x = -1.9;
      if (localPlayer!.x > 3.0) localPlayer!.x = 2.9;
    }

    if (remotePlayer != null) {
      if (remotePlayer!.x < -2.0) remotePlayer!.x = -1.9;
      if (remotePlayer!.x > 3.0) remotePlayer!.x = 2.9;
    }
  }

  Map<String, dynamic> _getFinalGameState(Map<String, dynamic> gameState) {
    return {
      ...gameState,
      'isGameRunning': false,
      'gameTime': 0,
      'isGameEnded': true,
      'gameResult': getGameResult(),
    };
  }

// ✅ تحديث الفيزياء - تُستدعى فقط للاعب المحلي
  void _updatePlayerPhysics(OnlinePlayer player) {
    try {
      // ✅ إذا كان هذا هو الخصم الحقيقي، لا نطبق الفيزياء مطلقاً!
      if (_isRealPlayerMatch && player.playerId != localPlayer?.playerId) {
        return; // ⭐ الخروج الفوري للخصم الحقيقي
      }

      // باقي الكود للاعب المحلي أو البوت فقط
      player.x += player.velocityX;
      player.y += player.velocityY;

      // ✅ تطبيق الجاذبية فقط إذا لم يكن على الأرض
      if (!player.isGrounded) {
        player.velocityY += gravity;

        if (player.velocityY > maxFallSpeed) {
          player.velocityY = maxFallSpeed;
        }
      }

      player.velocityX *= 0.9;
      if (player.velocityX.abs() < 0.001) {
        player.velocityX = 0.0;
      }

      _checkGroundCollision(player);

    } catch (e) {
      print('❌ خطأ في _updatePlayerPhysics: $e');
    }
  }

  // ✅ دالة لتحديث الخصم من Firebase فقط
  void updateRemotePlayerFromSync(Map<String, dynamic> syncData) {
    if (remotePlayer == null || !_isRealPlayerMatch) return;

    try {
      // ✅ تحديث الموقع فقط من Firebase
      if (syncData.containsKey('x')) {
        remotePlayer!.x = (syncData['x'] as num).toDouble();
      }
      if (syncData.containsKey('y')) {
        remotePlayer!.y = (syncData['y'] as num).toDouble();
      }

      // ✅ تحديث الحالة
      if (syncData.containsKey('state')) {
        final stateStr = syncData['state'] as String;
        final state = PlayerState.values.firstWhere(
              (e) => e.toString() == stateStr,
          orElse: () => remotePlayer!.state,
        );
        remotePlayer!.state = state;
      }

      // ✅ تحديث الأنيميشن فقط
      remotePlayer!.updateAnimationOnly(16.0);

    } catch (e) {
      print('⚠️ خطأ في تحديث الخصم: $e');
    }
  }

  // void _updatePlayerState(OnlinePlayer player) {
  //   if (player.state == PlayerState.dead) return;
  //
  //   if (!player.isGrounded) {
  //     if (player.velocityY < -0.001) {
  //       player.state = PlayerState.jumping;
  //     } else if (player.velocityY > 0.001) {
  //       player.state = PlayerState.falling;
  //     }
  //   } else {
  //     if (player.velocityX.abs() > 0.005) {
  //       player.state = PlayerState.running;
  //     } else {
  //       player.state = PlayerState.idle;
  //     }
  //   }
  // }

// ✅ التحقق من التصادم مع الأرض - للاعب المحلي فقط
  void _checkGroundCollision(OnlinePlayer player) {
    // ✅ إذا كان هذا هو الخصم الحقيقي، لا نتحقق من التصادم!
    if (_isRealPlayerMatch && player.playerId != localPlayer?.playerId) {
      return;
    }

    bool wasGrounded = player.isGrounded;
    player.isGrounded = false;

    bool foundPlatform = false;

    for (var platform in platforms) {
      if (_isPlayerActuallyOnPlatform(player, platform)) {
        player.isGrounded = true;
        foundPlatform = true;

        // ✅ تصحيح: وضع اللاعب فوق المنصة بدقة
        player.y = platform.top - 0.035;
        player.velocityY = 0.0;

        // ✅ إذا كان اللاعب في حالة سقوط، غيّر إلى idle
        if (player.state == PlayerState.falling) {
          player.state = PlayerState.idle;
        }

        break;
      }
    }

    // ✅ إذا لم يجد منصة وهو تحت الأرض، اجعله يموت
    if (!foundPlatform && player.y > 1.2 && player.state != PlayerState.death) {
      print('💀 [${player.playerId}] سقوط خارج المنصات!');  // ✅ استخدم player.playerId
      player.state = PlayerState.death;
    }
  }

  // ✅ أضف هذه الدالة الجديدة
  bool _isPlayerActuallyOnPlatform(OnlinePlayer player, BattlePlatform platform) {
    final playerBottom = player.y + 0.04;
    final playerLeft = player.x - 0.025;
    final playerRight = player.x + 0.025;

    // ✅ استخدام حدود المنصة المحسوبة مسبقاً
    final platformTop = platform.top;
    final platformLeft = platform.left;
    final platformRight = platform.right;

    // ✅ منطق محسّن مع هوستريسس
    final verticalThreshold = 0.03; // زيادة من 0.02 إلى 0.03
    final isTouching = playerBottom >= platformTop - verticalThreshold &&
        playerBottom <= platformTop + verticalThreshold;

    final isWithin = playerRight > platformLeft && playerLeft < platformRight;
    final isFalling = player.velocityY >= -0.005; // زيادة التسامح

    return isTouching && isWithin && isFalling;
  }

  // ✅ تصحيح موقع اللاعب لمنع التداخل
  void _correctPlayerPosition(OnlinePlayer player, BattlePlatform platform) {
    // ✅ وضع اللاعب فوق المنصة بدقة
    player.y = platform.top - 0.035; // رفع قليلاً

    // ✅ منع المرور عبر الجوانب
    final playerLeft = player.x - 0.025;
    final playerRight = player.x + 0.025;

    if (playerRight > platform.right) {
      player.x = platform.right - 0.026;
    } else if (playerLeft < platform.left) {
      player.x = platform.left + 0.026;
    }

    // ✅ إعادة تعيين السرعة
    if (player.velocityY > 0) {
      player.velocityY = 0.0;
    }
  }

  void _updateRemotePlayer() {
    // ✅ إذا كان الخصم لاعباً حقيقياً، لا نتحكم فيه إطلاقاً
    if (_isRealPlayerMatch) {
      // 🚫 ممنوع تغيير موقع الخصم أو حالته هنا
      // الخصم الحقيقي يتم التحكم به فقط عبر Firestore
      return; // ⭐ هذا مهم جداً!
    }

    // باقي الكود للبوت فقط
    if (remotePlayer == null || remotePlayer!.state == PlayerState.death) return;

    final distanceToLocal = (localPlayer!.x - remotePlayer!.x).abs();

    if (remotePlayer!.isGrounded) {
      if (distanceToLocal > 0.15) {
        final direction = (localPlayer!.x - remotePlayer!.x).sign;
        remotePlayer!.velocityX = direction * moveSpeed * 0.8;
        remotePlayer!.isFacingRight = direction > 0;
        remotePlayer!.state = PlayerState.running;
      } else if (distanceToLocal < 0.08) {
        final direction = (localPlayer!.x - remotePlayer!.x).sign;
        remotePlayer!.velocityX = -direction * moveSpeed * 0.6;
        remotePlayer!.state = PlayerState.running;
      } else {
        remotePlayer!.velocityX *= 0.8;
        if (remotePlayer!.velocityX.abs() < 0.005) {
          remotePlayer!.state = PlayerState.idle;
        }
      }

      if (random.nextDouble() < 0.03 && remotePlayer!.isGrounded) {
        remotePlayer!.velocityY = jumpForce * 1.1;
        remotePlayer!.state = PlayerState.jumping;
      }

      if (distanceToLocal < 0.12 && remotePlayer!.attackCooldown == 0 && random.nextDouble() < 0.08) {
        final attackType = random.nextDouble() < 0.7 ? OnlineAttackType.light : OnlineAttackType.heavy;
        _performEnemyAttack(attackType);
      }
    }
  }

  void _updatePlayerStateBasedOnPhysics(OnlinePlayer player) {
    if (player.state == PlayerState.death) return;
    if (!player.isGrounded) {
      if (player.velocityY < -0.02) {
        player.state = PlayerState.jumping;
      } else if (player.velocityY > 0.02) {
        player.state = PlayerState.falling;
      }
    } else {
      if (player.velocityX.abs() > 0.02) {
        player.state = PlayerState.running;
      } else {
        player.state = PlayerState.idle;
      }
    }
  }

  void _performEnemyAttack(OnlineAttackType attackType) {
    if (remotePlayer != null && remotePlayer!.state != PlayerState.death) {
      remotePlayer!.currentAttackType = attackType;

      final weapon = getCurrentWeapon(remotePlayer!);
      createAttack(
        type: attackType,
        weapon: weapon,
        x: remotePlayer!.x,
        y: remotePlayer!.y,
        isFacingRight: remotePlayer!.isFacingRight,
      );

      // ✅ تغيير من attacking إلى attacking_light أو attacking_heavy
      if (attackType == OnlineAttackType.light) {
        remotePlayer!.state = PlayerState.attacking_light;
      } else if (attackType == OnlineAttackType.heavy) {
        remotePlayer!.state = PlayerState.attacking_heavy;
      } else {
        remotePlayer!.state = PlayerState.attacking_light;
      }

      remotePlayer!.attackCooldown = 25;
    }
  }

  void _updateActiveAttacks() {
    // ✅ حد أقصى 10 هجمات فقط
    if (activeAttacks.length > 10) {
      print('⚠️ [CLEANUP] تقليل عدد الهجمات من ${activeAttacks.length} إلى 10');
      activeAttacks.sort((a, b) => b.lifetime.compareTo(a.lifetime));
      while (activeAttacks.length > 10) {
        activeAttacks.removeLast();
      }
    }

    final attacksToRemove = <OnlineBattleAttack>[];

    for (var attack in activeAttacks) {
      if (!attack.isActive) {
        attacksToRemove.add(attack);
        continue;
      }

      attack.x += attack.directionX * attack.speed;
      attack.lifetime--;

      if (attack.lifetime <= 0 || attack.x < -0.5 || attack.x > 1.5) {
        attack.isActive = false;
        attacksToRemove.add(attack);
      }
    }

    for (var attack in attacksToRemove) {
      activeAttacks.remove(attack);
    }
  }

  void _checkCollisions() {
    for (var attack in activeAttacks) {
      if (!attack.isActive) continue;

      // ✅ التحقق من تصادم مع اللاعب البعيد
      if (remotePlayer != null &&
          remotePlayer!.state != PlayerState.death &&
          _isAttackHittingPlayer(attack, remotePlayer!)) {

        print('🎯 [HIT] إصابة الخصم بالهجوم: ${attack.type}');
        print('   📍 موقع الهجوم: (${attack.x.toStringAsFixed(2)}, ${attack.y.toStringAsFixed(2)})');
        print('   📍 موقع الخصم: (${remotePlayer!.x.toStringAsFixed(2)}, ${remotePlayer!.y.toStringAsFixed(2)})');
        print('   💥 الضرر: ${attack.damage}');

        // ✅ تسجيل نوع الضرر
        _lastHitDamage['remote'] = attack.damage;

        _applyDamage(remotePlayer!, attack.damage, attack.directionX);
        attack.isActive = false;
        OnlineAudioService().playDamageSound();
        continue; // ✅ توقف عن التحقق من هذا الهجوم
      }

      // ✅ التحقق من تصادم مع اللاعب المحلي
      if (localPlayer != null &&
          localPlayer!.state != PlayerState.death &&
          _isAttackHittingPlayer(attack, localPlayer!)) {

        print('🎯 [HIT] إصابة اللاعب المحلي بالهجوم: ${attack.type}');
        print('   📍 موقع الهجوم: (${attack.x.toStringAsFixed(2)}, ${attack.y.toStringAsFixed(2)})');
        print('   📍 موقع اللاعب: (${localPlayer!.x.toStringAsFixed(2)}, ${localPlayer!.y.toStringAsFixed(2)})');
        print('   💥 الضرر: ${attack.damage}');

        // ✅ تسجيل نوع الضرر
        _lastHitDamage['local'] = attack.damage;

        _applyDamage(localPlayer!, attack.damage, attack.directionX);
        attack.isActive = false;
        OnlineAudioService().playDamageSound();
      }
    }
  }

  // ✅ إضافة دالة للحصول على نوع الضرر الأخير
  String getLastHitDamageType(String playerId) {
    final damage = _lastHitDamage[playerId] ?? 0;
    if (damage == 10) {
      return 'punch';
    } else if (damage >= 10 && damage <= 20) {
      return 'weapon';
    }
    return 'unknown';
  }

  void _applyDamage(OnlinePlayer player, int damage, double knockbackDirection) {
    if (player.damageCooldown > 0) {
      // print('⏳ اللاعب تحت تأثير التبريد: ${player.damageCooldown}');
      return;
    }

    player.takeDamage(damage);
    player.damageCooldown = 30;

    // ✅ تحديث النتيجة
    if (player.playerId == localPlayer!.playerId) {
      remotePlayerScore += damage;
      print('📊 النتيجة - الخصم: $remotePlayerScore');
    } else {
      localPlayerScore += damage;
      print('📊 النتيجة - اللاعب: $localPlayerScore');
    }

    // ✅ تأثير الدفع (Knockback) - قوي وملموس
    final knockbackPower = (damage / 30.0).clamp(0.02, 0.08); // زيادة القوة قليلاً
    player.velocityX = knockbackDirection * knockbackPower;
    player.velocityY = -knockbackPower * 1.2; // دفع للأعلى أكثر لإظهار التأثير

    print('💥 ضرر مطبق: $damage | الصحة المتبقية: ${player.health}');
    // ✅ إضافة تأثير بصري فوري على اللاعب (اختياري، لكنه مفيد)
    _addVisualEffect('hit', player.x, player.y, color: Colors.red, duration: 300);

    // ✅ إذا مات، تصحيح الأنيميشن
    if (player.health <= 0) {
      _fixDeathAnimation(player);
    }
  }

  // ✅ دالة محدثة لتحديث الخصم من بيانات Firestore - بدون أي فيزياء
  void updateRemotePlayerFromFirestore(Map<String, dynamic> playerState) {
    if (remotePlayer == null) return;

    try {
      // ✅ تحديث موقع الخصم فقط - لا نغير السرعات مطلقاً
      if (playerState.containsKey('x')) {
        remotePlayer!.x = (playerState['x'] as num).toDouble();
      }

      if (playerState.containsKey('y')) {
        remotePlayer!.y = (playerState['y'] as num).toDouble();
      }

      if (playerState.containsKey('health')) {
        remotePlayer!.health = (playerState['health'] as num).toDouble();
      }

      // ✅ تحديث حالة الخصم
      if (playerState.containsKey('state')) {
        final stateStr = playerState['state'] as String;
        try {
          final cleanState = stateStr.replaceAll('PlayerState.', '');
          final stateEnum = PlayerState.values.firstWhere(
                (e) => e.toString().replaceAll('PlayerState.', '') == cleanState,
            orElse: () => remotePlayer!.state,
          );
          remotePlayer!.state = stateEnum;
        } catch (e) {
          print('⚠️ خطأ في تحويل حالة الخصم: $e');
        }
      }

      // ✅ تحديث اتجاه الخصم
      if (playerState.containsKey('isFacingRight')) {
        remotePlayer!.isFacingRight = playerState['isFacingRight'] as bool;
      }

      // ✅ تحديث حالة الأرضية (اختياري - قد تكون مفيدة للأنيميشن)
      if (playerState.containsKey('isGrounded')) {
        remotePlayer!.isGrounded = playerState['isGrounded'] as bool;
      }

      // ⭐⭐⭐ مهم جداً: لا نغير السرعات مطلقاً
      // remotePlayer!.velocityX و remotePlayer!.velocityY لا يتم تغييرهما هنا أبداً

    } catch (e) {
      print('❌ خطأ في تحديث الخصم من Firestore: $e');
    }
  }

  // ✅ دالة لتصحيح معرف الخصم
  void setRemotePlayerId(String playerId) {
    if (remotePlayer != null) {
      print('🔄 تغيير معرف الخصم من ${remotePlayer!.playerId} إلى $playerId');
      remotePlayer!.playerId = playerId;
    }
  }

  // ✅ دالة للتحقق من صحة بيانات الخصم المستلمة
  bool validateRemotePlayerData(Map<String, dynamic> playerState) {
    try {
      if (playerState['x'] == null || playerState['y'] == null) return false;

      final x = playerState['x'] as double;
      final y = playerState['y'] as double;
      final health = playerState['health'] as double? ?? 100;

      // التحقق من أن القيم ضمن النطاق المعقول
      if (x < -1.0 || x > 2.0) return false;
      if (y < -0.5 || y > 2.0) return false;
      if (health < 0 || health > 100) return false;

      return true;
    } catch (e) {
      return false;
    }
  }

  void _endGameByTime() {
    isGameRunning = false;
    isGameEnded = true;
    endGameReason = 'time';

    if (localPlayerScore > remotePlayerScore) {
      gameWinner = localPlayer!.playerId;
    } else if (remotePlayerScore > localPlayerScore) {
      gameWinner = remotePlayer!.playerId;
    } else {
      gameWinner = 'draw';
    }

    _sendGameResult();
  }

  void _sendGameResult() {
    final gameResult = {
      'type': 'gameResult',
      'payload': {
        'winner': gameWinner,
        'reason': endGameReason,
        'localScore': localPlayerScore,
        'remoteScore': remotePlayerScore,
        'localDeaths': localPlayerDeaths,
        'remoteDeaths': remotePlayerDeaths,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    };

    print('📤 إرسال نتيجة اللعبة: $gameResult');
  }

  void resetGame() {
    isGameRunning = true;
    isGameEnded = false;
    gameWinner = null;
    endGameReason = null;
    localPlayerScore = 0;
    remotePlayerScore = 0;
    localPlayerDeaths = 0;
    remotePlayerDeaths = 0;
    gameTimer = 180.0;
    activeAttacks.clear();
    activeEffects.clear();

    // ✅ إعادة توليد المنصات العشوائية
    final pattern = PlatformGenerator.getRandomPattern();
    _currentRandomPlatforms = PlatformGenerator.generatePlatformsFromPattern(pattern);
    _currentPlatformPatternName = pattern.name;
    platforms = _currentRandomPlatforms;

    print('🎲 تم إعادة توليد المنصات بنمط: $_currentPlatformPatternName');

    if (localPlayer != null) {
      _respawnPlayer(localPlayer!);
      localPlayer!.weapons.clear();
      localPlayer!.weapons.addAll([
        OnlineWeaponLibrary.getWeapon(localPlayer!.character.primaryWeapon),
        OnlineWeaponLibrary.getWeapon(localPlayer!.character.secondaryWeapon),
      ]);
    }

    if (remotePlayer != null) {
      _respawnPlayer(remotePlayer!);
      remotePlayer!.weapons.clear();
      remotePlayer!.weapons.addAll([
        OnlineWeaponLibrary.getWeapon(remotePlayer!.character.primaryWeapon),
        OnlineWeaponLibrary.getWeapon(remotePlayer!.character.secondaryWeapon),
      ]);
    }

    print('🔄 تم إعادة تعيين اللعبة مع منصات جديدة');
  }

  void _respawnPlayer(OnlinePlayer player) {
    final random = Random();
    double newX, newY;

    newX = player.playerId == 'local_player' ? 0.3 : 0.7;
    newY = 0.7;

    player.health = 100.0;
    player.x = newX;
    player.y = newY;
    player.velocityX = 0.0;
    player.velocityY = 0.0;
    player.state = PlayerState.idle;
    player.isGrounded = false;
    player.canMove = true;
    player.damageCooldown = 60;
  }

  Map<String, dynamic> getGameResult() {
    return {
      'isGameEnded': isGameEnded,
      'winner': gameWinner,
      'reason': endGameReason,
      'localScore': localPlayerScore,
      'remoteScore': remotePlayerScore,
      'localDeaths': localPlayerDeaths,
      'remoteDeaths': remotePlayerDeaths,
      'isDraw': gameWinner == 'draw',
    };
  }

  bool _isPlayerOnPlatform(OnlinePlayer player, BattlePlatform platform) {
    final playerBottom = player.y + 0.04;
    final playerLeft = player.x - 0.025;
    final playerRight = player.x + 0.025;

    final platformTop = platform.y - platform.height / 2;
    final platformBottom = platform.y + platform.height / 2;
    final platformLeft = platform.x - platform.width / 2;
    final platformRight = platform.x + platform.width / 2;

    // ✅ تحقق دقيق من التصادم
    bool isVerticallyClose = playerBottom >= platformTop - 0.02 &&
        playerBottom <= platformTop + 0.1;

    bool isHorizontallyAligned = playerRight >= platformLeft &&
        playerLeft <= platformRight;

    bool isFalling = player.velocityY >= 0;

    bool isOnPlatform = isFalling && isVerticallyClose && isHorizontallyAligned;

    // ✅ طباعة معلومات التصادم للتصحيح
    if (isOnPlatform && !player.isGrounded) {
      print('🎯 تصادم مع منصة ${platform.type}:');
      print('   👤 اللاعب: (${player.x.toStringAsFixed(3)}, ${player.y.toStringAsFixed(3)})');
      print('   🏔️ المنصة: (${platform.x}, ${platform.y}) بعرض ${platform.width}');
      print('   📏 المسافة الرأسية: ${(playerBottom - platformTop).toStringAsFixed(3)}');
      print('   ➡️ محاذاة أفقية: $isHorizontallyAligned');
    }

    return isOnPlatform;
  }

  bool _isAttackHittingPlayer(OnlineBattleAttack attack, OnlinePlayer player) {
    final distanceX = (attack.x - player.x).abs();
    final distanceY = (attack.y - player.y).abs();

    // ✅ زيادة مساحة التأثير للهجمات
    final hitDistanceX = attack.range * 1.2; // ✅ زيادة من 1.5 إلى 1.2
    final hitDistanceY = 0.15; // ✅ زيادة من 0.1 إلى 0.15

    bool isHit = distanceX < hitDistanceX && distanceY < hitDistanceY;

    if (isHit) {
      print('🎯 [COLLISION DETECTED]');
      print('   📏 المسافة الأفقية: ${distanceX.toStringAsFixed(3)} < $hitDistanceX');
      print('   📏 المسافة العمودية: ${distanceY.toStringAsFixed(3)} < $hitDistanceY');
      print('   🎯 المدى: ${attack.range}');
    }

    return isHit && player.damageCooldown == 0;
  }

  void movePlayerLeft() {
    if (localPlayer != null && localPlayer!.state != PlayerState.death && localPlayer!.canMove) {
      if (localPlayer!.isGrounded) {
        localPlayer!.velocityX = -moveSpeed;
      } else {
        localPlayer!.velocityX = -airControl;
      }
      localPlayer!.isFacingRight = false;
      print('⬅️ حركة يسار - السرعة: ${localPlayer!.velocityX}');
    }
  }

  void movePlayerRight() {
    if (localPlayer != null && localPlayer!.state != PlayerState.death && localPlayer!.canMove) {
      if (localPlayer!.isGrounded) {
        localPlayer!.velocityX = moveSpeed;
      } else {
        localPlayer!.velocityX = airControl;
      }
      localPlayer!.isFacingRight = true;
      print('➡️ حركة يمين - السرعة: ${localPlayer!.velocityX}');
    }
  }

  void jumpPlayer() {
    if (localPlayer != null && localPlayer!.isGrounded && localPlayer!.canMove) {
      // ✅ زيادة قوة القفز مع تخفيض الجاذبية المؤقتة
      localPlayer!.velocityY = -0.038; // ✅ زيادة من -0.048 إلى -0.038 (أقوى)

      // ✅ تخفيض الجاذبية مؤقتاً أثناء القفز
      Future.delayed(Duration(milliseconds: 200), () {
        if (localPlayer != null && localPlayer!.state == PlayerState.jumping) {
          // ✅ إضافة جاذبية إضافية بعد ذروة القفز
          localPlayer!.velocityY += 0.001;
        }
      });

      localPlayer!.state = PlayerState.jumping;
      localPlayer!.isGrounded = false;
      OnlineAudioService().playJumpSound();
      print('🦘 🔥 قفز قوي جداً - القوة: -0.038');
    }
  }

  void playerAttack(OnlineAttackType attackType) {
    final player = localPlayer;
    if (player == null || player.state == PlayerState.death || player.attackCooldown > 0 || !player.canMove) {
      return;
    }

    player.currentAttackType = attackType;

    // ✅ تغيير من attacking إلى attacking_light أو attacking_heavy
    if (attackType == OnlineAttackType.light) {
      player.state = PlayerState.attacking_light;
    } else if (attackType == OnlineAttackType.heavy) {
      player.state = PlayerState.attacking_heavy;
    } else {
      player.state = PlayerState.attacking_light;
    }

    player.attackCooldown = 20;
  }

  void stopPlayerMovement() {
    if (localPlayer != null && localPlayer!.state == PlayerState.running) {
      localPlayer!.state = PlayerState.idle;
    }
  }

  void dodgePlayer() {
    if (localPlayer != null && localPlayer!.canMove) {
      localPlayer!.velocityX = (localPlayer!.isFacingRight ? 1 : -1) * 0.04;
      localPlayer!.velocityY = -0.01;
      localPlayer!.canMove = false;
      Timer(Duration(milliseconds: 300), () {
        if (localPlayer != null) {
          localPlayer!.canMove = true;
        }
      });
    }
  }

  void debugActiveAttacks() {
    print('''
🔫 === فحص الهجمات النشطة ===
   عدد الهجمات: ${activeAttacks.length}
   الهجمات النشطة: ${activeAttacks.where((a) => a.isActive).length}
==============================
''');

    for (var attack in activeAttacks) {
      if (attack.isActive) {
        print('   ⚔️ ${attack.type} - '
            '(${attack.x.toStringAsFixed(2)}, ${attack.y.toStringAsFixed(2)}) - '
            'العمر: ${attack.lifetime} - '
            'الضرر: ${attack.damage}');
      }
    }
  }

  // ✅ دالة لفحص النظام كاملاً
  void debugFullSystemCheck() {
    print('''
🔍 === فحص النظام الكامل ===
اللاعب المحلي:
   موجود: ${localPlayer != null}
   الصحة: ${localPlayer?.health ?? 0}
   الأسلحة: ${localPlayer?.weapons.length ?? 0}
   الهجوم الحالي: ${localPlayer?.currentWeapon?.name ?? "لا يوجد"}

الخصم:
   موجود: ${remotePlayer != null}
   الصحة: ${remotePlayer?.health ?? 0}
   الأسلحة: ${remotePlayer?.weapons.length ?? 0}
   الهجوم الحالي: ${remotePlayer?.currentWeapon?.name ?? "لا يوجد"}

الهجمات النشطة: ${activeAttacks.length}
المنصات: ${platforms.length}
وقت اللعبة: ${gameTimer.toStringAsFixed(1)}
اللعبة نشطة: $isGameRunning
اللعبة منتهية: $isGameEnded
=============================
''');
  }

  void dispose() {
    _gameTimer?.cancel();
    activeAttacks.clear();
    activeEffects.clear();
    localPlayer?.dispose();
    remotePlayer?.dispose();
  }
}