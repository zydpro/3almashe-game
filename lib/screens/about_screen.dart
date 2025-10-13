// about_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Languages/localization.dart';
import '../Languages/LanguageProvider.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  // ✅ نفس إعدادات الحجم والظل من MainMenuScreen
  double cornerShadowBlur = 10.0;
  double cornerShadowSpread = 2.0;
  Color cornerShadowColor = Colors.black.withOpacity(0.5);
  Offset cornerShadowOffset = const Offset(2, 2);
  double cornerIconSize = 50.0;
  double cornerButtonSize = 60.0;

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final Languages = AppLocalizations.of(context);

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

                        // About Game Section
                        _buildSection(
                          Languages.aboutGame,
                          Icons.info,
                          Colors.blue,
                          [
                            _buildAboutItem(
                              icon: Icons.business_center,
                              text: 'عالماشي .كوم',
                              value: '3almaShe.com',
                              color: Colors.amber,
                            ),
                            _buildAboutItem(
                              icon: Icons.star,
                              text: Languages.version,
                              value: '1.0.0',
                              color: Colors.green,
                            ),
                            _buildAboutItem(
                              icon: Icons.code,
                              text: Languages.developer,
                              value: languageProvider.isArabic ? 'فريق عالماشي' : '3almaShe Team',
                              color: Colors.purple,
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Game Description Section
                        _buildSection(
                          Languages.aboutDesecration,
                          Icons.games,
                          Colors.orange,
                          [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    Languages.aboutGameSubject1,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      height: 1.5,
                                    ),
                                    textAlign: TextAlign.start,
                                  ),
                                  const SizedBox(height: 15),
                                  Text(
                                    Languages.aboutGameSubject2,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      height: 1.5,
                                    ),
                                    textAlign: TextAlign.start,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Website Section
                        _buildSection(
                          Languages.aboutTheWebsite,
                          Icons.language,
                          Colors.green,
                          [
                            _buildWebsiteItem(
                              icon: Icons.public,
                              text: Languages.VisitWebsite,
                              value: 'www.3almaShe.com',
                              onTap: _visitWebsite,
                              color: Colors.blue,
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Language Section
                        _buildSection(
                          Languages.aboutLanguage,
                          Icons.language,
                          Colors.purple,
                          [
                            _buildLanguageOption(),
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
    final languageProvider = Provider.of<LanguageProvider>(context);
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
                l10n.aboutGame,
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
            // زر اللغة في الهيدر - بنفس تصميم MainMenuScreen
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: _buildLanguageToggleButton(languageProvider),
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
  Widget _buildLanguageToggleButton(LanguageProvider languageProvider) {
    return GestureDetector(
      onTap: () {
        languageProvider.toggleLanguage();
        setState(() {});
      },
      child: Container(
        width: cornerButtonSize, // ✅ نفس حجم الأزرار الجانبية
        height: cornerButtonSize, // ✅ نفس حجم الأزرار الجانبية
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.01),
          border: Border.all(
            color: Colors.white.withOpacity(0.01),
            width: 0.1,
          ),
          boxShadow: [
            BoxShadow(
              color: cornerShadowColor, // ✅ نفس لون ظل الأزرار الجانبية
              blurRadius: cornerShadowBlur, // ✅ نفس وضوح ظل الأزرار الجانبية
              spreadRadius: cornerShadowSpread, // ✅ نفس انتشار ظل الأزرار الجانبية
              offset: cornerShadowOffset, // ✅ نفس إزاحة ظل الأزرار الجانبية
            ),
          ],
        ),
        child: Center(
          child: languageProvider.isArabic
              ? _buildEnglishIcon()  // إذا العربية ظاهرة، اعرض الإنجليزية
              : _buildArabicIcon(),   // إذا الإنجليزية ظاهرة، اعرض العربية
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

  Widget _buildAboutItem({
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

  Widget _buildWebsiteItem({
    required IconData icon,
    required String text,
    required String value,
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
                      value,
                      style: TextStyle(
                        fontSize: 14,
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.open_in_new,
                color: color,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ خيار اللغة
  Widget _buildLanguageOption() {
    final languageProvider = Provider.of<LanguageProvider>(context);

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
          const Icon(Icons.language, color: Colors.purple, size: 24),
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
  }

  void _visitWebsite() {
    final Languages = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _buildStyledDialog(
          title: Languages.VisitWebsite,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.public, size: 60, color: Colors.blue),
              const SizedBox(height: 10),
              Text(
                Languages.aboutOpenWebsite,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                'www.3almaShe.com',
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(Languages.aboutCancel),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: إضافة كود فتح الموقع هنا
              },
              child: Text(Languages.aboutOpenLink),
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