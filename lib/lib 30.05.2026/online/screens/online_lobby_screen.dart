import 'dart:async';
import 'dart:math';
import 'package:almashe_game/online/screens/player_search_screen.dart';
import 'package:almashe_game/online/screens/real_character_selection_screen.dart';
import 'package:almashe_game/online/screens/searching_real_player_enhanced.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../Languages/localization.dart';
import '../../../Languages/LanguageProvider.dart';
import '../models/online_character_system.dart';
import '../services/auth_service.dart';
import '../services/real_player_matchmaking.dart';
import '../services/screen_orientation_service.dart';
import 'character_selection_screen.dart';
import 'friends_list_screen.dart';
import '../../../services/game_data_service.dart';
import '../services/p2p_connection_service.dart';
import 'p2p_lobby_screen.dart';
import 'online_characters_screen.dart';
import 'online_store_screen.dart';
import 'online_login_screen.dart';


class OnlineLobbyScreen extends StatefulWidget {
  const OnlineLobbyScreen({super.key});

  @override
  State<OnlineLobbyScreen> createState() => _OnlineLobbyScreenState();
}

class _OnlineLobbyScreenState extends State<OnlineLobbyScreen>
    with TickerProviderStateMixin {
  OnlineCharacter? _selectedCharacter;
  List<OnlineCharacter> _onlineCharacters = [];
  bool _isLoading = true;
  String _searchStatus = '';
  bool _isSearching = false;
  final P2PConnectionService _connectionService = P2PConnectionService();
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  Animation<double>? _slideAnimation;

  _OnlineLobbyScreenState() {
    // ⚠️ تحذير: هذا constructor يعمل قبل initState، ولا يمكن استخدام 'this' هنا
  }

  // ✅ متغيرات جديدة للحساب
  User? _currentUser;
  bool _isGuest = true;
  final AuthService _authService = AuthService();
  String _userDisplayName = '';
  String? _currentRandomImage;

  // ✅ إضافة مؤقت لتغيير الصورة تلقائياً
  Timer? _imageChangeTimer;

  // ✅ قائمة الصور العشوائية للشخصيات
  final List<String> _randomCharacterImages = [
    'assets/images/characters/almashe/almashe_heavy_attack_5.png',
    'assets/images/characters/arabic/arabic_idle_3.png',
    'assets/images/characters/comics/comics_idle_6.png',
    'assets/images/characters/fiery/fiery_heavy_attack_2.png',
    'assets/images/characters/greek/greek_heavy_attack_6.png',
    'assets/images/characters/rainbow/rainbow_heavy_attack_2.png',
    'assets/images/characters/snowy/snowy_dodge_1.png',
    'assets/images/characters/techno/techno_heavy_attack_2.png',
    'assets/images/characters/viking/viking_icon.png',
    'assets/images/characters/zombie/zombie_heavy_attack_2.png',
    'assets/images/characters/warrior/warrior_death_1.png',
  ];

  int _getStoreCharactersCount() {
    return _onlineCharacters.where((char) => char.isLocked).length;
  }

  void initState() {
    super.initState();
    // قفل الشاشة في الوضع الأفقي عند دخول اللوبي
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScreenOrientationService().lockToLandscape();
    });
    _setLandscapeOrientation();
    _initializeAnimations(); // ✅ استدعاء مباشر
    _loadOnlineCharacters();
    _checkUserStatus();
    _selectRandomCharacterImage();
    _startAutoImageChange();
  }

  void _initializeAnimations() {
    if (mounted) {
      _animationController = AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      );

      _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController!,
          curve: Curves.easeInOut,
        ),
      );

      _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
        CurvedAnimation(
          parent: _animationController!,
          curve: Curves.easeOutBack,
        ),
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _animationController != null) {
          _animationController!.forward();
        }
      });
    }
  }

  // ✅ دالة لتعيين الوضع الأفقي
  void _setLandscapeOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  // ✅ دالة لاستعادة الاتجاهات الافتراضية
  void _resetOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  // ✅ بدء تغيير الصور تلقائياً كل 10 ثواني
  void _startAutoImageChange() {
    _imageChangeTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (mounted) {
        _selectRandomCharacterImage();
      }
    });
  }

  // ✅ دالة لاختيار صورة عشوائية
  void _selectRandomCharacterImage() {
    if (_randomCharacterImages.isNotEmpty) {
      final random = Random();
      if (mounted) {
        setState(() {
          _currentRandomImage = _randomCharacterImages[random.nextInt(_randomCharacterImages.length)];
        });
      }
    }
  }

  // ✅ التحقق من حالة المستخدم والحصول على الاسم
  void _checkUserStatus() async {
    final user = _authService.currentUser;
    String displayName = '';

    if (user != null && !user.isAnonymous) {
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        displayName = user.displayName!;
      } else {
        displayName = await GameDataService.getPlayerName();
      }
    }

    if (mounted) {
      setState(() {
        _currentUser = user;
        _isGuest = user == null || user.isAnonymous;
        _userDisplayName = displayName;
      });
    }
  }

  Future<void> _loadOnlineCharacters() async {
    try {
      final onlineCharacters = OnlineCharacter.getAllOnlineCharacters();
      final ownedCharacters = await GameDataService.getOwnedCharacters();
      final ownedCharacterIds = ownedCharacters.map((c) => c.id).toList();

      final updatedOnlineCharacters = onlineCharacters.map((onlineChar) {
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

      if (mounted) {
        setState(() {
          _onlineCharacters = updatedOnlineCharacters;
          _selectedCharacter = updatedOnlineCharacters.firstWhere(
                (char) => !char.isLocked,
            orElse: () => updatedOnlineCharacters.first,
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _searchStatus = 'خطأ في تحميل الشخصيات';
        });
      }
    }
  }

  // ✅ زر تبديل اللغة
  Widget _buildLanguageToggleButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
        languageProvider.toggleLanguage();
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
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
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF012169), Color(0xFFC8102E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 5,
          ),
        ],
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
  }

  Widget _buildArabicIcon() {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF006233), Color(0xFFCE1126)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 5,
          ),
        ],
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
  }

// ✅ دالة للذهاب إلى المتجر مع ضمان العودة
  void _goToStore() async {
    print('🛒 الذهاب إلى المتجر من اللوبي...');

    // ✅ الانتقال إلى المتجر مع الانتظار للنتيجة
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OnlineStoreScreen(),
      ),
    );

    print('🛒 العودة من المتجر إلى اللوبي - النتيجة: $result');

    if (!mounted) return;

    // ✅ عند العودة من المتجر:
    // 1. إعادة تعيين الوضع الأفقي
    _setLandscapeOrientation();

    // 2. تحديث قائمة الشخصيات تلقائياً
    await _loadOnlineCharacters();

    // ✅ إظهار رسالة تأكيد فقط إذا تم شراء شيء
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تحديث المخزون!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // ✅ دوال اللعب
// ✅ دالة 1 ضد 1 للاعبين الحقيقيين
  void _startOnline1v1() async {
    if (_selectedCharacter == null || !mounted) return;

    print('🎮 بدء البحث عن 1v1 ضد لاعب حقيقي');

    try {
      final matchmakingService = RealPlayerMatchmakingFixed();

      // ✅ عرض شاشة البحث
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _buildEnhancedMatchmakingDialog(
          gameMode: '1v1',
          matchmakingService: matchmakingService,
        ),
      );

      // ✅ البحث عن مباراة
      final matchData = await matchmakingService.findRealPlayerMatch('1v1');

      if (mounted) {
        Navigator.pop(context); // إغلاق شاشة البحث

        print('✅ انتقال لشاشة اختيار الشخصيات');

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RealCharacterSelectionScreen(
              gameMode: '1v1',
              matchId: matchData['matchId'] as String,
              matchData: matchData,
              is1v1: true,
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ فشل البحث: $e');
      if (mounted) {
        Navigator.pop(context); // إغلاق شاشة البحث

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('فشل البحث'),
            content: Text('لم نتمكن من العثور على خصم: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('حسناً'),
              ),
            ],
          ),
        );
      }
    }
  }

  Widget _buildEnhancedMatchmakingDialog({
    required String gameMode,
    required RealPlayerMatchmakingFixed matchmakingService,
  }) {
    bool isDialogOpen = true;

    return StatefulBuilder(
      builder: (context, setState) {
        return SearchingRealPlayerEnhanced(
          gameMode: gameMode,
          onCancel: () {
            isDialogOpen = false;
            Navigator.pop(context);
          },
        );
      },
    );
  }

// ✅ دالة 2 ضد 2 للاعبين الحقيقيين
  void _startOnline2v2() async {  // أضف async
    if (_selectedCharacter == null || !mounted) return;

    print('🎮 بدء البحث عن 2v2 ضد لاعبين حقيقيين');

    try {
      final matchmakingService = RealPlayerMatchmakingFixed();

      // ✅ عرض شاشة البحث
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _buildEnhancedMatchmakingDialog(
          gameMode: '2v2',
          matchmakingService: matchmakingService,
        ),
      );

      // ✅ البحث عن مباراة (مع await)
      final matchData = await matchmakingService.findRealPlayerMatch('2v2');

      if (mounted) {
        Navigator.pop(context); // إغلاق شاشة البحث

        print('✅ انتقال لشاشة اختيار الشخصيات لـ 2v2');

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RealCharacterSelectionScreen(
              gameMode: '2v2',
              matchId: matchData['matchId'] as String,
              matchData: matchData,
              is1v1: false, // 2v2
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ فشل البحث في 2v2: $e');
      if (mounted) {
        Navigator.pop(context); // إغلاق شاشة البحث

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('فشل البحث'),
            content: Text('لم نتمكن من العثور على فريق: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('حسناً'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _startBot1v1() {
    if (_selectedCharacter == null) return;

    setState(() {
      _isSearching = true;
      _searchStatus = 'جاري إعداد معركة 1v1 ضد الكمبيوتر...';
    });

    _startQuickMatch(1);
  }

  void _startBot2v2() {
    if (_selectedCharacter == null) return;

    setState(() {
      _isSearching = true;
      _searchStatus = 'جاري إعداد معركة 2v2 ضد الكمبيوتر...';
    });

    _startQuickMatch(2);
  }

  void _startQuickMatch(int teamSize) async {
    if (_selectedCharacter == null) return;

    setState(() {
      _isSearching = true;
      _searchStatus = teamSize == 1
          ? 'جاري إعداد معركة 1v1 ضد الكمبيوتر...'
          : 'جاري إعداد معركة 2v2 ضد الكمبيوتر...';
    });

    if (mounted) {
      setState(() {
        _isSearching = false;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CharacterSelectionScreen(
            gameMode: teamSize == 1 ? '1v1 vs Bot' : '2v2 vs Bot',
            opponentsData: _createComputerOpponents(_onlineCharacters, teamSize),
            roomId: 'bot_${DateTime.now().millisecondsSinceEpoch}',
            isQuickMatch: true,
          ),
        ),
      ).then((_) {
        // ✅ عند العودة من اللعبة، إعادة تعيين الوضع الأفقي
        _setLandscapeOrientation();
      });
    }
  }

  List<Map<String, dynamic>> _createComputerOpponents(List<OnlineCharacter> availableCharacters, int count) {
    final opponents = <Map<String, dynamic>>[];
    final random = Random();

    for (int i = 0; i < count; i++) {
      final randomCharacter = availableCharacters.isNotEmpty
          ? availableCharacters[random.nextInt(availableCharacters.length)]
          : OnlineCharacter.getDefaultCharacter();

      opponents.add({
        'playerId': 'bot_${i}_${DateTime.now().millisecondsSinceEpoch}',
        'playerName': 'الكمبيوتر ${i + 1}',
        'character': randomCharacter,
        'isBot': true,
      });
    }

    return opponents;
  }

  void _cancelSearch() {
    setState(() {
      _isSearching = false;
      _searchStatus = '';
    });
  }

  // ✅ واجهة اللوبي المحسنة
  @override
  Widget build(BuildContext context) {
    // ✅ التحقق من تهيئة الأنيميشن
    if (_animationController == null || _fadeAnimation == null || _slideAnimation == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.blueAccent,
          ),
        ),
      );
    }

    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: _animationController!,
        builder: (context, child) {
          return Container(
            width: size.width,
            height: size.height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0A0E21),
                  Color(0xFF1A1A2E),
                  Color(0xFF16213E),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
              image: DecorationImage(
                image: AssetImage('assets/online/backgrounds/cave.png'),
                fit: BoxFit.cover,
                opacity: 0.15,
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.1,
                    child: CustomPaint(
                      painter: _ParticlesPainter(),
                    ),
                  ),
                ),

                _buildGlowingStars(),

                Positioned.fill(
                  child: Opacity(
                    opacity: _fadeAnimation!.value,
                    child: Transform.translate(
                      offset: Offset(0, _slideAnimation!.value),
                      child: Column(
                        children: [
                          _buildEnhancedHeader(l10n),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 160,
                                    child: _buildLeftPanel(l10n),
                                  ),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: _buildMainGameModes(l10n),
                                  ),
                                  SizedBox(width: 6),
                                  Container(
                                    width: 220,
                                    child: _buildRightPanel(l10n),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ✅ تحديث دالة _buildGlowingStars
  Widget _buildGlowingStars() {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _animationController ?? AnimationController(
            duration: Duration.zero,
            vsync: this,
          ),
          builder: (context, child) {
            return CustomPaint(
              painter: _StarsPainter(_animationController?.value ?? 0),
            );
          },
        ),
      ),
    );
  }

  // ✅ الهيدر المحسن
  Widget _buildEnhancedHeader(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          // 🔙 زر الرجوع
          _buildAnimatedButton(
            icon: Icons.arrow_back,
            color: Colors.white,
            onTap: () {
              // ✅ إعادة تعيين الاتجاهات قبل العودة
              _resetOrientation();
              Navigator.pop(context);
            },
            size: 40,
          ),

          SizedBox(width: 10),

          // 👤 زر الأصدقاء
          _buildAnimatedButton(
            icon: Icons.people,
            color: Colors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FriendsListScreen()),
              ).then((_) {
                // ✅ عند العودة، إعادة تعيين الوضع الأفقي
                _setLandscapeOrientation();
              });
            },
            size: 40,
          ),

          Spacer(),

          // 🏆 عنوان اللعبة
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.almasheBattle,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(
                      color: Colors.blueAccent,
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 4),
              Text(
                'ONLINE ARENA',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),

          Spacer(),

          // 👤 قسم الحساب
          _buildAccountSection(l10n),

          SizedBox(width: 10),

          // 🌐 زر اللغة
          _buildLanguageToggleButton(context),
        ],
      ),
    );
  }

  // ✅ زر أنيميشن
  Widget _buildAnimatedButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    double size = 40,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.3),
              color.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: color.withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Icon(
            icon,
            color: Colors.white,
            size: size * 0.5,
          ),
        ),
      ),
    );
  }

  // ✅ قسم الحساب المحسن
  Widget _buildAccountSection(AppLocalizations l10n) {
    final user = FirebaseAuth.instance.currentUser;

    return GestureDetector(
      onTap: _showProfileMenu,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: user == null
                ? [Colors.orange.withOpacity(0.3), Colors.orange.withOpacity(0.1)]
                : [Colors.green.withOpacity(0.3), Colors.green.withOpacity(0.1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: user == null ? Colors.orange : Colors.green,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (user == null ? Colors.orange : Colors.green).withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 👤 أيقونة الحساب
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: user == null
                      ? [Colors.orange, Colors.orange.shade800]
                      : [Colors.green, Colors.green.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (user == null ? Colors.orange : Colors.green).withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  user == null ? Icons.person_outline : Icons.person,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            SizedBox(width: 8),

            // 📝 معلومات الحساب
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user?.displayName?.split(' ').first ?? 'ضيف',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: user == null ? Colors.orange : Colors.green,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (user == null ? Colors.orange : Colors.green).withOpacity(0.8),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      user == null ? 'سجل الدخول' : 'متصل',
                      style: TextStyle(
                        color: user == null ? Colors.orange : Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ✅ الجزء الأيسر - الإحصائيات والملف الشخصي (بدون زر التغيير اليدوي)
  Widget _buildLeftPanel(AppLocalizations l10n) {
    final availableCount = _onlineCharacters.where((char) => !char.isLocked).length;
    final totalCount = _onlineCharacters.length;
    final user = FirebaseAuth.instance.currentUser;

    return Container(
      width: 200,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 👤 صورة الملف الشخصي بدون زر التغيير
            Center(
              child: Stack(
                children: [
                  // 🔥 تأثير الإطار
                  Container(
                    width: 110,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.blueAccent,
                          Colors.blue.shade800,
                          Colors.purpleAccent,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.5),
                          blurRadius: 25,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),

                  // 🖼️ الصورة الرئيسية
                  Container(
                    width: 100,
                    height: 100,
                    margin: EdgeInsets.only(top: 5, left: 5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: user?.photoURL != null
                          ? Image.network(
                        user!.photoURL!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildRandomCharacterImage();
                        },
                      )
                          : _buildRandomCharacterImage(),
                    ),
                  ),

                  // ✨ تأثير لامع في الزاوية
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 25,
                      height: 25,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.8),
                            Colors.transparent,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 10),

            // 📝 نص يوضح أن الصورة تتغير تلقائياً
            Center(
              child: Text(
                'الصورة تتغير تلقائياً',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

            SizedBox(height: 15),

            // 📊 الإحصائيات - بطاقات أصغر
            _buildCompactStatCard(
              title: 'الشخصيات المملوكة',
              value: '$availableCount/$totalCount',
              color: Colors.blue,
              icon: Icons.people,
            ),

            SizedBox(height: 8),

            _buildCompactStatCard(
              title: 'المعارك الفائزة',
              value: '0',
              color: Colors.green,
              icon: Icons.emoji_events,
            ),

            SizedBox(height: 8),

            _buildCompactStatCard(
              title: 'المستوى',
              value: '1',
              color: Colors.orange,
              icon: Icons.trending_up,
            ),
          ],
        ),
      ),
    );
  }

  // ✅ دالة لبناء صورة الشخصية العشوائية
  Widget _buildRandomCharacterImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueAccent, Colors.blue.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: _currentRandomImage != null
          ? Image.asset(
        _currentRandomImage!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackIcon();
        },
      )
          : _buildFallbackIcon(),
    );
  }

  // ✅ أيقونة احتياطية عند خطأ تحميل الصورة
  Widget _buildFallbackIcon() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person,
            size: 40,
            color: Colors.white.withOpacity(0.8),
          ),
          SizedBox(height: 5),
          Text(
            'Player',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ بطاقة إحصائية مضغوطة
  Widget _buildCompactStatCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: color.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.4),
                  color.withOpacity(0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Icon(
                icon,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ الجزء الأوسط - خيارات اللعب الرئيسية
  Widget _buildMainGameModes(AppLocalizations l10n) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Colors.blueAccent,
              strokeWidth: 3,
            ),
            SizedBox(height: 20),
            Text(
              l10n.loadingCharacters,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 6),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildGameModeCard(
                title: '1v1',
                subtitle: 'لاعب ضد لاعب',
                icon: Icons.person,
                iconColor: Colors.blueAccent,
                gradientColors: [Colors.blueAccent, Colors.blue.shade800],
                onTap: _startOnline1v1,
              ),
              SizedBox(width: 10),
              _buildGameModeCard(
                title: '2v2',
                subtitle: 'فريق ضد فريق',
                icon: Icons.people,
                iconColor: Colors.greenAccent,
                gradientColors: [Colors.greenAccent, Colors.green.shade800],
                onTap: _startOnline2v2,
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildGameModeCard(
                title: '1v1',
                subtitle: 'ضد الكمبيوتر',
                icon: Icons.computer,
                iconColor: Colors.orangeAccent,
                gradientColors: [Colors.orangeAccent, Colors.orange.shade800],
                onTap: _startBot1v1,
              ),
              SizedBox(width: 10),
              _buildGameModeCard(
                title: '2v2',
                subtitle: 'فريق ضد الكمبيوتر',
                icon: Icons.computer,
                iconColor: Colors.purpleAccent,
                gradientColors: [Colors.purpleAccent, Colors.purple.shade800],
                onTap: _startBot2v2,
              ),
            ],
          ),
          SizedBox(height: 15),
          _buildCustomRoomCard(l10n),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  // ✅ بطاقة نمط اللعب
  Widget _buildGameModeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 190,
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          children: [
            // 🔥 تأثير الإضاءة
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: gradientColors.first.withOpacity(0.2),
                ),
              ),
            ),

            Positioned(
              bottom: -30,
              left: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: gradientColors.last.withOpacity(0.1),
                ),
              ),
            ),

            // 🎮 المحتوى
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        child: Center(
                          child: Icon(
                            icon,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                      SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                height: 0.9,
                              ),
                            ),
                            Text(
                              subtitle,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  Spacer(),

                  SizedBox(height: 8),

                  Row(
                    children: [
                      Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.white.withOpacity(0.2),
                        ),
                        child: Text(
                          'PLAY',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ دالة للتأكد من بقاء الشاشة في الوضع الأفقي
  void _ensureLandscape() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final current = MediaQuery.of(context).orientation;
        if (current == Orientation.portrait) {
          _setLandscapeOrientation();
        }
      }
    });
  }

  // ✅ بطاقة الغرفة المخصصة
  Widget _buildCustomRoomCard(AppLocalizations l10n) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => P2PLobbyScreen()),
        ).then((_) {
          // ✅ عند العودة، إعادة تعيين الوضع الأفقي
          _setLandscapeOrientation();
        });
      },
      child: Container(
        width: 420,
        padding: EdgeInsets.all(25),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: LinearGradient(
            colors: [
              Colors.pinkAccent.withOpacity(0.3),
              Colors.pinkAccent.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: Colors.pinkAccent.withOpacity(0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.pinkAccent.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.pinkAccent, Colors.pink.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),

            SizedBox(width: 20),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'غرفة مخصصة',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'أنشئ غرفتك الخاصة وادعُ أصدقاءك',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  void _initializeTestData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      print('⚠️ يجب تسجيل الدخول أولاً');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('تهيئة البيانات'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('جاري تنظيف وتهيئة البيانات...'),
          ],
        ),
      ),
    );

    try {
      // تنظيف قوائم الانتظار القديمة
      final queueSnapshot = await FirebaseFirestore.instance
          .collection('matchmaking_queue')
          .get();

      final batch1 = FirebaseFirestore.instance.batch();
      for (var doc in queueSnapshot.docs) {
        batch1.delete(doc.reference);
      }
      await batch1.commit();

      print('✅ تم تنظيف ${queueSnapshot.docs.length} من قوائم الانتظار');

      // تنظيف المباريات القديمة
      final matchesSnapshot = await FirebaseFirestore.instance
          .collection('active_matches')
          .get();

      final batch2 = FirebaseFirestore.instance.batch();
      for (var doc in matchesSnapshot.docs) {
        batch2.delete(doc.reference);
      }
      await batch2.commit();

      print('✅ تم تنظيف ${matchesSnapshot.docs.length} من المباريات');

      Navigator.pop(context); // إغلاق الـ Dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ تم تنظيف البيانات بنجاح'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      Navigator.pop(context); // إغلاق الـ Dialog في حالة الخطأ

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ خطأ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ✅ الجزء الأيمن - معلومات إضافية
  Widget _buildRightPanel(AppLocalizations l10n) {
    final availableCount = _onlineCharacters.where((char) => !char.isLocked).length;
    final totalCount = _onlineCharacters.length;
    final storeCount = _getStoreCharactersCount();

    return Container(
      width: 280,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🎮 الشخصيات
            _buildMenuCard(
              icon: Icons.people_alt,
              title: 'الشخصيات',
              subtitle: 'إدارة وتخصيص شخصياتك',
              count: '$availableCount/$totalCount',
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => OnlineCharactersScreen()),
                ).then((_) {
                  // ✅ عند العودة، إعادة تعيين الوضع الأفقي
                  _setLandscapeOrientation();
                });
              },
            ),

            SizedBox(height: 10),

            // 🛒 المتجر - باستخدام الدالة المعدلة
            _buildMenuCard(
              icon: Icons.store,
              title: 'المتجر',
              subtitle: 'شراء شخصيات جديدة',
              count: '$storeCount',
              color: Colors.green,
              onTap: _goToStore, // ✅ استخدام الدالة المعدلة
            ),

            SizedBox(height: 10),

            // ⚙️ الإعدادات
            _buildMenuCard(
              icon: Icons.settings,
              title: 'الإعدادات',
              subtitle: 'تخصيص تجربة اللعب',
              count: '',
              color: Colors.purple,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('قريباً: شاشة الإعدادات'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ✅ بطاقة القائمة
  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.2),
              color.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.5),
                    color.withOpacity(0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (count.isNotEmpty)
              // Container(
              //   padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              //   decoration: BoxDecoration(
              //     borderRadius: BorderRadius.circular(10),
              //     color: color.withOpacity(0.3),
              //   ),
              //   child: Text(
              //     count,
              //     style: TextStyle(
              //       color: Colors.white,
              //       fontSize: 12,
              //       fontWeight: FontWeight.bold,
              //     ),
              //   ),
              // ),
            SizedBox(width: 10),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white54,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // ✅ قائمة الملف الشخصي
  void _showProfileMenu() {
    final user = FirebaseAuth.instance.currentUser;

    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFF1A1A2E).withOpacity(0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
            ],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: EdgeInsets.only(top: 10, bottom: 20),
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            // ✅ رأس الملف الشخصي المحسن
            Container(
              padding: EdgeInsets.all(20),
              margin: EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.withOpacity(0.2),
                    Colors.blue.withOpacity(0.1),
                  ],
                ),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.blue.withOpacity(0.3),
                    backgroundImage: user?.photoURL != null
                        ? NetworkImage(user!.photoURL!)
                        : null,
                    child: user?.photoURL == null
                        ? Icon(Icons.person, color: Colors.white, size: 30)
                        : null,
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'لاعب',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          user?.email ?? 'ضيف',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.8),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'متصل الآن',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // ✅ خيارات القائمة المحسنة
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildProfileMenuItem(
                    icon: Icons.people,
                    title: '👥 قائمة الأصدقاء',
                    subtitle: 'إدارة أصدقائك وتحديهم',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => FriendsListScreen()),
                      ).then((_) {
                        _setLandscapeOrientation();
                      });
                    },
                    color: Colors.blue,
                  ),

                  _buildProfileMenuItem(
                    icon: Icons.person_add,
                    title: '🔍 إضافة أصدقاء',
                    subtitle: 'ابحث عن لاعبين وأضفهم',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PlayerSearchScreen()),
                      ).then((_) {
                        _setLandscapeOrientation();
                      });
                    },
                    color: Colors.green,
                  ),

                  _buildProfileMenuItem(
                    icon: Icons.leaderboard,
                    title: '🏆 المتصدرين',
                    subtitle: 'شاهد أفضل اللاعبين',
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('قريباً: شاشة المتصدرين'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    },
                    color: Colors.orange,
                  ),

                  Divider(
                    color: Colors.white.withOpacity(0.1),
                    height: 30,
                  ),

                  if (user == null) ...[
                    _buildProfileMenuItem(
                      icon: Icons.login,
                      title: '🚀 تسجيل الدخول',
                      subtitle: 'استمتع بمزايا اللاعبين المسجلين',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => OnlineLoginScreen()),
                        );
                      },
                      color: Colors.green,
                    ),
                  ],

                  _buildProfileMenuItem(
                    icon: Icons.settings,
                    title: '⚙️ الإعدادات',
                    subtitle: 'تخصيص تجربة اللعب',
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('قريباً: شاشة الإعدادات'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    },
                    color: Colors.grey,
                  ),

                  if (user != null)
                    _buildProfileMenuItem(
                      icon: Icons.logout,
                      title: '🚪 تسجيل الخروج',
                      subtitle: 'الخروج من حسابك',
                      onTap: () {
                        Navigator.pop(context);
                        _showLogoutConfirmation();
                      },
                      color: Colors.red,
                    ),
                ],
              ),
            ),

            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ✅ بناء عنصر قائمة الملف الشخصي المحسن
  Widget _buildProfileMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        leading: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.3),
                color.withOpacity(0.1),
              ],
            ),
            border: Border.all(
              color: color.withOpacity(0.5),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.white54,
          size: 18,
        ),
        onTap: onTap,
      ),
    );
  }

  // ✅ تأكيد تسجيل الخروج المحسن
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) => Dialog(
        backgroundColor: Color(0xFF1A1A2E).withOpacity(0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
          side: BorderSide(
            color: Colors.red.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Container(
          padding: EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.red.withOpacity(0.3),
                      Colors.red.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.logout,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
              ),

              SizedBox(height: 25),

              Text(
                'تسجيل الخروج',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 15),

              Text(
                'هل أنت متأكد من أنك تريد تسجيل الخروج؟',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),

              SizedBox(height: 30),

              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.1),
                            Colors.white.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(
                          'إلغاء',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 15),

                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        gradient: LinearGradient(
                          colors: [
                            Colors.red.withOpacity(0.3),
                            Colors.red.withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _authService.signOut();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('تم تسجيل الخروج بنجاح'),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(
                          'تسجيل الخروج',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  @override
  void dispose() {
    _imageChangeTimer?.cancel();
    _imageChangeTimer = null;

    // ✅ التحقق قبل التخلص
    _animationController?.dispose();
    _animationController = null;

    _resetOrientation();
    _connectionService.dispose();

    super.dispose();
  }
}

// 🎨 رسام الجسيمات للخلفية
class _ParticlesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueAccent.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final random = Random();
    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 2 + 1;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ⭐ رسام النجوم اللامعة
class _StarsPainter extends CustomPainter {
  final double animationValue;

  _StarsPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42); // Seed ثابت لثبات المواقع

    // ⭐ النجوم الثابتة
    for (int i = 0; i < 30; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height * 0.7;
      final radius = random.nextDouble() * 1.5 + 0.5;
      final opacity = random.nextDouble() * 0.3 + 0.1;

      final paint = Paint()
        ..color = Colors.white.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // ✨ النجوم اللامعة المتحركة
    for (int i = 0; i < 10; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height * 0.7;
      final pulse = (sin(animationValue * 2 * pi + i) + 1) / 2;
      final radius = pulse * 2 + 0.5;
      final opacity = pulse * 0.5 + 0.1;

      final paint = Paint()
        ..color = Colors.blueAccent.withOpacity(opacity)
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}