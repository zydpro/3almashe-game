import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ads_service.dart';
import '../services/settings_service.dart';
import '../Languages/LanguageProvider.dart';
import '../Languages/localization.dart'; // ✅ إضافة الاستيراد
import 'main_menu_screen.dart';

class PauseMenuScreen extends StatefulWidget {
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final bool isGamePaused;

  const PauseMenuScreen({
    super.key,
    required this.onResume,
    required this.onRestart,
    required this.isGamePaused,
  });

  @override
  State<PauseMenuScreen> createState() => _PauseMenuScreenState();
}

class _PauseMenuScreenState extends State<PauseMenuScreen> with SingleTickerProviderStateMixin {
  late SettingsService _settingsService;
  late AnimationController _languageAnimationController;
  late Animation<double> _languageScaleAnimation;

  // ✅ نفس إعدادات الحجم والظل من SettingsScreen
  double cornerShadowBlur = 10.0;
  double cornerShadowSpread = 2.0;
  Color cornerShadowColor = Colors.black.withOpacity(0.5);
  Offset cornerShadowOffset = const Offset(2, 2);
  double cornerIconSize = 50.0;
  double cornerButtonSize = 60.0;

  @override
  void initState() {
    super.initState();
    _settingsService = SettingsService();
    _settingsService.addListener(_onSettingsChanged);
    _initLanguageAnimation();
  }

  void _initLanguageAnimation() {
    _languageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _languageScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.7), weight: 0.5),
      TweenSequenceItem(tween: Tween(begin: 0.7, end: 1.0), weight: 0.5),
    ]).animate(CurvedAnimation(
      parent: _languageAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _settingsService.removeListener(_onSettingsChanged);
    _languageAnimationController.dispose();
    super.dispose();
  }

  void _onSettingsChanged() {
    setState(() {});
  }

  void _resumeGame() {
    Navigator.pop(context);
    widget.onResume();
  }

  void _restartLevel() {
    Navigator.pop(context);
    _showAdAndRestart();
  }

  void _showAdAndRestart() {
    final l10n = AppLocalizations.of(context); // ✅ استخدام الترجمة

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          title: Text(
            l10n.loadingAd, // ✅ 'جاري تحميل الإعلان...'
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                l10n.loading, // ✅ 'جاري التحميل...'
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.pauseAdRestart, // ✅ 'بعد انتهاء الإعلان ستبدأ المرحلة من جديد'
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );

    AdsService.showInterstitialAd(
      onAdStarted: () {
        Navigator.pop(context);
      },
      onAdCompleted: () {
        widget.onRestart();
      },
      onAdFailed: (error) {
        Navigator.pop(context);
        widget.onRestart();
      },
    );
  }

  void _goToMainMenu() {
    final l10n = AppLocalizations.of(context); // ✅ استخدام الترجمة

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          title: Text(
            l10n.loadingAd, // ✅ 'جاري تحميل الإعلان...'
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                l10n.loading, // ✅ 'جاري التحميل...'
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.pauseAdMainMenu, // ✅ 'بعد انتهاء الإعلان ستعود للقائمة الرئيسية'
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );

    AdsService.showInterstitialAd(
      onAdStarted: () {
        Navigator.pop(context);
      },
      onAdCompleted: () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainMenuScreen()),
              (route) => false,
        );
      },
      onAdFailed: (error) {
        Navigator.pop(context);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainMenuScreen()),
              (route) => false,
        );
      },
    );
  }

  void _toggleSound() {
    _settingsService.toggleSound();
  }

  void _toggleMusic() {
    _settingsService.toggleMusic();
  }

  void _toggleVibration() {
    _settingsService.toggleVibration();
  }

  // ✅ دالة تبديل اللغة
  Future<void> _toggleLanguage(LanguageProvider languageProvider) async {
    await _languageAnimationController.forward();
    await languageProvider.toggleLanguage();
    await _languageAnimationController.reverse();
  }

  // ✅ زر تبديل اللغة في الهيدر - بنفس تصميم SettingsScreen تماماً
  Widget _buildLanguageToggleButton() {
    return GestureDetector(
      onTap: () {
        final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
        _toggleLanguage(languageProvider);
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

  // ✅ أيقونة اللغة الإنجليزية - بنفس تصميم SettingsScreen
  Widget _buildEnglishIcon() {
    return Image.asset(
      'assets/images/main_menu/english_icon.png',
      width: cornerIconSize, // ✅ نفس الحجم 50.0
      height: cornerIconSize, // ✅ نفس الحجم 50.0
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
                fontSize: 14,
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context); // ✅ استخدام الترجمة

    return Scaffold(
      backgroundColor: Colors.black54,
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey[900]!.withOpacity(0.95),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.orange, width: 3),
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
              // ✅ إضافة زر اللغة في الهيدر
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 10), // مساحة فارغة للتوازن
                  Text(
                    l10n.pauseTitle, // ✅ 'اللعبة متوقفة'
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.orange,
                          blurRadius: 10,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                  // _buildLanguageToggleButton(), // ✅ زر اللغة
                ],
              ),

              const SizedBox(height: 30),

              _buildOptionButton(
                icon: Icons.play_arrow,
                text: l10n.resume, // ✅ 'استئناف اللعبة'
                description: l10n.pauseResumeDesc, // ✅ 'استكمال المرحلة من حيث توقفت'
                onTap: _resumeGame,
                color: Colors.green,
              ),

              const SizedBox(height: 20),

              _buildOptionButton(
                icon: Icons.refresh,
                text: l10n.restartLevel, // ✅ 'إعادة المرحلة'
                description: l10n.pauseRestartDesc, // ✅ 'شاهد إعلان ثم حاول من جديد'
                onTap: _restartLevel,
                color: Colors.orange,
              ),

              const SizedBox(height: 20),

              _buildOptionButton(
                icon: Icons.home,
                text: l10n.mainMenu, // ✅ 'العودة للقائمة الرئيسية'
                description: l10n.pauseMainMenuDesc, // ✅ 'شاهد إعلان ثم ارجع للقائمة'
                onTap: _goToMainMenu,
                color: Colors.blue,
              ),

              const SizedBox(height: 30),

              _buildSettingsSection(l10n),
            ],
          ),
        ),
      ),
    );
  }

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

  Widget _buildSettingsSection(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey, width: 1),
      ),
      child: Column(
        children: [
          Text(
            l10n.settings, // ✅ 'الإعدادات'
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 15),

          // ✅ إعدادات اللغة
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.language, color: Colors.white),
                  const SizedBox(width: 10),
                  Text(
                    l10n.pauseLanguage, // ✅ 'اللغة'
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
              _buildLanguageToggleButton(),
            ],
          ),

          const SizedBox(height: 10),

          // ✅ إعدادات الموسيقى
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.music_note, color: Colors.white),
                  const SizedBox(width: 10),
                  Text(
                    l10n.music, // ✅ 'الموسيقى'
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
              Switch(
                value: _settingsService.musicEnabled,
                onChanged: (value) => _toggleMusic(),
                activeColor: Colors.green,
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ✅ إعدادات الأصوات
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.volume_up, color: Colors.white),
                  const SizedBox(width: 10),
                  Text(
                    l10n.sound, // ✅ 'الأصوات'
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
              Switch(
                value: _settingsService.soundEnabled,
                onChanged: (value) => _toggleSound(),
                activeColor: Colors.green,
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ✅ إعدادات الاهتزاز
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.vibration, color: Colors.white),
                  const SizedBox(width: 10),
                  Text(
                    l10n.vibration, // ✅ 'الاهتزاز'
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
              Switch(
                value: _settingsService.vibrationEnabled,
                onChanged: (value) => _toggleVibration(),
                activeColor: Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }
}