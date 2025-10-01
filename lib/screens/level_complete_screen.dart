import 'package:flutter/material.dart';
import 'game_screen.dart';
import 'levels_screen.dart';
import 'main_menu_screen.dart';
import '../models/level_data.dart';
import '../services/ads_service.dart';
import '../widgets/confetti_effect.dart';

class LevelCompleteScreen extends StatelessWidget {
  final int score;
  final LevelData levelData;
  final LevelData? nextLevel;

  const LevelCompleteScreen({
    super.key,
    required this.score,
    required this.levelData,
    this.nextLevel,
  });

  @override
  Widget build(BuildContext context) {
    final coinsEarned = score ~/ 10;

    return ConfettiEffect(
      isActive: true,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF4CAF50),
                Color(0xFF2E7D32),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // محتوى التهاني
                Expanded(
                  flex: 3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.celebration, size: 100, color: Colors.white),
                      const SizedBox(height: 20),
                      const Text(
                        'تهانينا!',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'لقد أكملت ${levelData.name}',
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'النقاط: $score',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.yellow,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'العملات: +$coinsEarned',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.amber,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (nextLevel != null)
                        Text(
                          'تم فتح المرحلة ${nextLevel!.levelNumber}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.lightGreen,
                          ),
                        ),
                    ],
                  ),
                ),

                // أزرار الإجراءات
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        if (nextLevel != null)
                          _buildActionButton(
                            'المرحلة التالية',
                            Icons.arrow_forward,
                            Colors.blue,
                                () => _startNextLevelWithAd(context),
                          ),

                        if (nextLevel != null) const SizedBox(height: 15),

                        _buildActionButton(
                          'إعادة اللعب',
                          Icons.refresh,
                          Colors.green,
                              () => _restartLevel(context),
                        ),

                        const SizedBox(height: 15),

                        _buildActionButton(
                          'قائمة المراحل',
                          Icons.list,
                          Colors.orange,
                              () => _goToLevels(context),
                        ),

                        const SizedBox(height: 15),

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
      ),
    );
  }

  Widget _buildActionButton(String text, IconData icon, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon),
            const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _startNextLevelWithAd(BuildContext context) {
    if (AdsService.isInterstitialAdReady()) {
      _showAdThenNextLevel(context);
    } else {
      _startNextLevelDirectly(context);
    }
  }

  void _showAdThenNextLevel(BuildContext context) {
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
        _startNextLevelDirectly(context);
      },
      onAdFailed: (error) {
        Navigator.of(context).pop();
        _startNextLevelDirectly(context);
      },
    );
  }

  void _startNextLevelDirectly(BuildContext context) {
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
      MaterialPageRoute(builder: (context) => const LevelsScreen()),
          (route) => false,
    );
  }

  void _goToMainMenu(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MainMenuScreen()),
          (route) => false,
    );
  }
}