import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../game/game_engine.dart';
import '../models/obstacle.dart';
import '../services/game_data_service.dart';
import 'game_over_screen.dart';
import 'level_complete_screen.dart';
import '../models/level_data.dart';
import '../services/audio_service.dart';
import '../services/image_service.dart';
import 'main_menu_screen.dart';

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

  // مؤشرات الكومبو
  bool _showComboIndicator = false;
  String _comboText = '';

  // متغيرات نظام السحب
  double _startDragY = 0.0;
  bool _isDragging = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() async {
    try {
      currentLevel = widget.levelData ?? await LevelData.getLevelData(1);
      _setupCharacterAnimation();

      _gameEngine = GameEngine(
        levelData: currentLevel,
        onGameOver: () => _gameOver(),
        onLevelComplete: () => _levelComplete(),
        onBossAppear: () => _onBossAppear(),
        onBossDefeated: () => _onBossDefeated(),
      );

      _gameEngine!.startGame();
      _characterController.repeat();
      _startGameLoop();
      AudioService().playBackgroundMusic();

      _isInitialized = true;
      setState(() {});

    } catch (e) {
      debugPrint('❌ Error initializing game: $e');
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainMenuScreen()),
              (route) => false,
        );
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

      setState(() {
        _updateComboIndicator();
      });

      if (_gameEngine!.isLevelCompleted) {
        timer.cancel();
        _levelComplete();
        return;
      }

      if (!_gameEngine!.isGameRunning && _gameEngine!.score > 0 && !_gameEngine!.isLevelCompleted) {
        timer.cancel();
        _gameOver();
      }
    });
  }

  void _updateComboIndicator() {
    if (_gameEngine!.isComboActive && _gameEngine!.comboCount >= 5) {
      _showComboIndicator = true;
      _comboText = 'كومبو! x${_gameEngine!.comboMultiplier}';
    } else {
      _showComboIndicator = false;
    }
  }

  void _onBossAppear() {
    setState(() {});
  }

  void _onBossDefeated() {
    setState(() {});
  }

  void _levelComplete() async {
    _cleanupResources();
    GameDataService.saveGameProgress(_gameEngine!.score, currentLevel.levelNumber);

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

  void _gameOver() {
    _cleanupResources();
    GameDataService.saveGameProgress(_gameEngine!.score, currentLevel.levelNumber);

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
    AudioService().stopBackgroundMusic();
  }

  Future<LevelData?> _getNextLevel() async {
    return currentLevel.levelNumber < 100
        ? await LevelData.getLevelData(currentLevel.levelNumber + 1)
        : null;
  }

  @override
  void dispose() {
    _characterController.dispose();
    _gameUpdateTimer?.cancel();
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
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _gameEngine == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 20),
              const Text(
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
          ],
        ),
      ),
    );
  }

  Widget _buildBossInterface() {
    final Boss? boss = _gameEngine!.currentBoss;
    if (boss == null) return const SizedBox.shrink();

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.red.withValues(alpha: 0.8),
              Colors.purple.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: Column(
          children: [
            Text(
              'زعيم المرحلة ${currentLevel.levelNumber}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 20,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width * boss.healthPercentage,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.red, Colors.orange],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Center(
                    child: Text(
                      '${boss.health}/${boss.maxHealth}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'انقر على الشاشة لرمي الطرود! 📦',
              style: TextStyle(
                color: Colors.yellow,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameCompletionOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.green, Colors.blue],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
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
        color: color.withValues(alpha: 0.2),
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
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
          if (_gameEngine!.isBossFight) ...[
            Text(
              'انقر لرمي الطرود على الزعيم! 📦',
              style: const TextStyle(
                color: Colors.orange,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_gameEngine!.isBossFight) ...[
                _buildControlButton(Icons.touch_app, 'هجوم', Colors.orange),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(IconData icon, String text, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(icon, color: Colors.white, size: 30),
        ),
        const SizedBox(height: 5),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildGameContainer(Size screenSize, double progress, bool isLevelComplete) {
    // اختر صورة الخلفية حسب رقم المرحلة
    String backgroundImage;
    if (currentLevel.levelNumber == 1) {
      backgroundImage = 'assets/images/backgrounds/city.png';
    } else if (currentLevel.levelNumber == 2) {
      backgroundImage = 'assets/images/backgrounds/forest.png';
    } else if (currentLevel.levelNumber == 3) {
      backgroundImage = 'assets/images/backgrounds/desert.png';
    } else {
      // إذا لم تحدد صورة للمرحلة، استخدم صورة افتراضية أو لون
      backgroundImage = 'assets/images/backgrounds/city.png';
    }

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
          _buildScoreInfo(),
          _buildPowerUpsAndControls(),
        ],
      ),
    );
  }

  Widget _buildScoreInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('النقاط: ${_gameEngine!.score}', style: _getTextStyle()),
            const SizedBox(width: 15),
            _buildCoinBadge(),
            const SizedBox(width: 15),
            _buildLivesIndicator(),
          ],
        ),
        Text('${currentLevel.name} - الهدف: ${currentLevel.targetScore}',
            style: const TextStyle(fontSize: 14, color: Colors.white70)),
      ],
    );
  }

  Widget _buildLivesIndicator() {
    return Row(
      children: List.generate(3, (index) {
        final bool hasLife = index < _gameEngine!.character.lives;
        return Container(
          margin: const EdgeInsets.only(right: 4),
          child: Icon(
            hasLife ? Icons.favorite : Icons.favorite_border,
            color: hasLife ? Colors.red : Colors.grey,
            size: 20,
          ),
        );
      }),
    );
  }

  Widget _buildCoinBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            ImageService.coin,
            width: 16,
            height: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '${_gameEngine!.score ~/ 10}',
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
        if (_gameEngine!.hasShield)
          _buildPowerUpIcon(Icons.shield, Colors.blue),
        if (_gameEngine!.isSlowMotion)
          _buildPowerUpIcon(Icons.slow_motion_video, Colors.green),
        if (_gameEngine!.isDoublePoints)
          _buildPowerUpIcon(Icons.double_arrow, Colors.purple),
        _buildPauseButton(),
      ],
    );
  }

  Widget _buildPowerUpIcon(IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }

  Widget _buildPauseButton() {
    return IconButton(
      onPressed: () {
        _gameEngine!.pauseGame();
        AudioService().stopBackgroundMusic();
        Navigator.pop(context);
      },
      icon: const Icon(Icons.pause, color: Colors.white, size: 30),
    );
  }

  Widget _buildProgressBar(double progress, bool isLevelComplete) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('التقدم:', style: TextStyle(color: Colors.white70, fontSize: 14)),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  color: isLevelComplete ? Colors.green : Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              isLevelComplete ? Colors.green : Colors.yellow,
            ),
            borderRadius: BorderRadius.circular(10),
            minHeight: 8,
          ),
          if (isLevelComplete) ...[
            const SizedBox(height: 5),
            const Text(
              '🎉 المرحلة اكتملت!',
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
        children: [
          ..._buildBackgroundElements(screenSize),
          _buildGround(),
          ..._buildBumps(screenSize),
          _buildCharacter(screenSize),
          ..._buildObstacles(screenSize),
          ..._buildEnemies(screenSize),
          ..._buildPowerUps(screenSize),
          ..._buildPackages(screenSize),
          ..._buildBossProjectiles(screenSize),
          _buildBoss(screenSize),
          ..._buildParticles(screenSize),
          if (isLevelComplete && currentLevel.levelNumber != 100) _buildLevelCompleteOverlay(),
        ],
      ),
    );
  }

  List<Widget> _buildBackgroundElements(Size screenSize) {
    return _gameEngine!.backgroundManager.elements
        .map(
          (element) => Positioned(
        top: screenSize.height * element.y - element.size / 2,
        left: screenSize.width * element.x - element.size / 2,
        child: Icon(
          element.icon,
          size: element.size,
          color: element.color,
        ),
      ),
    )
        .toList();
  }

  Widget _buildGround() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      height: 100,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.brown.withValues(alpha: 0.3),
              Colors.brown.withValues(alpha: 0.6),
            ],
          ),
        ),
        child: CustomPaint(
          painter: _GroundPainter(),
        ),
      ),
    );
  }

  List<Widget> _buildBumps(Size screenSize) {
    return _gameEngine!.bumpManager.bumps
        .map(
          (bump) => Positioned(
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
      ),
    )
        .toList();
  }

  Widget _buildCharacter(Size screenSize) {
    return AnimatedBuilder(
      animation: _characterAnimation,
      builder: (context, child) {
        final double bounceOffset = sin(_characterAnimation.value * 2 * pi) * 5;
        return Positioned(
          bottom: 100 + (screenSize.height * (0.75 - _gameEngine!.character.y)) + bounceOffset,
          left: screenSize.width * _gameEngine!.character.x - 40,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              border: _gameEngine!.character.hasShield
                  ? Border.all(color: Colors.blue, width: 3)
                  : null,
            ),
            child: Image.asset(
              _gameEngine!.character.isAttacking
                  ? 'assets/images/characters/character_attack.png'
                  : _gameEngine!.character.isDucking
                  ? ImageService.characterDuck
                  : _gameEngine!.character.isJumping
                  ? ImageService.characterJump
                  : ImageService.characterRun,
              fit: BoxFit.contain,
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildObstacles(Size screenSize) {
    return _gameEngine!.obstacles
        .map(
          (obstacle) => Positioned(
        bottom: 100 + (screenSize.height * (0.75 - obstacle.y)),
        left: screenSize.width * obstacle.x - 25,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: Image.asset(
            obstacle.color == Colors.red ? ImageService.pipe : ImageService.brick,
            fit: BoxFit.contain,
          ),
        ),
      ),
    )
        .toList();
  }

  List<Widget> _buildEnemies(Size screenSize) {
    return _gameEngine!.enemies
        .map(
          (enemy) => Positioned(
        bottom: 100 + (screenSize.height * (0.75 - enemy.y)),
        left: screenSize.width * enemy.x - 25,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/enemies/goomba.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    )
        .toList();
  }

  List<Widget> _buildPowerUps(Size screenSize) {
    return _gameEngine!.powerUps
        .map(
          (powerUp) => Positioned(
        bottom: 100 + (screenSize.height * (0.75 - powerUp.y)),
        left: screenSize.width * powerUp.x - 20,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: powerUp.color.withValues(alpha: 0.5),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            children: [
              Image.asset(
                ImageService.coin,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
      ),
    )
        .toList();
  }

  List<Widget> _buildPackages(Size screenSize) {
    return _gameEngine!.character.packages
        .map(
          (package) => Positioned(
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
                color: Colors.black.withValues(alpha: 0.3),
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
      ),
    )
        .toList();
  }

  List<Widget> _buildBossProjectiles(Size screenSize) {
    final Boss? boss = _gameEngine!.currentBoss;
    if (boss == null) return [];

    return boss.projectiles
        .map(
          (projectile) => Positioned(
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
                color: Colors.red.withValues(alpha: 0.5),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.warning, color: Colors.white, size: 20),
          ),
        ),
      ),
    )
        .toList();
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
              color: Colors.purple.withValues(alpha: 0.5),
              blurRadius: 15,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Image.asset(
          boss.imagePath,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  List<Widget> _buildParticles(Size screenSize) {
    return _gameEngine!.particles
        .map(
          (particle) => Positioned(
        bottom: 100 + (screenSize.height * (0.75 - particle.y)),
        left: screenSize.width * particle.x - particle.size / 2,
        child: Container(
          width: particle.size,
          height: particle.size,
          decoration: BoxDecoration(
            color: particle.color.withValues(alpha: particle.opacity),
            shape: BoxShape.circle,
          ),
        ),
      ),
    )
        .toList();
  }

  Widget _buildLevelCompleteOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
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
                color: Colors.white.withValues(alpha: 0.8),
              ),
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

class _GroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0xFF8B4513)
      ..style = PaintingStyle.fill;

    final Paint borderPaint = Paint()
      ..color = const Color(0xFF654321)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), borderPaint);

    final Paint grassPaint = Paint()
      ..color = const Color(0xFF00AA00)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 5), grassPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}