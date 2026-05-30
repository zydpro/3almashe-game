import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/Payment_UI_Service.dart';
import '../services/ads_service.dart';
import '../services/game_data_service.dart';
import '../services/payment_service.dart';
import '../services/settings_service.dart';
import '../services/ads_removal_service.dart';
import '../Languages/LanguageProvider.dart';
import '../Languages/localization.dart';
import 'main_menu_screen.dart';
import 'items_screen.dart';
import '../models/character_model.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> with SingleTickerProviderStateMixin {
  late SettingsService _settingsService;
  late AdsRemovalService _adsRemovalService;
  late PaymentService _paymentService;
  late PaymentUIService _paymentUIService;
  late AnimationController _languageAnimationController;
  late Animation<double> _languageScaleAnimation;

  // ✅ إعدادات التصميم المحسنة
  final double _cornerShadowBlur = 10.0;
  final double _cornerShadowSpread = 2.0;
  final Color _cornerShadowColor = Colors.black.withOpacity(0.5);
  final Offset _cornerShadowOffset = const Offset(2, 2);
  final double _cornerIconSize = 50.0;
  final double _cornerButtonSize = 60.0;

  // ✅ حالة التطبيق المحسنة
  List<GameCharacter> _characters = [];
  int _userPoints = 1000;
  GameCharacter? _selectedCharacter;
  bool _isLoading = true;
  String _errorMessage = '';

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

    // ✅ تهيئة الخدمات بالترتيب الصحيح
    _initializeAllServices();

    _initLanguageAnimation();
    _loadData();

    // ✅ تهيئة نظام الدفع
    _initializePayment();
    // ✅ تسجيل استجابة لتحديثات البيانات
    GameDataService().addUpdateListener(_onDataUpdated);
  }

  Future<void> _initializeAllServices() async {
    try {
      print('🔄 Starting all services initialization...');

      // ✅ تهيئة خدمة الإعلانات أولاً
      await _adsRemovalService.initialize();

      // ✅ تهيئة نظام الدفع
      await _paymentService.initialize();

      // ✅ تحميل البيانات
      await _loadData();

      // ✅ اختيار المنتجات بعد التهيئة
      _testProducts();

      print('✅ All services initialized successfully');

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
    print('🔄 StoreScreen - تم استلام تحديث البيانات');
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

  // ✅ دالة تحميل البيانات المحسنة
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final coins = await GameDataService.getUserCoins();
      final allCharacters = await GameDataService.getAllCharactersWithLockStatus();
      final selected = await GameDataService.getSelectedCharacter();

      // ✅ عرض الشخصيات غير المملوكة فقط في المتجر
      final availableCharacters = allCharacters.where((char) => char.isLocked).toList();

      print('🔄 StoreScreen - النقاط: $coins, الشخصيات المتاحة: ${availableCharacters.length}');

      setState(() {
        _userPoints = coins;
        _characters = availableCharacters;
        _selectedCharacter = selected;
        _isLoading = false;
      });

    } catch (e) {
      print('❌ خطأ في StoreScreen._loadData: $e');
      _handleLoadError();
    }
  }

  void _handleLoadError() {
    setState(() {
      _characters = [];
      _selectedCharacter = GameCharacter.getDefaultCharacter();
      _isLoading = false;
      _errorMessage = AppLocalizations.of(context).characterLoadError;
    });
  }

  @override
  void dispose() {
    _settingsService.removeListener(_onSettingsChanged);
    _adsRemovalService.removeListener(_onAdsSettingsChanged);
    _paymentService.removeListener(_onPaymentUpdate);
    _languageAnimationController.dispose();
    GameDataService().removeUpdateListener(_onDataUpdated);
    super.dispose();
  }

  void _onSettingsChanged() => setState(() {});

  void _onAdsSettingsChanged() => setState(() {});

  // ✅ فتح خيارات شراء العملات
  void _openCoinsPurchaseOptions() async {
    final l10n = AppLocalizations.of(context);

    // ✅ التحقق من التهيئة أولاً
    if (!_paymentService.isInitialized) {
      print('🔄 Payment not initialized, initializing now...');
      await _paymentService.initialize();
    }

    // ✅ إعادة تحميل المنتجات إذا لزم الأمر
    if (_paymentService.products.isEmpty) {
      await _paymentUIService.reloadProducts();
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _buildCoinsPurchaseDialog(l10n);
      },
    );
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

  // ✅ تحديث دالة بناء خيارات شراء العملات
  Widget _buildCoinsPurchaseDialog(AppLocalizations l10n) {
    return Dialog(
      backgroundColor: Colors.grey[900]!.withOpacity(0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Colors.blue, width: 2),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.buyCoins,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // ✅ حالة نظام الدفع - استخدام الخدمة الجديدة
              _paymentUIService.buildPaymentStatus(l10n, onRetry: _initializePayment),

              const SizedBox(height: 20),

              // ✅ خيارات شراء العملات - استخدام الخدمة الجديدة
              ..._paymentUIService.buildAllCoinsOptions(l10n, _purchaseCoins),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[700],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    l10n.close,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ فتح خيارات إزالة الإعلانات
  void _openAdsRemovalOptions() {
    final l10n = AppLocalizations.of(context);

    // ✅ إعادة تحميل المنتجات إذا لزم الأمر
    if (!_paymentService.isInitialized || _paymentService.products.isEmpty) {
      _paymentUIService.reloadProducts();
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _buildAdsRemovalDialog(l10n);
      },
    );
  }

  // ✅ تحديث دالة بناء خيارات إزالة الإعلانات
  Widget _buildAdsRemovalDialog(AppLocalizations l10n) {
    return Dialog(
      backgroundColor: Colors.grey[900]!.withOpacity(0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF048A81), width: 2),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.adsRemoval,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // ✅ حالة الإعلانات الحالية
              _buildCurrentAdsStatus(l10n),

              const SizedBox(height: 16),

              // ✅ حالة نظام الدفع - استخدام الخدمة الجديدة
              _paymentUIService.buildPaymentStatus(l10n, onRetry: _initializePayment),

              const SizedBox(height: 20),

              // ✅ خيارات إزالة الإعلانات - استخدام الخدمة الجديدة
              if (!_adsRemovalService.isActive) ...[
                ..._paymentUIService.buildAllAdsRemovalOptions(l10n, _purchaseAdsRemoval),
                const SizedBox(height: 16),

                // خيار الإزالة المؤقتة عبر مشاهدة إعلان
                _buildTemporaryRemovalOption(l10n),
              ],

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[700],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    l10n.close,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ خيار الإزالة المؤقتة
  Widget _buildTemporaryRemovalOption(AppLocalizations l10n) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showTemporaryRemovalConfirmation(l10n),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue, width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.play_circle,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l10n.watchAdToRemove} 30 ${l10n.minutes}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.removeAdsTemporarily,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.blue,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ دوال معالجة الشراء
  void _purchaseCoins(String productId) {
    _paymentService.purchaseProduct(productId);
  }

  void _purchaseAdsRemoval(String productId) {
    _paymentService.purchaseProduct(productId);
  }

  void _showTemporaryRemovalConfirmation(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900]!.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.blue, width: 2),
          ),
          title: Text(
            l10n.removeAdsTemporarily,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.play_circle, size: 60, color: Colors.blue),
              const SizedBox(height: 16),
              Text(
                '${l10n.watchAdToRemove} 30 ${l10n.minutes}',
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.removeAdsTemporarily,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
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
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _processTemporaryRemoval(l10n);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
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
        );
      },
    );
  }

  void _processTemporaryRemoval(AppLocalizations l10n) async {
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
            ],
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
          final removalSuccess = await _adsRemovalService.removeAdsTemporarily(const Duration(minutes: 30));
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
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.red, width: 2),
          ),
          title: Text(
            l10n.adFailed,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                l10n.adFailedMessage,
                style: const TextStyle(color: Colors.white),
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
                child: Text(l10n.close),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPurchaseSuccess(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900]!.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.green, width: 2),
          ),
          title: Text(
            l10n.purchaseSuccessful,
            style: const TextStyle(color: Colors.green),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, size: 60, color: Colors.green),
              const SizedBox(height: 16),
              Text(
                l10n.purchaseSuccessMessage,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: Text(l10n.close),
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
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.blue, width: 2),
          ),
          title: Text(
            l10n.purchaseSuccessful,
            style: const TextStyle(color: Colors.blue),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, size: 60, color: Colors.blue),
              const SizedBox(height: 16),
              Text(
                '${l10n.purchaseSuccessMessage}\n\n${l10n.remainingTime}: 30 ${l10n.minutes}',
                style: const TextStyle(color: Colors.white),
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
                child: Text(l10n.close),
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
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.red, width: 2),
          ),
          title: Text(
            l10n.purchaseFailed,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                l10n.purchaseErrorMessage,
                style: const TextStyle(color: Colors.white),
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
                child: Text(l10n.close),
              ),
            ),
          ],
        );
      },
    );
  }

  // ✅ حالة الإعلانات الحالية للدايالوج
  Widget _buildCurrentAdsStatus(AppLocalizations l10n) {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (_adsRemovalService.isActive) {
      statusText = _adsRemovalService.isTemporary ? l10n.removeAdsTemporarily : l10n.adsDisabled;
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;

      if (_adsRemovalService.expiryDate != null) {
        bool isArabic = l10n.locale.languageCode == 'ar';
        statusText += ' (${_adsRemovalService.getRemainingTime(isArabic: isArabic)})';
      } else if (!_adsRemovalService.isTemporary) {
        statusText += ' (${l10n.lifetime})';
      }
    } else {
      statusText = l10n.adsEnabled;
      statusColor = Colors.orange;
      statusIcon = Icons.ad_units;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusColor, width: 1),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 16,
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

  // ✅ دالة شراء الشخصية
  Future<void> _purchaseCharacter(GameCharacter character) async {
    final l10n = AppLocalizations.of(context);

    final currentCoins = await GameDataService.getUserCoins();
    if (currentCoins < character.integerPrice) {
      _showSnackBar(l10n.insufficientPoints, Colors.red);
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
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            l10n.confirmPurchase,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 24),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                character.imagePath,
                width: 80,
                height: 80,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.person, size: 80, color: character.color),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.purchaseConfirmation(character.name, character.integerPrice),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel, style: const TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final success = await GameDataService.purchaseCharacter(character);

                if (success) {
                  _showSnackBar(l10n.purchaseSuccess(character.name), Colors.green);
                  await _loadData();
                } else {
                  _showSnackBar(l10n.purchaseFailed, Colors.red);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text(l10n.confirm, style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // ✅ دالة عرض الإشعارات
  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
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
                l10n.watchAdForCoins,
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
  }

  // ✅ زر تبديل اللغة المحسن
  Widget _buildLanguageToggleButton() {
    return GestureDetector(
      onTap: () {
        final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
        _toggleLanguage(languageProvider);
      },
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
                fontSize: 14,
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

  // ✅ الانتقال إلى شاشة الشخصيات
  void _goToCharacters() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const itemsScreen()),
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
            if (_isLoading) _buildLoadingState(l10n),
            if (_errorMessage.isNotEmpty) _buildErrorState(l10n),
            if (!_isLoading && _errorMessage.isEmpty)
              Expanded(child: _buildCharactersGrid(l10n)),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(AppLocalizations l10n) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Colors.orange,
              strokeWidth: 4,
            ),
            const SizedBox(height: 20),
            Text(
              l10n.loadingCharacters,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(AppLocalizations l10n) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                l10n.retry,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
          GestureDetector(
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const MainMenuScreen()),
                    (route) => false,
              );
            },
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
                size: 30,
              ),
            ),
          ),

          Flexible(
            child: Text(
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
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          _buildLanguageToggleButton(),
        ],
      ),
    );
  }

  // ✅ تحديث قسم النقاط لاستخدام الخدمة الجديدة
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  l10n.yourCoins,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                  '$_userPoints 💎',
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

          // ✅ سطر واحد يحتوي على 3 أزرار متساوية الحجم
          Row(
            children: [
              // ✅ زر شراء العملات - استخدام الدالة المحدثة
              Expanded(
                child: ElevatedButton(
                  onPressed: _openCoinsPurchaseOptions, // ✅ تم التحديث
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_cart, color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          l10n.buyCoins,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // ✅ زر إزالة الإعلانات - استخدام الدالة المحدثة
              Expanded(
                child: ElevatedButton(
                  onPressed: _openAdsRemovalOptions, // ✅ تم التحديث
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.block, color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          l10n.removeAds,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // ✅ زر مشاهدة إعلان
              Expanded(
                child: ElevatedButton(
                  onPressed: _watchAdForPoints,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_arrow, color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          l10n.watchAd,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.purple, Colors.deepPurple],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _goToCharacters,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      l10n.goToCharacters,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 4,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharactersGrid(AppLocalizations l10n) {
    if (_characters.isEmpty) {
      return _buildEmptyCharactersState(l10n);
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: _characters.length,
      itemBuilder: (context, index) {
        return _buildCharacterCard(_characters[index], l10n);
      },
    );
  }

  Widget _buildEmptyCharactersState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off,
            size: 80,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.allCharactersPurchased,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[400],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.noCharactersAvailable,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _goToCharacters,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              l10n.goToMarketplace,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterCard(GameCharacter character, AppLocalizations l10n) {
    return GestureDetector(
      onTap: () => _showCharacterDetails(character, l10n),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900]!.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: character.color,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: character.color.withOpacity(0.5),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child: _buildLockedCharacter(character), // ✅ الآن تظهر الصورة
              ),
            ),

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
                      character.getName(l10n.locale.languageCode),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    _buildPurchaseButton(character, l10n),
                  ],
                ),
              ),
            ),

            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      character.displayPrice,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.diamond,
                      color: Colors.white,
                      size: 12,
                    ),
                  ],
                ),
              ),
            ),

            // ✅ إضافة شارة "جديد" أو "مميز" لجعل العرض أكثر جاذبية
            if (character.price > 2000) // الشخصيات غالية الثمن
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.purple,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'مميز',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedCharacter(GameCharacter character) {
    return Stack(
      children: [
        // ✅ عرض الصورة الحقيقية للشخصية
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
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  character.getStoreDisplayImage(), // ✅ الصورة الحقيقية
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.person,
                      size: 80,
                      color: character.color.withOpacity(0.7),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        // ✅ طبقة شفافة للإشارة إلى حالة القفل
        Container(
          color: Colors.black.withOpacity(0.3), // ✅ شفافية منخفضة
        ),

        // ✅ أيقونة القفل في المنتصف
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.lock,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPurchaseButton(GameCharacter character, AppLocalizations l10n) {
    final canPurchase = _userPoints >= character.integerPrice;

    return GestureDetector(
      onTap: () => _purchaseCharacter(character),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          gradient: canPurchase
              ? const LinearGradient(
            colors: [Colors.orange, Colors.yellow],
          )
              : LinearGradient(
            colors: [Colors.grey, Colors.grey[700]!],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: canPurchase
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
            Flexible(
              child: Text(
                l10n.buyNow,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: canPurchase ? Colors.black : Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.diamond,
              size: 16,
              color: canPurchase ? Colors.blue : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  void _showCharacterDetails(GameCharacter character, AppLocalizations l10n) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final currentLanguage = languageProvider.isArabic ? 'ar' : 'en';

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

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: character.color.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      '${l10n.characterType}: ${character.type}',
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

                  Text(
                    l10n.characterAbilities,
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

                  ElevatedButton(
                    onPressed: () {
                      _purchaseCharacter(character);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _userPoints >= character.integerPrice ? Colors.orange : Colors.grey,
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
                            l10n.buyNow,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
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
                    ),
                  ),

                  const SizedBox(height: 10),

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
}