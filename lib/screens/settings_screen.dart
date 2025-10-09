import 'package:flutter/material.dart';
import '../services/game_data_service.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SettingsService _settingsService;

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
      print('خطأ في تحميل الإحصائيات: $e');
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
              _buildHeader(),

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
                          'إعدادات اللعبة',
                          Icons.gamepad,
                          Colors.blue,
                          [
                            _buildSettingOption(
                              icon: Icons.volume_up,
                              text: 'الأصوات',
                              description: 'تشغيل أصوات اللعبة',
                              value: _settingsService.soundEnabled,
                              onChanged: (value) => _settingsService.setSoundEnabled(value),
                              color: Colors.green,
                            ),
                            _buildSettingOption(
                              icon: Icons.music_note,
                              text: 'الموسيقى',
                              description: 'تشغيل الموسيقى الخلفية',
                              value: _settingsService.musicEnabled,
                              onChanged: (value) => _settingsService.setMusicEnabled(value),
                              color: Colors.purple,
                            ),
                            _buildSettingOption(
                              icon: Icons.vibration,
                              text: 'الاهتزاز',
                              description: 'تفعيل الاهتزاز عند التصادم',
                              value: _settingsService.vibrationEnabled,
                              onChanged: (value) => _settingsService.setVibrationEnabled(value),
                              color: Colors.orange,
                            ),
                            _buildSettingOption(
                              icon: Icons.notifications,
                              text: 'الإشعارات',
                              description: 'تلقي إشعارات اللعبة',
                              value: _settingsService.notificationsEnabled,
                              onChanged: (value) => _settingsService.setNotificationsEnabled(value),
                              color: Colors.red,
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Game Progress Section
                        _buildSection(
                          'إحصائيات اللعبة',
                          Icons.analytics,
                          Colors.amber,
                          [
                            _buildStatOption(
                              icon: Icons.star,
                              text: 'أعلى نقاط',
                              value: highScore.toString(),
                              color: Colors.yellow,
                            ),
                            _buildStatOption(
                              icon: Icons.monetization_on,
                              text: 'إجمالي العملات',
                              value: totalCoins.toString(),
                              color: Colors.amber,
                            ),
                            _buildStatOption(
                              icon: Icons.check_circle,
                              text: 'المراحل المكتملة',
                              value: '${unlockedLevelsCount - 1}/100',
                              color: Colors.green,
                            ),
                            _buildStatOption(
                              icon: Icons.play_circle,
                              text: 'المرحلة الحالية',
                              value: currentLevel.toString(),
                              color: Colors.blue,
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // App Actions Section
                        _buildSection(
                          'إجراءات التطبيق',
                          Icons.settings,
                          Colors.orange,
                          [
                            _buildActionOption(
                              icon: Icons.star_rate,
                              text: 'قيم اللعبة',
                              description: 'ساعدنا بتقييمك في المتجر',
                              onTap: _rateApp,
                              color: Colors.orange,
                            ),
                            _buildActionOption(
                              icon: Icons.share,
                              text: 'مشاركة اللعبة',
                              description: 'شارك اللعبة مع أصدقائك',
                              onTap: _shareApp,
                              color: Colors.blue,
                            ),
                            _buildActionOption(
                              icon: Icons.refresh,
                              text: 'إعادة تعيين البيانات',
                              description: 'حذف جميع البيانات والبدء من جديد',
                              onTap: _resetGameData,
                              color: Colors.red,
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // About Section
                        _buildSection(
                          'حول اللعبة',
                          Icons.info,
                          Colors.grey,
                          [
                            _buildInfoOption(
                              icon: Icons.info_outline,
                              text: 'الإصدار',
                              value: '1.0.0',
                            ),
                            _buildInfoOption(
                              icon: Icons.code,
                              text: 'المطور',
                              value: 'فريق عالماشي',
                            ),
                            _buildActionOption(
                              icon: Icons.privacy_tip,
                              text: 'سياسة الخصوصية',
                              description: 'اطلع على سياسة الخصوصية',
                              onTap: _openPrivacyPolicy,
                              color: Colors.grey,
                            ),
                            _buildActionOption(
                              icon: Icons.description,
                              text: 'شروط الاستخدام',
                              description: 'اطلع على شروط الاستخدام',
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

  Widget _buildHeader() {
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
            const Expanded(
              child: Text(
                'الإعدادات',
                textAlign: TextAlign.center,
                style: TextStyle(
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
            const SizedBox(width: 50),
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

  // دوال الإجراءات تبقى كما هي
  void _rateApp() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _buildStyledDialog(
          title: 'تقييم اللعبة',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, size: 60, color: Colors.amber),
              const SizedBox(height: 10),
              const Text('هل تستمتع بلعبة عالماشي؟'),
              const Text('ساعدنا بتقييمك في المتجر!'),
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
                _launchAppStore();
              },
              child: const Text('قيم الآن'),
            ),
          ],
        );
      },
    );
  }

  void _shareApp() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _buildStyledDialog(
          title: 'مشاركة اللعبة',
          content: const Text('جرب لعبة عالماشي الممتعة!\n\nحمل اللعبة من المتجر واستمتع بالتحدي.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إغلاق'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('مشاركة'),
            ),
          ],
        );
      },
    );
  }

  void _resetGameData() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _buildStyledDialog(
          title: 'إعادة تعيين البيانات',
          content: const Text('هل أنت متأكد من حذف جميع بيانات اللعبة؟\n\nسيتم فقدان جميع النقاط والعملات والمراحل المفتوحة.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                await GameDataService.resetGameData();
                Navigator.of(context).pop();
                setState(() {
                  _loadStats();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم إعادة تعيين البيانات بنجاح'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('حذف'),
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _buildStyledDialog(
          title: 'سياسة الخصوصية',
          content: const SingleChildScrollView(
            child: Text(
              'نحن في عالماشي نحترم خصوصيتك ونلتزم بحماية بياناتك الشخصية.\n\n'
                  '• لا نجمع أي بيانات شخصية حساسة\n'
                  '• نستخدم البيانات فقط لتحسين تجربة اللعبة\n'
                  '• لا نشارك بياناتك مع أطراف ثالثة\n'
                  '• يمكنك حذف بياناتك في أي وقت من الإعدادات\n\n'
                  'للمزيد من المعلومات، يرجى زيارة موقعنا: 3almaShe.com',
            ),
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

  void _openTermsOfService() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _buildStyledDialog(
          title: 'شروط الاستخدام',
          content: const SingleChildScrollView(
            child: Text(
              'شروط استخدام لعبة عالماشي:\n\n'
                  '• اللعبة مجانية للاستخدام الشخصي\n'
                  '• يُمنع استخدام اللعبة لأغراض تجارية دون إذن\n'
                  '• نحتفظ بالحق في تحديث اللعبة وشروط الاستخدام\n'
                  '• المستخدم مسؤول عن استخدام اللعبة بطريقة مناسبة\n'
                  '• في حالة انتهاك الشروط، قد نقوم بإيقاف الخدمة\n\n'
                  'للمزيد من المعلومات، يرجى زيارة موقعنا: 3almaShe.com',
            ),
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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            content,
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: actions,
            ),
          ],
        ),
      ),
    );
  }
}