import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Languages/LanguageProvider.dart';
import '../services/game_data_service.dart';
import '../services/settings_service.dart';
import '../Languages/localization.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SettingsService _settingsService;

  // ✅ نفس إعدادات الحجم والظل من MainMenuScreen
  double cornerShadowBlur = 10.0;
  double cornerShadowSpread = 2.0;
  Color cornerShadowColor = Colors.black.withOpacity(0.5);
  Offset cornerShadowOffset = const Offset(2, 2);
  double cornerIconSize = 50.0;
  double cornerButtonSize = 60.0;

  int highScore = 0;
  int totalCoins = 0;
  int unlockedLevelsCount = 0;
  int currentLevel = 1;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _settingsService = SettingsService();
    _loadStats();
    _settingsService.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _settingsService.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    setState(() {});
  }

  void _loadStats() async {
    try {
      final highScoreResult = await GameDataService.getHighScore();
      final totalCoinsResult = await GameDataService.getTotalCoins();
      final unlockedLevelsResult = await GameDataService.getUnlockedLevels();
      final currentLevelResult = await GameDataService.getCurrentLevel();

      setState(() {
        highScore = highScoreResult;
        totalCoins = totalCoinsResult;
        unlockedLevelsCount = unlockedLevelsResult.length;
        currentLevel = currentLevelResult;
        isLoading = false;
      });
    } catch (e) {
      // print('خطأ في تحميل الإحصائيات: $e');
      setState(() {
        highScore = 0;
        totalCoins = 0;
        unlockedLevelsCount = 1;
        currentLevel = 1;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ استخدام listen: true فقط في الـ build method
    final languageProvider = Provider.of<LanguageProvider>(context, listen: true);
    final languages = AppLocalizations.of(context);

    if (isLoading) {
      return _buildLoadingScreen();
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
              _buildHeader(), // ✅ إزالة languageProvider من الباراميتر

              // Content
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),

                        // Game Settings Section
                        _buildSection(
                          languages.settings,
                          Icons.gamepad,
                          Colors.blue,
                          [
                            // ✅ إضافة خيار اللغة هنا
                            _buildLanguageOption(),

                            _buildSettingOption(
                              icon: Icons.volume_up,
                              text: languages.sound,
                              description: languages.sound,
                              value: _settingsService.soundEnabled,
                              onChanged: (value) => _settingsService.setSoundEnabled(value),
                              color: Colors.green,
                            ),
                            _buildSettingOption(
                              icon: Icons.music_note,
                              text: languages.music,
                              description: languages.music,
                              value: _settingsService.musicEnabled,
                              onChanged: (value) => _settingsService.setMusicEnabled(value),
                              color: Colors.purple,
                            ),
                            _buildSettingOption(
                              icon: Icons.vibration,
                              text: languages.vibration,
                              description: languages.vibration,
                              value: _settingsService.vibrationEnabled,
                              onChanged: (value) => _settingsService.setVibrationEnabled(value),
                              color: Colors.orange,
                            ),
                            _buildSettingOption(
                              icon: Icons.notifications,
                              text: languages.notifications,
                              description: languages.notifications,
                              value: _settingsService.notificationsEnabled,
                              onChanged: (value) => _settingsService.setNotificationsEnabled(value),
                              color: Colors.red,
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Game Progress Section
                        _buildSection(
                          languages.SettingsStatistics,
                          Icons.analytics,
                          Colors.amber,
                          [
                            _buildStatOption(
                              icon: Icons.star,
                              text: languages.highScore,
                              value: highScore.toString(),
                              color: Colors.yellow,
                            ),
                            _buildStatOption(
                              icon: Icons.monetization_on,
                              text: languages.totalCoins,
                              value: totalCoins.toString(),
                              color: Colors.amber,
                            ),
                            _buildStatOption(
                              icon: Icons.check_circle,
                              text: languages.unlockedLevels,
                              value: '${unlockedLevelsCount - 1}/100',
                              color: Colors.green,
                            ),
                            _buildStatOption(
                              icon: Icons.play_circle,
                              text: languages.currentLevel,
                              value: currentLevel.toString(),
                              color: Colors.blue,
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // App Actions Section
                        _buildSection(
                          languages.SettingsApplicationProcedures,
                          Icons.settings,
                          Colors.orange,
                          [
                            _buildActionOption(
                              icon: Icons.star_rate,
                              text: languages.SettingsGameRating,
                              description: languages.SettingsYourReview,
                              onTap: _rateApp,
                              color: Colors.orange,
                            ),
                            _buildActionOption(
                              icon: Icons.share,
                              text: languages.share,
                              description: languages.SettingsShareWithFriends,
                              onTap: _shareApp,
                              color: Colors.blue,
                            ),
                            _buildActionOption(
                              icon: Icons.refresh,
                              text: languages.SettingsResetData,
                              description: languages.SettingsDeleteAllData,
                              onTap: _resetGameData,
                              color: Colors.red,
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // About Section
                        _buildSection(
                          languages.about,
                          Icons.info,
                          Colors.grey,
                          [
                            _buildInfoOption(
                              icon: Icons.info_outline,
                              text: languages.version,
                              value: '1.0.0',
                            ),
                            _buildInfoOption(
                              icon: Icons.code,
                              text: languages.developer,
                              value: languages.almaSheTeam,
                            ),
                            _buildActionOption(
                              icon: Icons.privacy_tip,
                              text: languages.PrivacyPolicy,
                              description: languages.ReadOurPrivacyPolicy,
                              onTap: _openPrivacyPolicy,
                              color: Colors.grey,
                            ),
                            _buildActionOption(
                              icon: Icons.description,
                              text: languages.TermsOfUse,
                              description: languages.ReadTheTermsOfUse,
                              onTap: _openTermsOfService,
                              color: Colors.grey,
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                      ],
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

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.amber,
                size: 30,
              ),
            ),
            Expanded(
              child: Text(
                l10n.settings,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
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
            // ✅ إضافة زر اللغة في الهيدر
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: _buildLanguageToggleButton(),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: 2,
          color: Colors.white.withOpacity(0.3),
        ),
      ],
    );
  }

  // ✅ زر تبديل اللغة في الهيدر - بنفس تصميم MainMenuScreen تماماً
  Widget _buildLanguageToggleButton() { // ✅ إزالة الباراميتر
    return GestureDetector(
      onTap: () {
        // ✅ استخدام listen: false في event handlers
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
          // ✅ استخدام Consumer للجزء الذي يحتاج الاستماع للتغييرات
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

  // ✅ أيقونة اللغة الإنجليزية - بنفس تصميم MainMenuScreen
  Widget _buildEnglishIcon() {
    return Image.asset(
      'assets/images/main_menu/english_icon.png',
      width: cornerIconSize, // ✅ استخدام نفس حجم أيقونات الأزرار الجانبية
      height: cornerIconSize, // ✅ استخدام نفس حجم أيقونات الأزرار الجانبية
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: cornerIconSize, // ✅ استخدام نفس حجم أيقونات الأزرار الجانبية
          height: cornerIconSize, // ✅ استخدام نفس حجم أيقونات الأزرار الجانبية
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
                fontSize: 14, // ✅ حجم خط مناسب
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  // ✅ أيقونة اللغة العربية - بنفس تصميم MainMenuScreen
  Widget _buildArabicIcon() {
    return Image.asset(
      'assets/images/main_menu/arabic_icon.png',
      width: cornerIconSize, // ✅ استخدام نفس حجم أيقونات الأزرار الجانبية
      height: cornerIconSize, // ✅ استخدام نفس حجم أيقونات الأزرار الجانبية
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: cornerIconSize, // ✅ استخدام نفس حجم أيقونات الأزرار الجانبية
          height: cornerIconSize, // ✅ استخدام نفس حجم أيقونات الأزرار الجانبية
          decoration: BoxDecoration(
            color: const Color(0xFF006233),
            borderRadius: BorderRadius.circular(cornerIconSize / 2), // ✅ دائري بالكامل
          ),
          child: const Center(
            child: Text(
              'ع',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20, // ✅ حجم خط مناسب
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        );
      },
    );
  }

  // ✅ إضافة خيار اللغة
// ✅ إضافة خيار اللغة - معدلة
  Widget _buildLanguageOption() {
    final Languages = AppLocalizations.of(context);

    return Consumer<LanguageProvider>(
      // ✅ استخدام Consumer بدلاً من Provider.of مباشرة
      builder: (context, languageProvider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.language, color: Colors.blue, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'اللغة',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Language',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              DropdownButton<String>(
                value: languageProvider.currentLanguage,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    // ✅ لا حاجة لـ Provider.of هنا لأننا داخل Consumer
                    languageProvider.setLanguage(newValue);
                    setState(() {});
                  }
                },
                dropdownColor: Colors.grey[900],
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(color: Colors.white),
                items: <String>['ar', 'en']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Row(
                      children: [
                        value == 'ar'
                            ? Image.asset(
                          'assets/images/main_menu/arabic_icon.png',
                          width: 20,
                          height: 20,
                          errorBuilder: (context, error, stackTrace) {
                            return const Text('🇸🇦');
                          },
                        )
                            : Image.asset(
                          'assets/images/main_menu/english_icon.png',
                          width: 20,
                          height: 20,
                          errorBuilder: (context, error, stackTrace) {
                            return const Text('🇺🇸');
                          },
                        ),
                        const SizedBox(width: 8),
                        Text(
                          value == 'ar' ? 'العربية' : 'English',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  // ✅ أضف هذه الدالة للمساعدة في تحديث الواجهة
  Widget _buildLanguageAwareContent() {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final languages = AppLocalizations.of(context);

        return Column(
          children: [
            // كل محتوى الشاشة هنا
            // سيتم إعادة بنائه تلقائياً عند تغيير اللغة
          ],
        );
      },
    );
  }

  Widget _buildLoadingScreen() {
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
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 20),
              Text(
                'جاري تحميل الإحصائيات...',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, Color color, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.5), width: 2),
      ),
      child: Column(
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          // Section content
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingOption({
    required IconData icon,
    required String text,
    required String description,
    required bool value,
    required Function(bool) onChanged,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: color,
            inactiveThumbColor: Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildStatOption({
    required IconData icon,
    required String text,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionOption({
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
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
              Icon(
                Icons.arrow_forward_ios,
                color: color,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoOption({
    required IconData icon,
    required String text,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  void _rateApp() {
    final Languages = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900]!.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF048A81), width: 2),
          ),
          title: Text(
            Languages.rate,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, size: 50, color: Colors.amber), // ✅ أيقونة أصغر
              const SizedBox(height: 8),
              Text(
                Languages.rateYouHappy,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                Languages.rateHelpUs,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      Languages.later,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // _launchAppStore();
                    },
                    child: Text(Languages.rateNow),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _shareApp() {
    final Languages = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900]!.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF048A81), width: 2),
          ),
          title: Text(
            Languages.share,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            Languages.shareWithFriends,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      Languages.close,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // ✅ يمكنك إضافة وظيفة المشاركة الفعلية هنا
                      // _performShare();
                    },
                    child: Text(Languages.shareOnly),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _resetGameData() async {
    final Languages = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900]!.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF048A81), width: 2),
          ),
          title: Text(
            Languages.SettingsResetData,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18, // ✅ حجم أصغر
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            Languages.resetWillDelet,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14, // ✅ حجم أصغر
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      Languages.close,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await GameDataService.resetGameData();
                      Navigator.of(context).pop();
                      setState(() {
                        _loadStats();
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(Languages.resetDone),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: Text(Languages.delete),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _launchAppStore() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _buildStyledDialog(
          title: 'تقييم اللعبة',
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, size: 60, color: Colors.amber),
              SizedBox(height: 10),
              Text('شكراً لك! سيتم توجيهك إلى المتجر لتقييم اللعبة.'),
              SizedBox(height: 10),
              Text('في الإصدار النهائي، سيتم فتح صفحة اللعبة في متجر التطبيقات.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إغلاق'),
            ),
          ],
        );
      },
    );
  }

  void _openPrivacyPolicy() {
    // ✅ استخدام listen: false في event handlers
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final Languages = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _buildStyledDialog(
          title: Languages.PrivacyPolicy,
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // العنوان الرئيسي
                Center(
                  child: Text(
                    '🛡️ ${Languages.PrivacyPolicy}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 10),

                // تاريخ التحديث
                Center(
                  child: Text(
                    '${Languages.lastUpdate}: 11 أكتوبر 2025',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // النص التمهيدي
                Text(
                  '${Languages.welcomeToGame} "3almaShe Run – ${Languages.gameName}" ("${Languages.we}", "${Languages.theGame}", "${Languages.developmentTeam}").',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  Languages.privacyPolicyIntro,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),

                // البنود
                _buildPrivacySection(
                  '1. ${Languages.dataWeCollect}',
                  [
                    Languages.privacyPoint1,
                    Languages.privacyPoint2,
                    Languages.privacyPoint3,
                    Languages.privacyPoint4,
                  ],
                ),

                _buildPrivacySection(
                  '2. ${Languages.adsAndThirdParties}',
                  [
                    Languages.adsPoint1,
                    Languages.adsPoint2,
                  ],
                ),

                _buildPrivacySection(
                  '3. ${Languages.inAppPurchases}',
                  [
                    Languages.purchasesPoint1,
                  ],
                ),

                _buildPrivacySection(
                  '4. ${Languages.dataSecurity}',
                  [
                    Languages.securityPoint1,
                    Languages.securityPoint2,
                  ],
                ),

                _buildPrivacySection(
                  '5. ${Languages.childrenPrivacy}',
                  [
                    Languages.childrenPoint1,
                    Languages.childrenPoint2,
                  ],
                ),

                _buildPrivacySection(
                  '6. ${Languages.policyChanges}',
                  [
                    Languages.changesPoint1,
                    Languages.changesPoint2,
                  ],
                ),

                _buildPrivacySection(
                  '7. ${Languages.contactUs}',
                  [
                    Languages.contactPoint1,
                    '📧 support@3almashe.com',
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(Languages.close),
            ),
          ],
        );
      },
    );
  }

// ✅ دالة مساعدة لبناء أقسام سياسة الخصوصية
  Widget _buildPrivacySection(String title, List<String> points) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 15),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 10),
        ...points.map((point) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '• ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              Expanded(
                child: Text(
                  point,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  void _openTermsOfService() {
    // ✅ استخدام listen: false في event handlers
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final Languages = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _buildStyledDialog(
          title: Languages.TermsOfUse,
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // العنوان الرئيسي
                Center(
                  child: Text(
                    '⚖️ ${Languages.TermsOfUse}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 10),

                // تاريخ التحديث
                Center(
                  child: Text(
                    '${Languages.lastUpdate}: 11 أكتوبر 2025',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // النص التمهيدي
                Text(
                  '${Languages.welcomeToGame} "3almaShe Run – ${languageProvider.isArabic ? 'عالماشي اركض' : '3almaShe Arkod'}" ("${Languages.we}", "${Languages.theGame}", "${Languages.developmentTeam}").',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  languageProvider.isArabic
                      ? 'باستخدامك للعبة، فإنك توافق على الالتزام بهذه الشروط والأحكام. يرجى قراءتها بعناية قبل البدء في اللعب.'
                      : 'By downloading or playing this game, you agree to comply with these Terms of Use. Please read them carefully before starting.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),

                // البنود
                _buildTermsSection(
                  '1. ${Languages.termsAcceptance}',
                  languageProvider.isArabic
                      ? 'باستخدام اللعبة أو تثبيتها، فإنك تقر بأنك قد قرأت وفهمت هذه الشروط وتوافق على الالتزام بها. إذا كنت لا توافق على أي جزء من هذه الشروط، يرجى عدم استخدام اللعبة.'
                      : 'By installing or using this game, you acknowledge that you have read, understood, and agreed to these terms. If you do not agree with any part of the terms, please do not use the game.',
                ),

                _buildTermsSection(
                  '2. ${Languages.termsLicense}',
                  languageProvider.isArabic
                      ? 'نمنحك ترخيصًا محدودًا، غير حصري، وغير قابل للتحويل، لاستخدام اللعبة فقط للأغراض الشخصية والترفيهية. يُحظر تمامًا:\n• تعديل أو نسخ أو إعادة بيع اللعبة أو أي جزء منها.\n• استخدام اللعبة لأي غرض تجاري غير مصرح به.\n• محاولة الوصول إلى الكود المصدري أو تجاوز الحماية.'
                      : 'We grant you a limited, non-exclusive, non-transferable license to use the game solely for personal entertainment. You must not:\n• Modify, copy, or redistribute the game or any part of it.\n• Use the game for unauthorized commercial purposes.\n• Attempt to access the source code or bypass security mechanisms.',
                ),

                _buildTermsSection(
                  '3. ${Languages.termsContent}',
                  languageProvider.isArabic
                      ? 'قد تحتوي اللعبة على عناصر يمكن شراؤها أو فتحها أثناء التقدم في اللعب. كل العناصر الافتراضية (مثل الشخصيات أو النقاط أو العملات داخل اللعبة) ليس لها قيمة مالية حقيقية ولا يمكن استبدالها بأموال حقيقية.'
                      : 'The game may include virtual items or content that can be unlocked or purchased during gameplay. All such virtual items have no real-world monetary value and cannot be exchanged for real currency.',
                ),

                _buildTermsSection(
                  '4. ${Languages.termsAds}',
                  languageProvider.isArabic
                      ? 'اللعبة قد تعرض إعلانات أو تستخدم خدمات طرف ثالث مثل Unity Ads أو Google AdMob. نحن غير مسؤولين عن محتوى أو دقة أي إعلان أو رابط خارجي يظهر داخل اللعبة.'
                      : 'The game may display advertisements or use third-party services such as Unity Ads or Google AdMob. We are not responsible for the content or accuracy of any external links or ads displayed within the game.',
                ),

                _buildTermsSection(
                  '5. ${Languages.termsUpdates}',
                  languageProvider.isArabic
                      ? 'نحتفظ بالحق في تحديث اللعبة أو تعديلها أو إيقافها مؤقتًا أو نهائيًا في أي وقت دون إشعار مسبق. قد تتطلب بعض التحديثات إعادة تنزيل أو تثبيت اللعبة.'
                      : 'We reserve the right to update, modify, or temporarily or permanently discontinue the game at any time without prior notice. Some updates may require you to re-download or reinstall the game.',
                ),

                _buildTermsSection(
                  '6. ${Languages.termsDisclaimer}',
                  languageProvider.isArabic
                      ? 'اللعبة مقدمة كما هي "AS IS" بدون أي ضمانات صريحة أو ضمنية. لا نتحمل مسؤولية أي ضرر مباشر أو غير مباشر ينتج عن استخدامك للعبة، بما في ذلك فقدان البيانات أو الأعطال.'
                      : 'The game is provided "AS IS" without warranties of any kind, express or implied. We shall not be held liable for any direct or indirect damages arising from the use of the game, including data loss or device issues.',
                ),

                _buildTermsSection(
                  '7. ${Languages.termsTermination}',
                  languageProvider.isArabic
                      ? 'نحتفظ بالحق في إيقاف وصولك إلى اللعبة في أي وقت إذا خالفت هذه الشروط أو استخدمت اللعبة بطريقة غير قانونية.'
                      : 'We reserve the right to suspend or terminate your access to the game at any time if you violate these terms or use the game unlawfully.',
                ),

                _buildTermsSection(
                  '8. ${Languages.termsLaw}',
                  languageProvider.isArabic
                      ? 'تخضع هذه الشروط وتُفسَّر وفقًا للقوانين المعمول بها في بلد مطوّر اللعبة، دون النظر إلى تعارض القوانين.'
                      : 'These Terms shall be governed and interpreted in accordance with the laws of the developer\'s country, without regard to conflict of law principles.',
                ),

                _buildTermsSection(
                  '9. ${Languages.contactUs}',
                  languageProvider.isArabic
                      ? 'لأي استفسار أو ملاحظات حول شروط الاستخدام، يمكنك التواصل معنا عبر البريد الإلكتروني:\n📧 support@3almashe.com'
                      : 'For any questions or feedback regarding these Terms of Use, please contact us at:\n📧 support@3almashe.com',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(Languages.close),
            ),
          ],
        );
      },
    );
  }

// ✅ دالة مساعدة لبناء أقسام شروط الاستخدام
  Widget _buildTermsSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 15),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildStyledDialog({
    required String title,
    required Widget content,
    required List<Widget> actions,
  }) {
    return Dialog(
      backgroundColor: Colors.grey[900]!.withOpacity(0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF048A81), width: 2),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8, // ✅ تحديد أقصى ارتفاع
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Expanded( // ✅ جعل المحتوى قابل للتمرير
                child: SingleChildScrollView(
                  child: content,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: actions,
              ),
            ],
          ),
        ),
      ),
    );
  }
}