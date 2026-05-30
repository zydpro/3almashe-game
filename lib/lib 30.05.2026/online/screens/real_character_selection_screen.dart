import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/game_data_service.dart';
import '../animation/animation_manager.dart';
import '../models/online_character_system.dart';
import '../services/p2p_connection_service.dart';
import '../services/real_player_matchmaking.dart';
import 'online_game_screen.dart';

class RealCharacterSelectionScreen extends StatefulWidget {
  final String gameMode;
  final String matchId;
  final Map<String, dynamic> matchData;
  final bool is1v1;

  const RealCharacterSelectionScreen({
    super.key,
    required this.gameMode,
    required this.matchId,
    required this.matchData,
    this.is1v1 = true,
  });

  @override
  State<RealCharacterSelectionScreen> createState() => _RealCharacterSelectionScreenState();
}

class _RealCharacterSelectionScreenState extends State<RealCharacterSelectionScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<OnlineCharacter> _availableCharacters = [];
  OnlineCharacter? _selectedCharacter;
  bool _isLoading = true;
  bool _isReady = false;
  bool _isOpponentReady = false;
  int _countdown = 5;
  Timer? _countdownTimer;
  StreamSubscription? _matchSubscription;
  String _statusMessage = 'انتظر اختيار الشخصية...';
  String _userId = '';
  String _userName = '';

  String _actualPlayerId = '';
  bool _isGuestPlayer = false;

  Map<String, dynamic>? _opponentData;
  String _opponentName = 'الخصم';
  OnlineCharacter? _opponentCharacter;
  bool _hasOpponentJoined = false;

  bool _gameStarted = false;
  final String _collectionName = 'real_matches_fixed';
  bool _isUpdatingReady = false;
  Timer? _readyStatusTimer;

  int _selectionTimer = 10;
  Timer? _selectionTimerTimer;
  bool _showNotification = false;
  String _notificationMessage = '';
  Timer? _notificationTimer;
  bool _isTimerExpired = false;

  // Animation controllers
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initializeData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _identifyCurrentPlayer();
      _startMatchListener();
      _startSelectionTimer();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _matchSubscription?.cancel();
    _readyStatusTimer?.cancel();
    _selectionTimerTimer?.cancel();
    _notificationTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _identifyCurrentPlayer() async {
    final players = widget.matchData['players'] as List<dynamic>? ?? [];
    String currentUserId = await getStableGuestId();

    bool found = false;

    for (var player in players) {
      final p = player as Map<String, dynamic>;
      final playerId = p['playerId'] as String;

      if (playerId == currentUserId) {
        _actualPlayerId = playerId;
        _isGuestPlayer = true;
        found = true;
        break;
      }
    }

    if (!found && players.isNotEmpty) {
      final firstPlayer = players.first as Map<String, dynamic>;
      _actualPlayerId = firstPlayer['playerId'] as String;
    }
  }

  void _initializeData() async {
    try {
      final user = _auth.currentUser;
      _userId = user?.uid ?? 'guest_${DateTime.now().millisecondsSinceEpoch}';
      _userName = user?.displayName ?? 'ضيف';

      await _loadAvailableCharacters();
      _startMatchListener();
    } catch (e) {
      setState(() {
        _statusMessage = 'خطأ في الاتصال';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAvailableCharacters() async {
    try {
      final allCharacters = OnlineCharacter.getAllOnlineCharacters();
      final ownedCharactersData = await GameDataService.getOwnedCharacters();
      final ownedCharacterIds = ownedCharactersData.map((c) => c.id).toSet();

      setState(() {
        _availableCharacters = allCharacters.map((character) {
          return OnlineCharacter(
            id: character.id,
            name: character.name,
            nameEn: character.nameEn,
            type: character.type,
            imagePath: character.imagePath,
            iconPath: character.iconPath,
            isLocked: !ownedCharacterIds.contains(character.id),
            price: character.price,
            primaryWeapon: character.primaryWeapon,
            secondaryWeapon: character.secondaryWeapon,
            specialAbility: character.specialAbility,
            specialAbilityCooldown: character.specialAbilityCooldown,
            characterColor: character.characterColor,
            animationConfigPath: character.animationConfigPath,
          );
        }).toList();

        _selectedCharacter = _availableCharacters.firstWhere(
              (char) => !char.isLocked,
          orElse: () => _availableCharacters.first,
        );

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'خطأ في تحميل الشخصيات';
        _isLoading = false;
      });
    }
  }

  void _startMatchListener() {
    _matchSubscription?.cancel();

    _matchSubscription = _firestore
        .collection(_collectionName)
        .doc(widget.matchId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists || !mounted) return;
      final updatedData = snapshot.data() as Map<String, dynamic>;
      _handleMatchUpdate(updatedData);
    }, onError: (error) {
      print('❌ خطأ في تحديثات المباراة: $error');
    });
  }

  void _handleMatchUpdate(Map<String, dynamic> matchData) {
    try {
      final players = matchData['players'] as List<dynamic>? ?? [];

      bool foundCurrentPlayer = false;
      bool foundOpponent = false;

      for (var player in players) {
        final p = player as Map<String, dynamic>;
        final playerId = p['playerId'] as String;

        if (playerId == _actualPlayerId) {
          foundCurrentPlayer = true;
          final isPlayerReady = p['isReady'] == true;
          final characterId = p['character'] as String?;

          setState(() {
            _isReady = isPlayerReady;
            if (characterId != null && characterId.isNotEmpty && _selectedCharacter == null) {
              try {
                final charId = int.tryParse(characterId) ?? 0;
                final character = _availableCharacters.firstWhere(
                      (char) => char.id == charId,
                  orElse: () => OnlineCharacter.getDefaultCharacter(),
                );
                _selectedCharacter = character;
              } catch (e) {}
            }
          });
        } else {
          foundOpponent = true;
          final isOpponentReady = p['isReady'] == true;

          setState(() {
            _opponentData = p;
            _opponentName = p['playerName'] as String? ?? 'الخصم';
            _hasOpponentJoined = true;
            _isOpponentReady = isOpponentReady;

            final characterId = p['character'] as String?;
            if (characterId != null && characterId.isNotEmpty) {
              try {
                final charId = int.tryParse(characterId) ?? 0;
                final opponentChar = _availableCharacters.firstWhere(
                      (char) => char.id == charId,
                  orElse: () => OnlineCharacter.getDefaultCharacter(),
                );
                _opponentCharacter = opponentChar;
              } catch (e) {}
            }
          });
        }
      }

      if (!foundOpponent) {
        setState(() {
          _hasOpponentJoined = false;
          _isOpponentReady = false;
        });
      }

      if (!foundOpponent) {
        setState(() => _statusMessage = 'جاري انتظار الخصم...');
      } else if (_isReady && _isOpponentReady && !_gameStarted) {
        setState(() => _statusMessage = 'الجميع جاهز! بدء اللعبة...');
        _startCountdown();
        _selectionTimerTimer?.cancel();
      } else if (_isReady && !_isOpponentReady) {
        setState(() => _statusMessage = '✅ جاهز - انتظر الخصم');
      } else if (!_isReady && _isOpponentReady) {
        setState(() => _statusMessage = 'الخصم جاهز - اختر شخصيتك');
      } else {
        setState(() => _statusMessage = 'اختر شخصيتك ثم اضغط تأكيد');
      }
    } catch (e) {
      print('❌ خطأ في معالجة تحديث المباراة: $e');
    }
  }

  void _startCountdown() {
    if (_gameStarted) return;

    _countdownTimer?.cancel();
    _gameStarted = true;

    setState(() {
      _countdown = 5;
      _statusMessage = 'بدء اللعبة خلال $_countdown...';
    });

    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_countdown > 1) {
          _countdown--;
          _statusMessage = 'بدء اللعبة خلال $_countdown...';
        } else {
          timer.cancel();
          _statusMessage = 'بدء اللعبة الآن!';
          _startGame();
        }
      });
    });
  }

  void _startSelectionTimer() {
    _selectionTimer = 10;
    _isTimerExpired = false;

    _selectionTimerTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_selectionTimer > 0) {
          _selectionTimer--;

          if (_selectionTimer == 7 && !_isReady) {
            _showNotificationMessage('⚠️ لديك 3 ثواني متبقية للاختيار');
          }
        } else {
          timer.cancel();
          _isTimerExpired = true;

          if (!_isReady && mounted) {
            _selectRandomCharacter();
          }
        }
      });
    });
  }

  void _showNotificationMessage(String message) {
    setState(() {
      _showNotification = true;
      _notificationMessage = message;
    });

    _notificationTimer?.cancel();
    _notificationTimer = Timer(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showNotification = false;
        });
      }
    });
  }

  void _dismissNotification() {
    _notificationTimer?.cancel();
    setState(() {
      _showNotification = false;
    });
  }

  void _selectRandomCharacter() {
    if (_isReady) return;

    final unlockedCharacters = _availableCharacters.where((c) => !c.isLocked).toList();

    if (unlockedCharacters.isNotEmpty) {
      final random = Random();
      final randomChar = unlockedCharacters[random.nextInt(unlockedCharacters.length)];

      setState(() {
        _selectedCharacter = randomChar;
      });

      _updateReadyStatus();
      _showNotificationMessage('🎲 تم اختيار ${randomChar.name} عشوائياً');
    }
  }

  Future<void> _selectCharacter(OnlineCharacter character) async {
    if (character.isLocked) {
      _showElegantPurchaseDialog(character);
      return;
    }

    setState(() {
      _selectedCharacter = character;
    });
  }

  void _showElegantPurchaseDialog(OnlineCharacter character) {
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = screenSize.width * 0.65;
    final dialogHeight = screenSize.height * 0.48;

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 300),
            tween: Tween(begin: 0.8, end: 1.0),
            curve: Curves.easeOutCubic,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: dialogWidth,
                  height: dialogHeight,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        character.characterColor.withOpacity(0.3),
                        Color(0xFF1A1A2E).withOpacity(0.98),
                        character.characterColor.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: character.characterColor.withOpacity(0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: character.characterColor.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 1,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          physics: NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          character.characterColor.withOpacity(0.5),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 55,
                                    height: 55,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: character.characterColor,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: character.characterColor.withOpacity(0.6),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: Image.asset(
                                        character.iconPath,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                character.name,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      color: character.characterColor,
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 4),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: character.characterColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: character.characterColor.withOpacity(0.5),
                                  ),
                                ),
                                child: Text(
                                  character.type,
                                  style: TextStyle(
                                    color: character.characterColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    _buildCompactInfoRowSmall('السلاح الأساسي', character.primaryWeapon, Icons.minimize, character.characterColor),
                                    SizedBox(height: 6),
                                    _buildCompactInfoRowSmall('السلاح الثانوي', character.secondaryWeapon, Icons.shield, character.characterColor),
                                    SizedBox(height: 6),
                                    _buildCompactInfoRowSmall('القدرة الخاصة', character.specialAbility, Icons.flash_on, character.characterColor),
                                  ],
                                ),
                              ),
                              SizedBox(height: 10),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.amber.withOpacity(0.2),
                                      Colors.amber.withOpacity(0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.amber.withOpacity(0.5)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star, color: Colors.amber, size: 16),
                                    SizedBox(width: 6),
                                    Text(
                                      '${character.price}',
                                      style: TextStyle(
                                        color: Colors.amber,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(12, 4, 12, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'إلغاء',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                  _showNotificationMessage('✨ تم شراء ${character.name} بنجاح');
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        character.characterColor,
                                        character.characterColor.withOpacity(0.7),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: character.characterColor.withOpacity(0.5),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      'شراء',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCompactInfoRowSmall(String label, dynamic value, IconData icon, Color characterColor) {
    String displayValue = '';

    if (value == null) {
      displayValue = 'غير محدد';
    } else if (value is String) {
      displayValue = value;
    } else if (value is OnlineWeaponType) {
      switch (value) {
        case OnlineWeaponType.sword:
          displayValue = 'سيف';
          break;
        case OnlineWeaponType.bow:
          displayValue = 'قوس';
          break;
        case OnlineWeaponType.staff:
          displayValue = 'عصا';
          break;
        case OnlineWeaponType.dagger:
          displayValue = 'خنجر';
          break;
        case OnlineWeaponType.axe:
          displayValue = 'فأس';
          break;
        case OnlineWeaponType.spear:
          displayValue = 'رمح';
          break;
        case OnlineWeaponType.hammer:
          displayValue = 'مطرقة';
          break;
        default:
          displayValue = value.toString().split('.').last;
      }
    } else {
      displayValue = value.toString();
    }

    return Row(
      children: [
        Icon(icon, color: characterColor.withOpacity(0.8), size: 12),
        SizedBox(width: 6),
        Text(
          '$label:',
          style: TextStyle(color: Colors.white70, fontSize: 10),
        ),
        SizedBox(width: 4),
        Expanded(
          child: Text(
            displayValue,
            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> _updateReadyStatus() async {
    if (_selectedCharacter == null) {
      _showNotificationMessage('❌ اختر شخصية أولاً');
      return;
    }

    if (_isUpdatingReady) return;

    setState(() => _isUpdatingReady = true);

    try {
      final matchRef = _firestore.collection(_collectionName).doc(widget.matchId);
      final doc = await matchRef.get();

      if (!doc.exists) throw Exception('المباراة غير موجودة');

      final data = doc.data() as Map<String, dynamic>;
      final players = List<Map<String, dynamic>>.from(data['players'] ?? []);

      final updatedPlayers = players.map((player) {
        if (player['playerId'] == _actualPlayerId) {
          return {
            ...player,
            'character': _selectedCharacter!.id.toString(),
            'isReady': true,
            'readyAt': DateTime.now().millisecondsSinceEpoch,
          };
        }
        return player;
      }).toList();

      await matchRef.update({
        'players': updatedPlayers,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      setState(() {
        _isReady = true;
        _isUpdatingReady = false;
      });

      _showNotificationMessage('✅ أنت جاهز! انتظر الخصم');
    } catch (e) {
      setState(() => _isUpdatingReady = false);
      _showNotificationMessage('❌ فشل التحديث، حاول مرة أخرى');
    }
  }

  Future<void> _startGame() async {
    if (_selectedCharacter == null) return;

    if (mounted) {
      Map<String, dynamic> opponentMap = {
        'playerId': _opponentData?['playerId'] ?? 'unknown_opponent',
        'playerName': _opponentName,
        'character': _opponentCharacter ?? OnlineCharacter.getDefaultCharacter(),
        'isBot': false,
        'isRealPlayer': true,
      };

      String platformPattern = widget.matchData['platformPattern'] ?? 'كلاسيكي';
      String background = widget.matchData['background'] ?? 'forest.png';
      opponentMap['background'] = background;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OnlineGameScreen(
            playerCharacter: _selectedCharacter!,
            opponent: opponentMap,
            roomId: widget.matchId,
            isQuickMatch: false,
            connectionService: P2PConnectionService(),
            gameMode: widget.gameMode,
            platformPattern: platformPattern,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0F),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1A1A2E),
                  Color(0xFF0A0A0F),
                  Color(0xFF0F0F1A),
                ],
                stops: [0.0, 0.7, 1.0],
              ),
            ),
          ),
          ...List.generate(20, (index) {
            return Positioned(
              left: Random().nextDouble() * MediaQuery.of(context).size.width,
              top: Random().nextDouble() * MediaQuery.of(context).size.height,
              child: Container(
                width: 2,
                height: 2,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
          SafeArea(
            child: Column(
              children: [
                _buildElegantHeader(),
                SizedBox(height: 8),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 90,
                        child: _buildElegantPlayerSide(
                          isCurrentPlayer: true,
                          playerName: _userName,
                          character: _selectedCharacter,
                          isReady: _isReady,
                          hasJoined: true,
                        ),
                      ),
                      Expanded(
                        child: _isLoading
                            ? _buildLoadingWidget()
                            : Center(
                          child: SingleChildScrollView(
                            physics: NeverScrollableScrollPhysics(),
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: _buildElegantCharacterGrid(),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 90,
                        child: _buildElegantPlayerSide(
                          isCurrentPlayer: false,
                          playerName: _opponentName,
                          character: _opponentCharacter,
                          isReady: _isOpponentReady,
                          hasJoined: _hasOpponentJoined,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBar(),
              ],
            ),
          ),
          if (_showNotification)
            Positioned(
              top: 100,
              left: 20,
              right: 20,
              child: _buildElegantNotification(),
            ),
        ],
      ),
    );
  }

  Widget _buildElegantHeader() {
    return Container(
      height: 60,
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'اختر شخصيتك',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  shadows: [
                    Shadow(
                      color: Colors.blue.withOpacity(0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              if (!_isReady && _hasOpponentJoined)
                Container(
                  margin: EdgeInsets.only(top: 2),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _selectionTimer <= 3
                          ? [Colors.red.withOpacity(0.3), Colors.red.withOpacity(0.1)]
                          : [Colors.amber.withOpacity(0.3), Colors.amber.withOpacity(0.1)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _selectionTimer <= 3 ? Colors.red : Colors.amber,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer,
                        color: _selectionTimer <= 3 ? Colors.red : Colors.amber,
                        size: 12,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '$_selectionTimer ثانية',
                        style: TextStyle(
                          color: _selectionTimer <= 3 ? Colors.red : Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber.withOpacity(0.2),
                  Colors.amber.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: Text(
              widget.gameMode == '1v1' ? '⚔️ 1v1' : '⚔️ 2v2',
              style: TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElegantPlayerSide({
    required bool isCurrentPlayer,
    required String playerName,
    required OnlineCharacter? character,
    required bool isReady,
    required bool hasJoined,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: isCurrentPlayer ? Alignment.topLeft : Alignment.topRight,
          end: Alignment.bottomCenter,
          colors: [
            (isCurrentPlayer ? Colors.blue : Colors.red).withOpacity(0.15),
            Colors.transparent,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isReady
              ? Colors.green.withOpacity(0.5)
              : (isCurrentPlayer ? Colors.blue : Colors.red).withOpacity(0.3),
          width: isReady ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Spacer(),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      (character?.characterColor ?? Colors.grey).withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: character?.characterColor ?? Colors.grey,
                    width: 1.5,
                  ),
                ),
                child: character != null
                    ? ClipOval(
                  child: Image.asset(
                    character.iconPath,
                    fit: BoxFit.cover,
                  ),
                )
                    : Container(
                  color: Colors.grey[800],
                  child: Icon(
                    Icons.person_outline,
                    color: Colors.white38,
                    size: 24,
                  ),
                ),
              ),
              if (isReady)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Icon(Icons.check, color: Colors.white, size: 10),
                  ),
                ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            isCurrentPlayer ? 'أنت' : (playerName.length > 8 ? '${playerName.substring(0, 7)}...' : playerName),
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 6),
          if (character != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: character.characterColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                character.name.length > 6 ? '${character.name.substring(0, 5)}...' : character.name,
                style: TextStyle(
                  color: character.characterColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (character == null && hasJoined)
            Text(
              'يختار...',
              style: TextStyle(color: Colors.white38, fontSize: 9),
            ),
          if (!hasJoined && !isCurrentPlayer)
            Text(
              'في الانتظار',
              style: TextStyle(color: Colors.amber, fontSize: 9),
            ),
          Spacer(),
        ],
      ),
    );
  }

  Widget _buildElegantCharacterGrid() {
    return Container(
      constraints: BoxConstraints(
        maxHeight: 280, // تقليل أقصى ارتفاع
      ),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6, // تغيير من 3 إلى 6 شخصيات في كل صف
          crossAxisSpacing: 6, // مسافة أفقية بين المربعات
          mainAxisSpacing: 6, // مسافة عمودية بين المربعات
          childAspectRatio: 0.9, // نسبة العرض إلى الارتفاع
        ),
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: _availableCharacters.length,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemBuilder: (context, index) {
          final character = _availableCharacters[index];
          final isSelected = _selectedCharacter?.id == character.id;

          return GestureDetector(
            onTap: () => _selectCharacter(character),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    character.characterColor.withOpacity(isSelected ? 0.4 : 0.15),
                    character.characterColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? character.characterColor
                      : Colors.white.withOpacity(0.1),
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: character.characterColor.withOpacity(0.4),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ] : null,
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // صورة صغيرة جداً
                        Container(
                          width: 32, // تصغير الصورة
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: character.characterColor.withOpacity(0.5),
                              width: 1.5,
                            ),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              character.iconPath,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(height: 4),
                        // اسم الشخصية (مختصر)
                        Text(
                          character.name.length > 6 ? '${character.name.substring(0, 5)}.' : character.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2),
                        // نوع الشخصية (مختصر)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            character.type.length > 4 ? '${character.type.substring(0, 3)}.' : character.type,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 7,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // قفل للشخصيات المقفلة
                  if (character.isLocked)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.black.withOpacity(0.8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock, color: Colors.amber, size: 14),
                            SizedBox(height: 2),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star, color: Colors.amber, size: 8),
                                  SizedBox(width: 2),
                                  Text(
                                    '${character.price}',
                                    style: TextStyle(
                                      color: Colors.amber,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // علامة الاختيار
                  if (isSelected && !character.isLocked)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Icon(Icons.check, color: Colors.white, size: 8),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            strokeWidth: 2.5, // تقليل سمك الدائرة
          ),
          SizedBox(height: 12), // تقليل المسافة
          Text(
            'جاري تحميل الشخصيات...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12, // تقليل الخط من 14 إلى 12
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      margin: EdgeInsets.all(12),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1E1E2E).withOpacity(0.9),
            Color(0xFF0A0A1A).withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: _isReady && _isOpponentReady
              ? Colors.green.withOpacity(0.3)
              : Colors.blue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          if (_countdown > 0 && _isReady && _isOpponentReady)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.red, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '$_countdown',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          if (_countdown > 0 && _isReady && _isOpponentReady)
            SizedBox(width: 8),
          Expanded(
            child: Text(
              _statusMessage,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 70,
            height: 32,
            child: ElevatedButton(
              onPressed: _isReady || _selectedCharacter == null ? null : _updateReadyStatus,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isReady ? Colors.green : Colors.blue,
                disabledBackgroundColor: Colors.grey[800],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: EdgeInsets.zero,
                elevation: _isReady ? 0 : 3,
              ),
              child: Text(
                _isReady ? 'جاهز' : 'تأكيد',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElegantNotification() {
    return GestureDetector(
      onTap: _dismissNotification,
      onHorizontalDragEnd: (_) => _dismissNotification(),
      child: TweenAnimationBuilder<double>(
        duration: Duration(milliseconds: 300),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF2A2A3A).withOpacity(0.95),
                    Color(0xFF1A1A2A).withOpacity(0.95),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _notificationMessage.contains('✅')
                      ? Colors.green.withOpacity(0.5)
                      : _notificationMessage.contains('⚠️')
                      ? Colors.orange.withOpacity(0.5)
                      : _notificationMessage.contains('❌')
                      ? Colors.red.withOpacity(0.5)
                      : Colors.blue.withOpacity(0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _notificationMessage.contains('✅')
                          ? Colors.green.withOpacity(0.2)
                          : _notificationMessage.contains('⚠️')
                          ? Colors.orange.withOpacity(0.2)
                          : _notificationMessage.contains('❌')
                          ? Colors.red.withOpacity(0.2)
                          : Colors.blue.withOpacity(0.2),
                    ),
                    child: Icon(
                      _notificationMessage.contains('✅') ? Icons.check_circle :
                      _notificationMessage.contains('⚠️') ? Icons.warning_amber_rounded :
                      _notificationMessage.contains('❌') ? Icons.error :
                      _notificationMessage.contains('🎲') ? Icons.casino :
                      Icons.info,
                      color: _notificationMessage.contains('✅') ? Colors.green :
                      _notificationMessage.contains('⚠️') ? Colors.orange :
                      _notificationMessage.contains('❌') ? Colors.red :
                      _notificationMessage.contains('🎲') ? Colors.amber :
                      Colors.blue,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _notificationMessage,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.close,
                    color: Colors.white54,
                    size: 18,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}