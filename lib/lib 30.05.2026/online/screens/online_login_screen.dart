import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:country_picker/country_picker.dart';
import '../services/auth_service.dart';
import '../services/user_data_service.dart';
import 'online_lobby_screen.dart';
import '../../screens/main_menu_screen.dart';
import '../../Languages/LanguageProvider.dart';
import '../../Languages/localization.dart';

class OnlineLoginScreen extends StatefulWidget {
  const OnlineLoginScreen({super.key});

  @override
  State<OnlineLoginScreen> createState() => _OnlineLoginScreenState();
}

class _OnlineLoginScreenState extends State<OnlineLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  // ✅ إضافة حقلي الاسم الأول والاسم الثاني
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  // تم إخفاء متغيرات الهاتف ولكن لم نحذفها
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _phoneVerificationController = TextEditingController();

  // متغيرات اسم المستخدم
  final TextEditingController _usernameController = TextEditingController();
  final FocusNode _usernameFocusNode = FocusNode();

  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLogin = true;
  bool _isLoading = false;
  bool _showPhoneVerification = false;
  String? _verificationId;
  Country? _selectedCountry;

  // Focus nodes
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();
  // ✅ إضافة focus nodes للأسماء
  final FocusNode _firstNameFocusNode = FocusNode();
  final FocusNode _lastNameFocusNode = FocusNode();

  // تم إخفاء focus node الهاتف ولكن لم نحذفه
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _verificationFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(() {
      if (_emailFocusNode.hasFocus) _showEmailKeyboard();
    });
  }

  // ✅ دالة مبسطة للحصول على الاسم المترجم للدولة (محفوظة للاستخدام المستقبلي)
  String _getTranslatedCountryName(Country country) {
    final appLocalizations = AppLocalizations.of(context);
    return appLocalizations.getCountryNameByCode(country.countryCode);
  }

  // ✅ تم إخفاء دالة اختيار الدولة ولكن لم نحذفها
  void _showCountryPicker() {
    final l10n = AppLocalizations.of(context);

    showCountryPicker(
      context: context,
      showPhoneCode: true,
      countryListTheme: CountryListThemeData(
        flagSize: 25,
        backgroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 16, color: Colors.blueGrey),
        borderRadius: BorderRadius.circular(20),
        inputDecoration: InputDecoration(
          labelText: l10n.search,
          hintText: l10n.typeToSearch,
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      onSelect: (Country country) {
        setState(() {
          _selectedCountry = country;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
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
          ),
          child: Column(
            children: [
              // ✅ الهيدر المحسّن مع العنوان وزر الرجوع وزر اللغة
              _buildHeader(context),

              Expanded(
                child: _buildResponsiveLayout(l10n), // ✅ استدعاء التخطيط المتجاوب
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ تخطيط متجاوب يجعل المربعين متوازيين
  Widget _buildResponsiveLayout(AppLocalizations l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          // ✅ للشاشات الصغيرة - عمودي
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildLoginForm(l10n),
                  SizedBox(height: 20),
                  _buildSocialLogin(l10n),
                ],
              ),
            ),
          );
        } else {
          // ✅ للشاشات الكبيرة - أفقي ومتوازي
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: IntrinsicHeight( // ✅ يجعل الارتفاع متساوي
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start, // ✅ محاذاة من الأعلى
                  children: [
                    // ✅ قسم نموذج التسجيل
                    Expanded(
                      flex: 3,
                      child: _buildLoginForm(l10n),
                    ),

                    SizedBox(width: 20), // ✅ مسافة بين المربعين

                    // ✅ قسم التسجيل الاجتماعي
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: _buildSocialLogin(l10n),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }

  // ✅ بناء الهيدر مع زر اللغة على الجانب الآخر
  Widget _buildHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // ✅ زر الرجوع على اليسار
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white, size: 24),
            onPressed: () => Navigator.pop(context),
          ),
          SizedBox(width: 16),

          // ✅ العنوان في المنتصف
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  _isLogin ? l10n.signIn : l10n.signUp,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  _isLogin ? l10n.loginDescription : l10n.joinTheBattle,
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),

          // ✅ زر اللغة على اليمين
          _buildLanguageToggleButton(context),
        ],
      ),
    );
  }

  // ✅ زر تبديل اللغة
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

  // ✅ أيقونة اللغة الإنجليزية
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

  // ✅ أيقونة اللغة العربية
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

  Widget _buildLoginForm(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ✅ زر التبديل بين تسجيل الدخول وإنشاء حساب
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() {
                      _isLogin = true;
                      _clearForm();
                    }),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isLogin ? Colors.blue : Colors.transparent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      l10n.signIn,
                      style: TextStyle(
                        fontSize: 12,
                        color: _isLogin ? Colors.white : Colors.white70,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() {
                      _isLogin = false;
                      _clearForm();
                    }),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !_isLogin ? Colors.blue : Colors.transparent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      l10n.signUp,
                      style: TextStyle(
                        fontSize: 12,
                        color: !_isLogin ? Colors.white : Colors.white70,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),

          // ✅ حقول الاسم الأول والاسم الثاني (تظهر فقط عند إنشاء حساب)
          if (!_isLogin) ...[
            // ✅ حقل الاسم الأول
            TextField(
              controller: _firstNameController,
              focusNode: _firstNameFocusNode,
              decoration: InputDecoration(
                labelText: l10n.firstName,
                labelStyle: TextStyle(color: Colors.white70, fontSize: 12),
                prefixIcon: Icon(Icons.person_outline, color: Colors.white70, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white30),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              style: TextStyle(color: Colors.white, fontSize: 14),
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.next,
            ),
            SizedBox(height: 15),

            // ✅ حقل الاسم الثاني
            TextField(
              controller: _lastNameController,
              focusNode: _lastNameFocusNode,
              decoration: InputDecoration(
                labelText: l10n.lastName,
                labelStyle: TextStyle(color: Colors.white70, fontSize: 12),
                prefixIcon: Icon(Icons.person_outline, color: Colors.white70, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white30),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              style: TextStyle(color: Colors.white, fontSize: 14),
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.next,
            ),
            SizedBox(height: 15),

            // ✅ حقل Username الجديد
            TextField(
              controller: _usernameController,
              focusNode: _usernameFocusNode,
              decoration: InputDecoration(
                labelText: 'اسم المستخدم',
                labelStyle: TextStyle(color: Colors.white70, fontSize: 12),
                prefixIcon: Icon(Icons.alternate_email, color: Colors.white70, size: 20),
                hintText: 'مثال: player_ahmed',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white30),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              style: TextStyle(color: Colors.white, fontSize: 14),
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
            ),
            SizedBox(height: 15),
          ],

          // ✅ حقل البريد الإلكتروني
          TextField(
            controller: _emailController,
            focusNode: _emailFocusNode,
            decoration: InputDecoration(
              labelText: l10n.email,
              labelStyle: TextStyle(color: Colors.white70, fontSize: 12),
              prefixIcon: Icon(Icons.email, color: Colors.white70, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white30),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            style: TextStyle(color: Colors.white, fontSize: 14),
            keyboardType: TextInputType.emailAddress,
            textInputAction: _isLogin ? TextInputAction.next : TextInputAction.next,
          ),
          SizedBox(height: 15),

          // ✅ حقل كلمة المرور
          TextField(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            obscureText: true,
            decoration: InputDecoration(
              labelText: l10n.password,
              labelStyle: TextStyle(color: Colors.white70, fontSize: 12),
              prefixIcon: Icon(Icons.lock, color: Colors.white70, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white30),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            style: TextStyle(color: Colors.white, fontSize: 14),
            textInputAction: _isLogin ? TextInputAction.done : TextInputAction.next,
          ),
          SizedBox(height: 15),

          // ✅ حقل تأكيد كلمة المرور (يظهر فقط عند إنشاء حساب)
          if (!_isLogin) ...[
            TextField(
              controller: _confirmPasswordController,
              focusNode: _confirmPasswordFocusNode,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.confirmPassword,
                labelStyle: TextStyle(color: Colors.white70, fontSize: 12),
                prefixIcon: Icon(Icons.lock_outline, color: Colors.white70, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white30),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              style: TextStyle(color: Colors.white, fontSize: 14),
              textInputAction: TextInputAction.done,
            ),
            SizedBox(height: 15),
          ],

          // ✅ زر استعادة كلمة المرور (يظهر فقط في تسجيل الدخول)
          if (_isLogin) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _showResetPasswordDialog,
                child: Text(
                  l10n.forgotPassword,
                  style: TextStyle(color: Colors.blue, fontSize: 12),
                ),
              ),
            ),
            SizedBox(height: 10),
          ],

          // ✅ زر الإجراء الرئيسي
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleAuth,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : Text(
                _isLogin ? l10n.signIn : l10n.signUp,
                style: TextStyle(fontSize: 14),
              ),
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildSocialLogin(AppLocalizations l10n) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.loginWith,
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),

        SizedBox(height: 20),

        _buildSocialButton(
          'Facebook',
          Icons.facebook,
          Colors.blue[800]!,
          _loginWithFacebook,
        ),

        SizedBox(height: 12),
        _buildSocialButton(
          'Google',
          Icons.g_mobiledata,
          Colors.red,
          _loginWithGoogle,
        ),
      ],
    );
  }

  Widget _buildSocialButton(String text, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : onTap,
        icon: Icon(icon, color: Colors.white, size: 18),
        label: Text(
          text,
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  // ✅ دالة لمسح الحقول
  void _clearForm() {
    _passwordController.clear();
    _confirmPasswordController.clear();
    _firstNameController.clear();
    _lastNameController.clear();
  }

  void _showEmailKeyboard() => FocusScope.of(context).requestFocus(_emailFocusNode);

  // ✅ دالة استعادة كلمة المرور مع نافذة منبثقة
  void _showResetPasswordDialog() {
    final l10n = AppLocalizations.of(context);
    final TextEditingController resetEmailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.resetPassword),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.resetPasswordDescription),
            SizedBox(height: 16),
            TextField(
              controller: resetEmailController,
              decoration: InputDecoration(
                labelText: l10n.enterEmailForReset,
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (resetEmailController.text.isEmpty) {
                _showError(l10n.enterEmailForReset);
                return;
              }

              Navigator.pop(context);
              await _resetPassword(resetEmailController.text.trim());
            },
            child: Text(l10n.sendResetLink),
          ),
        ],
      ),
    );
  }

  // ✅ دالة استعادة كلمة المرور
  Future<void> _resetPassword(String email) async {
    final l10n = AppLocalizations.of(context);

    setState(() => _isLoading = true);
    try {
      await _auth.sendPasswordResetEmail(email: email);
      _showSuccess(l10n.resetLinkSent);
    } catch (e) {
      _showError('${l10n.resetFailed}: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleAuth() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isLoading = true);

    try {
      // ✅ التحقق من صحة البيانات
      if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
        _showError(l10n.emailPasswordRequired);
        setState(() => _isLoading = false);
        return;
      }

      // ✅ التحقق من Username عند إنشاء حساب
      if (!_isLogin) {
        if (_usernameController.text.isEmpty) {
          _showError('يرجى إدخال اسم المستخدم');
          setState(() => _isLoading = false);
          return;
        }

        if (_usernameController.text.length < 3) {
          _showError('اسم المستخدم يجب أن يكون 3 أحرف على الأقل');
          setState(() => _isLoading = false);
          return;
        }

        // ✅ التحقق من عدم تكرار Username
        final isUsernameAvailable = await _checkUsernameAvailability(_usernameController.text);
        if (!isUsernameAvailable) {
          _showError('اسم المستخدم مستخدم بالفعل، اختر اسم آخر');
          setState(() => _isLoading = false);
          return;
        }
      }

      User? user;

      if (_isLogin) {
        // ✅ تسجيل الدخول
        user = await _authService.signInWithEmail(_emailController.text, _passwordController.text);
        if (user != null) {
          await UserDataService.initializeUserData(user);
          _showSuccess(l10n.welcomeBack);
        }
      } else {
        // ✅ إنشاء حساب جديد مع Username
        user = await _authService.signUpWithEmail(_emailController.text, _passwordController.text, null);
        if (user != null) {
          // ✅ تحديث الاسم الكامل
          await user.updateDisplayName('${_firstNameController.text} ${_lastNameController.text}');
          await user.reload();

          // ✅ ربط البيانات مع إضافة Username
          await UserDataService.initializeUserDataWithUsername(
              user,
              _usernameController.text
          );
          _showSuccess(l10n.accountCreated);
        }
      }

      if (user != null) {
        print('✅ تم إنشاء الحساب: ${user.email} - Username: ${_usernameController.text}');
        _navigateToHome();
      } else {
        _showError(l10n.loginFailed);
        setState(() => _isLoading = false);
      }

    } catch (e) {
      _showError('${l10n.errorOccurred}: ${e.toString()}');
      setState(() => _isLoading = false);
    }
  }

  // ✅ دالة التحقق من توفر Username
  Future<bool> _checkUsernameAvailability(String username) async {
    try {
      // ✅ تحقق أولي من صحة Username
      if (username.length < 3) {
        _showError('اسم المستخدم يجب أن يكون 3 أحرف على الأقل');
        return false;
      }

      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
        _showError('اسم المستخدم يمكن أن يحتوي على أحرف إنجليزية وأرقام و _ فقط');
        return false;
      }

      // ✅ التحقق من الخوادم
      final isAvailable = await UserDataService.checkUsernameAvailability(username);

      if (!isAvailable) {
        _showError('اسم المستخدم "$username" مستخدم بالفعل، اختر اسم آخر');
      }

      return isAvailable;

    } catch (e) {
      print('❌ خطأ في التحقق من Username: $e');

      // ✅ عرض رسالة مناسبة حسب نوع الخطأ
      if (e.toString().contains('PERMISSION_DENIED')) {
        _showError('خطأ في الصلاحيات - يرجى المحاولة لاحقاً');
      } else {
        _showError('خطأ في التحقق من اسم المستخدم - تحقق من الاتصال بالإنترنت');
      }

      return false;
    }
  }

  void _loginWithFacebook() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isLoading = true);
    try {
      // ✅ تسجيل دخول فيسبوك + ربط يدوي
      User? user = await _authService.signInWithFacebook();
      if (user != null) {
        // ✅ الربط اليدوي مع Firestore
        await UserDataService.initializeUserData(user);
        _showSuccess(l10n.facebookLoginSuccess);
        _navigateToHome();
      } else {
        _showError(l10n.facebookLoginFailed);
      }
    } catch (e) {
      _showError('${l10n.facebookLoginFailed}: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _loginWithGoogle() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isLoading = true);
    try {
      // ✅ تسجيل دخول جوجل + ربط يدوي
      User? user = await _authService.signInWithGoogle();
      if (user != null) {
        await UserDataService.initializeUserData(user); // ✅ الربط اليدوي
        _showSuccess(l10n.googleLoginSuccess);
        _navigateToHome();
      } else {
        _showError(l10n.googleLoginFailed);
      }
    } catch (e) {
      _showError('${l10n.googleLoginFailed}: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ✅ التوجيه إلى OnlineLobbyScreen
  void _navigateToOnlineLobby() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => OnlineLobbyScreen()),
    );
  }

  // ✅ التوجيه إلى MainMenuScreen (محفوظ للاستخدام المستقبلي)
  void _navigateToMainMenu() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MainMenuScreen()),
    );
  }

  // ✅ التوجيه إلى Home (محفوظ للاستخدام المستقبلي)
  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => OnlineLobbyScreen()),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _phoneVerificationController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _firstNameFocusNode.dispose();
    _lastNameFocusNode.dispose();
    _phoneFocusNode.dispose();
    _verificationFocusNode.dispose();
    super.dispose();
  }
}