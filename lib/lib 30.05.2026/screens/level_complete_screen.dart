import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Languages/LanguageProvider.dart';
import '../Languages/localization.dart';
import '../services/Payment_UI_Service.dart';
import 'game_screen.dart';
import 'levels_screen.dart';
import 'main_menu_screen.dart';
import 'items_screen.dart';
import 'store_screen.dart';
import '../models/level_data.dart';
import '../services/ads_service.dart';
import '../services/ads_removal_service.dart';
import '../services/payment_service.dart';
import '../widgets/confetti_effect.dart';

class LevelCompleteScreen extends StatefulWidget {
  final int score;
  final LevelData levelData;
  final LevelData? nextLevel;
  final int timeSpent;

  const LevelCompleteScreen({
    super.key,
    required this.score,
    required this.levelData,
    this.nextLevel,
    required this.timeSpent,
  });

  @override
  State<LevelCompleteScreen> createState() => _LevelCompleteScreenState();
}

class _LevelCompleteScreenState extends State<LevelCompleteScreen> {
  late AdsRemovalService _adsRemovalService;
  late PaymentService _paymentService;
  late PaymentUIService _paymentUIService;

  @override
  void initState() {
    super.initState();
    _adsRemovalService = Provider.of<AdsRemovalService>(context, listen: false);
    _paymentService = PaymentService();
    _paymentUIService = PaymentUIService();

    _paymentService.addListener(_onPaymentUpdate);
    _initializePaymentSystem();
    _initializeAdsStatus();
  }

  @override
  void dispose() {
    _paymentService.removeListener(_onPaymentUpdate);
    super.dispose();
  }

  Future<void> _initializePaymentSystem() async {
    await _paymentService.initialize();
  }

  Future<void> _initializeAdsStatus() async {
    await AdsRemovalService().initialize();
  }

  void _onPaymentUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final coinsEarned = widget.score ~/ 10;

    return ConfettiEffect(
      isActive: true,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF4CAF50),
                Color(0xFF2E7D32),
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ✅ الهيدر مع زر اللغة وزر الإعلانات
                  _buildHeader(context, l10n),

                  // محتوى التهاني
                  const SizedBox(height: 20),
                  const Icon(Icons.celebration, size: 100, color: Colors.white),
                  const SizedBox(height: 20),
                  Text(
                    l10n.levelCompleteCongratulations,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      l10n.levelCompleteMessage(widget.levelData.getName(l10n)),
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '${l10n.score}: ${widget.score}',
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.yellow,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    '${l10n.coins}: +$coinsEarned',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.amber,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  if (widget.nextLevel != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        l10n.levelCompleteUnlocked(widget.nextLevel!.levelNumber),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.lightGreen,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  Text(
                    '${l10n.timeSpent}: ${_formatTime(widget.timeSpent)}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),

                  // ✅ قسم أزرار الإجراءات الرئيسية
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        if (widget.nextLevel != null)
                          _buildActionButton(
                            l10n.nextLevel,
                            Icons.arrow_forward,
                            Colors.blue,
                                () => _startNextLevelWithAd(context),
                          ),
                        if (widget.nextLevel != null) const SizedBox(height: 15),
                        _buildActionButton(
                          l10n.restartLevel,
                          Icons.refresh,
                          Colors.green,
                              () => _restartLevel(context),
                        ),
                        const SizedBox(height: 15),
                        _buildActionButton(
                          l10n.levelsMenu,
                          Icons.list,
                          Colors.orange,
                              () => _goToLevels(context),
                        ),
                        const SizedBox(height: 15),
                        _buildActionButton(
                          l10n.mainMenu,
                          Icons.home,
                          Colors.grey,
                              () => _goToMainMenu(context),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),

                  // ✅ قسم الأزرار الإضافية في الأسفل
                  _buildBottomActionButtons(l10n),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // ✅ الهيدر مع زر اللغة وزر الإعلانات
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

          // ✅ العنوان في المنتصف
          Expanded(
            child: Text(
              l10n.levelComplete,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.green,
                    blurRadius: 10,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
            ),
          ),

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
      onTap: _openAdsRemovalOptions,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
          border: Border.all(
            color: Colors.transparent,
            width: 0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 5,
              spreadRadius: 1,
              offset: const Offset(1, 1),
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
          Image.asset(
            'assets/images/ui/adsStop.png',
            width: 50,
            height: 50,
            fit: BoxFit.contain,
          ),
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
      return Stack(
        children: [
          Image.asset(
            'assets/images/ui/adsStop.png',
            width: 50,
            height: 50,
            fit: BoxFit.contain,
          ),
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

  // ✅ قسم الأزرار الإضافية في الأسفل
  Widget _buildBottomActionButtons(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900]!.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 15,
            spreadRadius: 3,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildBottomButton(
              icon: Icons.store,
              title: l10n.store,
              gradient: const LinearGradient(
                colors: [Colors.purple, Colors.deepPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              onPressed: _goToStore,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildBottomButton(
              icon: _adsRemovalService.isActive ? Icons.check_circle : Icons.block,
              title: _adsRemovalService.isActive ? l10n.adsDisabled : l10n.removeAds,
              gradient: _adsRemovalService.isActive
                  ? const LinearGradient(colors: [Colors.green, Colors.lightGreen])
                  : const LinearGradient(colors: [Colors.red, Colors.orange]),
              onPressed: _openAdsRemovalOptions,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildBottomButton(
              icon: Icons.person,
              title: l10n.myCharacters,
              gradient: const LinearGradient(
                colors: [Colors.teal, Colors.green],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              onPressed: _goToItems,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ زر سفلي مخصص
  Widget _buildBottomButton({
    required IconData icon,
    required String title,
    required Gradient gradient,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
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
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
          border: Border.all(
            color: Colors.transparent,
            width: 0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 6,
              spreadRadius: 1,
              offset: const Offset(1, 1),
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

  // ✅ أيقونة اللغة الإنجليزية
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

  // ✅ أيقونة اللغة العربية
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
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton(String text, IconData icon, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 5,
          shadowColor: Colors.black.withOpacity(0.3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon),
            const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ دوال التنقل
  void _goToStore() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StoreScreen()),
    );
  }

  void _goToItems() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const itemsScreen()),
    );
  }

  void _openAdsRemovalOptions() {
    final l10n = AppLocalizations.of(context);

    if (_adsRemovalService.isActive) {
      _showCurrentAdsStatus(l10n);
      return;
    }

    _showAdsRemovalOptions(l10n);
  }

  // ✅ استبدل الدالة القديمة بهذه الدالة الجديدة
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
                  const SizedBox(height: 16),

                  // ✅ استخدام الخدمة الجديدة لحالة الدفع
                  _paymentUIService.buildPaymentStatus(l10n, onRetry: _initializePaymentSystem),

                  const SizedBox(height: 20),

                  // ✅ استخدام الخدمة الجديدة لخيارات الإعلانات
                  ..._paymentUIService.buildAllAdsRemovalOptions(l10n, _purchaseAdsRemoval),

                  const SizedBox(height: 16),
                  _buildTemporaryRemovalOption(l10n),
                  const SizedBox(height: 20),

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

  void _startNextLevelWithAd(BuildContext context) {
    if (_adsRemovalService.isActive) {
      _startNextLevelDirectly(context);
      return;
    }

    if (AdsService.isInterstitialAdReady()) {
      _showAdThenNextLevel(context);
    } else {
      _startNextLevelDirectly(context);
    }
  }

  void _showAdThenNextLevel(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
              Text(l10n.loadingAd),
            ],
          ),
        );
      },
    );

    AdsService.showInterstitialAd(
      onAdStarted: () => Navigator.of(context).pop(),
      onAdCompleted: () => _startNextLevelDirectly(context),
      onAdFailed: (error) {
        Navigator.of(context).pop();
        _startNextLevelDirectly(context);
      },
    );
  }

  void _startNextLevelDirectly(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => GameScreen(levelData: widget.nextLevel!)),
    );
  }

  void _restartLevel(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => GameScreen(levelData: widget.levelData)),
    );
  }

  void _goToLevels(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LevelsScreen()),
          (route) => false,
    );
  }

  void _goToMainMenu(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MainMenuScreen()),
          (route) => false,
    );
  }
}