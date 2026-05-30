import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Languages/LanguageProvider.dart';
import '../models/level_data.dart';
import '../services/Payment_UI_Service.dart';
import '../services/game_data_service.dart';
import '../services/ads_service.dart';
import '../services/ads_removal_service.dart';
import '../services/payment_service.dart';
import 'game_screen.dart';
import 'items_screen.dart';
import 'main_menu_screen.dart';
import 'store_screen.dart';
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

  // ✅ إعدادات التصميم المعدلة
  final double cornerShadowBlur = 8.0;
  final double cornerShadowSpread = 1.0;
  final Color cornerShadowColor = Colors.black.withOpacity(0.4);
  final Offset cornerShadowOffset = const Offset(1, 1);
  final double cornerIconSize = 40.0;
  final double cornerButtonSize = 50.0;

  late PaymentUIService _paymentUIService;

  @override
  void initState() {
    super.initState();
    _paymentUIService = PaymentUIService();
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
    final routeSettings = ModalRoute.of(context)?.settings;
    final bool cameFromItems = routeSettings?.name == '/levels_from_items';

    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF2E4057),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 16),
              Text(
                l10n.loadingLevels,
                style: const TextStyle(color: Colors.white, fontSize: 16),
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
              _buildHeader(l10n, cameFromItems),

              // Player stats - تصميم جديد
              _buildStatsSection(l10n),

              // ✅ قسم الأزرار الإضافية
              _buildActionButtonsSection(l10n),

              // Levels grid
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[900]!.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF048A81), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
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

  Widget _buildHeader(AppLocalizations l10n, bool cameFromItems) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          // ✅ زر الرجوع - يعود إلى الشاشة السابقة بناءً على المصدر
          SizedBox(
            width: 50,
            height: 50,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    spreadRadius: 1,
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () {
                  if (cameFromItems) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const MainMenuScreen()),
                          (route) => false,
                    );
                  }
                },
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.amber,
                  size: 22,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // ✅ عنوان الشاشة
          Expanded(
            child: Text(
              l10n.chooseLevel,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Color(0xFFFFAE00),
                    blurRadius: 8,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // ✅ زر اللغة
          SizedBox(
            width: 50,
            height: 50,
            child: _buildLanguageToggleButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
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

  // ✅ قسم الأزرار الإضافية الجديد
  Widget _buildActionButtonsSection(AppLocalizations l10n) {
    return Consumer<AdsRemovalService>(
      builder: (context, adsService, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[900]!.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 15,
                spreadRadius: 3,
              ),
            ],
          ),
          child: Row(
            children: [
              // ✅ زر الذهاب إلى المتجر
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.purple, Colors.deepPurple],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _goToStore,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.store, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            l10n.store,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // ✅ زر إزالة الإعلانات - محدث
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: adsService.isActive
                        ? const LinearGradient(colors: [Colors.green, Colors.lightGreen])
                        : const LinearGradient(colors: [Colors.red, Colors.orange]),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: (adsService.isActive ? Colors.green : Colors.red).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => _openAdsRemovalOptions(adsService),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          adsService.isActive ? Icons.check_circle : Icons.block,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            adsService.isActive ? l10n.adsDisabled : l10n.removeAds,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // ✅ زر الذهاب إلى الشخصيات
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.teal, Colors.green],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _goToItems,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            l10n.myCharacters,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 30,
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
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.5), width: 1.5),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 3,
                offset: const Offset(1, 1),
              ),
            ],
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ✅ زر تبديل اللغة
  Widget _buildLanguageToggleButton() {
    return GestureDetector(
      onTap: () {
        final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
        languageProvider.toggleLanguage();
        setState(() {});
      },
      child: Container(
        width: cornerButtonSize,
        height: cornerButtonSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.01),
          border: Border.all(
            color: Colors.white.withOpacity(0.01),
            width: 0.1,
          ),
          boxShadow: [
            BoxShadow(
              color: cornerShadowColor,
              blurRadius: cornerShadowBlur,
              spreadRadius: cornerShadowSpread,
              offset: cornerShadowOffset,
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

  Widget _buildEnglishIcon() {
    return Image.asset(
      'assets/images/main_menu/english_icon.png',
      width: cornerIconSize,
      height: cornerIconSize,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: cornerIconSize,
          height: cornerIconSize,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF012169), Color(0xFFC8102E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(cornerIconSize / 2),
          ),
          child: const Center(
            child: Text(
              'EN',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildArabicIcon() {
    return Image.asset(
      'assets/images/main_menu/arabic_icon.png',
      width: cornerIconSize,
      height: cornerIconSize,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: cornerIconSize,
          height: cornerIconSize,
          decoration: BoxDecoration(
            color: const Color(0xFF006233),
            borderRadius: BorderRadius.circular(cornerIconSize / 2),
          ),
          child: const Center(
            child: Text(
              'ع',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
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
        onTap: level.isUnlocked ? () => _startLevelWithAd(level, l10n) : null,
        borderRadius: BorderRadius.circular(12),
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
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(
              color: level.isUnlocked
                  ? level.backgroundColor.withOpacity(0.8)
                  : Colors.grey.shade500,
              width: 1.5,
            ),
          ),
          child: Stack(
            children: [
              // تأثير خلفي
              if (level.isUnlocked)
                Positioned(
                  top: -8,
                  right: -8,
                  child: Container(
                    width: 25,
                    height: 25,
                    decoration: BoxDecoration(
                      color: level.backgroundColor.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Level number with lock/unlock state
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: level.isUnlocked ? Colors.white : Colors.grey.shade300,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(1, 1),
                          ),
                        ],
                        border: Border.all(
                          color: level.isUnlocked
                              ? level.backgroundColor.withOpacity(0.8)
                              : Colors.grey.shade500,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: level.isUnlocked
                            ? Text(
                          level.levelNumber.toString(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: level.backgroundColor,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 3,
                                offset: const Offset(1, 1),
                              ),
                            ],
                          ),
                        )
                            : const Icon(
                          Icons.lock,
                          color: Colors.grey,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Level name
                    Text(
                      level.getName(Languages),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 3,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Level description
                    Text(
                      level.getDescription(Languages),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.8),
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Target score
                    if (level.isUnlocked)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${l10n.target}: ${level.targetScore}',
                          style: const TextStyle(
                            fontSize: 10,
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
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.black.withOpacity(0.6),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.lock_outline,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ بدء المرحلة مع إعلان (يتخطى الإعلان إذا كانت الإعلانات معطلة)
  void _startLevelWithAd(LevelData level, AppLocalizations l10n) {
    if (!level.isUnlocked) return;

    final adsService = Provider.of<AdsRemovalService>(context, listen: false);

    // ✅ إذا كانت الإعلانات معطلة، ابدأ المرحلة مباشرة
    if (adsService.isActive) {
      _startLevel(level);
      return;
    }

    // ✅ إذا كانت الإعلانات مفعلة، اعرض إعلان مباشرة بدون نافذة تأكيد
    _playAdAndStartLevel(level, l10n);
  }

  // ✅ تشغيل الإعلان وبدء المرحلة (بدون نافذة تأكيد)
  void _playAdAndStartLevel(LevelData level, AppLocalizations l10n) {
    // ✅ عرض تحميل أثناء تحميل الإعلان
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            l10n.loadingAd,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                l10n.loading,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        );
      },
    );

    AdsService.showInterstitialAd(
      onAdStarted: () {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      },
      onAdCompleted: () {
        _startLevel(level);
      },
      onAdFailed: (error) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        _startLevel(level);
        _showAdErrorSnackBar(l10n);
      },
    );
  }

  void _showAdErrorSnackBar(AppLocalizations l10n) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.adFailed,
          style: const TextStyle(fontSize: 14),
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _startLevel(LevelData level) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(levelData: level),
      ),
    );
  }

  // ✅ دوال التنقل
  void _goToStore() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StoreScreen()),
    );
  }

  void _goToItems() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const itemsScreen(),
        settings: const RouteSettings(name: '/items_from_levels'),
      ),
    );
  }

  // ✅ دالة فتح خيارات إزالة الإعلانات مباشرة
  void _openAdsRemovalOptions(AdsRemovalService adsService) {
    final l10n = AppLocalizations.of(context);

    if (adsService.isActive) {
      _showCurrentAdsStatus(l10n, adsService);
      return;
    }

    _showAdsRemovalOptions(l10n, adsService);
  }

  // ✅ عرض خيارات إزالة الإعلانات
  void _showAdsRemovalOptions(AppLocalizations l10n, AdsRemovalService adsService) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.grey[900]!.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF048A81), width: 2),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.adsRemoval,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ✅ استخدام الخدمة الجديدة لحالة الدفع
                  _paymentUIService.buildPaymentStatus(l10n, onRetry: () {
                    final paymentService = Provider.of<PaymentService>(context, listen: false);
                    paymentService.initialize();
                  }),

                  const SizedBox(height: 20),

                  // ✅ استخدام الخدمة الجديدة لخيارات الإعلانات
                  ..._paymentUIService.buildAllAdsRemovalOptions(l10n, _purchaseAdsRemoval),

                  const SizedBox(height: 16),
                  _buildTemporaryRemovalOption(l10n, adsService),
                  const SizedBox(height: 20),

                  // زر الإغلاق
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[700],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        l10n.close,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentStatus(AppLocalizations l10n) {
    return _paymentUIService.buildPaymentStatus(l10n, onRetry: () {
      final paymentService = Provider.of<PaymentService>(context, listen: false);
      paymentService.initialize();
    });
  }

  // ✅ خيار الإزالة المؤقتة
  Widget _buildTemporaryRemovalOption(AppLocalizations l10n, AdsRemovalService adsService) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showTemporaryRemovalConfirmation(l10n, adsService),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue, width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.play_circle,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l10n.watchAdToRemove} 30 ${l10n.minutes}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      l10n.removeAdsTemporarily,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.blue,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ حالة الإعلانات الحالية
  Widget _buildCurrentAdsStatus(AppLocalizations l10n, AdsRemovalService adsService) {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (adsService.isActive) {
      statusText = adsService.isTemporary ? l10n.removeAdsTemporarily : l10n.adsDisabled;
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;

      if (adsService.expiryDate != null) {
        bool isArabic = l10n.locale.languageCode == 'ar';
        statusText += ' (${adsService.getRemainingTime(isArabic: isArabic)})';
      } else if (!adsService.isTemporary) {
        statusText += ' (${l10n.lifetime})';
      }
    } else {
      statusText = l10n.adsEnabled;
      statusColor = Colors.orange;
      statusIcon = Icons.ad_units;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor, width: 1),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 14,
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ دوال معالجة الشراء
  void _purchaseAdsRemoval(String productId) async {
    final paymentService = Provider.of<PaymentService>(context, listen: false);
    await paymentService.purchaseProduct(productId);
  }

  void _showTemporaryRemovalConfirmation(AppLocalizations l10n, AdsRemovalService adsService) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900]!.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.blue, width: 2),
          ),
          title: Text(
            l10n.removeAdsTemporarily,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.play_circle, size: 50, color: Colors.blue),
                const SizedBox(height: 12),
                Text(
                  '${l10n.watchAdToRemove} 30 ${l10n.minutes}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      l10n.cancel,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _processTemporaryRemoval(l10n, adsService);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    child: Text(
                      l10n.watchAd,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _processTemporaryRemoval(AppLocalizations l10n, AdsRemovalService adsService) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            l10n.loadingAd,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                l10n.loading,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        );
      },
    );

    try {
      await AdsService.showRewardedAd(
        onAdStarted: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        },
        onAdCompleted: () async {
          final removalSuccess = await adsService.removeAdsTemporarily(const Duration(minutes: 30));
          if (removalSuccess && mounted) {
            _showTemporaryRemovalSuccess(l10n);
          } else if (mounted) {
            _showPurchaseError(l10n);
          }
        },
        onAdFailed: (error) {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          if (mounted) {
            _showAdError(l10n);
          }
        },
      );
    } catch (e) {
      if (mounted) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        _showAdError(l10n);
      }
    }
  }

  void _showTemporaryRemovalSuccess(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900]!.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.blue, width: 2),
          ),
          title: Text(
            l10n.purchaseSuccessful,
            style: const TextStyle(color: Colors.blue, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, size: 50, color: Colors.blue),
              const SizedBox(height: 12),
              Text(
                '${l10n.purchaseSuccessMessage}\n\n${l10n.remainingTime}: 30 ${l10n.minutes}',
                style: const TextStyle(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                child: Text(l10n.close, style: const TextStyle(fontSize: 14)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPurchaseError(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900]!.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.red, width: 2),
          ),
          title: Text(
            l10n.purchaseFailed,
            style: const TextStyle(color: Colors.red, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error, size: 50, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                l10n.purchaseErrorMessage,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: Text(l10n.close, style: const TextStyle(fontSize: 14)),
              ),
            ),
          ],
        );
      },
    );
  }

  // ✅ عرض خطأ في الإعلان
  void _showAdError(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900]!.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.red, width: 2),
          ),
          title: Text(
            l10n.adFailed,
            style: const TextStyle(color: Colors.red, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error, size: 50, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                l10n.adFailedMessage,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: Text(l10n.close, style: const TextStyle(fontSize: 14)),
              ),
            ),
          ],
        );
      },
    );
  }

  // ✅ عرض حالة الإعلانات الحالية
  void _showCurrentAdsStatus(AppLocalizations l10n, AdsRemovalService adsService) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900]!.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.green, width: 2),
          ),
          title: Text(
            l10n.adsStatus,
            style: const TextStyle(
              color: Colors.green,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, size: 50, color: Colors.green),
              const SizedBox(height: 12),
              _buildCurrentAdsStatus(l10n, adsService),
              const SizedBox(height: 12),
              Text(
                l10n.noAdsEnjoy,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: Text(l10n.close, style: const TextStyle(fontSize: 14)),
              ),
            ),
          ],
        );
      },
    );
  }
}