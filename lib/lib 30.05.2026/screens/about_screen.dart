// about_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Languages/localization.dart';
import '../Languages/LanguageProvider.dart';
import '../services/Payment_UI_Service.dart';
import '../services/ads_removal_service.dart';
import '../services/ads_service.dart';
import '../services/payment_service.dart';

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

  // ✅ حالة فتح/إغلاق قسم إزالة الإعلانات
  bool _isAdsRemovalExpanded = false;

  // ✅ خدمات الدفع والإعلانات
  late PaymentService _paymentService;
  late AdsRemovalService _adsRemovalService;
  late PaymentUIService _paymentUIService;

  @override
  void initState() {
    super.initState();
    _paymentService = PaymentService();
    _paymentUIService = PaymentUIService();
    _adsRemovalService = AdsRemovalService();

    _paymentService.addListener(_onPaymentUpdate);
    _adsRemovalService.addListener(_onAdsSettingsChanged);

    // ✅ تهيئة نظام الدفع
    _initializePayment();
  }

  // ✅ تعريف دالة التهيئة المفقودة
  Future<void> _initializePayment() async {
    try {
      await _paymentService.initialize();
      await _paymentUIService.reloadProducts();
      if (mounted) setState(() {});
    } catch (e) {
      print('❌ فشل في تهيئة نظام الدفع: $e');
    }
  }


  @override
  void dispose() {
    _paymentService.removeListener(_onPaymentUpdate);
    _adsRemovalService.removeListener(_onAdsSettingsChanged);
    super.dispose();
  }

  void _onPaymentUpdate() {
    if (mounted) setState(() {});
  }

  void _onAdsSettingsChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final l10n = AppLocalizations.of(context);

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
              _buildHeader(l10n, languageProvider),

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

                        // ✅ قسم إزالة الإعلانات الجديد مع خاصية التوسيع
                        _buildExpandableAdsRemovalSection(l10n),

                        const SizedBox(height: 20),

                        // About Game Section
                        _buildSection(
                          l10n.aboutGame,
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
                              text: l10n.version,
                              value: '1.0.0',
                              color: Colors.green,
                            ),
                            _buildAboutItem(
                              icon: Icons.code,
                              text: l10n.developer,
                              value: languageProvider.isArabic ? 'فريق عالماشي' : '3almaShe Team',
                              color: Colors.purple,
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Game Description Section
                        _buildSection(
                          l10n.aboutDesecration,
                          Icons.games,
                          Colors.orange,
                          [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.aboutGameSubject1,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      height: 1.5,
                                    ),
                                    textAlign: TextAlign.start,
                                  ),
                                  const SizedBox(height: 15),
                                  Text(
                                    l10n.aboutGameSubject2,
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
                          l10n.aboutTheWebsite,
                          Icons.language,
                          Colors.green,
                          [
                            _buildWebsiteItem(
                              icon: Icons.public,
                              text: l10n.VisitWebsite,
                              value: 'www.3almaShe.com',
                              onTap: _visitWebsite,
                              color: Colors.blue,
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Language Section
                        _buildSection(
                          l10n.aboutLanguage,
                          Icons.language,
                          Colors.purple,
                          [
                            _buildLanguageOption(languageProvider),
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

  // ✅ قسم إزالة الإعلانات الجديد مع خاصية التوسيع
  Widget _buildExpandableAdsRemovalSection(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.purple.withOpacity(0.5), width: 2),
      ),
      child: Column(
        children: [
          // رأس القسم (يبقى كما هو)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _isAdsRemovalExpanded = !_isAdsRemovalExpanded;
                });
              },
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.2),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                ),
                child: Row(
                  children: [
                    _buildAdsRemovalIcon(_adsRemovalService.isActive),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.adsRemoval,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 300),
                      turns: _isAdsRemovalExpanded ? 0.5 : 0,
                      child: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.purple,
                        size: 30,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // محتوى القسم
          if (_isAdsRemovalExpanded) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // ✅ التصحيح: استخدام الدالة المعرفة
                  _paymentUIService.buildPaymentStatus(l10n, onRetry: () => _initializePayment()),

                  const SizedBox(height: 16),

                  // حالة الإعلانات الحالية
                  _buildAdsStatusOption(l10n),

                  const SizedBox(height: 16),

                  // خيارات الشراء الدائمة
                  if (!_adsRemovalService.isActive) ...[
                    ..._paymentUIService.buildAllAdsRemovalOptions(l10n, _purchaseAdsRemoval),
                    const SizedBox(height: 16),
                  ],

                  // خيار الإزالة المؤقتة
                  if (!_adsRemovalService.isActive)
                    _buildTemporaryRemovalOption(l10n),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }


  // ✅ أيقونة إزالة الإعلانات الجديدة من assets
  Widget _buildAdsRemovalIcon(bool isActive) {
    return Stack(
      children: [
        // الأيقونة الأساسية من assets
        Image.asset(
          'assets/images/ui/adsStop.png',
          width: 30,
          height: 30,
          fit: BoxFit.contain,
        ),
        // ✅ علامة صح خضراء إذا كانت الإعلانات معطلة
        if (isActive)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: const Icon(
                Icons.check,
                size: 8,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  // ✅ حالة الإعلانات الحالية
  Widget _buildAdsStatusOption(AppLocalizations l10n) {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    bool isArabic = languageProvider.isArabic;

    if (_adsRemovalService.isActive) {
      statusText = _adsRemovalService.getStatusText(isArabic: isArabic);
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;

      if (_adsRemovalService.expiryDate != null) {
        statusText += ' (${_adsRemovalService.getRemainingTime(isArabic: isArabic)})';
      } else if (!_adsRemovalService.isTemporary) {
        statusText += ' (${l10n.lifetime})';
      }
    } else {
      statusText = _adsRemovalService.getStatusText(isArabic: isArabic);
      statusColor = Colors.orange;
      statusIcon = Icons.ad_units;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          if (_adsRemovalService.isActive)
            IconButton(
              icon: const Icon(Icons.info, color: Colors.blue, size: 20),
              onPressed: () => _showAdsRemovalInfo(l10n),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(maxWidth: 30, maxHeight: 30),
            ),
        ],
      ),
    );
  }

  // ✅ خيار الإزالة المؤقتة (مشاهدة إعلان)
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
                  size: 20,
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
                        fontSize: 14,
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

  void _showAdsRemovalInfo(AppLocalizations l10n) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    bool isArabic = languageProvider.isArabic;

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
            l10n.adsRemoval,
            style: const TextStyle(
              color: Colors.blue,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAdsRemovalIcon(true),
              const SizedBox(height: 12),
              Text(
                '${l10n.currentAdsStatus}: ${_adsRemovalService.getStatusText(isArabic: isArabic)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_adsRemovalService.expiryDate != null) ...[
                const SizedBox(height: 6),
                Text(
                  '${l10n.remainingTime}: ${_adsRemovalService.getRemainingTime(isArabic: isArabic)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n.adsRemovalDescription,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
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

  // باقي الدوال الموجودة سابقاً (مع التعديلات البسيطة)
  Widget _buildHeader(AppLocalizations l10n, LanguageProvider languageProvider) {
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

  Widget _buildLanguageToggleButton(LanguageProvider languageProvider) {
    return GestureDetector(
      onTap: () {
        languageProvider.toggleLanguage();
        setState(() {});
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
        child: Center(
          child: languageProvider.isArabic
              ? _buildEnglishIcon()
              : _buildArabicIcon(),
        ),
      ),
    );
  }

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

  Widget _buildLanguageOption(LanguageProvider languageProvider) {
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
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _buildStyledDialog(
          title: l10n.VisitWebsite,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.public, size: 60, color: Colors.blue),
              const SizedBox(height: 10),
              Text(
                l10n.aboutOpenWebsite,
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
              child: Text(l10n.aboutCancel),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: إضافة كود فتح الموقع هنا
              },
              child: Text(l10n.aboutOpenLink),
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