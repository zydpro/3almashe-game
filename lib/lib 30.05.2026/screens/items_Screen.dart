import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ads_service.dart';
import '../services/game_data_service.dart';
import '../services/payment_service.dart';
import '../services/Payment_UI_Service.dart';
import '../services/settings_service.dart';
import '../services/ads_removal_service.dart';
import '../Languages/LanguageProvider.dart';
import '../Languages/localization.dart';
import 'main_menu_screen.dart';
import 'store_screen.dart';
import 'levels_screen.dart';
import '../models/character_model.dart';

class itemsScreen extends StatefulWidget {
  const itemsScreen({super.key});

  @override
  State<itemsScreen> createState() => _itemsScreenState();
}

class _itemsScreenState extends State<itemsScreen> with SingleTickerProviderStateMixin {
  late SettingsService _settingsService;
  late PaymentService _paymentService; // ✅ أضف خدمة الدفع
  late PaymentUIService _paymentUIService;
  late AnimationController _languageAnimationController;
  late Animation<double> _languageScaleAnimation;

  // إعدادات التصميم المعدلة
  final double _cornerShadowBlur = 8.0;
  final double _cornerShadowSpread = 1.0;
  final Color _cornerShadowColor = Colors.black.withOpacity(0.4);
  final Offset _cornerShadowOffset = const Offset(1, 1);
  final double _cornerIconSize = 40.0;
  final double _cornerButtonSize = 50.0;

  // حالة التطبيق
  int _userPoints = 1000;
  GameCharacter? _selectedCharacter;
  List<GameCharacter> _ownedCharacters = [];
  List<GameCharacter> _availableCharacters = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initLanguageAnimation();
    _loadUserData();
    _initializePayment(); // ⚡ مباشرة بدون تأخير
    _clearImageCache();

    GameDataService().addUpdateListener(_onDataUpdated);
  }

// ✅ دالة منفصلة لتهيئة الخدمات
  void _initializeServices() {
    _settingsService = SettingsService();
    _paymentService = PaymentService();
    _paymentUIService = PaymentUIService();

    _settingsService.addListener(_onSettingsChanged);
    _paymentService.addListener(_onPaymentUpdate);
  }

  Future<void> _initializePayment() async {
    // ✅ تحقق مبدئي من mounted
    if (!mounted) return;

    try {
      print('🔄 بدء تهيئة نظام الدفع...');

      await _paymentService.initialize();

      // ✅ تحقق بعد كل عملية غير متزامنة
      if (!mounted) return;
      await _paymentUIService.reloadProducts();

      if (!mounted) return;
      setState(() {});

      print('✅ تم تهيئة نظام الدفع بنجاح - ${_paymentService.products.length} منتج');

    } catch (e) {
      print('❌ فشل في تهيئة نظام الدفع: $e');
      // ✅ لا حاجة لـ setState هنا إلا إذا كنا نعرض خطأ
    }
  }

  void _clearImageCache() {
    imageCache.clear();
    imageCache.clearLiveImages();
    if (Platform.isAndroid) {
      SystemChannels.platform.invokeMethod('System.gc');
    }
  }

  void _onDataUpdated() {
    if (mounted) {
      _loadUserData();
    }
  }

  void _onPaymentUpdate() {
    if (mounted) setState(() {}); // ✅ تحديث الواجهة عند تغيير حالة الدفع
  }

  void _initLanguageAnimation() {
    _languageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
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

  // ✅ دالة تحميل البيانات المحسنة
  Future<void> _loadUserData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      // ✅ تحميل متوازي لتحسين الأداء
      final results = await Future.wait([
        GameDataService.getUserCoins(),
        GameDataService.getAllCharactersWithLockStatus(),
        GameDataService.getSelectedCharacter(),
      ], eagerError: true);

      final coins = results[0] as int;
      final allCharacters = results[1] as List<GameCharacter>;
      final selected = results[2] as GameCharacter?;

      // ✅ تصنيف الشخصيات
      final ownedCharacters = allCharacters.where((char) => !char.isLocked).toList();
      final availableCharacters = allCharacters.where((char) => char.isLocked).toList();

      // ✅ تحديث الواجهة فقط إذا كانت الشاشة مازالت مفتوحة
      if (!mounted) return;

      setState(() {
        _userPoints = coins;
        _ownedCharacters = ownedCharacters;
        _availableCharacters = availableCharacters;
        _selectedCharacter = selected;
        _isLoading = false;
      });

    } catch (e) {
      if (!mounted) return;
      _handleLoadError();
    }
  }

  void _handleLoadError() {
    final defaultCharacter = GameCharacter.getDefaultCharacter();
    setState(() {
      _userPoints = 1000;
      _ownedCharacters = [defaultCharacter];
      _availableCharacters = GameCharacter.getAllCharactersSync()
          .where((char) => char.id != defaultCharacter.id)
          .toList();
      _selectedCharacter = defaultCharacter;
      _isLoading = false;
    });
  }

  void _onSettingsChanged() => setState(() {});

  // ✅ دالة اختيار الشخصية مع الترجمة
  Future<void> _selectCharacter(GameCharacter character) async {
    await GameDataService.setSelectedCharacter(character);

    final l10n = AppLocalizations.of(context);
    _showSnackBar(
      '${l10n.characterSelected} ${character.name}!',
      Colors.green,
    );

    setState(() {
      _selectedCharacter = character;
    });
  }

  // ✅ دالة شراء شخصية جديدة مع الترجمة
  Future<void> _purchaseCharacter(GameCharacter character) async {
    final l10n = AppLocalizations.of(context);

    if (_userPoints < character.integerPrice) {
      _showSnackBar(l10n.insufficientPoints, Colors.red);
      return;
    }

    final success = await GameDataService.purchaseCharacter(character);

    if (success) {
      await _loadUserData();
      _showSnackBar(
        l10n.purchaseSuccess(character.name),
        Colors.green,
      );
    } else {
      _showSnackBar(l10n.purchaseFailed, Colors.red);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontSize: 14),
        ),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ✅ فتح خيارات شراء العملات عبر نظام الدفع الجديد
  void _openCoinsPurchaseOptions() {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _buildCoinsPurchaseDialog(l10n);
      },
    );
  }

  // ✅ بناء دايالوج شراء العملات عبر نظام الدفع
  Widget _buildCoinsPurchaseDialog(AppLocalizations l10n) {
    return Dialog(
      backgroundColor: Colors.grey[900]!.withOpacity(0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.blue, width: 2),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.buyCoins,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // ✅ حالة نظام الدفع
            _paymentUIService.buildPaymentStatus(l10n, onRetry: _initializePayment),

            const SizedBox(height: 16),

            // ✅ خيارات شراء العملات - التصحيح هنا
            ..._paymentUIService.buildAllCoinsOptions(l10n, _purchaseCoins),

            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                l10n.cancel,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ شراء العملات عبر نظام الدفع
  Future<void> _purchaseCoins(String productId) async {
    if (!mounted) return;

    try {
      final l10n = AppLocalizations.of(context);

      // ✅ تحقق من تهيئة النظام أولاً - استخدام النصوص الجديدة
      if (!_paymentService.isInitialized) {
        _showSnackBar(l10n.paymentSystemLoading, Colors.orange);
        await _initializePayment();
        if (!mounted) return;
      }

      // ✅ تحقق من وجود عملية شراء سابقة - استخدام النصوص الجديدة
      if (_paymentService.isLoading) {
        _showSnackBar(l10n.purchaseInProgress, Colors.orange);
        return;
      }

      // ✅ تحقق من توفر المنتج - استخدام النصوص الجديدة
      final product = _paymentService.getProductById(productId);
      if (product == null) {
        _showSnackBar(l10n.productNotAvailable, Colors.red);
        return;
      }

      _showSnackBar(l10n.processingPurchase, Colors.blue);
      await _paymentService.purchaseProduct(productId);

    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      _showSnackBar('${l10n.purchaseFailed}: ${e.toString()}', Colors.red);
    }
  }

  // ✅ دالة مشاهدة إعلان للحصول على نقاط مع الترجمة
  Future<void> _watchAdForPoints() async {
    final l10n = AppLocalizations.of(context);

    _showLoadingDialog(l10n.loadingAd, l10n);

    final result = await AdsService.showInterstitialAd(
      onAdStarted: () => Navigator.pop(context),
      onAdCompleted: () async {
        await GameDataService.addCharacterCoins(20);
        setState(() {
          _userPoints += 20;
        });
        _showSnackBar(l10n.coinsAdded(20), Colors.green);
      },
      onAdFailed: (error) {
        Navigator.pop(context);
        _showSnackBar(l10n.adFailed, Colors.red);
      },
    );

    if (!result) {
      Navigator.pop(context);
    }
  }

  void _showLoadingDialog(String title, AppLocalizations l10n) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                l10n.loading,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        );
      },
    );
  }

  // ✅ زر تبديل اللغة
  Widget _buildLanguageToggleButton() {
    return GestureDetector(
      onTap: () => _toggleLanguage(),
      child: Container(
        width: _cornerButtonSize,
        height: _cornerButtonSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.01),
          border: Border.all(
            color: Colors.white.withOpacity(0.01),
            width: 0.1,
          ),
          boxShadow: [
            BoxShadow(
              color: _cornerShadowColor,
              blurRadius: _cornerShadowBlur,
              spreadRadius: _cornerShadowSpread,
              offset: _cornerShadowOffset,
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

  Widget _buildEnglishIcon() {
    return Image.asset(
      'assets/images/main_menu/english_icon.png',
      width: _cornerIconSize,
      height: _cornerIconSize,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: _cornerIconSize,
          height: _cornerIconSize,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF012169), Color(0xFFC8102E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(_cornerIconSize / 2),
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

  Widget _buildArabicIcon() {
    return Image.asset(
      'assets/images/main_menu/arabic_icon.png',
      width: _cornerIconSize,
      height: _cornerIconSize,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: _cornerIconSize,
          height: _cornerIconSize,
          decoration: BoxDecoration(
            color: const Color(0xFF006233),
            borderRadius: BorderRadius.circular(_cornerIconSize / 2),
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

  Future<void> _toggleLanguage() async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    await _languageAnimationController.forward();
    await languageProvider.toggleLanguage();
    await _languageAnimationController.reverse();
  }

  void _goToStore() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StoreScreen()),
    );
  }

  void _goToMainMenu() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MainMenuScreen()),
          (route) => false,
    );
  }

  // ✅ الذهاب إلى شاشة المراحل مع إعدادات المسار
  void _goToLevels() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LevelsScreen(),
        settings: const RouteSettings(name: '/levels_from_items'),
      ),
    );
  }

  // ✅ فتح خيارات إزالة الإعلانات عبر نظام الدفع الجديد
  void _openAdsRemovalOptions() {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _buildAdsRemovalDialog(l10n);
      },
    );
  }

// ✅ بناء دايالوج إزالة الإعلانات عبر نظام الدفع
  Widget _buildAdsRemovalDialog(AppLocalizations l10n) {
    return Consumer<AdsRemovalService>(
      builder: (context, adsService, child) {
        return Dialog(
          backgroundColor: Colors.grey[900]!.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF048A81), width: 2),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.adsRemoval,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 12),

                // حالة الإعلانات الحالية
                _buildCurrentAdsStatus(l10n, adsService),

                const SizedBox(height: 12),

                // ✅ حالة نظام الدفع - استخدام PaymentUIService
                _paymentUIService.buildPaymentStatus(l10n, onRetry: _initializePayment),

                const SizedBox(height: 16),

                // ✅ خيارات إزالة الإعلانات - استخدام PaymentUIService
                if (!adsService.isActive) ...[
                  ..._paymentUIService.buildAllAdsRemovalOptions(l10n, _purchaseAdsRemoval),
                  const SizedBox(height: 12),

                  // خيار الإزالة المؤقتة
                  _buildTemporaryRemovalOption(l10n, adsService),
                ],

                const SizedBox(height: 16),

                // زر الإغلاق
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      padding: const EdgeInsets.symmetric(vertical: 10),
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
        );
      },
    );
  }

  // ✅ شراء إزالة الإعلانات عبر نظام الدفع
  Future<void> _purchaseAdsRemoval(String productId) async {
    await _purchaseCoins(productId); // ✅ إعادة استخدام نفس المنطق
  }

  // ✅ خيار الإزالة المؤقتة
  Widget _buildTemporaryRemovalOption(AppLocalizations l10n, AdsRemovalService adsService) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showTemporaryRemovalConfirmation(l10n, adsService),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue, width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.play_circle,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l10n.watchAdToRemove} 30 ${l10n.minutes}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.removeAdsTemporarily,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.blue,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ دوال معالجة الشراء المؤقت
  void _showTemporaryRemovalConfirmation(AppLocalizations l10n, AdsRemovalService adsService) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900]!.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.blue, width: 2),
          ),
          title: Text(
            l10n.removeAdsTemporarily,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.play_circle, size: 50, color: Colors.blue),
              const SizedBox(height: 12),
              Text(
                '${l10n.watchAdToRemove} 30 ${l10n.minutes}',
                style: const TextStyle(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                l10n.removeAdsTemporarily,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      l10n.cancel,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _processTemporaryRemoval(l10n, adsService);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    child: Text(
                      l10n.watchAd,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _processTemporaryRemoval(AppLocalizations l10n, AdsRemovalService adsService) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            l10n.loadingAd,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                l10n.loading,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        );
      },
    );

    try {
      final adSuccess = await AdsService.showRewardedAd(
        onAdStarted: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        },
        onAdCompleted: () async {
          final removalSuccess = await adsService.removeAdsTemporarily(const Duration(minutes: 30));
          if (removalSuccess && mounted) {
            _showTemporaryRemovalSuccess(l10n);
          } else if (mounted) {
            _showPurchaseError(l10n);
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

      if (!adSuccess && mounted) {
        _showAdError(l10n);
      }
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
          backgroundColor: Colors.grey[900]!.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.red, width: 2),
          ),
          title: Text(
            l10n.adFailed,
            style: const TextStyle(color: Colors.red, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error, size: 50, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                l10n.adFailedMessage,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: Text(l10n.close, style: const TextStyle(fontSize: 14)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showTemporaryRemovalSuccess(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900]!.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.blue, width: 2),
          ),
          title: Text(
            l10n.purchaseSuccessful,
            style: const TextStyle(color: Colors.blue, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, size: 50, color: Colors.blue),
              const SizedBox(height: 12),
              Text(
                '${l10n.purchaseSuccessMessage}\n\n${l10n.remainingTime}: 30 ${l10n.minutes}',
                style: const TextStyle(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                child: Text(l10n.close, style: const TextStyle(fontSize: 14)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPurchaseError(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900]!.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.red, width: 2),
          ),
          title: Text(
            l10n.purchaseFailed,
            style: const TextStyle(color: Colors.red, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error, size: 50, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                l10n.purchaseErrorMessage,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: Text(l10n.close, style: const TextStyle(fontSize: 14)),
              ),
            ),
          ],
        );
      },
    );
  }

  // ✅ حالة الإعلانات الحالية للدايالوج
  Widget _buildCurrentAdsStatus(AppLocalizations l10n, AdsRemovalService adsService) {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (adsService.isActive) {
      statusText = adsService.isTemporary ? l10n.removeAdsTemporarily : l10n.adsDisabled;
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;

      if (adsService.expiryDate != null) {
        bool isArabic = l10n.locale.languageCode == 'ar';
        statusText += ' (${adsService.getRemainingTime(isArabic: isArabic)})';
      } else if (!adsService.isTemporary) {
        statusText += ' (${l10n.lifetime})';
      }
    } else {
      statusText = l10n.adsEnabled;
      statusColor = Colors.orange;
      statusIcon = Icons.ad_units;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusColor, width: 1),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 14,
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeaderSection(l10n),
            _buildPointsSection(l10n),
            _buildTabSection(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(12),
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
          _buildBackButton(l10n),
          _buildTitle(l10n.myCharacters),
          _buildLanguageToggleButton(),
        ],
      ),
    );
  }

  Widget _buildBackButton(AppLocalizations l10n) {
    return GestureDetector(
      onTap: _goToMainMenu,
      child: Container(
        width: _cornerButtonSize,
        height: _cornerButtonSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.1),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: _cornerShadowColor,
              blurRadius: _cornerShadowBlur,
              spreadRadius: _cornerShadowSpread,
              offset: _cornerShadowOffset,
            ),
          ],
        ),
        child: const Icon(
          Icons.arrow_back,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        shadows: [
          Shadow(
            color: Colors.orange,
            blurRadius: 8,
            offset: Offset(1, 1),
          ),
        ],
      ),
    );
  }

  // ✅ قسم النقاط المحدث مع نظام الدفع الجديد
  Widget _buildPointsSection(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900]!.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 15,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Column(
        children: [
          // ✅ صف عرض النقاط
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.yourCoins,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.orange, Colors.yellow],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Text(
                  '$_userPoints 💎',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ✅ الصف الأول من الأزرار (3 أزرار)
          Row(
            children: [
              // ✅ زر شراء العملات عبر نظام الدفع الجديد
              Expanded(
                child: _buildActionButton(
                  onPressed: _openCoinsPurchaseOptions,
                  backgroundColor: Colors.green,
                  icon: Icons.shopping_cart,
                  text: l10n.buyCoinsNow,
                ),
              ),
              const SizedBox(width: 6),

              // ✅ زر إزالة الإعلانات عبر نظام الدفع الجديد
              Expanded(
                child: _buildActionButton(
                  onPressed: _openAdsRemovalOptions,
                  backgroundColor: Colors.purple,
                  icon: Icons.block,
                  text: l10n.removeAds,
                ),
              ),
              const SizedBox(width: 6),

              // ✅ زر مشاهدة إعلان
              Expanded(
                child: _buildActionButton(
                  onPressed: _watchAdForPoints,
                  backgroundColor: Colors.blue,
                  icon: Icons.play_arrow,
                  text: l10n.watchAd,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ✅ الصف الثاني من الأزرار (زرين)
          Row(
            children: [
              // ✅ زر الذهاب إلى المتجر
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.purple, Colors.deepPurple],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _goToStore,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.store, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          l10n.goToMarketplace,
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
              ),

              const SizedBox(width: 6),

              // ✅ زر الذهاب إلى المراحل
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.teal, Colors.green],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _goToLevels,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.gamepad, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          l10n.levels,
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
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required Color backgroundColor,
    required IconData icon,
    required String text,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        minimumSize: const Size(0, 0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ باقي الكود المعدل (الأقسام الأخرى تبقى كما هي)
  Widget _buildTabSection(AppLocalizations l10n) {
    return Expanded(
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            _buildTabBar(l10n),
            const SizedBox(height: 12),
            _buildTabContent(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[900]!.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TabBar(
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.orange, Colors.deepOrange],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.3),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[400],
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black54,
              blurRadius: 3,
              offset: Offset(1, 1),
            ),
          ],
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        tabs: [
          _buildTabItem(
            icon: Icons.person,
            color: Colors.green[300]!,
            text: '${l10n.ownedCharacters} (${_ownedCharacters.length})',
          ),
          _buildTabItem(
            icon: Icons.shopping_cart,
            color: Colors.orange[300]!,
            text: '${l10n.availableForPurchase} (${_availableCharacters.length})',
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({required IconData icon, required Color color, required String text}) {
    return Tab(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(AppLocalizations l10n) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          color: Colors.grey[900]!.withOpacity(0.6),
        ),
        child: TabBarView(
          children: [
            _buildCharactersGrid(_ownedCharacters, _buildOwnedCharacterCard, l10n),
            _buildCharactersGrid(_availableCharacters, _buildAvailableCharacterCard, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildCharactersGrid(List<GameCharacter> characters, Widget Function(GameCharacter, AppLocalizations) builder, AppLocalizations l10n) {
    if (characters.isEmpty) {
      return _buildEmptyState(
        characters == _ownedCharacters
            ? l10n.noCharactersOwned
            : l10n.allCharactersPurchased,
        l10n.goToMarketplace,
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: characters.length,
      itemBuilder: (context, index) => builder(characters[index], l10n),
    );
  }

  Widget _buildOwnedCharacterCard(GameCharacter character, AppLocalizations l10n) {
    final isSelected = _selectedCharacter?.id == character.id;

    return _buildCharacterCard(
      character: character,
      isLocked: false,
      isSelected: isSelected,
      onTap: () => _selectCharacter(character),
      actionWidget: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Colors.blue,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          isSelected ? l10n.selected : l10n.select,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      topWidget: isSelected ? _buildSelectionBadge() : null,
      l10n: l10n,
    );
  }

  Widget _buildAvailableCharacterCard(GameCharacter character, AppLocalizations l10n) {
    return _buildCharacterCard(
      character: character,
      isLocked: true,
      isSelected: false,
      onTap: () => _showCharacterDetails(character, l10n), // ✅ هذا صحيح - يفتح التفاصيل
      actionWidget: _buildPurchaseButton(character, l10n),
      topWidget: Column(
        children: [
          _buildLockBadge(),
          _buildPriceBadge(character),
        ],
      ),
      l10n: l10n,
    );
  }

  Widget _buildCharacterCard({
    required GameCharacter character,
    required bool isLocked,
    required bool isSelected,
    required VoidCallback onTap,
    required Widget actionWidget,
    required Widget? topWidget,
    required AppLocalizations l10n,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900]!.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLocked ? Colors.grey : (isSelected ? Colors.green : character.color),
            width: isSelected ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: (isLocked ? Colors.grey : (isSelected ? Colors.green : character.color)).withOpacity(0.4),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: isLocked
                    ? _buildLockedCharacter(character)
                    : _buildUnlockedCharacter(character),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildCharacterInfo(character, actionWidget, l10n),
            ),
            if (topWidget != null)
              Positioned(
                top: 8,
                right: 8,
                child: topWidget,
              ),
            if (isLocked)
              Positioned(
                top: 8,
                left: 8,
                child: _buildPurchaseLabel(l10n),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterInfo(GameCharacter character, Widget actionWidget, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(10),
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
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
      ),
      child: Column(
        children: [
          Text(
            character.getName(l10n.locale.languageCode),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: character.isLocked ? Colors.grey : Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          actionWidget,
        ],
      ),
    );
  }

  Widget _buildSelectionBadge() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.green,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.4),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: const Icon(
        Icons.check,
        color: Colors.white,
        size: 16,
      ),
    );
  }

  Widget _buildLockBadge() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.lock,
        color: Colors.white,
        size: 16,
      ),
    );
  }

  Widget _buildPriceBadge(GameCharacter character) {
    return Container(
      margin: const EdgeInsets.only(top: 32),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            character.displayPrice,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 2),
          const Icon(
            Icons.diamond,
            color: Colors.white,
            size: 10,
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseLabel(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.orange, Colors.red],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        l10n.buyNow,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPurchaseButton(GameCharacter character, AppLocalizations l10n) {
    final canPurchase = _userPoints >= character.integerPrice;

    return GestureDetector(
      onTap: () => _showCharacterDetails(character, l10n),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          gradient: canPurchase
              ? const LinearGradient(colors: [Colors.orange, Colors.yellow])
              : LinearGradient(colors: [Colors.grey, Colors.grey[700]!]),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: canPurchase
                  ? Colors.orange.withOpacity(0.4)
                  : Colors.grey.withOpacity(0.3),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.buyNow,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: canPurchase ? Colors.black : Colors.white,
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              Icons.diamond,
              size: 14,
              color: canPurchase ? Colors.blue : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedCharacter(GameCharacter character) {
    return Stack(
      children: [
        // ✅ عرض الصورة الحقيقية مع تأثيرات
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                character.color.withOpacity(0.4),
                character.color.withOpacity(0.2),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Image.asset(
              character.getStoreDisplayImage(),
              width: 60,
              height: 60,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.person,
                  size: 60,
                  color: character.color.withOpacity(0.8),
                );
              },
            ),
          ),
        ),

        // ✅ طبقة شفافة خفيفة فقط
        Container(
          color: Colors.black.withOpacity(0.2),
        ),

        // ✅ أيقونة القفل
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnlockedCharacter(GameCharacter character) {
    return Stack(
      children: [
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
        Center(
          child: Image.asset(
            character.imagePath,
            width: 70,
            height: 70,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.person,
                size: 70,
                color: character.color,
              );
            },
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
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

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: 60,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[400],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _goToStore,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ دالة عرض تفاصيل الشخصية مع خيار الشراء
  void _showCharacterDetails(GameCharacter character, AppLocalizations l10n) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final currentLanguage = languageProvider.isArabic ? 'ar' : 'en';
    final canPurchase = _userPoints >= character.integerPrice;

    // ✅ النصوص حسب اللغة
    final characterTypeText = currentLanguage == 'ar' ? 'النوع' : 'Type';
    final attackInfoText = currentLanguage == 'ar' ? 'معلومات الهجوم' : 'Attack Info';
    final damageText = currentLanguage == 'ar' ? 'الضرر' : 'Damage';
    final speedText = currentLanguage == 'ar' ? 'السرعة' : 'Speed';
    final abilitiesText = currentLanguage == 'ar' ? 'القدرات' : 'Abilities';
    final priceText = currentLanguage == 'ar' ? 'السعر' : 'Price';
    final yourCoinsText = currentLanguage == 'ar' ? 'نقاطك' : 'Your Coins';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
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
                    character.getName(currentLanguage),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 10),

                  // ✅ نوع الشخصية
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: character.color.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      '$characterTypeText: ${character.type}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(height: 15),

                  // ✅ وصف الشخصية
                  Text(
                    character.getDescription(currentLanguage),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 20),

                  // ✅ هجوم الشخصية
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange, width: 1),
                    ),
                    child: Column(
                      children: [
                        Text(
                          attackInfoText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          character.getAttackName(currentLanguage),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          character.getAttackDescription(currentLanguage),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildAttackStat('$damageText: ${character.attackDamage}', Icons.flash_on),
                            _buildAttackStat('$speedText: ${character.attackSpeed}', Icons.speed),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ✅ قدرات الشخصية
                  Text(
                    abilitiesText,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: character.abilities.map((ability) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          ability,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 25),

                  // ✅ معلومات السعر والنقاط المتاحة
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue, width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              priceText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              character.displayPrice,
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              yourCoinsText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '$_userPoints 💎',
                              style: TextStyle(
                                color: canPurchase ? Colors.green : Colors.red,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ✅ زر الشراء
                  ElevatedButton(
                    onPressed: canPurchase
                        ? () {
                      Navigator.of(context).pop();
                      _purchaseCharacter(character);
                    }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canPurchase ? Colors.orange : Colors.grey,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            canPurchase ? l10n.buyNow : l10n.insufficientPoints,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (canPurchase) ...[
                          const SizedBox(width: 8),
                          Text(
                            character.displayPrice,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Icon(Icons.diamond, size: 20, color: Colors.white),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ✅ زر الإغلاق
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      l10n.close,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

// ✅ دالة مساعدة لعرض إحصائيات الهجوم
  Widget _buildAttackStat(String text, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.orange, size: 16),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }


  @override
  void dispose() {
    // ✅ إزالة المستمعين فقط
    _settingsService.removeListener(_onSettingsChanged);
    _paymentService.removeListener(_onPaymentUpdate);
    GameDataService().removeUpdateListener(_onDataUpdated);

    // ✅ إيقاف المتحكمات
    _languageAnimationController.dispose();

    // ✅ تنظيف الذاكرة
    _clearImageCache();

    super.dispose();
  }

// ✅ دالة منفصلة للتنظيف
  void _cleanupResources() {
    // ✅ إزالة المستمعين
    _settingsService.removeListener(_onSettingsChanged);
    _paymentService.removeListener(_onPaymentUpdate);
    GameDataService().removeUpdateListener(_onDataUpdated);

    // ✅ إيقاف المتحكمات
    _languageAnimationController.dispose();

    // ✅ تنظيف الخدمات
    _paymentService.dispose();

    // ✅ تنظيف الذاكرة
    _clearImageCache();
  }
}