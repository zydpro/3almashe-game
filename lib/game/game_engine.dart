import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../managers/enemy_manager.dart';
import '../models/Boss.dart';
import '../models/background_elements.dart';
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

  double get gameTime => _gameTime;

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
  double _gameTime = 0.0;
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
      jumpPower: -0.025,
      gravity: 0.001,
      weight: 1.0,
    );

    // ✅ ضبط حدود القفز
    _character!.setJumpBounds(0.3, 0.1);

    _backgroundManager.initialize();
    _initializePlatforms();
    _isInitialized = true;

    _startTutorialTimer();
    _startGroundTextTimer();
    // print('🎮 تم تهيئة محرك اللعبة - المستوى ${levelData.levelNumber}');
  }

  // ✅ تهيئة المنصات
  void _initializePlatforms() {
    _platforms.clear();

    // ✅ منصات أولية بمسافات مناسبة
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
      x: 1.8, // ✅ زيادة المسافة
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
      x: 2.5, // ✅ زيادة المسافة أكثر
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

    // print('🎯 Initialized ${_platforms.length} platforms with proper spacing');
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
    _groundTextTimer = Timer(const Duration(seconds: 15), () {
      _showGroundText = false;
      print('🌍 Ground text hidden after 15 seconds');
    });
  }

  void _startBossHintTimer() {
    _showBossAttackHint = true;
    _bossHintTimer = Timer(const Duration(seconds: 10), () {
      _showBossAttackHint = false;
    });
  }

  void startGame() {
    if (!_isInitialized) initialize();

    _resetGameState();
    _isGameRunning = true;
    _levelCompleted = false;

    print('🚀 Game Started - Level ${levelData.levelNumber}');
    // ✅ إعادة تهيئة المنصات للتأكد
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

      _timeElapsed++; // ✅ الآن يزيد كل ثانية واحدة

      double completionPercentage = (_score / levelData.targetScore).clamp(0.0, 1.0);

      // ✅ التحقق من ظهور الزعيم
      if (!_isBossFight && !_bossSpawned && completionPercentage >= 0.8) {
        _startBossFight();
        _bossSpawned = true;
      }

      // ✅ الإصلاح: تحقق من انتهاء الوقت فقط إذا لم تكن في معركة زعيم
      if (!_isBossFight && _timeElapsed >= _levelDuration) {
        print('⏰ الوقت انتهى! إكمال المستوى...');
        _completeLevel();
        timer.cancel();
      }

      // ✅ طباعة تشخيصية كل 10 ثواني
      if (_timeElapsed % 10 == 0) {
        print('⏱️ الوقت المتبقي: ${_levelDuration - _timeElapsed} ثانية | '
            'النقاط: $_score/${levelData.targetScore}');
      }
    });
  }

  void _checkBossAppearance() {
    if (_isBossFight || _bossSpawned) return;

    double completionPercentage = (_score / levelData.targetScore).clamp(0.0, 1.0);

    // ✅ الإصلاح: تأكد من مرور وقت كافٍ قبل ظهور الزعيم
    bool hasEnoughTimePassed = _gameTime > 30.0; // 30 ثانية على الأقل

    if (completionPercentage >= 0.8 && hasEnoughTimePassed) {
      _startBossFight();
      _bossSpawned = true;

      // print('🎯 الزعيم ظهر! النسبة: ${(completionPercentage * 100).toStringAsFixed(1)}%');
      // print('🎯 الوقت المنقضي: ${_gameTime.toStringAsFixed(1)} ثانية');
    }
  }

  void _startSpawners() {
    _obstacleSpawnTimer = Timer.periodic(
      const Duration(milliseconds: 800), // ✅ كل 1.2 ثانية
          (timer) {
        // print('⏰ Obstacle spawn timer triggered');
        _spawnObstacle();
      },
    );

    _enemySpawnTimer = Timer.periodic(
      const Duration(milliseconds: 2500), // ✅ كل 2 ثواني
          (timer) {
        // print('⏰ Enemy spawn timer triggered');
        _spawnEnemy();
      },
    );

    _powerUpSpawnTimer = Timer.periodic(
      const Duration(seconds: 20), // ✅ كل 15 ثواني
          (timer) {
        // print('⏰ PowerUp spawn timer triggered');
        _spawnPowerUp();
      },
    );

    // ✅ إضافة platformSpawnTimer المفقود
    _platformSpawnTimer = Timer.periodic(
      const Duration(seconds: 20), // ✅ كل 15 ثواني
          (timer) {
        // print('⏰ Platform spawn timer triggered');
        _spawnPlatform();
      },
    );
  }

// ✅ زيادة فرصة ظهور المنصات
  void _spawnPlatform() {
    if (!_isGameRunning || _levelCompleted || _character == null) return;

    // ✅ زيادة فرصة الظهور بناءً على عدد المنصات الحالية
    double spawnChance = 0.0;

    if (_platforms.length < 3) {
      spawnChance = 0.8; // ✅ فرصة عالية إذا كان هناك القليل من المنصات
    } else if (_platforms.length < 6) {
      spawnChance = 0.4; // ✅ فرصة متوسطة
    } else if (_platforms.length < 10) {
      spawnChance = 0.2; // ✅ فرصة منخفضة
    }

    // ✅ زيادة الفرصة مع المستوى
    if (_level >= 5) spawnChance += 0.1;
    if (_level >= 10) spawnChance += 0.1;

    if (_random.nextDouble() < spawnChance) {
      final platform = _createRandomPlatform();

      // ✅ التحقق من عدم تداخل المنصات مع بعضها
      bool isPositionValid = true;
      for (var existingPlatform in _platforms) {
        final distanceX = (platform.x - existingPlatform.x).abs();
        final distanceY = (platform.y - existingPlatform.y).abs();

        // ✅ مسافات أفقية وعمودية آمنة
        if (distanceX < 0.4 && distanceY < 0.15) {
          isPositionValid = false;
          break;
        }
      }

      if (isPositionValid) {
        _platforms.add(platform);
        // print('🧱 Spawned platform - '
        //     'Total: ${_platforms.length}, '
        //     'X: ${platform.x.toStringAsFixed(2)}, '
        //     'Y: ${platform.y.toStringAsFixed(2)}');
      }
    }
  }

  Obstacle _createRandomPlatform() {
    // ✅ دالة مساعدة للحصول على ارتفاعات متنوعة - جميعها أعلى من الأرض
    double getRandomPlatformHeight() {
      final heightTier = _random.nextDouble();

      if (heightTier < 0.25) {
        return 0.25 + _random.nextDouble() * 0.1; // ✅ عالية جداً: 0.25 - 0.35
      } else if (heightTier < 0.5) {
        return 0.35 + _random.nextDouble() * 0.1; // ✅ عالية: 0.35 - 0.45
      } else if (heightTier < 0.75) {
        return 0.45 + _random.nextDouble() * 0.1; // ✅ متوسطة: 0.45 - 0.55
      } else {
        return 0.55 + _random.nextDouble() * 0.1; // ✅ منخفضة: 0.55 - 0.65
      }
    }

    // ✅ أنواع المنصات المتنوعة مع ارتفاعات عشوائية
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
      {
        'width': 0.2,
        'height': 0.04,
        'y': getRandomPlatformHeight(),
        'speed': 0.025,
        'type': 'wide_platform'
      },
      {
        'width': 0.16,
        'height': 0.032,
        'y': getRandomPlatformHeight(),
        'speed': 0.06,
        'type': 'fast_platform'
      },
      // ✅ منصات خاصة للمستويات المتقدمة - أعلى
      {
        'width': 0.14,
        'height': 0.025,
        'y': 0.2 + _random.nextDouble() * 0.15, // ✅ عالية جداً: 0.2 - 0.35
        'speed': 0.035,
        'type': 'high_platform'
      },
      {
        'width': 0.22,
        'height': 0.045,
        'y': getRandomPlatformHeight(),
        'speed': 0.015,
        'type': 'mega_platform'
      },
      {
        'width': 0.1,
        'height': 0.028,
        'y': getRandomPlatformHeight(),
        'speed': 0.07,
        'type': 'small_fast_platform'
      },
      // ❌ إزالة المنصات الأرضية
      // {
      //   'width': 0.25,
      //   'height': 0.05,
      //   'y': 0.68 + _random.nextDouble() * 0.07, // ❌ منصات أرضية - محذوف
      //   'speed': 0.02,
      //   'type': 'ground_platform'
      // }
    ];

    final type = types[_random.nextInt(types.length)];
    final baseSpeed = type['speed'] as double;

    // ✅ تحديد اتجاه الحركة بشكل عشوائي
    double finalSpeed;
    if (_random.nextDouble() < 0.7) {
      // ✅ 70% تتحرك لليسار (سرعة موجبة)
      finalSpeed = baseSpeed;
    } else {
      // ✅ 30% تتحرك لليمين (سرعة سالبة) - أبطأ قليلاً
      finalSpeed = -baseSpeed * 0.8;
    }

    // ✅ منصات ثابتة في بعض الأحيان (10%)
    if (_random.nextDouble() < 0.1) {
      finalSpeed = 0.0;
    }

    // ✅ إضافة تغييرات سرعة إضافية بناءً على المستوى
    if (_level >= 5) {
      finalSpeed *= (1.0 + (_level * 0.02)); // ✅ زيادة السرعة مع المستوى
    }

    // ✅ تحديد موقع البداية بناءً على اتجاه الحركة
    double startX;
    if (finalSpeed > 0) {
      // ✅ تتحرك لليسار - تبدأ من اليمين
      startX = 1.1 + _random.nextDouble() * 0.3;
    } else if (finalSpeed < 0) {
      // ✅ تتحرك لليمين - تبدأ من اليسار
      startX = -0.2 - _random.nextDouble() * 0.3;
    } else {
      // ✅ ثابتة - تبدأ من مواقع متنوعة
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

// ✅ دالة مساعدة لألوان المنصات المختلفة
  Color _getPlatformColor(String platformType) {
    switch (platformType) {
      case 'high_platform':
        return Colors.brown.shade300; // ✅ فاتح للمنصات العالية
      case 'mega_platform':
        return Colors.brown.shade600; // ✅ داكن للمنصات الكبيرة
      case 'small_fast_platform':
        return Colors.orange.shade400; // ✅ برتقالي للمنصات السريعة
      case 'ground_platform':
        return Colors.brown.shade800; // ✅ بني داكن للمنصات الأرضية
      default:
        return Colors.brown.shade400; // ✅ اللون الأساسي
    }
  }

  // ✅ دالة لتصنيف ارتفاع المنصة
  String _getPlatformHeightCategory(double y) {
    if (y < 0.3) return "VERY HIGH";
    if (y < 0.4) return "HIGH";
    if (y < 0.5) return "MEDIUM-HIGH";
    if (y < 0.6) return "MEDIUM";
    return "LOW";
  }

// ✅ دالة لوصف حركة المنصة
  String _getPlatformMovementDescription(double speed) {
    if (speed == 0) return "🛑 STATIC";
    if (speed > 0.05) return "🚀 FAST LEFT";
    if (speed > 0) return "⬅️ LEFT";
    if (speed > -0.04) return "➡️ RIGHT";
    return "💨 FAST RIGHT";
  }

  // // ✅ إضافة دالة لفحص حالة المنصات
  // void _debugPlatforms() {
  //   if (_platforms.isNotEmpty) {
  //     print('🔍 PLATFORM DEBUG - Total: ${_platforms.length}');
  //     for (int i = 0; i < _platforms.length; i++) {
  //       final platform = _platforms[i];
  //       print('   Platform $i: X=${platform.x.toStringAsFixed(3)}, '
  //           'Y=${platform.y.toStringAsFixed(3)}, '
  //           'Speed=${platform.speed}, '
  //           'Width=${platform.width}, '
  //           'Height=${platform.height}');
  //     }
  //   } else {
  //     print('🔍 PLATFORM DEBUG: No platforms found');
  //   }
  // }

  // فحص حركة المنصة
  void _debugPlatformMovement() {
    if (_platforms.isNotEmpty && _gameTime % 1 < 0.016) {
      final platform = _platforms.first;
      print('🔍 PLATFORM MOVEMENT DEBUG:');
      print('   - Game Time: ${_gameTime.toStringAsFixed(2)}s');
      print('   - Platform X: ${platform.x.toStringAsFixed(3)}');
      print('   - Platform Speed: ${platform.speed}');
      print('   - Platform Count: ${_platforms.length}');
      print('   - Game Running: $_isGameRunning');
      print('   - Update Called: ✅');
    }
  }

  void _forceReinitializePlatforms() {
    print('🔄 FORCE REINITIALIZING PLATFORMS');
    _platforms.clear();
    _initializePlatforms();

    // تحقق من المنصات الجديدة
    for (int i = 0; i < _platforms.length; i++) {
      final platform = _platforms[i];
      print('   New Platform $i: X=${platform.x.toStringAsFixed(3)}, '
          'Speed=${platform.speed}, '
          'Moving: ${platform.speed > 0}');
    }
  }

// ✅ جعلها public للوصول من GameScreen
  void forceReinitializePlatforms() {
    _forceReinitializePlatforms();
  }

// ✅ جعلها public للوصول من GameScreen
//   void debugPlatforms() {
//     _debugPlatforms();
//   }

  // === معركة الزعيم ===
  void _startBossFight() {
    if (_isBossFight || _bossSpawned) return;

    _isBossFight = true;
    _bossSpawned = true;
    _bossFightStartTime = _gameTime;
    _preBossScore = _score;
    _currentBoss = _createBossForLevel(levelData.levelNumber);

    // ✅ إيقاف توليد المنصات فقط أثناء معركة الزعيم
    _platformSpawnTimer?.cancel();

    _startBossHintTimer();

    AudioService().playBossMusic();
    print('👹 Boss fight started! Level ${levelData.levelNumber}');
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
      final rareIndex = _getRareBossIndex(level);
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

  // ✅ دالة مساعدة للحصول على صورة الزعيم
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

  int _getRareBossIndex(int level) {
    final rareLevels = [15, 25, 50, 75, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99];
    return rareLevels.indexOf(level) % 5;
  }

  // === تحديث اللعبة ===
  void _updateGame() {
    if (!_isGameRunning || _character == null) return;

    _gameTime += 0.016;

    // ✅ طباعة تشخيصية كل 5 ثواني
    if (_gameTime % 5 < 0.016 && !_isBossFight) {
      double completion = (_score / levelData.targetScore).clamp(0.0, 1.0);
      print('📊 [تشخيص] النسبة: ${(completion * 100).toStringAsFixed(1)}% | '
          'الوقت: ${_gameTime.toStringAsFixed(1)}s | '
          'النقاط: $_score/${levelData.targetScore}');
    }

    // ✅ الإصلاح: تحقق من نهاية اللعبة هنا
    if (_character!.isDead || _isBossDefeated) {
      if (_character!.isDead) {
        _gameOver();
      } else if (_isBossDefeated) {
        _completeLevel();
      }
      return;
    }

    // ✅ تحديث وقت EnemyManager للحركات التموجية
    _enemyManager.updateGameTime(0.016);

    if (!_isBossFight && !_bossSpawned) {
      _checkBossAppearance();
    }

    _updateCharacter();
    _backgroundManager.update();
    _bumpManager.update();
    _updateParticles();
    _updatePlatforms();
    _updateObstacles();
    _updateEnemies();
    _updatePowerUps();
    _debugPlatformMovement();

    // ✅ إضافة هذا السطر: التحقق من القفز على الـ brick
    _checkBrickJumping();

    if (_gameTime % 5 < 0.016 && _enemies.isNotEmpty) {
      _debugEnemies();
    }

    if (_isBossFight) {
      _updateBoss();
    }

    _updateChallenges();
    _checkLevelCompletion();
  }

  // ✅ دالة لفحص الأعداء
  void _debugEnemies() {
    if (_enemies.isEmpty) {
      print('🔍 No enemies to debug');
      return;
    }

    print('🔍 Enemy Debug - Total: ${_enemies.length}');
    int flyingCount = 0;
    int groundCount = 0;

    for (var enemy in _enemies) {
      final name = _enemyManager.getEnemyName(enemy);
      final isFlying = enemy.type == ObstacleType.flyingEnemy;

      if (isFlying) flyingCount++;
      else groundCount++;

      print('   - $name: '
          'X=${enemy.x.toStringAsFixed(2)}, '
          'Y=${enemy.y.toStringAsFixed(2)}, '
          'Health: ${enemy.health}');
    }

    print('   📊 Summary: $flyingCount flying, $groundCount ground');
  }

  void _updateCharacter() {
    _character!.update();
    _checkPlatformCollisions();
    _enforceScreenBounds();

    // ✅ إضافة التشخيص هنا
    _debugCharacterState();
  }

  // ✅ دالة تشخيصية لحالة الشخصية
  // ✅ دالة تشخيصية محسنة
  void _debugCharacterState() {
    // طباعة كل 5 ثواني فقط لتجنب spam
    if (_gameTime % 5 < 0.016) {
      final character = _character!;

      // ✅ تشخيص القفز - باستخدام الـ getters العامة
      if (character.isJumping) {
        print('🦘 حالة القفز - '
            'الارتفاع: ${character.y.toStringAsFixed(3)}, '
            'السرعة: ${character.velocityY.toStringAsFixed(4)}, '
            'الحد الأقصى: ${character.currentMaxJumpHeight.toStringAsFixed(3)}');
      }

      // ✅ تشخيص المنصات - باستخدام الـ getters العامة
      if (character.isOnPlatform) {
        print('🧱 على منصة - '
            'Y: ${character.y.toStringAsFixed(3)}, '
            'منصة Y: ${character.platformY?.toStringAsFixed(3)}');
      }

      // ✅ تشخيص الحركة - باستخدام الـ getters العامة
      if (character.isMovingLeft || character.isMovingRight) {
        final direction = character.isMovingLeft ? 'يسار' : 'يمين';
        print('🏃 يتحرك $direction - '
            'السرعة: ${character.moveSpeed.toStringAsFixed(4)}');
      }

      // ✅ تشخيص الحدود
      if (character.x <= 0.06 || character.x >= 0.94) {
        print('🚫 قريب من الحدود الأفقية - X: ${character.x.toStringAsFixed(3)}');
      }
      if (character.y <= 0.11 || character.y >= 0.84) {
        print('🚫 قريب من الحدود الرأسية - Y: ${character.y.toStringAsFixed(3)}');
      }

      // ✅ طباعة ملخص كل 15 ثانية
      if (_gameTime % 15 < 0.016) {
        print('📊 ملخص الشخصية - '
            'الصحة: ${character.health}, '
            'الأرواح: ${character.lives}, '
            'الدرع: ${character.hasShield}, '
            'المنيع: ${character.isInvincible}');
      }
    }
  }

  // ✅ دالة لفحص حالة الشخصية يمكن استدعاؤها من الخارج
  void debugCharacter() {
    if (_character != null) {
      print('🔍 فحص مفصل للشخصية:');
      print('   - الموقع: (${_character!.x.toStringAsFixed(3)}, ${_character!.y.toStringAsFixed(3)})');
      print('   - القفز: ${_character!.isJumping}');
      print('   - على منصة: ${_character!.isOnPlatform}');
      print('   - ارتفاع المنصة: ${_character!.platformY?.toStringAsFixed(3)}');
      print('   - السرعة الرأسية: ${_character!.velocityY.toStringAsFixed(4)}');
      print('   - الحد الأقصى للقفزة: ${_character!.currentMaxJumpHeight.toStringAsFixed(3)}');
      print('   - الصحة: ${_character!.health}');
      print('   - الأرواح: ${_character!.lives}');
    }
  }

  // ✅ دالة لفرض حدود الشاشة
  void _enforceScreenBounds() {
    if (_character == null) return;

    // ✅ حدود أفقية
    _character!.x = _character!.x.clamp(0.05, 0.95);

    // ✅ حدود رأسية
    final double minY = 0.1;
    final double maxY = 0.85;

    if (_character!.y < minY) {
      _character!.y = minY;
      _character!.velocityY = 0.0;
      print('🚫 وصل للحد العلوي: ${_character!.y.toStringAsFixed(3)}');
    }

    if (_character!.y > maxY) {
      _character!.y = maxY;
      _character!.velocityY = 0.0;
      print('🚫 وصل للحد السفلي: ${_character!.y.toStringAsFixed(3)}');
    }
  }

  // ✅ تحديث المنصات
  void _updatePlatforms() {
    final platformsToRemove = <Obstacle>[];

    for (var platform in _platforms) {
      platform.move(); // ✅ الحركة تعمل

      // ✅ تحسين شرط الخروج - إزالة أكثر مرونة
      bool shouldRemove = false;

      if (platform.speed > 0) {
        // ✅ تتحرك لليسار - تختفي عندما تخرج تماماً من الشاشة
        shouldRemove = platform.x < -platform.width;
      } else if (platform.speed < 0) {
        // ✅ تتحرك لليمين - تختفي عندما تخرج تماماً من الشاشة
        shouldRemove = platform.x > 1.0 + platform.width;
      } else {
        // ✅ ثابتة - تبقى لفترة أطول
        shouldRemove = platform.x < -0.5;
      }

      if (shouldRemove) {
        platformsToRemove.add(platform);
        // print('🗑️ Platform removed - X: ${platform.x.toStringAsFixed(2)}');
      }
    }

    _removePlatforms(platformsToRemove);

    // ✅ إضافة منصات جديدة بدلاً من الاستبدال فقط عند الإزالة
    if (platformsToRemove.isNotEmpty) {
      // print('🔄 Replacing ${platformsToRemove.length} platforms');
      _addNewPlatforms(platformsToRemove.length);
    }
  }

// ✅ دالة جديدة لإضافة منصات بدلاً من الاستبدال
  void _addNewPlatforms(int count) {
    for (int i = 0; i < count; i++) {
      if (_platforms.length < 10) { // ✅ زيادة الحد الأقصى
        final newPlatform = _createRandomPlatform();
        _platforms.add(newPlatform);

        // print('🧱 Added new platform - '
        //     'X: ${newPlatform.x.toStringAsFixed(2)}, '
        //     'Y: ${newPlatform.y.toStringAsFixed(2)}');
      }
    }
  }

// ✅ توليد منصات بديلة - مدمجة
  void _spawnReplacementPlatforms(int count) {
    // print('🔄 SPAWNING $count NEW FAST PLATFORMS');

    for (int i = 0; i < count; i++) {
      if (_platforms.length < 8) {
        final newPlatform = _createRandomPlatform();
        _platforms.add(newPlatform);

        // ✅ تحديد نوع الحركة بناءً على السرعة
        String movementType = newPlatform.speed > 0 ? "FAST ← LEFT" : "SLOW → RIGHT";
        String emoji = newPlatform.speed > 0 ? "🚀" : "🐢";

        // print('$emoji Platform ${i + 1}: '
        //     'X=${newPlatform.x.toStringAsFixed(3)}, '
        //     'Y=${newPlatform.y.toStringAsFixed(3)}, '
        //     'Speed=${newPlatform.speed}, '
        //     'Movement=$movementType');
      }
    }

    print('📊 Total platforms now: ${_platforms.length}');
  }

  // ✅ التحقق من الاصطدام مع المنصات - الإصلاح الرئيسي
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

  // ✅ التحقق من اكتمال المرحلة - الإصلاح الرئيسي
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

      // ✅ تحسين شرط الخروج للعقبات
      if (obstacle.isOffScreen() || obstacle.x < -0.4) {
        obstaclesToRemove.add(obstacle);
        _obstaclesAvoided++;

        // ✅ الإصلاح: لا تضيف نقاط أثناء معركة الزعيم
        if (obstacle.speed > 0 && !_isBossFight) {
          _score += (10 * _comboMultiplier).toInt();
          _checkLevelUp();
        }
      }
    }

    _removeObstacles(obstaclesToRemove);
  }

  void _updateEnemyMovement(Obstacle enemy) {
    // ✅ إذا كان عدو طائر (في السماء)
    if (enemy.y < 0.7 && enemy.imagePath == ImageService.enemyFlying) {
      // ✅ حركة تموجية للطيران
      final time = _gameTime * 2; // ✅ سرعة التموج
      final wave = sin(time + enemy.x * 10) * 0.02; // ✅ حركة تموجية

      enemy.y = enemy.y + wave * 0.016; // ✅ تحديث الموقع العمودي

      // ✅ طباعة للت debug (يمكن إزالتها لاحقاً)
      if (_gameTime % 5 < 0.016) {
        print('🦅 Flying enemy - Y: ${enemy.y.toStringAsFixed(3)}, Wave: ${wave.toStringAsFixed(3)}');
      }
    }
  }

  // ✅ إضافة زر لفرض ظهور أعداء
  void debugSpawnMultipleEnemies() {
    int spawnedCount = 0;
    for (int i = 0; i < 3; i++) {
      if (_random.nextDouble() < 0.8) {
        final enemy = _enemyManager.createRandomEnemy(
            _isSlowMotion ? levelData.obstacleSpeed * 0.5 : levelData.obstacleSpeed,
            _level
        );
        _enemies.add(enemy);
        spawnedCount++;

        final enemyName = _enemyManager.getEnemyName(enemy);
        // print('👹 DEBUG: Spawned $enemyName');
      }
    }
    // print('👹 DEBUG: Spawned $spawnedCount random enemies');
  }

// ✅ إضافة زر لاختبار العدو الطائر في ارتفاعات مختلفة
  void debugSpawnFlyingEnemy() {
    final flyingEnemy = _enemyManager.createFlyingEnemy(
        _isSlowMotion ? levelData.obstacleSpeed * 0.5 : levelData.obstacleSpeed,
        _level
    );
    _enemies.add(flyingEnemy);

    // ✅ الحصول على اسم المنطقة بناءً على الارتفاع
    String zoneName = 'غير معروف';
    if (flyingEnemy.y < 0.45) zoneName = 'منخفض';
    else if (flyingEnemy.y < 0.65) zoneName = 'متوسط';
    else zoneName = 'مرتفع';

    print('🦅 DEBUG: spawned flying enemy at '
        'X: ${flyingEnemy.x.toStringAsFixed(2)}, '
        'Y: ${flyingEnemy.y.toStringAsFixed(2)}, '
        'المنطقة: $zoneName, '
        'Level: $_level');
  }

  // ✅ دالة لفحص الأعداء الطائرين
  void debugFlyingEnemies() {
    if (_enemies.isEmpty) {
      print('🔍 No flying enemies to debug');
      return;
    }

    int lowFlying = 0;
    int midFlying = 0;
    int highFlying = 0;

    for (var enemy in _enemies) {
      if (enemy.type == ObstacleType.flyingEnemy) {
        if (enemy.y < 0.45) lowFlying++;
        else if (enemy.y < 0.65) midFlying++;
        else highFlying++;
      }
    }

    print('🦅 Flying Enemy Debug:');
    print('   - المنخفض: $lowFlying');
    print('   - المتوسط: $midFlying');
    print('   - المرتفع: $highFlying');
    print('   - الإجمالي: ${lowFlying + midFlying + highFlying}');
  }


  void _updateEnemies() {
    final enemiesToRemove = <Obstacle>[];

    _enemyManager.updateEnemies(_enemies, _character!.x, _character!.y);

    for (var enemy in _enemies) {
      // ✅ تحديث حركة خاصة للطائرين
      if (enemy.type == ObstacleType.flyingEnemy) {
        _updateFlyingEnemyMovement(enemy);
      }

      enemy.move();

      // ✅ الإصلاح: التحقق من القفز على رأس العدو فقط
      if (_isCharacterJumpingOnEnemy(_character!, enemy)) {
        _defeatEnemy(enemy, enemiesToRemove);
      }
      else if (_checkCollision(_character!, enemy)) {
        _handleEnemyCollision(enemy);
      }

      if (enemy.isOffScreen()) {
        enemiesToRemove.add(enemy);
        final enemyName = _enemyManager.getEnemyName(enemy);
        final enemyType = enemy.type == ObstacleType.flyingEnemy ? "FLYING" : "GROUND";
        // print('🗑️ $enemyType enemy removed - $enemyName at X: ${enemy.x.toStringAsFixed(2)}');
      }

      _enemyManager.checkPackageCollisions(_character!.packages, _enemies);
    }

    _removeEnemies(enemiesToRemove);
    _enemyManager.cleanupEnemies(_enemies);
  }

  // ✅ دالة جديدة لتحريك العدو الطائر
  void _updateFlyingEnemyMovement(Obstacle enemy) {
    if (enemy.type == ObstacleType.flyingEnemy) {
      // حركة تموجية إضافية للطائرين
      final wave = sin(_gameTime * 3 + enemy.x * 6) * 0.015;
      enemy.y = (enemy.y + wave).clamp(0.25, 0.6);

      // ✅ زيادة السرعة قليلاً للطائرين
      enemy.speed *= 1.1;

      // ✅ طباعة حركة الطائر (للـ debug)
      if (_gameTime % 3 < 0.016) {
        // print('🦅 Flying enemy moving - Y: ${enemy.y.toStringAsFixed(3)}, Speed: ${enemy.speed.toStringAsFixed(3)}');
      }
    }
  }

  // ✅ دالة جديدة للتحقق من القفز على رأس العدو
  bool _isCharacterJumpingOnEnemy(Character character, Obstacle enemy) {
    if (!enemy.isEnemy) return false;

    final characterBottom = character.y;
    final enemyTop = enemy.y - enemy.height / 2;
    final characterTop = character.y - character.height;

    // ✅ تحديد منطقة رأس العدو (الجزء العلوي فقط)
    final headRegionTop = enemyTop;
    final headRegionBottom = enemyTop + enemy.height * 0.3; // 30% العلوية فقط

    final horizontalOverlap = (character.x + character.width/2) > (enemy.x - enemy.width/2) &&
        (character.x - character.width/2) < (enemy.x + enemy.width/2);

    // ✅ الشروط الجديدة:
    // 1. يجب أن يكون اللاعب فوق العدو
    // 2. يجب أن يكون اللاعب يسقط (سرعة إيجابية)
    // 3. يجب أن يكون الجزء السفلي من اللاعب في منطقة رأس العدو
    // 4. يجب ألا يكون اللاعب مرتفعاً جداً فوق العدو
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

    if (isJumpingOnHead) {
      print('🎯 Jumping on enemy head - '
          'Character Bottom: ${characterBottom.toStringAsFixed(3)}, '
          'Enemy Top: ${enemyTop.toStringAsFixed(3)}, '
          'Head Region: ${headRegionTop.toStringAsFixed(3)}-${headRegionBottom.toStringAsFixed(3)}, '
          'Velocity Y: ${character.velocityY.toStringAsFixed(4)}');
    }

    return isJumpingOnHead;
  }

  // ✅ دالة خاصة لتحريك العدو الطائر
  void _updateFlyingEnemy(Obstacle enemy) {
    // حركة تموجية إضافية
    final wave = sin(_gameTime * 4 + enemy.x * 8) * 0.01;
    enemy.y = (enemy.y + wave).clamp(0.3, 0.75);

    // ✅ طباعة حركة الطائر (للـ debug)
    if (_gameTime % 2 < 0.016) {
      print('🦅 Flying enemy moving - Y: ${enemy.y.toStringAsFixed(3)}');
    }
  }

  // ✅ التحقق من القفز على عقبات الـ brick
  void _checkBrickJumping() {
    if (_character == null || !_character!.isJumping) return;

    for (var obstacle in _obstacles) {
      // ✅ التحقق إذا كانت العقبة من نوع brick
      if (_isBrickObstacle(obstacle) && _isCharacterJumpingOnBrick(_character!, obstacle)) {
        _handleBrickJump(obstacle);
        break;
      }
    }
  }

// ✅ التحقق إذا كانت العقبة من نوع brick
  bool _isBrickObstacle(Obstacle obstacle) {
    // ✅ يمكن التعرف على الـ brick باللون أو النوع أو الصورة
    return obstacle.color == Colors.brown ||
        obstacle.color == Colors.orange ||
        obstacle.imagePath == ImageService.brick ||
        obstacle.type == ObstacleType.groundLong; // أو أي معيار آخر
  }

// ✅ التحقق إذا كانت الشخصية تقفز على الـ brick
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

    if (isJumpingOnBrick) {
      print('🧱 Jumping on BRICK - '
          'Character Bottom: ${characterBottom.toStringAsFixed(3)}, '
          'Brick Top: ${brickTop.toStringAsFixed(3)}, '
          'Velocity Y: ${character.velocityY.toStringAsFixed(4)}');
    }

    return isJumpingOnBrick;
  }

// ✅ معالجة القفز على الـ brick
  void _handleBrickJump(Obstacle brick) {
    // ✅ إيقاف سقوط الشخصية
    _character!.velocityY = 0.0;
    _character!.isJumping = false;

    // ✅ وضع الشخصية فوق الـ brick
    _character!.y = (brick.y - brick.height / 2) - _character!.height;

    // ✅ إضافة نقاط للقفز على الـ brick
    final brickPoints = 20;
    _score += (brickPoints * _comboMultiplier).toInt();

    _createJumpParticles(_character!.x, _character!.y);
    AudioService().playJumpSound();
    VibrationService.vibrateSuccess();

    // ✅ إزالة الـ brick بعد القفز عليه (اختياري)
    _obstacles.remove(brick);

    print('🧱 Brick jump successful! +$brickPoints points - Brick removed');
  }

  // ✅ دالة مساعدة للتعرف على الـ brick
  bool _isBrick(Obstacle obstacle) {
    // ✅ عدة طرق للتعرف على الـ brick
    return obstacle.color == Colors.brown ||
        obstacle.imagePath == ImageService.brick ||
        obstacle.type == ObstacleType.groundLong && obstacle.width >= 0.12;
  }

  // ✅ إنشاء جسيمات خاصة للـ brick
  void _createBrickBreakParticles(double x, double y) {
    final particles = <GameParticle>[];

    for (int i = 0; i < 8; i++) {
      particles.add(GameParticle(
        x: x,
        y: y,
        vx: (_random.nextDouble() - 0.5) * 0.04,
        vy: -_random.nextDouble() * 0.06 - 0.02,
        life: 0.8 + _random.nextDouble() * 0.4,
        maxLife: 1.2,
        color: Colors.brown,
        size: 2.0 + _random.nextDouble() * 3.0,
      ));
    }

    _particles.addAll(particles);
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
    if (_isBossDefeated) return; // ✅ منع التكرار

    _isBossDefeated = true;
    _isBossFight = false;

    final bossScore = (levelData.targetScore * 0.3).toInt();
    _score = _preBossScore + bossScore;

    _createVictoryParticles();
    AudioService().playBossDefeatSound();

    print('🎉 Boss defeated! +$bossScore points - Total: $_score');

    // ✅ الإصلاح: استدعاء مباشر لإكمال المرحلة
    _completeLevel();

    onBossDefeated?.call();
  }

  void _defeatEnemy(Obstacle enemy, List<Obstacle> enemiesToRemove) {
    enemiesToRemove.add(enemy);
    _enemiesDefeated++;

    // ✅ الإصلاح: إضافة النقاط فقط عند هزيمة العدو بالقفز على رأسه
    final points = _enemyManager.getEnemyPoints(enemy) * _comboMultiplier.toInt();
    _score += points;

    _activateCombo();
    _createEnemyDefeatParticles(enemy.x, enemy.y);
    AudioService().playEnemyDieSound();
    VibrationService.vibrateSuccess();

    print('💀 ${_enemyManager.getEnemyName(enemy)} defeated! +$points points');
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
      powerUp.move(); // ✅ تأكد من تحريك الباور أب

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

    // ✅ زيادة فرصة الظهور بناءً على عدد العقبات الحالية
    double spawnChance = 0.0;

    if (_obstacles.length < 2) {
      spawnChance = 0.9; // ✅ فرصة عالية إذا كان هناك القليل من العقبات
    } else if (_obstacles.length < 5) {
      spawnChance = 0.7; // ✅ فرصة متوسطة
    } else if (_obstacles.length < 8) {
      spawnChance = 0.4; // ✅ فرصة منخفضة
    }

    if (_random.nextDouble() < spawnChance) {
      // ✅ التحقق من المسافة بين العقبات
      if (_obstacles.isNotEmpty) {
        final lastObstacle = _obstacles.last;
        final distanceFromLast = 1.1 - lastObstacle.x;

        // ✅ انتظر حتى تبتعد العقبة السابقة مسافة كافية
        if (distanceFromLast < 0.4) { // ✅ زيادة المسافة إلى 40%
          return;
        }
      }

      final obstacle = _createRandomObstacle(speed);
      _obstacles.add(obstacle);
      // print('🚧 Spawned obstacle - Total: ${_obstacles.length}');
    }

    if (_random.nextDouble() < 0.4) {
      _bumpManager.spawnBump();
    }
  }

  Obstacle _createRandomObstacle(double speed) {
    final obstacleType = _random.nextDouble();
    double yPosition, width, height;
    ObstacleType type;
    String? imagePath; // ✅ إضافة imagePath

    // ✅ دالة مساعدة للحصول على ارتفاع عشوائي مع تجنب المنصات
    double getRandomSkyHeight() {
      final heightTier = _random.nextDouble();

      if (heightTier < 0.25) {
        return 0.25 + _random.nextDouble() * 0.1; // ✅ عالي جداً: 0.25 - 0.35
      } else if (heightTier < 0.5) {
        return 0.35 + _random.nextDouble() * 0.1; // ✅ عالي: 0.35 - 0.45
      } else if (heightTier < 0.75) {
        return 0.45 + _random.nextDouble() * 0.15; // ✅ متوسط: 0.45 - 0.6
      } else {
        return 0.55 + _random.nextDouble() * 0.1; // ✅ منخفض: 0.55 - 0.65
      }
    }

    // ✅ تحديد نوع العقبة (Brick أو Pipe)
    bool isBrick = _random.nextDouble() < 0.5; // ✅ 50% لكل نوع

    if (obstacleType < 0.2) { // ✅ 20% عقبات أرضية
      yPosition = 0.75;
      if (isBrick) {
        width = 0.12;
        height = 0.12;
        type = ObstacleType.groundLong;
        imagePath = ImageService.brick; // ✅ Brick
      } else {
        width = 0.1;
        height = 0.15;
        type = ObstacleType.groundLong;
        imagePath = ImageService.pipe; // ✅ Pipe
      }
    } else if (obstacleType < 0.4) { // ✅ 20% عقبات متوسطة
      yPosition = getRandomSkyHeight();
      if (isBrick) {
        width = 0.08;
        height = 0.08;
        type = ObstacleType.skyLong;
        imagePath = ImageService.brick; // ✅ Brick
      } else {
        width = 0.07;
        height = 0.12;
        type = ObstacleType.skyLong;
        imagePath = ImageService.pipe; // ✅ Pipe
      }
    } else if (obstacleType < 0.6) { // ✅ 20% عقبات صغيرة
      yPosition = getRandomSkyHeight();
      if (isBrick) {
        width = 0.06;
        height = 0.06;
        type = ObstacleType.skyShort;
        imagePath = ImageService.brick; // ✅ Brick
      } else {
        width = 0.05;
        height = 0.1;
        type = ObstacleType.skyShort;
        imagePath = ImageService.pipe; // ✅ Pipe
      }
    } else if (obstacleType < 0.8) { // ✅ 20% عقبات عريضة
      yPosition = getRandomSkyHeight();
      if (isBrick) {
        width = 0.15;
        height = 0.08;
        type = ObstacleType.skyWide;
        imagePath = ImageService.brick; // ✅ Brick
      } else {
        width = 0.12;
        height = 0.18;
        type = ObstacleType.skyWide;
        imagePath = ImageService.pipe; // ✅ Pipe
      }
    } else { // ✅ 20% عقبات خاصة
      yPosition = getRandomSkyHeight();
      if (isBrick) {
        width = 0.1;
        height = 0.1;
        type = ObstacleType.skyLong;
        imagePath = ImageService.brick; // ✅ Brick
      } else {
        width = 0.08;
        height = 0.14;
        type = ObstacleType.skyLong;
        imagePath = ImageService.pipe; // ✅ Pipe
      }
    }

    // ✅ التأكد من أن الموضع آمن (تجنب المنصات)
    bool isPositionSafe(double testY, double testHeight) {
      for (var platform in _platforms) {
        final platformTop = platform.y - platform.height / 2;
        final platformBottom = platform.y + platform.height / 2;
        final obstacleTop = testY - testHeight / 2;
        final obstacleBottom = testY + testHeight / 2;

        // ✅ التحقق من التداخل الرأسي
        if ((obstacleBottom >= platformTop && obstacleTop <= platformBottom)) {
          return false; // ❌ يوجد تداخل مع منصة
        }
      }
      return true; // ✅ الموضع آمن
    }

    // ✅ التحقق من السلامة وإعادة تعيين الارتفاع إذا لزم الأمر
    if (!isPositionSafe(yPosition, height)) {
      yPosition = getRandomSkyHeight(); // ✅ ارتفاع بديل
    }

    // ✅ إضافة تنوع إضافي بناءً على المستوى
    if (_level >= 10 && _random.nextDouble() < 0.2) {
      // ✅ عقبات صعبة للمستويات المتقدمة
      yPosition = 0.3 + _random.nextDouble() * 0.2;
      width *= 0.8; // ✅ أصغر حجماً
      height *= 0.8;
    }

    return Obstacle(
      x: 1.1,
      y: yPosition,
      speed: speed,
      width: width,
      height: height,
      color: isBrick ? Colors.brown : Colors.green, // ✅ ألوان مختلفة
      icon: _getRandomObstacleIcon(),
      type: type,
      imagePath: imagePath, // ✅ تعيين imagePath
    );
  }

  // ✅ دالة مساعدة للحصول على ارتفاعات متنوعة
  double _getRandomSkyHeight() {
    final heightType = _random.nextDouble();

    if (heightType < 0.25) {
      return 0.25 + _random.nextDouble() * 0.1; // ✅ عالي جداً: 0.25 - 0.35
    } else if (heightType < 0.5) {
      return 0.35 + _random.nextDouble() * 0.1; // ✅ عالي: 0.35 - 0.45
    } else if (heightType < 0.75) {
      return 0.45 + _random.nextDouble() * 0.15; // ✅ متوسط: 0.45 - 0.6
    } else {
      return 0.55 + _random.nextDouble() * 0.1; // ✅ منخفض: 0.55 - 0.65
    }
  }

  // === توليد الأعداء ===
  void _spawnEnemy() {
    if (!_isGameRunning || _levelCompleted || _character == null) return;

    // ✅ زيادة فرصة ظهور الأعداء الطائرين في المستويات المتقدمة
    double flyingEnemyChance = 0.3; // ✅ 30% فرصة أساسية للطائرين
    if (_level >= 5) flyingEnemyChance = 0.5;
    if (_level >= 10) flyingEnemyChance = 0.7;

    if (_random.nextDouble() < 0.8) {
      final bool spawnFlyingEnemy = _random.nextDouble() < flyingEnemyChance;

      Obstacle enemy;
      if (spawnFlyingEnemy) {
        // ✅ إنشاء عدو طائر
        enemy = _enemyManager.createFlyingEnemy(
            _isSlowMotion ? levelData.obstacleSpeed * 0.5 : levelData.obstacleSpeed,
            _level
        );

        // ✅ تعديل ارتفاع العدو الطائر ليكون في مواقع متنوعة
        final heightType = _random.nextDouble();
        if (heightType < 0.33) {
          enemy.y = 0.3 + _random.nextDouble() * 0.1; // ✅ منخفض: 0.3 - 0.4
        } else if (heightType < 0.66) {
          enemy.y = 0.4 + _random.nextDouble() * 0.15; // ✅ متوسط: 0.4 - 0.55
        } else {
          enemy.y = 0.25 + _random.nextDouble() * 0.1; // ✅ عالي: 0.25 - 0.35
        }

        // print('🦅 Flying enemy spawned at Y: ${enemy.y.toStringAsFixed(2)}');
      } else {
        // ✅ إنشاء عدو أرضي
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

    // ✅ زيادة فرصة الظهور إلى 60%
    if (_random.nextDouble() < 0.6) {
      final yPosition = 0.4 + _random.nextDouble() * 0.4;
      final type = PowerUpType.values[_random.nextInt(PowerUpType.values.length)];

      final powerUp = PowerUp(
        x: 1.1, // ✅ تبدأ من اليمين كالمعتاد
        y: yPosition,
        type: type,
        width: 0.06,
        height: 0.06,
        speed: 0.015,
        color: _getPowerUpColor(type),
        icon: _getPowerUpIcon(type),
      );

      _powerUps.add(powerUp);
      // print('⭐ spawned powerup at x: ${powerUp.x.toStringAsFixed(2)}');
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

  // === إدارة اللعبة ===
  void pauseGame() {
    if (!_isGameRunning) return;

    _isGameRunning = false;
    _stopAllTimers(); // ✅ هذه الدالة موجودة بالفعل

    // print('⏸️ Game paused - Score: $_score, Health: ${_character?.health}');
  }

  void resumeGame() {
    if (_isGameRunning || _levelCompleted) return;

    _isGameRunning = true;
    _startGameLoop(); // ✅ هذه الدالة موجودة بالفعل
    _startSpawners(); // ✅ هذه الدالة موجودة بالفعل

    // print('▶️ Game resumed - Score: $_score, Health: ${_character?.health}');
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
    // ✅ منع الاستدعاء المزدوج بشكل أكثر فعالية
    if (!_isGameRunning || _levelCompleted) return;

    print('🎮 Game Over triggered - Score: $_score, Level: ${levelData.levelNumber}');

    _isGameRunning = false;
    _levelCompleted = false;
    _stopAllTimers();

    // ✅ إيقاف جميع المؤثرات الصوتية بشكل آمن
    try {
      AudioService().playGameOverSound();
      AudioService().stopBackgroundMusic();
    } catch (e) {
      print('❌ Audio error in gameOver: $e');
    }

    // ✅ الاهتزاز مع معالجة الأخطاء
    try {
      VibrationService.vibrateGameOver();
    } catch (e) {
      print('❌ Vibration error: $e');
    }

    // ✅ حفظ التقدم بشكل غير متزامن
    _saveGameProgress();

    // ✅ استدعاء callback بعد التأكد من اكتمال التحديثات
    _callGameOverCallback();
  }

  void _callGameOverCallback() {
    // ✅ استخدام addPostFrameCallback لأمان أكثر
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (onGameOver != null) {
        try {
          onGameOver!();
          print('✅ GameOver callback executed successfully');
        } catch (e) {
          print('❌ Error in GameOver callback: $e');
        }
      } else {
        print('⚠️ GameOver callback is null');
      }
    });
  }

  void _saveGameProgress() async {
    try {
      await GameDataService.saveGameProgress(_score, levelData.levelNumber);
      print('💾 Game progress saved successfully');
    } catch (e) {
      print('❌ Error saving game progress: $e');
    }
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
  }

  // === المساعدات ===
  void _removeObstacles(List<Obstacle> obstaclesToRemove) {
    for (var obstacle in obstaclesToRemove) {
      _obstacles.remove(obstacle);
      // ✅ الإصلاح: لا تضيف نقاط أثناء معركة الزعيم
      if (!_isBossFight) { // ⚠️ أضف هذا الشرط!
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