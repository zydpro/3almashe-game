import 'package:almashe_game/screens/levels_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ads_service.dart';
import '../services/settings_service.dart';
import '../services/ads_removal_service.dart';
import '../services/payment_service.dart';
import '../services/game_data_service.dart';
import '../Languages/LanguageProvider.dart';
import '../Languages/localization.dart';
import 'main_menu_screen.dart';

class PauseMenuScreen extends StatefulWidget {
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final bool isGamePaused;

  const PauseMenuScreen({
    super.key,
    required this.onResume,
    required this.onRestart,
    required this.isGamePaused,
  });

  @override
  State<PauseMenuScreen> createState() => _PauseMenuScreenState();
}

class _PauseMenuScreenState extends State<PauseMenuScreen> with SingleTickerProviderStateMixin {
  late SettingsService _settingsService;
  late AdsRemovalService _adsRemovalService;
  late PaymentService _paymentService;
  late AnimationController _languageAnimationController;
  late Animation<double> _languageScaleAnimation;

  // ✅ إعدادات التصميم المحسنة
  double cornerShadowBlur = 8.0;
  double cornerShadowSpread = 1.0;
  Color cornerShadowColor = Colors.black.withOpacity(0.4);
  Offset cornerShadowOffset = const Offset(1, 1);
  double cornerIconSize = 40.0;
  double cornerButtonSize = 50.0;

  @override
  void initState() {
    super.initState();
    _settingsService = SettingsService();
    _adsRemovalService = AdsRemovalService();
    _paymentService = PaymentService();

    _settingsService.addListener(_onSettingsChanged);
    _adsRemovalService.addListener(_onAdsSettingsChanged);
    _paymentService.addListener(_onPaymentUpdate);

    _initializePaymentSystem();
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

  Future<void> _initializePaymentSystem() async {
    await _paymentService.initialize();
  }

  @override
  void dispose() {
    _settingsService.removeListener(_onSettingsChanged);
    _adsRemovalService.removeListener(_onAdsSettingsChanged);
    _paymentService.removeListener(_onPaymentUpdate);
    _languageAnimationController.dispose();
    super.dispose();
  }

  void _onSettingsChanged() {
    setState(() {});
  }

  void _onAdsSettingsChanged() {
    setState(() {});
  }

  void _onPaymentUpdate() {
    if (mounted) setState(() {});
  }

  void _resumeGame() {
    Navigator.pop(context);
    widget.onResume();
  }

  void _restartLevel() {
    Navigator.pop(context);
    _showAdAndRestart();
  }

  void _showAdAndRestart() {
    if (_adsRemovalService.isActive) {
      widget.onRestart();
      return;
    }

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

    AdsService.showInterstitialAd(
      onAdStarted: () {
        Navigator.pop(context);
      },
      onAdCompleted: () {
        widget.onRestart();
      },
      onAdFailed: (error) {
        Navigator.pop(context);
        widget.onRestart();
      },
    );
  }

  void _goToMainMenu() {
    if (_adsRemovalService.isActive) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainMenuScreen()),
            (route) => false,
      );
      return;
    }

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

    AdsService.showInterstitialAd(
      onAdStarted: () {
        Navigator.pop(context);
      },
      onAdCompleted: () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainMenuScreen()),
              (route) => false,
        );
      },
      onAdFailed: (error) {
        Navigator.pop(context);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainMenuScreen()),
              (route) => false,
        );
      },
    );
  }

  void _toggleSound() {
    _settingsService.toggleSound();
  }

  void _toggleMusic() {
    _settingsService.toggleMusic();
  }

  void _toggleVibration() {
    _settingsService.toggleVibration();
  }

  void _openAdsRemovalScreen() {
    _showAdsRemovalOptions();
  }

  void _shareAdsRemoval() {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900]!.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.teal, width: 2),
          ),
          title: Text(
            l10n.share,
            style: const TextStyle(
              color: Colors.teal,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.share, size: 50, color: Colors.teal),
              const SizedBox(height: 16),
              Text(
                l10n.locale.languageCode == 'ar'
                    ? 'انضم إلى ${l10n.gameTitle} واستمتع بتجربة خالية من الإعلانات!'
                    : 'Join ${l10n.gameTitle} and enjoy an ad-free experience!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.teal, width: 1),
                ),
                child: Text(
                  l10n.locale.languageCode == 'ar'
                      ? 'شارك الرابط مع أصدقائك: [رابط التطبيق]'
                      : 'Share the link with your friends: [App Link]',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
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
                  backgroundColor: Colors.teal,
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

  void _showAdsRemovalOptions() {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _buildAdsRemovalDialog(l10n);
      },
    );
  }

  Widget _buildAdsRemovalDialog(AppLocalizations l10n) {
    return Dialog(
      backgroundColor: Colors.grey[900]!.withOpacity(0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF048A81), width: 2),
      ),
      child: SingleChildScrollView(
        child: Padding(
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
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // حالة الإعلانات الحالية
              _buildCurrentAdsStatus(l10n),

              const SizedBox(height: 8),

              // ✅ إضافة حالة نظام الدفع
              _buildPaymentStatus(l10n),

              const SizedBox(height: 12),

              // خيارات الشراء (تظهر فقط إذا كانت الإعلانات مفعلة)
              if (!_adsRemovalService.isActive) ...[
                _buildAdsPurchaseOption('remove_ads_1day', l10n),
                const SizedBox(height: 8),
                _buildAdsPurchaseOption('remove_ads_1week', l10n),
                const SizedBox(height: 8),
                _buildAdsPurchaseOption('remove_ads_1month', l10n),
                const SizedBox(height: 8),
                _buildAdsPurchaseOption('remove_ads_1year', l10n),
                const SizedBox(height: 8),
                _buildAdsPurchaseOption('remove_ads_lifetime', l10n),
                const SizedBox(height: 12),
                // خيار الإزالة المؤقتة
                _buildTemporaryRemovalOption(l10n),
              ],

              const SizedBox(height: 16),

              // زر الإغلاق
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    l10n.close,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color, width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.block,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _paymentService.getProductName(productId, l10n.locale.languageCode),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _paymentService.getProductDescription(productId, l10n.locale.languageCode),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                product.price,
                style: TextStyle(
                  fontSize: 16,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      l10n.removeAdsTemporarily,
                      style: const TextStyle(
                        fontSize: 11,
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
                size: 14,
              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
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
          if (_adsRemovalService.isActive)
            IconButton(
              icon: const Icon(Icons.info, color: Colors.blue, size: 18),
              onPressed: () => _showAdsRemovalInfo(l10n),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(maxWidth: 30, maxHeight: 30),
            ),
        ],
      ),
    );
  }

  void _showAdsRemovalInfo(AppLocalizations l10n) {
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
              const Icon(Icons.info, size: 40, color: Colors.blue),
              const SizedBox(height: 12),
              Text(
                '${l10n.currentAdsStatus}: ${_adsRemovalService.getStatusText()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_adsRemovalService.expiryDate != null) ...[
                const SizedBox(height: 6),
                Text(
                  '${l10n.remainingTime}: ${_adsRemovalService.getRemainingTime()}',
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
          content: SingleChildScrollView(
            child: Column(
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

  // ✅ دالة تبديل اللغة
  Future<void> _toggleLanguage(LanguageProvider languageProvider) async {
    await _languageAnimationController.forward();
    await languageProvider.toggleLanguage();
    await _languageAnimationController.reverse();
  }

  // ✅ زر تبديل اللغة في الهيدر
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

  // ✅ أيقونة اللغة الإنجليزية
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
      backgroundColor: Colors.black54,
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          constraints: BoxConstraints(
            maxWidth: 400,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[900]!.withOpacity(0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 15,
                spreadRadius: 3,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✅ الهيدر
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLanguageToggleButton(),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        l10n.pauseTitle,
                        style: const TextStyle(
                          fontSize: 24,
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
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 15),
                    SizedBox(
                      width: cornerButtonSize,
                      height: cornerButtonSize,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                _buildOptionButton(
                  icon: Icons.play_arrow,
                  text: l10n.resume,
                  description: l10n.pauseResumeDesc,
                  onTap: _resumeGame,
                  color: Colors.green,
                ),

                const SizedBox(height: 15),

                _buildOptionButton(
                  icon: Icons.refresh,
                  text: l10n.restartLevel,
                  description: l10n.pauseRestartDesc,
                  onTap: _restartLevel,
                  color: Colors.orange,
                ),

                const SizedBox(height: 15),

                _buildOptionButton(
                  icon: Icons.home,
                  text: l10n.mainMenu,
                  description: l10n.pauseMainMenuDesc,
                  onTap: _goToMainMenu,
                  color: Colors.blue,
                ),

                const SizedBox(height: 20),

                _buildSettingsSection(l10n),
              ],
            ),
          ),
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
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 1.5),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildSettingsSection(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey, width: 1),
      ),
      child: Column(
        children: [
          Text(
            l10n.settings,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),

          // ✅ إعدادات اللغة
          _buildSettingRow(
            icon: Icons.language,
            text: l10n.pauseLanguage,
            trailing: _buildLanguageToggleButton(),
          ),

          const SizedBox(height: 8),

          // ✅ إعدادات الموسيقى
          _buildSettingRow(
            icon: Icons.music_note,
            text: l10n.music,
            trailing: Switch(
              value: _settingsService.musicEnabled,
              onChanged: (value) => _toggleMusic(),
              activeColor: Colors.green,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),

          const SizedBox(height: 8),

          // ✅ إعدادات الأصوات
          _buildSettingRow(
            icon: Icons.volume_up,
            text: l10n.sound,
            trailing: Switch(
              value: _settingsService.soundEnabled,
              onChanged: (value) => _toggleSound(),
              activeColor: Colors.green,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),

          const SizedBox(height: 8),

          // ✅ إعدادات الاهتزاز
          _buildSettingRow(
            icon: Icons.vibration,
            text: l10n.vibration,
            trailing: Switch(
              value: _settingsService.vibrationEnabled,
              onChanged: (value) => _toggleVibration(),
              activeColor: Colors.green,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),

          const SizedBox(height: 8),

          // ✅ زر إزالة الإعلانات
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _openAdsRemovalScreen,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _adsRemovalService.isActive ? Icons.block : Icons.ad_units,
                          color: _adsRemovalService.isActive ? Colors.green : Colors.purple,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.adsRemoval,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              _adsRemovalService.isActive
                                  ? _adsRemovalService.getStatusText()
                                  : l10n.manageAds,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white70,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String text,
    required Widget trailing,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing,
      ],
    );
  }
}