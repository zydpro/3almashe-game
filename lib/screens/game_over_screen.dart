import 'package:almashe_game/screens/items_Screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Languages/LanguageProvider.dart';
import '../game/game_engine.dart';
import '../services/ads_service.dart';
import '../services/ads_removal_service.dart';
import '../services/game_data_service.dart';
import '../services/payment_service.dart';
import 'game_screen.dart';
import 'main_menu_screen.dart';
import 'levels_screen.dart';
import '../models/level_data.dart';
import '../Languages/localization.dart';

class GameOverScreen extends StatefulWidget {
  final int score;
  final int level;
  final LevelData? levelData;
  final int timeSpent;
  final GameEngine? gameEngine;

  const GameOverScreen({
    super.key,
    required this.score,
    this.level = 1,
    this.levelData,
    required this.timeSpent,
    this.gameEngine,
  });

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen> {
  bool _canContinue = false;
  int _remainingContinues = 0;
  bool _isContinuing = false;
  int _actualTimeSpent = 0;

  // ✅ إضافة PaymentService
  late PaymentService _paymentService;
  late AdsRemovalService _adsRemovalService;

  @override
  void initState() {
    super.initState();

    // ✅ تهيئة خدمات الدفع والإعلانات
    _paymentService = PaymentService();
    _adsRemovalService = AdsRemovalService();

    _paymentService.addListener(_onPaymentUpdate);
    _adsRemovalService.addListener(_onAdsSettingsChanged);

    _initializePaymentSystem();

    // ✅ جرب هذا الإصدار المبسط أولاً
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAdsService();
      // _checkContinueAvailability();

      // ✅ طباعة معلومات التصحيح
      print('🎮 GameOverScreen - gameEngine: ${widget.gameEngine != null}');
      if (widget.gameEngine != null) {
        // print('🔄 يمكن الاستمرار: ${widget.gameEngine!.canContinue}');
        // print('📊 المحاولات المتبقية: ${widget.gameEngine!.remainingContinues}');
      }
    });

    _calculateActualTime();
  }

  Future<void> _initializePaymentSystem() async {
    await _paymentService.initialize();
  }

  void _calculateActualTime() {
    // إذا كان الوقت صفراً، استخدم وقت محاكاة واقعي
    if (widget.timeSpent <= 0) {
      _actualTimeSpent = 120 + widget.score ~/ 10; // وقت واقعي بناءً على النقاط
    } else {
      _actualTimeSpent = widget.timeSpent;
    }
    // print('⏰ الوقت الفعلي: $_actualTimeSpent ثانية');
  }

  void _initializeAdsService() {
    final adsService = Provider.of<AdsRemovalService>(context, listen: false);
    adsService.addListener(_onAdsSettingsChanged);
  }

  // void _checkContinueAvailability() {
  //   if (widget.gameEngine != null) {
  //     setState(() {
  //       _canContinue = widget.gameEngine!.canContinue;
  //       _remainingContinues = widget.gameEngine!.remainingContinues;
  //     });
  //   }
  // }

  void _onPaymentUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onAdsSettingsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    bool levelCompleted = widget.levelData != null && widget.score >= widget.levelData!.targetScore;
    bool nextLevelUnlocked = levelCompleted && widget.levelData!.levelNumber < 100;
    int coinsEarned = widget.score ~/ 10;

    _saveGameProgress();

    return Scaffold(
      backgroundColor: Colors.black54,
      body: SafeArea(
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: const BoxConstraints(
              maxWidth: 400,
            ),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[900]!.withOpacity(0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: levelCompleted ? Colors.green : Colors.red,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✅ الهيدر مع زر اللغة وزر الإعلانات - التعديل: العنوان أصبح "Game Over"
                _buildHeader(context, l10n),

                const SizedBox(height: 20),

                // محتوى النتيجة
                _buildContentSection(context, l10n, levelCompleted, widget.score, coinsEarned, widget.levelData),

                const SizedBox(height: 30),

                // أزرار الإجراءات
                _buildActionButtons(l10n, levelCompleted, nextLevelUnlocked, context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ الهيدر مع زر اللغة وزر الإعلانات - التعديل: العنوان أصبح "Game Over"
  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ✅ زر الإعلانات على اليسار
          SizedBox(
            width: 60,
            height: 60,
            child: _buildAdsToggleButton(context, l10n),
          ),

          const SizedBox(width: 20),

          // ✅ العنوان في المنتصف - التعديل: أصبح "Game Over"
          Expanded(
            child: Text(
              l10n.gameOver, // ✅ تغيير من levelComplete إلى gameOver
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28, // ✅ زيادة حجم الخط
                fontWeight: FontWeight.bold,
                color: Colors.red, // ✅ تغيير اللون إلى الأحمر
                shadows: [
                  Shadow(
                    color: Colors.black, // ✅ تغيير الظل إلى الأسود
                    blurRadius: 10,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 20),

          // ✅ زر اللغة على اليمين
          SizedBox(
            width: 60,
            height: 60,
            child: _buildLanguageToggleButton(context),
          ),
        ],
      ),
    );
  }

  // ✅ زر تبديل الإعلانات
  Widget _buildAdsToggleButton(BuildContext context, AppLocalizations l10n) {
    return GestureDetector(
      onTap: () => _openAdsRemovalOptions(),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.01),
          border: Border.all(
            color: Colors.white.withOpacity(0.01),
            width: 0.1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Center(
          child: _buildAdsIcon(l10n),
        ),
      ),
    );
  }

  // ✅ أيقونة الإعلانات
  Widget _buildAdsIcon(AppLocalizations l10n) {
    // إذا كانت الإعلانات معطلة
    if (_adsRemovalService.isActive) {
      return Stack(
        children: [
          // أيقونة الإعلان المعطل من assets - بنفس حجم أيقونة اللغة
          Image.asset(
            'assets/images/ui/adsStop.png',
            width: 50,
            height: 50,
            fit: BoxFit.contain,
          ),
          // علامة صح خضراء
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: const Icon(
                Icons.check,
                size: 12,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    } else {
      // إذا كانت الإعلانات مفعلة
      return Stack(
        children: [
          // أيقونة الإعلان العادية من assets - بنفس حجم أيقونة اللغة
          Image.asset(
            'assets/images/ui/adsStop.png',
            width: 50,
            height: 50,
            fit: BoxFit.contain,
          ),
          // علامة تنبيه حمراء
          Positioned(
            top: 2,
            right: 2,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: const Icon(
                Icons.warning,
                size: 12,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    }
  }

  // ✅ فتح خيارات إزالة الإعلانات
  void _openAdsRemovalOptions() {
    final l10n = AppLocalizations.of(context);

    // ✅ إذا كانت الإعلانات معطلة بالفعل، اعرض حالة الإعلانات
    if (_adsRemovalService.isActive) {
      _showCurrentAdsStatus(l10n);
      return;
    }

    // ✅ إذا كانت الإعلانات مفعلة، اعرض خيارات الإزالة
    _showAdsRemovalOptions(l10n);
  }

  // ✅ عرض خيارات إزالة الإعلانات
  void _showAdsRemovalOptions(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
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

                  const SizedBox(height: 5),
                  _buildCurrentAdsStatus(l10n),

                  // ✅ إضافة حالة نظام الدفع
                  _buildPaymentStatus(l10n),

                  const SizedBox(height: 5),

                  _buildAdsPurchaseOption('remove_ads_1day', l10n),
                  const SizedBox(height: 5),
                  _buildAdsPurchaseOption('remove_ads_1week', l10n),
                  const SizedBox(height: 5),
                  _buildAdsPurchaseOption('remove_ads_1month', l10n),
                  const SizedBox(height: 5),
                  _buildAdsPurchaseOption('remove_ads_1year', l10n),
                  const SizedBox(height: 5),
                  _buildAdsPurchaseOption('remove_ads_lifetime', l10n),

                  const SizedBox(height: 5),
                  // خيار الإزالة المؤقتة عبر مشاهدة إعلان
                  _buildTemporaryRemovalOption(l10n),

                  const SizedBox(height: 5),

                  // زر الإغلاق
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
      },
    );
  }

  // ✅ حالة نظام الدفع
  Widget _buildPaymentStatus(AppLocalizations l10n) {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (_paymentService.isLoading) {
      statusText = l10n.loading;
      statusColor = Colors.orange;
      statusIcon = Icons.hourglass_bottom;
    } else if (_paymentService.errorMessage != null) {
      statusText = _paymentService.errorMessage!;
      statusColor = Colors.red;
      statusIcon = Icons.error;
    } else if (!_paymentService.isAvailable) {
      statusText = l10n.paymentNotAvailable;
      statusColor = Colors.red;
      statusIcon = Icons.error;
    } else {
      statusText = l10n.paymentReady;
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
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
          const SizedBox(width: 12),
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

  // ✅ خيار شراء إزالة الإعلانات باستخدام PaymentService
  Widget _buildAdsPurchaseOption(String productId, AppLocalizations l10n) {
    final product = _paymentService.getProductById(productId);
    if (product == null) return const SizedBox();

    Color color;
    switch (productId) {
      case 'remove_ads_1day': color = Colors.blue;
      case 'remove_ads_1week': color = Colors.green;
      case 'remove_ads_1month': color = Colors.orange;
      case 'remove_ads_1year': color = Colors.red;
      case 'remove_ads_lifetime': color = Colors.purple;
      default: color = Colors.grey;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _purchaseAdsRemoval(productId),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color, width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.block, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _paymentService.getProductName(productId, l10n.locale.languageCode),
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
                      _paymentService.getProductDescription(productId, l10n.locale.languageCode),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                product.price,
                style: TextStyle(
                  fontSize: 18,
                  color: color,
                  fontWeight: FontWeight.bold,
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
                child: const Icon(Icons.play_circle, color: Colors.blue, size: 24),
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
                    ),
                    Text(
                      l10n.removeAdsTemporarily,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.blue, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ حالة الإعلانات الحالية
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
            ),
          ),
        ],
      ),
    );
  }

  // ✅ دوال معالجة الشراء
  void _purchaseAdsRemoval(String productId) async {
    await _paymentService.purchaseProduct(productId);
  }

  void _showTemporaryRemovalConfirmation(AppLocalizations l10n) {
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
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.cancel, style: const TextStyle(fontSize: 14)),
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
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: Text(l10n.watchAd, style: const TextStyle(fontSize: 14)),
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
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.red, width: 2),
          ),
          title: Text(
            l10n.adError,
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                ),
                child: Text(l10n.close, style: const TextStyle(fontSize: 14)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCurrentAdsStatus(AppLocalizations l10n) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    bool isArabic = languageProvider.isArabic;

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
            l10n.adsStatus,
            style: const TextStyle(
              color: Colors.green,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, size: 60, color: Colors.green),
              const SizedBox(height: 16),
              _buildCurrentAdsStatus(l10n),
              const SizedBox(height: 16),
              Text(
                l10n.noAdsEnjoy,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: Text(l10n.close),
              ),
            ),
          ],
        );
      },
    );
  }

  // باقي الدوال الموجودة سابقاً (بدون تغيير)
  Widget _buildLanguageToggleButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
        languageProvider.toggleLanguage();
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.01),
          border: Border.all(
            color: Colors.white.withOpacity(0.01),
            width: 0.1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(2, 2),
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
      width: 50,
      height: 50,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF012169), Color(0xFFC8102E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
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
      width: 50,
      height: 50,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF006233),
            borderRadius: BorderRadius.circular(25),
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

Widget _buildContentSection(BuildContext context, AppLocalizations l10n, bool levelCompleted, int score, int coinsEarned, LevelData? levelData) {
  return Container(
    width: double.infinity,
    constraints: BoxConstraints(
      maxWidth: MediaQuery.of(context).size.width * 0.8,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          levelCompleted ? Icons.celebration : Icons.sentiment_dissatisfied,
          size: 80,
          color: levelCompleted ? Colors.green : Colors.red,
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Text(
                '${l10n.score}: $score',
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.yellow,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              if (levelData != null) ...[
                Text(
                  '${levelData.getName(l10n)} - ${l10n.target}: ${levelData.targetScore}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
              ],
              if (levelCompleted) ...[
                Text(
                  l10n.gameOverLevelCompleted,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.lightGreen,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
              ],
              Text(
                '${l10n.gameOverCoinsEarned}: $coinsEarned',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              // ✅ التعديل: إظهار الوقت الفعلي (لم يتم إخفاؤه)
              Text(
                '${l10n.timeSpent}: ${_formatTime(_actualTimeSpent)}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ],
    ),
  );
}

String _formatTime(int seconds) {
  final minutes = seconds ~/ 60;
  final remainingSeconds = seconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
}

Widget _buildActionButtons(AppLocalizations l10n, bool levelCompleted, bool nextLevelUnlocked, BuildContext context) {
  // ✅ إنشاء قائمة الـ widgets أولاً
  List<Widget> actionButtons = [];

  // ❌ زر الاستمرار معطل حالياً
  // if (!levelCompleted) {
  //   actionButtons.addAll([
  //     _buildOptionButton(...),
  //     const SizedBox(height: 5),
  //   ]);
  // }

  if (nextLevelUnlocked) {
    actionButtons.addAll([
      _buildOptionButton(
        icon: Icons.arrow_forward,
        text: l10n.nextLevel,
        description: l10n.gameOverNextLevelDesc,
        onTap: () => _showAdAndGoToNextLevel(context),
        color: Colors.blue,
        isEnabled: true,
      ),
      const SizedBox(height: 8),
    ]);
  }

  actionButtons.addAll([
    _buildOptionButton(
      icon: Icons.refresh,
      text: l10n.restartLevel,
      description: l10n.gameOverRestartDesc,
      onTap: () => _showAdAndRestartLevel(context),
      color: Colors.orange,
      isEnabled: true,
    ),
    const SizedBox(height: 8),

    _buildOptionButton(
      icon: Icons.directions_run,
      text: l10n.choseCharacter,
      description: l10n.choseAnotherCharacter,
      onTap: () => _showAdAndGoToItemsScreen(context),
      color: Colors.purple,
      isEnabled: true,
    ),
    const SizedBox(height: 8),

    _buildOptionButton(
      icon: Icons.home,
      text: l10n.mainMenu,
      description: l10n.gameOverMainMenuDesc,
      onTap: () => _showAdAndGoToMainMenu(context),
      color: Colors.grey,
      isEnabled: true,
    ),
  ]);

  // ✅ استخدام SingleChildScrollView + Column لمنع الفيضان على الشاشات الصغيرة
  return Flexible(
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: actionButtons,
      ),
    ),
  );
}

Widget _buildOptionButton({
  required IconData icon,
  required String text,
  required String description,
  required VoidCallback onTap,
  required Color color,
  required bool isEnabled,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(15),
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.5,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // ✅ تقليل الحشو الرأسي
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: color, width: 2),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 28), // ✅ تقليل حجم الأيقونة قليلاً
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center, // ✅ توسيط المحتوى
                  children: [
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: 16, // ✅ تقليل حجم الخط
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                      softWrap: true, // ✅ السماح بالتفاف النص
                      overflow: TextOverflow.ellipsis, // إظهار "..." إذا لزم الأمر
                    ),
                    const SizedBox(height: 2), // ✅ تقليل المسافة
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 11, // ✅ تقليل حجم الخط
                        color: Colors.white70,
                      ),
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!isEnabled)
                const Icon(Icons.lock, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    ),
  );
}

void _saveGameProgress() {
  if (widget.levelData != null) {
    GameDataService.saveGameProgress(widget.score, widget.levelData!.levelNumber);
  }
}

void _showAdAndContinue(BuildContext context) {
  _showLoadingDialog(context, AppLocalizations.of(context).loadingAd);

  AdsService.showRewardedAd(
    onAdStarted: () {
      Navigator.pop(context);
      _showAdPlayingDialog(context, AppLocalizations.of(context).gameOverAdTitle, AppLocalizations.of(context).gameOverAdDesc);
    },
    onAdCompleted: () {
      Navigator.pop(context);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => GameScreen(levelData: widget.levelData),
        ),
      );
    },
    onAdFailed: (error) {
      Navigator.pop(context);
      _showAdErrorSnackBar(context, error);
    },
  );
}

void _showAdAndContinueFromDeath(BuildContext context) {
  if (_isContinuing || !_canContinue) {
    print('❌ لا يمكن الاستمرار: isContinuing=$_isContinuing, canContinue=$_canContinue');
    return;
  }

  setState(() {
    _isContinuing = true;
  });

  print('🎬 بدء الإعلان للاستمرار');

  _showLoadingDialog(context, AppLocalizations.of(context).loadingAd);

  AdsService.showRewardedAd(
    onAdStarted: () {
      print('📺 بدء عرض الإعلان');
      if (Navigator.canPop(context)) Navigator.pop(context);
    },
    onAdCompleted: () {
      print('✅ اكتمل الإعلان بنجاح');
      // _handleAdCompleted();
    },
    onAdFailed: (error) {
      print('❌ فشل الإعلان: $error');
      if (Navigator.canPop(context)) Navigator.pop(context);
      setState(() {
        _isContinuing = false;
      });
      _showAdErrorSnackBar(context, error);
    },
  );
}

// void _handleAdCompleted() {
//   // 1. استدعاء دالة الاستمرار في محرك اللعبة
//   if (widget.gameEngine != null && widget.gameEngine!.canContinue) {
//     print('🔄 استدعاء continueGame من game_over_screen');
//     widget.gameEngine!.continueGame();
//   } else {
//     print('⚠️ لا يمكن الاستمرار، سيتم إعادة تشغيل المستوى');
//     _restartLevel(context);
//     return;
//   }
//
//   // 2. إغلاق شاشة GameOverScreen
//   if (Navigator.canPop(context)) {
//     print('🔙 إغلاق شاشة Game Over والعودة للعبة');
//     Navigator.of(context).pop();
//   }
// }

void _showAdAndGoToNextLevel(BuildContext context) async {
  if (widget.levelData != null && widget.levelData!.levelNumber < 100) {
    try {
      LevelData nextLevel = await LevelData.getLevelData(widget.levelData!.levelNumber + 1);
      _showAdAndStartNextLevel(context, nextLevel);
    } catch (e) {
      _showErrorDialog(context, AppLocalizations.of(context).gameOverLoadError);
    }
  } else {
    _showCompletionDialog(context);
  }
}

void _showAdAndStartNextLevel(BuildContext context, LevelData nextLevel) {
  _showLoadingDialog(context, AppLocalizations.of(context).loadingAd);

  AdsService.showInterstitialAd(
    onAdStarted: () => Navigator.pop(context),
    onAdCompleted: () => _navigateToLevel(context, nextLevel),
    onAdFailed: (error) => _navigateToLevel(context, nextLevel),
  );
}

void _showAdAndRestartLevel(BuildContext context) {
  _showLoadingDialog(context, AppLocalizations.of(context).loadingAd);

  AdsService.showInterstitialAd(
    onAdStarted: () => Navigator.pop(context),
    onAdCompleted: () => _restartLevel(context),
    onAdFailed: (error) => _restartLevel(context),
  );
}

void _showAdAndGoToItemsScreen(BuildContext context) {
  _showLoadingDialog(context, AppLocalizations.of(context).loadingAd);

  AdsService.showInterstitialAd(
    onAdStarted: () => Navigator.pop(context),
    onAdCompleted: () => _goToitemsScreen(context),
    onAdFailed: (error) => _goToitemsScreen(context),
  );
}

void _showAdAndGoToMainMenu(BuildContext context) {
  _showLoadingDialog(context, AppLocalizations.of(context).loadingAd);

  AdsService.showInterstitialAd(
    onAdStarted: () => Navigator.pop(context),
    onAdCompleted: () => _goToMainMenu(context),
    onAdFailed: (error) => _goToMainMenu(context),
  );
}

// الدوال المساعدة
void _showLoadingDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(message),
          ],
        ),
      );
    },
  );
}

void _showAdPlayingDialog(BuildContext context, String title, String description) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.video_library, size: 60, color: Colors.blue),
            const SizedBox(height: 10),
            Text(AppLocalizations.of(context).adPlaying),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    },
  );
}

void _showAdErrorSnackBar(BuildContext context, String error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('${AppLocalizations.of(context).adError}: $error'),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 3),
      action: SnackBarAction(
        label: AppLocalizations.of(context).retry,
        textColor: Colors.white,
        onPressed: () {},
      ),
    ),
  );
}

void _navigateToLevel(BuildContext context, LevelData nextLevel) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => GameScreen(levelData: nextLevel),
    ),
  );
}

void _restartLevel(BuildContext context) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => GameScreen(levelData: widget.levelData),
    ),
  );
}

void _goToitemsScreen(BuildContext context) {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (context) => const itemsScreen()),
        (route) => false,
  );
}

void _goToMainMenu(BuildContext context) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => const MainMenuScreen()),
  );
}

void _showCompletionDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context);

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('🎉 ${l10n.gameOverCongratulations}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.celebration, size: 60, color: Colors.amber),
            const SizedBox(height: 15),
            Text(
              l10n.gameOverAllLevelsCompleted,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.gameOverChampion,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.green,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.gameOverAwesome),
          ),
        ],
      );
    },
  );
}

void _showErrorDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 10),
            Text(AppLocalizations.of(context).error),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context).close),
          ),
        ],
      );
    },
  );
}

@override
void dispose() {
  _paymentService.removeListener(_onPaymentUpdate);
  _adsRemovalService.removeListener(_onAdsSettingsChanged);
  super.dispose();
}
}