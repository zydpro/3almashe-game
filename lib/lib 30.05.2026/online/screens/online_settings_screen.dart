import 'package:flutter/material.dart';
import '../../../Languages/localization.dart';

class OnlineSettingsScreen extends StatefulWidget {
  const OnlineSettingsScreen({super.key});

  @override
  State<OnlineSettingsScreen> createState() => _OnlineSettingsScreenState();
}

class _OnlineSettingsScreenState extends State<OnlineSettingsScreen> {
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _vibrationEnabled = true;
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'ar';
  double _soundVolume = 0.8;
  double _musicVolume = 0.6;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '⚙️ ${l10n.settings}',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f3460),
            ],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // إعدادات الصوت
            _buildSectionHeader('🔊 إعدادات الصوت'),
            _buildSoundSettingCard(),

            // إعدادات اللعبة
            _buildSectionHeader('🎮 إعدادات اللعبة'),
            _buildGameSettingCard(),

            // إعدادات اللغة
            _buildSectionHeader('🌐 إعدادات اللغة'),
            _buildLanguageSettingCard(),

            // معلومات التطبيق
            _buildSectionHeader('ℹ️ معلومات التطبيق'),
            _buildAppInfoCard(),

            // أزرار إضافية
            SizedBox(height: 20),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSoundSettingCard() {
    return Card(
      color: Colors.white.withOpacity(0.05),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSettingSwitch(
              title: 'تشغيل الصوت',
              value: _soundEnabled,
              onChanged: (value) {
                setState(() {
                  _soundEnabled = value;
                });
              },
            ),
            if (_soundEnabled) ...[
              SizedBox(height: 12),
              _buildVolumeSlider(
                title: 'مستوى الصوت',
                value: _soundVolume,
                onChanged: (value) {
                  setState(() {
                    _soundVolume = value;
                  });
                },
              ),
            ],
            SizedBox(height: 12),
            _buildSettingSwitch(
              title: 'تشغيل الموسيقى',
              value: _musicEnabled,
              onChanged: (value) {
                setState(() {
                  _musicEnabled = value;
                });
              },
            ),
            if (_musicEnabled) ...[
              SizedBox(height: 12),
              _buildVolumeSlider(
                title: 'مستوى الموسيقى',
                value: _musicVolume,
                onChanged: (value) {
                  setState(() {
                    _musicVolume = value;
                  });
                },
              ),
            ],
            SizedBox(height: 12),
            _buildSettingSwitch(
              title: 'الاهتزاز',
              value: _vibrationEnabled,
              onChanged: (value) {
                setState(() {
                  _vibrationEnabled = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameSettingCard() {
    return Card(
      color: Colors.white.withOpacity(0.05),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSettingSwitch(
              title: 'الإشعارات',
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
            ),
            SizedBox(height: 12),
            _buildSettingItem(
              title: 'جودة الرسومات',
              subtitle: 'عالية',
              onTap: () {
                _showGraphicsDialog();
              },
            ),
            SizedBox(height: 12),
            _buildSettingItem(
              title: 'عناصر التحكم',
              subtitle: 'لمس',
              onTap: () {
                _showControlsDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSettingCard() {
    return Card(
      color: Colors.white.withOpacity(0.05),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSettingItem(
              title: 'اللغة',
              subtitle: _selectedLanguage == 'ar' ? 'العربية' : 'English',
              onTap: () {
                _showLanguageDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfoCard() {
    return Card(
      color: Colors.white.withOpacity(0.05),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoItem('الإصدار', '1.0.0'),
            SizedBox(height: 8),
            _buildInfoItem('تاريخ البناء', '2024'),
            SizedBox(height: 8),
            _buildInfoItem('المطور', 'فريق عالماشي'),
            SizedBox(height: 8),
            _buildInfoItem('الدعم', 'support@almashe.com'),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'حفظ الإعدادات',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _resetSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.3),
              padding: EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'إعادة التعيين',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingSwitch({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.blue,
        ),
      ],
    );
  }

  Widget _buildVolumeSlider({
    required String title,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 8),
        Slider(
          value: value,
          onChanged: onChanged,
          min: 0.0,
          max: 1.0,
          divisions: 10,
          activeColor: Colors.blue,
          inactiveColor: Colors.white.withOpacity(0.3),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '0%',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              '${(value * 100).toInt()}%',
              style: TextStyle(color: Colors.blue, fontSize: 12),
            ),
            Text(
              '100%',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingItem({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      title: Text(
        title,
        style: TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.white70),
      ),
      trailing: Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
    );
  }

  Widget _buildInfoItem(String title, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  void _showGraphicsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1a1a2e),
        title: Text('جودة الرسومات', style: TextStyle(color: Colors.white)),
        content: Text('اختر جودة الرسومات المناسبة لجهازك', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('تطبيق'),
          ),
        ],
      ),
    );
  }

  void _showControlsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1a1a2e),
        title: Text('عناصر التحكم', style: TextStyle(color: Colors.white)),
        content: Text('اختر نمط عناصر التحكم المناسب لك', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('تطبيق'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1a1a2e),
        title: Text('اختر اللغة', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('العربية', style: TextStyle(color: Colors.white)),
              trailing: _selectedLanguage == 'ar' ? Icon(Icons.check, color: Colors.green) : null,
              onTap: () {
                setState(() {
                  _selectedLanguage = 'ar';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('English', style: TextStyle(color: Colors.white)),
              trailing: _selectedLanguage == 'en' ? Icon(Icons.check, color: Colors.green) : null,
              onTap: () {
                setState(() {
                  _selectedLanguage = 'en';
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _saveSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم حفظ الإعدادات بنجاح'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _resetSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1a1a2e),
        title: Text('إعادة التعيين', style: TextStyle(color: Colors.white)),
        content: Text('هل أنت متأكد من إعادة تعيين جميع الإعدادات؟', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _soundEnabled = true;
                _musicEnabled = true;
                _vibrationEnabled = true;
                _notificationsEnabled = true;
                _soundVolume = 0.8;
                _musicVolume = 0.6;
                _selectedLanguage = 'ar';
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تم إعادة التعيين بنجاح'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text('تأكيد'),
          ),
        ],
      ),
    );
  }
}