import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../game/game_engine.dart';
import '../models/Boss.dart';
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

  const GameScreen({super.key, this.levelData});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late AnimationController _characterController;
  late Animation<double> _characterAnimation;
  GameEngine? _gameEngine;
  late LevelData currentLevel;
  Timer? _gameUpdateTimer;

  DateTime? _lastDamageTime;
  static const int _damageEffectDuration = 150;
  int _lastCharacterHealth = 100;
  bool _isTakingDamage = false;

  // مؤشرات التأثيرات البصرية
  bool _showDamageEffect = false;
  bool _showBossHitEffect = false;
  double _damageShakeOffset = 0.0;
  Timer? _damageEffectTimer;
  Timer? _bossHitEffectTimer;
  Timer? _shakeTimer;

  // مؤشرات الكومبو
  bool _showComboIndicator = false;
  String _comboText = '';

  // متغيرات نظام السحب
  double _startDragY = 0.0;
  bool _isDragging = false;
  bool _isInitialized = false;
  bool _hasError = false;

  bool _isGameOverCalled = false; // أضف هذا المتغير في أعلى الكلاس


  Timer? _debugTimer;

  @override
  void initState() {
    super.initState();
    _setupCharacterAnimation();

    // إعادة تعيين القيم الابتدائية
    _lastCharacterHealth = 100;
    _lastDamageTime = null;
    _showDamageEffect = false;
    _showBossHitEffect = false;
    _damageShakeOffset = 0.0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeGame();
    });
  }

  void _initializeGame() async {
    try {
      _isGameOverCalled = false; // ✅ أضف هذا السطر هنا

      debugPrint("🎮 بدء تهيئة اللعبة...");

      // تحميل بيانات المرحلة
      currentLevel = widget.levelData ?? await LevelData.getLevelData(1);
      debugPrint("📊 المرحلة المحملة: ${currentLevel.name}");

      // إنشاء محرك اللعبة
      _gameEngine = GameEngine(
        levelData: currentLevel,
        onGameOver: _gameOver,
        onLevelComplete: _levelComplete,
        onBossAppear: _onBossAppear,
        onBossDefeated: _onBossDefeated,
        onCharacterDamage: _showDamageAnimation,
        onBossHit: _showBossHitAnimation,
      );

      // بدء اللعبة
      _gameEngine!.startGame();
      _characterController.repeat();
      _startGameLoop();

      // تشغيل الموسيقى
      AudioService().playBackgroundMusic();

      _isInitialized = true;
      _safeSetState(() {});

      debugPrint("✅ اللعبة مهيأة بنجاح");

    } catch (e) {
      debugPrint('❌ خطأ في تهيئة اللعبة: $e');
      _hasError = true;
      if (mounted) {
        _safeSetState(() {});
      }
    }
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

        // ✅ استخدام الخاصية الجديدة
        if (_gameEngine!.shouldGameEnd) {
          timer.cancel();
          if (_gameEngine!.character.isDead) {
            _gameOver();
          } else if (_gameEngine!.isBossDefeated) {
            _levelComplete();
          }
          return;
        }

      } catch (e) {
        debugPrint('❌ خطأ في game loop: $e');
        timer.cancel();
      }
    });
  }

  void _updateGameUI() {
    if (!mounted || _gameEngine == null) return;

    _safeSetState(() {
      _updateComboIndicator();
      _checkBossNotifications();
      _checkRealDamage();
    });

    // ❌ احذف هذا الجزء كاملاً - سنتعامل مع نهاية اللعبة في مكان آخر
    // if (_gameEngine!.isLevelCompleted) {
    //   _gameUpdateTimer?.cancel();
    //   _levelComplete();
    //   return;
    // }

    // if (!_gameEngine!.isGameRunning && _gameEngine!.score > 0 && !_gameEngine!.isLevelCompleted) {
    //   _gameUpdateTimer?.cancel();
    //   _gameOver();
    // }
  }

  void _updateComboIndicator() {
    if (_gameEngine!.isComboActive && _gameEngine!.comboCount >= 5) {
      _showComboIndicator = true;
      _comboText = 'كومبو! x${_gameEngine!.comboMultiplier}';
    } else {
      _showComboIndicator = false;
    }
  }

  void _checkBossNotifications() {
    if (_gameEngine == null) return;

    double completion = _gameEngine!.levelCompletionPercentage;

    if (completion >= 0.75 && completion < 0.8 && !_gameEngine!.isBossSpawned) {
      _showNotification('⚡ استعد! الزعيم يقترب...');
    }
    else if (completion >= 0.8 && !_gameEngine!.isBossSpawned) {
      _showNotification('👹 الزعيم يظهر!');
    }
  }

  void _checkRealDamage() {
    if (_gameEngine == null || _gameEngine!.character == null) return;

    final currentHealth = _gameEngine!.character!.health;
    final now = DateTime.now();

    // التحقق من انخفاض الصحة فقط (ليس عند الشفاء أو إعادة التعيين)
    if (currentHealth < _lastCharacterHealth) {
      final healthLost = _lastCharacterHealth - currentHealth;

      // التأكد من أن الضرر كبير enough ليستحق التأثير
      if (healthLost >= 5) {
        // التحقق من الوقت منذ آخر ضرر
        if (_lastDamageTime == null ||
            now.difference(_lastDamageTime!).inMilliseconds > 300) {

          print('🎯 ضرر حقيقي! فقدان: ${healthLost} صحة');
          _showDamageAnimation();
        }
      }
    }

    _lastCharacterHealth = currentHealth;
  }

  void _showNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.orange.withOpacity(0.9),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
      ),
    );
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
    await GameDataService.saveGameProgress(_gameEngine!.score, currentLevel.levelNumber);

    final LevelData? nextLevel = await _getNextLevel();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LevelCompleteScreen(
            score: _gameEngine!.score,
            levelData: currentLevel,
            nextLevel: nextLevel,
          ),
        ),
      );
    }
  }

  void _gameOver() async {
    if (_isGameOverCalled) return; // منع الاستدعاء المزدوج
    _isGameOverCalled = true;

    _cleanupResources();
    await GameDataService.saveGameProgress(_gameEngine!.score, currentLevel.levelNumber);

    Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GameOverScreen(
              score: _gameEngine!.score,
              level: _gameEngine!.level,
              levelData: currentLevel,
            ),
          ),
        );
      }
    });
  }

  void _cleanupResources() {
    _characterController.stop();
    _gameUpdateTimer?.cancel();
    _damageEffectTimer?.cancel();
    _bossHitEffectTimer?.cancel();
    _shakeTimer?.cancel();
    AudioService().stopBackgroundMusic();

    _safeSetState(() {
      _showDamageEffect = false;
      _showBossHitEffect = false;
      _damageShakeOffset = 0.0;
      _isTakingDamage = false;
      _lastDamageTime = null;
    });

    // print('🧹 تنظيف جميع الموارد والتأثيرات');
  }

  Future<LevelData?> _getNextLevel() async {
    try {
      return currentLevel.levelNumber < 100
          ? await LevelData.getLevelData(currentLevel.levelNumber + 1)
          : null;
    } catch (e) {
      debugPrint('❌ خطأ في تحميل المرحلة التالية: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _characterController.dispose();
    _gameUpdateTimer?.cancel();
    _damageEffectTimer?.cancel();
    _bossHitEffectTimer?.cancel();
    _shakeTimer?.cancel();
    _gameEngine?.dispose();
    super.dispose();
  }

  void _handleVerticalDragStart(DragStartDetails details) {
    if (_gameEngine == null || !_gameEngine!.isGameRunning) return;

    _startDragY = details.localPosition.dy;
    _isDragging = true;
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    if (!_isDragging || _gameEngine == null) return;

    final double deltaY = details.localPosition.dy - _startDragY;

    if (deltaY < -30) {
      _gameEngine!.jumpCharacter();
      _isDragging = false;
    } else if (deltaY > 30) {
      _gameEngine!.duckCharacter();
      _isDragging = false;
    }
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    _isDragging = false;
    _gameEngine?.stopDuckingCharacter();
  }

  void _handleTap() {
    if (_gameEngine?.isBossFight == true) {
      _gameEngine!.attackCharacter();
      _showBossHitAnimation();
    }
  }

  // ========== تأثيرات الضرر والدم - محسنة ==========

  void _showDamageAnimation() {
    final now = DateTime.now();

    // 1. منع تكرار التأثير إذا كان نشطاً بالفعل
    if (_showDamageEffect || _isTakingDamage) {
      print('⏭️ تخطي تأثير الضرر - التأثير نشط بالفعل');
      return;
    }

    // 2. التحقق من الوقت منذ آخر ضرر
    if (_lastDamageTime != null) {
      final timeSinceLastDamage = now.difference(_lastDamageTime!).inMilliseconds;
      if (timeSinceLastDamage < 300) {
        print('⏭️ تخطي تأثير الضرر - وقت قصير منذ آخر ضرر: ${timeSinceLastDamage}ms');
        return;
      }
    }

    // 3. إلغاء أي تأثير سابق
    _damageEffectTimer?.cancel();
    _shakeTimer?.cancel();

    // 4. تحديث وقت آخر ضرر
    _lastDamageTime = now;
    _isTakingDamage = true;

    // 5. بدء التأثير الجديد
    _safeSetState(() {
      _showDamageEffect = true;
      _damageShakeOffset = 0.0;
    });

    _startDamageShake();
    _createBloodParticles(_gameEngine!.character!.x, _gameEngine!.character!.y);

    print('💥 بدء تأثير الضرر - المدة: ${_damageEffectDuration}ms');

    // 6. إيقاف التأثير بعد المدة القصيرة
    _damageEffectTimer = Timer(Duration(milliseconds: _damageEffectDuration), () {
      _safeSetState(() {
        _showDamageEffect = false;
        _damageShakeOffset = 0.0;
        _isTakingDamage = false;
      });
      print('✅ انتهى تأثير الضرر');
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

  void _createBloodParticles(double x, double y) {
    print('🩸 إنشاء جسيمات دم عند: $x, $y');
  }

  Color _getDamageColor() {
    if (!_showDamageEffect) return Colors.transparent;

    final time = DateTime.now().millisecondsSinceEpoch;
    final blink = (time ~/ 80) % 2 == 0;

    return blink ? Colors.red.withOpacity(0.4) : Colors.pink.withOpacity(0.3);
  }

  List<Widget> _buildBloodSplatters() {
    return [
      Positioned(
        top: 5,
        left: 5,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _showDamageEffect ? 0.8 : 0.0,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
      Positioned(
        top: 5,
        right: 5,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: _showDamageEffect ? 0.8 : 0.0,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    ];
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    try {
      setState(fn);
    } catch (e) {
      debugPrint('❌ خطأ في setState: $e');
    }
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
      final bool isLevelComplete = progress >= 1.0 || _gameEngine!.isBossDefeated;

      return Scaffold(
        body: GestureDetector(
          onVerticalDragStart: isLevelComplete ? null : _handleVerticalDragStart,
          onVerticalDragUpdate: isLevelComplete ? null : _handleVerticalDragUpdate,
          onVerticalDragEnd: isLevelComplete ? null : _handleVerticalDragEnd,
          onTap: _handleTap,
          child: Stack(
            children: [
              _buildGameContainer(screenSize, progress, isLevelComplete),
              if (_showComboIndicator) _buildComboIndicator(),
              _buildControlIndicators(isLevelComplete),
              if (_gameEngine!.showTutorialArrows) _buildTutorialArrows(),
              if (_gameEngine!.isBossFight) _buildBossInterface(),
              if (currentLevel.levelNumber == 100 && _gameEngine!.isBossDefeated)
                _buildGameCompletionOverlay(),
              _buildBossWarning(),
            ].where((widget) => widget != null).toList(),
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ خطأ في بناء الواجهة: $e');
      return _buildErrorScreen();
    }
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
            '⚡ استعد! الزعيم يقترب...',
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
        // شريط صحة الزعيم يتحرك معه
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
        ),
      ],
    );
  }

  Widget _buildGameCompletionOverlay() {
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
            boxShadow: const [
              BoxShadow(
                color: Colors.black,
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
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
              const Text(
                'مبروك! لقد قمت بتختيم اللعبة! 🎉',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'خذ صورة لأنك قمت بتختيم اللعبة وأرسلها لنا على موقع عالماشي.كوم',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '🎁 جائزتك: تمييز إعلانك على موقعنا مجاناً لمدة شهر!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.yellow,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '💚 فقط أرسل الصورة لنا عبر مواقع التواصل الاجتماعي أو عبر حسابك على موقعنا وأخبرنا ماهو الإعلان الذي تريد تمييزه ليظهر بأول سجلات البحث',
                textAlign: TextAlign.center,
                style: TextStyle(
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
                child: const Text(
                  'العودة للقائمة الرئيسية',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTutorialArrows() {
    return Positioned(
      bottom: 150,
      left: 0,
      right: 0,
      child: Column(
        children: [
          _buildTutorialArrow(Icons.arrow_upward, 'اسحب للأعلى للقفز', Colors.green),
          const SizedBox(height: 20),
          _buildTutorialArrow(Icons.arrow_downward, 'اسحب لأسفل للانحناء', Colors.blue),
          if (_gameEngine!.isBossFight) ...[
            const SizedBox(height: 20),
            _buildTutorialArrow(Icons.touch_app, 'انقر لرمي الطرود', Colors.orange),
          ],
        ],
      ),
    );
  }

  Widget _buildTutorialArrow(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComboIndicator() {
    return Positioned(
      top: 100,
      right: 20,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.orange, Colors.red],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt, color: Colors.yellow, size: 20),
            const SizedBox(width: 8),
            Text(
              _comboText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlIndicators(bool isLevelComplete) {
    return Positioned(
      bottom: 30,
      left: 0,
      right: 0,
      child: Column(
        children: [
          if (!isLevelComplete) ...[
          if (_gameEngine!.isBossFight) ...[
            const SizedBox(height: 10),
            const Text(
              'انقر لرمي الطرود على الزعيم! 📦',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          ],
        ],
      ),
    );
  }

  Widget _buildGameContainer(Size screenSize, double progress, bool isLevelComplete) {
    String backgroundImage = currentLevel.backgroundImage;

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(backgroundImage),
          fit: BoxFit.cover,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeaderSection(),
            _buildProgressBar(progress, isLevelComplete),
            _buildGameArea(screenSize, isLevelComplete),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ✅ التعديل: وضع عناصر التحكم على اليمين (بالعربية)
          _buildPowerUpsAndControls(),

          // ✅ التعديل: وضع معلومات النقاط على اليسار (بالعربية)
          _buildScoreInfo(),
        ],
      ),
    );
  }

  Widget _buildScoreInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end, // ✅ محاذاة لليمين
      children: [
        Row(
          children: [
            _buildLivesIndicator(),
            const SizedBox(width: 15),
            _buildCoinBadge(),
            const SizedBox(width: 15),
            Text('${_gameEngine!.score} :النقاط', style: _getTextStyle()), // ✅ النص معكوس
          ],
        ),
        Text('${currentLevel.targetScore} :الهدف - ${currentLevel.name}',
            style: const TextStyle(fontSize: 14, color: Colors.white70)),
      ],
    );
  }

  Widget _buildLivesIndicator() {
    return Row(
      children: List.generate(3, (index) {
        final bool hasLife = index < _gameEngine!.character.lives;
        return Container(
          margin: const EdgeInsets.only(left: 4), // ✅ هامش على اليسار
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
      }).reversed.toList(), // ✅ عكس الترتيب لعرض من اليمين لليسار
    );
  }

  Widget _buildCoinBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${_gameEngine!.score ~/ 10}',
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
        ].reversed.toList(), // ✅ عكس الترتيب
      ),
    );
  }

  Widget _buildPowerUpsAndControls() {
    return Row(
      children: [
        _buildPauseButton(),
        if (_gameEngine!.isDoublePoints)
          _buildPowerUpIcon(Icons.double_arrow, Colors.purple),
        if (_gameEngine!.isSlowMotion)
          _buildPowerUpIcon(Icons.slow_motion_video, Colors.green),
        if (_gameEngine!.hasShield)
          _buildPowerUpIcon(Icons.shield, Colors.blue),
      ].reversed.toList(), // ✅ عكس الترتيب
    );
  }

  Widget _buildPowerUpIcon(IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 8), // ✅ هامش على اليسار
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Icon(icon, color: Colors.white, size: 24),
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
    // إيقاف اللعبة
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
    // استئناف اللعبة من حيث توقفت
    _gameEngine?.resumeGame();
    AudioService().resumeAllSounds();
    _safeSetState(() {});

    // print('🎮 Game resumed from pause');
  }

  void _restartLevel() {
    // إعادة تشغيل المرحلة من البداية
    _cleanupResources();

    // إعادة تهيئة اللعبة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeGame();
    });

    // print('🔄 Level restarted from beginning');
  }

  Widget _buildProgressBar(double progress, bool isLevelComplete) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '%${(progress * 100).toInt()}',
                style: TextStyle(
                  color: isLevelComplete ? Colors.green : Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(':التقدم', style: TextStyle(color: Colors.white70, fontSize: 14)), // ✅ نص معكوس
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              // الخلفية
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              // التقدم (من اليمين لليسار)
              Positioned(
                right: 0, // ✅ البدء من اليمين
                child: Container(
                  height: 8,
                  width: MediaQuery.of(context).size.width * 0.9 * progress, // ✅ العرض حسب التقدم
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
            const Text(
              '!🎉 المرحلة اكتملت',
              style: TextStyle(
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
      elements.add(_buildGround());
      elements.addAll(_buildPlatforms(screenSize)); // ✅ المنصات المستطيلة
      elements.addAll(_buildBumps(screenSize));
      elements.add(_buildCharacter(screenSize));

      if (_gameEngine!.obstacles.isNotEmpty) {
        elements.addAll(_buildObstacles(screenSize));
      }
      if (_gameEngine!.enemies.isNotEmpty) {
        elements.addAll(_buildEnemies(screenSize));
      }
      if (_gameEngine!.powerUps.isNotEmpty) {
        elements.addAll(_buildPowerUpsInGame(screenSize));
      }
      if (_gameEngine!.character.packages.isNotEmpty) {
        elements.addAll(_buildPackages(screenSize));
      }
      if (_gameEngine!.isBossFight && _gameEngine!.currentBoss != null) {
        elements.addAll(_buildBossProjectiles(screenSize));
        elements.add(_buildBoss(screenSize));
      }
      if (_gameEngine!.particles.isNotEmpty) {
        elements.addAll(_buildParticles(screenSize));
      }

      if (isLevelComplete && currentLevel.levelNumber != 100) {
        elements.add(_buildLevelCompleteOverlay());
      }
    } catch (e) {
      debugPrint('❌ خطأ في بناء عناصر اللعبة: $e');
    }

    return elements.where((element) => element != null).toList();
  }

  // ✅ بناء المنصات المستطيلة
  List<Widget> _buildPlatforms(Size screenSize) {
    final widgets = <Widget>[];

    try {
      print('🎯 Building ${_gameEngine!.platforms.length} platforms');

      for (var platform in _gameEngine!.platforms) {
        final double platformWidth = platform.width * screenSize.width;
        final double platformHeight = platform.height * screenSize.height;
        final double platformLeft = screenSize.width * platform.x - platformWidth / 2;
        final double platformBottom = 100 + (screenSize.height * (0.75 - platform.y));

        // ✅ طباعة موضع كل منصة
        if (_gameEngine!.platforms.indexOf(platform) == 0) {
          print('📍 First Platform - X: ${platform.x.toStringAsFixed(3)}, '
              'Screen Left: ${platformLeft.toInt()}px, '
              'Speed: ${platform.speed}');
        }

        final widget = Positioned(
          bottom: platformBottom,
          left: platformLeft,
          child: Container(
            width: platformWidth,
            height: platformHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 6,
                  offset: const Offset(3, 3),
                ),
              ],
            ),
            child: _buildPlatformImage(platform, platformWidth, platformHeight),
          ),
        );
        widgets.add(widget);
      }

      if (widgets.isNotEmpty) {
        print('✅ Successfully built ${widgets.length} moving platforms');
      } else {
        print('⚠️ No platforms to build');
      }
    } catch (e) {
      debugPrint('❌ خطأ في بناء المنصات: $e');
    }

    return widgets;
  }

// ✅ دالة لبناء صورة المنصة
  Widget _buildPlatformImage(Obstacle platform, double width, double height) {
    try {
      // استخدم imagePath من المنصة أو الصورة الافتراضية
      final String imagePath = platform.imagePath ?? ImageService.platform;

      return Image.asset(
        imagePath, // ✅ استخدام imagePath
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('❌ Failed to load platform image: $imagePath');
          // Fallback إذا فشل تحميل الصورة
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
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 4,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('❌ خطأ في بناء صورة المنصة: $e');
      return Container(
        color: Colors.brown.shade600,
        child: Center(child: Text('🧱')),
      );
    }
  }

// ✅ بناء عناصر الخلفية - محسنة
  List<Widget> _buildBackgroundElements(Size screenSize) {
    try {
      final elements = _gameEngine!.backgroundManager.elements;

      print('🌄 Building ${elements.length} background elements');

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
      debugPrint('❌ خطأ في بناء عناصر الخلفية: $e');
      return [];
    }
  }

  // ✅ دالة للتحقق من حالة المنصات
  void _checkPlatformsDebug() {
    if (_gameEngine != null) {
      final platforms = _gameEngine!.platforms;
      print('🔍 Platform Debug:');
      print('   - Total platforms: ${platforms.length}');
      print('   - Game running: ${_gameEngine!.isGameRunning}');

      for (int i = 0; i < platforms.length; i++) {
        final platform = platforms[i];
        print('   - Platform $i: X=${platform.x.toStringAsFixed(2)}, '
            'Y=${platform.y.toStringAsFixed(2)}, '
            'W=${platform.width}, H=${platform.height}');
      }
    }
  }

  Widget _buildGround() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.brown.shade300,
              Colors.brown.shade600,
              Colors.brown.shade800,
            ],
          ),
          border: Border.all(color: Colors.green.shade400, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Stack(
          children: [
            Container(
              height: 15,
              decoration: BoxDecoration(
                color: Colors.green.shade600,
                border: Border(
                  bottom: BorderSide(color: Colors.green.shade800, width: 2),
                ),
              ),
            ),
            const Center(
              child: Text(
                'عالماشي .كوم - المعركة بين يديك',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      offset: Offset(2, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBumps(Size screenSize) {
    try {
      return _gameEngine!.bumpManager.bumps.map((bump) {
        return Positioned(
          bottom: 80,
          left: screenSize.width * bump.x - bump.width / 2,
          child: Container(
            width: bump.width,
            height: bump.height,
            decoration: BoxDecoration(
              color: bump.color,
              borderRadius: BorderRadius.circular(bump.height / 2),
            ),
          ),
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ خطأ في بناء المطبات: $e');
      return [];
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
            // الشخصية الأساسية
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: _buildCharacterImage(),
            ),

            // تأثير الضرر المحسن
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
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pink.withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 3,
                      ),
                    ],
                    border: Border.all(
                      color: Colors.red.withOpacity(0.4),
                      width: 2,
                    ),
                  ),
                ),
              ),

              ..._buildBloodSplatters(),

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
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 10,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            // تأثير ضرب الزعيم
            if (_showBossHitEffect) ...[
              Positioned(
                top: -15,
                right: -15,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.7),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: const Text(
                    '🔥',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ),
            ],

            // تأثير الدرع
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
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.4),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    } catch (e) {
      debugPrint("❌ خطأ في بناء الشخصية: $e");
      return _buildFallbackCharacter();
    }
  }

  Widget _buildCharacterImage() {
    try {
      return Image.asset(
        _getCharacterImage(),
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
    final character = _gameEngine!.character;
    if (character.isAttacking) {
      return ImageService.characterAttack;
    } else if (character.isDucking) {
      return ImageService.characterDuck;
    } else if (character.isJumping) {
      return ImageService.characterJump;
    } else {
      return ImageService.characterRun;
    }
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
              borderRadius: BorderRadius.circular(isBrick ? 5 : 10), // ✅ شكل مختلف للـ brick
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(2, 2),
                ),
                if (isBrick) // ✅ ظل إضافي للـ brick
                  BoxShadow(
                    color: Colors.brown.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
              ],
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
                      isBrick ? '🧱' : '🚧', // ✅ إيموجي مختلف للـ brick
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
      debugPrint('❌ خطأ في بناء العوائق: $e');
    }

    return widgets;
  }

  List<Widget> _buildEnemies(Size screenSize) {
    final widgets = <Widget>[];

    try {
      for (var enemy in _gameEngine!.enemies) {
        final isFlyingEnemy = enemy.imagePath == ImageService.enemyFlying;
        final bottomPosition = isFlyingEnemy
            ? 100 + (screenSize.height * (0.75 - enemy.y))
            : 100 + (screenSize.height * (0.75 - enemy.y));

        final widget = Positioned(
          bottom: bottomPosition,
          left: screenSize.width * enemy.x - 30,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isFlyingEnemy ? 30 : 10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(2, 2),
                ),
                if (isFlyingEnemy) // ✅ ظل إضافي للطائر
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: Image.asset(
              _getEnemyImageByColor(enemy.color),
              width: 60,
              height: 60,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return _buildFallbackEnemy(enemy);
              },
            ),
          ),
        );
        widgets.add(widget);
      }
    } catch (e) {
      debugPrint('❌ خطأ في بناء الأعداء: $e');
    }

    return widgets;
  }

  String _getEnemyImageByColor(Color color) {
    if (color == Colors.brown) {
      return ImageService.enemyGoomba;
    } else if (color == Colors.red) {
      return ImageService.enemyMushroom;
    } else if (color == Colors.green) {
      return ImageService.enemyKoopa;
    } else if (color == Colors.purple) {
      return ImageService.enemyFlying; // ✅ العدو الطائر
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
        boxShadow: [
          BoxShadow(
            color: enemy.color.withOpacity(0.5),
            blurRadius: isFlying ? 15 : 8,
            spreadRadius: isFlying ? 3 : 1,
          ),
        ],
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
      return '🦅'; // ✅ إيموجي الطائر
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
          left: screenSize.width * powerUp.x - 20,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: powerUp.color.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Image.asset(
              ImageService.coin,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.yellow,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Text(
                      '💰',
                      style: TextStyle(fontSize: 20),
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
      debugPrint('❌ خطأ في بناء الباور-أب: $e');
    }

    return widgets;
  }

  List<Widget> _buildPackages(Size screenSize) {
    final widgets = <Widget>[];

    try {
      for (var package in _gameEngine!.character.packages) {
        final widget = Positioned(
          bottom: 100 + (screenSize.height * (0.75 - package.y)),
          left: screenSize.width * package.x - 15,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: Colors.brown,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                '📦',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        );
        widgets.add(widget);
      }
    } catch (e) {
      debugPrint('❌ خطأ في بناء الطرود: $e');
    }

    return widgets;
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
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.warning, color: Colors.white, size: 20),
            ),
          ),
        );
        widgets.add(widget);
      }
    } catch (e) {
      debugPrint('❌ خطأ في بناء مقذوفات الزعيم: $e');
    }

    return widgets;
  }

  Widget _buildBoss(Size screenSize) {
    final Boss? boss = _gameEngine!.currentBoss;
    if (boss == null) return const SizedBox.shrink();

    return Positioned(
      bottom: 100 + (screenSize.height * (0.75 - boss.y)),
      left: screenSize.width * boss.x - 60,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(60),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.5),
              blurRadius: 15,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Stack(
          children: [
            Image.asset(
              boss.imagePath,
              fit: BoxFit.contain,
            ),
          ],
        ),
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
      debugPrint('❌ خطأ في بناء الجسيمات: $e');
    }

    return widgets;
  }

  Widget _buildLevelCompleteOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.celebration, size: 60, color: Colors.yellow),
            const SizedBox(height: 10),
            const Text(
              'تهانينا! اكتملت المرحلة',
              style: TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'جاري الانتقال...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 60),
            const SizedBox(height: 20),
            const Text(
              'حدث خطأ في تحميل اللعبة',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'يرجى المحاولة مرة أخرى',
              style: TextStyle(
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
              child: const Text('العودة للقائمة الرئيسية'),
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
      shadows: [
        Shadow(
          color: Colors.black54,
          offset: Offset(1, 1),
          blurRadius: 2,
        ),
      ],
    );
  }
}