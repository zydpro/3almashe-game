import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/online_character_system.dart';
import '../../../services/game_data_service.dart';
import '../../../Languages/localization.dart';
import '../../../Languages/LanguageProvider.dart';
import '../../../services/Payment_UI_Service.dart';
import '../../../services/ads_removal_service.dart';
import '../../../services/ads_service.dart';
import '../../../services/payment_service.dart';
import '../../../services/settings_service.dart';
import '../../online/screens/online_store_screen.dart';
import '../../online/services/screen_orientation_service.dart';

class OnlineCharactersScreen extends StatefulWidget {
  const OnlineCharactersScreen({super.key});

  @override
  State<OnlineCharactersScreen> createState() => _OnlineCharactersScreenState();
}

class _OnlineCharactersScreenState extends State<OnlineCharactersScreen> {
  List<OnlineCharacter> _onlineCharacters = [];
  bool _isLoading = true;
  OnlineCharacter? _selectedCharacter;
  int _userCoins = 0;

  // ✅ تصميم جديد محسّن
  final double _characterImageHeight = 220.0; // تكبير الصورة

  late SettingsService _settingsService;
  late AdsRemovalService _adsRemovalService;
  late PaymentService _paymentService;
  late PaymentUIService _paymentUIService;

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

    // تأخير استدعاء الدوال حتى لا تسبب مشاكل أثناء البناء
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _precacheImages();
      _loadCharacters();
      _loadUserCoins();
    });

    ScreenOrientationService().lockToLandscape();
  }

  void _precacheImages() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final character in _onlineCharacters) {
        precacheImage(AssetImage(character.imagePath), context);
        precacheImage(AssetImage(character.iconPath), context);
      }
    });
  }

  Future<void> _loadCharacters() async {
    try {
      final onlineCharacters = OnlineCharacter.getAllOnlineCharacters();
      final ownedCharacters = await GameDataService.getOwnedCharacters();
      final ownedCharacterIds = ownedCharacters.map((c) => c.id).toList();

      final updatedCharacters = onlineCharacters.map((onlineChar) {
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
        _onlineCharacters = updatedCharacters;
        _selectedCharacter = updatedCharacters.firstWhere(
              (char) => !char.isLocked,
          orElse: () => updatedCharacters.first,
        );
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading characters: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserCoins() async {
    try {
      final coins = await GameDataService.getUserCoins();
      setState(() {
        _userCoins = coins;
      });
    } catch (e) {
      print('Error loading user coins: $e');
    }
  }

  void _onSettingsChanged() => setState(() {});
  void _onAdsSettingsChanged() => setState(() {});
  void _onPaymentUpdate() {
    // تأخير setState لتجنب مشاكل أثناء البناء
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {});
    });
  }

  // ✅ زر الرجوع
  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.6),
          border: Border.all(color: Colors.blueAccent, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 2,
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

  // ✅ إيقونة اللغة المميزة
  Widget _buildLanguageButton() {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return GestureDetector(
          onTap: () {
            languageProvider.toggleLanguage();
          },
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: languageProvider.isArabic
                    ? [const Color(0xFF006233), const Color(0xFF006233).withOpacity(0.8)]
                    : [const Color(0xFF012169), const Color(0xFFC8102E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(
                languageProvider.isArabic ? 'EN' : 'ع',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      blurRadius: 4,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ✅ زر العملات مع النافذة المنبثقة
  Widget _buildCoinsButton(AppLocalizations l10n) {
    return GestureDetector(
      onTap: _openCoinsPurchaseOptions,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.amber, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.diamond, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            Text(
              '$_userCoins',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 4,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ زر إزالة الإعلانات
  Widget _buildAdsRemovalButton(AppLocalizations l10n) {
    return GestureDetector(
      onTap: _openAdsRemovalOptions,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple[800]!, Colors.purple[600]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.purpleAccent, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.block, color: Colors.white, size: 20),
            const SizedBox(width: 6),
            Text(
              l10n.removeAdsButton,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

// ✅ شراء الشخصية
  void _buyCharacter() {
    final l10n = AppLocalizations.of(context); // أضف هذا السطر

    if (_selectedCharacter == null || !_selectedCharacter!.isLocked) return;

    if (_userCoins >= _selectedCharacter!.price) {
      // ✅ شراء الشخصية
      _showSnackBar(l10n.characterPurchased, Colors.green);
      setState(() {
        _userCoins -= _selectedCharacter!.price;
        _selectedCharacter = OnlineCharacter(
          id: _selectedCharacter!.id,
          name: _selectedCharacter!.name,
          nameEn: _selectedCharacter!.nameEn,
          type: _selectedCharacter!.type,
          imagePath: _selectedCharacter!.imagePath,
          iconPath: _selectedCharacter!.iconPath,
          isLocked: false,
          price: _selectedCharacter!.price,
          primaryWeapon: _selectedCharacter!.primaryWeapon,
          secondaryWeapon: _selectedCharacter!.secondaryWeapon,
          specialAbility: _selectedCharacter!.specialAbility,
          specialAbilityCooldown: _selectedCharacter!.specialAbilityCooldown,
          characterColor: _selectedCharacter!.characterColor,
        );

        // تحديث قائمة الشخصيات
        final index = _onlineCharacters.indexWhere((c) => c.id == _selectedCharacter!.id);
        if (index != -1) {
          _onlineCharacters[index] = _selectedCharacter!;
        }
      });
    } else {
      // ✅ لا يوجد نقاط كافية - فتح نافذة شراء النقاط
      _showInsufficientCoinsDialog();
    }
  }

  void _showInsufficientCoinsDialog() {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900]!.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.orange[700]!, width: 2),
          ),
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange[700], size: 28),
              const SizedBox(width: 10),
              Text(
                'Insufficient Coins',
                style: TextStyle(
                  color: Colors.orange[700],
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You need ${_selectedCharacter!.price} 💎 to purchase this character.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You currently have $_userCoins 💎',
                  style: TextStyle(
                    color: Colors.yellow[300],
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Would you like to buy more coins?',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.grey[700],
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _openCoinsPurchaseOptions();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Buy Coins',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ✅ دوال الشراء (نفس الكود القديم)
  void _openCoinsPurchaseOptions() async {
    final l10n = AppLocalizations.of(context);

    try {
      if (!_paymentService.isInitialized) {
        await _paymentService.initialize();
      }

      // تأخير تحميل المنتجات لتجنب المشاكل
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (_paymentService.products.isEmpty) {
          await _paymentUIService.reloadProducts();
        }

        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return _buildCoinsPurchaseDialog(l10n);
            },
          );
        }
      });
    } catch (e) {
      print('Error opening coins purchase: $e');
    }
  }

  void _openAdsRemovalOptions() {
    final l10n = AppLocalizations.of(context);

    try {
      // تأخير تحميل المنتجات لتجنب المشاكل
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!_paymentService.isInitialized || _paymentService.products.isEmpty) {
          await _paymentUIService.reloadProducts();
        }

        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return _buildAdsRemovalDialog(l10n);
            },
          );
        }
      });
    } catch (e) {
      print('Error opening ads removal: $e');
    }
  }

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
              _paymentUIService.buildPaymentStatus(l10n, onRetry: () {}),
              const SizedBox(height: 20),
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
              _buildCurrentAdsStatus(l10n),
              const SizedBox(height: 16),
              _paymentUIService.buildPaymentStatus(l10n, onRetry: () {}),
              const SizedBox(height: 20),
              if (!_adsRemovalService.isActive) ...[
                ..._paymentUIService.buildAllAdsRemovalOptions(l10n, _purchaseAdsRemoval),
                const SizedBox(height: 16),
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

  Widget _buildCurrentAdsStatus(AppLocalizations l10n) {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (_adsRemovalService.isActive) {
      statusText = _adsRemovalService.isTemporary ? l10n.removeAdsTemporarily : l10n.adsDisabled;
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
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

  void _purchaseCoins(String productId) {
    try {
      _paymentService.purchaseProduct(productId);
    } catch (e) {
      print('Error purchasing coins: $e');
    }
  }

  void _purchaseAdsRemoval(String productId) {
    try {
      _paymentService.purchaseProduct(productId);
    } catch (e) {
      print('Error purchasing ads removal: $e');
    }
  }

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
            ],
          ),
        );
      },
    );

    AdsService.showInterstitialAd(
      onAdStarted: () {
        if (context.mounted) {
          Navigator.pop(context);
        }
      },
      onAdCompleted: () async {
        try {
          await GameDataService.addCharacterCoins(20);
          setState(() {
            _userCoins += 20;
          });
          if (context.mounted) {
            _showSnackBar(l10n.coinsAdded(20), Colors.green);
          }
        } catch (e) {
          print('Error adding coins: $e');
        }
      },
      onAdFailed: (error) {
        if (context.mounted) {
          Navigator.pop(context);
          _showSnackBar(l10n.adFailed, Colors.red);
        }
      },
    );
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // ✅ تصفح الشخصيات
  void _navigateCharacter(int direction) {
    if (_selectedCharacter == null || _onlineCharacters.isEmpty) return;

    final currentIndex = _onlineCharacters.indexWhere((c) => c.id == _selectedCharacter!.id);
    if (currentIndex == -1) return;

    int newIndex = currentIndex + direction;
    if (newIndex < 0) newIndex = _onlineCharacters.length - 1;
    if (newIndex >= _onlineCharacters.length) newIndex = 0;

    setState(() {
      _selectedCharacter = _onlineCharacters[newIndex];
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bool isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0A14),
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
            ],
          ),
        ),
        child: Column(
          children: [
            // ✅ شريط التنقل العلوي المحسّن
            _buildTopNavigationBar(l10n), // ✅ إزالة l10n من هنا

            Expanded(
              child: Stack(
                children: [
                  // ✅ خلفية خفيفة
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.05,
                      child: Image.asset(
                        'assets/online/backgrounds/main_bg.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  if (_isLoading) _buildLoadingState(l10n),

                  if (!_isLoading && _selectedCharacter != null)
                    _buildCharacterSelectionScreen(l10n, isArabic),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopNavigationBar(AppLocalizations l10n) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        border: Border(
          bottom: BorderSide(color: Colors.blueAccent.withOpacity(0.5), width: 2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // ✅ الجانب الأيسر: زر الرجوع
            Row(
              children: [
                _buildBackButton(),
                const SizedBox(width: 10),
                _buildNavButton(l10n.home, Icons.home, () => Navigator.pop(context)),
              ],
            ),

            // ✅ المنتصف: العملات والأزرار
            Row(
              children: [
                _buildAdsRemovalButton(l10n),
                const SizedBox(width: 10),
                _buildCoinsButton(l10n),
              ],
            ),

            // ✅ الجانب الأيمن: أزرار متجر واللغة
            Row(
              children: [
                _buildNavButton(l10n.store, Icons.store, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const OnlineStoreScreen()),
                  );
                }),
                const SizedBox(width: 10),
                _buildLanguageButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton(String text, IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.transparent,
          border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(width: 4),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterSelectionScreen(AppLocalizations l10n, bool isArabic) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ قائمة الشخصيات على اليسار
          Container(
            width: 140,
            margin: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blueGrey[800]!, width: 2),
            ),
            child: Column(
              children: [
                // ✅ عنوان اللوحة
                Container(
                  height: 35,
                  decoration: BoxDecoration(
                    color: Colors.blueGrey[900],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      l10n.charactersTitle,
                      style: TextStyle(
                        color: Colors.blueAccent[100],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(5),
                    shrinkWrap: true,
                    itemCount: _onlineCharacters.length,
                    itemBuilder: (context, index) {
                      final character = _onlineCharacters[index];
                      return _buildCharacterListItem(character, l10n, isArabic);
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ✅ الشخصية المحددة في المنتصف (صورة مكبرة)
          Expanded(
            child: _buildSelectedCharacterPanel(l10n, isArabic),
          ),

          const SizedBox(width: 8),

          // ✅ المعلومات والإحصائيات على اليمين
          Container(
            width: 230,
            margin: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blueGrey[800]!, width: 2),
            ),
            child: Column(
              children: [
                // ✅ عنوان لوحة الإحصائيات
                Container(
                  height: 35,
                  decoration: BoxDecoration(
                    color: Colors.blueGrey[900],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      l10n.characterInfoTitle,
                      style: TextStyle(
                        color: Colors.blueAccent[100],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // ✅ استخدام SingleChildScrollView لمنع التدفق
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(10),
                    physics: const BouncingScrollPhysics(),
                    child: _buildCharacterStatsContent(l10n, isArabic),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterListItem(OnlineCharacter character, AppLocalizations l10n, bool isArabic) {
    bool isSelected = _selectedCharacter?.id == character.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCharacter = character;
        });
      },
      child: Container(
        height: 45,
        margin: const EdgeInsets.only(bottom: 5),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent.withOpacity(0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? Colors.blueAccent : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // ✅ أيقونة الشخصية
            Container(
              width: 35,
              height: 35,
              margin: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                image: DecorationImage(
                  image: AssetImage(character.iconPath),
                  fit: BoxFit.cover,
                  colorFilter: character.isLocked
                      ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                      : null,
                ),
                border: Border.all(
                  color: character.isLocked ? Colors.red : Colors.green,
                  width: 1,
                ),
              ),
            ),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic ? character.name : character.nameEn,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    character.type,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 7,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            if (character.isLocked)
              Padding(
                padding: const EdgeInsets.only(right: 3),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    '${character.price}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 7,
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

  Widget _buildSelectedCharacterPanel(AppLocalizations l10n, bool isArabic) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ✅ صورة الشخصية المحددة
          Container(
            height: _characterImageHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              image: DecorationImage(
                image: AssetImage(_selectedCharacter!.imagePath),
                fit: BoxFit.contain,
                colorFilter: _selectedCharacter!.isLocked
                    ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                    : null,
              ),
              boxShadow: [
                BoxShadow(
                  color: _selectedCharacter!.characterColor.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
              border: Border.all(
                color: _selectedCharacter!.characterColor,
                width: 3,
              ),
            ),
            child: Stack(
              children: [
                // ✅ اسم الشخصية في الزاوية
                Positioned(
                  bottom: 15,
                  left: 15,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic ? _selectedCharacter!.name : _selectedCharacter!.nameEn,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 8,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _selectedCharacter!.type.toUpperCase(),
                        style: TextStyle(
                          color: _selectedCharacter!.characterColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // ✅ أزرار التنقل بين الشخصيات
                Positioned(
                  left: 5,
                  top: _characterImageHeight / 2 - 20,
                  child: _buildNavigationArrow(Icons.arrow_back_ios, () => _navigateCharacter(-1)),
                ),
                Positioned(
                  right: 5,
                  top: _characterImageHeight / 2 - 20,
                  child: _buildNavigationArrow(Icons.arrow_forward_ios, () => _navigateCharacter(1)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          // ✅ زر الشراء/التحديد
          _buildActionButtons(l10n, isArabic),
        ],
      ),
    );
  }

  Widget _buildNavigationArrow(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.6),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildCharacterStatsContent(AppLocalizations l10n, bool isArabic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ✅ حالة القفل/الفتح
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _selectedCharacter!.isLocked
                ? Colors.red.withOpacity(0.2)
                : Colors.green.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _selectedCharacter!.isLocked ? Colors.red : Colors.green,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _selectedCharacter!.isLocked ? Icons.lock : Icons.lock_open,
                color: _selectedCharacter!.isLocked ? Colors.red : Colors.green,
                size: 18,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _selectedCharacter!.isLocked
                      ? l10n.locked // هنا دالة تأخذ باراميتر
                      : l10n.opened, // هنا getter بدون باراميتر
                  style: TextStyle(
                    color: _selectedCharacter!.isLocked ? Colors.red : Colors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ✅ نقاط القوة
        Text(
          l10n.strengthsTitle,
          style: TextStyle(
            color: Colors.blueAccent[100],
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        _buildStrengthRow(l10n.damage, 0.8, Colors.red),
        _buildStrengthRow(l10n.speed, 0.6, Colors.blue),
        _buildStrengthRow(l10n.defense, 0.9, Colors.green),
        _buildStrengthRow(l10n.range, 0.4, Colors.purple),

        const SizedBox(height: 12),

        // ✅ زر مشاهدة إعلان
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _watchAdForPoints,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.ondemand_video, size: 14),
                const SizedBox(width: 4),
                Text(
                  l10n.watchAdForCoinsButton,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // ✅ تفاصيل إضافية
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.blueGrey[700]!, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.difficultyTitle,
                style: TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    Icons.star,
                    color: index < 3 ? Colors.orange : Colors.grey,
                    size: 12,
                  );
                }),
              ),
              const SizedBox(height: 6),
              Text(
                _selectedCharacter!.isLocked
                    ? l10n.purchaseToUnlock
                    : l10n.readyForBattle,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 9,
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStrengthRow(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 9,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Container(
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${(value * 100).toInt()}%',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: color,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(AppLocalizations l10n, bool isArabic) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _selectedCharacter!.isLocked
            ? _buyCharacter // ✅ فتح شراء الشخصية
            : () {
          // ✅ اختيار الشخصية للعب
          _showSnackBar(l10n.characterSelected, Colors.green);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _selectedCharacter!.isLocked ? Colors.orange : Colors.green,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 5,
          shadowColor: _selectedCharacter!.isLocked ? Colors.orange[700] : Colors.green[700],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              color: Colors.white,
              _selectedCharacter!.isLocked ? Icons.shopping_cart : Icons.play_arrow,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _selectedCharacter!.isLocked
                  ? l10n.buyForPrice(_selectedCharacter!.price)
                  : l10n.selectCharacterButton,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 2,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Colors.blueAccent,
            strokeWidth: 3,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.loadingCharacters,
            style: TextStyle(
              color: Colors.blueAccent[100],
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _settingsService.removeListener(_onSettingsChanged);
    _adsRemovalService.removeListener(_onAdsSettingsChanged);
    _paymentService.removeListener(_onPaymentUpdate);
    imageCache.clear();
    imageCache.clearLiveImages();
    super.dispose();
  }
}