import 'package:flutter/material.dart';
import '../services/ads_service.dart';
import '../services/game_data_service.dart';
import 'game_screen.dart';
import 'main_menu_screen.dart';
import 'levels_screen.dart';
import '../models/level_data.dart';

class GameOverScreen extends StatelessWidget {
  final int score;
  final int level;
  final LevelData? levelData;

  const GameOverScreen({
    super.key,
    required this.score,
    this.level = 1,
    this.levelData,
  });

  @override
  Widget build(BuildContext context) {
    bool levelCompleted = levelData != null && score >= levelData!.targetScore;
    bool nextLevelUnlocked = levelCompleted && levelData!.levelNumber < 20;
    int coinsEarned = score ~/ 10;

    _saveGameProgress();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: levelCompleted
                ? [
                    const Color(0xFF4CAF50),
                    const Color(0xFF2E7D32),
                  ]
                : [
                    const Color(0xFF2E4057),
                    const Color(0xFF8B0000),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // العنوان والنتيجة
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      levelCompleted ? Icons.celebration : Icons.sentiment_dissatisfied,
                      size: 100,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      levelCompleted ? 'أحسنت!' : 'انتهت اللعبة!',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            offset: Offset(2, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'نقاطك: $score',
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.yellow,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (levelData != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        '${levelData!.name} - الهدف: ${levelData!.targetScore}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      if (levelCompleted) ...[
                        const SizedBox(height: 5),
                        const Text(
                          'تم إنجاز المرحلة بنجاح!',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.lightGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 10),
                    Text(
                      'العملات المكتسبة: $coinsEarned',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // أزرار الإجراءات
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // زر الاستمرار بمشاهدة إعلان
                      if (!levelCompleted && AdsService.isRewardedAdReady()) ...[
                        _buildActionButton(
                          'استمر (شاهد إعلان)',
                          Icons.play_arrow,
                          Colors.green,
                          () => _showAdAndContinue(context),
                        ),
                        const SizedBox(height: 15),
                      ],

                      // زر المرحلة التالية
                      if (nextLevelUnlocked) ...[
                        _buildActionButton(
                          'المرحلة التالية',
                          Icons.arrow_forward,
                          Colors.blue,
                          () => _goToNextLevel(context),
                        ),
                        const SizedBox(height: 15),
                      ],

                      // زر إعادة اللعب
                      _buildActionButton(
                        'إعادة اللعب',
                        Icons.refresh,
                        Colors.orange,
                        () => _restartLevel(context),
                      ),
                      const SizedBox(height: 15),

                      // زر قائمة المراحل
                      _buildActionButton(
                        'قائمة المراحل',
                        Icons.list,
                        Colors.purple,
                        () => _goToLevels(context),
                      ),
                      const SizedBox(height: 15),

                      // زر القائمة الرئيسية
                      _buildActionButton(
                        'القائمة الرئيسية',
                        Icons.home,
                        Colors.grey,
                        () => _goToMainMenu(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveGameProgress() {
    if (levelData != null) {
      GameDataService.saveGameProgress(score, levelData!.levelNumber);
    }
  }

  Widget _buildActionButton(
      String text,
      IconData icon,
      Color color,
      VoidCallback onPressed,
      ) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAdAndContinue(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('جاري تحميل الإعلان...'),
            ],
          ),
        );
      },
    );

    AdsService.showRewardedAd(
      onAdStarted: () {
        Navigator.of(context).pop();
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const AlertDialog(
              title: Text('إعلان مكافأة'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.video_library, size: 60, color: Colors.blue),
                  SizedBox(height: 10),
                  Text('يتم عرض الإعلان...'),
                  SizedBox(height: 10),
                  LinearProgressIndicator(),
                ],
              ),
            );
          },
        );
      },
      onAdCompleted: () {
        Navigator.of(context).pop();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GameScreen(levelData: levelData),
          ),
        );
      },
      onAdFailed: (error) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في تحميل الإعلان: $error'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      },
    );
  }

  void _goToNextLevel(BuildContext context) async {
    if (levelData != null && levelData!.levelNumber < 100) {
      LevelData nextLevel = await LevelData.getLevelData(levelData!.levelNumber + 1);

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('مرحلة جديدة!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, size: 60, color: Colors.amber),
                const SizedBox(height: 10),
                Text(
                  nextLevel.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  nextLevel.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('لاحقاً'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _startNextLevel(context, nextLevel);
                },
                child: const Text('ابدأ'),
              ),
            ],
          );
        },
      );
    }
  }

  void _startNextLevel(BuildContext context, LevelData nextLevel) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('جاري تحميل الإعلان...'),
            ],
          ),
        );
      },
    );

    AdsService.showInterstitialAd(
      onAdStarted: () {
        Navigator.of(context).pop();
      },
      onAdCompleted: () {
        _navigateToLevel(context, nextLevel);
      },
      onAdFailed: (error) {
        Navigator.of(context).pop();
        _navigateToLevel(context, nextLevel);
      },
    );
  }

  void _navigateToLevel(BuildContext context, LevelData nextLevel) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(levelData: nextLevel),
      ),
    );
  }

  void _restartLevel(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(levelData: levelData),
      ),
    );
  }

  void _goToLevels(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LevelsScreen(),
      ),
          (route) => false,
    );
  }

  void _goToMainMenu(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const MainMenuScreen(),
      ),
          (route) => false,
    );
  }
}