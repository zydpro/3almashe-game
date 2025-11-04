import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Languages/LanguageProvider.dart';
import '../services/ads_service.dart';
import '../services/game_data_service.dart';
import '../services/settings_service.dart';
import '../services/ads_removal_service.dart';
import '../services/payment_service.dart';
import '../Languages/localization.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SettingsService _settingsService;
  late AdsRemovalService _adsRemovalService;
  late PaymentService _paymentService;

  // ✅ نفس إعدادات الحجم والظل من MainMenuScreen
  double cornerShadowBlur = 10.0;
  double cornerShadowSpread = 2.0;
  Color cornerShadowColor = Colors.black.withOpacity(0.5);
  Offset cornerShadowOffset = const Offset(2, 2);
  double cornerIconSize = 50.0;
  double cornerButtonSize = 60.0;

  // ✅ حالة فتح/إغلاق قسم إزالة الإعلانات
  bool _isAdsRemovalExpanded = false;

  int highScore = 0;
  int totalCoins = 0;
  int unlockedLevelsCount = 0;
  int currentLevel = 1;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _settingsService = SettingsService();
    _adsRemovalService = AdsRemovalService();
    _paymentService = PaymentService();

    _loadStats();
    _settingsService.addListener(_onSettingsChanged);
    _adsRemovalService.addListener(_onAdsSettingsChanged);
    _paymentService.addListener(_onPaymentUpdate);

    _initializePaymentSystem();
  }

  @override
  void dispose() {
    _settingsService.removeListener(_onSettingsChanged);
    _adsRemovalService.removeListener(_onAdsSettingsChanged);
    _paymentService.removeListener(_onPaymentUpdate);
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

  Future<void> _initializePaymentSystem() async {
    await _paymentService.initialize();
  }

  void _loadStats() async {
    try {
      final highScoreResult = await GameDataService.getHighScore();
      final totalCoinsResult = await GameDataService.getTotalCoins();
      final unlockedLevelsResult = await GameDataService.getUnlockedLevels();
      final currentLevelResult = await GameDataService.getCurrentLevel();

      setState(() {
        highScore = highScoreResult;
        totalCoins = totalCoinsResult;
        unlockedLevelsCount = unlockedLevelsResult.length;
        currentLevel = currentLevelResult;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        highScore = 0;
        totalCoins = 0;
        unlockedLevelsCount = 1;
        currentLevel = 1;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: true);
    final l10n = AppLocalizations.of(context);

    if (isLoading) {
      return _buildLoadingScreen();
    }

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

                        // Game Settings Section
                        _buildSection(
                          l10n.settings,
                          Icons.gamepad,
                          Colors.blue,
                          [
                            _buildLanguageOption(languageProvider, l10n),
                            _buildSettingOption(
                              icon: Icons.volume_up,
                              text: l10n.sound,
                              description: l10n.sound,
                              value: _settingsService.soundEnabled,
                              onChanged: (value) => _settingsService.setSoundEnabled(value),
                              color: Colors.green,
                            ),
                            _buildSettingOption(
                              icon: Icons.music_note,
                              text: l10n.music,
                              description: l10n.music,
                              value: _settingsService.musicEnabled,
                              onChanged: (value) => _settingsService.setMusicEnabled(value),
                              color: Colors.purple,
                            ),
                            _buildSettingOption(
                              icon: Icons.vibration,
                              text: l10n.vibration,
                              description: l10n.vibration,
                              value: _settingsService.vibrationEnabled,
                              onChanged: (value) => _settingsService.setVibrationEnabled(value),
                              color: Colors.orange,
                            ),
                            _buildSettingOption(
                              icon: Icons.notifications,
                              text: l10n.notifications,
                              description: l10n.notifications,
                              value: _settingsService.notificationsEnabled,
                              onChanged: (value) => _settingsService.setNotificationsEnabled(value),
                              color: Colors.red,
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Game Progress Section
                        _buildSection(
                          l10n.SettingsStatistics,
                          Icons.analytics,
                          Colors.amber,
                          [
                            _buildStatOption(
                              icon: Icons.star,
                              text: l10n.highScore,
                              value: highScore.toString(),
                              color: Colors.yellow,
                            ),
                            _buildStatOption(
                              icon: Icons.monetization_on,
                              text: l10n.totalCoins,
                              value: totalCoins.toString(),
                              color: Colors.amber,
                            ),
                            _buildStatOption(
                              icon: Icons.check_circle,
                              text: l10n.unlockedLevels,
                              value: '${unlockedLevelsCount - 1}/100',
                              color: Colors.green,
                            ),
                            _buildStatOption(
                              icon: Icons.play_circle,
                              text: l10n.currentLevel,
                              value: currentLevel.toString(),
                              color: Colors.blue,
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // App Actions Section
                        _buildSection(
                          l10n.SettingsApplicationProcedures,
                          Icons.settings,
                          Colors.orange,
                          [
                            _buildActionOption(
                              icon: Icons.star_rate,
                              text: l10n.SettingsGameRating,
                              description: l10n.SettingsYourReview,
                              onTap: _rateApp,
                              color: Colors.orange,
                            ),
                            _buildActionOption(
                              icon: Icons.share,
                              text: l10n.share,
                              description: l10n.SettingsShareWithFriends,
                              onTap: _shareApp,
                              color: Colors.blue,
                            ),
                            _buildActionOption(
                              icon: Icons.refresh,
                              text: l10n.SettingsResetData,
                              description: l10n.SettingsDeleteAllData,
                              onTap: _resetGameData,
                              color: Colors.red,
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // About Section
                        _buildSection(
                          l10n.about,
                          Icons.info,
                          Colors.grey,
                          [
                            _buildInfoOption(
                              icon: Icons.info_outline,
                              text: l10n.version,
                              value: '1.0.0',
                            ),
                            _buildInfoOption(
                              icon: Icons.code,
                              text: l10n.developer,
                              value: l10n.almaSheTeam,
                            ),
                            _buildActionOption(
                              icon: Icons.privacy_tip,
                              text: l10n.PrivacyPolicy,
                              description: l10n.ReadOurPrivacyPolicy,
                              onTap: _openPrivacyPolicy,
                              color: Colors.grey,
                            ),
                            _buildActionOption(
                              icon: Icons.description,
                              text: l10n.TermsOfUse,
                              description: l10n.ReadTheTermsOfUse,
                              onTap: _openTermsOfService,
                              color: Colors.grey,
                            ),
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
          // ✅ رأس القسم القابل للنقر
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
                    // ✅ استخدام الأيقونة الجديدة من assets
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
                    // ✅ سهم التوسيع
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

          // ✅ محتوى القسم (يظهر/يختفي حسب الحالة)
          if (_isAdsRemovalExpanded) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // حالة نظام الدفع
                  _buildPaymentStatus(l10n),

                  const SizedBox(height: 12),

                  // حالة الإعلانات الحالية
                  _buildCurrentAdsStatus(l10n),

                  const SizedBox(height: 16),

                  // خيارات الشراء الدائمة (فقط إذا لم تكن الإعلانات معطلة)
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
                  ],

                  // خيار الإزالة المؤقتة (مشاهدة إعلان)
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
      statusText = l10n.paymentNotAvailable;  // ✅ الآن ستظهر بالعربية
      statusColor = Colors.red;
      statusIcon = Icons.error;
    } else {
      statusText = l10n.paymentReady;  // ✅ الآن ستظهر بالعربية
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
              _buildAdsRemovalIcon(true),
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

  // باقي الدوال الموجودة سابقاً (بدون تغيير)
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
                l10n.settings,
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
            // ✅ زر اللغة في الهيدر
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

  Widget _buildLanguageOption(LanguageProvider languageProvider, AppLocalizations l10n) {
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
          const Icon(Icons.language, color: Colors.blue, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.aboutLanguage,
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

  Widget _buildLoadingScreen() {
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
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 20),
              Text(
                'جاري تحميل الإحصائيات...',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
        ),
      ),
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

  Widget _buildSettingOption({
    required IconData icon,
    required String text,
    required String description,
    required bool value,
    required Function(bool) onChanged,
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
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: color,
            inactiveThumbColor: Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildStatOption({
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

  Widget _buildActionOption({
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
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: color,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoOption({
    required IconData icon,
    required String text,
    required String value,
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
          Icon(icon, color: Colors.white70, size: 24),
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
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ باقي الدوال (بدون تغيير)
  void _rateApp() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900]!.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF048A81), width: 2),
          ),
          title: Text(
            l10n.rate,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, size: 50, color: Colors.amber),
              const SizedBox(height: 8),
              Text(
                l10n.rateYouHappy,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.rateHelpUs,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
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
                      l10n.later,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(l10n.rateNow),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _shareApp() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900]!.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF048A81), width: 2),
          ),
          title: Text(
            l10n.share,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            l10n.shareWithFriends,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      l10n.close,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(l10n.shareOnly),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _resetGameData() async {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900]!.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF048A81), width: 2),
          ),
          title: Text(
            l10n.SettingsResetData,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning, size: 50, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                l10n.resetWillDelet,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red, width: 1),
                ),
                child: Text(
                  '⚠️ ${l10n.SettingsDeleteAllData}',
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
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
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await _performResetGameData(l10n);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: Text(l10n.delete),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _performResetGameData(AppLocalizations l10n) async {
    try {
      // ✅ إظهار نافذة تحميل
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.black87,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 16),
                Text(
                  l10n.SettingsResetData,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          );
        },
      );

      // ✅ تنفيذ إعادة التعيين
      await GameDataService.resetGameData();

      // ✅ إغلاق نافذة التحميل
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // ✅ إعادة تحميل الإحصائيات
      setState(() {
        _loadStats();
      });

      // ✅ إظهار رسالة نجاح
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.resetDone),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

    } catch (e) {
      // ✅ إغلاق نافذة التحميل في حالة الخطأ
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  void _openPrivacyPolicy() {
    final l10n = AppLocalizations.of(context);
    _showPrivacyPolicyDialog(l10n);
  }

  void _openTermsOfService() {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context);
    _showTermsOfServiceDialog(l10n, languageProvider);
  }

  void _showPrivacyPolicyDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _buildStyledDialog(
          title: l10n.PrivacyPolicy,
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    '🛡️ ${l10n.PrivacyPolicy}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    '${l10n.lastUpdate}: 11 أكتوبر 2025',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '${l10n.welcomeToGame} "3almaShe Run – ${l10n.gameName}" ("${l10n.we}", "${l10n.theGame}", "${l10n.developmentTeam}").',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.privacyPolicyIntro,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                _buildPrivacySection(
                  '1. ${l10n.dataWeCollect}',
                  [
                    l10n.privacyPoint1,
                    l10n.privacyPoint2,
                    l10n.privacyPoint3,
                    l10n.privacyPoint4,
                  ],
                ),
                _buildPrivacySection(
                  '2. ${l10n.adsAndThirdParties}',
                  [
                    l10n.adsPoint1,
                    l10n.adsPoint2,
                  ],
                ),
                _buildPrivacySection(
                  '3. ${l10n.inAppPurchases}',
                  [
                    l10n.purchasesPoint1,
                  ],
                ),
                _buildPrivacySection(
                  '4. ${l10n.dataSecurity}',
                  [
                    l10n.securityPoint1,
                    l10n.securityPoint2,
                  ],
                ),
                _buildPrivacySection(
                  '5. ${l10n.childrenPrivacy}',
                  [
                    l10n.childrenPoint1,
                    l10n.childrenPoint2,
                  ],
                ),
                _buildPrivacySection(
                  '6. ${l10n.policyChanges}',
                  [
                    l10n.changesPoint1,
                    l10n.changesPoint2,
                  ],
                ),
                _buildPrivacySection(
                  '7. ${l10n.contactUs}',
                  [
                    l10n.contactPoint1,
                    '📧 support@3almashe.com',
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.close),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPrivacySection(String title, List<String> points) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 15),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 10),
        ...points.map((point) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '• ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              Expanded(
                child: Text(
                  point,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  void _showTermsOfServiceDialog(AppLocalizations l10n, LanguageProvider languageProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _buildStyledDialog(
          title: l10n.TermsOfUse,
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    languageProvider.isArabic ? '⚖️ شروط الاستخدام' : '⚖️ Terms of Use',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    languageProvider.isArabic ?
                    '${l10n.lastUpdate}: 11 أكتوبر 2025' :
                    '${l10n.lastUpdate}: October 11, 2025',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  languageProvider.isArabic ?
                  '${l10n.welcomeToGame} "3almaShe Run – ${l10n.gameName}" ("${l10n.we}", "${l10n.theGame}", "${l10n.developmentTeam}").' :
                  '${l10n.welcomeToGame} "3almaShe Run – ${l10n.gameName}" ("${l10n.we}", "${l10n.theGame}", "${l10n.developmentTeam}").',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.termsIntro1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                _buildTermsSection(
                  '1. ${l10n.termsAcceptance}',
                  l10n.termsPoint1,
                  languageProvider.isArabic,
                ),
                _buildTermsSection(
                  '2. ${l10n.termsLicense}',
                  l10n.termsPoint2,
                  languageProvider.isArabic,
                ),
                _buildTermsSection(
                  '3. ${l10n.termsContent}',
                  l10n.termsPoint3,
                  languageProvider.isArabic,
                ),
                _buildTermsSection(
                  '4. ${l10n.termsAds}',
                  l10n.termsPoint4,
                  languageProvider.isArabic,
                ),
                _buildTermsSection(
                  '5. ${l10n.termsUpdates}',
                  l10n.termsPoint5,
                  languageProvider.isArabic,
                ),
                _buildTermsSection(
                  '6. ${l10n.termsDisclaimer}',
                  l10n.termsPoint6,
                  languageProvider.isArabic,
                ),
                _buildTermsSection(
                  '7. ${l10n.termsTermination}',
                  l10n.termsPoint7,
                  languageProvider.isArabic,
                ),
                _buildTermsSection(
                  '8. ${l10n.termsLaw}',
                  l10n.termsPoint8,
                  languageProvider.isArabic,
                ),
                _buildTermsSection(
                  '9. ${l10n.contactUs}',
                  l10n.termsPoint9,
                  languageProvider.isArabic,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.close),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTermsSection(String title, String content, bool isArabic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 15),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            height: 1.5,
          ),
          textAlign: isArabic ? TextAlign.right : TextAlign.left,
        ),
      ],
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
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: content,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: actions,
              ),
            ],
          ),
        ),
      ),
    );
  }
}