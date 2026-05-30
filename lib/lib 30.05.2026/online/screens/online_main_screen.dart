import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Languages/LanguageProvider.dart';
import '../../Languages/localization.dart';
import '../../screens/main_menu_screen.dart';
import '../../screens/profile_screen.dart';
import '../services/auth_service.dart';
import '../services/screen_orientation_service.dart';
import 'online_characters_screen.dart';
import 'online_lobby_screen.dart';
import 'online_settings_screen.dart';
import 'online_store_screen.dart';
import 'p2p_lobby_screen.dart';
import 'online_login_screen.dart';

class OnlineMainScreen extends StatefulWidget {
  const OnlineMainScreen({super.key});

  @override
  State<OnlineMainScreen> createState() => _OnlineMainScreenState();
}

class _OnlineMainScreenState extends State<OnlineMainScreen> {
  final ScreenOrientationService _orientationService = ScreenOrientationService();
  final AuthService _authService = AuthService();
  bool _isLoggedIn = false;
  String _userName = '';
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _initializeScreen();
    _checkLoginStatus();
    _setupAuthListener();
  }

  void _initializeScreen() async {
    await _orientationService.lockToLandscape(); // ✅ قفل الشاشة في الوضع الأفقي
  }

  void _setupAuthListener() {
    // ✅ الاستماع لتغيرات حالة المصادقة
    _authService.userStream.listen((user) {
      _checkLoginStatus();
    });
  }

  void _checkLoginStatus() async {
    final user = _authService.currentUser;
    setState(() {
      _isLoggedIn = user != null && !user.isAnonymous;
      _userName = user?.displayName ?? '';
      _userEmail = user?.email ?? '';
    });
  }

  // ✅ زر تبديل اللغة بنفس الخصائص
  Widget _buildLanguageToggleButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
        languageProvider.toggleLanguage();
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
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

  // أيقونة اللغة الإنجليزية
  Widget _buildEnglishIcon() {
    return Image.asset(
      'assets/images/main_menu/english_icon.png',
      width: 30,
      height: 30,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF012169), Color(0xFFC8102E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
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

  // أيقونة اللغة العربية
  Widget _buildArabicIcon() {
    return Image.asset(
      'assets/images/main_menu/arabic_icon.png',
      width: 30,
      height: 30,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: const Color(0xFF006233),
            borderRadius: BorderRadius.circular(15),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0f3460),
              Color(0xFF16213e),
              Color(0xFF1a1a2e),
            ],
          ),
          image: DecorationImage(
            image: AssetImage('assets/online/backgrounds/main_bg.png'),
            fit: BoxFit.cover,
            opacity: 0.3,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // معلومات المستخدم - أعلى اليمين
              Positioned(
                top: 8,
                right: 8,
                child: _buildUserInfoSection(l10n),
              ),

              // القائمة الرئيسية - على اليسار
              Positioned(
                left: 20,
                top: size.height * 0.3,
                child: _buildMainMenu(l10n),
              ),

              // زر الإعدادات وزر اللغة - أسفل اليمين
              Positioned(
                right: 8,
                bottom: 8,
                child: _buildSettingsAndLanguageSection(l10n),
              ),

              // العنوان - أعلى المنتصف
              Positioned(
                top: size.height * 0.15,
                left: 0,
                right: 0,
                child: _buildTitleSection(l10n),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoSection(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(14),
      // decoration: BoxDecoration(
      //   color: Colors.black.withOpacity(0.5),
      //   borderRadius: BorderRadius.circular(10),
      //   border: Border.all(color: Colors.white.withOpacity(0.3)),
      // ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_isLoggedIn) ...[
            _buildAuthButton(l10n.signUp, Icons.person_add, Colors.blue, _showLoginScreen),
            SizedBox(width: 6),
            _buildAuthButton(l10n.signIn, Icons.login, Colors.green, _showLoginScreen),
          ] else ...[
            // ✅ قسم الحساب للمستخدم المسجل (مثل Lobby Screen)
            _buildAccountSection(l10n),
          ],
        ],
      ),
    );
  }

  // ✅ قسم الحساب للمستخدم المسجل
  Widget _buildAccountSection(AppLocalizations l10n) {
    return GestureDetector(
      onTap: _navigateToProfile,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.green,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ أيقونة الحساب
            Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                color: Colors.green,
                size: 16,
              ),
            ),
            SizedBox(width: 6),

            // ✅ معلومات الحساب
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.yourAccount,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _userName.isNotEmpty ? _userName : _userEmail.split('@').first,
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthButton(String text, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 12),
            SizedBox(width: 4),
            Text(
              text,
              style: TextStyle(color: Colors.white, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ زر العودة للشاشة الأوفلاين بنفس خصائص زر اللغة والإعدادات
  Widget _buildBackToOfflineButton() {
    return GestureDetector(
      onTap: _backToOfflineScreen,
      child: Container(
        width: 40, // ✅ نفس حجم زر اللغة والإعدادات
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent, // ✅ نفس الشفافية
        ),
        child: Center(
          child: Image.asset(
            'assets/images/main_menu/offline_icon.png', // ✅ استخدام أيقونة الأوفلاين
            width: 30, // ✅ نفس حجم الأيقونات
            height: 30,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Center(
                  child: Icon(
                    Icons.home, // ✅ أيقونة بديلة
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

// ✅ دالة العودة للشاشة الأوفلاين
  void _backToOfflineScreen() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => MainMenuScreen()),
          (route) => false,
    );
  }

  // ✅ زر الإعدادات بنفس خصائص زر اللغة
  Widget _buildSettingsButton() {
    return GestureDetector(
      onTap: _showSettings,
      child: Container(
        width: 40, // ✅ نفس حجم زر اللغة
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent, // ✅ نفس الشفافية
        ),
        child: Center(
          child: Image.asset(
            'assets/images/main_menu/settings_icon.png', // ✅ استخدام الأيقونة الجديدة
            width: 30, // ✅ نفس حجم أيقونة اللغة
            height: 30,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              // ✅ نفس نظام الخطأ مثل أيقونة اللغة
              return Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Center(
                  child: Icon(
                    Icons.settings, // ✅ أيقونة الإعدادات البديلة
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

// ✅ قسم الإعدادات واللغة والعودة للأوفلاين
  Widget _buildSettingsAndLanguageSection(AppLocalizations l10n) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ✅ زر الإعدادات
        _buildSettingsButton(),
        SizedBox(width: 8),

        // ✅ زر اللغة
        _buildLanguageToggleButton(context),
        SizedBox(width: 8),

        // ✅ زر العودة للشاشة الأوفلاين
        _buildBackToOfflineButton(),
      ],
    );
  }

  Widget _buildMainMenu(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8),
        _buildMenuButton(
          l10n: l10n,
          icon: Icons.search,
          title: l10n.findPlayers,
          subtitle: l10n.oneVsOneOrTwoVsTwo,
          onTap: _findPlayers,
        ),
        SizedBox(height: 8),
        _buildMenuButton(
          l10n: l10n,
          icon: Icons.people,
          title: l10n.characters,
          subtitle: l10n.sixFreeCharacters,
          onTap: _showCharacters,
        ),
        SizedBox(height: 8),
        _buildMenuButton(
          l10n: l10n,
          icon: Icons.store,
          title: l10n.store,
          subtitle: l10n.freeAndPaidCharacters,
          onTap: _showStore,
        ),
      ],
    );
  }

  Widget _buildMenuButton({
    required AppLocalizations l10n,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 200,
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.withOpacity(0.3),
                Colors.purple.withOpacity(0.1),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleSection(AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.almasheBattle,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(blurRadius: 6, color: Colors.blue),
            ],
          ),
        ),
        SizedBox(height: 4),
        Text(
          l10n.onlineBattle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  void _findPlayers() {
    // ✅ إذا كان مسجل دخول يدخل مباشرة، إذا لم يكن مسجل تظهر النافذة
    if (!_isLoggedIn) {
      _showGuestDialog();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => OnlineLobbyScreen()),
      );
    }
  }

  void _showCharacters() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => OnlineCharactersScreen()),
    );
  }

  void _showStore() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => OnlineStoreScreen()),
    );
  }

  void _showSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => OnlineSettingsScreen()),
    );
  }

  void _showLoginScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => OnlineLoginScreen()),
    );
  }

  void _navigateToProfile() {
    final user = _authService.currentUser;
    if (user != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProfileScreen(user: user)),
      );
    }
  }

  void _logout() async {
    await _authService.signOut();
    setState(() {
      _isLoggedIn = false;
      _userName = '';
      _userEmail = '';
    });
  }

  void _showGuestDialog() {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1a1a2e),
        title: Text(
          l10n.signIn,
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: Text(
          l10n.loginToFindPlayers,
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel, style: TextStyle(color: Colors.red, fontSize: 12)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showLoginScreen();
            },
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: Text(l10n.signIn, style: TextStyle(fontSize: 12)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => OnlineLobbyScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: Text(l10n.playAsGuest, style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _orientationService.unlockToPortrait(); // ✅ إعادة الشاشة للوضع العمودي عند الخروج
    super.dispose();
  }
}