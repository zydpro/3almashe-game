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
    bool nextLevelUnlocked = levelCompleted && levelData!.levelNumber < 100;
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
                      if (!levelCompleted) ...[
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
                              () => _showAdAndGoToNextLevel(context),
                        ),
                        const SizedBox(height: 15),
                      ],

                      // زر إعادة اللعب
                      _buildActionButton(
                        'إعادة اللعب',
                        Icons.refresh,
                        Colors.orange,
                            () => _showAdAndRestartLevel(context),
                      ),
                      const SizedBox(height: 15),

                      // زر قائمة المراحل
                      _buildActionButton(
                        'قائمة المراحل',
                        Icons.list,
                        Colors.purple,
                            () => _showAdAndGoToLevels(context),
                      ),
                      const SizedBox(height: 15),

                      // زر القائمة الرئيسية
                      _buildActionButton(
                        'القائمة الرئيسية',
                        Icons.home,
                        Colors.grey,
                            () => _showAdAndGoToMainMenu(context),
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
      print('💾 تم حفظ التقدم: النقاط $score - المستوى ${levelData!.levelNumber}');
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
    print('🎬 المستخدم ضغط على "استمر (شاهد إعلان)"');

    _showLoadingDialog(context, 'جاري تحميل الإعلان...');

    AdsService.showRewardedAd(
      onAdStarted: () {
        print('▶️ إعلان الاستمرار بدأ');
        Navigator.pop(context); // إغلاق dialog التحميل
        _showAdPlayingDialog(context, 'إعلان مكافأة', 'ستستمر اللعبة بعد انتهاء الإعلان');
      },
      onAdCompleted: () {
        print('✅ إعلان الاستمرار اكتمل - الانتقال للعبة');
        Navigator.pop(context); // إغلاق dialog العرض
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GameScreen(levelData: levelData),
          ),
        );
      },
      onAdFailed: (error) {
        print('❌ إعلان الاستمرار فشل: $error');
        Navigator.pop(context); // إغلاق dialog
        _showAdErrorSnackBar(context, error);
      },
    );
  }

  void _showAdAndGoToNextLevel(BuildContext context) async {
    print('🚀 المستخدم ضغط على "المرحلة التالية"');

    if (levelData != null && levelData!.levelNumber < 100) {
      try {
        LevelData nextLevel = await LevelData.getLevelData(levelData!.levelNumber + 1);
        _showAdAndStartNextLevel(context, nextLevel);
      } catch (e) {
        print('❌ خطأ في تحميل المرحلة التالية: $e');
        _showErrorDialog(context, 'تعذر تحميل المرحلة التالية');
      }
    } else {
      _showCompletionDialog(context);
    }
  }

  void _showAdAndStartNextLevel(BuildContext context, LevelData nextLevel) {
    print('🎯 بدء المرحلة التالية مع إعلان: ${nextLevel.name}');

    _showLoadingDialog(context, 'جاري تحميل الإعلان...');

    AdsService.showInterstitialAd(
      onAdStarted: () {
        print('▶️ إعلان المرحلة التالية بدأ');
        Navigator.pop(context);
      },
      onAdCompleted: () {
        print('✅ إعلان المرحلة التالية اكتمل');
        _navigateToLevel(context, nextLevel);
      },
      onAdFailed: (error) {
        print('❌ إعلان المرحلة التالية فشل: $error');
        Navigator.pop(context);
        _navigateToLevel(context, nextLevel);
      },
    );
  }

  void _showAdAndRestartLevel(BuildContext context) {
    print('🔄 المستخدم ضغط على "إعادة اللعب" مع إعلان');

    _showLoadingDialog(context, 'جاري تحميل الإعلان...');

    AdsService.showInterstitialAd(
      onAdStarted: () {
        print('▶️ إعلان إعادة اللعب بدأ');
        Navigator.pop(context);
      },
      onAdCompleted: () {
        print('✅ إعلان إعادة اللعب اكتمل');
        _restartLevel(context);
      },
      onAdFailed: (error) {
        print('❌ إعلان إعادة اللعب فشل: $error');
        Navigator.pop(context);
        _restartLevel(context);
      },
    );
  }

  void _showAdAndGoToLevels(BuildContext context) {
    print('📋 المستخدم ضغط على "قائمة المراحل" مع إعلان');

    _showLoadingDialog(context, 'جاري تحميل الإعلان...');

    AdsService.showInterstitialAd(
      onAdStarted: () {
        print('▶️ إعلان قائمة المراحل بدأ');
        Navigator.pop(context);
      },
      onAdCompleted: () {
        print('✅ إعلان قائمة المراحل اكتمل');
        _goToLevels(context);
      },
      onAdFailed: (error) {
        print('❌ إعلان قائمة المراحل فشل: $error');
        Navigator.pop(context);
        _goToLevels(context);
      },
    );
  }

  void _showAdAndGoToMainMenu(BuildContext context) {
    print('🏠 المستخدم ضغط على "القائمة الرئيسية" مع إعلان');

    _showLoadingDialog(context, 'جاري تحميل الإعلان...');

    AdsService.showInterstitialAd(
      onAdStarted: () {
        print('▶️ إعلان القائمة الرئيسية بدأ');
        Navigator.pop(context);
      },
      onAdCompleted: () {
        print('✅ إعلان القائمة الرئيسية اكتمل');
        _goToMainMenu(context);
      },
      onAdFailed: (error) {
        print('❌ إعلان القائمة الرئيسية فشل: $error');
        Navigator.pop(context);
        _goToMainMenu(context);
      },
    );
  }

  // الدوال المساعدة
  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(message),
            ],
          ),
        );
      },
    );
  }

  void _showAdPlayingDialog(BuildContext context, String title, String description) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.video_library, size: 60, color: Colors.blue),
              const SizedBox(height: 10),
              const Text('يتم عرض الإعلان...'),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              const SizedBox(height: 10),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAdErrorSnackBar(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('فشل في تحميل الإعلان: $error'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'حاول مرة أخرى',
          textColor: Colors.white,
          onPressed: () {
            // يمكن إضافة إعادة المحاولة إذا لزم الأمر
          },
        ),
      ),
    );
  }

  Widget _buildLevelStat(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  void _navigateToLevel(BuildContext context, LevelData nextLevel) {
    print('🔄 الانتقال إلى المرحلة: ${nextLevel.name}');

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(levelData: nextLevel),
      ),
    );
  }

  void _restartLevel(BuildContext context) {
    print('🎮 إعادة تشغيل المرحلة: ${levelData!.name}');

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

  void _showCompletionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('🎉 مبروك!'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.celebration, size: 60, color: Colors.amber),
              SizedBox(height: 15),
              Text(
                'لقد أكملت جميع المراحل!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'أنت بطل اللعبة! 🏆',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('رائع!'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 10),
              Text('خطأ'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('حسناً'),
            ),
          ],
        );
      },
    );
  }
}