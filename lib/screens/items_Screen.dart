import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ads_service.dart';
import '../services/game_data_service.dart';
import '../services/settings_service.dart';
import '../Languages/LanguageProvider.dart';
import '../Languages/localization.dart';
import 'main_menu_screen.dart';
import 'store_screen.dart';
import '../models/character_model.dart';

class itemsScreen extends StatefulWidget {
  const itemsScreen({super.key});

  @override
  State<itemsScreen> createState() => _itemsScreenState();
}

class _itemsScreenState extends State<itemsScreen> with SingleTickerProviderStateMixin {
  late SettingsService _settingsService;
  late AnimationController _languageAnimationController;
  late Animation<double> _languageScaleAnimation;

  // إعدادات التصميم
  final double _cornerShadowBlur = 10.0;
  final double _cornerShadowSpread = 2.0;
  final Color _cornerShadowColor = Colors.black.withOpacity(0.5);
  final Offset _cornerShadowOffset = const Offset(2, 2);
  final double _cornerIconSize = 50.0;
  final double _cornerButtonSize = 60.0;

  // حالة التطبيق
  int _userPoints = 1000;
  GameCharacter? _selectedCharacter;
  List<GameCharacter> _ownedCharacters = [];
  List<GameCharacter> _availableCharacters = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _settingsService = SettingsService();
    _settingsService.addListener(_onSettingsChanged);
    _initLanguageAnimation();
    _loadUserData();

    // ✅ تسجيل استجابة لتحديثات البيانات
    GameDataService().addUpdateListener(_onDataUpdated);
  }

  void _onDataUpdated() {
    print('🔄 ItemsScreen - تم استلام تحديث البيانات');
    if (mounted) {
      _loadUserData();
    }
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
  Future<void> _loadUserData() async {
    try {
      setState(() => _isLoading = true);

      final coins = await GameDataService.getUserCoins();
      final allCharacters = await GameDataService.getAllCharactersWithLockStatus();

      // ✅ التصنيف الصحيح للشخصيات
      final ownedCharacters = allCharacters.where((char) => !char.isLocked).toList();
      final availableCharacters = allCharacters.where((char) => char.isLocked).toList();

      final selected = await GameDataService.getSelectedCharacter();

      print('🔄 ItemsScreen - النقاط: $coins, المملوكة: ${ownedCharacters.length}, المتاحة: ${availableCharacters.length}');

      setState(() {
        _userPoints = coins;
        _ownedCharacters = ownedCharacters;
        _availableCharacters = availableCharacters;
        _selectedCharacter = selected;
        _isLoading = false;
      });

    } catch (e) {
      print('❌ خطأ في ItemsScreen: $e');
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

  @override
  void dispose() {
    _settingsService.removeListener(_onSettingsChanged);
    _languageAnimationController.dispose();
    GameDataService().removeUpdateListener(_onDataUpdated);
    super.dispose();
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

    if (_userPoints < character.price) {
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
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ✅ دالة شراء نقاط جديدة مع الترجمة
  void _showBuyPointsDialog() {
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
              _buildPointsOption('100 ${l10n.coins}', '10.00', 100, l10n),
              const SizedBox(height: 10),
              _buildPointsOption('500 ${l10n.coins}', '45.00', 500, l10n),
              const SizedBox(height: 10),
              _buildPointsOption('1000 ${l10n.coins}', '80.00', 1000, l10n),
              const SizedBox(height: 10),
              _buildPointsOption('5000 ${l10n.coins}', '350.00', 5000, l10n),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                l10n.cancel,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPointsOption(String title, String price, int points, AppLocalizations l10n) {
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
                '$price ${l10n.locale.languageCode == 'ar' ? 'ريال' : 'SAR'}',
                style: const TextStyle(
                  color: Colors.yellow,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () => _handlePointsPurchase(points, l10n),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text(
              l10n.buyNow,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePointsPurchase(int points, AppLocalizations l10n) async {
    await GameDataService.addCharacterCoins(points);
    setState(() {
      _userPoints += points;
    });
    Navigator.of(context).pop();
    _showSnackBar('${l10n.purchasedSuccessfully} $points ${l10n.coins}!', Colors.green);
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
          title: Text(
            title,
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
          size: 30,
        ),
      ),
    );
  }

  Widget _buildTitle(String text) {
    return Text(
      text,
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
          _buildPointsRow(l10n),
          const SizedBox(height: 15),
          _buildActionButtons(l10n),
        ],
      ),
    );
  }

  Widget _buildPointsRow(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          l10n.yourCoins,
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
            '$_userPoints 💎',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            onPressed: _showBuyPointsDialog,
            backgroundColor: Colors.green,
            icon: Icons.shopping_cart,
            text: l10n.buyCoinsNow,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionButton(
            onPressed: _watchAdForPoints,
            backgroundColor: Colors.blue,
            icon: Icons.play_arrow,
            text: l10n.watchAd,
          ),
        ),
      ],
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSection(AppLocalizations l10n) {
    return Expanded(
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            _buildTabBar(l10n),
            const SizedBox(height: 16),
            _buildStoreButton(l10n),
            const SizedBox(height: 16),
            _buildTabContent(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[900]!.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[400],
        labelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black54,
              blurRadius: 4,
              offset: Offset(1, 1),
            ),
          ],
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
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
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreButton(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
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
          onPressed: _goToStore,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.store, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text(
                l10n.goToMarketplace,
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(AppLocalizations l10n) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
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
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Colors.blue,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          isSelected ? l10n.selected : l10n.select,
          style: const TextStyle(
            fontSize: 14,
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
      onTap: () => _purchaseCharacter(character),
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
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isLocked ? Colors.grey : (isSelected ? Colors.green : character.color),
            width: isSelected ? 4 : 3,
          ),
          boxShadow: [
            BoxShadow(
              color: (isLocked ? Colors.grey : (isSelected ? Colors.green : character.color)).withOpacity(0.5),
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
                top: 10,
                right: 10,
                child: topWidget,
              ),
            if (isLocked)
              Positioned(
                top: 10,
                left: 10,
                child: _buildPurchaseLabel(l10n),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterInfo(GameCharacter character, Widget actionWidget, AppLocalizations l10n) {
    return Container(
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
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: character.isLocked ? Colors.grey : Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          actionWidget,
        ],
      ),
    );
  }

  Widget _buildSelectionBadge() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.green,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(
        Icons.check,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Widget _buildLockBadge() {
    return Container(
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
    );
  }

  Widget _buildPriceBadge(GameCharacter character) {
    return Container(
      margin: const EdgeInsets.only(top: 40),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${character.price}',
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
    );
  }

  Widget _buildPurchaseLabel(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.orange, Colors.red],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        l10n.buyNow,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPurchaseButton(GameCharacter character, AppLocalizations l10n) {
    final canPurchase = _userPoints >= character.price;

    return GestureDetector(
      onTap: () => _purchaseCharacter(character),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          gradient: canPurchase
              ? const LinearGradient(colors: [Colors.orange, Colors.yellow])
              : LinearGradient(colors: [Colors.grey, Colors.grey[700]!]),
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
            Text(
              l10n.buyNow,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: canPurchase ? Colors.black : Colors.white,
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

  Widget _buildLockedCharacter(GameCharacter character) {
    return Stack(
      children: [
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
              const Text(
                '🔒',
                style: TextStyle(fontSize: 24),
              ),
            ],
          ),
        ),
        Container(color: Colors.black.withOpacity(0.6)),
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

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: 80,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _goToStore,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              subtitle,
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
}