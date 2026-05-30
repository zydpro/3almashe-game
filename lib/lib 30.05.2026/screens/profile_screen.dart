// online/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../Languages/localization.dart';
import '../../../Languages/LanguageProvider.dart';
import '../online/screens/online_login_screen.dart';
import '../online/screens/online_main_screen.dart';
import '../online/services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  final User user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    // يمكنك تحميل اسم المستخدم من GameDataService أو Firebase
    final displayName = widget.user.displayName ?? '';
    if (displayName.isNotEmpty) {
      final names = displayName.split(' ');
      _firstNameController.text = names.isNotEmpty ? names[0] : '';
      _lastNameController.text = names.length > 1 ? names[1] : '';
    }
  }

  void _updateProfile() async {
    final l10n = AppLocalizations.of(context);

    if (_firstNameController.text.isEmpty) {
      _showError(l10n.firstNameRequired);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final fullName = '${_firstNameController.text} ${_lastNameController.text}'.trim();

      // تحديث الاسم في Firebase Auth
      await widget.user.updateDisplayName(fullName);

      // يمكنك هنا تحديث الاسم في GameDataService أيضاً

      _showSuccess(l10n.profileUpdatedSuccess);
    } catch (e) {
      _showError('${l10n.profileUpdateFailed}: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _changePassword() async {
    final l10n = AppLocalizations.of(context);

    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showError(l10n.allFieldsRequired);
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showError(l10n.passwordsDoNotMatch);
      return;
    }

    if (_newPasswordController.text.length < 6) {
      _showError(l10n.passwordMinLength);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // إعادة المصادقة أولاً
      final credential = EmailAuthProvider.credential(
        email: widget.user.email!,
        password: _currentPasswordController.text,
      );

      await widget.user.reauthenticateWithCredential(credential);

      // ثم تغيير كلمة المرور
      await widget.user.updatePassword(_newPasswordController.text);

      _showSuccess(l10n.passwordChangedSuccess);
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        _showError(l10n.currentPasswordIncorrect);
      } else {
        _showError('${l10n.passwordChangeFailed}: ${e.message}');
      }
    } catch (e) {
      _showError('${l10n.unexpectedError}: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _signOut() async {
    final l10n = AppLocalizations.of(context);

    final shouldSignOut = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.signOut),
        content: Text(l10n.signOutConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );

    if (shouldSignOut == true) {
      setState(() => _isLoading = true);
      try {
        await _authService.signOut();
        // التوجيه إلى OnlineMainScreen بدلاً من OnlineLoginScreen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => OnlineMainScreen()),
              (route) => false,
        );
      } catch (e) {
        _showError('${l10n.signOutFailed}: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // زر تبديل اللغة بنفس الخصائص
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

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l10n.profile, style: TextStyle(color: Colors.white)),
        actions: [
          // إضافة أيقونة اللغة في AppBar
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _buildLanguageToggleButton(context),
          ),
        ],
      ),
      body: Container(
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              // ✅ معلومات الحساب
              _buildSection(
                title: l10n.accountInfo,
                icon: Icons.person,
                children: [
                  Text(l10n.email, style: TextStyle(color: Colors.white70)),
                  Text(widget.user.email ?? l10n.noEmail, style: TextStyle(color: Colors.white)),
                  SizedBox(height: 16),
                  TextField(
                    controller: _firstNameController,
                    decoration: InputDecoration(
                      labelText: l10n.firstName,
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                    ),
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _lastNameController,
                    decoration: InputDecoration(
                      labelText: l10n.lastName,
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                    ),
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _updateProfile,
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(l10n.updateProfile),
                  ),
                ],
              ),

              SizedBox(height: 24),

              // ✅ تغيير كلمة المرور
              _buildSection(
                title: l10n.changePassword,
                icon: Icons.lock,
                children: [
                  TextField(
                    controller: _currentPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: l10n.currentPassword,
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                    ),
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _newPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: l10n.newPassword,
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                    ),
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: l10n.confirmNewPassword,
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                    ),
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _changePassword,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(l10n.changePassword),
                  ),
                ],
              ),

              SizedBox(height: 24),

              // ✅ تسجيل الخروج
              _buildSection(
                title: l10n.settings,
                icon: Icons.settings,
                children: [
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signOut,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      minimumSize: Size(double.infinity, 50),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout),
                        SizedBox(width: 8),
                        Text(l10n.signOut),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.yellow),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}