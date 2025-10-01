import 'package:flutter/material.dart';
import '../services/game_data_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool soundEnabled = true;
  bool musicEnabled = true;
  bool vibrationEnabled = true;
  bool notificationsEnabled = true;

  // ✅ أضف متغيرات للإحصائيات
  int highScore = 0;
  int totalCoins = 0;
  int unlockedLevelsCount = 0;
  int currentLevel = 1;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  // ✅ دالة لتحميل الإحصائيات
  void _loadStats() async {
    try {
      // تحميل كل بيانات على حدة
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
      // استخدام قيم افتراضية
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

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2E4057), // Dark blue-grey
              Color(0xFF048A81), // Teal
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
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
                        ),
                      ),
                    ),
                    const SizedBox(width: 50), // Balance the back button
                  ],
                ),
              ),

              // Settings content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Game Settings Section
                      _buildSectionCard(
                        'إعدادات اللعبة',
                        Icons.gamepad,
                        [
                          _buildSwitchTile(
                            'الأصوات',
                            'تشغيل أصوات اللعبة',
                            Icons.volume_up,
                            soundEnabled,
                                (value) => setState(() => soundEnabled = value),
                          ),
                          _buildSwitchTile(
                            'الموسيقى',
                            'تشغيل الموسيقى الخلفية',
                            Icons.music_note,
                            musicEnabled,
                                (value) => setState(() => musicEnabled = value),
                          ),
                          _buildSwitchTile(
                            'الاهتزاز',
                            'تفعيل الاهتزاز عند التصادم',
                            Icons.vibration,
                            vibrationEnabled,
                                (value) => setState(() => vibrationEnabled = value),
                          ),
                          _buildSwitchTile(
                            'الإشعارات',
                            'تلقي إشعارات اللعبة',
                            Icons.notifications,
                            notificationsEnabled,
                                (value) => setState(() => notificationsEnabled = value),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Game Progress Section
                      _buildSectionCard(
                        'إحصائيات اللعبة',
                        Icons.analytics,
                        [
                          _buildStatTile(
                            'أعلى نقاط',
                            highScore.toString(), // ✅ استخدام المتغير
                            Icons.star,
                            Colors.yellow,
                          ),
                          _buildStatTile(
                            'إجمالي العملات',
                            totalCoins.toString(), // ✅ استخدام المتغير
                            Icons.monetization_on,
                            Colors.amber,
                          ),
                          _buildStatTile(
                            'المراحل المكتملة',
                            '${unlockedLevelsCount - 1}/100', // ✅ استخدام المتغير
                            Icons.check_circle,
                            Colors.green,
                          ),
                          _buildStatTile(
                            'المرحلة الحالية',
                            currentLevel.toString(), // ✅ استخدام المتغير
                            Icons.play_circle,
                            Colors.blue,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // App Actions Section
                      _buildSectionCard(
                        'إجراءات التطبيق',
                        Icons.settings,
                        [
                          _buildActionTile(
                            'قيم اللعبة',
                            'ساعدنا بتقييمك في المتجر',
                            Icons.star_rate,
                            Colors.orange,
                                () => _rateApp(),
                          ),
                          _buildActionTile(
                            'مشاركة اللعبة',
                            'شارك اللعبة مع أصدقائك',
                            Icons.share,
                            Colors.blue,
                                () => _shareApp(),
                          ),
                          _buildActionTile(
                            'إعادة تعيين البيانات',
                            'حذف جميع البيانات والبدء من جديد',
                            Icons.refresh,
                            Colors.red,
                                () => _resetGameData(),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // About Section
                      _buildSectionCard(
                        'حول اللعبة',
                        Icons.info,
                        [
                          _buildInfoTile(
                            'الإصدار',
                            '1.0.0',
                            Icons.info_outline,
                          ),
                          _buildInfoTile(
                            'المطور',
                            'فريق عالماشي',
                            Icons.code,
                          ),
                          _buildActionTile(
                            'سياسة الخصوصية',
                            'اطلع على سياسة الخصوصية',
                            Icons.privacy_tip,
                            Colors.grey,
                                () => _openPrivacyPolicy(),
                          ),
                          _buildActionTile(
                            'شروط الاستخدام',
                            'اطلع على شروط الاستخدام',
                            Icons.description,
                            Colors.grey,
                                () => _openTermsOfService(),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),
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

  // ... باقي الدوال (_buildSectionCard, _buildSwitchTile, etc.) تبقى كما هي ...
  // تأكد من وجود جميع الدوال المساعدة الأخرى

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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

  Widget _buildSwitchTile(
      String title,
      String subtitle,
      IconData icon,
      bool value,
      Function(bool) onChanged,
      ) {
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
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.green,
            inactiveThumbColor: Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(String title, String value, IconData icon, Color color) {
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
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
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

  Widget _buildActionTile(
      String title,
      String subtitle,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
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
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white60,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon) {
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
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
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

  // ... دوال الإجراءات (_rateApp, _shareApp, etc.) تبقى كما هي ...

  void _rateApp() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تقييم اللعبة'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, size: 60, color: Colors.amber),
              SizedBox(height: 10),
              Text('هل تستمتع بلعبة عالماشي؟'),
              Text('ساعدنا بتقييمك في المتجر!'),
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
    // In a real app, you would use the share package
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('مشاركة اللعبة'),
          content: const Text('جرب لعبة عالماشي الممتعة!\n\nحمل اللعبة من المتجر واستمتع بالتحدي.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إغلاق'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Here you would implement actual sharing
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
        return AlertDialog(
          title: const Text('إعادة تعيين البيانات'),
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
                  _loadStats(); // إعادة تحميل الإحصائيات
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
        return AlertDialog(
          title: const Text('تقييم اللعبة'),
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
        return AlertDialog(
          title: const Text('سياسة الخصوصية'),
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
        return AlertDialog(
          title: const Text('شروط الاستخدام'),
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
}