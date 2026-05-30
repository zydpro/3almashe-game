import 'package:almashe_game/online/screens/online_main_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../Languages/LanguageProvider.dart';
import '../../Languages/localization.dart';
import '../../models/character_model.dart';
import '../../screens/items_Screen.dart';
import '../../screens/main_menu_screen.dart';
import '../../services/Payment_UI_Service.dart';
import '../../services/ads_removal_service.dart';
import '../../services/ads_service.dart';
import '../../services/game_data_service.dart';
import '../../services/payment_service.dart';
import '../../services/settings_service.dart';
import '../models/online_character_system.dart';
import '../services/screen_orientation_service.dart';
import 'online_characters_screen.dart';

class OnlineStoreScreen extends StatefulWidget {
  final String? previousScreen;

  const OnlineStoreScreen({super.key, this.previousScreen});

  @override
  State<OnlineStoreScreen> createState() => _OnlineStoreScreenState();
}

class _OnlineStoreScreenState extends State<OnlineStoreScreen>
    with SingleTickerProviderStateMixin {
  late SettingsService _settingsService;
  late AdsRemovalService _adsRemovalService;
  late PaymentService _paymentService;
  late PaymentUIService _paymentUIService;
  late AnimationController _languageAnimationController;
  late Animation<double> _languageScaleAnimation;

  // ✅ إعدادات التصميم الجديدة
  final double _cornerIconSize = 22.0;
  final double _cornerButtonSize = 36.0;
  final Color _backgroundColor = const Color(0xFF0B1020);
  final Color _cardColor = const Color(0xFF151B2F);
  final Color _accentColor = Colors.amber;

  // ✅ خلفية مخصصة
  final String _backgroundImage = 'assets/images/backgrounds/store_bg.jpg';

  // ✅ حالة التطبيق المحسنة
  List<OnlineCharacter> _storeCharacters = [];
  int _userCoins = 0;
  bool _isLoading = true;
  String _errorMessage = '';

  // ✅ متحكم الصفحة للـ Slide مع Loop
  final PageController _pageController = PageController(
    viewportFraction: 0.25,
    initialPage: 1000, // لضمان عمل الـ Loop
  );
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _settingsService = SettingsService();
    _adsRemovalService = AdsRemovalService();
    _paymentService = PaymentService();
    _paymentUIService = PaymentUIService();

    _settingsService.addListener(_onSettingsChanged);
    _adsRemovalService.addListener(_onAdsSettingsChanged);
    _paymentService.addListener(_onPaymentUpdate);

    _initializeAllServices();
    _initLanguageAnimation();
    _loadData();
    _initializePayment();

    GameDataService().addUpdateListener(_onDataUpdated);

    // ✅ تأخير قفل الشاشة لضمان تطبيقه بعد بناء الويدجت
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScreenOrientationService().lockToLandscape();
      // ✅ إضافة مستمع للتأكد من بقاء الشاشة أفقية
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    });
  }

  Future<void> _initializeAllServices() async {
    try {
      await _adsRemovalService.initialize();
      await _paymentService.initialize();
      await _loadData();
      _testProducts();
    } catch (e) {
      print('❌ Failed to initialize services: $e');
    }
  }

  Future<void> _initializePayment() async {
    try {
      await _paymentUIService.reloadProducts();
      if (mounted) setState(() {});
    } catch (e) {
      print('❌ فشل في تهيئة نظام الدفع: $e');
    }
  }

  void _onDataUpdated() {
    if (mounted) {
      _loadData();
    }
  }

  void _onPaymentUpdate() {
    if (mounted) setState(() {});
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

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final coins = await GameDataService.getUserCoins();
      final allCharacters = OnlineCharacter.getAllOnlineCharacters();
      final ownedCharacters = await GameDataService.getOwnedCharacters();
      final ownedCharacterIds = ownedCharacters.map((char) => char.id).toList();

      final updatedCharacters = allCharacters.map((onlineChar) {
        final isOwned = ownedCharacterIds.contains(onlineChar.id);
        return OnlineCharacter(
          id: onlineChar.id,
          name: onlineChar.name,
          nameEn: onlineChar.nameEn,
          type: onlineChar.type,
          imagePath: onlineChar.imagePath,
          iconPath: onlineChar.iconPath,
          isLocked: !isOwned,
          price: onlineChar.price,
          primaryWeapon: onlineChar.primaryWeapon,
          secondaryWeapon: onlineChar.secondaryWeapon,
          specialAbility: onlineChar.specialAbility,
          specialAbilityCooldown: onlineChar.specialAbilityCooldown,
          characterColor: onlineChar.characterColor,
        );
      }).toList();

      setState(() {
        _userCoins = coins;
        _storeCharacters = updatedCharacters;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ خطأ في OnlineStoreScreen._loadData: $e');
      _handleLoadError();
    }
  }

  void _handleLoadError() {
    setState(() {
      _storeCharacters = OnlineCharacter.getAllOnlineCharacters();
      _isLoading = false;
      _errorMessage = AppLocalizations.of(context).characterLoadError;
    });
  }

  void _onSettingsChanged() => setState(() {});
  void _onAdsSettingsChanged() => setState(() {});

// ==================== TOP BAR التوب بار ====================
  Widget _buildTopBar() {
    final l10n = AppLocalizations.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _cardColor.withOpacity(0.97),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.15),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 5),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          // زر الرجوع - على اليسار
          _buildIconButton(
            Icons.arrow_back_rounded,
            Colors.blue,
                () {
              _safeNavigateTo(const OnlineMainScreen(), 'online_main');
            },
            l10n.close,
          ),
          const SizedBox(width: 8),

          // زر مشاهدة إعلان - مع إضافة النص
          _buildAdWatchButton(),

          const SizedBox(width: 8),

          // النقاط الحالية
          _buildCurrencyDisplay(),

          const Spacer(), // ← إضافة Spacer لتثبيت العنوان في المنتصف

          // اسم المتجر في المنتصف - ثابت لا يتحرك
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.withOpacity(0.9),
                  Colors.blue.withOpacity(0.9),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Text(
              l10n.store,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.0,
                shadows: [
                  Shadow(
                    color: Colors.black45,
                    blurRadius: 4,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const Spacer(), // ← إضافة Spacer من الجهة الأخرى

          // زر شراء العملات
          _buildActionButton(
            Icons.shopping_cart_rounded,
            Colors.green.shade600,
            l10n.buyCoins,
            _openCoinsPurchaseOptions,
          ),

          const SizedBox(width: 8),

          // زر إزالة الإعلانات - مع إضافة النص
          _buildAdsRemovalButton(), // ← تم التعديل هنا

          const SizedBox(width: 8),

          // زر تبديل اللغة
          _buildLanguageToggleButton(),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, Color color, VoidCallback onTap, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.9),
                color.withOpacity(0.5),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyDisplay() {
    return Tooltip(
      message: AppLocalizations.of(context).buyCoinsNow,
      child: GestureDetector(
        onTap: _openCoinsPurchaseOptions,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.amber.shade700,
                Colors.orange.shade600,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.monetization_on_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                "$_userCoins",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  shadows: [
                    Shadow(
                      color: Colors.black45,
                      blurRadius: 3,
                      offset: Offset(1, 1),
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

  Widget _buildActionButton(IconData icon, Color color, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.9),
                color.withOpacity(0.5),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageToggleButton() {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Tooltip(
          message: languageProvider.isArabic ? 'English' : 'العربية',
          child: GestureDetector(
            onTap: () => _toggleLanguage(languageProvider),
            child: ScaleTransition(
              scale: _languageScaleAnimation,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.withOpacity(0.9),
                      Colors.blue.withOpacity(0.5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Center(
                  child: languageProvider.isArabic
                      ? _buildEnglishIcon()
                      : _buildArabicIcon(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnglishIcon() {
    return const Text(
      'EN',
      style: TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            color: Colors.black45,
            blurRadius: 3,
            offset: Offset(1, 1),
          ),
        ],
      ),
    );
  }

  Widget _buildArabicIcon() {
    return const Text(
      'ع',
      style: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        fontFamily: 'Cairo',
        shadows: [
          Shadow(
            color: Colors.black45,
            blurRadius: 3,
            offset: Offset(1, 1),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleLanguage(LanguageProvider languageProvider) async {
    await _languageAnimationController.forward();
    await languageProvider.toggleLanguage();
    await _languageAnimationController.reverse();
  }

  // ==================== CHARACTER SLIDER مع Loop ====================
  Widget _buildCharacterSlider() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage.isNotEmpty) {
      return _buildErrorState();
    }

    if (_storeCharacters.isEmpty) {
      return _buildEmptyCharactersState();
    }

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            // مؤشر الصفحة
            Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _storeCharacters.length,
                        (index) => Container(
                      width: 20,
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: index == _currentPage % _storeCharacters.length
                            ? Colors.blue
                            : Colors.grey.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            Expanded(
              child: Stack(
                children: [
                  // خلفية متحركة
                  Positioned.fill(
                    child: _buildAnimatedBackground(),
                  ),

                  // الشخصيات في Slide مع Loop
                  PageView.builder(
                    controller: _pageController,
                    itemCount: 10000, // لضمان عمل الـ Loop
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final characterIndex = index % _storeCharacters.length;
                      return Padding(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                        child: _buildCharacterCard(
                            _storeCharacters[characterIndex]),
                      );
                    },
                  ),

                  // أزرار التنقل
                  Positioned(
                    left: 5,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _buildNavButton(
                        Icons.arrow_forward_ios,
                            () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    right: 5,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _buildNavButton(
                        Icons.arrow_back_ios,
                            () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.5,
          colors: [
            Colors.purple.withOpacity(0.1),
            Colors.blue.withOpacity(0.05),
            Colors.transparent,
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Opacity(
        opacity: 0.15,
        child: Image.asset(
          'assets/images/backgrounds/temple.png',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    Colors.blue.withOpacity(0.08),
                    Colors.purple.withOpacity(0.04),
                    Colors.transparent,
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNavButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 70,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.black.withOpacity(0.5),
            ],
            begin: Alignment.center,
            end: Alignment.center,
          ),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildCharacterCard(OnlineCharacter character) {
    final l10n = AppLocalizations.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isFree = character.price == 0;
    final canAfford = _userCoins >= character.price;
    final isOwned = !character.isLocked;

    return GestureDetector(
      onTap: () => _showCharacterDetails(character, l10n, isArabic, isOwned),
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              character.characterColor.withOpacity(0.9),
              character.characterColor.withOpacity(0.6),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: character.characterColor.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.4),
            width: 3,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              // صورة الشخصية
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(character.imagePath),
                      fit: BoxFit.contain,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // تدرج فوق الصورة
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),

                      // علامة الملكية/السعر
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withOpacity(0.4)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isOwned && !isFree)
                                const Icon(Icons.monetization_on,
                                    color: Colors.yellow, size: 14),
                              const SizedBox(width: 5),
                              Text(
                                isOwned
                                    ? l10n.owned
                                    : isFree
                                    ? l10n.freePoints
                                    : '${character.price}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // معلومات الشخصية
              Expanded(
                flex: 2,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.9),
                        Colors.black.withOpacity(0.7),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        isArabic ? character.name : character.nameEn,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black45,
                              blurRadius: 2,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),

                      Text(
                        character.type,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 11,
                          shadows: [
                            Shadow(
                              color: Colors.black45,
                              blurRadius: 1,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),

                      // زر الشراء
                      SizedBox(
                        width: double.infinity,
                        height: 32,
                        child: ElevatedButton(
                          onPressed: isOwned
                              ? null
                              : (isFree || canAfford
                              ? () => _purchaseCharacter(character)
                              : null),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isOwned
                                ? Colors.green
                                : isFree
                                ? Colors.green
                                : canAfford
                                ? Colors.orangeAccent
                                : Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.zero,
                            elevation: 4,
                          ),
                          child: Text(
                            isOwned
                                ? l10n.owned
                                : isFree
                                ? l10n.freePoints
                                : '${l10n.buyNow} ${character.price}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
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

  // ==================== LOADING & ERROR STATES ====================
  Widget _buildLoadingState() {
    final l10n = AppLocalizations.of(context);

    return Expanded(
      child: Center(
        child: Container(
          width: 300,
          height: 200,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _cardColor.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.orange, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 70,
                height: 70,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: _cardColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.orange, width: 3),
                ),
                child: const CircularProgressIndicator(
                  color: Colors.orange,
                  strokeWidth: 4,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.loadingCharacters,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final l10n = AppLocalizations.of(context);

    return Expanded(
      child: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _cardColor.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.orange, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 50,
                color: Colors.orange,
              ),
              const SizedBox(height: 15),
              Text(
                _errorMessage,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 4,
                ),
                child: Text(
                  l10n.retry,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCharactersState() {
    final l10n = AppLocalizations.of(context);

    return Expanded(
      child: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _cardColor.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.person_off,
                size: 50,
                color: Colors.grey,
              ),
              const SizedBox(height: 15),
              Text(
                l10n.allCharactersPurchased,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                l10n.noCharactersAvailable,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== MAIN BUILD مع حجم كامل للشاشة ====================
  @override
  Widget build(BuildContext context) {
    // ✅ التأكد من قفل الشاشة قبل بناء الواجهة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScreenOrientationService().lockToLandscape();
      // ✅ إضافة قفل إضافي للتأكد
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              _backgroundColor,
              _cardColor.withOpacity(0.8),
              _backgroundColor.withOpacity(0.9),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // خلفية التوهج
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.5,
                    colors: [
                      Colors.purple.withOpacity(0.15),
                      Colors.blue.withOpacity(0.08),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.3, 1.0],
                  ),
                ),
              ),
            ),

            // ✅ إضافة Listener للتغيرات في التوجيه
            OrientationBuilder(
              builder: (context, orientation) {
                // إذا تغير التوجيه، أعد قفله
                if (orientation != Orientation.landscape) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ScreenOrientationService().lockToLandscape();
                  });
                }
                return Column(
                  children: [
                    // التوب بار
                    Container(
                      height: 70,
                      child: _buildTopBar(),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: _buildCharacterSlider(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ==================== دوال العملات والإعلانات ====================
  void _openCoinsPurchaseOptions() async {
    final l10n = AppLocalizations.of(context);
    if (!_paymentService.isInitialized) {
      await _paymentService.initialize();
    }
    if (_paymentService.products.isEmpty) {
      await _paymentUIService.reloadProducts();
    }
    showDialog(
      context: context,
      builder: (BuildContext context) => _buildCoinsPurchaseDialog(l10n),
    );
  }

  void _openAdsRemovalOptions() {
    final l10n = AppLocalizations.of(context);
    if (!_paymentService.isInitialized || _paymentService.products.isEmpty) {
      _paymentUIService.reloadProducts();
    }
    showDialog(
      context: context,
      builder: (BuildContext context) => _buildAdsRemovalDialog(l10n),
    );
  }

  Widget _buildCoinsPurchaseDialog(AppLocalizations l10n) {
    return Dialog(
      backgroundColor: _cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.blue.withOpacity(0.5), width: 2),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.withOpacity(0.8),
                        Colors.blue.withOpacity(0.4),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    l10n.buyCoins,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                _paymentUIService.buildPaymentStatus(l10n,
                    onRetry: _initializePayment),
                const SizedBox(height: 16),
                ..._paymentUIService.buildAllCoinsOptions(l10n, _purchaseCoins),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      l10n.close,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdsRemovalButton() {
    final l10n = AppLocalizations.of(context);
    return Tooltip(
      message: l10n.adsRemoval,
      child: GestureDetector(
        onTap: _openAdsRemovalOptions,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.red.shade600.withOpacity(0.9),
                Colors.orange.shade600.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.block_rounded,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 6),
              Text(
                l10n.removeAds, // ← سيظهر "إزالة الإعلانات" أو "Remove Ads"
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black45,
                      blurRadius: 2,
                      offset: Offset(1, 1),
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

  Widget _buildAdsRemovalDialog(AppLocalizations l10n) {
    return Dialog(
      backgroundColor: _cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.purpleAccent.withOpacity(0.5), width: 2),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.purple.withOpacity(0.8),
                        Colors.purple.withOpacity(0.4),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    l10n.adsRemoval,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                _buildCurrentAdsStatus(l10n),
                const SizedBox(height: 12),
                _paymentUIService.buildPaymentStatus(l10n,
                    onRetry: _initializePayment),
                const SizedBox(height: 16),
                if (!_adsRemovalService.isActive) ...[
                  ..._paymentUIService.buildAllAdsRemovalOptions(
                      l10n, _purchaseAdsRemoval),
                  const SizedBox(height: 12),
                  _buildTemporaryRemovalOption(l10n),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      l10n.close,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentAdsStatus(AppLocalizations l10n) {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (_adsRemovalService.isActive) {
      statusText = _adsRemovalService.isTemporary
          ? l10n.removeAdsTemporarily
          : l10n.adsDisabled;
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      if (_adsRemovalService.expiryDate != null) {
        bool isArabic = l10n.locale.languageCode == 'ar';
        statusText +=
        ' (${_adsRemovalService.getRemainingTime(isArabic: isArabic)})';
      } else if (!_adsRemovalService.isTemporary) {
        statusText += ' (${l10n.lifetime})';
      }
    } else {
      statusText = l10n.adsEnabled;
      statusColor = Colors.orange;
      statusIcon = Icons.ad_units;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor, width: 2),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 14,
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemporaryRemovalOption(AppLocalizations l10n) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showTemporaryRemovalConfirmation(l10n),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.withOpacity(0.2),
                Colors.blue.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue, width: 2),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_circle, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l10n.watchAdToRemove} 30 ${l10n.minutes}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.removeAdsTemporarily,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.blue, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _purchaseCoins(String productId) =>
      _paymentService.purchaseProduct(productId);
  void _purchaseAdsRemoval(String productId) =>
      _paymentService.purchaseProduct(productId);

// ==================== دالة عرض تفاصيل الشخصية ====================
  void _showCharacterDetails(
      OnlineCharacter character, AppLocalizations l10n, bool isArabic, bool isOwned) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.6, // أصغر عرض
              maxHeight: MediaQuery.of(context).size.height * 0.7, // أصغر ارتفاع
            ),
            padding: const EdgeInsets.all(16), // أصغر حشوة
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  character.characterColor.withOpacity(0.9),
                  character.characterColor.withOpacity(0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16), // زوايا أصغر
              border: Border.all(color: Colors.white, width: 2), // حدود أرق
              boxShadow: [
                BoxShadow(
                  color: character.characterColor.withOpacity(0.5),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // صورة الشخصية - أصغر
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(35),
                      border: Border.all(color: Colors.white, width: 2),
                      image: DecorationImage(
                        image: AssetImage(character.imagePath),
                        fit: BoxFit.contain,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // اسم الشخصية - نص أصغر
                  Text(
                    isArabic ? character.name : character.nameEn,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // نوع الشخصية - نص أصغر
                  Text(
                    character.type,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 12),

                  // وصف الشخصية - مساحة أصغر
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isArabic
                          ? _getCharacterDescription(character)
                          : _getCharacterDescriptionEn(character),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3, // عدد أسطر محدود
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // // الأسلبة - تصميم مضغوط

                  // Row(
                  //   children: [
                  //     Expanded(
                  //       child: _buildCompactWeaponInfo(
                  //         _getWeaponName(character.primaryWeapon),
                  //         _getWeaponNameEn(character.primaryWeapon),
                  //         isArabic,
                  //         Icons.sports_martial_arts,
                  //         Colors.blue,
                  //       ),
                  //     ),
                  //     const SizedBox(width: 6),
                  //     Expanded(
                  //       child: _buildCompactWeaponInfo(
                  //         _getWeaponName(character.secondaryWeapon),
                  //         _getWeaponNameEn(character.secondaryWeapon),
                  //         isArabic,
                  //         Icons.security,
                  //         Colors.green,
                  //       ),
                  //     ),
                  //   ],
                  // ),
                  //
                  // const SizedBox(height: 12),
                  //
                  // // القدرة الخاصة - تصميم مضغوط
                  // _buildCompactSpecialAbility(character, isArabic),
                  //
                  // const SizedBox(height: 16),

                  // الأزرار - تصميم مضغوط
                  _buildCharacterActionButtons(character, l10n, isArabic, isOwned),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

// ==================== دوال مساعدة للتصميم ====================

  Widget _buildCompactWeaponInfo(
      String weaponNameAr, String weaponNameEn, bool isArabic, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 14),
          ),
          const SizedBox(height: 4),
          Text(
            isArabic ? weaponNameAr : weaponNameEn,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSpecialAbility(OnlineCharacter character, bool isArabic) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withOpacity(0.3),
            Colors.orange.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.flash_on, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'القدرة الخاصة' : 'Special Ability',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  character.specialAbility,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterActionButtons(
      OnlineCharacter character, AppLocalizations l10n, bool isArabic, bool isOwned) {
    return Column(
      children: [
        if (!isOwned) ...[
          // زر الشراء - تصميم مضغوط
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _purchaseCharacter(character);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                elevation: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '${l10n.buyNow} - ${character.price}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // زر شراء العملات - تصميم مضغوط
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _openCoinsPurchaseOptions();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                elevation: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.monetization_on, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    l10n.buyCoins,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          // إذا كانت مملوكة - زر أصغر
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _goToCharacters();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                elevation: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    isArabic ? 'الذهاب إلى الشخصيات' : 'Go to Characters',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 8),

        // زر الإغلاق - أصغر
        SizedBox(
          width: double.infinity,
          height: 35,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: Text(
              l10n.close,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeaponInfo(
      String weaponNameAr, String weaponNameEn, bool isArabic, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isArabic ? weaponNameAr : weaponNameEn,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _purchaseCharacter(OnlineCharacter character) async {
    final l10n = AppLocalizations.of(context);
    final currentCoins = await GameDataService.getUserCoins();

    if (currentCoins < character.price) {
      _showSnackBar(l10n.insufficientPoints, Colors.red);
      _openCoinsPurchaseOptions();
      return;
    }

    final isOwned = await GameDataService.isCharacterOwned(character.id);
    if (isOwned) {
      _showSnackBar(l10n.characterAlreadyOwned, Colors.orange);
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: _cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.orange, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    image: DecorationImage(
                      image: AssetImage(character.imagePath),
                      fit: BoxFit.cover,
                    ),
                    border: Border.all(color: Colors.orange, width: 2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.confirmPurchase,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.purchaseConfirmation(character.name, character.price),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[700],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          l10n.cancel,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          final gameCharacter = _convertToGameCharacter(character);
                          final success =
                          await GameDataService.purchaseCharacter(gameCharacter);

                          if (success) {
                            _showSnackBar(
                                l10n.purchaseSuccess(character.name), Colors.green);
                            await _loadData();
                          } else {
                            _showSnackBar(l10n.purchaseFailed, Colors.red);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          l10n.confirm,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdWatchButton() {
    final l10n = AppLocalizations.of(context);
    return Tooltip(
      message: l10n.watchAdForCoins,
      child: GestureDetector(
        onTap: _watchAdForPoints,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple.shade600.withOpacity(0.9),
                Colors.purple.shade400.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 6),
              Text(
                l10n.watchAd, // ← سيظهر "شاهد إعلان" أو "Watch Ad"
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black45,
                      blurRadius: 2,
                      offset: Offset(1, 1),
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

  void _watchAdForPoints() {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.blue, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow,
                      color: Colors.white, size: 30),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.loadingAd,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const CircularProgressIndicator(color: Colors.blue),
                const SizedBox(height: 12),
                // إضافة نص "شاهد إعلان" هنا أيضاً
                Text(
                  l10n.watchAdForCoins,
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 14, // ← زيادة حجم الخط
                    fontWeight: FontWeight.bold, // ← جعل النص عريض
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                // إضافة نص توضيحي
                Text(
                  l10n.watchAdForCoins, // ← أو يمكنك إضافة ترجمة جديدة "سوف تحصل على 20 عملة"
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );

    AdsService.showInterstitialAd(
      onAdStarted: () => Navigator.pop(context),
      onAdCompleted: () async {
        await GameDataService.addCharacterCoins(20);
        setState(() => _userCoins += 20);
        _showSnackBar(l10n.coinsAdded(20), Colors.green);
      },
      onAdFailed: (error) {
        Navigator.pop(context);
        _showSnackBar(l10n.adFailed, Colors.red);
      },
    );
  }

  void _goToCharacters() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const OnlineCharactersScreen(),
        settings: const RouteSettings(name: 'Characters_Screen'),
      ),
    ).then((_) {
      ScreenOrientationService().lockToLandscape();
    });
  }

  void _showTemporaryRemovalConfirmation(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: _cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.blue, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_circle,
                      color: Colors.white, size: 30),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.removeAdsTemporarily,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  '${l10n.watchAdToRemove} 30 ${l10n.minutes}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[700],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          l10n.cancel,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _processTemporaryRemoval(l10n);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          l10n.watchAd,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _processTemporaryRemoval(AppLocalizations l10n) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.blue, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Colors.blue),
                const SizedBox(height: 16),
                Text(
                  l10n.loadingAd,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      await AdsService.showRewardedAd(
        onAdStarted: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        },
        onAdCompleted: () async {
          final removalSuccess = await _adsRemovalService
              .removeAdsTemporarily(const Duration(minutes: 30));
          if (removalSuccess && mounted) {
            // _showTemporaryRemovalSuccess(l10n);
          } else if (mounted) {
            // _showPurchaseError(l10n);
          }
        },
        onAdFailed: (error) {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          if (mounted) {
            _showAdError(l10n);
          }
        },
      );
    } catch (e) {
      if (mounted) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        _showAdError(l10n);
      }
    }
  }

  void _showAdError(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.red, width: 2),
          ),
          title: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  l10n.adFailed,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
          content: Text(
            l10n.adFailedMessage,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(l10n.close),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // ==================== دوال المساعدة ====================
  GameCharacter _convertToGameCharacter(OnlineCharacter onlineChar) {
    return GameCharacter(
      id: onlineChar.id,
      name: onlineChar.name,
      nameEn: onlineChar.nameEn,
      imagePath: onlineChar.imagePath,
      price: onlineChar.price.toDouble(),
      isLocked: onlineChar.isLocked,
      color: _getCharacterColor(onlineChar.id),
      animations: _getDefaultAnimations(),
      description: _getCharacterDescription(onlineChar),
      descriptionEn: _getCharacterDescriptionEn(onlineChar),
      type: onlineChar.type,
      abilities: [onlineChar.specialAbility],
      characterKey: 'online_character_${onlineChar.id}',
      attackName: _getWeaponName(onlineChar.primaryWeapon),
      attackNameEn: _getWeaponNameEn(onlineChar.primaryWeapon),
      attackDescription: 'هجوم ${_getWeaponName(onlineChar.primaryWeapon)}',
      attackDescriptionEn: '${_getWeaponNameEn(onlineChar.primaryWeapon)} Attack',
      attackType: AttackType.almashePackage,
      attackDamage: 25,
      attackSpeed: 1.0,
      attackCooldown: 1.0,
      attackEffects: [],
      attackSound: 'attack_sound',
    );
  }

  List<String> _getDefaultAnimations() => ['idle_1.png', 'run_1.png', 'jump_1.png', 'attack_1.png'];

  Color _getCharacterColor(int id) {
    final colors = [Colors.blue, Colors.purple, Colors.green, Colors.orange, Colors.red, Colors.teal];
    return colors[id % colors.length];
  }

  String _getCharacterDescription(OnlineCharacter character) =>
      '${character.name} - ${character.type}. ${character.specialAbility}';

  String _getCharacterDescriptionEn(OnlineCharacter character) =>
      '${character.nameEn} - ${character.type}. ${character.specialAbility}';

  String _getWeaponName(OnlineWeaponType weaponType) {
    switch (weaponType) {
      case OnlineWeaponType.sword: return 'سيف';
      case OnlineWeaponType.hammer: return 'مطرقة';
      case OnlineWeaponType.bow: return 'قوس';
      case OnlineWeaponType.staff: return 'عصا سحرية';
      case OnlineWeaponType.dagger: return 'خنجر';
      case OnlineWeaponType.axe: return 'فأس';
      default: return 'سلاح';
    }
  }

  String _getWeaponNameEn(OnlineWeaponType weaponType) {
    switch (weaponType) {
      case OnlineWeaponType.sword: return 'Sword';
      case OnlineWeaponType.hammer: return 'Hammer';
      case OnlineWeaponType.bow: return 'Bow';
      case OnlineWeaponType.staff: return 'Magic Staff';
      case OnlineWeaponType.dagger: return 'Dagger';
      case OnlineWeaponType.axe: return 'Axe';
      default: return 'Weapon';
    }
  }

  void _testProducts() {
    print('=== 🛒 PRODUCTS TEST ===');
    print('📦 Products count: ${_paymentService.products.length}');
    print('🔄 Payment Initialized: ${_paymentService.isInitialized}');
    print('📱 Payment Available: ${_paymentService.isAvailable}');
    if (_paymentService.products.isEmpty) {
      print('❌ NO PRODUCTS LOADED!');
    } else {
      _paymentService.products.forEach((product) {
        print('💰 ${product.id} - ${product.price} - ${product.title}');
      });
    }
    print('========================');
  }

  // ✅ دالة للإنتقال الآمن مع الحفاظ على التوجيه
  void _safeNavigateTo(Widget screen, String routeName) {
    // أولاً: تأكد من قفل الشاشة
    ScreenOrientationService().lockToLandscape();

    // ثانياً: انتظر قليلاً ثم انتقل
    Future.delayed(const Duration(milliseconds: 50), () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => screen,
          settings: RouteSettings(name: routeName),
        ),
      );
    });
  }

  @override
  void dispose() {
    _settingsService.removeListener(_onSettingsChanged);
    _adsRemovalService.removeListener(_onAdsSettingsChanged);
    _paymentService.removeListener(_onPaymentUpdate);
    _languageAnimationController.dispose();
    _pageController.dispose();
    GameDataService().removeUpdateListener(_onDataUpdated);
    super.dispose();
  }
}