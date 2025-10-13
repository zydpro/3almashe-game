import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ads_service.dart';
import '../services/settings_service.dart';
import '../Languages/LanguageProvider.dart';
import '../Languages/localization.dart';
import 'main_menu_screen.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> with SingleTickerProviderStateMixin {
  late SettingsService _settingsService;
  late AnimationController _languageAnimationController;
  late Animation<double> _languageScaleAnimation;

  // ✅ نفس إعدادات الحجم والظل من الشكل المطلوب
  double cornerShadowBlur = 10.0;
  double cornerShadowSpread = 2.0;
  Color cornerShadowColor = Colors.black.withOpacity(0.5);
  Offset cornerShadowOffset = const Offset(2, 2);
  double cornerIconSize = 50.0;
  double cornerButtonSize = 60.0;

  // بيانات الشخصيات الافتراضية
  final List<Character> characters = [
    Character(
      id: 1,
      name: 'المحارب',
      imagePath: 'assets/images/characters/warrior.png',
      price: 100,
      isLocked: false,
      color: Colors.blue,
    ),
    Character(
      id: 2,
      name: 'الساحر',
      imagePath: 'assets/images/characters/wizard.png',
      price: 200,
      isLocked: true,
      color: Colors.purple,
    ),
    Character(
      id: 3,
      name: 'اللص',
      imagePath: 'assets/images/characters/thief.png',
      price: 300,
      isLocked: true,
      color: Colors.green,
    ),
    Character(
      id: 4,
      name: 'الفارس',
      imagePath: 'assets/images/characters/knight.png',
      price: 400,
      isLocked: true,
      color: Colors.red,
    ),
    Character(
      id: 5,
      name: 'الرامي',
      imagePath: 'assets/images/characters/archer.png',
      price: 500,
      isLocked: true,
      color: Colors.orange,
    ),
    Character(
      id: 6,
      name: 'العملاق',
      imagePath: 'assets/images/characters/giant.png',
      price: 600,
      isLocked: true,
      color: Colors.brown,
    ),
    Character(
      id: 7,
      name: 'التنين',
      imagePath: 'assets/images/characters/dragon.png',
      price: 700,
      isLocked: true,
      color: Colors.deepOrange,
    ),
    Character(
      id: 8,
      name: 'الفينيكس',
      imagePath: 'assets/images/characters/phoenix.png',
      price: 800,
      isLocked: true,
      color: Colors.yellow,
    ),
    Character(
      id: 9,
      name: 'الأسطورة',
      imagePath: 'assets/images/characters/legend.png',
      price: 900,
      isLocked: true,
      color: Colors.cyan,
    ),
    Character(
      id: 10,
      name: 'الإله',
      imagePath: 'assets/images/characters/god.png',
      price: 1000,
      isLocked: true,
      color: Colors.indigo,
    ),
  ];

  int userPoints = 350; // النقاط الحالية للمستخدم

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

  // ✅ دالة شراء الشخصية
  void _purchaseCharacter(Character character) {
    final l10n = AppLocalizations.of(context);

    if (userPoints >= character.price) {
      setState(() {
        userPoints -= character.price;
        character.isLocked = false;
      });

      // إظهار رسالة نجاح الشراء
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.purchasedSuccessfully} ${character.name}!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      // إظهار رسالة عدم كفاية النقاط
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.insufficientPoints),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // ✅ دالة شراء نقاط جديدة
  void _buyPoints() {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            l10n.buyPoints,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 24),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPointsOption('100 نقطة', '10.00', 100),
              const SizedBox(height: 10),
              _buildPointsOption('500 نقطة', '45.00', 500),
              const SizedBox(height: 10),
              _buildPointsOption('1000 نقطة', '80.00', 1000),
              const SizedBox(height: 10),
              _buildPointsOption('5000 نقطة', '350.00', 5000),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                l10n.aboutCancel,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPointsOption(String title, String price, int points) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$price ريال',
                style: const TextStyle(
                  color: Colors.yellow,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              // هنا سيتم دمج نظام الدفع
              setState(() {
                userPoints += points;
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تم شراء $points نقطة بنجاح!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text(
              'شراء',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ دالة مشاهدة إعلان للحصول على نقاط
  void _watchAdForPoints() {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          title: Text(
            l10n.loadingAd,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                l10n.loading,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.watchAdForPoints,
                textAlign: TextAlign.center,
                style: const TextStyle(
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
        setState(() {
          userPoints += 50; // منح 50 نقطة بعد مشاهدة الإعلان
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('🎉 حصلت على 50 نقطة مجانية!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      },
      onAdFailed: (error) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('❌ فشل تحميل الإعلان، حاول مرة أخرى'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }

  // ✅ زر تبديل اللغة - بنفس تصميم الشكل المطلوب
  Widget _buildLanguageToggleButton() {
    return GestureDetector(
      onTap: () {
        final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
        _toggleLanguage(languageProvider);
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

  // ✅ أيقونة اللغة الإنجليزية - بنفس تصميم الشكل المطلوب
  Widget _buildEnglishIcon() {
    return Image.asset(
      'assets/images/main_menu/english_icon.png',
      width: cornerIconSize,
      height: cornerIconSize,
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

  // ✅ أيقونة اللغة العربية - بنفس تصميم الشكل المطلوب
  Widget _buildArabicIcon() {
    return Image.asset(
      'assets/images/main_menu/arabic_icon.png',
      width: cornerIconSize,
      height: cornerIconSize,
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

  Future<void> _toggleLanguage(LanguageProvider languageProvider) async {
    await _languageAnimationController.forward();
    await languageProvider.toggleLanguage();
    await _languageAnimationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // ✅ الهيدر - شريط العودة واللغة والنقاط
            _buildHeaderSection(l10n),

            // ✅ قسم النقاط وشراء النقاط
            _buildPointsSection(l10n),

            // ✅ قائمة الشخصيات
            Expanded(
              child: _buildCharactersGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[900]!, Colors.black],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ✅ زر العودة للشاشة الرئيسية
          GestureDetector(
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const MainMenuScreen()),
                    (route) => false,
              );
            },
            child: Container(
              width: cornerButtonSize,
              height: cornerButtonSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 2,
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
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),

          // ✅ عنوان المتجر
          Text(
            l10n.characterStore,
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

          // ✅ زر اللغة
          _buildLanguageToggleButton(),
        ],
      ),
    );
  }

  Widget _buildPointsSection(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900]!.withOpacity(0.8),
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
        children: [
          // ✅ النقاط الحالية
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.yourPoints,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.orange, Colors.yellow],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Text(
                  '$userPoints 💎',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          // ✅ أزرار شراء النقاط ومشاهدة الإعلان
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _buyPoints,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_cart, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        l10n.buyPoints,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _watchAdForPoints,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_arrow, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        l10n.watchAd,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCharactersGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: characters.length,
      itemBuilder: (context, index) {
        return _buildCharacterCard(characters[index]);
      },
    );
  }

  Widget _buildCharacterCard(Character character) {
    return GestureDetector(
      onTap: () {
        if (!character.isLocked) {
          _showCharacterDetails(character);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900]!.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: character.isLocked ? Colors.grey : character.color,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: character.isLocked
                  ? Colors.grey.withOpacity(0.3)
                  : character.color.withOpacity(0.5),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          children: [
            // ✅ صورة الشخصية
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child: character.isLocked
                    ? _buildLockedCharacter(character)
                    : _buildUnlockedCharacter(character),
              ),
            ),

            // ✅ معلومات الشخصية
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.9),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(17),
                    bottomRight: Radius.circular(17),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      character.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: character.isLocked ? Colors.grey : Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 5),
                    if (character.isLocked)
                      _buildPurchaseButton(character)
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Text(
                          'مملوكة',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ✅ قفل إذا كانت مقفلة
            if (character.isLocked)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedCharacter(Character character) {
    return Stack(
      children: [
        // ✅ خلفية ملونة مع تدرج
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                character.color.withOpacity(0.3),
                character.color.withOpacity(0.1),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),

        // ✅ أيقونة بديلة
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person,
                size: 60,
                color: character.color.withOpacity(0.5),
              ),
              const SizedBox(height: 10),
              Text(
                '🔒',
                style: TextStyle(fontSize: 24),
              ),
            ],
          ),
        ),

        // ✅ طبقة داكنة
        Container(
          color: Colors.black.withOpacity(0.6),
        ),
      ],
    );
  }

  Widget _buildUnlockedCharacter(Character character) {
    return Stack(
      children: [
        // ✅ خلفية ملونة
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                character.color.withOpacity(0.4),
                character.color.withOpacity(0.1),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),

        // ✅ صورة الشخصية (ستحتاج لإضافة الصور في assets)
        Center(
          child: Image.asset(
            character.imagePath,
            width: 80,
            height: 80,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.person,
                size: 80,
                color: character.color,
              );
            },
          ),
        ),

        // ✅ تأثير لامع
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.transparent,
                  Colors.white.withOpacity(0.05),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPurchaseButton(Character character) {
    return GestureDetector(
      onTap: () => _purchaseCharacter(character),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          gradient: userPoints >= character.price
              ? const LinearGradient(
            colors: [Colors.orange, Colors.yellow],
          )
              : LinearGradient(
            colors: [Colors.grey, Colors.grey[700]!],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: userPoints >= character.price
                  ? Colors.orange.withOpacity(0.5)
                  : Colors.grey.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${character.price}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: userPoints >= character.price ? Colors.black : Colors.white,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.diamond,
              size: 16,
              color: userPoints >= character.price ? Colors.blue : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  void _showCharacterDetails(Character character) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  character.color.withOpacity(0.9),
                  Colors.grey[900]!.withOpacity(0.95),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: character.color, width: 3),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✅ صورة الشخصية
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: character.color.withOpacity(0.3),
                    border: Border.all(color: character.color, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: character.color.withOpacity(0.5),
                        blurRadius: 15,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Image.asset(
                      character.imagePath,
                      width: 80,
                      height: 80,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.person,
                          size: 60,
                          color: character.color,
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ✅ اسم الشخصية
                Text(
                  character.name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 15),

                // ✅ وصف الشخصية
                Text(
                  'هذه الشخصية تمتلك قدرات خاصة ومميزات فريدة في اللعبة.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),

                const SizedBox(height: 25),

                // ✅ زر الاختيار
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // هنا يمكن إضافة دورة اختيار الشخصية
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تم اختيار ${character.name}!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: character.color,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'اختيار الشخصية',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ✅ زر الإغلاق
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'إغلاق',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ✅ نموذج بيانات الشخصية
class Character {
  final int id;
  final String name;
  final String imagePath;
  final int price;
  bool isLocked;
  final Color color;

  Character({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.price,
    required this.isLocked,
    required this.color,
  });
}