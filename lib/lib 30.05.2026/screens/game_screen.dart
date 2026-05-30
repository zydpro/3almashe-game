import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../Languages/localization.dart';
import '../game/game_engine.dart';
import '../models/Boss.dart';
import '../models/attack.dart';
import '../models/background_elements.dart';
import '../models/enums.dart';
import '../models/obstacle.dart';
import '../services/game_data_service.dart';
import 'game_over_screen.dart';
import 'level_complete_screen.dart';
import '../models/level_data.dart';
import '../services/audio_service.dart';
import '../services/image_service.dart';
import 'main_menu_screen.dart';
import 'pause_menu_screen.dart';

class GameScreen extends StatefulWidget {
  final LevelData? levelData;
  final GameEngine? gameEngine;

  const GameScreen({super.key, this.levelData,this.gameEngine});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late AnimationController _characterController;
  late Animation<double> _characterAnimation;
  GameEngine? _gameEngine;
  late LevelData currentLevel;
  Timer? _gameUpdateTimer;

  OverlayEntry? _notificationOverlayEntry;

  // ✅ نظام الإشعارات الموحد
  Timer? _notificationTimer;
  String? _currentNotification;

  DateTime? _lastDamageTime;
  static const int _damageEffectDuration = 150;
  int _lastCharacterHealth = 100;
  bool _isTakingDamage = false;
  bool _showDamageEffect = false;
  bool _showBossHitEffect = false;
  double _damageShakeOffset = 0.0;
  Timer? _damageEffectTimer;
  Timer? _bossHitEffectTimer;
  Timer? _shakeTimer;
  double _startDragX = 0.0;
  double _startDragY = 0.0;
  bool _isDragging = false;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isGameOverCalled = false;
  bool _showDragInstructions = true;
  Timer? _dragInstructionsTimer;
  bool _showAttackNotification = false;
  Timer? _attackNotificationTimer;
  bool _hasShownAttackNotification = false; // ✅ لتتبع إذا تم عرض الإشعار من قبل

  // دالة مساعدة للتحقق من اللغة
  bool get _isArabic => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _setupCharacterAnimation();

    _lastCharacterHealth = 100;
    _lastDamageTime = null;
    _showDamageEffect = false;
    _showBossHitEffect = false;
    _damageShakeOffset = 0.0;
    _preloadPowerUpImages();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeGame();
    });
  }

  // ✅ دالة جديدة لعرض إشعار الهجوم لمدة 2 ثانية
  void _showAttackNotificationTemporary() {
    if (!_hasShownAttackNotification) { // ✅ تظهر فقط في المرة الأولى
      _hasShownAttackNotification = true;
      _safeSetState(() {
        _showAttackNotification = true;
      });

      _attackNotificationTimer?.cancel();
      _attackNotificationTimer = Timer(const Duration(seconds: 2), () {
        _safeSetState(() {
          _showAttackNotification = false;
        });
      });
    }
  }

  void _preloadPowerUpImages() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ImageService.preloadImages(context);
    });
  }

  void _initializeGame() async {
    final languages = AppLocalizations.of(context);
    try {
      _isGameOverCalled = false;

      currentLevel = widget.levelData ?? await LevelData.getLevelData(1);

      // ✅ استخدام GameEngine الممرر إن وجد، أو إنشاء جديد
      if (widget.gameEngine != null) {
        _gameEngine = widget.gameEngine;
        print('🔄 استخدام GameEngine موجود للاستمرار');
      } else {
        _gameEngine = GameEngine(
          levelData: currentLevel,
          // onGameOver: _gameOver, // 👈 تم تعطيل الطريقة القديمة
          onLevelComplete: _levelComplete,
          onBossAppear: _onBossAppear,
          onBossDefeated: _onBossDefeated,
          onCharacterDamage: _showDamageAnimation,
          onBossHit: _showBossHitAnimation,
        );

        // 🛑🛑🛑 التعديل الجوهري هنا 🛑🛑🛑
        // تعريف onGameOver بشكل منفصل للوصول إلى context بشكل صحيح
        _gameEngine!.onGameOver = () {
          if (!mounted || _isGameOverCalled) return;
          _isGameOverCalled = true;

          // لا تدمر الموارد! اللعبة الآن متوقفة مؤقتًا فقط.
          // _cleanupResources(); // <<--- لا تستدعِ هذه الدالة هنا

          // حفظ التقدم العام (مثل أعلى نقاط)
          GameDataService.saveGameProgress(_gameEngine!.score, currentLevel.levelNumber);

          // اعرض شاشة النهاية كنافذة حوار (Dialog) فوق اللعبة
          showDialog(
            context: context,
            barrierDismissible: false, // منع إغلاقها بالضغط في الخارج
            builder: (BuildContext dialogContext) {
              return GameOverScreen(
                score: _gameEngine!.score,
                level: _gameEngine!.level,
                levelData: currentLevel,
                timeSpent: _gameEngine!.timeSpent,
                gameEngine: _gameEngine, // تمرير المحرك ليتمكن من الاستمرار
              );
            },
          ).then((_) {
            // هذا الكود يتم تنفيذه بعد إغلاق نافذة الحوار
            // إذا لم يقم اللاعب بالاستمرار، قد ترغب في العودة للقائمة الرئيسية
            // يمكنك ترك هذا الجزء فارغًا في الوقت الحالي
            _isGameOverCalled = false; // السماح بظهور الشاشة مرة أخرى إذا لزم الأمر
          });
        };

        _gameEngine!.initialize();
        print('🎮 إنشاء GameEngine جديد');
      }

      _gameEngine!.startGame();
      _characterController.repeat();
      _startGameLoop();

      AudioService().playBackgroundMusic();

      _isInitialized = true;
      _safeSetState(() {});

      _startDragInstructionsTimer();

    } catch (e) {
      print('❌ خطأ في تهيئة اللعبة: $e');
      _hasError = true;
      if (mounted) {
        _safeSetState(() {});
      }
    }
  }

  void _startDragInstructionsTimer() {
    _dragInstructionsTimer = Timer(const Duration(seconds: 6), () {
      _safeSetState(() {
        _showDragInstructions = false;
      });
    });
  }

  void _setupCharacterAnimation() {
    _characterController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _characterAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _characterController, curve: Curves.easeInOut),
    );
  }

  void _startGameLoop() {
    _gameUpdateTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted || _gameEngine == null) {
        timer.cancel();
        return;
      }

      try {
        _updateGameUI();

        // ✅ تم تبسيط المنطق هنا
        if (_gameEngine!.shouldGameEnd) {
          timer.cancel(); // أوقف هذا التايمر الخاص بالواجهة

          // ✅ لم نعد بحاجة لاستدعاء _gameOver() هنا.
          // محرك اللعبة سيقوم الآن باستدعاء _gameEngine.onGameOver بنفسه
          // والذي قمنا بتعريفه في _initializeGame.

          // الحالة الوحيدة التي نحتاج للتعامل معها هنا هي إكمال المستوى
          if (_gameEngine!.isBossDefeated) {
            _levelComplete();
          }
          return;
        }

      } catch (e) {
        timer.cancel();
      }
    });
  }


  void _updateGameUI() {
    if (!mounted || _gameEngine == null) return;

    _safeSetState(() {
      _checkBossNotifications();
      _checkRealDamage();
    });
  }

  void _checkBossNotifications() {
    if (_gameEngine == null) return;

    // ✅ استخدام النظام الجديد المعتمد على الوقت
    final timeRemaining = _gameEngine!.bossTimeRemaining;

    // ✅ إشعار تحذير قبل 30 ثانية من ظهور الزعيم
    if (timeRemaining <= 30 && timeRemaining > 0 && !_gameEngine!.isBossSpawned) {
      if (_notificationOverlayEntry == null) {
        _showNotification('boss_warning');
      }
    }
    // ✅ إشعار ظهور الزعيم عندما يصل الوقت إلى الصفر
    else if (timeRemaining <= 0 && !_gameEngine!.isBossSpawned) {
      if (_notificationOverlayEntry == null) {
        _showNotification('boss_appear');
      }
    }
  }

  void _checkRealDamage() {
    if (_gameEngine == null || _gameEngine!.character == null) return;

    final currentHealth = _gameEngine!.character!.health;
    final now = DateTime.now();

    if (currentHealth < _lastCharacterHealth) {
      final healthLost = _lastCharacterHealth - currentHealth;

      if (healthLost >= 5) {
        if (_lastDamageTime == null ||
            now.difference(_lastDamageTime!).inMilliseconds > 300) {
          _showDamageAnimation();
        }
      }
    }

    _lastCharacterHealth = currentHealth;
  }

  void _showNotification(String messageKey) {
    final l10n = AppLocalizations.of(context);

    String message;

    switch (messageKey) {
      case 'boss_warning':
        message = '⚡ ${l10n.bossWarning}';
        break;
      case 'boss_appear':
        message = '👹 ${l10n.bossAppear}';
        break;
      default:
        message = messageKey;
    }

    _removeNotification();

    _notificationOverlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 20,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.yellow, width: 2),
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );

    final overlay = Overlay.of(context);
    overlay.insert(_notificationOverlayEntry!);

    _notificationTimer = Timer(const Duration(seconds: 2), () {
      _removeNotification();
    });
  }

  // ✅ إزالة الدوال القديمة للإشعارات
  void _removeNotification() {
    _notificationTimer?.cancel();
    _notificationTimer = null;

    // ✅ التأكد من إزالة الـ OverlayEntry بشكل آمن
    if (_notificationOverlayEntry != null) {
      try {
        _notificationOverlayEntry!.remove();
      } catch (e) {
        // تجاهل الأخطاء إذا كان الـ OverEntry قد أُزيل بالفعل
      }
      _notificationOverlayEntry = null;
    }
  }

  void _onBossAppear() {
    _safeSetState(() {});
  }

  void _onBossDefeated() {
    _showBossHitAnimation();
    _safeSetState(() {});
  }

  void _levelComplete() async {
    _cleanupResources();
    _removeNotification();

    await GameDataService.saveGameProgress(_gameEngine!.score, currentLevel.levelNumber);

    final LevelData? nextLevel = await _getNextLevel();

    if (mounted) {
      // ✅ تظهر LevelCompleteScreen فقط عند قتل الزعيم
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LevelCompleteScreen(
            score: _gameEngine!.score,
            levelData: currentLevel,
            nextLevel: nextLevel,
            timeSpent: _gameEngine!.timeSpent,
          ),
        ),
      );
    }
  }

  void _cleanupResources() {
    _characterController.stop();
    _gameUpdateTimer?.cancel();
    _damageEffectTimer?.cancel();
    _bossHitEffectTimer?.cancel();
    _shakeTimer?.cancel();
    _dragInstructionsTimer?.cancel();
    _attackNotificationTimer?.cancel(); // ✅ إضافة هذا السطر
    AudioService().stopBackgroundMusic();
    _removeNotification();
    _safeSetState(() {
      _showDamageEffect = false;
      _showBossHitEffect = false;
      _damageShakeOffset = 0.0;
      _isTakingDamage = false;
      _lastDamageTime = null;
      _showDragInstructions = false;
      _showAttackNotification = false; // ✅ إضافة هذا السطر
    });
  }

  Future<LevelData?> _getNextLevel() async {
    try {
      return currentLevel.levelNumber < 100
          ? await LevelData.getLevelData(currentLevel.levelNumber + 1)
          : null;
    } catch (e) {
      return null;
    }
  }

  void _handlePanStart(DragStartDetails details) {
    if (_gameEngine == null || !_gameEngine!.isGameRunning) return;

    _startDragX = details.localPosition.dx;
    _startDragY = details.localPosition.dy;
    _isDragging = true;

    if (_showDragInstructions) {
      _safeSetState(() {
        _showDragInstructions = false;
      });
      _dragInstructionsTimer?.cancel();
    }
  }


  void _handlePanUpdate(DragUpdateDetails details) {
    if (!_isDragging || _gameEngine == null || !_gameEngine!.isGameRunning) return;

    final double deltaX = details.localPosition.dx - _startDragX;
    final double deltaY = details.localPosition.dy - _startDragY;

    // ✅ تحديث اتجاه الهجوم أولاً
    _gameEngine!.character.setAttackDirection(deltaX, deltaY);

    // ✅ استخدام النظام البسيط للحركة والقفز
    _gameEngine!.handleCharacterDrag(deltaX, deltaY);

    _startDragX = details.localPosition.dx;
    _startDragY = details.localPosition.dy;
  }

  void _handlePanEnd(DragEndDetails details) {
    _isDragging = false;

    // ✅ إعادة تعيين اتجاه الهجوم عند انتهاء السحب
    if (_gameEngine != null) {
      _gameEngine!.character.setAttackDirection(0, 0);
    }
  }

  void _handleTapDown(TapDownDetails details) {
    if (_gameEngine == null || !_gameEngine!.isGameRunning) return;

    // ✅ الحصول على موقع النقر بالنسبة للشاشة بدقة
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset localPosition = box.globalToLocal(details.globalPosition);

    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    // ✅ تحويل إحداثيات النقر إلى إحداثيات اللعبة (0-1)
    // x: من اليسار (0) إلى اليمين (1)
    // y: من الأعلى (0) إلى الأسفل (1)
    double tapX = (localPosition.dx / screenWidth).clamp(0.0, 1.0);
    double tapY = (localPosition.dy / screenHeight).clamp(0.0, 1.0);

    // ✅ إطلاق الهجوم باتجاه النقر الحقيقي
    _gameEngine!.attackCharacterAtPosition(tapX, tapY);

    // ✅ إظهار إشعار الهجوم في أول مرة فقط
    _showAttackNotificationTemporary();

    if (_showDragInstructions) {
      setState(() {
        _showDragInstructions = false;
      });
      _dragInstructionsTimer?.cancel();
    }
  }

  void _handleTap() {
    // ✅ الهجوم للأعلى بشكل افتراضي عند النقر بدون تحديد موقع
    if (_gameEngine != null && _gameEngine!.isGameRunning) {
      _gameEngine!.attackCharacterWithDirection(1.0, -0.3); // أعلى ويمين قليلاً
      _showAttackNotificationTemporary();
    }
  }

// ✅ تحديد إذا كان السحب للحركة أم للهجوم
  bool _isMovementDrag(double deltaX, double deltaY) {
    // إذا كانت الحركة أفقية بشكل رئيسي = حركة
    // إذا كانت الحركة رأسية أو صغيرة = هجوم
    return deltaX.abs() > deltaY.abs() && deltaX.abs() > 15;
  }

  void _showDamageAnimation() {
    final now = DateTime.now();

    if (_showDamageEffect || _isTakingDamage) {
      return;
    }

    if (_lastDamageTime != null) {
      final timeSinceLastDamage = now.difference(_lastDamageTime!).inMilliseconds;
      if (timeSinceLastDamage < 300) {
        return;
      }
    }

    _damageEffectTimer?.cancel();
    _shakeTimer?.cancel();

    _lastDamageTime = now;
    _isTakingDamage = true;

    _safeSetState(() {
      _showDamageEffect = true;
      _damageShakeOffset = 0.0;
    });

    _startDamageShake();

    _damageEffectTimer = Timer(Duration(milliseconds: _damageEffectDuration), () {
      _safeSetState(() {
        _showDamageEffect = false;
        _damageShakeOffset = 0.0;
        _isTakingDamage = false;
      });
    });
  }

  void _startDamageShake() {
    _damageShakeOffset = 0.0;
    int shakeCount = 0;

    _shakeTimer?.cancel();

    _shakeTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (shakeCount < 4) {
        _damageShakeOffset = shakeCount.isEven ? 3.0 : -3.0;
        _safeSetState(() {});
      } else {
        _damageShakeOffset = 0.0;
        timer.cancel();
        _safeSetState(() {});
      }
      shakeCount++;
    });
  }

  void _showBossHitAnimation() {
    _showBossHitEffect = true;
    _bossHitEffectTimer?.cancel();
    _bossHitEffectTimer = Timer(const Duration(milliseconds: 300), () {
      _safeSetState(() {
        _showBossHitEffect = false;
      });
    });
  }

  Color _getDamageColor() {
    if (!_showDamageEffect) return Colors.transparent;

    final time = DateTime.now().millisecondsSinceEpoch;
    final blink = (time ~/ 80) % 2 == 0;

    return blink ? Colors.red.withOpacity(0.4) : Colors.pink.withOpacity(0.3);
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    try {
      setState(fn);
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorScreen();
    }

    if (!_isInitialized || _gameEngine == null) {
      return _buildLoadingScreen();
    }

    try {
      final Size screenSize = MediaQuery.of(context).size;
      final double progress = (_gameEngine!.score / currentLevel.targetScore).clamp(0.0, 1.0);

      // ✅ التعديل: المرحلة تكتمل فقط بقتل الزعيم، وليس بالنقاط
      final bool isLevelComplete = _gameEngine!.isBossDefeated; // إزالة: || progress >= 1.0

      return Scaffold(
        body: GestureDetector(
          behavior: HitTestBehavior.opaque, // ✅ السماح باللمس في أي مكان
          onPanStart: isLevelComplete ? null : _handlePanStart,
          onPanUpdate: isLevelComplete ? null : _handlePanUpdate,
          onPanEnd: isLevelComplete ? null : _handlePanEnd,
          onTapDown: _handleTapDown,
          onTap: _handleTap,
          child: Stack(
            children: [
              _buildGameContainer(screenSize, progress, isLevelComplete),
              _buildControlIndicators(isLevelComplete),
              _buildActivePowerUps(),
              if (_gameEngine!.isBossFight) _buildBossInterface(),
              if (currentLevel.levelNumber == 100 && _gameEngine!.isBossDefeated)
                _buildGameCompletionOverlay(),
              _buildBossWarning(),
              if (_showDragInstructions) _buildDragInstructions(),
              if (_showAttackNotification) _buildAttackNotification(),
            ].where((widget) => widget != null).toList(),
          ),
        ),
      );
    } catch (e) {
      return _buildErrorScreen();
    }
  }

  // ✅ ويدجت إشعار الهجوم الجديد
  Widget _buildAttackNotification() {
    final l10n = AppLocalizations.of(context);

    return Positioned(
      top: MediaQuery.of(context).size.height * 0.15,
      left: 20,
      right: 20,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.orange, Colors.deepOrange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.bolt,
              color: Colors.yellow,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.tapAnywhereToAim, // ✅ استخدام النص المترجم الجديد
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ ويدجت الإشعار الموحد
  Widget _buildUnifiedNotification() {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.15, // ✅ تحت شريط النقاط
      left: 20,
      right: 20,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.blue, Colors.lightBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _currentNotification!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticBackground(Size screenSize) {
    // ✅ استخدام الخلفية من نظام الأرضيات بدلاً من levelData
    String backgroundImage = GroundSystem.currentBackground;

    return Container(
      width: screenSize.width,
      height: screenSize.height,
      child: Image.asset(
        backgroundImage,
        width: screenSize.width,
        height: screenSize.height,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildAnimatedGround() {
    final l10n = AppLocalizations.of(context);
    // ✅ استخدام الأرضية من نظام الأرضيات
    final groundImage = GroundSystem.getGroundImage();

    double groundOffset = _gameEngine?.backgroundManager.currentGroundOffset ?? 0.0;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 100,
        child: Stack(
          children: [
            Positioned(
              left: MediaQuery.of(context).size.width * groundOffset,
              child: Image.asset(
                groundImage,
                width: MediaQuery.of(context).size.width,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              left: MediaQuery.of(context).size.width * (groundOffset + 1.0),
              child: Image.asset(
                groundImage,
                width: MediaQuery.of(context).size.width,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameContainer(Size screenSize, double progress, bool isLevelComplete) {
    return Container(
      child: Stack(
        children: [
          _buildStaticBackground(screenSize),
          SafeArea(
            child: Column(
              children: [
                _buildHeaderSection(),
                _buildProgressBar(progress, isLevelComplete),
                _buildGameArea(screenSize, isLevelComplete),
              ],
            ),
          ),
          _buildAnimatedGround(),
        ],
      ),
    );
  }

  Widget _buildTimeIndicator() {
    if (_gameEngine == null) return const SizedBox.shrink();

    // ✅ إخفاء التوقيت أثناء اللعب
    return const SizedBox.shrink();
  }

  Widget _buildHeaderSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // === للغة العربية: زر الإيقاف أولاً ثم الباور أب ===
          if (_isArabic) _buildPowerUpsAndControls(),
          // === النقاط في المنتصف ===
          _buildScoreInfo(),
          // === للغة الإنجليزية: الباور أب ثم زر الإيقاف ===
          if (!_isArabic) _buildPowerUpsAndControls(),
        ],
      ),
    );
  }

  Widget _buildScoreInfo() {
    final l10n = AppLocalizations.of(context);

    return Expanded(
      child: Column(
        crossAxisAlignment: _isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: _isArabic ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              // === للغة العربية: النقاط - العملات - الصحة ===
              if (_isArabic) ...[
                _buildLivesIndicator(),
                const SizedBox(width: 15),
                _buildCoinBadge(),
                const SizedBox(width: 15),
                Text('${_gameEngine!.score} :${l10n.score}', style: _getTextStyle()),
              ],
              // === للغة الإنجليزية: النقاط - العملات - الصحة ===
              if (!_isArabic) ...[
                Text('${l10n.score}: ${_gameEngine!.score}', style: _getTextStyle()),
                const SizedBox(width: 15),
                _buildCoinBadge(),
                const SizedBox(width: 15),
                _buildLivesIndicator(),
              ],
            ],
          ),
          Text(
            _isArabic
                ? '${currentLevel.targetScore} :${l10n.target} - ${currentLevel.getName(l10n)}'
                : '${currentLevel.getName(l10n)} - ${l10n.target}: ${currentLevel.targetScore}',
            style: const TextStyle(fontSize: 14, color: Colors.white70),
            textAlign: _isArabic ? TextAlign.right : TextAlign.left,
          ),
        ],
      ),
    );
  }

  Widget _buildLivesIndicator() {
    return Row(
      children: List.generate(3, (index) {
        final bool hasLife = index < _gameEngine!.character.lives;
        return Container(
          margin: EdgeInsets.only(left: _isArabic ? 4 : 0, right: _isArabic ? 0 : 4),
          child: Image.asset(
            hasLife ? 'assets/images/ui/heart.png' : 'assets/images/ui/empty_heart.png',
            width: 20,
            height: 20,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                hasLife ? Icons.favorite : Icons.favorite_border,
                color: hasLife ? Colors.red : Colors.grey,
                size: 20,
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildCoinBadge() {
    final coins = _gameEngine!.score ~/ 50;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _isArabic
            ? [
          Text(
            '$coins',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 4),
          Image.asset(
            ImageService.coin,
            width: 16,
            height: 16,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.monetization_on, size: 16, color: Colors.white);
            },
          ),
        ]
            : [
          Image.asset(
            ImageService.coin,
            width: 16,
            height: 16,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.monetization_on, size: 16, color: Colors.white);
            },
          ),
          const SizedBox(width: 4),
          Text(
            '$coins',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPowerUpsAndControls() {
    return Row(
      children: [
        if (!_isArabic) ...[
          // === للغة الإنجليزية: الباور أب ثم زر الإيقاف ===
          if (_gameEngine!.isDoublePoints)
            _buildPowerUpImageWidget(PowerUpType.doublePoints, Colors.purple),
          if (_gameEngine!.isSlowMotion)
            _buildPowerUpImageWidget(PowerUpType.slowMotion, Colors.green),
          if (_gameEngine!.hasShield)
            _buildPowerUpImageWidget(PowerUpType.shield, Colors.blue),
          if (_gameEngine!.isSpeedBoostActive)
            _buildPowerUpImageWidget(PowerUpType.speedBoost, Colors.yellow),
          if (_gameEngine!.areEnemiesSlowed)
            _buildPowerUpImageWidget(PowerUpType.slowEnemies, Colors.blue),
          const SizedBox(width: 8),
          _buildPauseButton(),
        ],
        if (_isArabic) ...[
          // === للغة العربية: زر الإيقاف ثم الباور أب ===
          _buildPauseButton(),
          const SizedBox(width: 8),
          if (_gameEngine!.isDoublePoints)
            _buildPowerUpImageWidget(PowerUpType.doublePoints, Colors.purple),
          if (_gameEngine!.isSlowMotion)
            _buildPowerUpImageWidget(PowerUpType.slowMotion, Colors.green),
          if (_gameEngine!.hasShield)
            _buildPowerUpImageWidget(PowerUpType.shield, Colors.blue),
          if (_gameEngine!.isSpeedBoostActive)
            _buildPowerUpImageWidget(PowerUpType.speedBoost, Colors.yellow),
          if (_gameEngine!.areEnemiesSlowed)
            _buildPowerUpImageWidget(PowerUpType.slowEnemies, Colors.blue),
        ],
      ],
    );
  }

  Widget _buildPowerUpImageWidget(PowerUpType type, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Image.asset(
        _getPowerUpImagePath(type),
        width: 24,
        height: 24,
        errorBuilder: (context, error, stackTrace) {
          return Text(
            _getPowerUpEmoji(type),
            style: const TextStyle(fontSize: 20),
          );
        },
      ),
    );
  }

  Widget _buildPauseButton() {
    return IconButton(
      onPressed: () {
        _showPauseMenu();
      },
      icon: const Icon(Icons.pause, color: Colors.white, size: 30),
    );
  }

  void _showPauseMenu() {
    _gameEngine?.pauseGame();
    AudioService().pauseAllSounds();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PauseMenuScreen(
          onResume: _resumeGame,
          onRestart: _restartLevel,
          isGamePaused: true,
        );
      },
    );
  }

  void _resumeGame() {
    _gameEngine?.resumeGame();
    AudioService().resumeAllSounds();
    _safeSetState(() {});
  }

  void _restartLevel() {
    _cleanupResources();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ✅ إعادة إنشاء GameEngine بدلاً من استخدام reset
      _gameEngine?.cleanup();
      _gameEngine = null;
      _isInitialized = false;
      _hasError = false;
      _isGameOverCalled = false;
      _hasShownAttackNotification = false;
      _showDragInstructions = true;
      _showAttackNotification = false;
      _initializeGame();
    });
  }

  Widget _buildProgressBar(double progress, bool isLevelComplete) {
    final l10n = AppLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // === للغة العربية: النسبة على اليمين ===
              if (_isArabic)
                Text(
                  '%${(progress * 100).toInt()}',
                  style: TextStyle(
                    color: isLevelComplete ? Colors.green : Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),

              Text(
                  _isArabic ? '${l10n.progress}:' : '${l10n.progress}:',
                  style: const TextStyle(color: Colors.white70, fontSize: 14)
              ),

              // === للغة الإنجليزية: النسبة على اليسار ===
              if (!_isArabic)
                Text(
                  '%${(progress * 100).toInt()}',
                  style: TextStyle(
                    color: isLevelComplete ? Colors.green : Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Positioned(
                right: _isArabic ? 0 : null,
                left: _isArabic ? null : 0,
                child: Container(
                  height: 8,
                  width: MediaQuery.of(context).size.width * 0.9 * progress,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isLevelComplete
                          ? [Colors.green, Colors.lightGreen]
                          : [Colors.yellow, Colors.orange],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          if (isLevelComplete) ...[
            const SizedBox(height: 5),
            Text(
              _isArabic ? '!${l10n.levelComplete} 🎉' : '${l10n.levelComplete} 🎉!',
              style: const TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGameArea(Size screenSize, bool isLevelComplete) {
    return Expanded(
      child: Stack(
        children: _getGameElements(screenSize, isLevelComplete),
      ),
    );
  }

  List<Widget> _getGameElements(Size screenSize, bool isLevelComplete) {
    final elements = <Widget>[];

    try {
      elements.addAll(_buildBackgroundElements(screenSize));
      elements.addAll(_buildPlatforms(screenSize));
      elements.add(_buildCharacter(screenSize));

      if (_gameEngine!.character.attacks.isNotEmpty) {
        elements.addAll(_buildAttacks(screenSize));
      }
      if (_gameEngine!.obstacles.isNotEmpty) {
        elements.addAll(_buildObstacles(screenSize));
      }
      if (_gameEngine!.enemies.isNotEmpty) {
        elements.addAll(_buildEnemies(screenSize));
      }
      if (_gameEngine!.powerUps.isNotEmpty) {
        elements.addAll(_buildPowerUpsInGame(screenSize));
      }
      if (_gameEngine!.isBossFight && _gameEngine!.currentBoss != null) {
        elements.addAll(_buildBossProjectiles(screenSize));
        elements.add(_buildBoss(screenSize));
      }
      if (_gameEngine!.particles.isNotEmpty) {
        elements.addAll(_buildParticles(screenSize));
      }

    } catch (e) {
      // خطأ صامت
    }

    return elements.where((element) => element != null).toList();
  }

  List<Widget> _buildBackgroundElements(Size screenSize) {
    try {
      final elements = _gameEngine!.backgroundManager.elements;

      return elements.map((element) {
        return Positioned(
          top: screenSize.height * element.y - element.size / 2,
          left: screenSize.width * element.x - element.size / 2,
          child: Container(
            width: element.size,
            height: element.size,
            child: Icon(
              element.icon,
              size: element.size * 0.8,
              color: element.color.withOpacity(0.7),
            ),
          ),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  List<Widget> _buildPlatforms(Size screenSize) {
    final widgets = <Widget>[];

    try {
      for (var platform in _gameEngine!.platforms) {
        final double platformWidth = platform.width * screenSize.width;
        final double platformHeight = platform.height * screenSize.height;
        final double platformLeft = screenSize.width * platform.x - platformWidth / 2;
        final double platformBottom = 100 + (screenSize.height * (0.75 - platform.y));

        final widget = Positioned(
          bottom: platformBottom,
          left: platformLeft,
          child: Container(
            width: platformWidth,
            height: platformHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: _buildPlatformImage(platform, platformWidth, platformHeight),
          ),
        );
        widgets.add(widget);
      }
    } catch (e) {
      // خطأ صامت
    }

    return widgets;
  }

  Widget _buildPlatformImage(Obstacle platform, double width, double height) {
    try {
      final String imagePath = platform.imagePath ?? ImageService.platform;

      return Image.asset(
        imagePath,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.brown.shade600,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.brown.shade800,
                width: 3,
              ),
            ),
            child: Center(
              child: Text(
                '🧱',
                style: TextStyle(
                  fontSize: height * 0.5,
                ),
              ),
            ),
          );
        },
      );
    } catch (e) {
      return Container(
        color: Colors.brown.shade600,
        child: const Center(child: Text('🧱')),
      );
    }
  }

  Widget _buildCharacter(Size screenSize) {
    if (_gameEngine == null || _gameEngine!.character == null) {
      return const SizedBox.shrink();
    }

    try {
      final character = _gameEngine!.character!;
      double characterX = character.x.clamp(0.1, 0.9);
      double characterY = character.y;

      final double bounceOffset = sin(_characterAnimation.value * 2 * pi) * 5;
      final double bottomPosition = 100 + (screenSize.height * (0.75 - characterY)) + bounceOffset;
      final double leftPosition = screenSize.width * characterX - 40;

      if (character.isDead || character.health <= 0) {
        return const SizedBox.shrink();
      }

      return Positioned(
        bottom: bottomPosition,
        left: leftPosition + _damageShakeOffset,
        child: Stack(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
              ),
              child: _buildCharacterImage(),
            ),

            if (_showDamageEffect) ...[
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 50),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    color: _getDamageColor(),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.4),
                      width: 2,
                    ),
                  ),
                ),
              ),

              Positioned(
                top: -25,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 100),
                  opacity: _showDamageEffect ? 1.0 : 0.0,
                  child: const Text(
                    '💢',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],

            // if (_showBossHitEffect) ...[
            //   Positioned(
            //     top: -15,
            //     right: -15,
            //     child: Container(
            //       padding: const EdgeInsets.all(8),
            //       decoration: BoxDecoration(
            //         color: Colors.orange.withOpacity(0.7),
            //         shape: BoxShape.circle,
            //       ),
            //       child: const Text(
            //         '🔥',
            //         style: TextStyle(fontSize: 20),
            //       ),
            //     ),
            //   ),
            // ],

            if (_gameEngine!.hasShield && !character.isDead) ...[
              Positioned(
                top: -8,
                left: -8,
                right: -8,
                bottom: -8,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(48),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.7),
                      width: 3,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    } catch (e) {
      return _buildFallbackCharacter();
    }
  }

  Widget _buildCharacterImage() {
    try {
      final character = _gameEngine!.character;
      String imagePath = _getCharacterImage();

      return Image.asset(
        imagePath,
        width: 80,
        height: 80,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackCharacter();
        },
      );
    } catch (e) {
      return _buildFallbackCharacter();
    }
  }

  String _getCharacterImage() {
    return _gameEngine!.character.getCurrentImage();
  }

  Widget _buildFallbackCharacter() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: const Center(
        child: Text(
          '👤',
          style: TextStyle(fontSize: 40),
        ),
      ),
    );
  }

  List<Widget> _buildObstacles(Size screenSize) {
    final widgets = <Widget>[];

    try {
      for (var obstacle in _gameEngine!.obstacles) {
        final isBrick = obstacle.color == Colors.brown;

        final widget = Positioned(
          bottom: 100 + (screenSize.height * (0.75 - obstacle.y)),
          left: screenSize.width * obstacle.x - 25,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isBrick ? 5 : 10),
              border: isBrick ? Border.all(color: Colors.brown.shade800, width: 2) : null,
            ),
            child: Image.asset(
              isBrick ? ImageService.brick : ImageService.pipe,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: obstacle.color,
                  child: Center(
                    child: Text(
                      isBrick ? '🧱' : '🚧',
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                );
              },
            ),
          ),
        );
        widgets.add(widget);
      }
    } catch (e) {
      // خطأ صامت
    }

    return widgets;
  }

  List<Widget> _buildEnemies(Size screenSize) {
    final widgets = <Widget>[];

    try {
      for (var enemy in _gameEngine!.enemies) {
        final isFlyingEnemy = enemy.type == ObstacleType.flyingEnemy;
        final bottomPosition = 100 + (screenSize.height * (0.75 - enemy.y));

        final widget = Positioned(
          bottom: bottomPosition,
          left: screenSize.width * enemy.x - 30,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isFlyingEnemy ? 30 : 10),
            ),
            child: _buildEnemyImage(enemy),
          ),
        );
        widgets.add(widget);
      }
    } catch (e) {
      // خطأ صامت
    }

    return widgets;
  }

  Widget _buildEnemyImage(Obstacle enemy) {
    try {
      String imagePath = _getEnemyImagePath(enemy);
      return Image.asset(
        imagePath,
        width: 60,
        height: 60,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackEnemy(enemy);
        },
      );
    } catch (e) {
      return _buildFallbackEnemy(enemy);
    }
  }

  String _getEnemyImagePath(Obstacle enemy) {
    if (enemy.type == ObstacleType.flyingEnemy) {
      return ImageService.enemyFlying;
    } else if (enemy.color == Colors.brown) {
      return ImageService.enemyGoomba;
    } else if (enemy.color == Colors.red) {
      return ImageService.enemyMushroom;
    } else if (enemy.color == Colors.green) {
      return ImageService.enemyKoopa;
    } else {
      return ImageService.enemyGoomba;
    }
  }

  Widget _buildFallbackEnemy(Obstacle enemy) {
    final isFlying = enemy.color == Colors.purple;

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: enemy.color,
        borderRadius: BorderRadius.circular(isFlying ? 30 : 10),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Text(
          _getEnemyEmoji(enemy.color),
          style: const TextStyle(fontSize: 30),
        ),
      ),
    );
  }

  String _getEnemyEmoji(Color color) {
    if (color == Colors.brown) {
      return '👹';
    } else if (color == Colors.red) {
      return '🍄';
    } else if (color == Colors.green) {
      return '🐢';
    } else if (color == Colors.purple) {
      return '🦅';
    } else {
      return '👹';
    }
  }

  List<Widget> _buildPowerUpsInGame(Size screenSize) {
    final widgets = <Widget>[];

    try {
      for (var powerUp in _gameEngine!.powerUps) {
        final widget = Positioned(
          bottom: 100 + (screenSize.height * (0.75 - powerUp.y)),
          left: screenSize.width * powerUp.x - 25,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
            ),
            child: _buildPowerUpImage(powerUp),
          ),
        );
        widgets.add(widget);
      }
    } catch (e) {
      // خطأ صامت
    }

    return widgets;
  }

  Widget _buildPowerUpImage(PowerUp powerUp) {
    try {
      String imagePath = _getPowerUpImagePath(powerUp.type);
      return Image.asset(
        imagePath,
        width: 50,
        height: 50,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackPowerUpWidget(powerUp);
        },
      );
    } catch (e) {
      return _buildFallbackPowerUpWidget(powerUp);
    }
  }

  Widget _buildFallbackPowerUpWidget(PowerUp powerUp) {
    return Container(
      decoration: BoxDecoration(
        color: powerUp.color,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Text(
          _getPowerUpEmoji(powerUp.type),
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }

  String _getPowerUpEmoji(PowerUpType type) {
    switch (type) {
      case PowerUpType.health: return '❤️';
      case PowerUpType.speedBoost: return '⚡';
      case PowerUpType.slowEnemies: return '🐌';
      case PowerUpType.coin: return '🪙';
      case PowerUpType.points: return '⭐';
      case PowerUpType.shield: return '🛡️';
      case PowerUpType.slowMotion: return '⏱️';
      case PowerUpType.doublePoints: return '💰';
      case PowerUpType.slowCharacter: return '🐢';
      default: return '🎁';
    }
  }

  String _getPowerUpImagePath(PowerUpType type) {
    switch (type) {
      case PowerUpType.health:
        return 'assets/images/powerups/health.png';
      case PowerUpType.speedBoost:
        return 'assets/images/powerups/speed_icon.png';
      case PowerUpType.slowEnemies:
        return 'assets/images/powerups/slow_icon.png';
      case PowerUpType.coin:
        return 'assets/images/resources/coin.png';
      case PowerUpType.points:
        return 'assets/images/powerups/points.png';
      case PowerUpType.shield:
        return 'assets/images/powerups/shield.png';
      case PowerUpType.slowMotion:
        return 'assets/images/powerups/slow_motion.png';
      case PowerUpType.doublePoints:
        return 'assets/images/powerups/double_points.png';
      case PowerUpType.slowCharacter:
        return 'assets/images/powerups/slow_icon.png';
      default:
        return 'assets/images/powerups/points.png';
    }
  }

  List<Widget> _buildAttacks(Size screenSize) {
    final widgets = <Widget>[];

    try {
      for (var attack in _gameEngine!.character.attacks) {
        if (attack.isActive) {
          final widget = Positioned(
            bottom: 100 + (screenSize.height * (0.75 - attack.y)),
            left: screenSize.width * attack.x - 30,
            child: Container(
              width: 60,
              height: 60,
              child: Image.asset(
                attack.imagePath,
                width: 60,
                height: 60,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return _buildFallbackAttack(attack);
                },
              ),
            ),
          );
          widgets.add(widget);
        }
      }
    } catch (e) {
      print('❌ خطأ في بناء الهجمات: $e');
    }

    return widgets;
  }

  Widget _buildFallbackAttack(Attack attack) {
    final fallbackIcons = {
      AttackType.snowySnowball: '❄️',
      AttackType.fieryFireball: '🔥',
      AttackType.greekLightning: '⚡',
      AttackType.warriorBullet: '🔫',
      AttackType.arabicFalcon: '🦅',
      AttackType.vikingHammer: '🔨',
      AttackType.comicsPow: '💥',
      AttackType.technoHack: '💻',
      AttackType.zombieSpit: '🦠',
      AttackType.medievalMud: '🌰',
      AttackType.rainbowBeam: '🌈',
      AttackType.almashePackage: '📦',
    };

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Center(
        child: Text(
          fallbackIcons[attack.type] ?? '⚡',
          style: TextStyle(fontSize: 30),
        ),
      ),
    );
  }

  List<Widget> _buildBossProjectiles(Size screenSize) {
    final widgets = <Widget>[];
    final Boss? boss = _gameEngine!.currentBoss;

    if (boss == null) return widgets;

    try {
      for (var projectile in boss.projectiles) {
        final widget = Positioned(
          bottom: 100 + (screenSize.height * (0.75 - projectile.y)),
          left: screenSize.width * projectile.x - 15,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Colors.red,
            ),
            child: const Center(
              child: Icon(Icons.warning, color: Colors.white, size: 20),
            ),
          ),
        );
        widgets.add(widget);
      }
    } catch (e) {
      // خطأ صامت
    }

    return widgets;
  }

  Widget _buildBoss(Size screenSize) {
    final Boss? boss = _gameEngine!.currentBoss;
    if (boss == null) return const SizedBox.shrink();

    return Positioned(
      bottom: 100 + (screenSize.height * (0.75 - boss.y)),
      left: screenSize.width * boss.x - 100,
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
        ),
        child: Stack(
          children: [
            Image.asset(
              boss.imagePath,
              width: 200,
              height: 200,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.purple,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: Colors.yellow, width: 4),
                  ),
                  child: const Center(
                    child: Text(
                      '👹',
                      style: TextStyle(fontSize: 80),
                    ),
                  ),
                );
              },
            ),

            if (_gameEngine!.isBossFight)
              Positioned(
                top: -10,
                left: -10,
                right: -10,
                bottom: -10,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(110),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.7),
                      width: 3,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // في ملف game_screen.dart - تأكد من أن هذه الدوال موجودة

  Widget _buildActivePowerUps() {
    final l10n = AppLocalizations.of(context);

    return Positioned(
      top: 100,
      left: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_gameEngine!.isSpeedBoostActive)
            _buildActivePowerUpIndicator(_isArabic ? '🚀 زيادة السرعة' : '🚀 Speed Boost', Colors.yellow, PowerUpType.speedBoost),
          if (_gameEngine!.areEnemiesSlowed)
            _buildActivePowerUpIndicator(_isArabic ? '🐌 الأعداء بطيئون' : '🐌 Enemies Slowed', Colors.blue, PowerUpType.slowEnemies),
          if (_gameEngine!.character.isCharacterSlowed)
            _buildActivePowerUpIndicator(_isArabic ? '🐌 الشخصية بطيئة' : '🐌 Character Slowed', Colors.purple, PowerUpType.slowCharacter),
          if (_gameEngine!.hasShield)
            _buildActivePowerUpIndicator(_isArabic ? '🛡️ درع واقي' : '🛡️ Shield', Colors.blue, PowerUpType.shield),
          if (_gameEngine!.isDoublePoints)
            _buildActivePowerUpIndicator(_isArabic ? '💰 نقاط مضاعفة' : '💰 Double Points', Colors.purple, PowerUpType.doublePoints),
          if (_gameEngine!.isSlowMotion)
            _buildActivePowerUpIndicator(_isArabic ? '⏱️ تباطؤ زمني' : '⏱️ Slow Motion', Colors.green, PowerUpType.slowMotion),
        ],
      ),
    );
  }

  Widget _buildActivePowerUpIndicator(String text, Color color, PowerUpType type) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            margin: EdgeInsets.only(left: _isArabic ? 0 : 8, right: _isArabic ? 8 : 0),
            child: Image.asset(
              _getPowerUpImagePath(type),
              errorBuilder: (context, error, stackTrace) {
                return Text(_getPowerUpEmoji(type));
              },
            ),
          ),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildParticles(Size screenSize) {
    final widgets = <Widget>[];

    try {
      for (var particle in _gameEngine!.particles) {
        final widget = Positioned(
          bottom: 100 + (screenSize.height * (0.75 - particle.y)),
          left: screenSize.width * particle.x - particle.size / 2,
          child: Container(
            width: particle.size,
            height: particle.size,
            decoration: BoxDecoration(
              color: particle.color.withOpacity(particle.opacity),
              shape: BoxShape.circle,
            ),
          ),
        );
        widgets.add(widget);
      }
    } catch (e) {
      // خطأ صامت
    }

    return widgets;
  }

  Widget _buildDragInstructions() {
    final l10n = AppLocalizations.of(context);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      child: GestureDetector(
        onTap: () {
          _safeSetState(() {
            _showDragInstructions = false;
          });
          _dragInstructionsTimer?.cancel();
        },
        child: Container(
          color: Colors.black.withOpacity(0.7),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Column(
                  children: [
                    Text(
                      '🎮 ${l10n.tutorialTitle}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildInstructionItem('⬅️ ➡️ ${l10n.tutorialDragHorizontal}', l10n.tutorialDragHorizontalDesc),
                    _buildInstructionItem('⬆️ ${l10n.tutorialDragUpSmall}', l10n.tutorialDragUpSmallDesc),
                    _buildInstructionItem('⬆️ ${l10n.tutorialDragUpLarge}', l10n.tutorialDragUpLargeDesc),
                    _buildInstructionItem('⬇️ ${l10n.tutorialDragDown}', l10n.tutorialDragDownDesc),
                    _buildInstructionItem('🎯 ${l10n.tutorialFullControl}', l10n.tutorialFullControlDesc),
                    const SizedBox(height: 15),
                    Text(
                      '💡 ${l10n.tutorialTapAnywhere}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.yellow,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      '⏱️ ${l10n.tutorialAutoHide}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionItem(String action, String result) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              action,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 1,
            child: Text(
              result,
              style: const TextStyle(
                color: Colors.yellow,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlIndicator(String emoji, String text) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _isArabic
            ? [
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          Text(emoji, style: const TextStyle(fontSize: 16)),
        ]
            : [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBossWarning() {
    if (_gameEngine == null) return const SizedBox.shrink();

    double completion = _gameEngine!.levelCompletionPercentage;

    if (completion >= 0.75 && completion < 0.8 && !_gameEngine!.isBossSpawned) {
      return Positioned(
        top: 100,
        left: 0,
        right: 0,
        child: Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.yellow, width: 2),
          ),
          child: Text(
            _isArabic ? '⚡ استعد! الزعيم يقترب...' : '⚡ Get ready! Boss is approaching...',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildBossInterface() {
    final Boss? boss = _gameEngine!.currentBoss;
    if (boss == null) return const SizedBox.shrink();

    return Stack(
      children: [
        Positioned(
          bottom: 100 + (MediaQuery.of(context).size.height * (0.75 - boss.y)) + 130,
          left: MediaQuery.of(context).size.width * boss.x - 60,
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
                  _isArabic ? '👑 الزعيم' : '👑 Boss',
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
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlIndicators(bool isLevelComplete) {
    final l10n = AppLocalizations.of(context);

    return Positioned(
      bottom: 30,
      left: 0,
      right: 0,
      child: Column(
        children: [
          if (!isLevelComplete && !_hasShownAttackNotification) ...[
            // ✅ إظهار التعليمات فقط إذا لم يتم عرض إشعار الهجوم من قبل
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _gameEngine!.isBossFight ? l10n.tapToFight : l10n.tapToAttack,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGameCompletionOverlay() {
    final l10n = AppLocalizations.of(context);

    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.green, Colors.blue],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.celebration,
                size: 80,
                color: Colors.yellow,
              ),
              const SizedBox(height: 20),
              Text(
                l10n.gameCompleteTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                l10n.gameCompleteMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.gameCompleteReward,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.yellow,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.gameCompleteInstructions,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const MainMenuScreen()),
                        (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: Text(
                  l10n.returnToMainMenu,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    final l10n = AppLocalizations.of(context);

    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 20),
            Text(
              'جاري تحميل اللعبة...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 60),
            const SizedBox(height: 20),
            Text(
              l10n.gameError,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.pleaseTryAgain,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const MainMenuScreen()),
                      (route) => false,
                );
              },
              child: Text(l10n.returnToMainMenu),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _getTextStyle() {
    return const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );
  }


  @override
  void dispose() {
    _removeNotification();

    _characterController.dispose();
    _gameUpdateTimer?.cancel();
    _damageEffectTimer?.cancel();
    _bossHitEffectTimer?.cancel();
    _shakeTimer?.cancel();
    _dragInstructionsTimer?.cancel();
    _attackNotificationTimer?.cancel();

    // ✅ استخدام cleanup بدلاً من dispose
    if (widget.gameEngine == null) {
      _gameEngine?.cleanup(); // ✅ تغيير من dispose إلى cleanup
    }

    super.dispose();
  }
}