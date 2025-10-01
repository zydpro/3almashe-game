import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/background_elements.dart';
import '../services/game_data_service.dart';
import '../models/character.dart';
import '../models/obstacle.dart';
import '../models/level_data.dart';
import '../models/particle.dart';
import '../services/audio_service.dart';
import '../services/vibration_service.dart';
import '../services/challenge_service.dart';

class GameEngine {
  // === المتغيرات الأساسية ===
  Character? _character;
  final List<Obstacle> _obstacles = [];
  final List<Obstacle> _enemies = [];
  final List<PowerUp> _powerUps = [];
  final List<GameParticle> _particles = [];
  final BackgroundManager _backgroundManager = BackgroundManager();
  final BumpManager _bumpManager = BumpManager();

  // === نظام الزعيم ===
  Boss? _currentBoss;
  bool _isBossFight = false;
  bool _isBossDefeated = false;
  double _bossFightStartTime = 0;

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
  double _gameTime = 0.0;
  static const int _levelDuration = 120;

  // === التايمرات ===
  Timer? _gameTimer;
  Timer? _obstacleSpawnTimer;
  Timer? _enemySpawnTimer;
  Timer? _powerUpSpawnTimer;
  Timer? _shieldTimer;
  Timer? _slowMotionTimer;
  Timer? _doublePointsTimer;
  Timer? _comboTimer;
  Timer? _levelTimer;
  Timer? _tutorialTimer;

  // === نظام التعليمات ===
  bool _showTutorialArrows = true;

  final Random _random = Random();
  final LevelData levelData;
  final Function()? onGameOver;
  final Function()? onLevelComplete;
  final Function()? onBossAppear;
  final Function()? onBossDefeated;

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
  List<PowerUp> get powerUps => _powerUps;
  List<GameParticle> get particles => _particles;
  BackgroundManager get backgroundManager => _backgroundManager;
  BumpManager get bumpManager => _bumpManager;
  Character get character => _character!;
  bool get showTutorialArrows => _showTutorialArrows;
  Boss? get currentBoss => _currentBoss;
  bool get isBossFight => _isBossFight;
  bool get isBossDefeated => _isBossDefeated;

  GameEngine({
    required this.levelData,
    this.onGameOver,
    this.onLevelComplete,
    this.onBossAppear,
    this.onBossDefeated,
  });

  // === التهيئة ===
  void initialize() {
    if (_isInitialized) return;

    _character = Character(x: 0.2, y: 0.7);
    _backgroundManager.initialize();
    _isInitialized = true;

    // بدء مؤقت إخفاء التعليمات بعد 5 ثواني
    _startTutorialTimer();

    print('🎮 GameEngine initialized - Level ${levelData.levelNumber}');
  }

  void _startTutorialTimer() {
    _tutorialTimer = Timer(const Duration(seconds: 5), () {
      _showTutorialArrows = false;
      print('🎯 Tutorial arrows hidden after 5 seconds');
    });
  }

  // === بدء اللعبة ===
  void startGame() {
    if (!_isInitialized) initialize();

    _resetGameState();
    _isGameRunning = true;
    _levelCompleted = false;

    print('🚀 Game Started - Level ${levelData.levelNumber}');

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
      if (_isGameRunning && _character != null) {
        _timeElapsed++;

        // التحقق إذا حان وقت ظهور الزعيم
        if (!_isBossFight && _timeElapsed >= _levelDuration - 30) {
          _startBossFight();
        }

        if (_timeElapsed >= _levelDuration) {
          if (_isBossFight && !_isBossDefeated) {
            // إذا انتهى الوقت ولم يهزم الزعيم
            _character!.loseLife();
            if (_character!.isDead) {
              _gameOver();
            } else {
              _resetBossFight();
            }
          } else {
            _completeLevel();
          }
        }
      }
    });
  }

  void _startSpawners() {
    _obstacleSpawnTimer = Timer.periodic(
      const Duration(milliseconds: 1200),
          (timer) => _spawnObstacle(),
    );

    _enemySpawnTimer = Timer.periodic(
      const Duration(milliseconds: 3000),
          (timer) => _spawnEnemy(),
    );

    _powerUpSpawnTimer = Timer.periodic(
      const Duration(seconds: 8),
          (timer) => _spawnPowerUp(),
    );
  }

  // === معركة الزعيم ===
  void _startBossFight() {
    _isBossFight = true;
    _bossFightStartTime = _gameTime;
    _currentBoss = _createBossForLevel(levelData.levelNumber);

    // إيقاف ظهور العوائق والأعداء الجديدة
    _obstacleSpawnTimer?.cancel();
    _enemySpawnTimer?.cancel();

    // تغيير الموسيقى
    AudioService().playBossMusic();

    print('👹 Boss fight started! Level ${levelData.levelNumber}');
    onBossAppear?.call();
  }

  void _resetBossFight() {
    _isBossFight = false;
    _isBossDefeated = false;
    _currentBoss = null;
    _character?.health = _character!.maxHealth;

    // استئناف ظهور العوائق
    _startSpawners();

    AudioService().playBackgroundMusic();
  }

  Boss _createBossForLevel(int level) {
    final isRare = _isRareBossLevel(level);
    final isFinal = level == 100;

    String imagePath;
    int baseHealth = 100 + (level * 20);
    double attackSpeed = 3.0 - (level * 0.02);
    if (attackSpeed < 0.5) attackSpeed = 0.5;

    if (isFinal) {
      imagePath = 'assets/images/bosses/final_boss.png';
      baseHealth = 5000;
      attackSpeed = 0.3;
    } else if (isRare) {
      final rareIndex = _getRareBossIndex(level);
      imagePath = 'assets/images/bosses/rare_boss${rareIndex + 1}.png';
      baseHealth = (baseHealth * 1.5).toInt();
    } else {
      final normalIndex = level % 5;
      imagePath = 'assets/images/bosses/boss${normalIndex + 1}.png';
    }

    return Boss(
      x: 0.7,
      y: 0.3,
      health: baseHealth,
      maxHealth: baseHealth,
      attackSpeed: attackSpeed,
      moveSpeed: 0.005 + (level * 0.0001),
      imagePath: imagePath,
      level: level,
      isRare: isRare,
      isFinalBoss: isFinal,
    );
  }

  bool _isRareBossLevel(int level) {
    return level == 15 || level == 25 || level == 50 || level == 75 ||
        level == 90 || level == 91 || level == 92 || level == 93 ||
        level == 94 || level == 95 || level == 96 || level == 97 ||
        level == 98 || level == 99;
  }

  int _getRareBossIndex(int level) {
    final rareLevels = [15, 25, 50, 75, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99];
    return rareLevels.indexOf(level) % 5;
  }

  // === تحديث اللعبة ===
  void _updateGame() {
    if (!_isGameRunning || _character == null) return;

    _gameTime += 0.016; // حوالي 60 FPS

    _updateCharacter();
    _backgroundManager.update();
    _bumpManager.update();
    _updateParticles();
    _checkLevelCompletion();
    _updateObstacles();
    _updateEnemies();
    _updatePowerUps();
    _updateBoss();
    _updateChallenges();
  }

  void _updateCharacter() {
    _character!.update();
  }

  void _updateParticles() {
    _particles.removeWhere((particle) => particle.isDead);
    for (final particle in _particles) {
      particle.update();
    }
  }

  void _checkLevelCompletion() {
    if (!_levelCompleted && (_isBossDefeated || _score >= levelData.targetScore)) {
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

      if (obstacle.isOffScreen()) {
        obstaclesToRemove.add(obstacle);
        _obstaclesAvoided++;
      }
    }

    _removeObstacles(obstaclesToRemove);
  }

  void _updateEnemies() {
    final enemiesToRemove = <Obstacle>[];

    for (var enemy in _enemies) {
      enemy.move();

      // التحقق إذا قفز اللاعب فوق العدو
      if (_character!.isAboveEnemy(enemy)) {
        _defeatEnemy(enemy, enemiesToRemove);
      }
      // التحقق إذا اصطدم اللاعب بالعدو
      else if (_checkCollision(_character!, enemy)) {
        _handleEnemyCollision(enemy);
      }

      // التحقق إذا خرج العدو من الشاشة
      if (enemy.isOffScreen()) {
        enemiesToRemove.add(enemy);
      }

      // التحقق إذا اصطدم طرد اللاعب بالعدو
      for (var package in _character!.packages) {
        if (package.collidesWith(enemy)) {
          enemy.takeDamage(package.damage);
          package.isActive = false;
          if (enemy.isDead) {
            _defeatEnemy(enemy, enemiesToRemove);
          }
          _createHitParticles(enemy.x, enemy.y);
          AudioService().playEnemyHitSound();
        }
      }
    }

    _removeEnemies(enemiesToRemove);
  }

  void _updateBoss() {
    if (_currentBoss == null || !_isBossFight || _character == null) return;

    _currentBoss!.move();
    _currentBoss!.attack(_gameTime);
    _currentBoss!.updateProjectiles();

    // التحقق إذا اصطدمت طرود اللاعب بالزعيم
    for (var package in _character!.packages) {
      if (package.collidesWith(Obstacle(
        x: _currentBoss!.x,
        y: _currentBoss!.y,
        width: _currentBoss!.width,
        height: _currentBoss!.height,
      ))) {
        _currentBoss!.takeDamage(package.damage);
        package.isActive = false;
        _createBossHitParticles(_currentBoss!.x, _currentBoss!.y);
        AudioService().playBossHitSound();

        if (_currentBoss!.isDead) {
          _defeatBoss();
        }
      }
    }

    // التحقق إذا اصطدمت طرود الزعيم باللاعب
    for (var projectile in _currentBoss!.projectiles) {
      if (_character!.collidesWithPackage(projectile)) {
        _character!.takeDamage(projectile.damage);
        projectile.isActive = false;
        _createHitParticles(_character!.x, _character!.y);

        if (_character!.isDead) {
          _gameOver();
        }
      }
    }
  }

  void _defeatBoss() {
    _isBossDefeated = true;
    _isBossFight = false;

    final bossScore = 1000 + (levelData.levelNumber * 100);
    _score += bossScore;

    _createVictoryParticles();
    AudioService().playBossDefeatSound();

    print('🎉 Boss defeated! +$bossScore points');
    onBossDefeated?.call();

    // الانتقال لإكمال المرحلة بعد فترة
    Timer(const Duration(seconds: 2), () {
      _completeLevel();
    });
  }

  void _defeatEnemy(Obstacle enemy, List<Obstacle> enemiesToRemove) {
    enemiesToRemove.add(enemy);
    _enemiesDefeated++;
    _score += 50 * _comboMultiplier.toInt();
    _activateCombo();

    _createEnemyDefeatParticles(enemy.x, enemy.y);
    AudioService().playEnemyDieSound();
    VibrationService.vibrateSuccess();

    print('💀 Enemy defeated! +${(50 * _comboMultiplier).toInt()} points');
  }

  void _handleEnemyCollision(Obstacle enemy) {
    _character?.takeDamage(20);
    _createHitParticles(_character!.x, _character!.y);
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
    // إذا كانت الشخصية لديها درع، لا تتعارض مع العوائق
    if (character.hasShield || character.isInvincible) {
      return false;
    }

    final charRect = Rect.fromLTWH(
      character.x - character.width / 2,
      character.y - character.height,
      character.width,
      character.height,
    );

    final objRect = Rect.fromLTWH(
      object.x - object.width / 2,
      object.y - object.height,
      object.width,
      object.height,
    );

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
      print('🛡️ Shield protected from obstacle!');
    } else {
      _character?.takeDamage(10);
      _createHitParticles(_character!.x, _character!.y);

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

    print('🎯 Combo! x$_comboMultiplier (${_comboCount} consecutive)');
    VibrationService.vibrateCombo();
  }

  // === توليد العوائق ===
  void _spawnObstacle() {
    if (!_isGameRunning || _levelCompleted || _isBossFight || _character == null) return;

    final speed = _isSlowMotion ? levelData.obstacleSpeed * 0.5 : levelData.obstacleSpeed;

    if (_random.nextDouble() < 0.8) {
      _obstacles.add(_createRandomObstacle(speed));
    }

    if (_random.nextDouble() < 0.4) {
      _bumpManager.spawnBump();
    }
  }

  Obstacle _createRandomObstacle(double speed) {
    final obstacleType = _random.nextDouble();
    double yPosition, width, height;
    ObstacleType type;

    if (obstacleType < 0.25) {
      // عقبات أرضية طويلة (25%)
      yPosition = 0.75;
      width = 0.12;
      height = 0.12;
      type = ObstacleType.groundLong;
    } else if (obstacleType < 0.4) {
      // عقبات أرضية قصيرة (15%)
      yPosition = 0.75;
      width = 0.06;
      height = 0.06;
      type = ObstacleType.groundShort;
    } else if (obstacleType < 0.55) {
      // عقبات أرضية عريضة (15%)
      yPosition = 0.75;
      width = 0.15;
      height = 0.08;
      type = ObstacleType.groundWide;
    } else if (obstacleType < 0.7) {
      // عقبات سماوية طويلة (15%)
      yPosition = 0.45 + _random.nextDouble() * 0.15;
      width = 0.08;
      height = 0.08;
      type = ObstacleType.skyLong;
    } else if (obstacleType < 0.85) {
      // عقبات سماوية قصيرة (15%)
      yPosition = 0.45 + _random.nextDouble() * 0.15;
      width = 0.05;
      height = 0.05;
      type = ObstacleType.skyShort;
    } else {
      // عقبات سماوية عريضة (15%)
      yPosition = 0.45 + _random.nextDouble() * 0.15;
      width = 0.12;
      height = 0.06;
      type = ObstacleType.skyWide;
    }

    return Obstacle(
      x: 1.1,
      y: yPosition,
      speed: speed,
      width: width,
      height: height,
      color: _getRandomObstacleColor(),
      icon: _getRandomObstacleIcon(),
      type: type,
    );
  }

  // === توليد الأعداء ===
  void _spawnEnemy() {
    if (!_isGameRunning || _levelCompleted || _isBossFight || _character == null) return;

    if (_random.nextDouble() < 0.3) {
      _enemies.add(_createRandomEnemy());
    }
  }

  Obstacle _createRandomEnemy() {
    final enemyType = _random.nextDouble();
    int health;
    double speed;

    if (enemyType < 0.6) {
      // عدو عادي (60%)
      health = 1;
      speed = 0.01;
    } else if (enemyType < 0.9) {
      // عدو متوسط (30%)
      health = 2;
      speed = 0.012;
    } else {
      // عدو قوي (10%)
      health = 3;
      speed = 0.008;
    }

    return Obstacle(
      x: 1.1,
      y: 0.75,
      speed: speed,
      width: 0.08,
      height: 0.08,
      color: Colors.red,
      icon: Icons.warning,
      type: ObstacleType.enemy,
      isEnemy: true,
      health: health,
      maxHealth: health,
      isMoving: true,
    );
  }

  // === توليد الباور أب ===
  void _spawnPowerUp() {
    if (!_isGameRunning || _levelCompleted || _isBossFight || _character == null) return;

    if (_random.nextDouble() < 0.4) {
      final yPosition = 0.4 + _random.nextDouble() * 0.4;
      final type = PowerUpType.values[_random.nextInt(PowerUpType.values.length)];

      _powerUps.add(PowerUp(
        x: 1.1,
        y: yPosition,
        type: type,
        width: 0.06,
        height: 0.06,
        speed: 0.015,
        color: _getPowerUpColor(type),
        icon: _getPowerUpIcon(type),
      ));
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
        print('⭐ Collected points power-up! Score: $_score');
        break;
      case PowerUpType.shield:
        _activateShield();
        print('🛡️ Shield activated!');
        break;
      case PowerUpType.slowMotion:
        _activateSlowMotion();
        print('🐌 Slow motion activated!');
        break;
      case PowerUpType.doublePoints:
        _activateDoublePoints();
        print('⚡ Double points activated!');
        break;
      case PowerUpType.health:
        _character?.heal(25);
        print('❤️ Health restored! Health: ${_character?.health}');
        break;
    }
  }

  // === تفعيل الباور أب ===
  void _activateShield() {
    _hasShield = true;
    _character?.activateShield(const Duration(seconds: 5)); // تفعيل الدرع في الشخصية
    _shieldTimer?.cancel();
    _shieldTimer = Timer(const Duration(seconds: 5), () {
      _hasShield = false;
      _character?.deactivateShield(); // إلغاء تفعيل الدرع من الشخصية
      print('🛡️ Shield expired');
    });
  }

  void _activateSlowMotion() {
    _isSlowMotion = true;
    _slowMotionTimer?.cancel();
    _slowMotionTimer = Timer(const Duration(seconds: 3), () {
      _isSlowMotion = false;
      print('🐌 Slow motion ended');
    });
  }

  void _activateDoublePoints() {
    _isDoublePoints = true;
    _doublePointsTimer?.cancel();
    _doublePointsTimer = Timer(const Duration(seconds: 10), () {
      _isDoublePoints = false;
      print('⚡ Double points ended');
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

  // === إدارة اللعبة ===
  void pauseGame() {
    _isGameRunning = false;
    _stopAllTimers();
    AudioService().stopBackgroundMusic();
    print('⏸️ Game paused');
  }

  void resumeGame() {
    if (!_isGameRunning && !_levelCompleted) {
      print('▶️ Game resumed');
      startGame();
    }
  }

  void _completeLevel() {
    print('🎉 Level completed! Score: $_score / Target: ${levelData.targetScore} / Time: $_timeElapsed seconds');
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
      print('🔓 Level ${levelData.levelNumber + 1} unlocked');
    }

    onLevelComplete?.call();
  }

  void _gameOver() {
    print('💀 Game over! Score: $_score / Time: $_timeElapsed seconds');
    _isGameRunning = false;
    _levelCompleted = false;
    _stopAllTimers();

    AudioService().playGameOverSound();
    AudioService().stopBackgroundMusic();
    VibrationService.vibrateGameOver();

    GameDataService.saveGameProgress(_score, levelData.levelNumber);

    Timer(const Duration(milliseconds: 100), () {
      onGameOver?.call();
    });
  }

  void _resetGameState() {
    _score = 0;
    _level = 1;
    _timeElapsed = 0;
    _gameTime = 0.0;
    _obstacles.clear();
    _enemies.clear();
    _powerUps.clear();
    _particles.clear();
    _backgroundManager.initialize();
    _bumpManager.bumps.clear();
    _character = Character(x: 0.2, y: 0.7);
    _levelCompleted = false;
    _showTutorialArrows = true;
    _isBossFight = false;
    _isBossDefeated = false;
    _currentBoss = null;

    // إعادة تعيين نظام الكومبو
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
    _startTutorialTimer();
    print('🔄 Game reset');
  }

  void _stopAllTimers() {
    _gameTimer?.cancel();
    _obstacleSpawnTimer?.cancel();
    _enemySpawnTimer?.cancel();
    _powerUpSpawnTimer?.cancel();
    _shieldTimer?.cancel();
    _slowMotionTimer?.cancel();
    _doublePointsTimer?.cancel();
    _comboTimer?.cancel();
    _levelTimer?.cancel();
    _tutorialTimer?.cancel();
  }

  // === المساعدات ===
  void _removeObstacles(List<Obstacle> obstaclesToRemove) {
    for (var obstacle in obstaclesToRemove) {
      _obstacles.remove(obstacle);
      _score += (10 * _comboMultiplier).toInt();
      _checkLevelUp();
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

  void _checkLevelUp() {
    final newLevel = (_score ~/ 200) + 1;
    if (newLevel > _level) {
      _level = newLevel;
      print('📈 Level up! Current level: $_level');
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
  Color _getRandomObstacleColor() {
    final colors = [Colors.red, Colors.orange, Colors.purple, Colors.brown, Colors.green, Colors.blue];
    return colors[_random.nextInt(colors.length)];
  }

  IconData _getRandomObstacleIcon() {
    final icons = [Icons.warning, Icons.block, Icons.dangerous, Icons.error, Icons.arrow_upward, Icons.arrow_downward];
    return icons[_random.nextInt(icons.length)];
  }

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

  // === التنظيف ===
  void dispose() {
    _stopAllTimers();
    AudioService().stopBackgroundMusic();
    _particles.clear();
    _character = null;
    print('🗑️ GameEngine disposed');
  }
}