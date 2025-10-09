import 'package:flutter/material.dart';
import '../services/ads_service.dart';
import '../services/settings_service.dart';
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

class _PauseMenuScreenState extends State<PauseMenuScreen> {
  late SettingsService _settingsService;

  @override
  void initState() {
    super.initState();
    _settingsService = SettingsService();
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

  void _resumeGame() {
    Navigator.pop(context);
    widget.onResume();
  }

  void _restartLevel() {
    Navigator.pop(context);
    _showAdAndRestart();
  }

  void _showAdAndRestart() {
    print('🔄 بدء عملية إعادة التشغيل مع الإعلان');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          title: const Text(
            'جاري عرض الإعلان',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              const Text(
                'يرجى الانتظار...',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 10),
              Text(
                'بعد انتهاء الإعلان ستبدأ المرحلة من جديد',
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
        print('▶️ إعلان إعادة التشغيل بدأ');
        Navigator.pop(context); // إغلاق dialog الانتظار
      },
      onAdCompleted: () {
        print('✅ إعلان إعادة التشغيل اكتمل - الانتقال للعبة');
        widget.onRestart();
      },
      onAdFailed: (error) {
        print('❌ إعلان إعادة التشغيل فشل: $error - الاستمرار بدون إعلان');
        Navigator.pop(context); // إغلاق dialog الانتظار
        widget.onRestart(); // استمرار اللعبة حتى لو فشل الإعلان
      },
    );
  }

  void _goToMainMenu() {
    print('🏠 المستخدم ضغط على "العودة للقائمة الرئيسية" مع إعلان');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          title: const Text(
            'جاري عرض الإعلان',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              const Text(
                'يرجى الانتظار...',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 10),
              Text(
                'بعد انتهاء الإعلان ستعود للقائمة الرئيسية',
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
        print('▶️ إعلان العودة للقائمة الرئيسية بدأ');
        Navigator.pop(context); // إغلاق dialog الانتظار
      },
      onAdCompleted: () {
        print('✅ إعلان العودة للقائمة الرئيسية اكتمل');
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainMenuScreen()),
              (route) => false,
        );
      },
      onAdFailed: (error) {
        print('❌ إعلان العودة للقائمة الرئيسية فشل: $error');
        Navigator.pop(context); // إغلاق dialog الانتظار
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

  @override
  Widget build(BuildContext context) {
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
              const Text(
                'اللعبة متوقفة',
                style: TextStyle(
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

              const SizedBox(height: 30),

              _buildOptionButton(
                icon: Icons.play_arrow,
                text: 'استئناف اللعبة',
                description: 'استكمال المرحلة من حيث توقفت',
                onTap: _resumeGame,
                color: Colors.green,
              ),

              const SizedBox(height: 20),

              _buildOptionButton(
                icon: Icons.refresh,
                text: 'إعادة المرحلة',
                description: 'شاهد إعلان ثم حاول من جديد',
                onTap: _restartLevel,
                color: Colors.orange,
              ),

              const SizedBox(height: 20),

              _buildOptionButton(
                icon: Icons.home,
                text: 'العودة للقائمة الرئيسية',
                description: 'شاهد إعلان ثم ارجع للقائمة',
                onTap: _goToMainMenu,
                color: Colors.blue,
              ),

              const SizedBox(height: 30),

              _buildSettingsSection(),
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

  Widget _buildSettingsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey, width: 1),
      ),
      child: Column(
        children: [
          const Text(
            'الإعدادات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 15),

          // ✅ إضافة زر الموسيقى
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.music_note, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    'الموسيقى',
                    style: TextStyle(color: Colors.white),
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

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.volume_up, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    'الأصوات',
                    style: TextStyle(color: Colors.white),
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

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.vibration, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    'الاهتزاز',
                    style: TextStyle(color: Colors.white),
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