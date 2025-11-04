import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../Languages/localization.dart';
import '../managers/enemy_manager.dart';
import '../models/Boss.dart';
import '../models/background_elements.dart';
import '../models/character_model.dart';
import '../models/enums.dart';
import '../models/power_up_system.dart';
import '../services/game_data_service.dart';
import '../models/character.dart';
import '../models/obstacle.dart';
import '../models/level_data.dart';
import '../models/particle.dart';
import '../services/audio_service.dart';
import '../services/image_service.dart';
import '../services/vibration_service.dart';
import '../services/challenge_service.dart';
import 'game_state_restore.dart';

class GameEngine {
  // === المتغيرات الأساسية ===
  Character? _character;
  final List<Obstacle> _obstacles = [];
  final List<Obstacle> _enemies = [];
  final List<Obstacle> _platforms = [];
  final List<PowerUp> _powerUps = [];
  final List<GameParticle> _particles = [];
  final BackgroundManager _backgroundManager = BackgroundManager();
  final EnemyManager _enemyManager = EnemyManager();

  BuildContext? _gameContext;

  // === نظام الزعيم ===
  Boss? _currentBoss;
  bool _isBossFight = false;
  bool _isBossDefeated = false;
  double _bossFightStartTime = 0;
  bool _bossSpawned = false;
  int _preBossScore = 0;
  bool _isBossSpawnTriggered = false;
  int get _targetScoreForBoss => (levelData.targetScore * 0.7).toInt();

  // === حالة اللعبة ===
  int _score = 0;
  int _level = 1;
  bool _isGameRunning = false;
  bool _hasShield = false;
  bool _isSlowMotion = false;
  bool _isDoublePoints = false;
  bool _levelCompleted = false;
  bool _isInitialized = false;
  double _gameTime = 0.0;

  // === نظام الكومبو ===
  int _coinsCollected = 0;
  int _obstaclesAvoided = 0;
  int _powerUpsCollected = 0;
  int _enemiesDefeated = 0;
  Timer? _comboTimer;

  // === نظام الباور أب المتقدم ===
  final Map<PowerUpType, int> _powerUpSpawnsThisLevel = {};
  final Map<PowerUpType, int> _powerUpsCollectedThisLevel = {};
  bool _isSpeedBoostActive = false;
  bool _areEnemiesSlowed = false;
  Timer? _speedBoostTimer;
  Timer? _slowEnemiesTimer;
  int _coinsEarnedThisLevel = 0;

  // === التايمرات ===
  Timer? _gameTimer;
  Timer? _obstacleSpawnTimer;
  Timer? _enemySpawnTimer;
  Timer? _powerUpSpawnTimer;
  Timer? _platformSpawnTimer;
  Timer? _shieldTimer;
  Timer? _slowMotionTimer;
  Timer? _doublePointsTimer;
  Timer? _levelTimer;
  Timer? _tutorialTimer;
  Timer? _groundTextTimer;

  // === نظام التعليمات ===
  bool _showTutorialArrows = true;
  bool _showGroundText = true;
  bool _showBossAttackHint = false;
  Timer? _bossHintTimer;
  bool _showCombatHint = false;
  Timer? _combatHintTimer;

  // === منع الاستدعاء المزدوج ===
  bool _isGameOverCalled = false;
  bool _isLevelCompleteCalled = false;

  final Random _random = Random();
  final LevelData levelData;
  VoidCallback? onGameOver;
  final Function()? onLevelComplete;
  final Function()? onBossAppear;
  final Function()? onBossDefeated;
  final Function()? onCharacterDamage;
  final Function()? onBossHit;

  // === نظام الاستمرار بعد الموت ===
  // int _continueCount = 0;
  // static const int _maxContinueCount = 3;
  // GameStateRestore? _savedGameState;
  // bool get canContinue => _continueCount < _maxContinueCount && _savedGameState != null;
  // int get remainingContinues => _maxContinueCount - _continueCount;

  bool _showTutorialInstructions = true;
  Timer? _tutorialInstructionsTimer;

  // === الخصائص العامة ===
  int get score => _score;
  int get level => _level;
  bool get isGameRunning => _isGameRunning;
  bool get hasShield => _hasShield;
  bool get isSlowMotion => _isSlowMotion;
  bool get isDoublePoints => _isDoublePoints;
  bool get isLevelCompleted => _levelCompleted;
  int get remainingTime => 0; // إرجاع 0 لأننا لا نستخدم الوقت
  List<Obstacle> get obstacles => _obstacles;
  List<Obstacle> get enemies => _enemies;
  List<Obstacle> get platforms => _platforms;
  List<PowerUp> get powerUps => _powerUps;
  List<GameParticle> get particles => _particles;
  BackgroundManager get backgroundManager => _backgroundManager;
  Character get character => _character!;
  bool get showTutorialArrows => _showTutorialArrows;
  bool get showGroundText => _showGroundText;
  bool get showBossAttackHint => _showBossAttackHint;
  Boss? get currentBoss => _currentBoss;
  bool get isBossFight => _isBossFight;
  bool get isBossDefeated => _isBossDefeated;
  double get gameTime => _gameTime;
  bool get isSpeedBoostActive => _isSpeedBoostActive;
  bool get areEnemiesSlowed => _areEnemiesSlowed;
  String get currentBackground => _backgroundManager.currentBackground;
  int get timeSpent => 0; // إرجاع 0 لأننا لا نستخدم الوقت

  // === خصائص الزعيم ===
  bool get isBossSpawned => _bossSpawned;

  bool get shouldGameEnd => _character?.isDead == true || _isBossDefeated;
  bool get showTutorialInstructions => _showTutorialInstructions;

  double get levelCompletionPercentage {
    if (_isBossFight || _isBossDefeated) return 1.0;
    return (_score / levelData.targetScore).clamp(0.0, 1.0);
  }

  double get bossTimeProgress {
    if (_isBossFight || _bossSpawned) return 1.0;
    return (_score / _targetScoreForBoss).clamp(0.0, 1.0);
  }

  int get bossTimeRemaining {
    if (_isBossFight || _bossSpawned) return 0;
    final scoreNeeded = _targetScoreForBoss - _score;
    return scoreNeeded.clamp(0, _targetScoreForBoss);
  }

  String get bossTimeInfo {
    if (_isBossFight || _bossSpawned) return 'الزعيم ظهر!';
    final scoreNeeded = _targetScoreForBoss - _score;
    if (scoreNeeded <= 0) return 'الزعيم سيظهر قريباً!';
    return 'الزعيم: $scoreNeeded نقطة';
  }

  GameEngine({
    required this.levelData,
    this.onLevelComplete,
    this.onBossAppear,
    this.onBossDefeated,
    this.onCharacterDamage,
    this.onBossHit,
  });

  // === دالة التعليمات المؤقتة ===
  void _startTutorialInstructionsTimer() {
    _tutorialInstructionsTimer = Timer(const Duration(seconds: 6), () {
      _showTutorialInstructions = true;
    });
  }

  // === التهيئة ===
  void initialize() {
    if (_isInitialized) return;

    _character = Character(
      x: 0.2,
      y: 0.7,
      groundY: 0.75,
      jumpPower: -0.045,
      gravity: 0.0018,
      weight: 1.1,
    );

    _loadSelectedCharacter();
    _character!.setJumpBounds(0.3, 0.1);
    _backgroundManager.initialize();
    _initializePlatforms();
    _initializePowerUpSystem();
    PowerUpSystem.initializeStats();
    _isInitialized = true;

    _startTutorialTimer();
    _startGroundTextTimer();
    // print('🎮 تم تهيئة محرك اللعبة بنجاح');
  }

  void _loadSelectedCharacter() async {
    try {
      final selectedCharacter = await GameDataService.getSelectedCharacter();
      _character?.setCharacter(selectedCharacter);
      // print('👤 تم تحميل الشخصية: ${selectedCharacter.name}');
    } catch (e) {
      final defaultCharacter = GameCharacter.getDefaultCharacter();
      _character?.setCharacter(defaultCharacter);
      // print('⚠️ استخدام الشخصية الافتراضية بسبب: $e');
    }
  }

  void _initializePowerUpSystem() {
    PowerUpSystem.initializeStats();
    _powerUpSpawnsThisLevel.clear();
    _powerUpsCollectedThisLevel.clear();
    _coinsEarnedThisLevel = 0;

    for (final type in PowerUpType.values) {
      _powerUpSpawnsThisLevel[type] = 0;
      _powerUpsCollectedThisLevel[type] = 0;
    }
  }

  void _initializePlatforms() {
    _platforms.clear();

    // منصة أساسية
    _platforms.add(Obstacle(
      x: 1.1,
      y: 0.5,
      width: 0.18,
      height: 0.035,
      speed: 0.04,
      color: Colors.brown.shade400,
      type: ObstacleType.groundLong,
      isWalkable: true,
      isEnemy: false,
      imagePath: ImageService.platform,
    ));

    // منصة ثانية
    _platforms.add(Obstacle(
      x: 1.8,
      y: 0.4,
      width: 0.12,
      height: 0.035,
      speed: 0.05,
      color: Colors.brown.shade400,
      type: ObstacleType.groundLong,
      isWalkable: true,
      isEnemy: false,
      imagePath: ImageService.platform,
    ));
  }

// === نظام حفظ حالة اللعبة ===
//   void _saveGameState() {
//     if (_character == null) {
//       print('❌ لا يمكن حفظ الحالة: الشخصية غير موجودة');
//       return;
//     }
//
//     // ✅✅✅ هنا الحل: استخدام .map((e) => e.clone()).toList() ✅✅✅
//     _savedGameState = GameStateRestore(
//       score: _score,
//       level: _level,
//       characterX: _character!.x,
//       characterY: _character!.y,
//       characterHealth: _character!.health,
//       characterLives: _character!.lives,
//
//       // إنشاء نسخ عميقة ومستقلة من كل كائن في القوائم
//       obstacles: _obstacles.map((obs) => obs.clone()).toList(),
//       enemies: _enemies.map((enemy) => enemy.clone()).toList(),
//       powerUps: _powerUps.map((p) => p.clone()).toList(),
//       platforms: _platforms.map((p) => p.clone()).toList(),
//
//       gameTime: _gameTime,
//       isBossFight: _isBossFight,
//       currentBoss: _currentBoss?.clone(), // نسخ الزعيم أيضًا إذا كان موجودًا
//       hasShield: _hasShield,
//       isSlowMotion: _isSlowMotion,
//       isDoublePoints: _isDoublePoints,
//     );
//
//     print('💾 تم حفظ حالة اللعبة بنسخ عميق - النقاط: $_score');
//     print('🔄 عدد المحاولات المتبقية: ${_maxContinueCount - _continueCount}');
//   }
//
//
//   void _restoreGameState() {
//     if (_savedGameState == null || _character == null) return;
//
//     final state = _savedGameState!;
//
//     _score = state.score;
//     _level = state.level;
//     _character!.x = state.characterX;
//     _character!.y = state.characterY;
//     _character!.health = state.characterHealth;
//     _character!.lives = state.characterLives;
//
//     _obstacles.clear();
//     _obstacles.addAll(state.obstacles);
//
//     _enemies.clear();
//     _enemies.addAll(state.enemies);
//
//     _powerUps.clear();
//     _powerUps.addAll(state.powerUps);
//
//     _platforms.clear();
//     _platforms.addAll(state.platforms);
//
//     _gameTime = state.gameTime;
//     _isBossFight = state.isBossFight;
//     _currentBoss = state.currentBoss;
//     _hasShield = state.hasShield;
//     _isSlowMotion = state.isSlowMotion;
//     _isDoublePoints = state.isDoublePoints;
//
//     _isGameRunning = true;
//     _levelCompleted = false;
//     _isGameOverCalled = false;
//   }
//
//   void continueGame() {
//     // التأكد من أن اللاعب يمكنه الاستمرار
//     if (!canContinue) { // تم تبسيط الشرط
//       print('❌ لا يمكن الاستمرار، سيتم إعادة تشغيل اللعبة.');
//       startGame(); // إعادة تشغيل المستوى كحل بديل إذا لم يتمكن من الاستمرار
//       return;
//     }
//
//     print('🔄 استمرار اللعبة...');
//     _continueCount++;
//
//     // 1. استعادة حالة اللعبة من النقطة التي توقفت عندها
//     _restoreGameState();
//
//     // 2. إعادة إحياء الشخصية (خطوة حاسمة)
//     _character?.revive();
//
//     // 3. إعادة تعيين متغيرات الحالة للسماح باللعب مرة أخرى
//     _isGameOverCalled = false;
//     _isLevelCompleteCalled = false;
//     _levelCompleted = false;
//
//     // 4. استئناف منطق اللعبة
//     _isGameRunning = true;
//
//     // 5. إعادة تشغيل المولدات التي تم إيقافها
//     _startSpawners();
//
//     // 6. ✅✅✅ إعادة تشغيل حلقة اللعبة الرئيسية ✅✅✅
//     _startGameLoop();
//
//     // 7. استئناف الموسيقى
//     AudioService().playBackgroundMusic();
//
//     print('✅ تم استمرار اللعبة بنجاح!');
//   }

  // دالة لتعيين context للترجمة
  void setGameContext(BuildContext context) {
    _gameContext = context;
  }

  // دالة للحصول على معلومات الباور أب المترجمة
  Map<String, String> getPowerUpInfo(PowerUpType type) {
    if (_gameContext == null) return {'name': '', 'description': ''};

    final l10n = AppLocalizations.of(_gameContext!);
    final powerUp = PowerUpSystem.getPowerUp(type);

    return {
      'name': powerUp.getName(l10n),
      'description': powerUp.getDescription(l10n),
      'effect': powerUp.getEffectDescription(l10n),
      'rarity': PowerUpSystem.getPowerUpRarityName(type, l10n),
    };
  }

  // === نظام التعليمات ===
  void _startTutorialTimer() {
    _tutorialTimer = Timer(const Duration(seconds: 5), () {
      _showTutorialArrows = false;
    });
  }

  void _startGroundTextTimer() {
    _groundTextTimer = Timer(const Duration(seconds: 2), () {
      _showGroundText = false;
    });
  }

  void _startBossHintTimer() {
    _showBossAttackHint = true;
    _bossHintTimer = Timer(const Duration(seconds: 2), () {
      _showBossAttackHint = false;
    });
  }

  void _showCombatHintTemporary() {
    if (!_showCombatHint) {
      _showCombatHint = true;
      _combatHintTimer?.cancel();
      _combatHintTimer = Timer(const Duration(seconds: 2), () {
        _showCombatHint = false;
      });
    }
  }

  // === بدء اللعبة ===
  void startGame() {
    if (!_isInitialized) initialize();

    _resetGameState();
    _isGameRunning = true;
    _levelCompleted = false;

    // === تعيين الزوج المناسب للخلفية والأرضية للمستوى الحالي ===
    _setBackgroundGroundPairForLevel();

    _startGameLoop();
    _startLevelTimer();
    _startSpawners();

    AudioService().playBackgroundMusic();
    // print('🎮 بدء اللعبة - المستوى: ${levelData.levelNumber}');
  }

  void _startGameLoop() {
    _gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (_isGameRunning && _character != null) {
        _updateGame();
      } else {
        timer.cancel();
      }
    });
  }

  void _startLevelTimer() {
    _levelTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isGameRunning || _character == null || _levelCompleted) {
        timer.cancel();
        return;
      }

      _updateBossAppearance();

      // === التحقق من النقاط للزعيم ===
      final scoreForBoss = _targetScoreForBoss - _score;

      if (scoreForBoss <= 50 && scoreForBoss > 0 && !_bossSpawned) {
        print('⚡ تحذير: الزعيم سيظهر بعد $scoreForBoss نقطة!');
      }
    });
  }

  // === نظام ظهور الزعيم ===
  bool get _shouldBossAppear {
    if (_isBossFight || _bossSpawned || _levelCompleted) return false;

    // === التغيير: الظهور عند 80% من النقاط ===
    final bool shouldAppear = _score >= _targetScoreForBoss && !_isBossSpawnTriggered;

    if (shouldAppear && !_bossSpawned) {
      print('👹 ظهور الزعيم عند النقاط: $_score (الهدف: $_targetScoreForBoss)');
      _isBossSpawnTriggered = true;
    }
    return shouldAppear;
  }

  // === نظام النقاط المتوازن ===
  int _calculateBalancedPoints(int basePoints) {
    // جعل النقاط أقل لزيادة صعوبة اللعبة
    final reducedPoints = (basePoints * 0.8).toInt(); // تخفيض النقاط إلى 60%
    return reducedPoints.clamp(1, basePoints);
  }

  void _addScore(int points) {
    // إزالة نظام منع التجميع السريع لجعل اللعبة أطول
    _score += points;

    // التحقق من ظهور الزعيم عند كل إضافة نقاط
    _updateBossAppearance();

    // التحقق من اكتمال المستوى (فقط بعد هزيمة الزعيم)
    if (_isBossDefeated && _score >= levelData.targetScore && !_levelCompleted) {
      _completeLevel();
    }
  }

  // === التحديث الرئيسي ===
  void _updateGame() {
    if (!_isGameRunning || _character == null) return;

    // التحقق من حالة الشخصية أولاً
    if (_character!.isDead && !_isGameOverCalled) {
      // 🛑 الخطوة الحاسمة: أوقف اللعبة مؤقتًا واحفظ الحالة فورًا
      _isGameRunning = false; // لمنع استدعاءات متكررة
      // _saveGameState();       // ✅✅✅ احفظ الحالة *قبل* استدعاء gameOver

      // استدعِ gameOver بعد ذلك
      _gameOver();
      return; // مهم جدًا للخروج من التحديث
    }

    _gameTime += 0.016;
    _character!.updateAttacks();

    // تحديث ظهور الزعيم بناءً على النقاط
    if (!_isBossFight && !_bossSpawned) {
      _updateBossAppearance();
    }

    // تحديث العناصر بناءً على حالة المعركة
    if (_isBossFight) {
      _updateBoss();
    } else {
      _updateEnemies();
      _updateObstacles();
      _updatePowerUps();
      _updatePlatforms();
      _checkBrickJumping();
      _checkPlatformAndBrickBreaking();
    }

    _backgroundManager.update();
    _updateCharacter();
    _updateParticles();
  }

  void _updateCharacter() {
    _character!.update();
    _checkPlatformCollisions();
    _enforceScreenBounds();
  }

  void _enforceScreenBounds() {
    if (_character == null) return;
    _character!.x = _character!.x.clamp(0.05, 0.95);
    _character!.y = _character!.y.clamp(0.1, 0.85);
  }

  // === نظام المنصات ===
  void _updatePlatforms() {
    final platformsToRemove = <Obstacle>[];

    for (var platform in _platforms) {
      platform.move();

      bool shouldRemove = platform.speed > 0
          ? platform.x < -platform.width
          : platform.x > 1.0 + platform.width;

      if (shouldRemove) {
        platformsToRemove.add(platform);
      }
    }

    _removePlatforms(platformsToRemove);

    // إضافة منصات جديدة إذا لزم الأمر
    if (_platforms.length < 3 && _random.nextDouble() < 0.3) {
      _spawnPlatform();
    }
  }

  void _spawnPlatform() {
    if (!_isGameRunning || _levelCompleted || _character == null) return;

    final platform = _createRandomPlatform();
    _platforms.add(platform);
  }

  Obstacle _createRandomPlatform() {
    final types = [
      {'width': 0.18, 'height': 0.035, 'speed': 0.04},
      {'width': 0.12, 'height': 0.035, 'speed': 0.05},
      {'width': 0.15, 'height': 0.03, 'speed': 0.03},
    ];

    final type = types[_random.nextInt(types.length)];
    final baseSpeed = type['speed'] as double;
    double finalSpeed = _random.nextDouble() < 0.7 ? baseSpeed : -baseSpeed * 0.8;

    if (_random.nextDouble() < 0.1) finalSpeed = 0.0;
    if (_level >= 5) finalSpeed *= (1.0 + (_level * 0.02));

    double startX = finalSpeed > 0 ? 1.1 + _random.nextDouble() * 0.3 : -0.2 - _random.nextDouble() * 0.3;

    return Obstacle(
      x: startX,
      y: 0.3 + _random.nextDouble() * 0.4,
      width: type['width'] as double,
      height: type['height'] as double,
      speed: finalSpeed,
      color: Colors.brown.shade400,
      type: ObstacleType.groundLong,
      isWalkable: true,
      isEnemy: false,
      imagePath: ImageService.platform,
    );
  }

  void _checkPlatformCollisions() {
    bool onPlatform = false;

    for (var platform in _platforms) {
      if (_isCharacterOnPlatform(_character!, platform)) {
        onPlatform = true;
        _character!.standOnPlatform(platform.y - platform.height / 2);
        break;
      }
    }

    for (var obstacle in _obstacles) {
      if (obstacle.isStandable && _isCharacterOnPlatform(_character!, obstacle)) {
        onPlatform = true;
        _character!.standOnPlatform(obstacle.y - obstacle.height / 2);
        break;
      }
    }

    if (!onPlatform && _character!.isOnPlatform) {
      _character!.leavePlatform();
    }
  }

  bool _isCharacterOnPlatform(Character character, Obstacle platform) {
    final characterBottom = character.y;
    final platformTop = platform.y - platform.height / 2;

    final characterLeft = character.x - character.width / 2;
    final characterRight = character.x + character.width / 2;

    final platformLeft = platform.x - platform.width / 2;
    final platformRight = platform.x + platform.width / 2;

    final horizontalOverlap = characterRight > platformLeft && characterLeft < platformRight;
    final verticalProximity = (characterBottom - platformTop).abs() < 0.05;
    final isFallingOntoPlatform = character.velocityY > 0;

    return horizontalOverlap && verticalProximity && isFallingOntoPlatform;
  }

  // === نظام تكسير المنصات والطوب ===
  void _checkPlatformAndBrickBreaking() {
    if (_character == null) return;

    final platformsToRemove = <Obstacle>[];
    for (var platform in _platforms) {
      if (_isCharacterOnPlatform(_character!, platform)) {
        platformsToRemove.add(platform);
      }
    }

    final bricksToRemove = <Obstacle>[];
    for (var obstacle in _obstacles) {
      if (_isBrickObstacle(obstacle) && _isCharacterJumpingOnBrick(_character!, obstacle)) {
        bricksToRemove.add(obstacle);
      }
    }

    for (var platform in platformsToRemove) {
      _handlePlatformBreak(platform);
    }
    for (var brick in bricksToRemove) {
      _handleBrickBreak(brick);
    }
  }

  void _handlePlatformBreak(Obstacle platform) {
    _createPlatformBreakParticles(platform.x, platform.y);
    _platforms.remove(platform);
    AudioService().playEnemyHitSound();
    VibrationService.vibrateSuccess();
  }

  void _handleBrickBreak(Obstacle brick) {
    _createBrickBreakParticles(brick.x, brick.y);
    _obstacles.remove(brick);

    final brickPoints = _calculateBalancedPoints(2);
    _addScore(brickPoints);

    AudioService().playEnemyHitSound();
    VibrationService.vibrateSuccess();
  }

  bool _isBrickObstacle(Obstacle obstacle) {
    return obstacle.color == Colors.brown ||
        obstacle.imagePath == ImageService.brick ||
        obstacle.type == ObstacleType.groundLong;
  }

  bool _isCharacterJumpingOnBrick(Character character, Obstacle brick) {
    final characterBottom = character.y;
    final brickTop = brick.y - brick.height / 2;
    final characterLeft = character.x - character.width / 2;
    final characterRight = character.x + character.width / 2;

    final brickLeft = brick.x - brick.width / 2;
    final brickRight = brick.x + brick.width / 2;

    final horizontalReduction = 0.1;
    final effectiveBrickLeft = brickLeft + (brick.width * horizontalReduction / 2);
    final effectiveBrickRight = brickRight - (brick.width * horizontalReduction / 2);

    final horizontalOverlap = characterRight > effectiveBrickLeft && characterLeft < effectiveBrickRight;
    final verticalProximity = (characterBottom - brickTop).abs() < 0.05;
    final isFalling = character.velocityY > 0;

    return horizontalOverlap && verticalProximity && isFalling;
  }

  void _checkBrickJumping() {
    if (_character == null || !_character!.isJumping) return;

    final bricksToRemove = <Obstacle>[];
    for (var obstacle in _obstacles) {
      if (_isBrickObstacle(obstacle) && _isCharacterJumpingOnBrick(_character!, obstacle)) {
        bricksToRemove.add(obstacle);
      }
    }

    for (var brick in bricksToRemove) {
      _handleBrickJump(brick);
    }
  }

  void _handleBrickJump(Obstacle brick) {
    _character!.velocityY = 0.0;
    _character!.isJumping = false;
    _character!.y = (brick.y - brick.height / 2) - _character!.height;

    final brickPoints = _calculateBalancedPoints(1);
    _addScore(brickPoints);

    _createJumpParticles(_character!.x, _character!.y);
    AudioService().playJumpSound();
    VibrationService.vibrateSuccess();

    _createBrickBreakParticles(brick.x, brick.y);
    _obstacles.remove(brick);
  }

  // === نظام العوائق ===
  void _updateObstacles() {
    final obstaclesToRemove = <Obstacle>[];

    for (var obstacle in _obstacles) {
      obstacle.move();

      if (_checkCollision(_character!, obstacle)) {
        _handleObstacleCollision(obstacle, obstaclesToRemove);
      }

      if (obstacle.isOffScreen()) {
        obstaclesToRemove.add(obstacle);
        _obstaclesAvoided++;

        if (!_isBossFight) {
          final pointsEarned = _calculateBalancedPoints(5);
          _addScore(pointsEarned);
        }
      }
    }

    _removeObstacles(obstaclesToRemove);
  }

  void _spawnObstacle() {
    if (!_isGameRunning || _levelCompleted || _character == null || _isBossFight) return;

    final speed = _isSlowMotion ? levelData.obstacleSpeed * 0.5 : levelData.obstacleSpeed;

    if (_random.nextDouble() < 0.8) {
      final obstacle = _createRandomObstacle(speed);
      _obstacles.add(obstacle);
    }
  }

  Obstacle _createRandomObstacle(double speed) {
    final obstacleType = _random.nextDouble();
    double yPosition, width, height;
    ObstacleType type;
    String? imagePath;

    double getRandomSkyHeight() {
      final heightTier = _random.nextDouble();
      if (heightTier < 0.25) return 0.25 + _random.nextDouble() * 0.1;
      else if (heightTier < 0.5) return 0.35 + _random.nextDouble() * 0.1;
      else if (heightTier < 0.75) return 0.45 + _random.nextDouble() * 0.15;
      else return 0.55 + _random.nextDouble() * 0.1;
    }

    bool isBrick = _random.nextDouble() < 0.5;

    if (obstacleType < 0.2) {
      yPosition = 0.75;
      if (isBrick) {
        width = 0.12; height = 0.12;
        type = ObstacleType.groundLong;
        imagePath = ImageService.brick;
      } else {
        width = 0.1; height = 0.15;
        type = ObstacleType.groundLong;
        imagePath = ImageService.pipe;
      }
    } else if (obstacleType < 0.4) {
      yPosition = getRandomSkyHeight();
      if (isBrick) {
        width = 0.08; height = 0.08;
        type = ObstacleType.skyLong;
        imagePath = ImageService.brick;
      } else {
        width = 0.07; height = 0.12;
        type = ObstacleType.skyLong;
        imagePath = ImageService.pipe;
      }
    } else {
      yPosition = getRandomSkyHeight();
      if (isBrick) {
        width = 0.1; height = 0.1;
        type = ObstacleType.skyLong;
        imagePath = ImageService.brick;
      } else {
        width = 0.08; height = 0.14;
        type = ObstacleType.skyLong;
        imagePath = ImageService.pipe;
      }
    }

    return Obstacle(
      x: 1.1,
      y: yPosition,
      speed: speed,
      width: width,
      height: height,
      color: isBrick ? Colors.brown : Colors.green,
      type: type,
      imagePath: imagePath,
    );
  }

  // === نظام الأعداء ===
  void _updateEnemies() {
    final enemiesToRemove = <Obstacle>[];

    final currentSpeedMultiplier = _areEnemiesSlowed ? 0.5 : 1.0;

    _enemyManager.updateEnemies(_enemies, _character!.x, _character!.y);

    for (var enemy in _enemies) {
      if (enemy.type == ObstacleType.flyingEnemy) {
        _updateFlyingEnemyMovement(enemy);
      }

      enemy.move(currentSpeedMultiplier);

      if (_isCharacterJumpingOnEnemy(_character!, enemy)) {
        _defeatEnemy(enemy, enemiesToRemove);
      }
      else if (_checkCollision(_character!, enemy)) {
        _handleEnemyCollision(enemy);
      }

      for (var attack in _character!.attacks) {
        if (attack.isActive && _enemyManager.checkAttackEnemyCollision(attack, enemy)) {
          enemy.takeDamage(attack.damage);
          attack.isActive = false;

          if (enemy.isDead) {
            _defeatEnemy(enemy, enemiesToRemove);
          } else {
            _createEnemyHitParticles(enemy.x, enemy.y);
          }
          break;
        }
      }

      if (enemy.isOffScreen()) {
        enemiesToRemove.add(enemy);
      }
    }

    _removeEnemies(enemiesToRemove);
    _enemyManager.cleanupEnemies(_enemies);
  }

  void _updateFlyingEnemyMovement(Obstacle enemy) {
    if (enemy.type == ObstacleType.flyingEnemy) {
      final wave = sin(_gameTime * 3 + enemy.x * 6) * 0.015;
      enemy.y = (enemy.y + wave).clamp(0.25, 0.6);
    }
  }

  void _spawnEnemy() {
    if (!_isGameRunning || _levelCompleted || _character == null) return;

    if (_random.nextDouble() < 0.9) {
      final bool spawnFlyingEnemy = _random.nextDouble() < 0.4;

      Obstacle enemy;
      if (spawnFlyingEnemy) {
        enemy = _enemyManager.createFlyingEnemy(
            _isSlowMotion ? levelData.obstacleSpeed * 0.5 : levelData.obstacleSpeed,
            _level
        );
        enemy.y = 0.25 + _random.nextDouble() * 0.4;
      } else {
        enemy = _enemyManager.createRandomEnemy(
            _isSlowMotion ? levelData.obstacleSpeed * 0.5 : levelData.obstacleSpeed,
            _level
        );
      }

      _enemies.add(enemy);
    }
  }

  bool _isCharacterJumpingOnEnemy(Character character, Obstacle enemy) {
    if (!enemy.isEnemy) return false;

    final characterBottom = character.y;
    final enemyTop = enemy.y - enemy.height / 2;
    final headRegionBottom = enemyTop + enemy.height * 0.15;

    final headHorizontalReduction = 0.3;
    final enemyHeadLeft = enemy.x - enemy.width / 2 + (enemy.width * headHorizontalReduction / 2);
    final enemyHeadRight = enemy.x + enemy.width / 2 - (enemy.width * headHorizontalReduction / 2);

    final characterLeft = character.x - character.width / 2;
    final characterRight = character.x + character.width / 2;

    final horizontalOverlap = characterRight > enemyHeadLeft && characterLeft < enemyHeadRight;
    final bool isAboveEnemy = characterBottom <= headRegionBottom;
    final bool isFalling = character.velocityY > 0;
    final bool isInHeadRegion = characterBottom >= enemyTop && characterBottom <= headRegionBottom;
    final bool isNotTooHigh = (enemyTop - characterBottom).abs() < 0.03;

    return horizontalOverlap && isAboveEnemy && isFalling && isInHeadRegion && isNotTooHigh;
  }

  void _defeatEnemy(Obstacle enemy, List<Obstacle> enemiesToRemove) {
    enemiesToRemove.add(enemy);
    _enemiesDefeated++;

    final basePoints = _enemyManager.getEnemyPoints(enemy);
    final points = _calculateBalancedPoints(basePoints);
    _addScore(points);

    _createEnemyDefeatParticles(enemy.x, enemy.y);
    AudioService().playEnemyDieSound();
    VibrationService.vibrateSuccess();
  }

  void _handleEnemyCollision(Obstacle enemy) {
    if (_checkSideCollision(_character!, enemy)) {
      _character?.takeDamage(20);
      _createHitParticles(_character!.x, _character!.y);
      onCharacterDamage?.call();

      AudioService().playGameOverSound();
      VibrationService.vibrateGameOver();

      if (_character!.isDead) {
        _gameOver();
      }
    }
  }

  // === نظام الباور أب ===
  void _updatePowerUps() {
    final powerUpsToRemove = <PowerUp>[];

    for (var powerUp in _powerUps) {
      powerUp.move();

      if (_character != null && _checkCollision(_character!, powerUp)) {
        _collectPowerUp(powerUp);
        powerUpsToRemove.add(powerUp);
      } else if (powerUp.isOffScreen()) {
        powerUpsToRemove.add(powerUp);
      }
    }

    _removePowerUps(powerUpsToRemove);
  }

  void _spawnPowerUp() {
    if (!_isGameRunning || _levelCompleted || _character == null) return;

    if (_random.nextDouble() < 0.2) {
      _spawnAdvancedPowerUp();
    }
  }

  bool _canSpawnPowerUp(PowerUpType type) {
    final maxSpawns = PowerUpSystem.getMaxSpawnsForLevel(type, _level);
    final currentSpawns = _powerUpSpawnsThisLevel[type] ?? 0;
    return currentSpawns < maxSpawns;
  }

  void _spawnAdvancedPowerUp() {
    final availablePowerUps = PowerUpType.values.where((type) => _canSpawnPowerUp(type)).toList();

    // ✅ التعديل: إزالة العملة من الباور أب المتاحة أو تقليل فرصها
    final filteredPowerUps = availablePowerUps.where((type) => type != PowerUpType.coin).toList();

    if (filteredPowerUps.isEmpty) {
      return;
    }

    final selectedType = filteredPowerUps[_random.nextInt(filteredPowerUps.length)];
    final spawnChance = PowerUpSystem.getSpawnDifficulty(selectedType, _level);

    // ✅ التعديل: تقليل فرص الظهور بشكل عام
    if (_random.nextDouble() < spawnChance * 0.5) { // تقليل إلى النصف
      _spawnPowerUpAtPosition(1.1, 0.3 + _random.nextDouble() * 0.4, selectedType);
    }
  }

  void _spawnPowerUpAtPosition(double x, double y, [PowerUpType? specificType]) {
    final type = specificType ?? [
      PowerUpType.health,
      PowerUpType.shield,
      PowerUpType.points,
      PowerUpType.doublePoints
    ][_random.nextInt(4)];

    final powerUp = PowerUp(
      x: x,
      y: y,
      type: type,
      width: 0.08,
      height: 0.08,
      speed: 0.01,
      color: _getPowerUpColor(type),
      imagePath: _getPowerUpImagePath(type),
    );

    _powerUps.add(powerUp);
    _powerUpSpawnsThisLevel[type] = (_powerUpSpawnsThisLevel[type] ?? 0) + 1;
    PowerUpSystem.recordPowerUpSpawn(type);
  }

// === تحديث دالة جمع الباور أب ===
  void _collectPowerUp(PowerUp powerUp) {
    _powerUpsCollected++;
    PowerUpSystem.recordPowerUpCollection(powerUp.type);

    _activatePowerUpEffect(powerUp.type);
    _createPowerUpParticles(powerUp.x, powerUp.y, _getPowerUpColor(powerUp.type));
    AudioService().playCoinSound();
    VibrationService.vibrateSuccess();
  }

  void _handlePowerUpEffect(PowerUp powerUp) {
    switch (powerUp.type) {
      case PowerUpType.speedBoost:
        _activateSpeedBoost();
        break;
      case PowerUpType.slowEnemies:
        _activateSlowEnemies();
        break;
      case PowerUpType.coin:
        _collectCoin();
        break;
      case PowerUpType.shield:
        _activateShield();
        break;
      case PowerUpType.health:
        _activateHealthBoost();
        break;
      case PowerUpType.slowCharacter:
        _activateSlowCharacter();
        break;
      case PowerUpType.points:
        _addScore(PowerUpSystem.getPowerUpPoints(PowerUpType.points));
        break;
      case PowerUpType.slowMotion:
        _activateSlowMotion();
        break;
      case PowerUpType.doublePoints:
        _activateDoublePoints();
        break;
    }
  }


  void _activateSlowCharacter() {
    _character?.activateSlowCharacter();
    Timer(PowerUpSystem.getPowerUpDuration(PowerUpType.slowCharacter), () {
      _character?.deactivateSlowCharacter();
    });
  }

  void _activateHealthBoost() {
    final healAmount = PowerUpSystem.getHealAmount(_character!.maxHealth);
    _character!.heal(healAmount);
    _createHealingParticles(_character!.x, _character!.y);
  }

// === دوال تفعيل الباور أب ===
  void _activateSpeedBoost() {
    _isSpeedBoostActive = true;
    _character?.activateSpeedBoost();
    _speedBoostTimer?.cancel();
    _speedBoostTimer = Timer(PowerUpSystem.getPowerUpDuration(PowerUpType.speedBoost), () {
      _isSpeedBoostActive = false;
      _character?.deactivateSpeedBoost();
    });
    _createSpeedBoostParticles(_character!.x, _character!.y);
  }

  void _activateSlowEnemies() {
    _areEnemiesSlowed = true;
    _slowEnemiesTimer?.cancel();
    _slowEnemiesTimer = Timer(PowerUpSystem.getPowerUpDuration(PowerUpType.slowEnemies), () {
      _areEnemiesSlowed = false;
    });
    for (var enemy in _enemies) {
      _createSlowEffectParticles(enemy.x, enemy.y);
    }
  }

  void _collectCoin() {
    _coinsEarnedThisLevel++;
    // ✅ التأكد من تمرير القيمة الصحيحة
    GameDataService.addCharacterCoins(1).then((_) {
      // print('💰 تم إضافة 1 عملة إلى قاعدة البيانات');
    }).catchError((error) {
      print('❌ خطأ في إضافة العملة: $error');
    });

    _addScore(_calculateBalancedPoints(1));
  }

  void _handleBasicPowerUp(PowerUp powerUp) {
    switch (powerUp.type) {
      case PowerUpType.points:
        final baseScore = _isDoublePoints ? 30 : 15;
        _addScore(_calculateBalancedPoints(baseScore));
        break;
      case PowerUpType.coin:
        _collectCoin();
        break;
      case PowerUpType.shield:
        _activateShield();
        break;
      case PowerUpType.slowMotion:
        _activateSlowMotion();
        break;
      case PowerUpType.doublePoints:
        _activateDoublePoints();
        break;
      case PowerUpType.health:
        _activateHealthBoost();
        break;
      default:
        break;
    }
  }

  void _activateShield() {
    _hasShield = true;
    _character?.activateShield(PowerUpSystem.getPowerUpDuration(PowerUpType.shield));
    _shieldTimer?.cancel();
    _shieldTimer = Timer(PowerUpSystem.getPowerUpDuration(PowerUpType.shield), () {
      _hasShield = false;
      _character?.deactivateShield();
    });
  }

  void _activateSlowMotion() {
    _isSlowMotion = true;
    _slowMotionTimer?.cancel();
    _slowMotionTimer = Timer(PowerUpSystem.getPowerUpDuration(PowerUpType.slowMotion), () {
      _isSlowMotion = false;
    });
  }

  void _activateDoublePoints() {
    _isDoublePoints = true;
    _doublePointsTimer?.cancel();
    _doublePointsTimer = Timer(PowerUpSystem.getPowerUpDuration(PowerUpType.doublePoints), () {
      _isDoublePoints = false;
    });
  }

  // === نظام تفعيل الباور أب ===
  void _activatePowerUpEffect(PowerUpType type) {
    switch (type) {
      case PowerUpType.speedBoost:
        _activateSpeedBoost();
        break;
      case PowerUpType.slowEnemies:
        _activateSlowEnemies();
        break;
      case PowerUpType.coin:
        _collectCoin();
        break;
      case PowerUpType.shield:
        _activateShield();
        break;
      case PowerUpType.health:
        _activateHealthBoost();
        break;
      case PowerUpType.slowCharacter:
        _activateSlowCharacter();
        break;
      case PowerUpType.points:
        _addScore(PowerUpSystem.getPowerUpPoints(PowerUpType.points));
        break;
      case PowerUpType.slowMotion:
        _activateSlowMotion();
        break;
      case PowerUpType.doublePoints:
        _activateDoublePoints();
        break;
    }
  }

  String _getPowerUpName(PowerUpType type, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PowerUpSystem.getPowerUp(type).getName(l10n);
  }

// === دوال مساعدة للباور أب ===
  Color _getPowerUpColor(PowerUpType type) {
    return PowerUpSystem.getPowerUp(type).color;
  }

  String _getPowerUpImagePath(PowerUpType type) {
    return PowerUpSystem.getPowerUp(type).imagePath;
  }

  // === نظام الزعيم ===
  void _updateBossAppearance() {
    if (_shouldBossAppear) {
      _startBossFight();
    }
  }

  void _startBossFight() {
    if (_isBossFight || _bossSpawned) {
      return;
    }

    print('👹 بدء معركة الزعيم عند النقاط $_score');

    _isBossFight = true;
    _bossSpawned = true;
    _bossFightStartTime = _gameTime;
    _preBossScore = _score;

    _currentBoss = _createBossForLevel(levelData.levelNumber);
    _currentBoss!.setTarget(_character!);

    _stopAllSpawners();

    Timer(const Duration(milliseconds: 1500), () {
      _startBossSpawners();
    });

    _startBossHintTimer();

    AudioService().stopBackgroundMusic();
    AudioService().playBossMusic();

    onBossAppear?.call();
  }

  void _startBossSpawners() {
    if (!_isBossFight) return;

    _obstacleSpawnTimer = Timer.periodic(
      const Duration(milliseconds: 1200),
          (timer) {
        if (_isBossFight && _isGameRunning) {
          _spawnObstacleDuringBoss();
        }
      },
    );

    _enemySpawnTimer = Timer.periodic(
      const Duration(milliseconds: 2000),
          (timer) {
        if (_isBossFight && _isGameRunning) {
          _spawnEnemyDuringBoss();
        }
      },
    );

    _powerUpSpawnTimer = Timer.periodic(
      const Duration(seconds: 4),
          (timer) {
        if (_isBossFight && _isGameRunning) {
          _spawnPowerUpDuringBoss();
        }
      },
    );
  }

  void _spawnObstacleDuringBoss() {
    if (!_isGameRunning || _character == null) return;

    final speed = levelData.obstacleSpeed * 1.3;

    if (_random.nextDouble() < 0.8) {
      final obstacle = _createRandomObstacle(speed);
      _obstacles.add(obstacle);
    }

    if (_random.nextDouble() < 0.4) {
      final additionalObstacle = _createRandomObstacle(speed);
      _obstacles.add(additionalObstacle);
    }
  }

  void _spawnEnemyDuringBoss() {
    if (!_isGameRunning || _character == null) return;

    if (_random.nextDouble() < 0.7) {
      final bool spawnFlyingEnemy = _random.nextDouble() < 0.6;

      Obstacle enemy;
      if (spawnFlyingEnemy) {
        enemy = _enemyManager.createFlyingEnemy(
            levelData.obstacleSpeed * 1.2,
            _level
        );

        final heightType = _random.nextDouble();
        if (heightType < 0.33) {
          enemy.y = 0.25 + _random.nextDouble() * 0.15;
        } else if (heightType < 0.66) {
          enemy.y = 0.45 + _random.nextDouble() * 0.15;
        } else {
          enemy.y = 0.65 + _random.nextDouble() * 0.1;
        }
      } else {
        enemy = _enemyManager.createRandomEnemy(
            levelData.obstacleSpeed * 1.2,
            _level
        );
      }

      _enemies.add(enemy);
    }
  }

  void _spawnPowerUpDuringBoss() {
    if (!_isGameRunning || _character == null) return;

    if (_random.nextDouble() < 0.5) {
      final availableTypes = [
        PowerUpType.health,
        PowerUpType.shield,
        PowerUpType.speedBoost,
        PowerUpType.doublePoints
      ];

      final selectedType = availableTypes[_random.nextInt(availableTypes.length)];
      _spawnPowerUpAtPosition(1.1, 0.3 + _random.nextDouble() * 0.4, selectedType);
    }
  }

  Boss _createBossForLevel(int level) {
    final isRare = _isRareBossLevel(level);
    final isFinal = level == 100;

    String imagePath;
    int baseHealth = 100 + (level * 20);
    double attackSpeed = 1.5 - (level * 0.01);
    if (attackSpeed < 0.3) attackSpeed = 0.3;

    if (isFinal) {
      imagePath = ImageService.finalBoss;
      baseHealth = 5000;
      attackSpeed = 0.5;
    } else if (isRare) {
      imagePath = _getBossImagePath(level, true);
      baseHealth = (baseHealth * 1.5).toInt();
    } else {
      imagePath = _getBossImagePath(level, false);
    }

    return Boss(
      x: 0.8,
      y: 0.3,
      width: 0.12,
      height: 0.12,
      health: baseHealth,
      maxHealth: baseHealth,
      attackSpeed: attackSpeed,
      moveSpeed: 0.015,
      imagePath: imagePath,
      level: level,
      isRare: isRare,
      isFinalBoss: isFinal,
    );
  }

  String _getBossImagePath(int level, bool isRare) {
    final bossIndex = (level ~/ 10) % 5;
    if (isRare) {
      switch (bossIndex) {
        case 0: return ImageService.rareBoss1;
        case 1: return ImageService.rareBoss2;
        case 2: return ImageService.rareBoss3;
        case 3: return ImageService.rareBoss4;
        case 4: return ImageService.rareBoss5;
        default: return ImageService.rareBoss1;
      }
    } else {
      switch (bossIndex) {
        case 0: return ImageService.boss1;
        case 1: return ImageService.boss2;
        case 2: return ImageService.boss3;
        case 3: return ImageService.boss4;
        case 4: return ImageService.boss5;
        default: return ImageService.boss1;
      }
    }
  }

  bool _isRareBossLevel(int level) {
    return level == 15 || level == 25 || level == 50 || level == 75 ||
        level == 90 || level == 91 || level == 92 || level == 93 ||
        level == 94 || level == 95 || level == 96 || level == 97 ||
        level == 98 || level == 99;
  }

  void _updateBoss() {
    if (_currentBoss == null || !_isBossFight || _character == null) {
      return;
    }

    if (_currentBoss!.isDead) {
      _defeatBoss();
      return;
    }

    _currentBoss!.move();
    _currentBoss!.attack(_gameTime);
    _currentBoss!.updateProjectiles();

    _updateEnemies();
    _updateObstacles();
    _updatePowerUps();
    _updatePlatforms();
    _checkBrickJumping();

    bool bossWasHit = false;
    for (var attack in _character!.attacks) {
      if (attack.isActive && attack.collidesWithBoss(_currentBoss!)) {
        _currentBoss!.takeDamage(attack.damage);

        final effects = attack.applyEffects();
        _applyBossEffects(effects);

        attack.isActive = false;
        _createBossHitParticles(_currentBoss!.x, _currentBoss!.y);
        AudioService().playBossHitSound();
        onBossHit?.call();
        bossWasHit = true;

        if (_currentBoss!.isDead) {
          _defeatBoss();
          return;
        }
      }
    }

    for (var projectile in _currentBoss!.projectiles) {
      if (_character!.collidesWithAttack(projectile)) {
        _character!.takeDamage(projectile.damage);
        projectile.isActive = false;
        _createHitParticles(_character!.x, _character!.y);
        onCharacterDamage?.call();

        if (_character!.isDead) {
          _gameOver();
          return;
        }
      }
    }

    if (_checkCollision(_character!, _currentBoss!)) {
      _character!.takeDamage(25);
      _createHitParticles(_character!.x, _character!.y);
      onCharacterDamage?.call();

      if (_character!.isDead) {
        _gameOver();
        return;
      }
    }
  }

  void _applyBossEffects(Map<String, dynamic> effects) {
    if (effects.containsKey('slow')) {
      _currentBoss!.applySlowEffect(effects['slow'], effects['duration']);
    }
    if (effects.containsKey('freeze')) {
      _currentBoss!.applyFreezeEffect(effects['duration']);
    }
    if (effects.containsKey('burn')) {
      _currentBoss!.applyBurnEffect(effects['burn'], effects['duration']);
    }
  }

  void _defeatBoss() {
    if (_isBossDefeated) return;

    // print('🎉 هزيمة الزعيم!');
    _isBossDefeated = true;
    _isBossFight = false;
    _bossSpawned = false;

    final bossScore = (levelData.targetScore * 0.4).toInt();
    _score = _preBossScore + bossScore;

    final bossCoins = 2;
    _coinsEarnedThisLevel += bossCoins;

    // ✅ حفظ عملات الزعيم فوراً
    GameDataService.addCharacterCoins(bossCoins).then((_) {
      // print('💰 تم حفظ عملات الزعيم في قاعدة البيانات');
    });

    _createVictoryParticles();
    AudioService().playBossDefeatSound();

    _stopAllSpawners();
    _obstacles.clear();
    _enemies.clear();
    _powerUps.clear();

    if (_currentBoss != null) {
      _currentBoss!.projectiles.clear();
    }

    if (_score >= levelData.targetScore && !_levelCompleted) {
      Timer(const Duration(milliseconds: 1500), () {
        if (!_levelCompleted && !_isLevelCompleteCalled) {
          _completeLevel();
        }
      });
    }

    onBossDefeated?.call();
  }

  // === نظام التصادم ===
  bool _checkCollision(Character character, dynamic object) {
    if (character.hasShield || character.isInvincible) {
      return false;
    }

    final charRect = _getPreciseCharacterBoundingBox(character);
    final objRect = _getPreciseObjectBoundingBox(object);

    return charRect.overlaps(objRect);
  }

  bool _checkSideCollision(Character character, dynamic object) {
    final charRect = _getPreciseCharacterBoundingBox(character);
    final objRect = _getPreciseObjectBoundingBox(object);

    if (!charRect.overlaps(objRect)) return false;

    final characterBottom = character.y;
    final objectTop = object.y - object.height / 2;
    return characterBottom > objectTop + (object.height * 0.3);
  }

  Rect _getPreciseCharacterBoundingBox(Character character) {
    final horizontalReduction = 0.15;
    final verticalReduction = 0.3;

    final reducedWidth = character.width * (1 - horizontalReduction);
    final reducedHeight = character.height * (1 - verticalReduction);
    final centerY = character.y - character.height / 2 + (character.height * verticalReduction / 3);

    return Rect.fromCenter(
      center: Offset(character.x, centerY),
      width: reducedWidth,
      height: reducedHeight,
    );
  }

  Rect _getPreciseObjectBoundingBox(dynamic object) {
    if (object is Obstacle) {
      final horizontalReduction = 0.2;
      final verticalReduction = 0.4;

      final reducedWidth = object.width * (1 - horizontalReduction);
      final reducedHeight = object.height * (1 - verticalReduction);
      final centerY = object.y - (object.height * verticalReduction / 4);

      return Rect.fromCenter(
        center: Offset(object.x, centerY),
        width: reducedWidth,
        height: reducedHeight,
      );
    }
    else if (object is PowerUp) {
      final reduction = 0.4;
      final reducedWidth = object.width * (1 - reduction);
      final reducedHeight = object.height * (1 - reduction);

      return Rect.fromCenter(
        center: Offset(object.x, object.y),
        width: reducedWidth,
        height: reducedHeight,
      );
    }
    else if (object is Boss) {
      final reduction = 0.5;
      final reducedWidth = object.width * (1 - reduction);
      final reducedHeight = object.height * (1 - reduction);

      return Rect.fromCenter(
        center: Offset(object.x, object.y),
        width: reducedWidth,
        height: reducedHeight,
      );
    }

    return object.boundingBox;
  }

  void _handleObstacleCollision(Obstacle obstacle, List<Obstacle> obstaclesToRemove) {
    if (_checkSideCollision(_character!, obstacle)) {
      if (_hasShield) {
        _hasShield = false;
        _shieldTimer?.cancel();
        obstaclesToRemove.add(obstacle);
        _createShieldParticles(_character!.x, _character!.y);
        AudioService().playCoinSound();
        VibrationService.vibrateSuccess();
      } else {
        _character?.takeDamage(15);
        _createHitParticles(_character!.x, _character!.y);
        onCharacterDamage?.call();

        if (_character!.isDead) {
          _gameOver();
        }
      }
    }
  }

  // === نظام الجسيمات ===
  void _updateParticles() {
    _particles.removeWhere((particle) => particle.isDead);
    for (final particle in _particles) {
      particle.update();
    }
  }

  void _createJumpParticles(double x, double y) {
    final newParticles = GameParticle.createJumpParticles(x, y, 3, _random);
    _particles.addAll(newParticles);
  }

  void _createPowerUpParticles(double x, double y, Color color) {
    final newParticles = GameParticle.createPowerUpParticles(x, y, color, 5, _random);
    _particles.addAll(newParticles);
  }

  void _createShieldParticles(double x, double y) {
    final newParticles = GameParticle.createShieldParticles(x, y, 8, _random);
    _particles.addAll(newParticles);
  }

  void _createHitParticles(double x, double y) {
    final newParticles = GameParticle.createHitParticles(x, y, 8, _random);
    _particles.addAll(newParticles);
  }

  void _createEnemyHitParticles(double x, double y) {
    final newParticles = GameParticle.createEnemyHitParticles(x, y, 8, _random);
    _particles.addAll(newParticles);
    AudioService().playEnemyHitSound();
  }

  void _createEnemyDefeatParticles(double x, double y) {
    final newParticles = GameParticle.createEnemyDefeatParticles(x, y, 12, _random);
    _particles.addAll(newParticles);
  }

  void _createBossHitParticles(double x, double y) {
    final newParticles = GameParticle.createBossHitParticles(x, y, 15, _random);
    _particles.addAll(newParticles);
  }

  void _createVictoryParticles() {
    final newParticles = GameParticle.createVictoryParticles(0.5, 0.5, 20, _random);
    _particles.addAll(newParticles);
  }

  void _createHealingParticles(double x, double y) {
    final newParticles = GameParticle.createHealingParticles(x, y, 12, _random);
    _particles.addAll(newParticles);
  }

  void _createSpeedBoostParticles(double x, double y) {
    final newParticles = GameParticle.createSpeedBoostParticles(x, y, 15, _random);
    _particles.addAll(newParticles);
  }

  void _createSlowEffectParticles(double x, double y) {
    final newParticles = GameParticle.createSlowEffectParticles(x, y, 8, _random);
    _particles.addAll(newParticles);
  }

  void _createPlatformBreakParticles(double x, double y) {
    final newParticles = GameParticle.createPlatformBreakParticles(x, y, 12, _random);
    _particles.addAll(newParticles);
  }

  void _createBrickBreakParticles(double x, double y) {
    final newParticles = GameParticle.createBrickBreakParticles(x, y, 15, _random);
    _particles.addAll(newParticles);
  }

  // === نظام المولدات ===
  void _startSpawners() {
    _obstacleSpawnTimer = Timer.periodic(
      const Duration(milliseconds: 800),
          (timer) {
        _spawnObstacle();
      },
    );

    _enemySpawnTimer = Timer.periodic(
      const Duration(milliseconds: 2500),
          (timer) {
        _spawnEnemy();
      },
    );

    _powerUpSpawnTimer = Timer.periodic(
      const Duration(seconds: 3),
          (timer) {
        _spawnPowerUp();
      },
    );

    _platformSpawnTimer = Timer.periodic(
      const Duration(seconds: 20),
          (timer) {
        _spawnPlatform();
      },
    );
  }

  void _stopAllSpawners() {
    _obstacleSpawnTimer?.cancel();
    _enemySpawnTimer?.cancel();
    _powerUpSpawnTimer?.cancel();
    _platformSpawnTimer?.cancel();
  }

  // === نظام التحكم ===
  void jumpCharacter() {
    if (_character == null || !_isGameRunning) return;

    _character!.jump();
    _createJumpParticles(_character!.x, _character!.y + 0.05);
    AudioService().playJumpSound();
    VibrationService.vibrateSuccess();
  }

  void duckCharacter() => _character?.duck();

  void stopDuckingCharacter() => _character?.stopDucking();

  void attackCharacter() {
    if (!isGameRunning || character.isDead) return;
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    character.attack(currentTime);
    _showCombatHintTemporary();
    AudioService().playPackageThrowSound();
  }

  void moveCharacterLeft() => _character?.moveLeft();

  void moveCharacterRight() => _character?.moveRight();

  void moveCharacterUp() => _character?.moveUp();

  void moveCharacterDown() => _character?.moveDown();

  void stopCharacterMoving() => _character?.stopMoving();

  void handleCharacterDrag(double deltaX, double deltaY) {
    if (_character == null || !_isGameRunning) return;

    double dragSensitivity = 0.0005;

    if (deltaX.abs() > 2) {
      double horizontalForce = deltaX * dragSensitivity;
      _character!.x += horizontalForce;
      _character!.x = _character!.x.clamp(0.05, 0.95);
    }

    if (deltaY.abs() > 2 && !_character!.isOnPlatform) {
      double verticalForce = deltaY * dragSensitivity;
      _character!.y += verticalForce;
      _character!.y = _character!.y.clamp(0.1, 0.85);
    }

    _handleSimpleJump(deltaY);
  }

  void _handleSimpleJump(double deltaY) {
    if (_character == null || !_isGameRunning) return;

    bool canJump = !_character!.isJumping && !_character!.isDucking;

    if (deltaY < -25 && canJump) {
      _character!.jump();
      _createJumpParticles(_character!.x, _character!.y + 0.05);
      AudioService().playJumpSound();
      VibrationService.vibrateSuccess();
    }
  }

  // === إدارة اللعبة ===
  void pauseGame() {
    if (!_isGameRunning) return;
    _isGameRunning = false;
    _stopAllTimers();
    AudioService().pauseAllSounds();
  }

  void resumeGame() {
    if (_isGameRunning || _levelCompleted) return;
    _isGameRunning = true;
    _startGameLoop();
    _startSpawners();
    AudioService().resumeAllSounds();
  }

  // === نظام الحفظ عند الإغلاق ===
  void saveGameBeforeExit() {
    print('💾 حفظ اللعبة قبل الإغلاق...');

    // حفظ النقاط والتقدم
    GameDataService.saveGameProgress(_score, levelData.levelNumber);

    // حفظ العملات المكتسبة خلال الجلسة
    if (_coinsEarnedThisLevel > 0) {
      print('💰 حفظ العملات المكتسبة: $_coinsEarnedThisLevel');
    }

    // إيقاف جميع المؤثرات الصوتية
    AudioService().stopAllSounds();
  }

  void _completeLevel() {
    if (_levelCompleted || _isLevelCompleteCalled) return;
    _isLevelCompleteCalled = true;

    if (!_isBossDefeated || _score < levelData.targetScore) {
      // print('⚠️ لا يمكن اكتمال المستوى: الزعيم لم يهزم أو النقاط غير كافية');
      _isLevelCompleteCalled = false;
      return;
    }

    // print('🏁 اكتمال المستوى - النقاط: $_score - الزعيم هُزم: $_isBossDefeated');
    _levelCompleted = true;
    _isGameRunning = false;
    _stopAllTimers();

    final levelCompletionCoins = 3;
    _coinsEarnedThisLevel += levelCompletionCoins;

    // ✅ حفظ عملات اكتمال المستوى فوراً
    GameDataService.addCharacterCoins(levelCompletionCoins).then((_) {
      print('💰 تم حفظ عملات اكتمال المستوى في قاعدة البيانات');
    });

    _createVictoryParticles();
    AudioService().playLevelCompleteSound();
    AudioService().stopBackgroundMusic();
    VibrationService.vibrateAchievement();

    GameDataService.saveGameProgress(_score, levelData.levelNumber);
    if (levelData.levelNumber < 100) {
      GameDataService.unlockLevel(levelData.levelNumber + 1);
    }

    onLevelComplete?.call();
  }

  void _gameOver() {
    // ✅ التأكد من عدم استدعاء الدالة مرارًا وتكرارًا
    if (_isGameOverCalled || _levelCompleted) return;
    _isGameOverCalled = true;

    print('🎮 استدعاء _gameOver - إيقاف المحرك');

    // ✅ إيقاف المحرك أولاً
    _isGameRunning = false;
    _stopAllTimers();
    _stopAllSpawners();

    saveGameBeforeExit();
    AudioService().playGameOverSound();
    AudioService().stopBackgroundMusic();
    VibrationService.vibrateGameOver();

    _saveGameProgress();

    // ✅ تأخير استدعاء onGameOver لضمان إيقاف一切
    Timer(const Duration(milliseconds: 100), () {
      print('🎮 استدعاء onGameOver');
      onGameOver?.call();
    });
  }

  void _saveGameProgress() async {
    await GameDataService.saveGameProgress(_score, levelData.levelNumber);
  }

  void _resetGameState() {
    _score = 0;
    _level = 1;
    _gameTime = 0.0;
    _obstacles.clear();
    _enemies.clear();
    _powerUps.clear();
    _platforms.clear();
    _particles.clear();
    _backgroundManager.initialize();

    _character = Character(x: 0.2, y: 0.7);
    _loadSelectedCharacter();

    _levelCompleted = false;
    _showTutorialArrows = true;
    _showGroundText = true;
    _showBossAttackHint = false;
    _showTutorialInstructions = true;
    _isBossFight = false;
    _isBossDefeated = false;
    _currentBoss = null;
    _bossSpawned = false;
    _preBossScore = 0;
    _isBossSpawnTriggered = false;
    _coinsCollected = 0;
    _obstaclesAvoided = 0;
    _powerUpsCollected = 0;
    _enemiesDefeated = 0;
    _hasShield = false;
    _isSlowMotion = false;
    _isDoublePoints = false;
    _isSpeedBoostActive = false;
    _areEnemiesSlowed = false;
    _coinsEarnedThisLevel = 0;
    _startTutorialInstructionsTimer();
    _isGameOverCalled = false;
    _isLevelCompleteCalled = false;

    _initializePowerUpSystem();
    _stopAllTimers();
    _initializePlatforms();
    _startTutorialTimer();
    _startGroundTextTimer();
  }

  void _stopAllTimers() {
    final timers = [
      _gameTimer, _obstacleSpawnTimer, _enemySpawnTimer, _powerUpSpawnTimer,
      _platformSpawnTimer, _shieldTimer, _slowMotionTimer, _doublePointsTimer,
      _comboTimer, _levelTimer, _tutorialTimer, _groundTextTimer,
      _bossHintTimer, _combatHintTimer, _speedBoostTimer, _slowEnemiesTimer,
      _tutorialInstructionsTimer
    ];

    for (var timer in timers) {
      timer?.cancel();
      timer = null;
    }
  }

  void attackCharacterAtPosition(double tapX, double tapY) {
    if (!isGameRunning || character.isDead) return;

    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;

    // ✅ تمرير إحداثيات النقر للشخصية
    character.attackAtPosition(currentTime, tapX, tapY);

    _showCombatHintTemporary();
    AudioService().playPackageThrowSound();
  }

  void attackCharacterWithDirection(double directionX, double directionY) {
    if (!isGameRunning || character.isDead) return;

    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;

    // ✅ تمرير اتجاه الهجوم للشخصية
    character.attackWithDirection(currentTime, directionX, directionY);

    _showCombatHintTemporary();
    AudioService().playPackageThrowSound();
  }

  // === المساعدات ===
  void _removeObstacles(List<Obstacle> obstaclesToRemove) {
    for (var obstacle in obstaclesToRemove) {
      _obstacles.remove(obstacle);
    }
  }

  void _removeEnemies(List<Obstacle> enemiesToRemove) {
    for (var enemy in enemiesToRemove) {
      _enemies.remove(enemy);
    }
  }

  void _removePowerUps(List<PowerUp> powerUpsToRemove) {
    for (var powerUp in powerUpsToRemove) {
      _powerUps.remove(powerUp);
    }
  }

  void _removePlatforms(List<Obstacle> platformsToRemove) {
    for (var platform in platformsToRemove) {
      _platforms.remove(platform);
    }
  }

  void _checkLevelUp() {
    final newLevel = (_score ~/ 200) + 1;
    if (newLevel > _level) {
      _level = newLevel;
      _adjustSpawners();
    }
  }

  void _adjustSpawners() {
    _obstacleSpawnTimer?.cancel();
    final spawnInterval = (1800 - (_level * 20)).clamp(400, 1800);

    _obstacleSpawnTimer = Timer.periodic(
      Duration(milliseconds: spawnInterval),
          (timer) => _spawnObstacle(),
    );
  }

  void _updateChallenges() {
    if (_character == null) return;

    int attacksUsed = _character!.attacks.where((attack) => !attack.isActive).length;
    if (attacksUsed > 0) {
      ChallengeService.updateChallengeProgress('5', attacksUsed);
    }

    if (_character!.jumpCount > 0) {
      ChallengeService.updateChallengeProgress('1', _character!.jumpCount);
      _character!.resetJumpCount();
    }

    if (_coinsCollected > 0) {
      ChallengeService.updateChallengeProgress('2', _coinsCollected);
      _coinsCollected = 0;
    }

    if (_obstaclesAvoided > 0) {
      ChallengeService.updateChallengeProgress('3', _obstaclesAvoided);
      _obstaclesAvoided = 0;
    }

    if (_enemiesDefeated > 0) {
      ChallengeService.updateChallengeProgress('4', _enemiesDefeated);
      _enemiesDefeated = 0;
    }
  }

  // === دالة جديدة لتعيين الزوج المناسب ===
  void _setBackgroundGroundPairForLevel() {
    // قائمة الأزواج المتناسقة
    List<Map<String, String>> backgroundGroundPairs = [
      {
        'background': 'assets/images/backgrounds/city.png',
        'ground': 'assets/images/ground/city_ground.png',
      },
      {
        'background': 'assets/images/backgrounds/forest.png',
        'ground': 'assets/images/ground/forest_ground.png',
      },
      {
        'background': 'assets/images/backgrounds/desert.png',
        'ground': 'assets/images/ground/desert_ground.png',
      },
      {
        'background': 'assets/images/backgrounds/night.png',
        'ground': 'assets/images/ground/night_ground.png',
      },
      {
        'background': 'assets/images/backgrounds/storm.png',
        'ground': 'assets/images/ground/storm_ground.png',
      },
      {
        'background': 'assets/images/backgrounds/snow.png',
        'ground': 'assets/images/ground/snow_ground.png',
      },
      {
        'background': 'assets/images/backgrounds/jungle.png',
        'ground': 'assets/images/ground/jungle_ground.png',
      },
      {
        'background': 'assets/images/backgrounds/ocean.png',
        'ground': 'assets/images/ground/ocean_ground.png',
      },
      {
        'background': 'assets/images/backgrounds/space.png',
        'ground': 'assets/images/ground/space_ground.png',
      },
      {
        'background': 'assets/images/backgrounds/mountain.png',
        'ground': 'assets/images/ground/mountain_ground.png',
      },
      {
        'background': 'assets/images/backgrounds/castle.png',
        'ground': 'assets/images/ground/castle_ground.png',
      },
      {
        'background': 'assets/images/backgrounds/volcano.png',
        'ground': 'assets/images/ground/volcano_ground.png',
      },
      {
        'background': 'assets/images/backgrounds/lab.png',
        'ground': 'assets/images/ground/lab_ground.png',
      },
      {
        'background': 'assets/images/backgrounds/future.png',
        'ground': 'assets/images/ground/future_ground.png',
      },
      {
        'background': 'assets/images/backgrounds/park.png',
        'ground': 'assets/images/ground/park_ground.png',
      },
      {
        'background': 'assets/images/backgrounds/temple.png',
        'ground': 'assets/images/ground/temple_ground.png',
      },
      {
        'background': 'assets/images/backgrounds/arctic.png',
        'ground': 'assets/images/ground/arctic_ground.png',
      },
      {
        'background': 'assets/images/backgrounds/mystery.png',
        'ground': 'assets/images/ground/mystery_ground.png',
      },
      {
        'background': 'assets/images/backgrounds/cave.png',
        'ground': 'assets/images/ground/cave_ground.png',
      },
      {
        'background': 'assets/images/backgrounds/egypt.png',
        'ground': 'assets/images/ground/egypt_ground.png',
      },
    ];

    // اختيار الزوج بناءً على رقم المستوى
    final pairIndex = (levelData.levelNumber - 1) % backgroundGroundPairs.length;
    final currentPair = backgroundGroundPairs[pairIndex];

    // تعيين الزوج في نظام الأرضيات
    GroundSystem.setCurrentPair(currentPair);
  }

  void reset() {
    _stopAllTimers();

    // تنظيف جميع القوائم
    _obstacles.clear();
    _enemies.clear();
    _powerUps.clear();
    _platforms.clear();
    _particles.clear();

    // إعادة تعيين جميع المتغيرات
    _score = 0;
    _level = 1;
    _gameTime = 0.0;
    _isGameRunning = false;
    _levelCompleted = false;
    _isBossFight = false;
    _isBossDefeated = false;
    _currentBoss = null;
    _bossSpawned = false;
    _hasShield = false;
    _isSlowMotion = false;
    _isDoublePoints = false;
    _isSpeedBoostActive = false;
    _areEnemiesSlowed = false;
    // _continueCount = 0;
    // _savedGameState = null;

    // ✅ استخدام resetSimple بدلاً من reset
    if (_character != null) {
      _character!.resetSimple(); // ✅ التغيير هنا
    }

    // إعادة تهيئة الخلفية
    _backgroundManager.initialize();

    print('🔄 تم إعادة تعيين GameEngine');
  }

  void stop() {
    print('🛑 إيقاف GameEngine بشكل كامل');

    _isGameRunning = false;
    _levelCompleted = false;

    _stopAllTimers();
    _stopAllSpawners();

    // تنظيف جميع القوائم
    _obstacles.clear();
    _enemies.clear();
    _powerUps.clear();
    _platforms.clear();
    _particles.clear();

    // إيقاف الصوت
    AudioService().stopBackgroundMusic();
    AudioService().stopAllSounds();

    print('✅ تم إيقاف GameEngine بنجاح');
  }

  void cleanup() {
    saveGameBeforeExit();
    _stopAllTimers();
    AudioService().stopBackgroundMusic();
    _particles.clear();
    _obstacles.clear();
    _enemies.clear();
    _powerUps.clear();
    _platforms.clear();
    _character = null;
    _currentBoss = null;
    // _savedGameState = null; // ✅ إضافة تنظيف الحالة المحفوظة
    print('🧹 تم تنظيف GameEngine');
  }
}