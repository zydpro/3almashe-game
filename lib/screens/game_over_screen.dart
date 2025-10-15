import 'package:almashe_game/screens/items_Screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Languages/LanguageProvider.dart';
import '../services/ads_service.dart';
import '../services/game_data_service.dart';
import 'game_screen.dart';
import 'main_menu_screen.dart';
import 'levels_screen.dart';
import '../models/level_data.dart';
import '../Languages/localization.dart';

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
    final l10n = AppLocalizations.of(context);
    bool levelCompleted = levelData != null && score >= levelData!.targetScore;
    bool nextLevelUnlocked = levelCompleted && levelData!.levelNumber < 100;
    int coinsEarned = score ~/ 10;

    _saveGameProgress();

    return Scaffold(
      backgroundColor: Colors.black54,
      body: SafeArea(
        child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: BoxConstraints(
            maxWidth: 400, // ✅ تحديد أقصى عرض
          ),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[900]!.withOpacity(0.95),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: levelCompleted ? Colors.green : Colors.red,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✅ إضافة الهيدر مع زر اللغة
              _buildHeader(context, l10n),

              const SizedBox(height: 20),

              // محتوى النتيجة
              _buildContentSection(context, l10n, levelCompleted, score, coinsEarned, levelData),

              const SizedBox(height: 30),

              // أزرار الإجراءات
              _buildActionButtons(l10n, levelCompleted, nextLevelUnlocked, context),
            ],
          ),
        ),
      ),
      ),
    );
  }

  // ✅ إضافة الهيدر مع زر اللغة
  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ✅ إصلاح: استخدام SizedBox بعرض ثابت بدلاً من const
          SizedBox(
            width: 60,
            child: Container(), // عنصر فارغ للمساحة
          ),

          // ✅ إصلاح: استخدام Expanded مع تكبير النص
          Expanded(
            child: Text(
              l10n.levelComplete,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24, // ✅ تقليل حجم الخط قليلاً
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.green,
                    blurRadius: 10,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
            ),
          ),

          // ✅ إصلاح: تحديد حجم ثابت لزر اللغة
          SizedBox(
            width: 60,
            height: 60,
            child: _buildLanguageToggleButton(context),
          ),
        ],
      ),
    );
  }

  // ✅ زر تبديل اللغة
  Widget _buildLanguageToggleButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
        languageProvider.toggleLanguage();
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.01),
          border: Border.all(
            color: Colors.white.withOpacity(0.01),
            width: 0.1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Consumer<LanguageProvider>(
          builder: (context, languageProvider, child) {
            return Center(
              child: languageProvider.isArabic
                  ? _buildEnglishIcon()
                  : _buildArabicIcon(),
            );
          },
        ),
      ),
    );
  }

  // ✅ أيقونة اللغة الإنجليزية
  Widget _buildEnglishIcon() {
    return Image.asset(
      'assets/images/main_menu/english_icon.png',
      width: 50,
      height: 50,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF012169), Color(0xFFC8102E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
          ),
          child: const Center(
            child: Text(
              'EN',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  // ✅ أيقونة اللغة العربية
  Widget _buildArabicIcon() {
    return Image.asset(
      'assets/images/main_menu/arabic_icon.png',
      width: 50,
      height: 50,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF006233),
            borderRadius: BorderRadius.circular(25),
          ),
          child: const Center(
            child: Text(
              'ع',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        );
      },
    );
  }

// ✅ قسم المحتوى - تم الإصلاح
  Widget _buildContentSection(BuildContext context, AppLocalizations l10n, bool levelCompleted, int score, int coinsEarned, LevelData? levelData) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.8, // ✅ تحديد أقصى عرض
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            levelCompleted ? Icons.celebration : Icons.sentiment_dissatisfied,
            size: 80,
            color: levelCompleted ? Colors.green : Colors.red,
          ),
          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Text(
                  '${l10n.score}: $score',
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.yellow,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 10),

                // ✅ إصلاح: استخدام null-check operator
                if (levelData != null) ...[
                  Text(
                    '${levelData.getName(l10n)} - ${l10n.target}: ${levelData.targetScore}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                ],

                if (levelCompleted) ...[
                  Text(
                    l10n.gameOverLevelCompleted,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.lightGreen,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                ],

                Text(
                  '${l10n.gameOverCoinsEarned}: $coinsEarned',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ أزرار الإجراءات
  Widget _buildActionButtons(AppLocalizations l10n, bool levelCompleted, bool nextLevelUnlocked, BuildContext context) {
    return Column(
      children: [
        // زر الاستمرار بمشاهدة إعلان
        if (!levelCompleted) ...[
          _buildOptionButton(
            icon: Icons.play_arrow,
            text: l10n.gameOverContinue,
            description: l10n.gameOverContinueDesc,
            onTap: () => _showAdAndContinue(context),
            color: Colors.green,
          ),
          const SizedBox(height: 15),
        ],

        // زر المرحلة التالية
        if (nextLevelUnlocked) ...[
          _buildOptionButton(
            icon: Icons.arrow_forward,
            text: l10n.nextLevel,
            description: l10n.gameOverNextLevelDesc,
            onTap: () => _showAdAndGoToNextLevel(context),
            color: Colors.blue,
          ),
          const SizedBox(height: 15),
        ],

        // زر إعادة اللعب
        _buildOptionButton(
          icon: Icons.refresh,
          text: l10n.restartLevel,
          description: l10n.gameOverRestartDesc,
          onTap: () => _showAdAndRestartLevel(context),
          color: Colors.orange,
        ),
        const SizedBox(height: 15),

        // زر قائمة المراحل
        _buildOptionButton(
          icon: Icons.directions_run,
          text: l10n.choseCharacter,
          description: l10n.choseAnotherCharacter,
          onTap: () => _showAdAndGoToItemsScreen(context),
          color: Colors.purple,
        ),
        const SizedBox(height: 15),

        // زر القائمة الرئيسية
        _buildOptionButton(
          icon: Icons.home,
          text: l10n.mainMenu,
          description: l10n.gameOverMainMenuDesc,
          onTap: () => _showAdAndGoToMainMenu(context),
          color: Colors.grey,
        ),
      ],
    );
  }

  // ✅ زر الإجراءات - تصميم جديد
  Widget _buildOptionButton({
    required IconData icon,
    required String text,
    required String description,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: color, width: 2),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
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

  void _saveGameProgress() {
    if (levelData != null) {
      GameDataService.saveGameProgress(score, levelData!.levelNumber);
    }
  }

  void _showAdAndContinue(BuildContext context) {
    _showLoadingDialog(context, AppLocalizations.of(context).loadingAd);

    AdsService.showRewardedAd(
      onAdStarted: () {
        Navigator.pop(context);
        _showAdPlayingDialog(context, AppLocalizations.of(context).gameOverAdTitle, AppLocalizations.of(context).gameOverAdDesc);
      },
      onAdCompleted: () {
        Navigator.pop(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GameScreen(levelData: levelData),
          ),
        );
      },
      onAdFailed: (error) {
        Navigator.pop(context);
        _showAdErrorSnackBar(context, error);
      },
    );
  }

  void _showAdAndGoToNextLevel(BuildContext context) async {
    if (levelData != null && levelData!.levelNumber < 100) {
      try {
        LevelData nextLevel = await LevelData.getLevelData(levelData!.levelNumber + 1);
        _showAdAndStartNextLevel(context, nextLevel);
      } catch (e) {
        _showErrorDialog(context, AppLocalizations.of(context).gameOverLoadError);
      }
    } else {
      _showCompletionDialog(context);
    }
  }

  void _showAdAndStartNextLevel(BuildContext context, LevelData nextLevel) {
    _showLoadingDialog(context, AppLocalizations.of(context).loadingAd);

    AdsService.showInterstitialAd(
      onAdStarted: () => Navigator.pop(context),
      onAdCompleted: () => _navigateToLevel(context, nextLevel),
      onAdFailed: (error) => _navigateToLevel(context, nextLevel),
    );
  }

  void _showAdAndRestartLevel(BuildContext context) {
    _showLoadingDialog(context, AppLocalizations.of(context).loadingAd);

    AdsService.showInterstitialAd(
      onAdStarted: () => Navigator.pop(context),
      onAdCompleted: () => _restartLevel(context),
      onAdFailed: (error) => _restartLevel(context),
    );
  }

  void _showAdAndGoToItemsScreen(BuildContext context) {
    _showLoadingDialog(context, AppLocalizations.of(context).loadingAd);

    AdsService.showInterstitialAd(
      onAdStarted: () => Navigator.pop(context),
      onAdCompleted: () => _goToitemsScreen(context),
      onAdFailed: (error) => _goToitemsScreen(context),
    );
  }

  void _showAdAndGoToMainMenu(BuildContext context) {
    _showLoadingDialog(context, AppLocalizations.of(context).loadingAd);

    AdsService.showInterstitialAd(
      onAdStarted: () => Navigator.pop(context),
      onAdCompleted: () => _goToMainMenu(context),
      onAdFailed: (error) => _goToMainMenu(context),
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
              Text(AppLocalizations.of(context).adPlaying),
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
        content: Text('${AppLocalizations.of(context).adError}: $error'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: AppLocalizations.of(context).retry,
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
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

  void _goToitemsScreen(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const itemsScreen()),
          (route) => false,
    );
  }

  void _goToMainMenu(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainMenuScreen()),
    );
  }

  void _showCompletionDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('🎉 ${l10n.gameOverCongratulations}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.celebration, size: 60, color: Colors.amber),
              const SizedBox(height: 15),
              Text(
                l10n.gameOverAllLevelsCompleted,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.gameOverChampion,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.gameOverAwesome),
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
          title: Row(
            children: [
              const Icon(Icons.error, color: Colors.red),
              const SizedBox(width: 10),
              Text(AppLocalizations.of(context).error),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context).close),
            ),
          ],
        );
      },
    );
  }
}