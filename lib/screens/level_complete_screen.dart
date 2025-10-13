import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Languages/LanguageProvider.dart';
import '../Languages/localization.dart';
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
    final l10n = AppLocalizations.of(context);
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
                // ✅ إضافة الهيدر مع زر اللغة
                _buildHeader(context, l10n),

                // محتوى التهاني
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.celebration, size: 100, color: Colors.white),
                        const SizedBox(height: 20),
                        Text(
                          l10n.levelCompleteCongratulations,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),

                        // ✅ إصلاح: استخدام levelData مباشرة (ليست null)
                        Text(
                          l10n.levelCompleteMessage(levelData.getName(l10n)),
                          style: const TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          '${l10n.score}: $score',
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.yellow,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          '${l10n.coins}: +$coinsEarned',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.amber,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        if (nextLevel != null)
                          Text(
                            l10n.levelCompleteUnlocked(nextLevel!.levelNumber),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.lightGreen,
                            ),
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),
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
                            l10n.nextLevel,
                            Icons.arrow_forward,
                            Colors.blue,
                                () => _startNextLevelWithAd(context),
                          ),

                        if (nextLevel != null) const SizedBox(height: 15),

                        _buildActionButton(
                          l10n.restartLevel,
                          Icons.refresh,
                          Colors.green,
                              () => _restartLevel(context),
                        ),

                        const SizedBox(height: 15),

                        _buildActionButton(
                          l10n.levelsMenu,
                          Icons.list,
                          Colors.orange,
                              () => _goToLevels(context),
                        ),

                        const SizedBox(height: 15),

                        _buildActionButton(
                          l10n.mainMenu,
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

  // ✅ إضافة الهيدر مع زر اللغة
  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ✅ إصلاح: استخدام Container بعرض ثابت
          Container(
            width: 60,
            height: 60,
            child: const SizedBox(), // مساحة فارغة متوازنة
          ),

          // ✅ إصلاح: استخدام Expanded للنص
          Expanded(
            child: Text(
              l10n.levelComplete,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24, // ✅ تقليل حجم الخط
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

          // ✅ إصلاح: حجم ثابت لزر اللغة
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
    final l10n = AppLocalizations.of(context);

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
              Text(l10n.loadingAd),
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