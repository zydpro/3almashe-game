import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Languages/LanguageProvider.dart';
import '../models/level_data.dart';
import '../services/game_data_service.dart';
import 'game_screen.dart';
import '../Languages/localization.dart';

class LevelsScreen extends StatefulWidget {
  const LevelsScreen({super.key});

  @override
  State<LevelsScreen> createState() => _LevelsScreenState();
}

class _LevelsScreenState extends State<LevelsScreen> {
  List<LevelData> levels = [];
  bool isLoading = true;
  int unlockedLevelsCount = 0;
  int highScore = 0;
  int totalCoins = 0;

  // ✅ نفس إعدادات الحجم والظل من PauseMenuScreen
  double cornerShadowBlur = 10.0;
  double cornerShadowSpread = 2.0;
  Color cornerShadowColor = Colors.black.withOpacity(0.5);
  Offset cornerShadowOffset = const Offset(2, 2);
  double cornerIconSize = 50.0;
  double cornerButtonSize = 60.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final results = await Future.wait([
      LevelData.getAllLevels(),
      GameDataService.getUnlockedLevels(),
      GameDataService.getHighScore(),
      GameDataService.getTotalCoins(),
    ]);

    setState(() {
      levels = results[0] as List<LevelData>;
      unlockedLevelsCount = (results[1] as List<int>).length;
      highScore = results[2] as int;
      totalCoins = results[3] as int;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF2E4057),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 20),
              Text(
                l10n.loadingLevels,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2E4057),
              Color(0xFF048A81),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(l10n),

              // Player stats - تصميم جديد
              _buildStatsSection(l10n),

              // Levels grid
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900]!.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF048A81), width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: levels.length,
                      itemBuilder: (context, index) {
                        return _buildLevelCard(levels[index], l10n);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
        ),
      ),
      child: Row(
        children: [
          // ✅ إصلاح: تحديد حجم ثابت لزر الرجوع
          SizedBox(
            width: 60,
            height: 60,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 5,
                    spreadRadius: 1,
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.amber,
                  size: 25,
                ),
              ),
            ),
          ),

          const SizedBox(width: 10), // ✅ إضافة مسافة

          // ✅ إصلاح: استخدام Expanded للنص
          Expanded(
            child: Text(
              l10n.chooseLevel,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24, // ✅ تقليل حجم الخط
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Color(0xFFFFAE00),
                    blurRadius: 10,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 10), // ✅ إضافة مسافة

          // ✅ إصلاح: حجم ثابت لزر اللغة
          SizedBox(
            width: 60,
            height: 60,
            child: _buildLanguageToggleButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            l10n.highScore,
            highScore.toString(),
            Icons.star,
            Colors.yellow,
          ),
          _buildVerticalDivider(),
          _buildStatItem(
            l10n.coins,
            totalCoins.toString(),
            Icons.monetization_on,
            Colors.amber,
          ),
          _buildVerticalDivider(),
          _buildStatItem(
            l10n.unlockedLevels,
            '$unlockedLevelsCount/${levels.length}',
            Icons.lock_open,
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Colors.white.withOpacity(0.5),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.5), width: 2),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 4,
                offset: const Offset(1, 1),
              ),
            ],
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

// ✅ زر تبديل اللغة في الهيدر - بنفس تصميم SettingsScreen تماماً
  Widget _buildLanguageToggleButton() {
    return GestureDetector(
      onTap: () {
        final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
        languageProvider.toggleLanguage();
        setState(() {});
      },
      child: Container(
        width: cornerButtonSize, // ✅ نفس الحجم 60.0
        height: cornerButtonSize, // ✅ نفس الحجم 60.0
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.01),
          border: Border.all(
            color: Colors.white.withOpacity(0.01),
            width: 0.1,
          ),
          boxShadow: [
            BoxShadow(
              color: cornerShadowColor, // ✅ نفس الظل
              blurRadius: cornerShadowBlur, // ✅ نفس التمويه 10.0
              spreadRadius: cornerShadowSpread, // ✅ نفس الانتشار 2.0
              offset: cornerShadowOffset, // ✅ نفس الإزاحة Offset(2, 2)
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

// ✅ أيقونة اللغة الإنجليزية - بنفس تصميم SettingsScreen
  Widget _buildEnglishIcon() {
    return Image.asset(
      'assets/images/main_menu/english_icon.png',
      width: cornerIconSize, // ✅ نفس الحجم 50.0
      height: cornerIconSize, // ✅ نفس الحجم 50.0
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: cornerIconSize, // ✅ نفس الحجم 50.0
          height: cornerIconSize, // ✅ نفس الحجم 50.0
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF012169), Color(0xFFC8102E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(cornerIconSize / 2), // ✅ دائري بالكامل
          ),
          child: const Center(
            child: Text(
              'EN',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14, // ✅ نفس حجم الخط
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

// ✅ أيقونة اللغة العربية - بنفس تصميم SettingsScreen
  Widget _buildArabicIcon() {
    return Image.asset(
      'assets/images/main_menu/arabic_icon.png',
      width: cornerIconSize, // ✅ نفس الحجم 50.0
      height: cornerIconSize, // ✅ نفس الحجم 50.0
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: cornerIconSize, // ✅ نفس الحجم 50.0
          height: cornerIconSize, // ✅ نفس الحجم 50.0
          decoration: BoxDecoration(
            color: const Color(0xFF006233),
            borderRadius: BorderRadius.circular(cornerIconSize / 2), // ✅ دائري بالكامل
          ),
          child: const Center(
            child: Text(
              'ع',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20, // ✅ نفس حجم الخط
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLevelCard(LevelData level, AppLocalizations l10n) {
    final Languages = AppLocalizations.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: level.isUnlocked ? () => _startLevel(level) : null,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: BoxDecoration(
            gradient: level.isUnlocked
                ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                level.backgroundColor,
                level.backgroundColor.withOpacity(0.7),
              ],
            )
                : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey.shade600,
                Colors.grey.shade800,
              ],
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: level.isUnlocked
                  ? level.backgroundColor.withOpacity(0.8)
                  : Colors.grey.shade500,
              width: 2,
            ),
          ),
          child: Stack(
            children: [
              // تأثير خلفي
              if (level.isUnlocked)
                Positioned(
                  top: -10,
                  right: -10,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: level.backgroundColor.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Level number with lock/unlock state
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: level.isUnlocked ? Colors.white : Colors.grey.shade300,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(2, 2),
                          ),
                        ],
                        border: Border.all(
                          color: level.isUnlocked
                              ? level.backgroundColor.withOpacity(0.8)
                              : Colors.grey.shade500,
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: level.isUnlocked
                            ? Text(
                          level.levelNumber.toString(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: level.backgroundColor,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(1, 1),
                              ),
                            ],
                          ),
                        )
                            : const Icon(
                          Icons.lock,
                          color: Colors.grey,
                          size: 30,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Level name
                    Text(
                      level.getName(Languages),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 4,
                            offset: const Offset(1, 1),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Level description
                    Text(
                      level.getDescription(Languages),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.8),
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),

                    // Target score
                    if (level.isUnlocked)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${l10n.target}: ${level.targetScore}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // تأثير القفل للمراحل المقفلة
              if (!level.isUnlocked)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.black.withOpacity(0.6),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.lock_outline,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _startLevel(LevelData level) {
    if (!level.isUnlocked) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(levelData: level),
      ),
    );
  }
}