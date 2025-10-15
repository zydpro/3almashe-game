import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../managers/enemy_manager.dart';
import '../models/Boss.dart';
import '../models/background_elements.dart';
import '../models/character_model.dart';
import '../models/enums.dart';
import '../services/game_data_service.dart';
import '../models/character.dart';
import '../models/obstacle.dart';
import '../models/level_data.dart';
import '../models/particle.dart';
import '../services/audio_service.dart';
import '../services/image_service.dart';
import '../services/vibration_service.dart';
import '../services/challenge_service.dart';

class GameEngine {
  Character? _character;
  final List<Obstacle> _obstacles = [];
  final List<Obstacle> _enemies = [];
  final List<Obstacle> _platforms = [];
  final List<PowerUp> _powerUps = [];
  final List<GameParticle> _particles = [];
  final BackgroundManager _backgroundManager = BackgroundManager();
  final BumpManager _bumpManager = BumpManager();
  final EnemyManager _enemyManager = EnemyManager();

  int _preBossScore = 0;
  bool _bossSpawned = false;
  double _gameTime = 0.0;

  // === نظام الزعيم ===
  Boss? _currentBoss;
  bool _isBossFight = false;
  bool _isBossDefeated = false;
  double _bossFightStartTime = 0;
  bool get shouldGameEnd => _character?.isDead == true || _isBossDefeated;

  // === حالة اللعبة ===
  int _score = 0;
  int _level = 1;
  bool _isGameRunning = false;
  bool _hasShield = false;
  bool _isSlowMotion = false;
  bool _isDoublePoints = false;
  bool _levelCompleted = false;
  bool _isInitialized = false;

  // === نظام الكومبو ===
  int _comboCount = 0;
  int _maxCombo = 0;
  bool _isComboActive = false;
  double _comboMultiplier = 1.0;
  int _coinsCollected = 0;
  int _obstaclesAvoided = 0;
  int _powerUpsCollected = 0;
  int _enemiesDefeated = 0;

  // === نظام الوقت ===
  int _timeElapsed = 0;
  static const int _levelDuration = 120;

  // === التايمرات ===
  Timer? _gameTimer;
  Timer? _obstacleSpawnTimer;
  Timer? _enemySpawnTimer;
  Timer? _powerUpSpawnTimer;
  Timer? _platformSpawnTimer;
  Timer? _shieldTimer;
  Timer? _slowMotionTimer;
  Timer? _doublePointsTimer;
  Timer? _comboTimer;
  Timer? _levelTimer;
  Timer? _tutorialTimer;
  Timer? _groundTextTimer;

  // === نظام التعليمات ===
  bool _showTutorialArrows = true;
  bool _showGroundText = true;
  bool _showBossAttackHint = false;
  Timer? _bossHintTimer;

  // === نظام التعليمات المؤقت ===
  bool _showTutorialInstructions = true;
  Timer? _tutorialInstructionsTimer;

  final Random _random = Random();
  final LevelData levelData;
  final Function()? onGameOver;
  final Function()? onLevelComplete;
  final Function()? onBossAppear;
  final Function()? onBossDefeated;
  final Function()? onCharacterDamage;
  final Function()? onBossHit;

  // === الخصائص العامة ===
  int get score => _score;
  int get level => _level;
  bool get isGameRunning => _isGameRunning;
  bool get hasShield => _hasShield;
  bool get isSlowMotion => _isSlowMotion;
  bool get isDoublePoints => _isDoublePoints;
  bool get isLevelCompleted => _levelCompleted;
  bool get isComboActive => _isComboActive;
  int get comboCount => _comboCount;
  double get comboMultiplier => _comboMultiplier;
  int get remainingTime => _levelDuration - _timeElapsed;
  List<Obstacle> get obstacles => _obstacles;
  List<Obstacle> get enemies => _enemies;
  List<Obstacle> get platforms => _platforms;
  List<PowerUp> get powerUps => _powerUps;
  List<GameParticle> get particles => _particles;
  BackgroundManager get backgroundManager => _backgroundManager;
  BumpManager get bumpManager => _bumpManager;
  Character get character => _character!;
  bool get showTutorialArrows => _showTutorialArrows;
  bool get showGroundText => _showGroundText;
  bool get showBossAttackHint => _showBossAttackHint;
  Boss? get currentBoss => _currentBoss;
  bool get isBossFight => _isBossFight;
  bool get isBossDefeated => _isBossDefeated;
  bool get showTutorialInstructions => _showTutorialInstructions;
  double get gameTime => _gameTime;

  GameEngine({
    required this.levelData,
    this.onGameOver,
    this.onLevelComplete,
    this.onBossAppear,
    this.onBossDefeated,
    this.onCharacterDamage,
    this.onBossHit,
  });

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

    // ✅ تحميل الشخصية المختارة تلقائياً
    _loadSelectedCharacter();
    _character!.setJumpBounds(0.3, 0.1);
    _backgroundManager.initialize();
    _initializePlatforms();
    _isInitialized = true;

    _startTutorialTimer();
    _startGroundTextTimer();
    _startTutorialInstructionsTimer();
  }

  void _loadSelectedCharacter() async {
    try {
      final selectedCharacter = await GameDataService.getSelectedCharacter();
      print('🎮 تحميل الشخصية المختارة: ${selectedCharacter.name} (ID: ${selectedCharacter.id})');

      _character?.setCharacter(selectedCharacter);

      // ✅ التأكد من تحميل الصور بشكل صحيح
      _preloadCharacterImages(selectedCharacter);

    } catch (e) {
      print('❌ خطأ في تحميل الشخصية المختارة: $e');
      // استخدام الشخصية الافتراضية في حالة الخطأ
      final defaultCharacter = GameCharacter.getDefaultCharacter();
      _character?.setCharacter(defaultCharacter);
    }
  }

  // ✅ دالة مساعدة لتحميل الصور مسبقاً
  void _preloadCharacterImages(GameCharacter character) {
    try {
      // يمكن إضافة منطق لتحميل الصور مسبقاً هنا إذا لزم الأمر
      print('🖼️ تحميل صور الشخصية: ${character.name}');
    } catch (e) {
      print('❌ خطأ في تحميل صور الشخصية: $e');
    }
  }

  void _startTutorialInstructionsTimer() {
    _tutorialInstructionsTimer = Timer(const Duration(seconds: 6), () {
      _showTutorialInstructions = true;
    });
  }

  void _initializePlatforms() {
    _platforms.clear();

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

    _platforms.add(Obstacle(
      x: 2.5,
      y: 0.3,
      width: 0.15,
      height: 0.03,
      speed: -0.03,
      color: Colors.brown.shade400,
      type: ObstacleType.groundLong,
      isWalkable: true,
      isEnemy: false,
      imagePath: ImageService.platform,
    ));
  }

  void ensureGameStarted() {
    if (!_isInitialized) {
      initialize();
    }
    if (!_isGameRunning && !_levelCompleted) {
      startGame();
    }
  }

  void _startTutorialTimer() {
    _tutorialTimer = Timer(const Duration(seconds: 5), () {
      _showTutorialArrows = false;
    });
  }

  void _startGroundTextTimer() {
    _groundTextTimer = Timer(const Duration(seconds: 6), () {
      _showGroundText = false;
    });
  }

  void _startBossHintTimer() {
    _showBossAttackHint = true;
    _bossHintTimer = Timer(const Duration(seconds: 6), () {
      _showBossAttackHint = false;
    });
  }

  void startGame() {
    if (!_isInitialized) initialize();

    _resetGameState();
    _isGameRunning = true;
    _levelCompleted = false;

    _forceReinitializePlatforms();
    _startGameLoop();
    _startLevelTimer();
    _startSpawners();

    AudioService().playBackgroundMusic();
  }

  void _startGameLoop() {
    _gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (_isGameRunning && _character != null) {
        _updateGame();
      }
    });
  }

  void _startLevelTimer() {
    _levelTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isGameRunning || _character == null || _levelCompleted) {
        return;
      }

      _timeElapsed++;
      _checkBossAppearance();

      if (!_isBossFight && _timeElapsed >= _levelDuration) {
        _completeLevel();
        timer.cancel();
      }
    });
  }

  void _checkBossAppearance() {
    if (_isBossFight || _bossSpawned) return;

    double completionPercentage = (_score / levelData.targetScore).clamp(0.0, 1.0);
    bool hasEnoughTimePassed = _gameTime > 30.0;

    if (completionPercentage >= 0.8 && hasEnoughTimePassed) {
      _startBossFight();
      _bossSpawned = true;
    }
  }

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
      const Duration(seconds: 20),
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

  void _spawnPlatform() {
    if (!_isGameRunning || _levelCompleted || _character == null) return;

    double spawnChance = 0.0;

    if (_platforms.length < 3) {
      spawnChance = 0.8;
    } else if (_platforms.length < 6) {
      spawnChance = 0.4;
    } else if (_platforms.length < 10) {
      spawnChance = 0.2;
    }

    if (_level >= 5) spawnChance += 0.1;
    if (_level >= 10) spawnChance += 0.1;

    if (_random.nextDouble() < spawnChance) {
      final platform = _createRandomPlatform();

      bool isPositionValid = true;
      for (var existingPlatform in _platforms) {
        final distanceX = (platform.x - existingPlatform.x).abs();
        final distanceY = (platform.y - existingPlatform.y).abs();

        if (distanceX < 0.4 && distanceY < 0.15) {
          isPositionValid = false;
          break;
        }
      }

      if (isPositionValid) {
        _platforms.add(platform);
      }
    }
  }

  Obstacle _createRandomPlatform() {
    double getRandomPlatformHeight() {
      final heightTier = _random.nextDouble();

      if (heightTier < 0.25) {
        return 0.25 + _random.nextDouble() * 0.1;
      } else if (heightTier < 0.5) {
        return 0.35 + _random.nextDouble() * 0.1;
      } else if (heightTier < 0.75) {
        return 0.45 + _random.nextDouble() * 0.1;
      } else {
        return 0.55 + _random.nextDouble() * 0.1;
      }
    }

    final types = [
      {
        'width': 0.18,
        'height': 0.035,
        'y': getRandomPlatformHeight(),
        'speed': 0.04,
        'type': 'large_platform'
      },
      {
        'width': 0.12,
        'height': 0.035,
        'y': getRandomPlatformHeight(),
        'speed': 0.05,
        'type': 'medium_platform'
      },
      {
        'width': 0.15,
        'height': 0.03,
        'y': getRandomPlatformHeight(),
        'speed': 0.03,
        'type': 'long_platform'
      },
    ];

    final type = types[_random.nextInt(types.length)];
    final baseSpeed = type['speed'] as double;

    double finalSpeed;
    if (_random.nextDouble() < 0.7) {
      finalSpeed = baseSpeed;
    } else {
      finalSpeed = -baseSpeed * 0.8;
    }

    if (_random.nextDouble() < 0.1) {
      finalSpeed = 0.0;
    }

    if (_level >= 5) {
      finalSpeed *= (1.0 + (_level * 0.02));
    }

    double startX;
    if (finalSpeed > 0) {
      startX = 1.1 + _random.nextDouble() * 0.3;
    } else if (finalSpeed < 0) {
      startX = -0.2 - _random.nextDouble() * 0.3;
    } else {
      startX = 0.3 + _random.nextDouble() * 0.7;
    }

    return Obstacle(
      x: startX,
      y: type['y'] as double,
      width: type['width'] as double,
      height: type['height'] as double,
      speed: finalSpeed,
      color: _getPlatformColor(type['type'] as String),
      type: ObstacleType.groundLong,
      isWalkable: true,
      isEnemy: false,
      imagePath: ImageService.platform,
    );
  }

  Color _getPlatformColor(String platformType) {
    switch (platformType) {
      case 'high_platform':
        return Colors.brown.shade300;
      case 'mega_platform':
        return Colors.brown.shade600;
      case 'small_fast_platform':
        return Colors.orange.shade400;
      case 'ground_platform':
        return Colors.brown.shade800;
      default:
        return Colors.brown.shade400;
    }
  }

  void _forceReinitializePlatforms() {
    _platforms.clear();
    _initializePlatforms();
  }

  void forceReinitializePlatforms() {
    _forceReinitializePlatforms();
  }

  // === معركة الزعيم ===
  void _startBossFight() {
    if (_isBossFight || _bossSpawned) return;

    _isBossFight = true;
    _bossSpawned = true;
    _bossFightStartTime = _gameTime;
    _preBossScore = _score;
    _currentBoss = _createBossForLevel(levelData.levelNumber);

    _platformSpawnTimer?.cancel();
    _startBossHintTimer();

    AudioService().playBossMusic();
    onBossAppear?.call();
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
      x: 0.5,
      y: 0.3,
      health: baseHealth,
      maxHealth: baseHealth,
      attackSpeed: attackSpeed,
      moveSpeed: 0.008 + (level * 0.0002),
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
        case 0: return 'assets/images/bosses/rare_boss1.png';
        case 1: return 'assets/images/bosses/rare_boss2.png';
        case 2: return 'assets/images/bosses/rare_boss3.png';
        case 3: return 'assets/images/bosses/rare_boss4.png';
        case 4: return 'assets/images/bosses/rare_boss5.png';
        default: return 'assets/images/bosses/rare_boss1.png';
      }
    } else {
      switch (bossIndex) {
        case 0: return 'assets/images/bosses/boss1.png';
        case 1: return 'assets/images/bosses/boss2.png';
        case 2: return 'assets/images/bosses/boss3.png';
        case 3: return 'assets/images/bosses/boss4.png';
        case 4: return 'assets/images/bosses/boss5.png';
        default: return 'assets/images/bosses/boss1.png';
      }
    }
  }

  bool _isRareBossLevel(int level) {
    return level == 15 || level == 25 || level == 50 || level == 75 ||
        level == 90 || level == 91 || level == 92 || level == 93 ||
        level == 94 || level == 95 || level == 96 || level == 97 ||
        level == 98 || level == 99;
  }

  // === تحديث اللعبة ===
  void _updateGame() {
    if (!_isGameRunning || _character == null) return;

    _gameTime += 0.016;

    if (_character!.isDead || _isBossDefeated) {
      if (_character!.isDead) {
        _gameOver();
      } else if (_isBossDefeated) {
        _completeLevel();
      }
      return;
    }

    _enemyManager.updateGameTime(0.016);
    _updateCharacter();
    _backgroundManager.update();
    _bumpManager.update();
    _updateParticles();
    _updatePlatforms();
    _updateObstacles();
    _updateEnemies();
    _updatePowerUps();

    _checkBrickJumping();

    if (_isBossFight) {
      _updateBoss();
    }

    _updateChallenges();
    _checkLevelCompletion();
  }

  void _updateCharacter() {
    _character!.update();
    _checkPlatformCollisions();
    _enforceScreenBounds();
  }

  void _enforceScreenBounds() {
    if (_character == null) return;

    _character!.x = _character!.x.clamp(0.05, 0.95);

    final double minY = 0.1;
    final double maxY = 0.85;

    if (_character!.y < minY) {
      _character!.y = minY;
      _character!.velocityY = 0.0;
    }

    if (_character!.y > maxY) {
      _character!.y = maxY;
      _character!.velocityY = 0.0;
    }
  }

  void _updatePlatforms() {
    final platformsToRemove = <Obstacle>[];

    for (var platform in _platforms) {
      platform.move();

      bool shouldRemove = false;

      if (platform.speed > 0) {
        shouldRemove = platform.x < -platform.width;
      } else if (platform.speed < 0) {
        shouldRemove = platform.x > 1.0 + platform.width;
      } else {
        shouldRemove = platform.x < -0.5;
      }

      if (shouldRemove) {
        platformsToRemove.add(platform);
      }
    }

    _removePlatforms(platformsToRemove);

    if (platformsToRemove.isNotEmpty) {
      _addNewPlatforms(platformsToRemove.length);
    }
  }

  void _addNewPlatforms(int count) {
    for (int i = 0; i < count; i++) {
      if (_platforms.length < 10) {
        final newPlatform = _createRandomPlatform();
        _platforms.add(newPlatform);
      }
    }
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

    if (!onPlatform && _character!.isOnPlatform) {
      _character!.leavePlatform();
    }
  }

  bool _isCharacterOnPlatform(Character character, Obstacle platform) {
    final characterBottom = character.y;
    final characterLeft = character.x - character.width / 2;
    final characterRight = character.x + character.width / 2;

    final platformTop = platform.y - platform.height / 2;
    final platformLeft = platform.x - platform.width / 2;
    final platformRight = platform.x + platform.width / 2;

    final horizontalOverlap = characterRight > platformLeft && characterLeft < platformRight;
    final verticalProximity = (characterBottom - platformTop).abs() < 0.03;
    final isFallingOntoPlatform = character.velocityY > 0;

    return horizontalOverlap && verticalProximity && isFallingOntoPlatform;
  }

  void _updateParticles() {
    _particles.removeWhere((particle) => particle.isDead);
    for (final particle in _particles) {
      particle.update();
    }
  }

  void _checkLevelCompletion() {
    if (!_levelCompleted && _isBossDefeated && _isBossFight) {
      _completeLevel();
    }
  }

  void _updateObstacles() {
    final obstaclesToRemove = <Obstacle>[];

    for (var obstacle in _obstacles) {
      obstacle.move();

      if (_checkCollision(_character!, obstacle)) {
        _handleObstacleCollision(obstacle, obstaclesToRemove);
      }

      if (obstacle.isOffScreen() || obstacle.x < -0.4) {
        obstaclesToRemove.add(obstacle);
        _obstaclesAvoided++;

        if (obstacle.speed > 0 && !_isBossFight) {
          _score += (10 * _comboMultiplier).toInt();
          _checkLevelUp();
        }
      }
    }

    _removeObstacles(obstaclesToRemove);
  }

  void _updateEnemies() {
    final enemiesToRemove = <Obstacle>[];

    _enemyManager.updateEnemies(_enemies, _character!.x, _character!.y);

    for (var enemy in _enemies) {
      if (enemy.type == ObstacleType.flyingEnemy) {
        _updateFlyingEnemyMovement(enemy);
      }

      enemy.move();

      if (_isCharacterJumpingOnEnemy(_character!, enemy)) {
        _defeatEnemy(enemy, enemiesToRemove);
      }
      else if (_checkCollision(_character!, enemy)) {
        _handleEnemyCollision(enemy);
      }

      if (enemy.isOffScreen()) {
        enemiesToRemove.add(enemy);
      }

      _enemyManager.checkPackageCollisions(_character!.packages, _enemies);
    }

    _removeEnemies(enemiesToRemove);
    _enemyManager.cleanupEnemies(_enemies);
  }

  void _updateFlyingEnemyMovement(Obstacle enemy) {
    if (enemy.type == ObstacleType.flyingEnemy) {
      final wave = sin(_gameTime * 3 + enemy.x * 6) * 0.015;
      enemy.y = (enemy.y + wave).clamp(0.25, 0.6);
      enemy.speed *= 1.1;
    }
  }

  bool _isCharacterJumpingOnEnemy(Character character, Obstacle enemy) {
    if (!enemy.isEnemy) return false;

    final characterBottom = character.y;
    final enemyTop = enemy.y - enemy.height / 2;
    final characterTop = character.y - character.height;

    final headRegionTop = enemyTop;
    final headRegionBottom = enemyTop + enemy.height * 0.3;

    final horizontalOverlap = (character.x + character.width/2) > (enemy.x - enemy.width/2) &&
        (character.x - character.width/2) < (enemy.x + enemy.width/2);

    final bool isAboveEnemy = characterBottom <= headRegionBottom;
    final bool isFalling = character.velocityY > 0;
    final bool isInHeadRegion = characterBottom >= headRegionTop &&
        characterBottom <= headRegionBottom;
    final bool isNotTooHigh = (headRegionTop - characterBottom).abs() < 0.08;

    bool isJumpingOnHead = horizontalOverlap &&
        isAboveEnemy &&
        isFalling &&
        isInHeadRegion &&
        isNotTooHigh;

    return isJumpingOnHead;
  }

  void _checkBrickJumping() {
    if (_character == null || !_character!.isJumping) return;

    for (var obstacle in _obstacles) {
      if (_isBrickObstacle(obstacle) && _isCharacterJumpingOnBrick(_character!, obstacle)) {
        _handleBrickJump(obstacle);
        break;
      }
    }
  }

  bool _isBrickObstacle(Obstacle obstacle) {
    return obstacle.color == Colors.brown ||
        obstacle.color == Colors.orange ||
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

    final horizontalOverlap = characterRight > brickLeft && characterLeft < brickRight;
    final verticalProximity = (characterBottom - brickTop).abs() < 0.05;
    final isFalling = character.velocityY > 0;

    bool isJumpingOnBrick = horizontalOverlap &&
        verticalProximity &&
        isFalling;

    return isJumpingOnBrick;
  }

  void _handleBrickJump(Obstacle brick) {
    _character!.velocityY = 0.0;
    _character!.isJumping = false;
    _character!.y = (brick.y - brick.height / 2) - _character!.height;

    final brickPoints = 20;
    _score += (brickPoints * _comboMultiplier).toInt();

    _createJumpParticles(_character!.x, _character!.y);
    AudioService().playJumpSound();
    VibrationService.vibrateSuccess();

    _obstacles.remove(brick);
  }

  void _updateBoss() {
    if (_currentBoss == null || !_isBossFight || _character == null) return;

    _currentBoss!.move();
    _currentBoss!.attack(_gameTime);
    _currentBoss!.updateProjectiles();

    if (_checkCollision(_character!, _currentBoss!)) {
      _character!.takeDamage(25);
      _createHitParticles(_character!.x, _character!.y);
      onCharacterDamage?.call();

      if (_character!.isDead) {
        _gameOver();
      }
    }

    for (var package in _character!.packages) {
      if (package.collidesWithBoss(_currentBoss!)) {
        _currentBoss!.takeDamage(package.damage);
        package.isActive = false;
        _createBossHitParticles(_currentBoss!.x, _currentBoss!.y);
        AudioService().playBossHitSound();
        onBossHit?.call();

        if (_currentBoss!.isDead) {
          _defeatBoss();
        }
      }
    }

    for (var projectile in _currentBoss!.projectiles) {
      if (_character!.collidesWithPackage(projectile)) {
        _character!.takeDamage(projectile.damage);
        projectile.isActive = false;
        _createHitParticles(_character!.x, _character!.y);
        onCharacterDamage?.call();

        if (_character!.isDead) {
          _gameOver();
        }
      }
    }
  }

  void _defeatBoss() {
    if (_isBossDefeated) return;

    _isBossDefeated = true;
    _isBossFight = false;

    final bossScore = (levelData.targetScore * 0.3).toInt();
    _score = _preBossScore + bossScore;

    _createVictoryParticles();
    AudioService().playBossDefeatSound();

    _completeLevel();
    onBossDefeated?.call();
  }

  void _defeatEnemy(Obstacle enemy, List<Obstacle> enemiesToRemove) {
    enemiesToRemove.add(enemy);
    _enemiesDefeated++;

    final points = _enemyManager.getEnemyPoints(enemy) * _comboMultiplier.toInt();
    _score += points;

    _activateCombo();
    _createEnemyDefeatParticles(enemy.x, enemy.y);
    AudioService().playEnemyDieSound();
    VibrationService.vibrateSuccess();
  }

  void _handleEnemyCollision(Obstacle enemy) {
    _character?.takeDamage(20);
    _createHitParticles(_character!.x, _character!.y);
    onCharacterDamage?.call();

    AudioService().playGameOverSound();
    VibrationService.vibrateGameOver();

    if (_character!.isDead) {
      _gameOver();
    }
  }

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

  // === نظام التصادم ===
  bool _checkCollision(Character character, dynamic object) {
    if (character.hasShield || character.isInvincible) {
      return false;
    }

    final charRect = character.boundingBox;
    final objRect = object.boundingBox;

    return charRect.overlaps(objRect);
  }

  void _handleObstacleCollision(Obstacle obstacle, List<Obstacle> obstaclesToRemove) {
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

  // === نظام الجسيمات ===
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

  void _createComboParticles(double x, double y) {
    final newParticles = GameParticle.createComboParticles(x, y, _comboMultiplier, 10, _random);
    _particles.addAll(newParticles);
  }

  void _createHitParticles(double x, double y) {
    final newParticles = GameParticle.createHitParticles(x, y, 8, _random);
    _particles.addAll(newParticles);
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

  // === نظام الكومبو ===
  void _activateCombo() {
    _comboCount++;
    _maxCombo = max(_maxCombo, _comboCount);
    _isComboActive = true;

    _createComboParticles(_character!.x, _character!.y - 0.1);

    _comboTimer?.cancel();
    _comboTimer = Timer(const Duration(seconds: 3), () {
      _isComboActive = false;
      _comboCount = 0;
      _comboMultiplier = 1.0;
    });

    if (_comboCount >= 5) _comboMultiplier = 1.5;
    if (_comboCount >= 10) _comboMultiplier = 2.0;
    if (_comboCount >= 15) _comboMultiplier = 2.5;
    if (_comboCount >= 20) _comboMultiplier = 3.0;

    VibrationService.vibrateCombo();
  }

  // === توليد العوائق ===
  void _spawnObstacle() {
    if (!_isGameRunning || _levelCompleted || _character == null) return;

    final speed = _isSlowMotion ? levelData.obstacleSpeed * 0.5 : levelData.obstacleSpeed;

    double spawnChance = 0.0;

    if (_obstacles.length < 2) {
      spawnChance = 0.9;
    } else if (_obstacles.length < 5) {
      spawnChance = 0.7;
    } else if (_obstacles.length < 8) {
      spawnChance = 0.4;
    }

    if (_random.nextDouble() < spawnChance) {
      if (_obstacles.isNotEmpty) {
        final lastObstacle = _obstacles.last;
        final distanceFromLast = 1.1 - lastObstacle.x;

        if (distanceFromLast < 0.4) {
          return;
        }
      }

      final obstacle = _createRandomObstacle(speed);
      _obstacles.add(obstacle);
    }

    if (_random.nextDouble() < 0.4) {
      _bumpManager.spawnBump();
    }
  }

  Obstacle _createRandomObstacle(double speed) {
    final obstacleType = _random.nextDouble();
    double yPosition, width, height;
    ObstacleType type;
    String? imagePath;

    double getRandomSkyHeight() {
      final heightTier = _random.nextDouble();

      if (heightTier < 0.25) {
        return 0.25 + _random.nextDouble() * 0.1;
      } else if (heightTier < 0.5) {
        return 0.35 + _random.nextDouble() * 0.1;
      } else if (heightTier < 0.75) {
        return 0.45 + _random.nextDouble() * 0.15;
      } else {
        return 0.55 + _random.nextDouble() * 0.1;
      }
    }

    bool isBrick = _random.nextDouble() < 0.5;

    if (obstacleType < 0.2) {
      yPosition = 0.75;
      if (isBrick) {
        width = 0.12;
        height = 0.12;
        type = ObstacleType.groundLong;
        imagePath = ImageService.brick;
      } else {
        width = 0.1;
        height = 0.15;
        type = ObstacleType.groundLong;
        imagePath = ImageService.pipe;
      }
    } else if (obstacleType < 0.4) {
      yPosition = getRandomSkyHeight();
      if (isBrick) {
        width = 0.08;
        height = 0.08;
        type = ObstacleType.skyLong;
        imagePath = ImageService.brick;
      } else {
        width = 0.07;
        height = 0.12;
        type = ObstacleType.skyLong;
        imagePath = ImageService.pipe;
      }
    } else if (obstacleType < 0.6) {
      yPosition = getRandomSkyHeight();
      if (isBrick) {
        width = 0.06;
        height = 0.06;
        type = ObstacleType.skyShort;
        imagePath = ImageService.brick;
      } else {
        width = 0.05;
        height = 0.1;
        type = ObstacleType.skyShort;
        imagePath = ImageService.pipe;
      }
    } else {
      yPosition = getRandomSkyHeight();
      if (isBrick) {
        width = 0.1;
        height = 0.1;
        type = ObstacleType.skyLong;
        imagePath = ImageService.brick;
      } else {
        width = 0.08;
        height = 0.14;
        type = ObstacleType.skyLong;
        imagePath = ImageService.pipe;
      }
    }

    bool isPositionSafe(double testY, double testHeight) {
      for (var platform in _platforms) {
        final platformTop = platform.y - platform.height / 2;
        final platformBottom = platform.y + platform.height / 2;
        final obstacleTop = testY - testHeight / 2;
        final obstacleBottom = testY + testHeight / 2;

        if ((obstacleBottom >= platformTop && obstacleTop <= platformBottom)) {
          return false;
        }
      }
      return true;
    }

    if (!isPositionSafe(yPosition, height)) {
      yPosition = getRandomSkyHeight();
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

  // === توليد الأعداء ===
  void _spawnEnemy() {
    if (!_isGameRunning || _levelCompleted || _character == null) return;

    double flyingEnemyChance = 0.3;
    if (_level >= 5) flyingEnemyChance = 0.5;
    if (_level >= 10) flyingEnemyChance = 0.7;

    if (_random.nextDouble() < 0.8) {
      final bool spawnFlyingEnemy = _random.nextDouble() < flyingEnemyChance;

      Obstacle enemy;
      if (spawnFlyingEnemy) {
        enemy = _enemyManager.createFlyingEnemy(
            _isSlowMotion ? levelData.obstacleSpeed * 0.5 : levelData.obstacleSpeed,
            _level
        );

        final heightType = _random.nextDouble();
        if (heightType < 0.33) {
          enemy.y = 0.3 + _random.nextDouble() * 0.1;
        } else if (heightType < 0.66) {
          enemy.y = 0.4 + _random.nextDouble() * 0.15;
        } else {
          enemy.y = 0.25 + _random.nextDouble() * 0.1;
        }

      } else {
        enemy = _enemyManager.createRandomEnemy(
            _isSlowMotion ? levelData.obstacleSpeed * 0.5 : levelData.obstacleSpeed,
            _level
        );
      }

      _enemies.add(enemy);
    }
  }

  // === توليد الباور أب ===
  void _spawnPowerUp() {
    if (!_isGameRunning || _levelCompleted || _character == null) return;

    if (_random.nextDouble() < 0.6) {
      final yPosition = 0.4 + _random.nextDouble() * 0.4;
      final type = PowerUpType.values[_random.nextInt(PowerUpType.values.length)];

      final powerUp = PowerUp(
        x: 1.1,
        y: yPosition,
        type: type,
        width: 0.06,
        height: 0.06,
        speed: 0.015,
        color: _getPowerUpColor(type),
        icon: _getPowerUpIcon(type),
      );

      _powerUps.add(powerUp);
    }
  }

  void _collectPowerUp(PowerUp powerUp) {
    _activateCombo();
    _powerUpsCollected++;
    _coinsCollected++;

    _createPowerUpParticles(powerUp.x, powerUp.y, _getPowerUpColor(powerUp.type));
    AudioService().playCoinSound();
    VibrationService.vibrateSuccess();

    switch (powerUp.type) {
      case PowerUpType.points:
        final baseScore = _isDoublePoints ? 100 : 50;
        _score += (baseScore * _comboMultiplier).toInt();
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
        _character?.heal(25);
        break;
    }
  }

  // === تفعيل الباور أب ===
  void _activateShield() {
    _hasShield = true;
    _character?.activateShield(const Duration(seconds: 5));
    _shieldTimer?.cancel();
    _shieldTimer = Timer(const Duration(seconds: 5), () {
      _hasShield = false;
      _character?.deactivateShield();
    });
  }

  void _activateSlowMotion() {
    _isSlowMotion = true;
    _slowMotionTimer?.cancel();
    _slowMotionTimer = Timer(const Duration(seconds: 3), () {
      _isSlowMotion = false;
    });
  }

  void _activateDoublePoints() {
    _isDoublePoints = true;
    _doublePointsTimer?.cancel();
    _doublePointsTimer = Timer(const Duration(seconds: 10), () {
      _isDoublePoints = false;
    });
  }

  // === التحكم في الشخصية ===
  void jumpCharacter() {
    if (_character == null) return;

    _character!.jump();
    _createJumpParticles(_character!.x, _character!.y + 0.05);
    AudioService().playJumpSound();
    VibrationService.vibrateSuccess();
  }

  void duckCharacter() => _character?.duck();

  void stopDuckingCharacter() => _character?.stopDucking();

  void attackCharacter() {
    if (_character == null) return;

    _character!.attack(_gameTime);
    AudioService().playPackageThrowSound();
    VibrationService.vibrateSuccess();
  }

  // === دوال الحركة الجديدة ===
  void moveCharacterLeft() {
    _character?.moveLeft();
  }

  void moveCharacterRight() {
    _character?.moveRight();
  }

  void moveCharacterUp() {
    _character?.moveUp();
  }

  void moveCharacterDown() {
    _character?.moveDown();
  }

  void stopCharacterMoving() {
    _character?.stopMoving();
  }

  // ✅✅✅ نظام السحب المحسن ✅✅✅
  void handleCharacterDrag(double deltaX, double deltaY) {
    if (_character == null) return;

    // ✅ تحديد قوة السحب بناءً على المسافة
    double dragSensitivity = 0.0005;
    double horizontalForce = deltaX * dragSensitivity;
    double verticalForce = deltaY * dragSensitivity;

    // ✅ تطبيق الحركة الأفقية
    if (horizontalForce.abs() > 0.001) {
      _character!.x += horizontalForce;
      _character!.x = _character!.x.clamp(0.05, 0.95);
    }

    // ✅ تطبيق الحركة العمودية (فقط إذا لم يكن على الأرض)
    if (verticalForce.abs() > 0.001 && !_character!.isOnPlatform) {
      _character!.y += verticalForce;
      _character!.y = _character!.y.clamp(0.1, 0.85);
    }

    // ✅ تحديد نوع القفز بناءً على قوة السحب العمودي
    if (deltaY < -20) {
      // ✅ سحب للأعلى - قفز
      bool isLongJump = deltaY.abs() > 80;
      _character!.jump(isLongJump: isLongJump);
      _createJumpParticles(_character!.x, _character!.y + 0.05);
      AudioService().playJumpSound();
    } else if (deltaY > 20 && _character!.isJumping) {
      // ✅ سحب للأسفل أثناء القفز - تسريع الهبوط
      _character!.velocityY += 0.005 * (deltaY / 50).abs();
    }
  }

  // === إدارة اللعبة ===
  void pauseGame() {
    if (!_isGameRunning) return;

    _isGameRunning = false;
    _stopAllTimers();
  }

  void resumeGame() {
    if (_isGameRunning || _levelCompleted) return;

    _isGameRunning = true;
    _startGameLoop();
    _startSpawners();
  }

  void _completeLevel() {
    _levelCompleted = true;
    _isGameRunning = false;
    _stopAllTimers();

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
    if (!_isGameRunning || _levelCompleted) return;

    _isGameRunning = false;
    _levelCompleted = false;
    _stopAllTimers();

    AudioService().playGameOverSound();
    AudioService().stopBackgroundMusic();
    VibrationService.vibrateGameOver();

    _saveGameProgress();
    _callGameOverCallback();
  }

  void _callGameOverCallback() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (onGameOver != null) {
        onGameOver!();
      }
    });
  }

  void _saveGameProgress() async {
    await GameDataService.saveGameProgress(_score, levelData.levelNumber);
  }

  void _resetGameState() {
    _score = 0;
    _level = 1;
    _timeElapsed = 0;
    _gameTime = 0.0;
    _obstacles.clear();
    _enemies.clear();
    _powerUps.clear();
    _platforms.clear();
    _particles.clear();
    _backgroundManager.initialize();
    _bumpManager.bumps.clear();
    _character = Character(x: 0.2, y: 0.7);
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

    _comboCount = 0;
    _maxCombo = 0;
    _isComboActive = false;
    _comboMultiplier = 1.0;
    _coinsCollected = 0;
    _obstaclesAvoided = 0;
    _powerUpsCollected = 0;
    _enemiesDefeated = 0;

    _hasShield = false;
    _isSlowMotion = false;
    _isDoublePoints = false;

    _stopAllTimers();
    _initializePlatforms();
    _startTutorialTimer();
    _startGroundTextTimer();
    _startTutorialInstructionsTimer();
  }

  void _stopAllTimers() {
    _gameTimer?.cancel();
    _obstacleSpawnTimer?.cancel();
    _enemySpawnTimer?.cancel();
    _powerUpSpawnTimer?.cancel();
    _platformSpawnTimer?.cancel();
    _shieldTimer?.cancel();
    _slowMotionTimer?.cancel();
    _doublePointsTimer?.cancel();
    _comboTimer?.cancel();
    _levelTimer?.cancel();
    _tutorialTimer?.cancel();
    _groundTextTimer?.cancel();
    _bossHintTimer?.cancel();
    _platformSpawnTimer?.cancel();
    _tutorialInstructionsTimer?.cancel();
  }

  // === المساعدات ===
  void _removeObstacles(List<Obstacle> obstaclesToRemove) {
    for (var obstacle in obstaclesToRemove) {
      _obstacles.remove(obstacle);
      if (!_isBossFight) {
        _score += (10 * _comboMultiplier).toInt();
        _checkLevelUp();
      }
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

  // === الألوان والرموز ===
  Color _getPowerUpColor(PowerUpType type) {
    switch (type) {
      case PowerUpType.points: return Colors.amber;
      case PowerUpType.shield: return Colors.blue;
      case PowerUpType.slowMotion: return Colors.green;
      case PowerUpType.doublePoints: return Colors.purple;
      case PowerUpType.health: return Colors.red;
    }
  }

  IconData _getPowerUpIcon(PowerUpType type) {
    switch (type) {
      case PowerUpType.points: return Icons.star;
      case PowerUpType.shield: return Icons.shield;
      case PowerUpType.slowMotion: return Icons.slow_motion_video;
      case PowerUpType.doublePoints: return Icons.double_arrow;
      case PowerUpType.health: return Icons.favorite;
    }
  }

  bool get isBossSpawned => _bossSpawned;
  double get levelCompletionPercentage => (_score / levelData.targetScore).clamp(0.0, 1.0);

  int get pointsUntilBoss {
    int targetForBoss = (levelData.targetScore * 0.8).toInt();
    return (targetForBoss - _score).clamp(0, targetForBoss);
  }

  bool get canBossAppear => levelCompletionPercentage >= 0.8 && !_bossSpawned && !_isBossFight;

  int? get remainingBossTime {
    if (!_isBossFight) return null;
    return (60 - (_timeElapsed - _levelDuration)).clamp(0, 60);
  }

  // === دالة بناء واجهة الزعيم ===
  Widget buildBossInterface(Size screenSize) {
    final Boss? boss = _currentBoss;
    if (boss == null) return const SizedBox.shrink();

    return Positioned(
      bottom: 100 + (screenSize.height * (0.75 - boss.y)) + 130,
      left: screenSize.width * boss.x - 60,
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.yellow, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '👑 الزعيم',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 12,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 104 * boss.healthPercentage,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.red, Colors.orange, Colors.yellow],
                        stops: [0.0, 0.5, 1.0],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  Center(
                    child: Text(
                      '${boss.health}/${boss.maxHealth}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            offset: Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void dispose() {
    _stopAllTimers();
    AudioService().stopBackgroundMusic();
    _particles.clear();
    _obstacles.clear();
    _enemies.clear();
    _powerUps.clear();
    _platforms.clear();
    _character = null;
    _currentBoss = null;
  }
}