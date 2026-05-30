import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../Languages/localization.dart';
import '../../models/character_model.dart';
import '../../services/game_data_service.dart';
import '../animation/animation_manager.dart';
import '../firebase/MatchmakingFirebaseService.dart';
import '../models/online_character_system.dart';
import '../services/p2p_connection_service.dart';
import 'online_game_screen.dart';

class CharacterSelectionScreen extends StatefulWidget {
  final String gameMode;
  final List<Map<String, dynamic>> opponentsData;
  final String roomId;
  final bool isQuickMatch;
  final bool isMatchmaking; // ✅ أضف هذا السطر
  final Map<String, dynamic>? matchData; // ✅ أضف هذا السطر
  final P2PConnectionService? connectionService; // ✅ أضف هذا السطر إن لم يكن موج

  const CharacterSelectionScreen({
    super.key,
    required this.gameMode,
    required this.opponentsData,
    required this.roomId,
    this.isQuickMatch = false,
    this.isMatchmaking = false, // ✅ أضف هذا السطر
    this.matchData, // ✅ أضف هذا السطر
    this.connectionService, // ✅ أضف هذا السطر إن لم يكن موجوداً
  });

  @override
  State<CharacterSelectionScreen> createState() => _CharacterSelectionScreenState();
}

class _CharacterSelectionScreenState extends State<CharacterSelectionScreen>
    with SingleTickerProviderStateMixin {
  List<OnlineCharacter> _availableCharacters = [];
  List<OnlineCharacter> _ownedCharacters = [];
  OnlineCharacter? _selectedCharacter;
  bool _isLoading = true;
  int _countdown = 10;
  bool _isOpponentReady = false;
  Timer? _countdownTimer;
  Timer? _randomSelectionTimer;
  String _statusMessage = '';
  int _userCoins = 0;
  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseAnimation;
  StreamSubscription? _matchSubscription;
  bool _isAutoSelectionEnabled = true;
  int _autoSelectionTime = 5;

  // إضافة دعم اللغة
  Locale _currentLocale = const Locale('ar');
  bool _isRTL = true;

  @override
  void initState() {
    super.initState();
    // ✅ أضف هذا الكود بعد super.initState();
    // if (widget.isMatchmaking && widget.matchData != null) {
    //   // _setupMatchmakingListener();
    //   // _checkOpponentReadyStatus();
    // }
    // تهيئة أنيمشن النبض
    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _loadUserCoins();
    _loadAvailableCharacters();
    _listenForOpponentSelection();
    _startAutoSelectionTimer();

    if (widget.isQuickMatch) {
      setState(() {
        _isOpponentReady = true;
        _startCountdown();
      });
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _randomSelectionTimer?.cancel();
    _matchSubscription?.cancel();
    _pulseAnimationController.dispose();
    super.dispose();
  }

  // ✅ دالة للاستماع لتحديثات المباراة (Matchmaking)
  // void _setupMatchmakingListener() {
  //   final matchmakingService = MatchmakingFirebaseService();
  //   final matchId = widget.matchData?['matchId'];
  //
  //   if (matchId != null) {
  //     _matchSubscription = matchmakingService.listenToMatchUpdates(
  //       matchId,
  //           (matchData) {
  //         if (mounted) {
  //           _onMatchUpdate(matchData);
  //         }
  //       },
  //     );
  //   }
  // }

// ✅ تحديث حالة المباراة
  void _onMatchUpdate(Map<String, dynamic> matchData) {
    if (mounted) {
      // ✅ التحقق من أن المباراة حقيقية
      if (matchData['isRealMatch'] != true) {
        print('⚠️ هذه ليست مباراة حقيقية');
        return;
      }

      // ✅ تحديث حالة جاهزية الخصوم الحقيقيين
      final playersById = matchData['playersById'] as Map<String, dynamic>? ?? {};
      // final currentUserId = MatchmakingFirebaseService().currentUserId;

      // البحث عن جميع الخصوم الحقيقيين
      // final opponents = playersById.entries
      //     .where((entry) => entry.key != currentUserId)
      //     .where((entry) => entry.value['isRealPlayer'] == true)
      //     .map((entry) => entry.value as Map<String, dynamic>)
      //     .toList();

      // if (opponents.isNotEmpty) {
      //   // التحقق إذا كان أي خصم جاهز
      //   final isAnyOpponentReady = opponents.any((opponent) => opponent['isReady'] == true);
      //
      //   if (isAnyOpponentReady) {
      //     setState(() {
      //       _isOpponentReady = true;
      //       _statusMessage = 'الخصم الحقيقي جاهز!';
      //     });
      //
      //     // بدء العد التنازلي إذا كان اللاعب الحالي جاهزاً أيضاً
      //     if (_selectedCharacter != null && !_selectedCharacter!.isLocked) {
      //       _startCountdown();
      //     }
      //   }
      //
      //   // التحقق إذا كان جميع اللاعبين جاهزين
      //   final allReady = playersById.values
      //       .whereType<Map<String, dynamic>>()
      //       .where((player) => player['isRealPlayer'] == true)
      //       .every((player) => player['isReady'] == true);
      //
      //   if (allReady) {
      //     _startCountdown();
      //   }
      // }
    }
  }

// // ✅ التحقق من حالة جاهزية الخصوم
//   void _checkOpponentReadyStatus() {
//     final players = widget.matchData?['players'] as List<dynamic>? ?? [];
//     final currentUserId = MatchmakingFirebaseService().currentUserId;
//
//     for (var player in players) {
//       if (player['playerId'] != currentUserId && player['isReady'] == true) {
//         setState(() {
//           _isOpponentReady = true;
//           _statusMessage = 'الخصم جاهز بالفعل!';
//         });
//         break;
//       }
//     }
//   }

// ✅ تحديث حالة الاستعداد في Firebase
//   Future<void> _updateReadyStatusInFirebase(bool isReady) async {
//     if (!widget.isMatchmaking || widget.matchData == null) return;
//
//     final matchmakingService = MatchmakingFirebaseService();
//     final characterId = _selectedCharacter?.id.toString() ?? '';
//
//     await matchmakingService.updateReadyStatus(isReady, characterId);
//   }

  // تغيير اللغة
  void _toggleLanguage() {
    setState(() {
      if (_currentLocale.languageCode == 'ar') {
        _currentLocale = const Locale('en');
        _isRTL = false;
      } else {
        _currentLocale = const Locale('ar');
        _isRTL = true;
      }
    });
  }

  Future<void> _loadUserCoins() async {
    final coins = await GameDataService.getCoins();
    setState(() {
      _userCoins = coins;
    });
  }

  void _startAutoSelectionTimer() {
    _randomSelectionTimer?.cancel();
    _randomSelectionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_autoSelectionTime > 0) {
          _autoSelectionTime--;
        } else {
          timer.cancel();
          _selectRandomCharacter();
        }
      });
    });
  }

  void _selectRandomCharacter() {
    if (_ownedCharacters.isEmpty) {
      setState(() {
        _statusMessage = AppLocalizations(_currentLocale).noCharactersOwned;
      });
      return;
    }

    final random = Random();
    final randomCharacter = _ownedCharacters[random.nextInt(_ownedCharacters.length)];

    setState(() {
      _selectedCharacter = randomCharacter;
      _statusMessage = '${AppLocalizations(_currentLocale).characterSelected} ${randomCharacter.name}';
      _autoSelectionTime = 0;
    });

    _randomSelectionTimer?.cancel();
  }

  Future<void> _loadAvailableCharacters() async {
    try {
      final allCharacters = OnlineCharacter.getAllOnlineCharacters();
      final ownedCharactersData = await GameDataService.getOwnedCharacters();
      final ownedCharacterIds = ownedCharactersData.map((c) => c.id).toList();

      final availableCharacters = allCharacters.map((character) {
        final isOwned = ownedCharacterIds.contains(character.id);
        return OnlineCharacter(
          id: character.id,
          name: character.name,
          nameEn: character.nameEn,
          type: character.type,
          imagePath: character.imagePath,
          iconPath: character.iconPath,
          isLocked: !isOwned,
          price: character.price,
          primaryWeapon: character.primaryWeapon,
          secondaryWeapon: character.secondaryWeapon,
          specialAbility: character.specialAbility,
          specialAbilityCooldown: character.specialAbilityCooldown,
          characterColor: character.characterColor,
          animationConfigPath: character.animationConfigPath,
        );
      }).toList();

      final ownedCharacters = availableCharacters.where((char) => !char.isLocked).toList();

      setState(() {
        _availableCharacters = availableCharacters;
        _ownedCharacters = ownedCharacters;
        _isLoading = false;

        if (ownedCharacters.isNotEmpty) {
          _selectedCharacter = ownedCharacters.first;
          _autoSelectionTime = 5;
          _startAutoSelectionTimer();
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = AppLocalizations(_currentLocale).characterLoadError;
      });
    }
  }

  void _listenForOpponentSelection() {
    if (widget.isQuickMatch) return;

    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isOpponentReady = true;
          _startCountdown();
        });
      }
    });
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          timer.cancel();
          _startGame();
        }
      });
    });
  }

  Future<void> _selectCharacter(OnlineCharacter character) async {
    if (character.isLocked) {
      await _showPurchaseDialog(character);
      return;
    }

    setState(() {
      _selectedCharacter = character;
      _statusMessage = '${AppLocalizations(_currentLocale).characterSelected} ${character.name}';
      _autoSelectionTime = 5;
    });

    _startAutoSelectionTimer();

    // ✅ أضف هذا الجزء
    // if (widget.isMatchmaking) {
    //   await _updateReadyStatusInFirebase(true);
    //
    //   // التحقق إذا كان الجميع جاهزين
    //   final players = widget.matchData?['players'] as List<dynamic>? ?? [];
    //   final allReady = players.every((player) => player['isReady'] == true);
    //
    //   if (allReady) {
    //     setState(() {
    //       _isOpponentReady = true;
    //     });
    //     _startCountdown();
    //   }
    // } else if (!_isOpponentReady && !widget.isQuickMatch) {
    //   setState(() {
    //     _statusMessage = AppLocalizations(_currentLocale).waitingForOpponent;
    //   });
    // }
  }

  Future<void> _showPurchaseDialog(OnlineCharacter character) async {
    final shouldPurchase = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final isEnoughCoins = _userCoins >= character.price;
        final buyButtonColor = isEnoughCoins ? Colors.green : Colors.grey;

        return Dialog(
          backgroundColor: character.characterColor.withOpacity(0.15), // لون متناسق
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: character.characterColor.withOpacity(0.4), width: 2),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 350, // تصغير العرض
              maxHeight: 550, // تحديد ارتفاع أقصى
            ),
            child: SingleChildScrollView( // إضافة scroll لاحتمال overflow
              child: Padding(
                padding: const EdgeInsets.all(16), // تقليل padding
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // عنوان الحوار - تبسيط
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock, color: character.characterColor, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          AppLocalizations(_currentLocale).characterLocked,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // أيقونة الشخصية - تصغير
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: character.characterColor, width: 2),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          character.iconPath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.person,
                            size: 32,
                            color: character.characterColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // اسم الشخصية
                    Text(
                      _currentLocale.languageCode == 'ar' ? character.name : character.nameEn,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 8),

                    // سعر الشخصية - تبسيط
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.monetization_on, size: 14, color: Colors.yellow),
                          const SizedBox(width: 4),
                          Text(
                            '${character.price}',
                            style: TextStyle(
                              color: Colors.yellow,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // عملات المستخدم - تبسيط
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.account_balance_wallet, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            '${AppLocalizations(_currentLocale).yourCoins}: $_userCoins',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (!isEnoughCoins) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.red),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.warning, color: Colors.red, size: 14),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                AppLocalizations(_currentLocale).insufficientPoints,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // أزرار الإجراءات - تنظيم أفضل
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // زر الإلغاء
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context, false),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.withOpacity(0.3),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(color: Colors.red),
                                ),
                                minimumSize: Size(0, 40), // تحديد ارتفاع ثابت
                              ),
                              child: Text(
                                AppLocalizations(_currentLocale).cancel,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // زر الشراء
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(left: 6),
                            child: ElevatedButton(
                              onPressed: isEnoughCoins
                                  ? () => Navigator.pop(context, true)
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: buyButtonColor.withOpacity(0.3),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(color: buyButtonColor),
                                ),
                                minimumSize: Size(0, 40), // تحديد ارتفاع ثابت
                              ),
                              child: Text(
                                AppLocalizations(_currentLocale).buyNow,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
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
          ),
        );
      },
    );

    if (shouldPurchase == true) {
      await _purchaseCharacter(character);
    }
  }

  Future<void> _purchaseCharacter(OnlineCharacter character) async {
    try {
      if (_userCoins < character.price) {
        setState(() {
          _statusMessage = AppLocalizations(_currentLocale).insufficientPoints;
        });
        return;
      }

      final allGameCharacters = GameCharacter.getAllCharacters();
      final existingGameChar = allGameCharacters.firstWhere(
            (gameChar) => gameChar.id == character.id,
        orElse: () => _createFallbackGameCharacter(character),
      );

      final purchasedCharacter = GameCharacter(
        id: existingGameChar.id,
        name: existingGameChar.name,
        nameEn: existingGameChar.nameEn,
        imagePath: existingGameChar.imagePath,
        price: existingGameChar.price,
        isLocked: false,
        color: existingGameChar.color,
        animations: List.from(existingGameChar.animations),
        description: existingGameChar.description,
        descriptionEn: existingGameChar.descriptionEn,
        type: existingGameChar.type,
        abilities: List.from(existingGameChar.abilities),
        characterKey: existingGameChar.characterKey,
        attackName: existingGameChar.attackName,
        attackNameEn: existingGameChar.attackNameEn,
        attackDescription: existingGameChar.attackDescription,
        attackDescriptionEn: existingGameChar.attackDescriptionEn,
        attackType: existingGameChar.attackType,
        attackDamage: existingGameChar.attackDamage,
        attackSpeed: existingGameChar.attackSpeed,
        attackCooldown: existingGameChar.attackCooldown,
        attackEffects: List.from(existingGameChar.attackEffects),
        attackSound: existingGameChar.attackSound,
      );

      final isSuccess = await GameDataService.purchaseCharacter(purchasedCharacter);

      if (isSuccess) {
        await GameDataService.spendCoins(character.price);
        await _loadUserCoins();
        await _loadAvailableCharacters();

        setState(() {
          _statusMessage = '✅ ${AppLocalizations(_currentLocale).purchaseSuccess(character.name)}';
        });

        final updatedCharacter = _availableCharacters.firstWhere(
              (c) => c.id == character.id,
          orElse: () => _availableCharacters.first,
        );

        if (!updatedCharacter.isLocked) {
          setState(() {
            _selectedCharacter = updatedCharacter;
          });
        }
      } else {
        setState(() {
          _statusMessage = '❌ ${AppLocalizations(_currentLocale).purchaseFailed}';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ ${AppLocalizations(_currentLocale).error}: $e';
      });
    }
  }

  GameCharacter _createFallbackGameCharacter(OnlineCharacter onlineChar) {
    final attackType = _getSafeAttackType(onlineChar.primaryWeapon);

    return GameCharacter(
      id: onlineChar.id,
      name: onlineChar.name,
      nameEn: onlineChar.nameEn,
      imagePath: onlineChar.imagePath,
      price: onlineChar.price.toDouble(),
      isLocked: false,
      color: onlineChar.characterColor,
      animations: [],
      description: onlineChar.type,
      descriptionEn: onlineChar.type,
      type: onlineChar.type,
      abilities: [onlineChar.specialAbility],
      characterKey: 'character_${onlineChar.id}',
      attackName: _getWeaponName(onlineChar.primaryWeapon),
      attackNameEn: _getWeaponNameEn(onlineChar.primaryWeapon),
      attackDescription: onlineChar.specialAbility,
      attackDescriptionEn: onlineChar.specialAbility,
      attackType: attackType,
      attackDamage: 10,
      attackSpeed: 1.0,
      attackCooldown: 3,
      attackEffects: [],
      attackSound: 'attack_sound.mp3',
    );
  }

  dynamic _getSafeAttackType(OnlineWeaponType weaponType) {
    try {
      final weaponString = _getWeaponNameEn(weaponType).toLowerCase();
      return weaponString;
    } catch (e) {
      return 'sword';
    }
  }

  String _getWeaponName(OnlineWeaponType weaponType) {
    switch (weaponType) {
      case OnlineWeaponType.sword: return 'سيف';
      case OnlineWeaponType.hammer: return 'مطرقة';
      case OnlineWeaponType.bow: return 'قوس';
      case OnlineWeaponType.spear: return 'رمح';
      case OnlineWeaponType.katars: return 'مخالب';
      case OnlineWeaponType.gauntlets: return 'قفازات';
      case OnlineWeaponType.blasters: return 'مسدسات';
      case OnlineWeaponType.orb: return 'كرة';
      case OnlineWeaponType.staff: return 'عصا سحرية';
      case OnlineWeaponType.axe: return 'فأس';
      case OnlineWeaponType.dagger: return 'خنجر';
      default: return 'سلاح';
    }
  }

  String _getWeaponNameEn(OnlineWeaponType weaponType) {
    switch (weaponType) {
      case OnlineWeaponType.sword: return 'Sword';
      case OnlineWeaponType.hammer: return 'Hammer';
      case OnlineWeaponType.bow: return 'Bow';
      case OnlineWeaponType.spear: return 'Spear';
      case OnlineWeaponType.katars: return 'Katars';
      case OnlineWeaponType.gauntlets: return 'Gauntlets';
      case OnlineWeaponType.blasters: return 'Blasters';
      case OnlineWeaponType.orb: return 'Orb';
      case OnlineWeaponType.staff: return 'Staff';
      case OnlineWeaponType.axe: return 'Axe';
      case OnlineWeaponType.dagger: return 'Dagger';
      default: return 'Weapon';
    }
  }

  String _getCharacterAnimationId(int characterId) {
    switch (characterId) {
      case 1: return 'almashe';
      case 2: return 'rainbow';
      case 3: return 'arabic';
      case 4: return 'medieval';
      case 5: return 'greek';
      case 6: return 'snowy';
      case 7: return 'fiery';
      case 8: return 'techno';
      case 9: return 'viking';
      case 10: return 'comics';
      case 11: return 'zombie';
      case 12: return 'warrior';
      default: return 'default';
    }
  }

  void _startGame() async {
    if (_selectedCharacter == null && _ownedCharacters.isNotEmpty) {
      _selectRandomCharacter();
    }

    if (_selectedCharacter == null) return;

    await _loadSelectedCharactersOnly();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OnlineGameScreen(
            playerCharacter: _selectedCharacter!,
            opponent: widget.opponentsData.isNotEmpty
                ? widget.opponentsData.first
                : {
              'playerId': 'bot_1',
              'playerName': 'الكمبيوتر',
              'character': OnlineCharacter.getDefaultCharacter(),
              'isBot': true,
            },
            roomId: widget.roomId,
            isQuickMatch: widget.isQuickMatch,
            connectionService: P2PConnectionService(),
            gameMode: widget.gameMode,
          ),
        ),
      );
    }
  }

  Future<void> _loadSelectedCharactersOnly() async {
    try {
      if (_selectedCharacter == null) return;

      final animationManager = AnimationManager();
      final playerCharacterId = _getCharacterAnimationId(_selectedCharacter!.id);
      await animationManager.loadCharacterOnDemand(
        playerCharacterId,
        _selectedCharacter!.animationConfigPath,
      );

      for (final opponentData in widget.opponentsData) {
        final opponentCharacter = opponentData['character'] as OnlineCharacter;
        final opponentCharacterId = _getCharacterAnimationId(opponentCharacter.id);
        await animationManager.loadCharacterOnDemand(
          opponentCharacterId,
          opponentCharacter.animationConfigPath,
        );
      }
    } catch (e) {
      print('❌ ${AppLocalizations(_currentLocale).characterLoadError}: $e');
    }
  }

  Widget _buildCharacterFocusArea() {
    final character = _selectedCharacter;

    if (character == null) {
      return Container(
        width: 250, // تقليل العرض
        padding: const EdgeInsets.all(12), // تقليل padding
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Icon(Icons.person, size: 50, color: Colors.white30),
            ),
            const SizedBox(height: 10),
            Text(
              AppLocalizations(_currentLocale).selectCharacter,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      width: 250, // تقليل العرض
      padding: const EdgeInsets.all(12), // تقليل padding
      child: SingleChildScrollView( // إضافة scroll لمنع overflow
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // نموذج الشخصية مع أنيمشن - تصغير
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: child,
                );
              },
              child: Container(
                width: 160, // تقليل العرض
                height: 200, // تقليل الارتفاع
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: character.characterColor.withOpacity(0.4),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // منصة الهولوجرام - تصغير
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              character.characterColor.withOpacity(0.3),
                              character.characterColor.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    // صورة الشخصية - تصغير
                    Center(
                      child: Image.asset(
                        character.imagePath,
                        width: 140,
                        height: 180,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.person,
                            size: 80,
                            color: character.characterColor,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // اسم الشخصية
            Text(
              _currentLocale.languageCode == 'ar' ? character.name : character.nameEn,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18, // تصغير الخط
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),

            const SizedBox(height: 8),

            // بطاقة معلومات - تبسيط
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // معلومات اللاعب
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'PLAYER 1',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // معلومات السلاح - تنظيم أفضل
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // السلاح الأساسي
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.sports_mma,
                              color: character.characterColor,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                _currentLocale.languageCode == 'ar'
                                    ? _getWeaponName(character.primaryWeapon)
                                    : _getWeaponNameEn(character.primaryWeapon),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // السلاح الثانوي
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.sports_martial_arts,
                              color: character.characterColor,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                _currentLocale.languageCode == 'ar'
                                    ? _getWeaponName(character.secondaryWeapon)
                                    : _getWeaponNameEn(character.secondaryWeapon),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
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

  Widget _buildCharacterGrid() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Colors.blue,
              strokeWidth: 2,
            ),
            SizedBox(height: 12),
            Text(
              'جاري تحميل الشخصيات...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: _isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // مهم: تغيير mainAxisSize
      children: [
        // عنوان الشبكة
        Padding(
          padding: const EdgeInsets.only(bottom: 15, left: 6, right: 6),
          child: Text(
            AppLocalizations(_currentLocale).availableForPurchase,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // شبكة الأيقونات - استخدام Expanded فقط عند الحاجة
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.85,
            ),
            itemCount: _availableCharacters.length,
            shrinkWrap: true, // إضافة shrinkWrap
            physics: const AlwaysScrollableScrollPhysics(), // تمكين التمرير دائماً
            itemBuilder: (context, index) {
              final character = _availableCharacters[index];
              final isSelected = _selectedCharacter?.id == character.id;

              return GestureDetector(
                onTap: () => _selectCharacter(character),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? character.characterColor
                          : character.isLocked
                          ? Colors.grey.withOpacity(0.3)
                          : Colors.white.withOpacity(0.1),
                      width: isSelected ? 2 : 1,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isSelected
                          ? [
                        character.characterColor.withOpacity(0.3),
                        character.characterColor.withOpacity(0.1),
                      ]
                          : [
                        Colors.white.withOpacity(0.05),
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: isSelected
                        ? [
                      BoxShadow(
                        color: character.characterColor.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                        : null,
                  ),
                  child: Stack(
                    children: [
                      // الأيقونة
                      Center(
                        child: Container(
                          width: isSelected ? 40 : 36,
                          height: isSelected ? 40 : 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: character.characterColor.withOpacity(0.1),
                            border: Border.all(
                              color: character.characterColor.withOpacity(0.3),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              character.iconPath,
                              width: isSelected ? 36 : 32,
                              height: isSelected ? 36 : 32,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.person,
                                  size: isSelected ? 24 : 20,
                                  color: character.characterColor,
                                );
                              },
                            ),
                          ),
                        ),
                      ),

                      // القفل للشخصيات المقفلة
                      if (character.isLocked)
                        Positioned(
                          top: 4,
                          right: _isRTL ? 4 : null,
                          left: _isRTL ? null : 4,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black54,
                            ),
                            child: const Icon(
                              Icons.lock,
                              size: 10,
                              color: Colors.yellow,
                            ),
                          ),
                        ),

                      // سعر الشخصية المقفلة
                      if (character.isLocked)
                        Positioned(
                          bottom: 4,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${character.price}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                      // علامة الاختيار
                      if (isSelected)
                        Positioned(
                          top: 4,
                          left: _isRTL ? 4 : null,
                          right: _isRTL ? null : 4,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green,
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 8,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomArea() {
    final isReady = _selectedCharacter != null && !_selectedCharacter!.isLocked;
    final canStart = (_isOpponentReady || widget.isQuickMatch) && isReady;

    return Container(
      padding: const EdgeInsets.all(12),
      height: 80,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // المؤقت
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red),
                ),
                child: Text(
                  '$_countdown',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              if (_autoSelectionTime > 0 && _selectedCharacter == null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Text(
                    '${AppLocalizations(_currentLocale).selectCharacter} $_autoSelectionTime',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                    ),
                  ),
                ),
            ],
          ),

          // زر التأكيد
          Container(
            width: 160,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: canStart
                    ? [
                  Colors.green,
                  const Color(0xFF00C853),
                ]
                    : [
                  Colors.grey.withOpacity(0.5),
                  Colors.grey.withOpacity(0.3),
                ],
              ),
              boxShadow: canStart
                  ? [
                BoxShadow(
                  color: Colors.green.withOpacity(0.5),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: canStart ? _startGame : null,
                borderRadius: BorderRadius.circular(12),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (canStart)
                        const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                      const SizedBox(width: 6),
                      Text(
                        canStart ? AppLocalizations(_currentLocale).play : AppLocalizations(_currentLocale).confirm,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // معلومات إضافية
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: _isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet, color: Colors.amber, size: 16),
                    const SizedBox(width: 5),
                    Text(
                      '$_userCoins',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              if (_isOpponentReady && !widget.isQuickMatch)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person, color: Colors.green, size: 10),
                      const SizedBox(width: 4),
                      Text(
                        AppLocalizations(_currentLocale).verificationCodeSent,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final selectedColor = _selectedCharacter?.characterColor ?? Colors.blue[800]!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            selectedColor.withOpacity(0.8),
            selectedColor.withOpacity(0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),

            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations(_currentLocale).selectCharacter,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${AppLocalizations(_currentLocale).gameMode}: ${widget.gameMode}',
                    style: const TextStyle(
                      color: Colors.yellow,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            GestureDetector(
              onTap: _toggleLanguage,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    _currentLocale.languageCode == 'ar' ? 'EN' : 'AR',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterGridContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Colors.blue,
              strokeWidth: 2,
            ),
            SizedBox(height: 12),
            Text(
              'جاري تحميل الشخصيات...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemCount: _availableCharacters.length,
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final character = _availableCharacters[index];
        final isSelected = _selectedCharacter?.id == character.id;

        return GestureDetector(
          onTap: () => _selectCharacter(character),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? character.characterColor
                    : character.isLocked
                    ? Colors.grey.withOpacity(0.3)
                    : Colors.white.withOpacity(0.1),
                width: isSelected ? 2 : 1,
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isSelected
                    ? [
                  character.characterColor.withOpacity(0.3),
                  character.characterColor.withOpacity(0.1),
                ]
                    : [
                  Colors.white.withOpacity(0.05),
                  Colors.transparent,
                ],
              ),
              boxShadow: isSelected
                  ? [
                BoxShadow(
                  color: character.characterColor.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
                  : null,
            ),
            child: Stack(
              children: [
                // الأيقونة
                Center(
                  child: Container(
                    width: isSelected ? 40 : 36,
                    height: isSelected ? 40 : 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: character.characterColor.withOpacity(0.1),
                      border: Border.all(
                        color: character.characterColor.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        character.iconPath,
                        width: isSelected ? 36 : 32,
                        height: isSelected ? 36 : 32,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.person,
                            size: isSelected ? 24 : 20,
                            color: character.characterColor,
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // القفل للشخصيات المقفلة
                if (character.isLocked)
                  Positioned(
                    top: 4,
                    right: _isRTL ? 4 : null,
                    left: _isRTL ? null : 4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black54,
                      ),
                      child: const Icon(
                        Icons.lock,
                        size: 10,
                        color: Colors.yellow,
                      ),
                    ),
                  ),

                // سعر الشخصية المقفلة
                if (character.isLocked)
                  Positioned(
                    bottom: 4,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${character.price}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // علامة الاختيار
                if (isSelected)
                  Positioned(
                    top: 4,
                    left: _isRTL ? 4 : null,
                    right: _isRTL ? null : 4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 8,
                        color: Colors.white,
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              // الهيدر
              _buildHeader(),

              // رسالة الحالة
              if (_statusMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  color: Colors.blue.withOpacity(0.2),
                  child: Center(
                    child: Text(
                      _statusMessage,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),

              // ✅ استخدم Expanded مع SingleChildScrollView
              Expanded(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height - 150,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      textDirection: _isRTL ? TextDirection.rtl : TextDirection.ltr,
                      children: _isRTL
                          ? [
                        // الجزء الأيمن: عرض الشخصية المختارة
                        Container(
                          width: 250,
                          padding: const EdgeInsets.all(12),
                          child: _buildCharacterFocusArea(),
                        ),

                        Container(
                          width: 1,
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.1),
                                Colors.white.withOpacity(0.3),
                                Colors.white.withOpacity(0.1),
                              ],
                            ),
                          ),
                        ),

                        // الجزء الأيسر: شبكة الشخصيات
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // عنوان شبكة الشخصيات
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 15),
                                child: Text(
                                  'الشخصيات المتاحة',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.end,
                                ),
                              ),

                              // شبكة الشخصيات مع ارتفاع محدد
                              Container(
                                height: 300, // ✅ تحديد ارتفاع ثابت
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: _buildCharacterGridContent(),
                              ),
                            ],
                          ),
                        ),
                      ]
                          : [
                        // الجزء الأيسر: شبكة الشخصيات
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // عنوان شبكة الشخصيات
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 15),
                                child: Text(
                                  'الشخصيات المتاحة',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.start,
                                ),
                              ),

                              // شبكة الشخصيات مع ارتفاع محدد
                              Container(
                                height: 300, // ✅ تحديد ارتفاع ثابت
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: _buildCharacterGridContent(),
                              ),
                            ],
                          ),
                        ),

                        Container(
                          width: 1,
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.1),
                                Colors.white.withOpacity(0.3),
                                Colors.white.withOpacity(0.1),
                              ],
                            ),
                          ),
                        ),

                        // الجزء الأيمن: عرض الشخصية المختارة
                        Container(
                          width: 250,
                          padding: const EdgeInsets.all(12),
                          child: _buildCharacterFocusArea(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ✅ منطقة التحكم السفلية
              _buildBottomArea(),
            ],
          ),
        ),
      ),
    );
  }
}