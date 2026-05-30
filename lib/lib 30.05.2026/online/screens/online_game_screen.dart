import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/game_data_service.dart';
import '../animation/advanced_animation_system.dart';
import '../animation/animation_loader.dart';
import '../animation/animation_manager.dart';
import '../models/online_character_system.dart';
import '../services/ai_bot_service.dart';
import '../services/livekit/latency_compensator.dart';
import '../services/livekit/livekit_service.dart';
import '../services/livekit/smooth_movement.dart';
import '../services/online_game_service.dart';
import '../services/p2p_connection_service.dart';
import '../services/online_audio_service.dart';
import '../services/real_player_matchmaking.dart' as GuestIdService;
import '../services/screen_orientation_service.dart';
import '../services/sync_service.dart';
import '../services/user_data_service.dart';
import 'online_characters_screen.dart';
import 'online_lobby_screen.dart';
import 'online_store_screen.dart';

class OnlineGameScreen extends StatefulWidget {
  final OnlineCharacter playerCharacter;
  final Map<String, dynamic> opponent;
  final String roomId;
  final bool isQuickMatch;
  final P2PConnectionService connectionService;
  final String? gameMode;
  final List<Map<String, dynamic>>? opponentsData;
  final String? platformPattern;

  const OnlineGameScreen({
    super.key,
    required this.playerCharacter,
    required this.opponent,
    required this.roomId,
    required this.isQuickMatch,
    required this.connectionService,
    this.gameMode = '1v1',
    this.opponentsData,
    this.platformPattern,
  });

  @override
  State<OnlineGameScreen> createState() => _OnlineGameScreenState();
}

class _OnlineGameScreenState extends State<OnlineGameScreen> with TickerProviderStateMixin {
  // ✅ المتغيرات الأساسية
  late OnlineGameService _gameService = OnlineGameService.instance;
  late AnimationController _gameLoopController;
  Map<String, dynamic> _gameState = {};
  late SmartCameraSystem _cameraSystem;
  StreamSubscription? _weaponSubscription; // ⭐ أضف هذا
  StreamSubscription? _platformSubscription; // ⭐ جديد
  Timer? _playerPresenceTimer; // ⭐ جديد
  Map<String, int> _lastPresenceTime = {};
  String _userId = '';
  // ✅ إضافة متغير لمنع تصحيح الموقع بعد القفز مباشرة
  Map<String, bool> _justJumped = {'local': false, 'remote': false};
  Map<String, int> _jumpFrameLock = {'local': 0, 'remote': 0};

  // ✅ النظام الجديد للاهتزاز والتوهج
  Timer? _weaponVibrationTimer;  // ⭐ أضف هذا السطر هنا
  // ✅ نظام البوت الذكي
  AIBotService? _aiBotService;
  bool _isBotGame = false;
  String _currentBackground = '';
  bool _backgroundLoaded = false;
  // ✅ حدود الخريطة
  double _mapWidth = 6.0;
  double _mapHeight = 4.0;
  double _mapLeftBound = -3.0;
  double _mapRightBound = 3.0;
  double _mapBottomBound = 4.0;
  double _groundLevel = 0.9;
  // ✅ حالة اللعبة
  bool _isGameEnded = false;
  bool _isPaused = false;
  String? _winnerName;

  // ✅ أنظمة اللاعبين
  Map<String, int> _playerLives = {'local': 3, 'remote': 3};
  Map<String, int> _respawnCooldown = {'local': 0, 'remote': 0};
  Map<String, bool> _playerIsRespawning = {'local': false, 'remote': false};
  Map<String, bool> _showKOEffect = {'local': false, 'remote': false};
  String _localPlayerName = 'اللاعب';
  String _remotePlayerName = 'الخصم';

  // ✅ نظام الأسلحة
  List<Map<String, dynamic>> _weaponsOnGround = [];
  int _maxWeaponsOnGround = 3;
  Map<String, int> _weaponAmmo = {};
  String? _currentAmmoWeaponId;
  bool _showAmmoCounter = false;

  // ✅ التحكم باللمس
  Offset? _continuousDragPosition;
  Offset? _startDragPosition;
  bool _isDragging = false;
  double _playerSpeed = 0.025;
  double _controlSensitivity = 1.5;
  double _moveDeadZone = 0.015;
  double _jumpSensitivity = 0.6;

  // ✅ القفز والمناورة
  bool _canDoubleJump = true;
  bool _hasDoubleJumped = false;
  Map<String, bool> _playerHasDoubleJumped = {'local': false, 'remote': false};

  // ✅ إشعارات اللعبة
  List<GameNotification> _activeNotifications = [];
  bool _isNotificationVisible = false;
  Map<String, bool> _shownNotificationIds = {};
  Timer? _notificationTimer;

  // ✅ المؤقتات
  Timer? _movementTimer;
  Timer? _weaponSpawnTimer;
  Timer? _weaponCleanupTimer;
  Timer? _gameEndTimer;
  Timer? _pauseTimer;
  Timer? _fallDeathTimer;
  Timer? _doubleJumpResetTimer;
  Timer? _comboResetTimer;

  // ✅ التأثيرات البصرية
  List<Map<String, dynamic>> _visualEffects = [];
  List<Map<String, dynamic>> _thrownWeapons = [];
  Map<String, double> _weaponBounceOffsets = {};
  Map<String, double> _weaponBounceDirections = {};
  Timer? _weaponBounceTimer;

  // ✅ نظام المبارزة
  Map<String, int> _consecutiveHits = {'local': 0, 'remote': 0};
  bool _canPunch = true;
  double _punchDamage = 10.0;
  Timer? _punchCooldownTimer;

  // ✅ الرسوم المتحركة
  Map<String, double> _playerSmoothX = {};
  Map<String, double> _playerSmoothY = {};
  Map<String, double> _playerTargetX = {};
  Map<String, double> _playerTargetY = {};

  // ✅ إضافة متغيرات جديدة للاهتزاز والتوهج
  Map<String, double> _weaponVibrationOffsets = {};
  Map<String, double> _weaponGlowIntensities = {};
  Map<String, Timer> _weaponVibrationTimers = {};
  // ✅ متغيرات النظام
  static const bool DEBUG_MODE = false;
  bool _showTutorial = true;
  int _frameCounter = 0;
  int _systemCheckCounter = 0;
  int _monitoringCounter = 0;
  int _lastAttackHash = 0;
  int _lastAttackTime = 0;

  // في أعلى الكلاس، مع المتغيرات الأخرى
  Map<String, int> _lastProcessedAttackTimes = {}; // لتتبع آخر ضربة تمت معالجتها لكل خصم
  // ✅ إضافة المتغيرات المفقودة
  Map<String, double> _weaponRotation = {};
  Map<String, int> _playerFallStartY = {'local': 0, 'remote': 0};
  int _playerWeaponUses = 0;

  Map<String, int> _lastKOTime = {'local': 0, 'remote': 0};
  Map<String, dynamic> _correctedWeaponsData = {};
  // ✅ النظام الجديد للمنصات العشوائية
  PlatformPattern? _currentPlatformPattern;
  List<BattlePlatform> _randomPlatforms = [];
  List<Map<String, dynamic>> _strategicGaps = [];
  Color _currentPlatformPrimaryColor = Color(0xFF8B4513);
  Color _currentPlatformSecondaryColor = Color(0xFF654321);
  String _platformPatternName = 'كلاسيكي';
  bool _showPlatformPatternNotification = false;
  Timer? _patternNotificationTimer;

  // ✅ إضافة متغيرات للانتربوليشين
  Map<String, Offset> _targetPositions = {};
  Map<String, DateTime> _lastPositionUpdate = {};
  Map<String, double> _interpolationSpeed = {'local': 0.2, 'remote': 0.15}; // أبطأ للخصم

  // ✅ متغيرات جديدة للأسلحة المسقطة
  Map<String, List<Map<String, dynamic>>> _droppedWeapons = {
    'local': [],
    'remote': [],
  };
  // ✅ أضف هذه المتغيرات الجديدة
  bool _isRealPlayerMatch = false;
  String? _opponentId;
  StreamSubscription? _gameStateSubscription;
  Timer? _syncTimer;
  SyncService _syncService = SyncService();

  Map<String, List<double>> _positionHistory = {
    'local': [],
    'remote': [],
  };
  Map<String, DateTime> _lastUpdateTime = {};
  double _compensatedGameTime = 0;
  int _lastServerTimestamp = 0;
  int _lastWeaponSyncTime = 0;
  Timer? _weaponFallbackTimer;
  bool _hasReceivedWeapons = false;
  int _gameStartTime = 0;
  int _gameStartTimestamp = 0;
  int _gameEndTimestamp = 0;
  bool _hasShownResults = false;
  int _lastTimeSync = 0;
  bool _isGameEnding = false;
  int _lastMovementTime = 0;
  bool _isMatchInitialized = false;
  bool _isMatchStarted = false;
  static const int MOVEMENT_INTERVAL = 16; // ~60 FPS
  bool _isHost = false;
  Timer? _startMatchTimer;
  bool _hasStartedMatch = false; // لمنع المحاولات المتكررة
  String _currentUserId = '';
  bool _allPlayersReady = false; // لتتبع جاهزية جميع اللاعبين
  bool _gameFullyStarted = false; // ⭐ متغير جديد للتأكد من بدء اللعبة بالكامل
  // ✅ نظام منع التكدس
  final Map<String, int> _attackCountByPosition = {}; // عدد الهجمات في نفس الموقع
  final Set<String> _processedAttackHashes = {}; // الهجمات المعالجة
  Timer? _attackCleanupTimer;
  int _maxAttacksPerPosition = 3; // الحد الأقصى للهجمات في نفس الموقع
  int _lastAttackSendTime = 0;
  static const int MIN_ATTACK_INTERVAL = 300; // 300ms بين الهجمات
  // ✅ متغير جديد لتتبع اشتراك حالة المباراة
  StreamSubscription<DocumentSnapshot>? _matchStatusSubscription;
  // ✅ متغير لمنع المعالجة المزدوجة لنهاية اللعبة
  // ✅ إضافة متغير لمنع التوليد المتكرر
  bool _isSpawningWeapons = false;

  // ✅ خدمات LiveKit الجديدة
  final LiveKitGameService _liveKitService = LiveKitGameService();
  final SmoothMovementController _smoothMovement = SmoothMovementController();
  final LatencyCompensator _latencyCompensator = LatencyCompensator();

  // ✅ متغيرات التوقيت
  int _lastLiveKitSendTime = 0;
  static const int LIVEKIT_SEND_INTERVAL_MS = 33; // 30 مرة في الثانية
  bool _useLiveKit = true; // يمكنك تغييره إلى false لاستخدام Firebase بدلاً من LiveKit

  @override
  void initState() {
    super.initState();

    _getCurrentUserId().then((id) {
      _userId = id;
      _continueInitialization();
      // ✅ الاتصال بـ LiveKit
      _connectToLiveKit();

      // ✅ ✅ ✅ ترتيب التهيئة مهم جداً
      Future.delayed(Duration(milliseconds: 100), () {
        if (mounted) {
          // فقط تهيئة المستمعين هنا - مرة واحدة فقط
          _initializeAllListeners();
          // تهيئة نظام تنظيف الهجمات
          _initializeAttackCleanup();
          print('✅ [INIT] تم تهيئة جميع الأنظمة');
        }
      });
    });
  }

// ✅ دالة لتهيئة جميع المستمعين - نسخة محسنة
  void _initializeAllListeners() {
    if (!_isRealPlayerMatch) {
      print('📡 [INIT] هذه ليست مباراة حقيقية، تخطي تهيئة المستمعين');
      return;
    }

    print('📡 [INIT] تهيئة جميع المستمعين للمباراة: ${widget.roomId}');

    // ✅ 1. تعيين callback للهجمات - مهم جداً
    _syncService.setAttacksCallback((attacks) {
      print('📢 [CALLBACK] استلام ${attacks.length} هجوم من SyncService');
      _processAttacksFromFirebase(attacks);
    });

    // ✅ 2. بدء الاستماع للهجمات
    _syncService.listenToAttacks((attacks) {
      print('👂 [LISTENER] استلام هجمات من المستمع');
      _processAttacksFromFirebase(attacks);
    });

    // ✅ 3. الاستماع للأسلحة
    _listenToWeaponUpdates();

    // ✅ 4. الاستماع للمنصات (مهم للضيف)
    _listenToPlatformUpdates();

    // ✅ 5. الاستماع لحالة المباراة
    _listenToMatchStatus();

    // ✅ 6. بدء مراقبة الوجود
    _startPresenceMonitoring();

    // ✅ 7. تأكيد أن المستمعات تعمل
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        print('✅ [INIT] تأكيد: جميع المستمعات نشطة');
        _debugCheckListeners();
      }
    });

    print('✅ [INIT] تم تهيئة جميع المستمعين بنجاح');
  }


  // ✅ دالة اختبار لعرض هجوم تجريبي
  void _testShowAttack() {
    final testAttack = {
      'type': 'OnlineAttackType.light',
      'x': 0.5,
      'y': 0.5,
      'directionX': 1.0,
      'damage': 10,
      'weaponImagePath': 'assets/online/weapons/sword.png',
      'playerId': 'test',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    _createAndShowAttack(testAttack);
    print('🔧 [DEBUG] تم إنشاء هجوم تجريبي');
  }

// ✅ دالة محدثة لمواصلة التهيئة بعد الحصول على userId
  void _continueInitialization() {
    // ✅ بعد التأكد من المستخدم، أكمل التهيئة
    _initializeGameSystems();
    _initializeBackgroundSystem();

    // ✅ التحقق مما إذا كانت هذه مباراة حقيقية
    _isRealPlayerMatch = widget.opponent['isRealPlayer'] == true ||
        widget.opponent['isBot'] != true;
    // ✅ تخزين معرف المستخدم الحالي
    _currentUserId = _userId;
    // ✅ تحديد المضيف بشكل صحيح - دالة واحدة فقط
    _determineHostStatus();
    // ✅ ✅ ✅  توليد المنصات قبل أي شيء
    _generateRandomPlatformPattern();

    if (_isRealPlayerMatch) {
      print('🎮 [ONLINE] مباراة ضد لاعب حقيقي!');
      _opponentId = widget.opponent['playerId'] as String?;

      // ✅ بدء SyncService للجميع
      _syncService.startSync(
        matchId: widget.roomId,
        isHost: _isHost,
      );

      // ✅ بدء الاستماع لحالة المباراة فوراً
      _listenToMatchStatus();

      // ✅ الاستماع لنهاية اللعبة
      _listenToGameEnd();

      // ✅ مراقبة انقطاع اللاعبين
      _startPresenceMonitoring();

      // ✅ التحقق الدوري من وجود الخصم
      _checkOpponentPresence();

      // ✅ تحديث يدوي بعد ثانيتين
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          _debugForceRefreshWeapons();
          if (_gameService.remotePlayer == null && _opponentId != null) {
            print('⚠️ [DELAYED] الخصم لا يزال غير موجود، محاولة إنشائه...');
            _createOpponentIfNeeded();
          }
        }
      });

    } else {
      print('🤖 [BOT] مباراة ضد بوت');
      setState(() {
        _isMatchStarted = true;
      });
    }

    // ✅ تهيئة جميع المصفوفات
    _initializeGameMaps();

    // ✅ إرسال الحالة الأولية للاعب
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isRealPlayerMatch && mounted) {
        Future.delayed(Duration(milliseconds: 500), () {
          _syncPlayerState();
          print('📤 تم إرسال الحالة الأولية للاعب');
        });
      }
    });

    // ✅ ✅ ✅ بدء المباراة تلقائياً - نسخة واحدة فقط
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isRealPlayerMatch && mounted) {
        Future.delayed(Duration(milliseconds: 1000), () {
          _checkAndStartGameAutomatically();
        });
      }
    });

    _debugCheckListeners();
  }

// ✅ دالة لتهيئة جميع المصفوفات (Maps)
  void _initializeGameMaps() {
    // التأكد من أن جميع المصفوفات مهيئة بشكل صحيح
    if (_playerLives.isEmpty) {
      _playerLives = {'local': 3, 'remote': 3};
    }
    if (_respawnCooldown.isEmpty) {
      _respawnCooldown = {'local': 0, 'remote': 0};
    }
    if (_playerIsRespawning.isEmpty) {
      _playerIsRespawning = {'local': false, 'remote': false};
    }
    if (_showKOEffect.isEmpty) {
      _showKOEffect = {'local': false, 'remote': false};
    }
    if (_playerHasDoubleJumped.isEmpty) {
      _playerHasDoubleJumped = {'local': false, 'remote': false};
    }
    if (_consecutiveHits.isEmpty) {
      _consecutiveHits = {'local': 0, 'remote': 0};
    }
    if (_droppedWeapons.isEmpty) {
      _droppedWeapons = {'local': [], 'remote': []};
    }
    if (_playerSmoothX.isEmpty) {
      _playerSmoothX = {'local': 0.0, 'remote': 0.0};
    }
    if (_playerSmoothY.isEmpty) {
      _playerSmoothY = {'local': 0.0, 'remote': 0.0};
    }
    if (_playerTargetX.isEmpty) {
      _playerTargetX = {'local': 0.0, 'remote': 0.0};
    }
    if (_playerTargetY.isEmpty) {
      _playerTargetY = {'local': 0.0, 'remote': 0.0};
    }
    if (_playerFallStartY.isEmpty) {
      _playerFallStartY = {'local': 0, 'remote': 0};
    }
    if (_lastKOTime.isEmpty) {
      _lastKOTime = {'local': 0, 'remote': 0};
    }
    if (_lastProcessedAttackTimes.isEmpty) {
      _lastProcessedAttackTimes = {};
    }
    if (_weaponRotation.isEmpty) {
      _weaponRotation = {};
    }

    print('✅ [INIT] تم تهيئة جميع المصفوفات بنجاح');
  }

// ✅ دالة جديدة لتحديد حالة المضيف
  void _determineHostStatus() {
    print('🔍 [HOST] بدء تحديد المضيف');
    print('   _currentUserId=$_currentUserId');
    print('   _userId=$_userId');

    // استخدام معرف المضيف من الـ widget إذا كان موجوداً
    final hostId = widget.opponent['hostId'] as String?;
    print('   hostId من opponent=$hostId');

    _isHost = (hostId == _currentUserId);
    print('   بعد المقارنة: _isHost=$_isHost');

    // إذا لم يكن hostId موجوداً، استخدم الطريقة القديمة كنسخة احتياطية
    if (!_isHost && widget.opponent.containsKey('players')) {
      print('   🔍 البحث في players...');
      final playersList = widget.opponent['players'] as List?;
      if (playersList != null && playersList.isNotEmpty) {
        final firstPlayer = playersList.first as Map<String, dynamic>;
        final creatorId = firstPlayer['playerId'] as String;
        print('   creatorId=$creatorId');
        _isHost = (creatorId == _currentUserId);
        print('   بعد المقارنة: _isHost=$_isHost');
      }
    }

    // إذا ما زال غير معروف، اعتبر اللاعب الأول هو المضيف (يحدث مرة واحدة فقط)
    if (!_isHost && _userId == _gameService.localPlayer?.playerId) {
      print('   🔍 استخدام الحل الأخير');
      _isHost = true; // حل أخير
      print('   بعد الحل الأخير: _isHost=$_isHost');
    }

    print('🎮 [HOST] النتيجة النهائية: أنا المضيف: $_isHost');
  }

// ✅ ✅ ✅ دالة معدلة - بدون حلقة لا نهائية
  void _checkAndStartGameAutomatically() {
    if (!_isRealPlayerMatch || _isMatchStarted || _gameFullyStarted) return;

    print('🤖 [AUTO] التحقق من إمكانية بدء المباراة...');

    // ✅ التحقق من وجود كلا اللاعبين
    if (_gameService.localPlayer != null && _gameService.remotePlayer != null) {
      print('✅ [AUTO] كلا اللاعبين موجودين - بدء المباراة تلقائياً');

      setState(() {
        _isMatchStarted = true;
        _gameFullyStarted = true;
        _gameService.gameTimer = 120.0;
      });

      // ✅ بدء أنظمة اللعبة
      _syncGameStart();

      // ✅ تحديث Firebase إذا كنا المضيف
      if (_isHost) {
        _forceUpdateFirebaseStatus();
      }

      _showGameNotification(
        id: 'auto_start',
        message: 'بدأت المباراة!',
        color: Colors.green,
        icon: Icons.play_arrow,
        durationSeconds: 2,
      );
    } else {
      print('⚠️ [AUTO] في انتظار اللاعبين...');
      print('   localPlayer: ${_gameService.localPlayer != null}');
      print('   remotePlayer: ${_gameService.remotePlayer != null}');

      // ✅ محاولة واحدة فقط بعد ثانية - لا تكرار!
      Future.delayed(Duration(seconds: 1), () {
        if (mounted && !_isMatchStarted) {
          _checkAndStartGameAutomatically();
        }
      });
    }
    // ❌ تم إزالة النداء المتكرر داخل addPostFrameCallback
  }

  // ✅ ✅ ✅ دالة تحديث Firebase (مأخوذة من زر FORCE)
  Future<void> _forceUpdateFirebaseStatus() async {
    try {
      await FirebaseFirestore.instance
          .collection('real_matches_fixed')
          .doc(widget.roomId)
          .update({
        'status': 'playing',
        'gameStartTime': DateTime.now().millisecondsSinceEpoch,
        'gameTime': 120.0,
        'matchStarted': true,
        'lastSync': DateTime.now().millisecondsSinceEpoch,
      });
      print('✅ تم تحديث حالة المباراة في Firebase إلى playing');
    } catch (e) {
      print('⚠️ خطأ في تحديث Firebase: $e');
    }
  }

// ✅ ✅ ✅ دالة جديدة لإنشاء الخصم إذا لم يكن موجوداً
  void _createOpponentIfNeeded() {
    if (_gameService.remotePlayer != null || _opponentId == null) return;

    print('🎯 [CREATE] محاولة إنشاء الخصم: $_opponentId');

    // ✅ إنشاء خصم مؤقت
    final opponentCharacter = OnlineCharacter.getDefaultCharacter();

    setState(() {
      _gameService.remotePlayer = OnlinePlayer(
        playerId: _opponentId!,
        character: opponentCharacter,
        x: 0.7,
        y: 0.7,
        isFacingRight: false,
        weapons: [],
      );
    });

    // ✅ تحميل أنيميشن الخصم
    final animationManager = AnimationManager();
    final opponentAnimationId = _getCharacterAnimationId(opponentCharacter.id);
    animationManager.loadCharacterOnDemand(
      opponentAnimationId,
      opponentCharacter.animationConfigPath,
    );

    print('✅ [CREATE] تم إنشاء الخصم بنجاح');
  }

// ✅ ✅ ✅ دالة جديدة للتحقق الدوري من وجود الخصم
  void _checkOpponentPresence() {
    Timer.periodic(Duration(seconds: 3), (timer) {
      if (!mounted || !_isRealPlayerMatch || _isGameEnded) {
        timer.cancel();
        return;
      }

      if (_gameService.remotePlayer == null && _opponentId != null) {
        print('⚠️ [CHECK] الخصم لا يزال غير موجود، محاولة إنشائه...');
        _createOpponentIfNeeded();

        // ✅ محاولة جلب الخصم من Firebase
        FirebaseFirestore.instance
            .collection('real_matches_fixed')
            .doc(widget.roomId)
            .get()
            .then((snapshot) {
          if (!snapshot.exists) return;

          final data = snapshot.data() as Map<String, dynamic>;

          // ✅ البحث عن الخصم في playerState
          if (data.containsKey('playerState')) {
            final playerState = data['playerState'] as Map<String, dynamic>?;

            if (playerState != null) {
              playerState.forEach((playerId, state) {
                if (playerId != _userId && playerId == _opponentId) {
                  print('✅ [CHECK] تم العثور على الخصم في Firebase: $playerId');

                  // ✅ تحديث موقع الخصم
                  if (_gameService.remotePlayer != null) {
                    final stateMap = state as Map<String, dynamic>;
                    if (stateMap.containsKey('x')) {
                      _gameService.remotePlayer!.x = (stateMap['x'] as num).toDouble();
                    }
                    if (stateMap.containsKey('y')) {
                      _gameService.remotePlayer!.y = (stateMap['y'] as num).toDouble();
                    }
                    setState(() {});
                  }
                }
              });
            }
          }
        });
      }
    });
  }

  void _initializeGameSystems() {
    // print('🎮 === بدء تهيئة أنظمة اللعبة ===');

    // ✅ 1. إعداد حدود الخريطة
    _mapLeftBound = -_mapWidth / 2;
    _mapRightBound = _mapWidth / 2;
    _mapBottomBound = _mapHeight;
    _cameraSystem = SmartCameraSystem();

    // ✅ 2. وضع الشاشة كاملة
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // ✅ 3. تهيئة AnimationController
    _gameLoopController = AnimationController(
      duration: const Duration(milliseconds: 16),
      vsync: this,
    );

    // ✅ 4. تهيئة اللعبة بعد بناء الـ widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeGame();
    });

    // ✅ بدء تنظيف الأسلحة المسقطة كل 10 ثوان
    Timer.periodic(Duration(seconds: 10), (timer) {
      if (mounted && !_isGameEnded && !_isPaused) {
        _cleanupOldDroppedWeapons();
      }
    });

    // ✅ 5. إعداد الأنظمة الأساسية فقط
    _hideTutorialAfterDelay();
    _initializeAudio();
    _loadPlayerNames();
    // ✅ إضافة نظام الاهتزاز والتوهج للأسلحة
    _initializeWeaponVibrationSystem();

    // print('✅ تم تهيئة الأنظمة الأساسية');
  }

  Future<void> _connectToLiveKit() async {
    print('🟡 [LIVEKIT] محاولة الاتصال... useLiveKit=$_useLiveKit, isHost=$_isHost');

    if (!_useLiveKit) return;

    final connected = await _liveKitService.connectToRoom(
      roomId: widget.roomId,
      playerId: _userId,
      isHost: _isHost,
    );

    print('🟡 [LIVEKIT] نتيجة الاتصال: connected=$connected');

    if (!connected) {
      print('❌ [LIVEKIT] فشل الاتصال');
      _useLiveKit = false;
      return;
    }

    print('✅ [LIVEKIT] تم الاتصال بنجاح!');
    print('   🆔 معرفي: $_userId');
    print('   🏠 الغرفة: ${widget.roomId}');
    print('   👑 مضيف: $_isHost');

    _liveKitService.onPlayerStateReceived = _onRemotePlayerStateLiveKit;
    _liveKitService.onAttackReceived = _onRemoteAttackLiveKit;
    _liveKitService.onGameEndReceived = _onRemoteGameEndLiveKit;
    _liveKitService.onPlatformsReceived = _onRemotePlatformsReceived;
  }

// ✅ استلام حالة الخصم من LiveKit
  void _onRemotePlayerStateLiveKit(Map<String, dynamic> data) {
    // ✅ طباعة كل البيانات المستلمة (مهم جداً للتشخيص)
    print('📡 [LIVEKIT RAW] البيانات الخام: $data');

    if (_gameService.remotePlayer == null) {
      print('⚠️ [LIVEKIT] remotePlayer غير موجود بعد!');
      return;
    }

    final x = (data['x'] as num?)?.toDouble();
    final y = (data['y'] as num?)?.toDouble();
    final timestamp = data['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch;

    if (x == null || y == null) {
      print('⚠️ [LiveKit] بيانات غير مكتملة: x=$x, y=$y');
      print('   البيانات الكاملة: $data');
      return;
    }

    print('📥 [LiveKit] استلام حالة الخصم: x=$x, y=$y, timestamp=$timestamp');

    // ✅ تحديث موقع الخصم
    _gameService.remotePlayer!.x = x;
    _gameService.remotePlayer!.y = y;

    // ✅ طباعة الموقع بعد التحديث
    print('   ✅ بعد التحديث: remotePlayer في (${_gameService.remotePlayer!.x.toStringAsFixed(3)}, ${_gameService.remotePlayer!.y.toStringAsFixed(3)})');

    // ✅ تحديث حالة الأرضية
    if (data.containsKey('isGrounded')) {
      _gameService.remotePlayer!.isGrounded = data['isGrounded'] as bool;
    }

    // ✅ تحديث الصحة إذا وردت
    if (data.containsKey('health')) {
      _gameService.remotePlayer!.health = (data['health'] as num).toDouble();
      print('   ❤️ تحديث الصحة: ${_gameService.remotePlayer!.health}');
    }

    // ✅ تحديث الواجهة
    if (mounted) setState(() {});
  }

// ✅ استلام هجوم الخصم من LiveKit
  void _onRemoteAttackLiveKit(Map<String, dynamic> data) {
    if (_gameService.localPlayer == null || _isGameEnded) return;

    final damage = data['damage'] as int? ?? 10;
    final x = (data['x'] as num?)?.toDouble() ?? 0;
    final y = (data['y'] as num?)?.toDouble() ?? 0;

    print('⚔️ [LIVEKIT] هجوم وارد من الخصم: ضرر $damage في ($x, $y)');

    // ✅ تطبيق الضرر على اللاعب المحلي
    _gameService.localPlayer!.health -= damage;

    if (_gameService.localPlayer!.health <= 0) {
      _handlePlayerDeath('local');
    } else {
      _gameService.localPlayer!.state = PlayerState.hurt;
    }

    // ✅ إضافة تأثير بصري
    _addVisualEffect('hit', x, y, color: Colors.red, duration: 300);
  }

// ✅ الاستماع لتحديثات اللعبة من Firestore - نسخة محسنة
  void _listenToGameUpdates() {
    // ⭐ هذه الدالة لم نعد بحاجة إليها - SyncService يتولى كل شيء
    print('👂 تم تعطيل المستمع المحلي - استخدام SyncService');
  }

// ✅ تحديث موقع الخصم في حلقة اللعبة
  void _updateSmoothRemotePosition() {
    if (_gameService.remotePlayer == null) return;
    if (!_targetPositions.containsKey('remote')) return;

    final lastUpdate = _lastPositionUpdate['remote'];
    if (lastUpdate == null) return;

    final elapsed = DateTime.now().difference(lastUpdate).inMilliseconds / 1000.0;
    if (elapsed > 0.1) {
      // انتقل فوراً إذا مر وقت طويل
      _gameService.remotePlayer!.x = _targetPositions['remote']!.dx;
      _gameService.remotePlayer!.y = _targetPositions['remote']!.dy;
      return;
    }

    // انتربوليشين سلس
    final speed = _interpolationSpeed['remote']!;
    _gameService.remotePlayer!.x += (_targetPositions['remote']!.dx - _gameService.remotePlayer!.x) * speed;
    _gameService.remotePlayer!.y += (_targetPositions['remote']!.dy - _gameService.remotePlayer!.y) * speed;
  }


// ✅ تحديث موقع الخصم بشكل سلس
  void _updateRemotePlayerSmoothly(Map<String, dynamic> newState) {
    if (_gameService.remotePlayer == null) return;

    final targetX = (newState['x'] as num).toDouble();
    final targetY = (newState['y'] as num).toDouble();

    // تخزين الهدف
    _targetPositions['remote'] = Offset(targetX, targetY);
    _lastPositionUpdate['remote'] = DateTime.now();

    // تحديث مباشر إذا كانت المسافة كبيرة
    final currentPos = Offset(_gameService.remotePlayer!.x, _gameService.remotePlayer!.y);
    final targetPos = Offset(targetX, targetY);
    final distance = (targetPos - currentPos).distance;

    if (distance > 0.2) {
      _gameService.remotePlayer!.x = targetX;
      _gameService.remotePlayer!.y = targetY;
      _interpolationSpeed['remote'] = 0.3;
    } else {
      _interpolationSpeed['remote'] = 0.12;
    }
  }

// ✅ استلام المنصات من المضيف عبر LiveKit
  void _onRemotePlatformsReceived(Map<String, dynamic> data) {
    print('📥 [LIVEKIT] استلام منصات من المضيف');
    print('🔥 [PLATFORM] دخلت دالة _generateRandomPlatformPattern');
    print('   _isRealPlayerMatch=$_isRealPlayerMatch, _isHost=$_isHost');

    try {
      final platformsData = data['platforms'] as List<dynamic>;
      final patternName = data['patternName'] as String;

      List<BattlePlatform> receivedPlatforms = [];

      for (var p in platformsData) {
        receivedPlatforms.add(BattlePlatform(
          x: (p['x'] as num).toDouble(),
          y: (p['y'] as num).toDouble(),
          width: (p['width'] as num).toDouble(),
          height: (p['height'] as num).toDouble(),
          type: p['type'] as String,
          color: Color(p['color'] as int),
        ));
      }

      setState(() {
        _randomPlatforms = receivedPlatforms;
        _platformPatternName = patternName;
      });

      _gameService.platforms = receivedPlatforms;

      print('✅ [LIVEKIT] تم تحديث ${receivedPlatforms.length} منصة');

    } catch (e) {
      print('⚠️ [LIVEKIT] خطأ في معالجة المنصات: $e');
      print('❌ خطأ في توليد المنصات: $e');
    }
  }

  // ✅ دالة جديدة لمزامنة الوقت
  Future<void> _syncGameTime() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('real_matches_fixed')
          .doc(widget.roomId)
          .get();

      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;

      if (data.containsKey('gameTime') && data.containsKey('serverTime')) {
        final serverGameTime = data['gameTime'] as double;
        final serverTimestamp = data['serverTime'] as int;

        final now = DateTime.now().millisecondsSinceEpoch;
        final latency = (now - serverTimestamp) / 1000;
        final compensatedTime = serverGameTime - latency;

        // ✅ تحديث سلس
        final diff = (compensatedTime - _gameService.gameTimer).abs();
        if (diff > 0.5) {
          _gameService.gameTimer = compensatedTime.clamp(0, 120);
          print('⏰ [TIME FIX] فرق كبير: $diff ثانية -> تم التصحيح');
        }
      }
    } catch (e) {
      // تجاهل الأخطاء
    }
  }

// ✅ دالة مساعدة لتحويل نوع الهجوم
  OnlineAttackType _parseAttackType(String? typeStr) {
    if (typeStr == null) return OnlineAttackType.light;
    if (typeStr.contains('heavy')) return OnlineAttackType.heavy;
    if (typeStr.contains('aerial')) return OnlineAttackType.aerial;
    if (typeStr.contains('special')) return OnlineAttackType.special;
    if (typeStr.contains('signature')) return OnlineAttackType.signature;
    return OnlineAttackType.light;
  }

  // ✅ دالة للتحقق من صحة حالة الخصم
  void _validateRemotePlayerState() {
    if (_gameService.remotePlayer == null) return;

    final remote = _gameService.remotePlayer!;

    // ✅ إذا كان الخصم ميتاً بشكل غير منطقي (يعود للحياة)
    if (remote.state == PlayerState.death && remote.health <= 0) {
      // تحقق من Firebase
      FirebaseFirestore.instance
          .collection('real_matches_fixed')
          .doc(widget.roomId)
          .get()
          .then((snapshot) {
        if (!snapshot.exists) return;

        final data = snapshot.data() as Map<String, dynamic>;
        final playerState = data['playerState'] as Map<String, dynamic>?;

        if (playerState != null && playerState.containsKey(_opponentId)) {
          final state = playerState[_opponentId] as Map<String, dynamic>;
          final health = (state['health'] as num?)?.toDouble() ?? 100;

          // ✅ إذا كان الخصم حياً في Firebase، صحح حالته
          if (health > 0) {
            print('🔄 [FIX] تصحيح حالة الخصم: ميت -> حي');
            remote.health = health;
            remote.state = PlayerState.idle;
            setState(() {});
          }
        }
      });
    }
  }

  // ✅ إرسال حالة اللاعب إلى Firestore
  Future<void> _syncPlayerState() async {
    try {
      if (_gameService.localPlayer == null) return;

      final localPlayer = _gameService.localPlayer!;
      String currentUserId = await _getCurrentUserId();

      final now = DateTime.now().millisecondsSinceEpoch;

      final playerState = {
        'x': localPlayer.x,
        'y': localPlayer.y,
        'health': localPlayer.health,
        'state': localPlayer.state.toString(), // ✅ استخدام getter الجديد
        'animationState': localPlayer.animationController.currentState.toString(),
        'isFacingRight': localPlayer.isFacingRight,
        'velocityX': localPlayer.velocityX,
        'velocityY': localPlayer.velocityY,
        'isGrounded': localPlayer.isGrounded,
        'lastUpdate': now,
        'playerId': currentUserId,
        'timestamp': now,
      };

      await FirebaseFirestore.instance
          .collection('real_matches_fixed')
          .doc(widget.roomId)
          .set({
        'playerState': {
          currentUserId: playerState,
        },
        'lastSync': now,
      }, SetOptions(merge: true));

    } catch (e) {
      // تجاهل الأخطاء
    }
  }

  // ✅ إضافة دالة لتنظيف تأثيرات الاهتزاز عند التخلص
  void _cleanupWeaponVibrationSystem() {
    // ✅ إلغاء جميع مؤقتات الاهتزاز
    for (var timer in _weaponVibrationTimers.values) {
      timer.cancel();
    }
    _weaponVibrationTimers.clear();

    _weaponVibrationOffsets.clear();
    _weaponGlowIntensities.clear();

    _weaponVibrationTimer?.cancel();
  }

// ✅ هذه دالة جديدة - دمج فيها _initializeGame مع توليد المنصات
  Future<void> _initializeGame() async {
    print('🔥 [GAME] دخلت _initializeGame');
    print('🔥 [GAME] _isHost=$_isHost, _isRealPlayerMatch=$_isRealPlayerMatch');
    if (!mounted || _isGameEnded) return;

    try {
      _isRealPlayerMatch = widget.opponent['isRealPlayer'] == true;
      if (_isRealPlayerMatch) {
        _opponentId = widget.opponent['playerId'] as String?;
      }
      _gameStartTimestamp = DateTime.now().millisecondsSinceEpoch;

      // print('🔥 [GAME] جاري استدعاء _generateRandomPlatformPattern...');
      // _generateRandomPlatformPattern();
      // print('🔥 [GAME] تم العودة من _generateRandomPlatformPattern');

      // تحميل أنيميشنات اللاعب
      final playerAnimationId = _getCharacterAnimationId(widget.playerCharacter.id);
      final animationManager = AnimationManager();
      await animationManager.loadCharacterOnDemand(
        playerAnimationId,
        widget.playerCharacter.animationConfigPath,
      );

      // تحميل أنيميشنات الخصم
      OnlineCharacter opponentCharacter;
      if (widget.opponent['character'] is OnlineCharacter) {
        opponentCharacter = widget.opponent['character'] as OnlineCharacter;
      } else if (widget.opponent['character'] != null && widget.opponent['character'] is Map) {
        opponentCharacter = OnlineCharacter.fromJson(widget.opponent['character']);
      } else {
        opponentCharacter = OnlineCharacter.getDefaultCharacter();
      }

      final opponentAnimationId = _getCharacterAnimationId(opponentCharacter.id);
      await animationManager.loadCharacterOnDemand(
        opponentAnimationId,
        opponentCharacter.animationConfigPath,
      );

      _gameService = OnlineGameService.instance;
      String currentUserId = await _getCurrentUserId();

      final bool amIHost = _isHost; // تحديد من هو المضيف

      double localX, localY, remoteX, remoteY;

      if (amIHost) {
        // المضيف على اليسار
        localX = 0.2;
        localY = 0.7;
        remoteX = 0.8;
        remoteY = 0.7;
      } else {
        // الضيف على اليمين
        localX = 0.8;
        localY = 0.7;
        remoteX = 0.2;
        remoteY = 0.7;
      }

      print('📍 [POSITIONS]');
      print('   أنا: ($localX, $localY)');
      print('   الخصم: ($remoteX, $remoteY)');

      // ✅ إنشاء اللاعب المحلي
      if (_gameService.localPlayer == null) {
        _gameService.localPlayer = OnlinePlayer(
          playerId: currentUserId,
          character: widget.playerCharacter,
          x: localX,
          y: localY,
          isFacingRight: true,
          weapons: [],
        );
      } else {
        _gameService.localPlayer!.x = localX;
        _gameService.localPlayer!.y = localY;
        _gameService.localPlayer!.isFacingRight = true;
      }

      // ✅ إنشاء الخصم
      if (_gameService.remotePlayer == null) {
        _gameService.remotePlayer = OnlinePlayer(
          playerId: _opponentId ?? 'opponent',
          character: opponentCharacter,
          x: remoteX,
          y: remoteY,
          isFacingRight: false,
          weapons: [],
        );
      } else {
        _gameService.remotePlayer!.x = remoteX;
        _gameService.remotePlayer!.y = remoteY;
        _gameService.remotePlayer!.isFacingRight = false;
      }

      final opponentData = {
        ...widget.opponent,
        'character': opponentCharacter,
        'localPlayerId': currentUserId,
      };

      print('🔍 [GAME] قبل initializeBattleRoom - _randomPlatforms.length=${_randomPlatforms.length}');
      print('🔍 [GAME] _useLiveKit=$_useLiveKit, isConnected=${_liveKitService.isConnected}');
      print('🔍 [GAME] _isRealPlayerMatch=$_isRealPlayerMatch');

      _gameState = _gameService!.initializeBattleRoom(
        localCharacter: widget.playerCharacter,
        opponent: opponentData,
        customPlatforms: _randomPlatforms,
        platformPatternName: _platformPatternName,
        localPlayerId: currentUserId,
      );

      // ✅ بدء المباراة فوراً
      print('🚀 بدء المباراة فوراً...');
      setState(() {
        _isMatchStarted = true;
        _gameFullyStarted = true;
        _gameService.gameTimer = 120.0;
      });

      // ✅ تحديث Firebase
      if (_isRealPlayerMatch) {
        _forceUpdateFirebaseStatus();
      }

      // ✅ بدء أنظمة اللعبة
      _syncGameStart();

      // بدء الأنظمة الأخرى
      _startWeaponBounceSystem();
      _startComboSystem();
      _startDoubleJumpSystem();
      _startPunchSystem();
      _startThrownWeaponsSystem();
      _startFallDeathSystem();

      // بدء نظام الأسلحة بعد تأخير
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) {
          _initializeWeaponSystem();
        }
      });

      // ✅ ✅ ✅ الأهم: إضافة الـ listener وبدء حلقة اللعبة
      _gameLoopController.addListener(_updateGame);
      _startGameLoop();

      print('✅ تم تهيئة اللعبة وبدء حلقة اللعبة.');

    } catch (e) {
      _logError('initialize_game_error', e.toString());

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text('خطأ في التهيئة'),
            content: Text('حدث خطأ أثناء تحميل اللعبة: ${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _exitGame();
                },
                child: Text('حسناً'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _liveKitService.disconnect();
    _smoothMovement.reset();
    _latencyCompensator.reset();
    print('🗑️ بدء التخلص من الموارد...');
    _weaponFallbackTimer?.cancel();
    // ✅ تنظيف مؤقت الهجمات
    _attackCleanupTimer?.cancel();
    _attackCountByPosition?.clear();
    _processedAttackHashes?.clear();
    _startMatchTimer?.cancel();
    // ✅ إلغاء اشتراك حالة المباراة
    _matchStatusSubscription?.cancel();
    // ✅ إلغاء جميع الاشتراكات
    _gameStateSubscription?.cancel();
    _weaponSubscription?.cancel();
    _playerPresenceTimer?.cancel();
    _syncTimer?.cancel();
    // ⭐ تنظيف المتغيرات
    _lastProcessedAttackTimes.clear();
    if (_isBotGame) {
      try {
        AIBotService.instance.stop();
      } catch (e) {}
    }
    _cancelAllTimers();
    _disposeControllers();
    try {
      if (_gameService != null) {
        _gameService!.isGameRunning = false;
      }
    } catch (e) {}
    try {
      OnlineAudioService().stopAllSounds();
    } catch (e) {}
    _cleanupResources();
    _cleanupWeaponVibrationSystem();
    _syncService.stopSync();
    // ✅ ⭐⭐ إعادة ضبط الشاشة مع الحفاظ على الوضع الأفقي ⭐⭐
    try {
      // إعادة الأزرار النظامية فقط
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
          overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);

      // ✅ لا نغير الاتجاه - نتركه كما هو (أفقي)
      // SystemChrome.setPreferredOrientations([...]); // ❌ لا تفعل هذا

      print('✅ تم إعادة ضبط وضع الشاشة مع الحفاظ على الوضع الأفقي');
    } catch (e) {
      print('⚠️ خطأ في إعادة ضبط الشاشة: $e');
    }

    super.dispose();
    print('✅ تم التخلص من جميع الموارد');
  }

  void _cancelAllTimers() {
    final timers = [
      _notificationTimer, _movementTimer, _weaponSpawnTimer,
      _pauseTimer, _weaponCleanupTimer, _gameEndTimer,
      _weaponBounceTimer, _comboResetTimer, _doubleJumpResetTimer,
      _punchCooldownTimer, _fallDeathTimer
    ];

    for (var timer in timers) {
      timer?.cancel();
    }
  }

  void _disposeControllers() {
    try {
      if (_gameLoopController.isAnimating) {
        _gameLoopController.stop();
      }
      _gameLoopController.dispose();
    } catch (e) {
      // print('⚠️ خطأ في التخلص من gameLoopController: $e');
    }
  }

  void _cleanupResources() {
    try {
      _gameService?.dispose();
    } catch (e) {
      // print('⚠️ خطأ في تنظيف gameService: $e');
    }

    _activeNotifications.clear();
    _shownNotificationIds.clear();
    _weaponsOnGround.clear();
    _thrownWeapons.clear();
    _visualEffects.clear();
    _weaponBounceOffsets.clear();
    _weaponBounceDirections.clear();
  }

  Future<void> _initializeAudioSafely() async {
    try {
      // print('🔊 تهيئة نظام الصوت...');

      // تأخير قصير لتجنب التعارض مع تهيئة النظام
      await Future.delayed(Duration(milliseconds: 200));

      final audioService = OnlineAudioService();

      // ⭐ استخدام خاصية isDisposed مباشرة
      if (audioService.isDisposed) {
        // print('⚠️ خدمة الصوت تم التخلص منها، إنشاء جديدة...');
        return;
      }

      await audioService.initialize();
      await Future.delayed(Duration(milliseconds: 100));

      // ⭐ تشغيل الموسيقى فقط إذا كانت اللعبة لم تنته
      if (!_isGameEnded && mounted) {
        audioService.playBattleMusic();
      }
    } catch (e) {
      // print('⚠️ خطأ في تهيئة الصوت (سيستمر بدون صوت): $e');
    }
  }

// ✅ دالة إحياء اللاعب
  void _respawnPlayer(String playerType) {
    final player = playerType == 'local'
        ? _gameService.localPlayer
        : _gameService.remotePlayer;

    if (player == null) return;

    // ✅ منع الإحياء المتكرر
    if (_respawnCooldown[playerType]! > 0) return;

    print('🔄 [$playerType] الإحياء...');

    // ✅ إيجاد موقع آمن للإحياء
    double newX = playerType == 'local' ? 0.3 : 0.7;
    double newY = 0.7;
    bool foundSafePlatform = false;

    // ✅ البحث عن منصة آمنة فوق مستوى الموت
    for (var platform in _randomPlatforms) {
      // ✅ منصة آمنة فوق مستوى الموت وليست الأرضية الرئيسية
      if (platform.type != 'ground' && platform.y < 1.2 && platform.y > 0.3) {
        // ✅ التأكد من أن المنصة آمنة (ليست تحت الأرض)
        if (platform.y + platform.height / 2 < 1.3) {
          newX = platform.x;
          newY = platform.y - platform.height / 2 - 0.05; // فوق المنصة مباشرة
          foundSafePlatform = true;
          print('📍 [$playerType] تم العثور على منصة آمنة: ${platform.type} في Y=${platform.y}');
          break;
        }
      }
    }

    if (!foundSafePlatform) {
      // ✅ استخدام المواقع الافتراضية على منصة القتال الرئيسية
      if (playerType == 'local') {
        newX = 0.3;
      } else {
        newX = 0.7;
      }
      newY = 0.7;
      print('📍 [$playerType] استخدام الموقع الافتراضي: ($newX, $newY)');
    }

    // ✅ تحديث موقع اللاعب
    player.x = newX;
    player.y = newY;
    player.velocityX = 0;
    player.velocityY = 0;
    player.isGrounded = true; // ✅ تأكد من أنه على الأرض

    // ✅ استدعاء startRespawn
    player.startRespawn();

    // ✅ تحديث المواقع السلسة
    _playerSmoothX[playerType] = newX;
    _playerSmoothY[playerType] = newY;
    _playerTargetX[playerType] = newX;
    _playerTargetY[playerType] = newY;

    // ✅ إعادة تعيين العداد
    _respawnCooldown[playerType] = 0;
    _playerIsRespawning[playerType] = false;
    _showKOEffect[playerType] = false;

    // ✅ استعادة الأسلحة
    _restorePlayerWeaponsAfterRespawn(player, playerType);

    print('✅ [$playerType] تم الإحياء في ($newX, $newY)');
  }

  // ✅ ========== دالة متكاملة للحصول على معرف المستخدم الحالي ==========
  Future<String> _getCurrentUserId() async {
    if (_currentUserId.isEmpty) {
      _currentUserId = await GuestIdService.getStableGuestId();
      print('🆔 [_getCurrentUserId] معرف المستخدم: $_currentUserId');
    }
    return _currentUserId;
  }

  // ✅ ========== دالة موحدة للتحقق من الموت بالسقوط ==========
  void _checkFallDeathUnified() {
    if (_isGameEnded || _isPaused) return;

    final checkPlayer = (OnlinePlayer? player, String playerType) {
      if (player == null || _playerIsRespawning[playerType] == true || _playerLives[playerType]! <= 0) return;

      // ✅ الشرط الأساسي: إذا كان اللاعب تحت مستوى الموت
      if (player.y > 1.3) { // ⭐ تقليل من 2.0 إلى 1.3
        // print('💀 [$playerType] اللاعب تحت الأرض! الموقع: ${player.y}');

        // ✅ إعادة تعيين الحالة المادية أولاً
        player.isGrounded = false;
        player.velocityY = 0.0;

        _handlePlayerDeath(playerType);
        return;
      }

      // ✅ إذا كان اللاعب يسقط في فجوة
      if (_isInEmptySpace(player) && player.velocityY > 0.02 && player.y > 1.0) {
        // print('💀 [$playerType] سقوط في فجوة');
        player.isGrounded = false;
        _handlePlayerDeath(playerType);
        return;
      }

      // ✅ الموت بالسقوط العادي (مع هوستريسس لمنع التكرار)
      if (player.y > 1.2 && player.velocityY > 0.01) { // ⭐ إضافة شرط السرعة
        // print('💀 [$playerType] الموت بالسقوط خارج الحدود!');
        player.isGrounded = false;
        _handlePlayerDeath(playerType);
      }
    };

    checkPlayer(_gameService.localPlayer, 'local');
    checkPlayer(_gameService.remotePlayer, 'remote');
  }

  // ✅ دالة لتفادي تعلق اللاعب تحت الأرض
  void _resetPlayerPositionIfStuck() {
    if (_frameCounter % 60 == 0) { // كل ثانية
      // ✅ التحقق من اللاعب المحلي
      if (_gameService.localPlayer != null) {
        final player = _gameService.localPlayer!;

        // ✅ إذا كان اللاعب تحت الأرض ولا يتحرك
        if (player.y > 1.1 && player.velocityY.abs() < 0.001 && player.state != PlayerState.death) {
          // print('🚨 [FIX] اللاعب المحلي عالق تحت الأرض، إعادته للسطح');

          // ⭐ بدلاً من إعادته، نجعله يموت
          _handlePlayerDeath('local');
        }
      }

      // ✅ التحقق من الخصم
      if (_gameService.remotePlayer != null) {
        final player = _gameService.remotePlayer!;

        if (player.y > 1.1 && player.velocityY.abs() < 0.001 && player.state != PlayerState.death) {
          // print('🚨 [FIX] الخصم عالق تحت الأرض، إعادته للسطح');

          // ⭐ بدلاً من إعادته، نجعله يموت
          _handlePlayerDeath('remote');
        }
      }
    }
  }
  // ✅ ========== نظام الأسلحة الموحد ==========
  void _initializeWeaponSystem() {
    // print('🎯 [WEAPON SYSTEM] تهيئة نظام الأسلحة');

    _cancelWeaponTimers();
    _weaponsOnGround.clear();

    // ✅ إشعار بدء النظام
    _showGameNotification(
      id: 'weapon_system_start',
      message: 'ستظهر الأسلحة بعد 10 ثواني!\nتمسك بها قبل أن تختفي',
      color: Colors.blue,
      icon: Icons.notifications_active,
      durationSeconds: 4,
    );

    // ✅ أول ظهور بعد 10 ثواني
    Timer(Duration(seconds: 10), () {
      if (mounted && !_isGameEnded && !_isPaused) {
        _spawnWeaponBatch();

        _showGameNotification(
          id: 'weapons_appeared',
          message: 'ظهرت الأسلحة! اقترب وانقر لالتقاطها',
          color: Colors.green,
          icon: Icons.emoji_objects,
          durationSeconds: 3,
        );
      }
    });

    // ✅ بدء التكرار المنتظم بعد 45 ثانية
    Timer(Duration(seconds: 45), () {
      if (mounted && !_isGameEnded && !_isPaused) {
        _startRegularWeaponSpawning();
      }
    });

    // ✅ بدء تنظيف الأسلحة
    _startWeaponCleanup();
  }

  void _cancelWeaponTimers() {
    _weaponSpawnTimer?.cancel();
    _weaponCleanupTimer?.cancel();
  }

// ✅ تأكد من هذه الدالة
  List<Widget> _buildActiveWeaponAttacks(Size screenSize) {
    final attacks = _gameService.activeAttacks.where((attack) => attack.isActive).toList();

    if (attacks.isEmpty) return [];

    print('🎯 بناء ${attacks.length} هجوم على الشاشة');

    return attacks.map<Widget>((attack) {
      return Positioned(
        left: attack.x * screenSize.width - 25,
        top: attack.y * screenSize.height - 25,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..scale((attack.directionX > 0 ? 1.0 : -1.0), 1.0),
          child: Container(
            width: 50,
            height: 50,
            child: Image.asset(
              attack.weaponImagePath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stack) {
                print('❌ خطأ في تحميل صورة السلاح: ${attack.weaponImagePath}');
                return Container(
                  width: 50,
                  height: 50,
                  color: Colors.red.withOpacity(0.5),
                  child: Center(child: Text('⚔️', style: TextStyle(fontSize: 20))),
                );
              },
            ),
          ),
        ),
      );
    }).toList();
  }

  void _startRegularWeaponSpawning() {
    _weaponSpawnTimer = Timer.periodic(Duration(seconds: 45), (timer) {
      if (!mounted || _isGameEnded || _isPaused) {
        timer.cancel();
        return;
      }

      if (_weaponsOnGround.length < _maxWeaponsOnGround) {
        _spawnWeaponBatch();
      }
    });
  }

  void _startWeaponCleanup() {
    _weaponCleanupTimer = Timer.periodic(Duration(seconds: 15), (timer) {
      if (!mounted || _isGameEnded || _isPaused) {
        timer.cancel();
        return;
      }
      _cleanupOldWeapons();
    });
  }

  bool _checkIfMatchCreator() {
    // إذا لم تكن مباراة حقيقية، اعتبر نفسك المنشئ
    if (!_isRealPlayerMatch) return true;

    // التحقق من وجود بيانات اللاعبين
    if (!widget.opponent.containsKey('players')) return false;

    final playersList = widget.opponent['players'] as List?;
    if (playersList == null || playersList.isEmpty) return false;

    final firstPlayer = playersList.first as Map<String, dynamic>;
    final creatorId = firstPlayer['playerId'] as String;

    return creatorId == _userId;
  }

// ✅ دالة لبدء المؤقت الاحتياطي للأسلحة
  void _startWeaponFallbackTimer() {
    // إلغاء المؤقت السابق
    _weaponFallbackTimer?.cancel();

    // تعيين أننا لم نستلم أسلحة بعد
    _hasReceivedWeapons = false;

    // بدء مؤقت جديد
    _weaponFallbackTimer = Timer(Duration(seconds: 5), () {
      if (!mounted || _isGameEnded || _isPaused) return;

      // إذا لم نستلم أسلحة ولم تكن هناك أسلحة على الأرض
      if (!_hasReceivedWeapons && _weaponsOnGround.isEmpty) {
        print('⚠️ [WEAPON FALLBACK] لم يتم استلام أسلحة، توليد محلي');

        // توليد أسلحة محلياً
        _generateWeaponsBatch();

        // إشعار للمستخدم
        _showGameNotification(
          id: 'weapons_fallback',
          message: 'تم توليد أسلحة محلياً',
          color: Colors.orange,
          icon: Icons.warning,
          durationSeconds: 3,
        );
      }
    });
  }

  void _spawnWeaponBatch() {
    if (_isGameEnded || _isPaused || !mounted) return;

    // منع توليد أسلحة متعددة في نفس الوقت
    if (_isSpawningWeapons) return;
    _isSpawningWeapons = true;

    try {
      final isMatchCreator = _checkIfMatchCreator();

      // ✅ إذا كانت مباراة حقيقية ولسنا المنشئ
      if (_isRealPlayerMatch && !isMatchCreator) {
        // بدء مؤقت احتياطي إذا لم نستلم أسلحة
        _startWeaponFallbackTimer();
        return;
      }

      // توليد الأسلحة
      _generateWeaponsBatch();

    } finally {
      // إعادة تعيين القفل بعد انتهاء التوليد
      Future.delayed(Duration(milliseconds: 100), () {
        _isSpawningWeapons = false;
      });
    }
  }

  void _generateWeaponsBatch() {
    final random = Random();

    if (OnlineWeaponLibrary.weapons.isEmpty) {
      print('⚠️ [WEAPON] مكتبة الأسلحة فارغة');
      return;
    }

    final weaponsList = OnlineWeaponLibrary.weapons.values.toList();

    // تنظيف الأسلحة القديمة إذا تجاوزنا العدد المسموح
    if (_weaponsOnGround.length >= _maxWeaponsOnGround) {
      _cleanupOldWeapons();
    }

    final neededWeapons = _maxWeaponsOnGround - _weaponsOnGround.length;
    if (neededWeapons <= 0) return;

    final randomPositions = _generateRandomWeaponPositions(neededWeapons);
    List<Map<String, dynamic>> newWeapons = [];

    for (int i = 0; i < min(neededWeapons, randomPositions.length); i++) {
      if (weaponsList.isEmpty) break;

      final weapon = weaponsList[random.nextInt(weaponsList.length)];
      final pos = randomPositions[i];

      final weaponData = {
        'weapon': weapon,
        'x': pos['x']!,
        'y': pos['y']!,
        'id': 'weapon_${DateTime.now().millisecondsSinceEpoch}_$i',
        'spawnTime': DateTime.now().millisecondsSinceEpoch,
        'type': weapon.type.toString(),
        'isActive': true,
        'lifetime': 45,
        'hasVibration': true,
        'hasGlow': true,
      };

      newWeapons.add(weaponData);
      _startWeaponVibrationEffect(weaponData['id'] as String);
    }

    if (newWeapons.isNotEmpty) {
      setState(() {
        _weaponsOnGround.addAll(newWeapons);
      });

      // مزامنة الأسلحة مع Firebase فقط إذا كنا المنشئ
      if (_isRealPlayerMatch && _checkIfMatchCreator()) {
        _syncWeaponsToFirestore();
      }

      _showGameNotification(
        id: 'weapons_spawned_random',
        message: 'ظهرت أسلحة جديدة!',
        color: Colors.orange,
        icon: Icons.explore,
        durationSeconds: 3,
      );

      print('✅ [WEAPON] تم توليد ${newWeapons.length} سلاح جديد');
    }
  }

  // ✅ دالة مساعدة للحصول على userId بشكل متزامن
  String _getCurrentUserIdSync() {
    return _userId;
  }

  // ✅ دالة لبدء تأثير الاهتزاز والتوهج لسلاح معين
  void _startWeaponVibrationEffect(String weaponId) {
    if (_weaponVibrationTimers.containsKey(weaponId)) {
      _weaponVibrationTimers[weaponId]?.cancel();
    }

    // ✅ تهيئة قيم الاهتزاز والتوهج
    _weaponVibrationOffsets[weaponId] = 0.0;
    _weaponGlowIntensities[weaponId] = 0.3;

    // print('✨ بدء تأثير الاهتزاز والتوهج للسلاح: $weaponId');
  }

  // ✅ دالة لوقف تأثير الاهتزاز والتوهج لسلاح معين
  void _stopWeaponVibrationEffect(String weaponId) {
    if (_weaponVibrationTimers.containsKey(weaponId)) {
      _weaponVibrationTimers[weaponId]?.cancel();
      _weaponVibrationTimers.remove(weaponId);
    }

    _weaponVibrationOffsets.remove(weaponId);
    _weaponGlowIntensities.remove(weaponId);

    // print('🛑 إيقاف تأثير الاهتزاز والتوهج للسلاح: $weaponId');
  }

  void _cleanupOldWeapons() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final weaponsToRemove = <Map<String, dynamic>>[];

    for (var weaponData in _weaponsOnGround) {
      final spawnTime = weaponData['spawnTime'] as int;
      final lifetime = weaponData['lifetime'] ?? 45;
      final age = (now - spawnTime) / 1000.0;

      if (age > lifetime) {
        weaponsToRemove.add(weaponData);

        // ✅ إيقاف تأثير الاهتزاز والتوهج
        final weaponId = weaponData['id'] as String;
        _stopWeaponVibrationEffect(weaponId);
      }
    }

    if (weaponsToRemove.isNotEmpty) {
      setState(() {
        _weaponsOnGround.removeWhere((weapon) => weaponsToRemove.contains(weapon));
      });

      print('🧹 تم تنظيف ${weaponsToRemove.length} سلاح قديم مع تأثيراتها');
    }
  }

  // ✅ دالة محسنة لتوليد مواقع عشوائية للأسلحة
  List<Map<String, double>> _generateRandomWeaponPositions(int count) {
    final random = Random();
    final positions = <Map<String, double>>[];

    // ✅ قائمة بجميع المناطق المحتملة في الخريطة
    final List<Map<String, double>> allPossiblePositions = [
      // ✅ مناطق في المنتصف
      {'x': 0.3, 'y': _groundLevel - 0.03},
      {'x': 0.5, 'y': _groundLevel - 0.03},
      {'x': 0.7, 'y': _groundLevel - 0.03},

      // ✅ مناطق على المنصات العائمة (إذا وجدت)
      {'x': 0.2, 'y': 0.65},
      {'x': 0.8, 'y': 0.65},
      {'x': 0.5, 'y': 0.5},
      {'x': 0.35, 'y': 0.55},
      {'x': 0.65, 'y': 0.55},

      // ✅ مناطق في الأطراف
      {'x': 0.15, 'y': _groundLevel - 0.03},
      {'x': 0.85, 'y': _groundLevel - 0.03},

      // ✅ مناطق مرتفعة (إذا كانت هناك منصات علوية)
      {'x': 0.4, 'y': 0.4},
      {'x': 0.6, 'y': 0.4},

      // ✅ مناطق خاصة بالمنصات العشوائية
      {'x': 0.25, 'y': 0.8},
      {'x': 0.75, 'y': 0.8},
    ];

    // ✅ إضافة مواقع من المنصات العشوائية الحالية
    for (var platform in _randomPlatforms) {
      if (platform.type != 'ground') { // لا نضع أسلحة على الأرضية الرئيسية
        // ✅ توليد مواقع عشوائية على المنصة
        for (int i = 0; i < 2; i++) {
          final platformLeft = platform.x - platform.width / 2;
          final platformRight = platform.x + platform.width / 2;
          final platformTop = platform.y - platform.height / 2;

          final randomX = platformLeft + random.nextDouble() * platform.width;
          final randomY = platformTop - 0.02; // فوق المنصة قليلاً

          // ✅ التحقق من أن الموقع داخل حدود الخريطة
          if (randomX > 0.1 && randomX < 0.9 && randomY > 0.1 && randomY < 1.0) {
            allPossiblePositions.add({
              'x': randomX,
              'y': randomY,
            });
          }
        }
      }
    }

    // ✅ اختيار مواقع عشوائية فريدة
    final shuffledPositions = List.from(allPossiblePositions)..shuffle(random);

    for (int i = 0; i < min(count, shuffledPositions.length); i++) {
      positions.add(shuffledPositions[i]);
    }

    // print('🎯 تم توليد ${positions.length} موقع عشوائي للأسلحة');
    return positions;
  }

  // ✅ ========== التقاط السلاح ==========
  void _pickUpWeaponWithConditions(Map<String, dynamic> weaponData) {
    if (_gameService.localPlayer == null || _isGameEnded || _isPaused) return;

    final player = _gameService.localPlayer!;
    final weapon = weaponData['weapon'] as OnlineWeapon;

    final distance = sqrt(pow(player.x - weaponData['x'], 2) + pow(player.y - weaponData['y'], 2));
    final pickupDistance = 0.08;

    if (distance > pickupDistance) {
      _showGameNotification(
        id: 'too_far_weapon',
        message: 'اقترب أكثر من السلاح ثم انقر عليه',
        color: Colors.orange,
        icon: Icons.warning,
      );
      return;
    }

    if (player.weapons.isNotEmpty && player.currentWeapon != null) {
      _showWeaponReplacementNotification(weapon);
      return;
    }

    // ✅ تغيير من attacking إلى attacking_light أو attacking_heavy
    if (player.state == PlayerState.attacking_light ||
        player.state == PlayerState.attacking_heavy) {
      _showGameNotification(
        id: 'cant_pickup_attacking',
        message: 'لا يمكن التقاط سلاح أثناء الهجوم',
        color: Colors.red,
        icon: Icons.block,
      );
      return;
    }

    _performWeaponPickup(weaponData);
  }

  void _performWeaponPickup(Map<String, dynamic> weaponData) {
    final player = _gameService.localPlayer!;
    final weapon = weaponData['weapon'] as OnlineWeapon;
    final isDroppedWeapon = weaponData['isDropped'] == true;

    final random = Random();

    // ✅ تحديد عدد الطلقات بناءً على نوع السلاح
    int ammoCount;
    if (isDroppedWeapon) {
      ammoCount = 1 + random.nextInt(3); // 1-3 طلقات فقط
    } else {
      ammoCount = 3 + random.nextInt(5); // 3-7 طلقات
    }

    final weaponTypeKey = weapon.type.toString();
    _weaponAmmo[weaponTypeKey] = ammoCount;
    _currentAmmoWeaponId = weaponTypeKey;

    player.pickUpWeapon(weapon);

    setState(() {
      _weaponsOnGround.remove(weaponData);

      // ✅ إذا كان سلاحاً مسقطاً، إزالته من القائمة
      if (isDroppedWeapon) {
        for (var playerType in ['local', 'remote']) {
          _droppedWeapons[playerType]!.remove(weaponData);
        }
      }

      _showAmmoCounter = true;
    });

    // ✅ مزامنة الأسلحة مع الخادم بعد الالتقاط
    _syncWeaponsToFirestore();

    _addVisualEffect(
      'weapon_pickup',
      player.x,
      player.y,
      color: isDroppedWeapon ? Colors.orange : Colors.yellow,
      duration: 600,
    );

    // print('✅ [PICKUP] تم التقاط ${isDroppedWeapon ? 'سلاح مسقط' : 'سلاح عادي'}: ${weapon.name}');
    // print('   🔫 عدد الطلقات: $ammoCount');

    _showGameNotification(
      id: 'pickup_${weapon.name}_${DateTime.now().millisecondsSinceEpoch}',
      message: '✅ التقاط ${weapon.name} ($ammoCount طلقة)',
      color: isDroppedWeapon ? Colors.orange : Colors.green,
      icon: Icons.check_circle,
      durationSeconds: 2,
    );
  }

  // ✅ ========== نظام الإشعارات الموحد ==========
  void _showGameNotification({
    required String id,
    required String message,
    Color color = Colors.blue,
    IconData icon = Icons.info,
    int durationSeconds = 3,
  }) {
    if (!mounted || _isGameEnded) return;

    if (_shownNotificationIds.containsKey(id) && _shownNotificationIds[id] == true) {
      return;
    }

    _notificationTimer?.cancel();

    setState(() {
      _activeNotifications = [GameNotification(
        id: id,
        message: message,
        color: color,
        icon: icon,
        durationSeconds: durationSeconds,
      )];
      _shownNotificationIds[id] = true;
      _isNotificationVisible = true;
    });

    // print('📢 [NOTIFICATION]: $message');

    _notificationTimer = Timer(Duration(seconds: durationSeconds.clamp(1, 3)), () {
      if (mounted) {
        _hideNotification(id);
      }
    });
  }

  void _hideNotification(String id) {
    if (mounted) {
      setState(() {
        _activeNotifications.removeWhere((notification) => notification.id == id);
        if (_activeNotifications.isEmpty) {
          _isNotificationVisible = false;
        }
      });
    }
  }

// ✅ ========== تهيئة اللعبة الرئيسية المعدلة ==========
// ✅ 1. أضف هذه الدوال للتأكد من عدم وجود أخطاء
  @override
  void didUpdateWidget(OnlineGameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.roomId != widget.roomId) {
      print('⚠️ تم تغيير roomId أثناء التشغيل!');
    }
  }

// ✅ 2. أضف معالج للأخطاء غير المتوقعة في _updateGame
  void _safeUpdateGame() {
    try {
      _updateGame();
    } catch (e, stack) {
      print('❌ خطأ فادح في حلقة اللعبة: $e');
      print(stack);
      // لا نريد إيقاف اللعبة، فقط نسجل الخطأ
    }
  }

// ثم في _startGameLoop:
  void _startGameLoop() {
    if (!_isPaused && !_isGameEnded && mounted) {
      _gameLoopController.addListener(_safeUpdateGame); // استخدم الدالة الآمنة
      _gameLoopController.repeat();
    }
  }

// ✅ ========== دالة التحديث الرئيسية المعدلة مع النظام الجديد ==========
  void _updateGame() {
    // ✅ في بداية دالة _updateGame، أضف هذه الطباعة كل 60 إطار
    if (_frameCounter % 60 == 0) {
      print('🔍 [LIVEKIT STATUS] connected=${_liveKitService.isConnected}, useLiveKit=$_useLiveKit');
    }

    // ✅ التحقق من نهاية اللعبة أولاً
    if (_isGameEnded) return;

    // ✅ تأكد فقط من أن اللعبة لم تنته ولم تتوقف
    if (!mounted || _isGameEnded || _isPaused) return;

    _frameCounter++;

    // ✅ بدلاً من ذلك، استخدم DEBUG_MODE فقط
    if (DEBUG_MODE && _frameCounter % 120 == 0) {
      _debugFullState();  // فقط في وضع DEBUG وكل ثانيتين
      print('🔍 [LIVEKIT STATUS] connected=${_liveKitService.isConnected}, useLiveKit=$_useLiveKit, isHost=$_isHost');
    }

    // تنظيف الهجمات كل 5 إطارات
    if (_frameCounter % 5 == 0) {
      if (_gameService.activeAttacks.length > 25) {
        print('⚠️ [EMERGENCY CLEANUP] عدد كبير جداً من الهجمات: ${_gameService.activeAttacks.length}');
        _gameService.activeAttacks.removeWhere((attack) => attack.lifetime < 20);
      }
    }

    // تنظيف الهجمات القديمة كل 10 إطارات
    if (_frameCounter % 10 == 0) {
      _cleanupOldAttacks();
    }

    // مزامنة الوقت كل 30 إطار (يبقى لأنها ضرورية)
    if (_frameCounter % 30 == 0 && _isRealPlayerMatch) {
      _syncGameTime();
    }

    // ✅ تحديث موقع الخصم بشكل سلس
    _updateSmoothRemotePosition();

    try {
      _ensureMapsInitialized();

      // تحقق من اللاعبين العالقين كل 30 إطار
      if (_frameCounter % 30 == 0) {
        _checkForStuckPlayers();
      }

      // التحقق من المنصات كل 60 إطار
      if (_frameCounter % 60 == 0) {
        _validatePlatforms();
      }

      bool needsUiUpdate = false;

      // 1. تحديث الفيزياء الأساسية
      _applySmartCeilingGravity();
      _updateCeilingStickiness();
      _updateWeaponsPhysics();

      // 2. تحديث نظام الإحياء
      _updateRespawnSystem();

      // 3. التحقق من التصادمات
      _checkGroundCollision();
      _checkPlayerCollisions();
      _checkThrownWeaponsCollision();

      // 4. التحقق من حالات الموت
      _checkFallDeathEnhanced();
      _updateDeadPlayers();
      _checkPlayerDeaths();

      // 5. تحديث حالة اللاعبين
      if (_gameService.localPlayer != null) {
        _gameService.localPlayer!.updateStateFromPhysics();
      }

      // 6. تحديث الأنيميشن للاعبين
      if (_gameService.localPlayer != null) {
        _gameService.localPlayer!.updateAnimation(16.0);
      }
      if (_gameService.remotePlayer != null) {
        _gameService.remotePlayer!.updateAnimationOnly(16.0);
      }

      // 7. تحديث المواقع السلسة
      _updateSmoothPlayerPositions();
      _updateWeaponBounce();
      _resetPlayerPositionIfStuck();

      // 8. التحقق من صحة مواقع اللاعبين
      _validatePlayerPositions();

      // 9. تحديث حالة اللعبة
      try {
        final newGameState = _gameService.updateGameState(
          gameState: _gameState,
          deltaTime: Duration(milliseconds: 16),
        );
        if (newGameState != null) {
          _gameState = newGameState;
          needsUiUpdate = true;
        }
      } catch (e) {
        _gameState = {};
      }

      // 10. تحديث التأثيرات
      _updateVisualEffects();
      _updateThrownWeapons();

      // 11. إعادة تعيين تأثير KO
      _autoResetKOEffects();

      // ✅ ✅ ✅ استخدام LiveKit فقط (تم تعطيل Firebase مؤقتاً للتجربة)
      if (_useLiveKit && _liveKitService.isConnected && _gameService.localPlayer != null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - _lastLiveKitSendTime >= LIVEKIT_SEND_INTERVAL_MS) {
          _lastLiveKitSendTime = now;
          _liveKitService.sendPlayerState(
            x: _gameService.localPlayer!.x,
            y: _gameService.localPlayer!.y,
            health: _gameService.localPlayer!.health,
            frame: _frameCounter,
          );
        }
      }

      // 12. تحديث الواجهة
      if (needsUiUpdate && mounted) {
        setState(() {});
      }

    } catch (e) {
      _logError('main_update_error', e.toString());
    }
  }

// ✅ دالة للتحقق من صحة مواقع اللاعبين وتصحيحها
  void _validatePlayerPositions() {
    // التحقق من اللاعب المحلي
    if (_gameService.localPlayer != null) {
      final local = _gameService.localPlayer!;

      // إذا كان اللاعب خارج الخريطة
      if (local.x < -0.5 || local.x > 1.5 || local.y < -0.5 || local.y > 2.0) {
        print('⚠️ [FIX] موقع غير صحيح للاعب المحلي: (${local.x.toStringAsFixed(2)}, ${local.y.toStringAsFixed(2)})');

        // إعادة تعيين الموقع حسب دور اللاعب
        if (_isHost) {
          local.x = 0.2;
        } else {
          local.x = 0.8;
        }
        local.y = 0.7;
        local.velocityX = 0;
        local.velocityY = 0;
        local.isGrounded = false;

        // تحديث المواقع السلسة أيضاً
        _playerSmoothX['local'] = local.x;
        _playerSmoothY['local'] = local.y;
        _playerTargetX['local'] = local.x;
        _playerTargetY['local'] = local.y;
      }

      // إذا كانت قيمة x أو y غير صالحة (NaN)
      if (local.x.isNaN || local.y.isNaN) {
        print('⚠️ [FIX] موقع اللاعب المحلي يحتوي على NaN، إعادة تعيين');
        local.x = _isHost ? 0.2 : 0.8;
        local.y = 0.7;
        _playerSmoothX['local'] = local.x;
        _playerSmoothY['local'] = local.y;
      }
    }

    // التحقق من الخصم
    if (_gameService.remotePlayer != null) {
      final remote = _gameService.remotePlayer!;

      // إذا كان الخصم خارج الخريطة
      if (remote.x < -0.5 || remote.x > 1.5 || remote.y < -0.5 || remote.y > 2.0) {
        print('⚠️ [FIX] موقع غير صحيح للخصم: (${remote.x.toStringAsFixed(2)}, ${remote.y.toStringAsFixed(2)})');

        // إعادة تعيين الموقع حسب دور المضيف
        if (_isHost) {
          remote.x = 0.8;
        } else {
          remote.x = 0.2;
        }
        remote.y = 0.7;
        remote.velocityX = 0;
        remote.velocityY = 0;
        remote.isGrounded = false;

        // تحديث المواقع السلسة أيضاً
        _playerSmoothX['remote'] = remote.x;
        _playerSmoothY['remote'] = remote.y;
        _playerTargetX['remote'] = remote.x;
        _playerTargetY['remote'] = remote.y;
      }

      // إذا كانت قيمة x أو y غير صالحة (NaN)
      if (remote.x.isNaN || remote.y.isNaN) {
        print('⚠️ [FIX] موقع الخصم يحتوي على NaN، إعادة تعيين');
        remote.x = _isHost ? 0.8 : 0.2;
        remote.y = 0.7;
        _playerSmoothX['remote'] = remote.x;
        _playerSmoothY['remote'] = remote.y;
      }
    }
  }

  void _ensureMapsInitialized() {
    // ✅ تأكد من أن جميع المصفوفات مهيئة
    if (_playerLives.isEmpty) {
      _playerLives = {'local': 3, 'remote': 3};
    }
    if (_respawnCooldown.isEmpty) {
      _respawnCooldown = {'local': 0, 'remote': 0};
    }
    if (_playerIsRespawning.isEmpty) {
      _playerIsRespawning = {'local': false, 'remote': false};
    }
    if (_showKOEffect.isEmpty) {
      _showKOEffect = {'local': false, 'remote': false};
    }
    if (_playerHasDoubleJumped.isEmpty) {
      _playerHasDoubleJumped = {'local': false, 'remote': false};
    }
    if (_consecutiveHits.isEmpty) {
      _consecutiveHits = {'local': 0, 'remote': 0};
    }
    if (_droppedWeapons.isEmpty) {
      _droppedWeapons = {'local': [], 'remote': []};
    }
  }

  // ✅ دالة للتحقق من اللاعبين العالقين
  void _checkForStuckPlayers() {
    final checkPlayer = (OnlinePlayer? player, String playerType) {
      if (player == null || _playerIsRespawning[playerType] == true) return;

      // ✅ إذا كان اللاعب في الأسفل (y > 1.1) ولا يتحرك لعدة إطارات
      if (player.y > 1.1 && player.velocityY.abs() < 0.001 && player.state != PlayerState.death) {
        // print('⚠️ [$playerType] لاعب عالق في الأسفل! إجبار الموت...');
        _handlePlayerDeath(playerType);
      }
    };

    checkPlayer(_gameService.localPlayer, 'local');
    checkPlayer(_gameService.remotePlayer, 'remote');
  }

  void _notifyBotEvents() {
    // يمكنك إرسال الأحداث هنا بناءً على ما يحدث في اللعبة
    // مثال: عندما يهاجم اللاعب
    // ✅ تغيير من attacking إلى attacking_light أو attacking_heavy
    if (_gameService.localPlayer!.state == PlayerState.attacking_light ||
        _gameService.localPlayer!.state == PlayerState.attacking_heavy) {
      AIBotService.instance.notifyEvent('player_attacked', {
        'attacker_id': _gameService.localPlayer!.playerId,
        'weapon_type': _gameService.localPlayer!.currentWeapon?.type,
      });
    }

    // عندما يصيب اللاعب البوت
    if (_gameService.remotePlayer!.state == PlayerState.hurt) {
      AIBotService.instance.notifyEvent('player_hit', {
        'attacker_id': _gameService.localPlayer!.playerId,
        'target_id': _gameService.remotePlayer!.playerId,
        'damage': 10,
      });
    }
  }

  // ✅ دالة لإعادة تعيين تأثير KO تلقائياً بعد فترة
  void _autoResetKOEffects() {
    if (_frameCounter % 60 == 0) { // كل ثانية (60 إطار)
      final now = DateTime.now().millisecondsSinceEpoch;

      // إعادة تعيين تأثير KO للاعب المحلي بعد 2 ثانية
      if (_showKOEffect['local']! &&
          (now - _lastKOTime['local']!) > 2000) {
        setState(() {
          _showKOEffect['local'] = false;
        });
        // print('🔄 تم إعادة تعيين تأثير KO للاعب المحلي');
      }

      // إعادة تعيين تأثير KO للخصم بعد 2 ثانية
      if (_showKOEffect['remote']! &&
          (now - _lastKOTime['remote']!) > 2000) {
        setState(() {
          _showKOEffect['remote'] = false;
        });
        // print('🔄 تم إعادة تعيين تأثير KO للخصم');
      }
    }
  }

// ✅ دالة تحديث نظام الإحياء (يجب إضافتها مع الدوال الأخرى)
  void _updateRespawnSystem() {
    try {
      // ✅ استخدام الدوال الآمنة
      _respawnCooldown.forEach((playerType, cooldown) {
        if (cooldown is int && cooldown > 0) {
          _respawnCooldown[playerType] = cooldown - 1;
          if (_respawnCooldown[playerType] == 0) {
            // print('🔄 [RESPAWN] بدء إحياء $playerType');

            Future.delayed(Duration(milliseconds: 50), () {
              if (mounted) {
                _respawnPlayer(playerType);
                setState(() {});
              }
            });
          }
        }
      });
    } catch (e) {
      // print('❌ خطأ في _updateRespawnSystem: $e');
      // ✅ إعادة تهيئة المصفوفة في حالة الخطأ
      _respawnCooldown = {'local': 0, 'remote': 0};
    }
  }

  // ✅ دالة للتحقق من حالة الخصم بعد التهيئة
  // void _debugOpponentState() {
  //   // print('🔍 ===== فحص حالة الخصم =====');
  //   if (_gameService.remotePlayer != null) {
  //     print('✅ الخصم موجود في GameService');
  //     print('   🆔 معرف الخصم: ${_gameService.remotePlayer!.playerId}');
  //     print('   🎭 شخصية الخصم: ${_gameService.remotePlayer!.character.name}');
  //     print('   🤖 هل هو بوت؟ ${_isBotGame}');
  //     print('   👤 لاعب حقيقي؟ ${_isRealPlayerMatch}');
  //   } else {
  //     print('❌ الخصم غير موجود في GameService!');
  //   }
  //   print('🔍 ==========================');
  // }

  // ✅ ========== دوال المساعدة ==========
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
      default: return 'almashe';
    }
  }

  void _startFallDeathSystem() {
    _fallDeathTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (!_isGameEnded && !_isPaused && mounted) {
        _checkFallDeathUnified();
        _updateDoubleJumpSystem();
      }
    });
  }

  void _startComboSystem() {
    _comboResetTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      _consecutiveHits['local'] = 0;
      _consecutiveHits['remote'] = 0;
    });
  }

  void _startDoubleJumpSystem() {
    _doubleJumpResetTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_gameService.localPlayer?.isGrounded == true) {
        _canDoubleJump = true;
        _hasDoubleJumped = false;
      }
    });
  }

  void _startPunchSystem() {
    _punchCooldownTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      _canPunch = true;
    });
  }

  void _startThrownWeaponsSystem() {
    Timer.periodic(Duration(milliseconds: 60), (timer) {
      if (!_isGameEnded && !_isPaused && mounted) {
        setState(() {
          _updateThrownWeapons();
        });
      }
    });
  }

  void _startWeaponBounceSystem() {
    _weaponBounceTimer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      if (!_isGameEnded && !_isPaused && mounted) {
        setState(() {
          _updateWeaponBounce();
        });
      }
    });
  }

// ✅ ========== بناء الواجهة ==========
  @override
  Widget build(BuildContext context) {
    try {
      final size = MediaQuery.of(context).size;
      final safeWidth = size.width.isNaN ? 400.0 : size.width;
      final safeHeight = size.height.isNaN ? 800.0 : size.height;

      return Scaffold(
        body: GestureDetector(
          onTapDown: _onTapDown,
          onPanStart: _onDragStart,
          onPanUpdate: _onDragUpdate,
          onPanEnd: _onDragEnd,
          child: Container(
            width: safeWidth,
            height: safeHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1a1a2e),
                  Color(0xFF16213e),
                  Color(0xFF0f3460),
                ],
              ),
            ),
            child: Stack(
              children: [
                // 1. الخلفية والمنصات
                _buildBrawlhallaBackground(safeWidth, safeHeight),
                ..._buildPlatforms(Size(safeWidth, safeHeight)),

                // 2. إضافة مؤشر نمط المنصات
                _buildPlatformPatternIndicator(),

                // 2. الأسلحة
                ..._buildWeaponsOnGround(Size(safeWidth, safeHeight)),
                ..._buildThrownWeapons(Size(safeWidth, safeHeight)),

                // 3. اللاعبون
                ..._buildPlayers(Size(safeWidth, safeHeight)),

                // 4. التأثيرات
                ..._buildKOEffects(Size(safeWidth, safeHeight)),
                ..._buildActiveWeaponAttacks(Size(safeWidth, safeHeight)),

                // 5. واجهة المستخدم
                _buildNewTopBar(),
                _buildGameNotifications(),

                // 6. عناصر التحكم
                if (_currentAmmoWeaponId != null && _weaponAmmo.containsKey(_currentAmmoWeaponId))
                  _buildAmmoCounter(),

                if (_showTutorial)
                  _buildTutorialOverlay(),

                if (_gameService.localPlayer?.weapons.isNotEmpty ?? false)
                  _buildThrowWeaponButton(),

                // ✅ ✅ ✅ أزرار الاختبار - تظهر فقط في وضع DEBUG
                if (DEBUG_MODE) ...[
                  Positioned(
                    bottom: 160,
                    right: 20,
                    child: GestureDetector(
                      onTap: _testSendAttack,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            'TEST\nATTACK',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 220,
                    right: 20,
                    child: GestureDetector(
                      onTap: _testFirebaseAttack,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            'TEST\nFIREBASE',
                            style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      // print('❌ خطأ في بناء الواجهة: $e');
      return _buildErrorScreen(e);
    }
  }

  // ✅ ========== بناء واجهة اللاعبين ==========
  List<Widget> _buildPlayers(Size screenSize) {
    // ✅ إذا انتهت اللعبة، لا نبني اللاعبين
    if (_isGameEnded) return [];

    try {
      final localPlayer = _gameService.localPlayer;
      final remotePlayer = _gameService.remotePlayer;

      // ✅ لا تبني إذا كان اللاعب ميتاً نهائياً
      if (localPlayer == null && remotePlayer == null) return [];

      print('👥 بناء اللاعبين - local: ${localPlayer != null}, remote: ${remotePlayer != null}');

      List<Widget> players = [];

      if (localPlayer != null && _playerLives['local']! > 0) {
        players.add(_buildPlayer(localPlayer, screenSize, true));
      }

      if (remotePlayer != null && _playerLives['remote']! > 0) {
        players.add(_buildPlayer(remotePlayer, screenSize, false));
      }

      if (players.isEmpty) {
        players.add(SizedBox.shrink());
      }

      return players;
    } catch (e) {
      print('❌ خطأ في _buildPlayers: $e');
      return [];
    }
  }

  Widget _buildPlayer(OnlinePlayer player, Size screenSize, bool isLocal) {
    try {
      final playerId = isLocal ? 'local' : 'remote';
      final playerX = _playerSmoothX[playerId] ?? player.x;
      final playerY = _playerSmoothY[playerId] ?? player.y;

      final safeX = (playerX?.isNaN ?? true) ? 0.5 : playerX.clamp(0.0, 1.0);
      final safeY = (playerY?.isNaN ?? true) ? _groundLevel - 0.1 : playerY.clamp(0.0, 1.0);

      return Stack(
        children: [
          Positioned(
            left: safeX * screenSize.width - 30,
            top: safeY * screenSize.height - 40,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..scale((player.isFacingRight ?? true) ? 1.0 : -1.0, 1.0),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(_getSafeFramePath(player.currentFramePath)),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            left: safeX * screenSize.width - 30,
            top: safeY * screenSize.height - 60,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isLocal ? Colors.blue : Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isLocal ? 'أنت' : 'الخصم',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    } catch (e) {
      return SizedBox.shrink();
    }
  }

  // ✅ ========== بناء الأسلحة على الأرض ==========
  List<Widget> _buildWeaponsOnGround(Size screenSize) {
    return _weaponsOnGround.map<Widget>((weaponData) {
      final weapon = weaponData['weapon'] as OnlineWeapon;
      final x = weaponData['x'] as double;
      final y = weaponData['y'] as double;
      final weaponId = weaponData['id'] as String;

      // ✅ الحصول على قيم الاهتزاز والتوهج
      final vibrationOffset = _weaponVibrationOffsets[weaponId] ?? 0.0;
      final glowIntensity = _weaponGlowIntensities[weaponId] ?? 0.3;

      return Positioned(
        left: x * screenSize.width - 20,
        top: (y + vibrationOffset) * screenSize.height - 20,
        child: GestureDetector(
          onTap: () => _pickUpWeaponWithConditions(weaponData),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: weapon.attackColor.withOpacity(glowIntensity),
                  blurRadius: 15,
                  spreadRadius: 3,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(glowIntensity * 0.5),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Stack(
              children: [
                // ✅ صورة السلاح الأساسية
                Image.asset(
                  weapon.imagePath,
                  fit: BoxFit.contain,
                ),

                // ✅ طبقة توهج إضافية
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        weapon.attackColor.withOpacity(glowIntensity * 0.3),
                        Colors.transparent,
                      ],
                      stops: [0.3, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  // ✅ دالة لتهيئة نظام الاهتزاز والتوهج للأسلحة
  void _initializeWeaponVibrationSystem() {
    // print('✨ تهيئة نظام اهتزاز وتوهج الأسلحة');

    // ✅ بدء نظام الاهتزاز لكل سلاح
    _weaponVibrationTimer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      if (!mounted || _isGameEnded || _isPaused) {
        timer.cancel();
        return;
      }

      _updateWeaponVibration();
    });
  }

// ✅ دالة لتحديث اهتزاز وتوهج جميع الأسلحة
  void _updateWeaponVibration() {
    final now = DateTime.now().millisecondsSinceEpoch;

    // ✅ تحديث الأسلحة على الأرض
    for (var weaponData in _weaponsOnGround) {
      final weaponId = weaponData['id'] as String;

      if (!_weaponVibrationOffsets.containsKey(weaponId)) {
        _weaponVibrationOffsets[weaponId] = 0.0;
        _weaponGlowIntensities[weaponId] = 0.0;
      }

      // ✅ حساب اهتزاز خفيف لأعلى ولأسفل
      final spawnTime = weaponData['spawnTime'] as int;
      final timeSinceSpawn = (now - spawnTime) / 1000.0;

      // ✅ اهتزاز بتردد منخفض ومدى صغير
      final vibration = sin(timeSinceSpawn * 4) * 0.008; // اهتزاز خفيف
      _weaponVibrationOffsets[weaponId] = vibration;

      // ✅ توهج خفيف متغير
      final glow = 0.3 + sin(timeSinceSpawn * 3) * 0.2; // توهج متغير
      _weaponGlowIntensities[weaponId] = glow.clamp(0.1, 0.5);
    }

    // ✅ تحديث الأسلحة المقذوفة
    for (var weaponData in _thrownWeapons) {
      final weaponId = weaponData['id'] as String;

      if (weaponData['isActive'] == true && !_weaponVibrationOffsets.containsKey(weaponId)) {
        _weaponVibrationOffsets[weaponId] = 0.0;
      }
    }

    if (mounted) {
      setState(() {});
    }
  }
  // ✅ ========== بناء الأسلحة المقذوفة ==========
  List<Widget> _buildThrownWeapons(Size screenSize) {
    return _thrownWeapons.where((weaponData) => weaponData['isActive'] == true).map<Widget>((weaponData) {
      final weapon = weaponData['weapon'] as OnlineWeapon;
      final x = weaponData['x'] as double;
      final y = weaponData['y'] as double;
      final weaponId = weaponData['id'] as String;
      final rotation = _weaponRotation[weaponId] ?? 0.0;

      // ✅ اهتزاز خفيف للأسلحة المقذوفة
      final vibrationOffset = _weaponVibrationOffsets[weaponId] ?? 0.0;

      return Positioned(
        left: x * screenSize.width - 25,
        top: (y + vibrationOffset) * screenSize.height - 25,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..rotateZ(rotation)
            ..translate(0.0, vibrationOffset * 10), // تضخيم الاهتزاز قليلاً
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: weapon.attackColor.withOpacity(0.4),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Image.asset(
              weapon.imagePath,
              fit: BoxFit.contain,
            ),
          ),
        ),
      );
    }).toList();
  }

  // ✅ ========== بناء شريط المعلومات العلوي ==========
  Widget _buildNewTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black.withOpacity(0.8), Colors.transparent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPlayerInfo(true),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      _formatGameTime(_gameService.gameTimer),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(color: Colors.black, blurRadius: 10, offset: Offset(2, 2)),
                        ],
                      ),
                    ),
                  ),

                  GestureDetector(
                    onTap: _togglePause,
                    child: Container(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        _isPaused ? Icons.play_arrow : Icons.pause,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),

              _buildPlayerInfo(false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerInfo(bool isLocal) {
    final lives = isLocal ? _playerLives['local']! : _playerLives['remote']!;
    final playerName = isLocal ? _localPlayerName : _remotePlayerName;

    return Container(
      width: 80,
      constraints: BoxConstraints(maxHeight: 90),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // اسم اللاعب
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _truncateName(playerName),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              // صورة الشخصية
              Flexible(
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: lives > 0 ? Colors.white : Colors.grey, width: 1),
                    image: DecorationImage(
                      image: AssetImage(_gameService.localPlayer?.character.iconPath ??
                          'assets/images/characters/almashe/almashe_icon.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              // الأرواح المتبقية
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 0.2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(
                      color: lives > 1 ? Colors.green : Colors.red,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.favorite,
                        color: lives > 0 ? Colors.red : Colors.grey,
                        size: 11,
                      ),
                      SizedBox(width: 2),
                      Text(
                        '$lives',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ✅ ========== بناء إشعارات اللعبة ==========
  Widget _buildGameNotifications() {
    if (!_isNotificationVisible || _activeNotifications.isEmpty) {
      return SizedBox.shrink();
    }

    final notification = _activeNotifications.first;

    return Positioned(
      top: 80,
      left: 0,
      right: 0,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        margin: EdgeInsets.symmetric(horizontal: 30, vertical: 5),
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: notification.color.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 10,
              spreadRadius: 2,
              offset: Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.4),
            width: 1.5,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              notification.color.withOpacity(0.9),
              notification.color.withOpacity(0.7),
            ],
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              notification.icon,
              color: Colors.white,
              size: 18,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                notification.message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 2,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ ========== بناء عداد الطلقات ==========
  Widget _buildAmmoCounter() {
    final ammoCount = _weaponAmmo[_currentAmmoWeaponId];

    if (ammoCount == null || ammoCount <= 0) {
      return SizedBox.shrink();
    }

    Color color;
    if (ammoCount > 5) {
      color = Colors.green;
    } else if (ammoCount > 2) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return Positioned(
      top: 100,
      right: 20,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              ammoCount > 5 ? Icons.bolt : Icons.arrow_circle_up,
              color: color,
              size: 16,
            ),
            SizedBox(width: 6),
            Text(
              '$ammoCount',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 6),
            Text(
              'طلقة',
              style: TextStyle(
                color: color,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ ========== بناء زر رمي السلاح ==========
  Widget _buildThrowWeaponButton() {
    return Positioned(
      bottom: 30,
      right: 20,
      child: GestureDetector(
        onTap: _throwWeapon,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.8),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.arrow_upward,
                color: Colors.white,
                size: 24,
              ),
              SizedBox(height: 2),
              Text(
                'رمي',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// ✅ ========== الموت النهائي ==========
  void _handleFinalDeath(String playerType) {
    if (_isGameEnded || _isPaused) return;

    final player = playerType == 'local' ? _gameService.localPlayer : _gameService.remotePlayer;

    if (player != null) {
      print('💀🔥 [FINAL DEATH] $playerType مات نهائياً!');

      // ✅ تعيين حالة الموت النهائي
      player.health = 0;
      player.state = PlayerState.death;
      player.canMove = false;

      // ✅ منع أي حركة أو تغيير
      player.velocityX = 0;
      player.velocityY = 0;

      // ✅ تحديث النتيجة
      if (playerType == 'local') {
        _gameService.remotePlayerScore += 100;
        _winnerName = _remotePlayerName;
      } else {
        _gameService.localPlayerScore += 100;
        _winnerName = _localPlayerName;
      }

      // ✅ تأثيرات الموت النهائي
      _addVisualEffect('final_death', player.x, player.y, color: Colors.red, duration: 3000);
      OnlineAudioService().playDeathSound();

      // ✅ ✅ ✅ أهم شيء: إرسال نهاية اللعبة إلى Firebase
      if (_isRealPlayerMatch) {
        _syncGameEndToFirestore();
      }

      // ✅ ✅ ✅ إرسال نهاية اللعبة عبر LiveKit (أسرع)
      _sendGameEndViaLiveKit();

      // ✅ ✅ ✅ إيقاف حلقة اللعبة فوراً
      _gameLoopController.stop();

      // ✅ عرض شاشة النتائج بعد تأخير بسيط
      Timer(Duration(seconds: 1), () {
        if (mounted && !_hasShownResults) {
          _hasShownResults = true;
          _showResultsDialog();
        }
      });
    }
  }

  void _startPresenceMonitoring() {
    _playerPresenceTimer?.cancel();

    _playerPresenceTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (!mounted || !_isRealPlayerMatch) return;

      _checkPlayerPresence();
    });
  }

  void _checkPlayerPresence() async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final matchDoc = await FirebaseFirestore.instance
          .collection('real_matches_fixed')
          .doc(widget.roomId)
          .get();

      if (!matchDoc.exists) return;

      final data = matchDoc.data() as Map<String, dynamic>;
      final lastUpdate = data['lastPresence'] as Map<String, dynamic>? ?? {};

      // ✅ إذا كانت المباراة انتهت، لا تفعل شيئاً
      if (data['status'] == 'ended' || data['status'] == 'finished') {
        _playerPresenceTimer?.cancel();
        return;
      }

      String currentUserId = await _getCurrentUserId();

      // ✅ تحديث وجودنا
      await FirebaseFirestore.instance
          .collection('real_matches_fixed')
          .doc(widget.roomId)
          .update({
        'lastPresence.$currentUserId': now,
      });

      // ✅ التحقق من وجود الخصم
      if (_opponentId != null && lastUpdate.containsKey(_opponentId)) {
        final opponentLastSeen = lastUpdate[_opponentId] as int;
        final timeSinceLastSeen = now - opponentLastSeen;

        // إذا لم يظهر الخصم لأكثر من 8 ثوانٍ
        if (timeSinceLastSeen > 8000 && !_isGameEnded) {
          // print('⚠️ [PRESENCE] الخصم غير متصل! منذ ${timeSinceLastSeen ~/ 1000} ثانية');

          // تحقق مرة أخرى قبل إنهاء اللعبة
          Future.delayed(Duration(seconds: 2), () {
            if (mounted && !_isGameEnded) {
              _verifyOpponentDisconnected();
            }
          });
        }
      }
    } catch (e) {
      // print('⚠️ خطأ في مراقبة الوجود: $e');
    }
  }

  // ✅ دالة للتحقق النهائي من انقطاع الخصم
  void _verifyOpponentDisconnected() async {
    try {
      final matchDoc = await FirebaseFirestore.instance
          .collection('real_matches_fixed')
          .doc(widget.roomId)
          .get();

      if (!matchDoc.exists) return;

      final data = matchDoc.data() as Map<String, dynamic>;
      final lastUpdate = data['lastPresence'] as Map<String, dynamic>? ?? {};
      final now = DateTime.now().millisecondsSinceEpoch;

      if (_opponentId != null && lastUpdate.containsKey(_opponentId)) {
        final opponentLastSeen = lastUpdate[_opponentId] as int;
        final timeSinceLastSeen = now - opponentLastSeen;

        if (timeSinceLastSeen > 8000 && !_isGameEnded) {
          print('🏆 [DISCONNECT] تأكد انقطاع الخصم - أنت الفائز!');
          _winnerName = _localPlayerName;
          _showGameEndScreen();
        }
      }
    } catch (e) {
      print('⚠️ خطأ في التحقق من الانقطاع: $e');
    }
  }

  // ✅ ========== الإحياء في مكان عشوائي ==========
// ✅ دالة آمنة للحصول على القيم
  bool _getPlayerBoolValue(Map<String, bool> map, String playerType, bool defaultValue) {
    if (!map.containsKey(playerType)) {
      return defaultValue;
    }
    final value = map[playerType];
    return value is bool ? value : defaultValue;
  }

// ✅ استخدام الدوال الآمنة في الكود
  void _checkFallDeathEnhanced() {
    if (_isGameEnded || _isPaused) return;

    final checkPlayer = (OnlinePlayer? player, String playerType) {
      if (player == null) return;

      // ✅ التحقق الأول: إذا كان اللاعب ميتاً بالفعل، لا تفعل شيئاً
      if (player.state == PlayerState.death) return;

      if (_getPlayerBoolValue(_playerIsRespawning, playerType, false)) return;
      if (_playerLives[playerType]! <= 0) return;

      // ✅ تحقق من الموت فقط إذا كان اللاعب تحت الأرض كثيراً
      // زيادة الحد من 1.3 إلى 1.5 لمنع الموت المفاجئ
      if (player.y > 1.5) {
        print('💀 [$playerType] الموت بالسقوط خارج الحدود! (y=${player.y.toStringAsFixed(2)})');
        player.isGrounded = false;
        _handlePlayerDeath(playerType);
        return;
      }

      // ✅ إذا كان اللاعب تحت الأرض قليلاً (بين 1.2 و 1.5)، حاول تصحيحه بدلاً من قتله
      if (player.y > 1.2 && player.y <= 1.5 && player.state != PlayerState.death) {
        print('⚠️ [$playerType] لاعب تحت الأرض قليلاً، تصحيح الموقع');
        // تصحيح الموقع إلى فوق المنصة
        player.y = 0.7;
        player.velocityY = 0;
        player.isGrounded = true;
      }
    };

    checkPlayer(_gameService.localPlayer, 'local');
    checkPlayer(_gameService.remotePlayer, 'remote');
  }

  // ✅ تعديل دالة التحقق من الفجوات
  bool _isInEmptySpace(OnlinePlayer player) {
    if (player.isGrounded || player.velocityY <= 0) {
      return false;
    }

    // ✅ استخدام الفجوات الاستراتيجية المولدة
    for (var gap in _strategicGaps) {
      final left = gap['left'] as double;
      final right = gap['right'] as double;
      final name = gap['name'] as String;

      if (player.x > left && player.x < right) {
        if (!player.isGrounded && player.velocityY > 0.01) {
          // print('⚠️ اللاعب يسقط في منطقة فارغة: $name');
          return true;
        }
      }
    }

    return false;
  }

  void _throwWeapon() {
    if (_gameService.localPlayer == null ||
        _isGameEnded ||
        _isPaused ||
        _gameService.localPlayer!.weapons.isEmpty) {
      return;
    }

    final player = _gameService.localPlayer!;
    final currentWeapon = player.currentWeapon;

    if (currentWeapon == null) return;

    player.weapons.remove(currentWeapon);

    if (player.weapons.isNotEmpty) {
      player.currentWeaponIndex = 0;
    } else {
      player.currentWeaponIndex = -1;
      setState(() {
        _showAmmoCounter = false;
        _currentAmmoWeaponId = null;
      });
    }

    final weaponData = {
      'weapon': currentWeapon,
      'x': player.x,
      'y': player.y,
      'id': 'weapon_${DateTime.now().millisecondsSinceEpoch}',
      'spawnTime': DateTime.now().millisecondsSinceEpoch,
      'type': currentWeapon.type.toString(),
      'isThrown': true,
      'owner': 'player',
      'velocityX': player.isFacingRight ? 0.03 : -0.03,
      'velocityY': -0.02,
      'isMoving': true,
    };

    setState(() {
      _weaponsOnGround.add(weaponData);
    });

    _addVisualEffect(
      'weapon_throw',
      player.x,
      player.y,
      color: Colors.orange,
      duration: 500,
    );

    // ✅ تغيير من attacking إلى attacking_light
    player.state = PlayerState.attacking_light;
    player.attackCooldown = 20;

    Timer(Duration(milliseconds: 500), () {
      if (_gameService.localPlayer != null) {
        _gameService.localPlayer!.state = PlayerState.idle;
      }
    });
  }

// ✅ ========== تعديل دالة الملاكمة ==========
  void _performPunch() {
    if (_gameService.localPlayer != null && _canPunch && !_isGameEnded && !_isPaused) {
      final player = _gameService.localPlayer!;
      player.state = PlayerState.attacking_light;  // ✅ تغيير من attacking إلى attacking_light

      if (_gameService.remotePlayer != null) {
        final enemy = _gameService.remotePlayer!;
        final distance = sqrt(pow(player.x - enemy.x, 2) + pow(player.y - enemy.y, 2));

        if (distance < 0.03) {
          _applyDamageToOpponent(10, 'punch');
          _canPunch = false;
        }
      }

      Timer(Duration(milliseconds: 500), () {
        if (_gameService.localPlayer != null) {
          _gameService.localPlayer!.state = PlayerState.idle;
        }
      });
    }
  }

  void _checkPlayerCollisions() {
    try {
      final localPlayer = _gameService.localPlayer;
      final remotePlayer = _gameService.remotePlayer;

      if (localPlayer == null || remotePlayer == null) return;

      final distance = sqrt(pow(localPlayer.x - remotePlayer.x, 2) +
          pow(localPlayer.y - remotePlayer.y, 2));

      if (distance < 0.03) {
        // ✅ تغيير من attacking إلى attacking_light
        if ((localPlayer.state == PlayerState.attacking_light ||
            localPlayer.state == PlayerState.attacking_heavy) &&
            localPlayer.weapons.isEmpty &&
            _canPunch) {
          _applyDamageToOpponent(_punchDamage.toInt(), 'punch');
          _canPunch = false;
          _syncAttackToFirestore('punch', _punchDamage.toInt());
        }
      }
    } catch (e) {
      // print('❌ خطأ في التحقق من التصادم: $e');
    }
  }

  void _sendGameEndViaLiveKit() {
    if (!_useLiveKit || !_liveKitService.isConnected) return;

    _liveKitService.sendGameEnd(
      winner: _winnerName ?? 'local',
      reason: 'elimination',
    );
  }

  void _onRemoteGameEndLiveKit(Map<String, dynamic> data) {
    if (_isGameEnded) return;

    final winner = data['winner'] as String? ?? 'remote';
    print('🏆 [LIVEKIT] نهاية اللعبة - الفائز: $winner');

    setState(() {
      _isGameEnded = true;
      _winnerName = winner == 'local' ? _localPlayerName : _remotePlayerName;
    });

    _gameLoopController.stop();
    _showResultsDialog();
  }

  Future<void> _testSendAttack() async {
    print('🧪 [TEST] بدء اختبار إرسال هجوم...');

    if (_gameService.localPlayer == null) {
      print('❌ [TEST] لا يوجد لاعب محلي');
      return;
    }

    final localPlayer = _gameService.localPlayer!;

    // إنشاء هجوم تجريبي
    final testAttack = OnlineBattleAttack(
      type: OnlineAttackType.light,
      x: localPlayer.x + (localPlayer.isFacingRight ? 0.08 : -0.08),
      y: localPlayer.y - 0.02,
      directionX: localPlayer.isFacingRight ? 1.0 : -1.0,
      damage: 15,
      speed: 0.03,
      range: 0.1,
      color: Colors.red,
      weaponImagePath: 'assets/online/weapons/sword.png',
      isActive: true,
      lifetime: 120,
    );

    // ✅ إرسال عبر SyncService
    await _syncService.sendFullAttack(testAttack);

    // ✅ إضافة محلياً أيضاً
    setState(() {
      _gameService.activeAttacks.add(testAttack);
    });

    print('✅ [TEST] تم إرسال هجوم تجريبي');
  }

  // ✅ تهيئة نظام تنظيف الهجمات
  void _initializeAttackCleanup() {
    _attackCleanupTimer?.cancel();
    _attackCleanupTimer = Timer.periodic(Duration(seconds: 2), (_) {
      _processedAttackHashes.clear();
      _attackCountByPosition.clear();
    });
  }

  // ✅ دالة جديدة لتنظيف الهجمات القديمة في _updateGame
  void _cleanupOldAttacks() {
    final now = DateTime.now().millisecondsSinceEpoch;

    // ✅ إزالة الهجمات المنتهية
    _gameService.activeAttacks.removeWhere((attack) {
      return attack.lifetime <= 0 || !attack.isActive;
    });

    // ✅ منع التكدس - حد أقصى 20 هجوم
    if (_gameService.activeAttacks.length > 20) {
      print('⚠️ [CLEANUP] تقليل عدد الهجمات من ${_gameService.activeAttacks.length} إلى 20');

      // الاحتفاظ بأحدث 20 هجوم
      _gameService.activeAttacks.sort((a, b) => b.lifetime.compareTo(a.lifetime));

      // إزالة الهجمات الأقدم
      while (_gameService.activeAttacks.length > 20) {
        _gameService.activeAttacks.removeLast();
      }
    }

    // ✅ تنظيف Set الهجمات المعالجة كل 5 ثواني
    if (_frameCounter % 300 == 0) { // كل 5 ثواني (60fps * 5)
      _processedAttackHashes?.clear();
    }

    // ✅ تنظيف خريطة الهجمات المعالجة القديمة
    _lastProcessedAttackTimes.removeWhere((key, timestamp) {
      return now - timestamp > 15000; // أقدم من 15 ثانية
    });
  }

  Future<void> _testFirebaseAttack() async {
    print('🧪 [TEST FIREBASE] بدء اختبار إرسال هجوم...');

    if (_gameService.localPlayer == null) {
      print('❌ [TEST] لا يوجد لاعب محلي');
      return;
    }

    final localPlayer = _gameService.localPlayer!;

    // ✅ إنشاء هجوم تجريبي في موقع اللاعب
    final testAttack = OnlineBattleAttack(
      type: OnlineAttackType.light,
      x: localPlayer.x + (localPlayer.isFacingRight ? 0.15 : -0.15),
      y: localPlayer.y - 0.02,
      directionX: localPlayer.isFacingRight ? 1.0 : -1.0,
      damage: 15,
      speed: 0.03,
      range: 0.1,
      color: Colors.red,
      weaponImagePath: 'assets/online/weapons/sword.png',
      isActive: true,
      lifetime: 120,
    );

    // ✅ إرسال عبر SyncService
    await _syncService.sendFullAttack(testAttack);

    print('✅ [TEST] تم إرسال هجوم تجريبي');
  }

  // ✅ دالة محسنة لإنشاء وعرض الهجوم مع منع التكدس
  void _createAndShowAttack(Map<String, dynamic> attackData) {
    // ⚠️ هذه الدالة تسبب تكرار الهجمات
    // الحل: إما تعطيلها تماماً أو تعديلها

    print('⚠️ [WARNING] تم استدعاء _createAndShowAttack - هذه الدالة يجب ألا تستخدم');

    // إذا أردت الاحتفاظ بها للاختبارات، أضف شرطاً صارماً
    if (attackData['test'] == true) {
      try {
        final attackX = (attackData['x'] as num?)?.toDouble() ?? 0;
        final attackY = (attackData['y'] as num?)?.toDouble() ?? 0;

        print('🧪 [TEST] إنشاء هجوم تجريبي في ($attackX, $attackY)');

        final attack = OnlineBattleAttack(
          type: OnlineAttackType.light,
          x: attackX,
          y: attackY,
          directionX: 1.0,
          damage: 10,
          speed: 0.03,
          range: 0.1,
          color: Colors.red,
          weaponImagePath: 'assets/online/weapons/sword.png',
          isActive: true,
          lifetime: 45,
        );

        _gameService.activeAttacks.add(attack);
        if (mounted) setState(() {});
      } catch (e) {
        print('⚠️ خطأ في إنشاء الهجوم التجريبي: $e');
      }
    }
  }

// دالة مساعدة جديدة
  void _applyDamageToLocalPlayer(int damage) {
    if (_gameService.localPlayer == null) return;

    _gameService.localPlayer!.health -= damage.toDouble();

    if (_gameService.localPlayer!.health > 0) {
      _gameService.localPlayer!.state = PlayerState.hurt;
      _gameService.localPlayer!.damageCooldown = 30;
    } else {
      _gameService.localPlayer!.health = 0;
      _gameService.localPlayer!.state = PlayerState.death;
      _handlePlayerDeath('local');
    }
  }

// ✅ دالة محسنة لمزامنة الضربات
  Future<void> _syncAttackToFirestore(String attackType, int damage) async {
    // ✅ إرسال الهجوم عبر LiveKit أولاً
    if (_useLiveKit && _liveKitService.isConnected && _gameService.localPlayer != null) {
      _liveKitService.sendAttack(
        x: _gameService.localPlayer!.x,
        y: _gameService.localPlayer!.y,
        damage: damage,
        weaponType: attackType,
        isFacingRight: _gameService.localPlayer!.isFacingRight,
      );
      print('⚔️ [LIVEKIT] تم إرسال هجوم: $attackType ضرر $damage');
      return; // لا نرسل إلى Firebase
    }
  }

  // ✅ ========== دالة موحدة لتطبيق الضرر ==========
// ✅ دالة موحدة لتطبيق الضرر (مع إرسال الضربة)
  void _applyDamageToOpponent(int damage, String damageType) {
    if (_gameService.remotePlayer == null || _isGameEnded || _isPaused) return;

    final opponent = _gameService.remotePlayer!;

    opponent.health -= damage.toDouble();
    opponent.state = PlayerState.hurt;  // ✅ تغيير من damaged إلى hurt
    opponent.canMove = false;
    opponent.damageCooldown = 30;

    _gameService.localPlayerScore += damage;

    _addVisualEffect(
      damageType == 'punch' ? 'punch_hit' : 'weapon_hit',
      opponent.x,
      opponent.y,
      color: Colors.red,
      duration: 300,
    );

    final localPlayer = _gameService.localPlayer;
    if (localPlayer != null) {
      final direction = (localPlayer.x - opponent.x).sign;
      opponent.velocityX = -direction * 0.02;
      opponent.velocityY = -0.01;
    }

    if (damageType == 'punch') {
      OnlineAudioService().playPunchSound();
    } else {
      OnlineAudioService().playWeaponHitSound();
    }

    _syncAttackToFirestore(damageType, damage);

    if (opponent.health <= 0) {
      opponent.health = 0;
      opponent.state = PlayerState.death;
      _handlePlayerDeath('remote');
    }
  }

  // ✅ دالة معالجة موت اللاعب
  void _handlePlayerDeath(String playerType) {
    // ✅ منع معالجة الموت المتكرر
    if (_playerIsRespawning[playerType] == true) return;

    // ✅ التحقق من عدد الأرواح
    if (_playerLives[playerType]! <= 0) {
      print('⚠️ [$playerType] لا توجد أرواح متبقية، لن يموت مرة أخرى');
      return;
    }

    final player = playerType == 'local'
        ? _gameService.localPlayer
        : _gameService.remotePlayer;

    if (player == null) return;

    // ✅ إذا كان اللاعب ميتاً بالفعل، لا تعالج مرة أخرى
    if (player.state == PlayerState.death) return;

    print('💀 [$playerType] مات - الحياة المتبقية: ${_playerLives[playerType]! - 1}');

    // ✅ فقدان الأسلحة
    _dropPlayerWeapons(player, playerType);

    // ✅ تحديد ما إذا كان الموت نهائياً (الأرواح <= 1)
    final isFinalDeath = _playerLives[playerType]! <= 1;

    // ✅ تحديث عدد الأرواح أولاً
    setState(() {
      _playerLives[playerType] = _playerLives[playerType]! - 1;
    });

    // ✅ إرسال الموت إلى Firebase
    if (_isRealPlayerMatch) {
      _syncPlayerDeathToFirestore(playerType);
    }

    // ✅ بدء أنيميشن الموت
    player.startDeath(isFinalDeath);

    // ✅ تحديث النتيجة
    if (playerType == 'local') {
      _gameService.remotePlayerScore += 10;
    } else {
      _gameService.localPlayerScore += 10;
    }

    // ✅ تأثيرات الموت
    _addVisualEffect('death', player.x, player.y, color: Colors.red, duration: 1500);
    OnlineAudioService().playDeathSound();

    // ✅ إذا كان الموت مؤقتاً وتبقت أرواح، ابدأ الإحياء
    if (!isFinalDeath && _playerLives[playerType]! > 0) {
      _playerIsRespawning[playerType] = true;
      Timer(Duration(seconds: 1), () {
        if (mounted && !_isGameEnded) {
          _respawnPlayer(playerType);
        }
      });
    } else if (isFinalDeath) {
      // ✅ موت نهائي
      _handleFinalDeath(playerType);
    }
  }

  // ✅ دالة جديدة لمزامنة الموت مع Firestore
  Future<void> _syncPlayerDeathToFirestore(String playerType) async {
    if (!_isRealPlayerMatch) return;

    String deadPlayerId = playerType == 'local' ? _userId : _opponentId ?? '';
    if (deadPlayerId.isEmpty) return;

    try {
      await _syncService.sendDeath(deadPlayerId, _playerLives[playerType]!);
      print('📤 [DEATH] تم مزامنة موت $playerType مع Firebase');
    } catch (e) {
      print('⚠️ [DEATH] خطأ في مزامنة الموت: $e');
    }
  }

  // ✅ دالة لإسقاط أسلحة اللاعب
  void _dropPlayerWeapons(OnlinePlayer player, String playerType) {
    if (player.weapons.isEmpty) return;

    final random = Random();

    for (var weapon in player.weapons) {
      // ✅ حساب موقع إسقاط السلاح
      double dropX = player.x + (random.nextDouble() * 0.15 - 0.075);
      double dropY = player.y + 0.05;

      // ✅ إنشاء بيانات السلاح المسقط
      final droppedWeapon = {
        'weapon': weapon,
        'x': dropX,
        'y': dropY,
        'id': 'dropped_${playerType}_${DateTime.now().millisecondsSinceEpoch}',
        'spawnTime': DateTime.now().millisecondsSinceEpoch,
        'owner': playerType,
        'isDropped': true,
        'lifetime': 60, // 60 ثانية قبل أن تختفي
      };

      // ✅ إضافة السلاح للأرض
      setState(() {
        _weaponsOnGround.add(droppedWeapon);
        _droppedWeapons[playerType]!.add(droppedWeapon);
      });

      // print('🗡️ [$playerType] إسقاط سلاح: ${weapon.name} في ($dropX, $dropY)');
    }

    // ✅ تأثيرات بصرية
    _addVisualEffect(
      'weapons_drop',
      player.x,
      player.y,
      color: Colors.orange,
      duration: 800,
    );

    // ✅ مسح أسلحة اللاعب
    player.weapons.clear();
    player.currentWeaponIndex = 0;

    // ✅ إخفاء عداد الذخيرة إذا كان اللاعب المحلي
    if (playerType == 'local') {
      setState(() {
        _showAmmoCounter = false;
        _currentAmmoWeaponId = null;
        _weaponAmmo.clear();
      });
    }
  }

// ✅ دالة لاستعادة الأسلحة بعد الإحياء
  void _restorePlayerWeaponsAfterRespawn(OnlinePlayer player, String playerType) {
    final random = Random();

    // ✅ فرصة 50% لاستعادة سلاح واحد بعد الموت
    if (random.nextDouble() < 0.5 && _droppedWeapons[playerType]!.isNotEmpty) {
      // ✅ استعادة سلاح عشوائي من الأسلحة المسقطة
      final availableWeapons = _droppedWeapons[playerType]!
          .where((w) => _weaponsOnGround.contains(w))
          .toList();

      if (availableWeapons.isNotEmpty) {
        final weaponToRestore = availableWeapons[random.nextInt(availableWeapons.length)];
        final weapon = weaponToRestore['weapon'] as OnlineWeapon;

        player.weapons.add(weapon);

        // ✅ إزالة السلاح من الأرض
        setState(() {
          _weaponsOnGround.remove(weaponToRestore);
          _droppedWeapons[playerType]!.remove(weaponToRestore);
        });

        // print('🔄 [$playerType] تمت استعادة السلاح: ${weapon.name} بعد الإحياء');

        // ✅ إذا كان اللاعب المحلي، تحديث عداد الذخيرة
        if (playerType == 'local') {
          final ammoCount = 2 + random.nextInt(4); // 2-5 طلقات
          _weaponAmmo[weapon.type.toString()] = ammoCount;
          _currentAmmoWeaponId = weapon.type.toString();
          _showAmmoCounter = true;

          _showGameNotification(
            id: 'weapon_restored_${DateTime.now().millisecondsSinceEpoch}',
            message: 'تمت استعادة ${weapon.name} ($ammoCount طلقة)',
            color: Colors.green,
            icon: Icons.auto_fix_high,
            durationSeconds: 2,
          );
        }
      }
    } else {
      // ✅ إذا لم يحصل على سلاح، أعطيه فرصة للملاكمة فقط
      // print('👊 [$playerType] سيعتمد على الملاكمة فقط');

      if (playerType == 'local') {
        _showGameNotification(
          id: 'no_weapon_restored',
          message: 'لم تحصل على سلاح! استخدم الملاكمة',
          color: Colors.orange,
          icon: Icons.warning,
          durationSeconds: 3,
        );
      }
    }
  }

// ✅ دالة تنظيف الأسلحة المسقطة القديمة
  void _cleanupOldDroppedWeapons() {
    final now = DateTime.now().millisecondsSinceEpoch;

    for (var playerType in ['local', 'remote']) {
      final weaponsToRemove = <Map<String, dynamic>>[];

      for (var weapon in _droppedWeapons[playerType]!) {
        final spawnTime = weapon['spawnTime'] as int;
        final age = (now - spawnTime) / 1000.0;

        if (age > 60) { // بعد 60 ثانية
          weaponsToRemove.add(weapon);
        }
      }

      if (weaponsToRemove.isNotEmpty) {
        setState(() {
          for (var weapon in weaponsToRemove) {
            _weaponsOnGround.remove(weapon);
            _droppedWeapons[playerType]!.remove(weapon);
          }
        });

        // print('🗑️ تم تنظيف ${weaponsToRemove.length} سلاح مسقط قديم لـ $playerType');
      }
    }
  }

// ✅ دالة بدء عداد الإحياء
  void _startRespawnCooldown(String playerType) {
    if (mounted) {
      setState(() {
        _respawnCooldown[playerType] = 60;
        _playerIsRespawning[playerType] = true;
      });
    }
    print('⏳ [$playerType] سيُعاد إحياؤه بعد 1 ثانية...');
  }

  void _recordHit(String playerType) {
    _consecutiveHits[playerType] = (_consecutiveHits[playerType] ?? 0) + 1;

    if (_consecutiveHits[playerType]! >= 5) {
      _instantKO(playerType == 'local' ? 'remote' : 'local');
      _consecutiveHits[playerType] = 0;
    }
  }

  void _instantKO(String playerType) {
    final player = playerType == 'local' ? _gameService.localPlayer : _gameService.remotePlayer;
    if (player != null) {
      player.health = 0;

      setState(() {
        _showKOEffect[playerType] = true;
        _lastKOTime[playerType] = DateTime.now().millisecondsSinceEpoch;
      });

      OnlineAudioService().playSpecialAttackSound();
      _handlePlayerDeath(playerType);

      // print('💥 [INSTANT KO] $playerType - تم تسجيل وقت: ${_lastKOTime[playerType]}');
    }
  }

  void _checkPlayerDeaths() {
    if (_gameService.localPlayer?.state == PlayerState.death) {
      _handlePlayerDeath('local');
    }

    if (_gameService.remotePlayer?.state == PlayerState.death) {
      _handlePlayerDeath('remote');
    }
  }

  void _updateCeilingStickiness() {
    final player = _gameService.localPlayer;
    if (player != null && player.y < 0.1) {
      player.velocityY += 0.002;
    }
  }

  void _applySmartCeilingGravity() {
    final localPlayer = _gameService.localPlayer;
    final remotePlayer = _gameService.remotePlayer;

    if (localPlayer != null && !localPlayer.isGrounded) {
      if (localPlayer.velocityY.abs() < 0.005 && localPlayer.y < 0.3) {
        localPlayer.velocityY += 0.0015;
      }

      if (localPlayer.y < -0.05) {
        localPlayer.y = -0.04;
        localPlayer.velocityY = 0.03;
      }
    }

    if (remotePlayer != null && !remotePlayer.isGrounded) {
      if (remotePlayer.velocityY.abs() < 0.005 && remotePlayer.y < 0.3) {
        remotePlayer.velocityY += 0.0015;
      }

      if (remotePlayer.y < -0.05) {
        remotePlayer.y = -0.04;
        remotePlayer.velocityY = 0.03;
      }
    }
  }

  void _updateWeaponsPhysics() {
    for (var weaponData in _weaponsOnGround) {
      if (weaponData['isMoving'] == true) {
        double vx = weaponData['velocityX'] ?? 0.0;
        double vy = weaponData['velocityY'] ?? 0.0;

        vy += 0.0003;

        weaponData['x'] = (weaponData['x'] as double) + vx;
        weaponData['y'] = (weaponData['y'] as double) + vy;

        vx *= 0.95;
        vy *= 0.95;

        if (vx.abs() < 0.001 && vy.abs() < 0.001) {
          weaponData['isMoving'] = false;
          weaponData['velocityX'] = 0.0;
          weaponData['velocityY'] = 0.0;
        } else {
          weaponData['velocityX'] = vx;
          weaponData['velocityY'] = vy;
        }
      }
    }
  }

  void _checkThrownWeaponsCollision() {
    if (_gameService.remotePlayer == null) return;

    final opponent = _gameService.remotePlayer!;

    for (var weaponData in List.from(_weaponsOnGround)) {
      if (weaponData['owner'] == 'player' && weaponData['isMoving'] == true) {
        final distance = sqrt(
            pow(weaponData['x'] - opponent.x, 2) +
                pow(weaponData['y'] - opponent.y, 2)
        );

        if (distance < 0.06) {
          final weapon = weaponData['weapon'] as OnlineWeapon;
          // ✅ تصحيح: إضافة المعامل الثاني 'weapon'
          _applyDamageToOpponent(weapon.damage, 'weapon');

          setState(() {
            _weaponsOnGround.remove(weaponData);
          });

          break;
        }
      }
    }
  }

  void _updateSmoothPlayerPositions() {
    if (_gameService.localPlayer != null) {
      _updateSmoothPosition('local', _gameService.localPlayer!);
    }
    if (_gameService.remotePlayer != null) {
      _updateSmoothPosition('remote', _gameService.remotePlayer!);
    }
  }

  void _updateSmoothPosition(String playerId, OnlinePlayer player) {
    if (!_playerTargetX.containsKey(playerId)) {
      _playerTargetX[playerId] = player.x;
      _playerSmoothX[playerId] = player.x;
      _playerTargetY[playerId] = player.y;
      _playerSmoothY[playerId] = player.y;
    }

    _playerTargetX[playerId] = player.x;
    _playerTargetY[playerId] = player.y;

    final smoothFactor = 0.2; // يمكن تقليل هذا الرقم لزيادة السلاسة (مثلاً 0.15)
    _playerSmoothX[playerId] = _playerSmoothX[playerId]! + (_playerTargetX[playerId]! - _playerSmoothX[playerId]!) * smoothFactor;
    _playerSmoothY[playerId] = _playerSmoothY[playerId]! + (_playerTargetY[playerId]! - _playerSmoothY[playerId]!) * smoothFactor;
  }

  void _updateWeaponBounce() {
    final now = DateTime.now().millisecondsSinceEpoch;
    for (var weaponData in _weaponsOnGround) {
      final weaponId = weaponData['id'] as String;
      if (!_weaponBounceOffsets.containsKey(weaponId)) {
        _weaponBounceOffsets[weaponId] = 0.0;
        _weaponBounceDirections[weaponId] = 1.0;
      }
      final spawnTime = weaponData['spawnTime'] as int;
      final timeSinceSpawn = (now - spawnTime) / 1000.0;
      final bounce = sin(timeSinceSpawn * 3) * 0.02;
      _weaponBounceOffsets[weaponId] = bounce;
    }
  }

  void _updateThrownWeapons() {
    _thrownWeapons.removeWhere((weaponData) {
      return DateTime.now().millisecondsSinceEpoch - weaponData['throwTime'] > 3000;
    });

    for (var weaponData in _thrownWeapons) {
      final weaponId = weaponData['id'] as String;
      final direction = weaponData['directionX'] as double;
      final speed = 0.03;

      weaponData['x'] = (weaponData['x'] as double) + (direction * speed);

      if (!_weaponRotation.containsKey(weaponId)) {
        _weaponRotation[weaponId] = 0.0;
      }
      _weaponRotation[weaponId] = _weaponRotation[weaponId]! + 0.3;
    }

    _thrownWeapons.removeWhere((weaponData) => weaponData['isActive'] == false);
  }

  void _updateVisualEffects() {
    final now = DateTime.now().millisecondsSinceEpoch;

    _visualEffects.removeWhere((effect) {
      final endTime = effect['startTime'] + effect['duration'];
      return now > endTime;
    });
  }

  void _checkGroundCollision() {
    // التحقق من اللاعب المحلي
    if (_gameService.localPlayer != null) {
      _checkSinglePlayerCollision(_gameService.localPlayer!, 'local');
    }

    // التحقق من الخصم
    if (_gameService.remotePlayer != null) {
      _checkSinglePlayerCollision(_gameService.remotePlayer!, 'remote');
    }
  }

// ✅ دالة مساعدة للتحقق من تصادم لاعب واحد
  void _checkSinglePlayerCollision(OnlinePlayer player, String playerType) {
    if (player == null) return;

    // ✅ إذا قفزنا في هذا الإطار، لا نصحح الموقع
    if (_justJumped[playerType] == true &&
        _jumpFrameLock[playerType] == _frameCounter) {
      return;
    }

    final wasGrounded = player.isGrounded;
    final isOnPlatform = _gameService.checkPlayerPlatformCollision(player);

    if (isOnPlatform) {
      player.isGrounded = true;

      if (player.state == PlayerState.falling) {
        player.state = PlayerState.idle;
      }
    } else if (player.velocityY > 0.001) {
      player.isGrounded = false;
    }

    // ✅ إعادة تعيين قفل القفز في الإطار التالي
    if (_justJumped[playerType] == true &&
        _jumpFrameLock[playerType] != _frameCounter) {
      _justJumped[playerType] = false;
    }
  }

  void _syncPlatformsToFirestore({int retryCount = 0}) async {
    if (!_isRealPlayerMatch || !_isHost) {
      print('⚠️ [SYNC] لست مضيفاً أو ليست مباراة حقيقية');
      return;
    }

    // ✅ التحقق من وجود منصات
    if (_randomPlatforms.isEmpty) {
      print('⚠️ [SYNC] لا توجد منصات للمزامنة! العدد = ${_randomPlatforms.length}');

      if (retryCount < 3) {
        print('🔄 [SYNC] إعادة محاولة المزامنة بعد 0.5 ثانية (محاولة ${retryCount + 1})');
        await Future.delayed(Duration(milliseconds: 500));
        _syncPlatformsToFirestore(retryCount: retryCount + 1);
      } else {
        print('❌ [SYNC] فشلت المحاولات، استخدام منصات افتراضية');
        _useDefaultPlatforms();
        if (_randomPlatforms.isNotEmpty) {
          _syncPlatformsToFirestore(retryCount: 0);
        }
      }
      return;
    }

    const maxRetries = 3;

    try {
      List<Map<String, dynamic>> platformsJson = _randomPlatforms.map((platform) {
        return {
          'x': platform.x,
          'y': platform.y,
          'width': platform.width,
          'height': platform.height,
          'type': platform.type,
          'color': platform.color.value,
        };
      }).toList();

      print('📤 [SYNC] مزامنة ${platformsJson.length} منصة مع Firebase...');

      await FirebaseFirestore.instance
          .collection('real_matches_fixed')
          .doc(widget.roomId)
          .set({
        'platforms': platformsJson,
        'platformPattern': _platformPatternName,
        'platformsSynced': true,
        'lastPlatformSync': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));

      print('✅ [SYNC] تم مزامنة ${platformsJson.length} منصة بنجاح');

    } catch (e) {
      print('⚠️ [SYNC] خطأ في المزامنة (محاولة ${retryCount + 1}): $e');

      if (retryCount < maxRetries) {
        await Future.delayed(Duration(seconds: 1));
        _syncPlatformsToFirestore(retryCount: retryCount + 1);
      } else {
        print('❌ [SYNC] فشلت جميع محاولات مزامنة المنصات');
      }
    }
  }

// ✅ دالة للاستماع لتحديثات المنصات (محسنة للضيف)
  void _listenToPlatformUpdates() {
    print('👂 [PLATFORM] بدء الاستماع لتحديثات المنصات...');

    // ✅ إلغاء الاشتراك السابق
    _platformSubscription?.cancel();

    _platformSubscription = FirebaseFirestore.instance
        .collection('real_matches_fixed')
        .doc(widget.roomId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists || !mounted) return;

      final data = snapshot.data() as Map<String, dynamic>;

      // ✅ التحقق من وجود منصات
      if (data.containsKey('platforms') && data['platforms'] != null) {
        final platformsData = data['platforms'] as List<dynamic>?;

        if (platformsData != null && platformsData.isNotEmpty) {
          // ✅ تجنب إعادة التحديث إذا كانت المنصات نفسها
          final platformsSynced = data['platformsSynced'] as bool? ?? false;
          final lastSync = data['lastPlatformSync'] as int? ?? 0;

          if (platformsSynced || lastSync > 0) {
            _syncPlatformsFromFirestore(platformsData);
            print('📥 [PLATFORM] تم استلام ${platformsData.length} منصة من Firebase');
          }
        }
      }

      // ✅ إذا كنا ضيفاً ولم تصل منصات بعد، أظهر رسالة انتظار
      if (!_isHost && _randomPlatforms.isEmpty && data['platforms'] == null) {
        print('⏳ [PLATFORM] في انتظار المنصات من المضيف...');
      }

    }, onError: (error) {
      print('⚠️ [PLATFORM] خطأ في الاستماع: $error');

      // ✅ محاولة إعادة الاتصال بعد تأخير
      Future.delayed(Duration(seconds: 3), () {
        if (mounted && !_isGameEnded) {
          _listenToPlatformUpdates();
        }
      });
    });
  }

// ✅ دالة لمزامنة المنصات من Firestore
  void _syncPlatformsFromFirestore(List<dynamic> platformsData) {
    try {
      List<BattlePlatform> newPlatforms = [];

      for (var platformJson in platformsData) {
        final p = platformJson as Map<String, dynamic>;
        newPlatforms.add(BattlePlatform(
          x: p['x'],
          y: p['y'],
          width: p['width'],
          height: p['height'],
          type: p['type'],
          color: Color(p['color']),
        ));
      }

      setState(() {
        _randomPlatforms = newPlatforms;
      });

      // print('📥 تم تحديث المنصات من Firestore');
    } catch (e) {
      // print('⚠️ خطأ في مزامنة المنصات: $e');
    }
  }

  void _validatePlatforms() {
    if (_randomPlatforms.isEmpty && _gameService.platforms.isNotEmpty) {
      _randomPlatforms = _gameService.platforms;
    }

    // ✅ التحقق من عدم وجود منصات متداخلة
    for (int i = 0; i < _randomPlatforms.length; i++) {
      for (int j = i + 1; j < _randomPlatforms.length; j++) {
        final p1 = _randomPlatforms[i];
        final p2 = _randomPlatforms[j];

        if (p1.overlaps(p2)) {
          // print('⚠️ ⚠️ ⚠️ تحذير: منصات متداخلة!');
          // print('   ${p1.type} في (${p1.x}, ${p1.y})');
          // print('   ${p2.type} في (${p2.x}, ${p2.y})');

          // ✅ إصلاح تلقائي: تحريك المنصة الثانية
          _randomPlatforms[j] = p2.copyWith(
            x: p2.x + 0.1,
            y: p2.y - 0.05,
          );

          // ✅ تحديث gameService
          _gameService.platforms = _randomPlatforms;
        }
      }
    }
  }

  bool _isPlayerOnPlatform(OnlinePlayer player, BattlePlatform platform) {
    final playerBottom = player.y + 0.04;
    final playerLeft = player.x - 0.025;
    final playerRight = player.x + 0.025;

    final platformTop = platform.y - platform.height / 2;
    final platformBottom = platform.y + platform.height / 2;
    final platformLeft = platform.x - platform.width / 2;
    final platformRight = platform.x + platform.width / 2;

    bool isDirectlyAbove = playerBottom >= platformTop - 0.01 &&
        playerBottom <= platformTop + 0.05;

    bool isWithinHorizontalBounds = playerRight > platformLeft &&
        playerLeft < platformRight;

    bool isFalling = player.velocityY >= 0;

    return isFalling && isDirectlyAbove && isWithinHorizontalBounds;
  }

  void _onTapDown(TapDownDetails details) {
    if (_isGameEnded || _isPaused) return;

    final screenSize = MediaQuery.of(context).size;
    final tapX = details.localPosition.dx / screenSize.width;
    final tapY = details.localPosition.dy / screenSize.height;

    // ✅ البحث عن أقرب سلاح
    Map<String, dynamic>? closestWeapon;
    double closestDistance = double.infinity;

    for (var weaponData in _weaponsOnGround) {
      final weaponX = weaponData['x'] as double;
      final weaponY = weaponData['y'] as double;

      final distance = sqrt(pow(tapX - weaponX, 2) + pow(tapY - weaponY, 2));

      if (distance < closestDistance) {
        closestDistance = distance;
        closestWeapon = weaponData;
      }
    }

    if (closestWeapon != null && closestDistance < 0.08) {
      _pickUpWeaponWithConditions(closestWeapon);
    } else {
      final player = _gameService.localPlayer;
      if (player != null && player.weapons.isNotEmpty && player.currentWeapon != null) {
        _performWeaponAttackWithAmmo();
      } else {
        _performPunch();
      }
    }
  }

  void _onDragStart(DragStartDetails details) {
    if (_isGameEnded || _isPaused) return;

    _startDragPosition = details.localPosition;
    _continuousDragPosition = details.localPosition;
    _isDragging = true;
    _startContinuousMovement();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_isGameEnded || _isPaused) return;

    _continuousDragPosition = details.localPosition;
    _updateContinuousMovement();
  }

  void _onDragEnd(DragEndDetails details) {
    if (_isGameEnded || _isPaused) return;

    _stopContinuousMovement();
    _isDragging = false;
    _startDragPosition = null;
    _continuousDragPosition = null;
  }

  void _startContinuousMovement() {
    if (_movementTimer != null) return;

    _movementTimer = Timer.periodic(Duration(milliseconds: 16), (timer) {
      if (!_isGameEnded && !_isPaused && mounted && _continuousDragPosition != null) {
        _updateContinuousMovement();
      }
    });
  }

  void _updateContinuousMovement() {
    final now = DateTime.now().millisecondsSinceEpoch;

    // منع التحديث أكثر من 60 مرة في الثانية
    if (now - _lastMovementTime < MOVEMENT_INTERVAL) return;
    _lastMovementTime = now;

    if (_continuousDragPosition == null || _startDragPosition == null) return;

    final dragVector = _continuousDragPosition! - _startDragPosition!;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final relativeX = (dragVector.dx / screenWidth) * 2.0;
    final relativeY = (dragVector.dy / screenHeight) * 2.0;

    if (relativeX.abs() > _moveDeadZone) {
      final movePower = relativeX.clamp(-1.0, 1.0) * _playerSpeed * _controlSensitivity;

      if (_gameService.localPlayer != null) {
        _gameService.localPlayer!.velocityX = movePower;
        _gameService.localPlayer!.isFacingRight = relativeX > 0;

        if (_gameService.localPlayer!.isGrounded == true) {
          _gameService.localPlayer!.state = PlayerState.running;
        }
      }
    }

    if (relativeY < -_jumpSensitivity) {
      _handleJump();
    }
  }

  void _stopContinuousMovement() {
    _movementTimer?.cancel();
    _movementTimer = null;

    if (_gameService.localPlayer != null) {
      _gameService.localPlayer!.velocityX *= 0.5;
    }
  }

  void _handleJump() {
    if (_gameService.localPlayer != null && _gameService.localPlayer!.canMove) {
      final player = _gameService.localPlayer!;

      if (player.isGrounded) {
        player.velocityY = -0.036;
        player.state = PlayerState.jumping;
        player.isGrounded = false;
        _canDoubleJump = true;
        _hasDoubleJumped = false;

        // ✅ قفل تصحيح الموقع للإطار الحالي
        _justJumped['local'] = true;
        _jumpFrameLock['local'] = _frameCounter;

        _playerFallStartY['local'] = (player.y * 1000).toInt();

        print('🦘 قفز - قوة: -0.036 | الإطار: $_frameCounter');
      } else if (_canDoubleJump && !_hasDoubleJumped) {
        player.velocityY = -0.032;
        _hasDoubleJumped = true;
        _playerHasDoubleJumped['local'] = true;

        _justJumped['local'] = true;
        _jumpFrameLock['local'] = _frameCounter;

        _addVisualEffect(
          'double_jump',
          player.x,
          player.y,
          color: Colors.blue,
          duration: 300,
        );

        print('🦘🦘 قفزة مزدوجة - الإطار: $_frameCounter');
      }

      OnlineAudioService().playJumpSound();
    }
  }

// ✅ دالة بدء المباراة - مع تحديث فوري للمتغيرات المحلية
  Future<void> _startMatch() async {
    if (!_isHost || !_isRealPlayerMatch || _isMatchStarted || _hasStartedMatch) {
      return;
    }

    setState(() {
      _hasStartedMatch = true;
      _isMatchStarted = true;
      _gameFullyStarted = true;
      _gameService.gameTimer = 120.0;
    });

    try {
      print('🎮 [MATCH] المضيف يبدأ المباراة...');
      final now = DateTime.now().millisecondsSinceEpoch;

      final matchData = {
        'status': 'playing',
        'gameStartTime': now,
        'gameTime': 120.0,
        'matchStarted': true,
        'lastSync': now,
        'weapons': [],
        'attacks': {},
        'platforms': [],
        'deaths': {},
        'playerState': {},
        'lastWeaponSync': now,
        'lastAttackTime': now,
      };

      await FirebaseFirestore.instance
          .collection('real_matches_fixed')
          .doc(widget.roomId)
          .set(matchData, SetOptions(merge: true));

      print('🎮 [MATCH] تم تحديث Firebase بنجاح');

      _showGameNotification(
        id: 'match_start',
        message: 'بدأت المباراة!',
        color: Colors.green,
        icon: Icons.sports_mma,
        durationSeconds: 2,
      );

    } catch (e) {
      print('⚠️ خطأ في بدء المباراة: $e');
    }
  }

  // ✅ دالة جديدة لمزامنة بدء اللعبة
  void _syncGameStart() {
    print('🎮 [SYNC] مزامنة بدء اللعبة...');

    _initializeWeaponSystem();

    if (_isHost) {
      Future.delayed(Duration(milliseconds: 200), () {
        if (_randomPlatforms.isNotEmpty) {
          print('🎮 [SYNC] المضيف يبدأ مزامنة ${_randomPlatforms.length} منصة...');
          _syncPlatformsToFirestore();
        } else {
          print('⚠️ [SYNC] لا توجد منصات، إعادة توليد...');
          _generateRandomPlatformPattern();  // ✅ إعادة توليد بنفس النمط
          if (_randomPlatforms.isNotEmpty) {
            _syncPlatformsToFirestore();
          }
        }
      });
    } else {
      _listenToPlatformUpdates();
    }

    _startWeaponBounceSystem();
    _startComboSystem();
    _startDoubleJumpSystem();
    _startPunchSystem();
    _startThrownWeaponsSystem();
    _startFallDeathSystem();

    OnlineAudioService().playBattleMusic();

    print('🎮 [SYNC] تمت مزامنة بدء اللعبة');
  }

// ✅ دالة الاستماع لحالة المباراة - نسخة محسنة
  void _listenToMatchStatus() {
    print('👂 [MATCH] بدء الاستماع لتحديثات المباراة: ${widget.roomId}');

    _matchStatusSubscription = FirebaseFirestore.instance
        .collection('real_matches_fixed')
        .doc(widget.roomId)
        .snapshots()
        .listen((snapshot) {
      if (!mounted || _isGameEnded) return;
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;

      // ✅ طباعة debug للمساعدة في التتبع
      if (data.containsKey('attacks')) {
        final attacksCount = (data['attacks'] as Map<String, dynamic>).length;
        if (attacksCount > 0) {
          print('🔥 [MATCH] استلام $attacksCount هجوم من Firebase');
        }
      }

      // 1. معالجة الهجمات أولاً
      if (data.containsKey('attacks')) {
        _processAttacksFromFirebase(data['attacks'] as Map<String, dynamic>);
      }

      // 2. التحقق من نهاية اللعبة
      if (data['gameEnded'] == true && !_isGameEnded) {
        _handleGameEndFromFirebase(data);
        return;
      }

      // 3. تحديث حالة المباراة
      _updateMatchStateFromFirebase(data);

      // 4. تحديث موقع الخصم
      _updateRemotePlayerFromFirebase(data);

    }, onError: (error) {
      print('❌ [MATCH] خطأ في الاستماع: $error');
    });
  }

// ✅ دالة معالجة الهجمات من Firebase - نسخة محسنة
  void _processAttacksFromFirebase(Map<String, dynamic> attacks) {
    // ✅ التحقق من صحة المدخلات
    if (attacks == null || attacks.isEmpty) {
      return;
    }

    if (_gameService.localPlayer == null) {
      print('⚠️ [ATTACK] لا يوجد لاعب محلي لتطبيق الهجوم عليه');
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    int newAttacksCount = 0;
    final List<OnlineBattleAttack> attacksToAdd = [];

    print('🔥 [ATTACK] معالجة ${attacks.length} هجوم واردة من Firebase');

    attacks.forEach((attackId, attackData) {
      try {
        final attack = attackData as Map<String, dynamic>;

        // ✅ 1. تجاهل هجمات اللاعب نفسه
        final playerId = attack['playerId'] as String?;
        if (playerId == _userId) {
          print('⏭️ [ATTACK] تجاهل هجومي أنا: $attackId');
          return;
        }

        // ✅ 2. تجاهل الهجمات القديمة (أكثر من 3 ثوانٍ)
        final timestamp = attack['timestamp'] as int? ?? 0;
        final age = now - timestamp;
        if (age > 3000) {
          print('⏭️ [ATTACK] هجوم قديم (${age}ms) تم تجاهله: $attackId');
          return;
        }

        // ✅ 3. منع التكرار باستخدام attackId
        if (_processedAttackHashes.contains(attackId)) {
          print('⏭️ [ATTACK] هجوم مكرر تم تجاهله: $attackId');
          return;
        }
        _processedAttackHashes.add(attackId);

        // ✅ 4. استخراج بيانات الهجوم مع قيم افتراضية آمنة
        final attackX = (attack['x'] as num?)?.toDouble() ?? 0.5;
        final attackY = (attack['y'] as num?)?.toDouble() ?? 0.5;

        // ✅ التحقق من صحة الإحداثيات
        if (attackX.isNaN || attackY.isNaN ||
            attackX < -0.5 || attackX > 1.5 ||
            attackY < -0.5 || attackY > 2.0) {
          print('⚠️ [ATTACK] إحداثيات غير صالحة: ($attackX, $attackY)');
          return;
        }

        // ✅ 5. تحديد نوع الهجوم
        OnlineAttackType attackType = OnlineAttackType.light;
        final typeStr = attack['type'] as String? ?? '';
        if (typeStr.contains('heavy')) {
          attackType = OnlineAttackType.heavy;
        } else if (typeStr.contains('aerial')) {
          attackType = OnlineAttackType.aerial;
        } else if (typeStr.contains('special')) {
          attackType = OnlineAttackType.special;
        }

        final directionX = (attack['directionX'] as num?)?.toDouble() ?? 1.0;
        final damage = attack['damage'] as int? ?? 10;
        final weaponImagePath = attack['weaponImagePath'] as String? ?? 'assets/online/weapons/sword.png';

        // ✅ 6. إنشاء الهجوم
        final newAttack = OnlineBattleAttack(
          type: attackType,
          x: attackX,
          y: attackY,
          directionX: directionX,
          damage: damage,
          speed: 0.03,
          range: 0.1,
          color: Colors.red,
          weaponImagePath: weaponImagePath,
          isActive: true,
          lifetime: 120,
        );

        attacksToAdd.add(newAttack);
        newAttacksCount++;

        print('⚔️ [ATTACK] هجوم جديد من $playerId');
        print('   📍 الموقع: ($attackX, $attackY)');
        print('   ⚔️ النوع: $attackType - ضرر: $damage');
        print('   🆔 ID: $attackId');

      } catch (e) {
        print('⚠️ [ATTACK] خطأ في معالجة هجوم $attackId: $e');
      }
    });

    // ✅ 7. إضافة جميع الهجمات دفعة واحدة
    if (attacksToAdd.isNotEmpty) {
      setState(() {
        _gameService.activeAttacks.addAll(attacksToAdd);
      });
      print('✅ [ATTACK] تمت إضافة $newAttacksCount هجوم جديد');
    }

    // ✅ 8. تنظيف Set الهجمات المعالجة كل 100 عنصر
    if (_processedAttackHashes.length > 100) {
      _processedAttackHashes.clear();
      print('🧹 [ATTACK] تم تنظيف Set الهجمات المعالجة');
    }

    // ✅ 9. تحديث الواجهة إذا لزم الأمر
    if (newAttacksCount > 0 && mounted) {
      setState(() {});
    }
  }

// ✅ تحديث حالة المباراة من Firebase
  void _updateMatchStateFromFirebase(Map<String, dynamic> data) {
    final status = data['status'] as String? ?? 'waiting';

    // بدء المباراة إذا لزم الأمر
    if (status == 'playing' && !_isMatchStarted) {
      print('🎮 [MATCH] بدء المباراة من Firebase');

      setState(() {
        _isMatchStarted = true;
        _gameFullyStarted = true;

        if (data.containsKey('gameStartTime')) {
          final serverStartTime = data['gameStartTime'] as int;
          final now = DateTime.now().millisecondsSinceEpoch;
          final elapsedSeconds = (now - serverStartTime) / 1000;
          _gameService.gameTimer = (120.0 - elapsedSeconds).clamp(0, 120);
        }
      });

      _syncGameStart();

      _showGameNotification(
        id: 'match_started',
        message: 'بدأت المباراة!',
        color: Colors.green,
        icon: Icons.play_arrow,
        durationSeconds: 2,
      );
    }

    // تحديث الوقت
    if (!_isGameEnded && status == 'playing' && data.containsKey('gameTime')) {
      final serverTime = data['gameTime'] as double;
      final serverTimestamp = data['serverTime'] as int? ?? 0;

      if (serverTimestamp > 0) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final latency = (now - serverTimestamp) / 1000;
        final compensatedTime = serverTime - latency;

        if ((_gameService.gameTimer - compensatedTime).abs() > 0.5) {
          _gameService.gameTimer = compensatedTime.clamp(0, 120);
        }
      }
    }
  }


// ✅ تحديث موقع الخصم من Firebase
  void _updateRemotePlayerFromFirebase(Map<String, dynamic> data) {
    if (!data.containsKey('playerState')) return;
    if (_gameService.remotePlayer == null) return;

    final playerState = data['playerState'] as Map<String, dynamic>?;
    if (playerState == null) return;

    playerState.forEach((playerId, state) {
      if (playerId != _userId && playerId == _opponentId) {
        final stateMap = state as Map<String, dynamic>;

        if (stateMap.containsKey('x') && stateMap.containsKey('y')) {
          final targetX = (stateMap['x'] as num).toDouble();
          final targetY = (stateMap['y'] as num).toDouble();

          // ✅ التحقق من صحة الإحداثيات
          if (targetX >= -0.5 && targetX <= 1.5 && targetY >= -0.5 && targetY <= 2.0) {
            _updateRemotePlayerSmoothly({'x': targetX, 'y': targetY});
          }
        }

        if (stateMap.containsKey('health')) {
          final health = (stateMap['health'] as num).toDouble();
          if (health >= 0 && health <= 100) {
            _gameService.remotePlayer!.health = health;
          }
        }
      }
    });
  }


// ✅ معالجة نهاية اللعبة من Firebase
  void _handleGameEndFromFirebase(Map<String, dynamic> data) {
    if (_isGameEnded || _hasShownResults) return;

    print('🏆 [GAME END] نهاية اللعبة من Firebase');
    _winnerName = data['winner'] as String?;

    setState(() {
      _isGameEnded = true;
    });

    _gameLoopController.stop();
    _cancelWeaponTimers();
    _hasShownResults = true;

    // ✅ عرض النتائج بعد تأخير بسيط
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        _showResultsDialog();
      }
    });
  }

  void _updateDoubleJumpSystem() {
    if (_gameService.localPlayer != null) {
      final player = _gameService.localPlayer!;

      if (player.isGrounded) {
        _canDoubleJump = true;
        _hasDoubleJumped = false;
      }
    }
  }

  void _addVisualEffect(String type, double x, double y, {Color color = Colors.white, int duration = 1000}) {
    _visualEffects.add({
      'type': type,
      'x': x,
      'y': y,
      'color': color,
      'startTime': DateTime.now().millisecondsSinceEpoch,
      'duration': duration,
    });
  }

  Future<void> _loadPlayerNames() async {
    try {
      final localName = await _getPlayerDisplayName(true);
      setState(() {
        _localPlayerName = localName;
      });

      if (widget.opponent['isBot'] != true) {
        final remoteName = await _getPlayerDisplayName(false);
        setState(() {
          _remotePlayerName = remoteName;
        });
      }
    } catch (e) {
      // تجاهل الخطأ
    }
  }

  Future<String> _getPlayerDisplayName(bool isLocal) async {
    try {
      if (isLocal) {
        final userData = await UserDataService.getUserData(FirebaseAuth.instance.currentUser?.uid ?? '');
        if (userData != null) {
          return userData['displayName'] ?? userData['username'] ?? 'اللاعب';
        }
        final playerName = await GameDataService.getPlayerName();
        return playerName.isNotEmpty ? playerName : 'اللاعب';
      } else {
        if (widget.opponent.containsKey('displayName')) {
          return widget.opponent['displayName'];
        }
        if (widget.opponent.containsKey('username')) {
          return widget.opponent['username'];
        }
        return 'الخصم';
      }
    } catch (e) {
      return isLocal ? 'اللاعب' : 'الخصم';
    }
  }

  void _initializeAudio() async {
    try {
      await OnlineAudioService().initialize();
      Future.delayed(Duration(seconds: 1), () {
        OnlineAudioService().playBattleMusic();
      });
    } catch (e) {
      // تجاهل الخطأ
    }
  }

  // ✅ ========== تعديل دالة هجوم السلاح ==========
  void _performWeaponAttackWithAmmo() {
    if (_gameService.localPlayer == null ||
        _isGameEnded ||
        _isPaused ||
        _gameService.localPlayer!.state == PlayerState.death) {
      return;
    }

    final player = _gameService.localPlayer!;

    if (player.weapons.isNotEmpty && player.currentWeapon != null) {
      final weapon = player.currentWeapon!;
      final weaponTypeKey = weapon.type.toString();

      if (!_weaponAmmo.containsKey(weaponTypeKey)) {
        final random = Random();
        _weaponAmmo[weaponTypeKey] = 3 + random.nextInt(5);
        _currentAmmoWeaponId = weaponTypeKey;
      }

      final currentAmmo = _weaponAmmo[_currentAmmoWeaponId!];

      if (currentAmmo != null && currentAmmo > 0) {
        setState(() {
          _weaponAmmo[_currentAmmoWeaponId!] = currentAmmo - 1;
        });

        if (_gameService.remotePlayer != null) {
          final enemy = _gameService.remotePlayer!;
          final attack = _gameService.createAttack(
            type: OnlineAttackType.light,
            weapon: weapon,
            x: player.x + (player.isFacingRight ? 0.08 : -0.08),
            y: player.y - 0.02,
            isFacingRight: player.isFacingRight,
          );

          final attackDistance = sqrt(
              pow(attack.x - enemy.x, 2) +
                  pow(attack.y - enemy.y, 2)
          );

          if (attackDistance < 0.1) {
            // ✅ الهجوم بالسلاح يضرر 10-20 نقطة عشوائية
            final random = Random();
            final weaponDamage = 10 + random.nextInt(11); // 10-20
            _applyDamageToOpponent(weaponDamage, 'weapon');
          }
        }

        player.performLightAttack();
        OnlineAudioService().playAttackSound();

        if (_weaponAmmo[_currentAmmoWeaponId!]! <= 0) {
          _handleWeaponDepleted(player);
        }

        return;
      }
    }

    _performPunch();
  }

  void _handleWeaponDepleted(OnlinePlayer player) {
    if (player.currentWeapon != null) {
      player.weapons.remove(player.currentWeapon!);
    }

    setState(() {
      _showAmmoCounter = false;
      _currentAmmoWeaponId = null;
    });

    _addVisualEffect(
      'weapon_empty',
      player.x,
      player.y,
      color: Colors.red,
      duration: 800,
    );
  }

  void _showWeaponReplacementNotification(OnlineWeapon newWeapon) {
    final player = _gameService.localPlayer!;
    final currentWeapon = player.currentWeapon;

    _showGameNotification(
      id: 'weapon_replacement_${newWeapon.type}',
      message: 'لديك ${currentWeapon?.name ?? "سلاح"} بالفعل!\nتخلص منه أولاً لتأخذ ${newWeapon.name}',
      color: Colors.amber,
      icon: Icons.swap_horiz,
      durationSeconds: 4,
    );
  }

  void _logError(String errorType, String message) {
    final timestamp = DateTime.now().toIso8601String();
    // print('📝 [ERROR] $timestamp - $errorType: $message');
  }

  void _togglePause() {
    if (_isGameEnded) return;

    setState(() {
      _isPaused = !_isPaused;
    });

    if (_isPaused) {
      _gameLoopController.stop();
      _showPauseMenu();
    } else {
      _resumeGame();
    }
  }

  void _showPauseMenu() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black.withOpacity(0.98),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.blue, width: 3),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.pause_circle_filled, color: Colors.blue, size: 35),
                      SizedBox(height: 6),
                      Text(
                        '⏸️ اللعبة متوقفة',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16),

                Container(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _resumeGame();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 3,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'استئناف اللعبة',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 12),

                Container(
                  width: double.infinity,
                  height: 35,
                  child: ElevatedButton(
                    onPressed: _exitGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      'خروج',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    _pauseTimer = Timer(Duration(seconds: 15), () {
      if (_isPaused && mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
        _resumeGame();
      }
    });
  }

  void _resumeGame() {
    setState(() {
      _isPaused = false;
    });
    _pauseTimer?.cancel();
    _startGameLoop();
  }

  void _checkGameEnd() {
    if (_playerLives['local']! <= 0 || _playerLives['remote']! <= 0) {
      _endGameByElimination();
    }
  }

  void _endGameByElimination() {
    if (_playerLives['local']! <= 0 && _playerLives['remote']! <= 0) {
      _winnerName = 'تعادل';
    } else if (_playerLives['local']! <= 0) {
      _winnerName = 'الخصم';
    } else {
      _winnerName = 'اللاعب';
    }
    _showGameEndScreen();
  }

  void _endGameByTime() {
    if (_isGameEnded) return;

    final localScore = _gameService.localPlayerScore;
    final remoteScore = _gameService.remotePlayerScore;

    if (localScore > remoteScore) {
      _winnerName = _localPlayerName;
    } else if (remoteScore > localScore) {
      _winnerName = _remotePlayerName;
    } else {
      _winnerName = 'تعادل';
    }

    // ✅ إرسال نتيجة اللعبة إلى Firestore
    _syncGameEndToFirestore();
  }

  // ✅ دالة جديدة لمزامنة نهاية اللعبة
  Future<void> _syncGameEndToFirestore() async {
    // ✅ أرسل نهاية اللعبة عبر LiveKit أولاً
    _sendGameEndViaLiveKit();
    try {
      String currentUserId = await _getCurrentUserId();

      await FirebaseFirestore.instance
          .collection('real_matches_fixed')
          .doc(widget.roomId)
          .update({
        'gameEnded': true,
        'gameEndTime': DateTime.now().millisecondsSinceEpoch,
        'winner': _winnerName,
        'endedBy': currentUserId,
      });

      print('🏆 [GAME END] تم مزامنة نهاية اللعبة مع Firebase');

      // ❌ إزالة هذا السطر - لا حاجة لاستدعاء _listenToGameEnd() هنا
      // _listenToGameEnd();

    } catch (e) {
      print('⚠️ خطأ في مزامنة نهاية اللعبة: $e');
      // ✅ إذا فشل الإرسال، عرض النتيجة محلياً بعد 3 ثوان
      _gameEndTimer = Timer(Duration(seconds: 3), () {
        if (mounted) {
          _showResultsDialog();
        }
      });
    }
  }

// ✅ دالة جديدة للاستماع لنهاية اللعبة (نسخة احتياطية)
  void _listenToGameEnd() {
    FirebaseFirestore.instance
        .collection('real_matches_fixed')
        .doc(widget.roomId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists || !mounted || _isGameEnded || _hasShownResults) return;

      final data = snapshot.data() as Map<String, dynamic>;

      if (data.containsKey('gameEnded') && data['gameEnded'] == true) {
        final gameEndTime = data['gameEndTime'] as int? ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;

        if (now >= gameEndTime - 100) {
          _winnerName = data['winner'] as String?;

          setState(() {
            _isGameEnded = true;
          });

          _gameLoopController.stop();
          _cancelWeaponTimers();
          _hasShownResults = true;

          _showResultsDialog();
        }
      }
    });
  }

  void _showGameEndScreen() {
    if (_isGameEnded) return;

    _gameEndTimestamp = DateTime.now().millisecondsSinceEpoch;

    setState(() {
      _isGameEnded = true;
    });

    _gameLoopController.stop();
    _cancelWeaponTimers();

    // ✅ مزامنة نهاية اللعبة
    _syncGameEndToFirestore();
  }

  // ✅ ========== شاشة النتائج ==========
  void _showResultsDialog() {
    // ✅ استخدام المتغيرات الصحيحة فقط
    final localScore = _gameService.localPlayerScore;
    final remoteScore = _gameService.remotePlayerScore;

    final isWinner = _winnerName == _localPlayerName;
    final isDraw = _winnerName == 'تعادل';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black.withOpacity(0.98),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
            side: BorderSide(color: Colors.yellow, width: 4),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.65,
              maxWidth: MediaQuery.of(context).size.width * 0.85,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ✅ العنوان الرئيسي
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDraw ? [Colors.yellow, Colors.amber] :
                          isWinner ? [Colors.green, Colors.lightGreen] : [Colors.red, Colors.orange],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            isDraw ? Icons.emoji_events_outlined :
                            isWinner ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                            color: Colors.white,
                            size: 50,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'انتهت الجولة',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(color: Colors.black, blurRadius: 5, offset: Offset(2, 2)),
                              ],
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            isDraw ? '⚖️ تعادل!' :
                            isWinner ? '🎉 فزت!' : '😞 خسرت!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),

                    // ✅ مقارنة النتائج
                    Container(
                      padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey[600]!, width: 1),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '📊 مقارنة النتائج',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    Text('أنت', style: TextStyle(color: Colors.blue, fontSize: 14)),
                                    SizedBox(height: 5),
                                    Container(
                                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '$localScore',
                                        style: TextStyle(
                                          color: Colors.yellow,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.all(8),
                                child: Icon(Icons.emoji_events, color: Colors.yellow, size: 24),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Text('الخصم', style: TextStyle(color: Colors.red, fontSize: 14)),
                                    SizedBox(height: 5),
                                    Container(
                                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '$remoteScore',
                                        style: TextStyle(
                                          color: Colors.yellow,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Text(
                            localScore > remoteScore ? '🔥 لقد فزت بالنقاط!' :
                            remoteScore > localScore ? '⚠️ الخصم فاز بالنقاط' : '⚖️ تعادل في النقاط',
                            style: TextStyle(
                              color: localScore > remoteScore ? Colors.green :
                              remoteScore > localScore ? Colors.red : Colors.yellow,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),

                    // ✅ أزرار الإجراءات
                    Column(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _restartGame,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 5,
                              shadowColor: Colors.blue.withOpacity(0.5),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.refresh, size: 20),
                                SizedBox(width: 10),
                                Text(
                                  'إعادة المحاولة',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 45,
                                child: ElevatedButton(
                                  onPressed: _goToStore,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 3,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.shopping_cart, size: 16),
                                      SizedBox(height: 2),
                                      Text(
                                        'المتجر',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(width: 8),

                            Expanded(
                              child: Container(
                                height: 45,
                                child: ElevatedButton(
                                  onPressed: _goToLobby,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 3,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.home, size: 16),
                                      SizedBox(height: 2),
                                      Text(
                                        'اللوبي',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(width: 8),

                            Expanded(
                              child: Container(
                                height: 45,
                                child: ElevatedButton(
                                  onPressed: _goToCharacters,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 3,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.person, size: 16),
                                      SizedBox(height: 2),
                                      Text(
                                        'الشخصيات',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
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
  }

  // ✅ تحديث دالة إعادة تشغيل اللعبة
  void _restartGame() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    setState(() {
      _isGameEnded = false;
      _isPaused = false;

      // ✅ توليد نمط منصات جديد في كل مرة
      _generateRandomPlatformPattern();

      // ✅ إعادة تعيين النظام الجديد
      _playerLives = {'local': 3, 'remote': 3};
      _respawnCooldown = {'local': 0, 'remote': 0};
      _playerIsRespawning = {'local': false, 'remote': false};

      // ✅ إعادة تعيين النقاط
      _gameService.localPlayerScore = 0;
      _gameService.remotePlayerScore = 0;

      // ✅ تنظيف العناصر
      _weaponsOnGround.clear();
      _thrownWeapons.clear();
      _showTutorial = false;
      _visualEffects.clear();
      _weaponBounceOffsets.clear();
      _weaponBounceDirections.clear();
      _showKOEffect = {'local': false, 'remote': false};
      _consecutiveHits = {'local': 0, 'remote': 0};
      _canDoubleJump = true;
      _hasDoubleJumped = false;
      _canPunch = true;

      _activeNotifications.clear();
      _shownNotificationIds.clear();
      _isNotificationVisible = false;
      _notificationTimer?.cancel();

      _weaponAmmo.clear();
      _currentAmmoWeaponId = null;
      _showAmmoCounter = false;

      _playerHasDoubleJumped = {'local': false, 'remote': false};

      // ✅ تنظيف الأسلحة المسقطة
      _droppedWeapons = {
        'local': [],
        'remote': [],
      };
    });

    _gameService.resetGame();
    _gameService.gameTimer = 120.0;
    _startGameLoop();

    Future.delayed(Duration(seconds: 2), () {
      _initializeWeaponSystem();
    });

    _startWeaponBounceSystem();
    _startComboSystem();
    _startDoubleJumpSystem();
    _startPunchSystem();
    _startThrownWeaponsSystem();
    _startFallDeathSystem();

    print('🔄 تم إعادة تشغيل اللعبة بنمط منصات جديد: $_platformPatternName');
  }

  void _goToStore() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => OnlineStoreScreen()),
    );
  }

  void _goToCharacters() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => OnlineCharactersScreen()),
    );
  }

  void _goToLobby() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => OnlineLobbyScreen()),
    );
  }

  void _hideTutorialAfterDelay() {
    Future.delayed(Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showTutorial = false;
        });
      }
    });
  }

  Widget _buildTutorialOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 300,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blueGrey[900],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blueAccent),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🎮 تحكم باللمس', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 15),
                  _buildTutorialItem('⬆️ سحب لأعلى', 'قفزة'),
                  _buildTutorialItem('➡️ سحب لليمين/يسار', 'حركة أفقية'),
                  _buildTutorialItem('👆 النقر على سلاح', 'التقاط السلاح'),
                  _buildTutorialItem('👆 النقر بدون سلاح', 'ملاكمة'),
                  SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: () => setState(() => _showTutorial = false),
                    child: Text('ابدأ اللعب!'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTutorialItem(String title, String description) {
    return Padding(
        padding: EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Text(title, style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            SizedBox(width: 10),
            Expanded(child: Text(description, style: TextStyle(color: Colors.white70, fontSize: 12))),
          ],
        )
    );
  }

  Widget _buildErrorScreen(dynamic error) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 60),
            SizedBox(height: 20),
            Text('حدث خطأ في اللعبة',
                style: TextStyle(color: Colors.white, fontSize: 20)),
            SizedBox(height: 10),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                  error.toString(),
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _exitGame,
              child: Text('العودة للرئيسية'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _exitGame() {
    _isGameEnded = true;
    _isPaused = false;
    _gameLoopController.stop();
    _cancelWeaponTimers();
    // ⭐ أضف null-check:
    if (_gameService != null) {
      _gameService!.isGameRunning = false;
    }
    try {
      widget.connectionService.disconnect();
    } catch (e) {
      // تجاهل الخطأ
    }
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  String _truncateName(String name) {
    if (name.length <= 8) return name;
    return name.substring(0, 7) + '...';
  }

  String _getSafeFramePath(String? path) {
    if (path == null || path.isEmpty) {
      // ✅ استخدام صورة حقيقية بدلاً من default.png
      return 'assets/images/characters/almashe/almashe_idle_1.png';
    }
    return path;
  }

  String _formatGameTime(double seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toInt().toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  // ✅ تعديل دالة بناء المنصات
  List<Widget> _buildPlatforms(Size screenSize) {
    try {
      // ✅ استخدام المنصات العشوائية بدلاً من الثابتة
      final platformsToBuild = _randomPlatforms.isNotEmpty
          ? _randomPlatforms
          : _gameService.platforms;

      return platformsToBuild.map<Widget>((platform) {
        final platformX = platform.x;
        final platformY = platform.y;
        double platformWidth = platform.width;
        double platformHeight = platform.height;

        Color platformColor;
        Color borderColor;

        // ✅ تحديد الألوان بناءً على نوع المنصة
        if (platform.type.contains('ground')) {
          platformColor = _currentPlatformPrimaryColor;
          borderColor = Colors.red;
        } else if (platform.type.contains('main')) {
          platformColor = _currentPlatformPrimaryColor.withOpacity(0.9);
          borderColor = Colors.yellow;
        } else if (platform.type.contains('floating')) {
          platformColor = _currentPlatformSecondaryColor;
          borderColor = Colors.green;
        } else {
          // ✅ ألوان للمنصات الخاصة
          platformColor = platform.color;
          borderColor = Colors.white.withOpacity(0.5);
        }

        return Positioned(
          left: (platformX - platformWidth / 2) * screenSize.width,
          top: (platformY - platformHeight / 2) * screenSize.height,
          child: Container(
            width: platformWidth * screenSize.width,
            height: platformHeight * screenSize.height,
            decoration: BoxDecoration(
              color: platformColor,
              borderRadius: BorderRadius.circular(platformHeight * screenSize.height / 2),
              border: Border.all(color: borderColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
                BoxShadow(
                  color: platformColor.withOpacity(0.3),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
              // ✅ تأثير تدرج للون
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  platformColor.withOpacity(0.9),
                  platformColor.withOpacity(0.7),
                  platformColor.withOpacity(0.9),
                ],
              ),
            ),
            // ✅ إضافة نص صغير لنوع المنصة (في وضع التصحيح فقط)
            child: DEBUG_MODE ? Center(
              child: Text(
                platform.type.length > 10
                    ? platform.type.substring(0, 10)
                    : platform.type,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ) : null,
          ),
        );
      }).toList();
    } catch (e) {
      print('❌ خطأ في بناء المنصات: $e');
      return [];
    }
  }

// ✅ دالة توليد نمط المنصات مع دعم المزامنة - نسخة محسنة
  void _generateRandomPlatformPattern() {
    // ✅ ✅ ✅ أضف هذه الأسطر في البداية
    print('🔥 [PLATFORM] دخلت دالة _generateRandomPlatformPattern');
    print('   _isRealPlayerMatch=$_isRealPlayerMatch, _isHost=$_isHost');
    print('   _useLiveKit=$_useLiveKit');

    try {
      // 🔥 القاعدة الذهبية: فقط المضيف يقوم بتوليد المنصات
      if (_isRealPlayerMatch && !_isHost) {
        print('🎮 [PLATFORM] أنا ضيف، انتظر المنصات من المضيف...');

        // ✅ التحقق من وجود منصات مستلمة بالفعل
        if (_randomPlatforms.isEmpty) {
          _listenToPlatformUpdates();
          _showGameNotification(
            id: 'waiting_platforms',
            message: 'جاري استلام بيانات الحلبة من المضيف...',
            color: Colors.orange,
            icon: Icons.download,
            durationSeconds: 3,
          );
        }
        return;
      }

      // ✅ هنا نحن المضيف - نقوم بتوليد المنصات
      print('🎮 [PLATFORM] أنا المضيف، أقوم بتوليد المنصات...');

      // ✅ تحديد نمط المنصات
      String patternName = widget.platformPattern ?? 'كلاسيكي';
      PlatformPattern? selectedPattern;

      if (widget.platformPattern != null) {
        selectedPattern = PlatformGenerator.getPatternByName(patternName);
        if (selectedPattern != null) {
          print('🎮 تم العثور على النمط المحدد: ${selectedPattern.name}');
        }
      }

      final pattern = selectedPattern ?? PlatformGenerator.getRandomPattern();

      // ✅ تخزين النمط المختار
      _currentPlatformPattern = pattern;
      _platformPatternName = pattern.name;
      _currentPlatformPrimaryColor = pattern.primaryColor;
      _currentPlatformSecondaryColor = pattern.secondaryColor;

      print('🎮 === توليد نمط منصات جديد: ${pattern.name} ===');

      // ✅ توليد المنصات بناءً على النمط
      _randomPlatforms = PlatformGenerator.generatePlatformsFromPattern(pattern);
      _strategicGaps = PlatformGenerator.generateStrategicGaps(_randomPlatforms);

      print('🏔️ تم توليد ${_randomPlatforms.length} منصة بنمط: $_platformPatternName');

      // ✅ ✅ ✅ تشخيص قبل الإرسال
      print('🔍 [LIVEKIT] قبل إرسال المنصات - useLiveKit=$_useLiveKit, isConnected=${_liveKitService.isConnected}, platformsCount=${_randomPlatforms.length}');

      // ✅ ✅ ✅ إرسال المنصات عبر LiveKit (أسرع)
      if (_useLiveKit && _liveKitService.isConnected) {
        print('📤 [LIVEKIT] جاري إرسال ${_randomPlatforms.length} منصة...');
        _liveKitService.sendPlatforms(_randomPlatforms, _platformPatternName);
        print('📤 [LIVEKIT] تم إرسال المنصات إلى الضيف');
      } else {
        print('⚠️ [LIVEKIT] لم يتم إرسال المنصات - useLiveKit=$_useLiveKit, isConnected=${_liveKitService.isConnected}');
      }

      // ✅ مزامنة المنصات مع Firebase (نسخة احتياطية)
      if (_isRealPlayerMatch && _isHost) {
        _syncPlatformsToFirestore();
      }

      // ✅ إشعار للمستخدم بنمط المنصات
      _showPlatformPatternNotificationWidget(pattern);

    } catch (e) {
      print('❌ خطأ في توليد المنصات: $e');
      _useDefaultPlatforms();

      // ✅ محاولة المزامنة حتى مع المنصات الافتراضية
      if (_isRealPlayerMatch && _isHost) {
        _syncPlatformsToFirestore();
      }
    }
  }

  void _useDefaultPlatforms() {
    print('🎮 استخدام المنصات الافتراضية في حالة الخطأ');

    _randomPlatforms = [
      BattlePlatform(
        x: 0.5,
        y: 1.5,
        width: 2.5,
        height: 0.1,
        type: 'ground',
        color: Color(0xFF8B4513),
      ),
      BattlePlatform(
        x: 0.5,
        y: 0.9,
        width: 0.8,
        height: 0.05,
        type: 'main',
        color: Color(0xFF8B4513),
      ),
    ];

    _platformPatternName = 'افتراضي';
    _currentPlatformPrimaryColor = Color(0xFF8B4513);
    _currentPlatformSecondaryColor = Color(0xFF654321);
    _strategicGaps = [];
  }

// ✅ دالة مساعدة للبحث عن النمط بالاسم
  PlatformPattern? _getPatternByName(String name) {
    // قائمة بكل الأنماط المتاحة (يجب أن تكون مطابقة للأنماط في PlatformGenerator)
    final allPatterns = [
      PlatformPattern(
        name: 'كلاسيكي',
        description: 'منصات تقليدية متوازنة',
        primaryColor: Color(0xFF8B4513),
        secondaryColor: Color(0xFF654321),
        platformConfigs: [], // ✅ أضف هذا
      ),
      PlatformPattern(
        name: 'متاهة',
        description: 'منصات معقدة تشبه المتاهة',
        primaryColor: Color(0xFF2C3E50),
        secondaryColor: Color(0xFF34495E),
        platformConfigs: [], // ✅ أضف هذا
      ),
      PlatformPattern(
        name: 'أبراج',
        description: 'منصات عالية للقتال الجوي',
        primaryColor: Color(0xFF4A235A),
        secondaryColor: Color(0xFF6C3483),
        platformConfigs: [], // ✅ أضف هذا
      ),
      PlatformPattern(
        name: 'جسر',
        description: 'منصة رئيسية وجسور معلقة',
        primaryColor: Color(0xFF784212),
        secondaryColor: Color(0xFFBA4A00),
        platformConfigs: [], // ✅ أضف هذا
      ),
      PlatformPattern(
        name: 'عشوائي متقدم',
        description: 'توزيع عشوائي متطور',
        primaryColor: Color(0xFF117A65),
        secondaryColor: Color(0xFF148F77),
        platformConfigs: [], // ✅ أضف هذا
      ),
    ];

    // البحث عن النمط بالاسم
    try {
      return allPatterns.firstWhere(
            (pattern) => pattern.name == name,
      );
    } catch (e) {
      print('⚠️ لم يتم العثور على النمط "$name"');
      return null;
    }
  }

  void _showPlatformPatternNotificationWidget(PlatformPattern pattern) {
    if (!mounted || _isGameEnded) return;

    setState(() {
      _showPlatformPatternNotification = true;
    });

    _patternNotificationTimer?.cancel();
    _patternNotificationTimer = Timer(Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showPlatformPatternNotification = false;
        });
      }
    });

    // ✅ إشعار في النظام
    _showGameNotification(
      id: 'platform_pattern_${pattern.name}',
      message: 'نمط منصات: ${pattern.name}\n${pattern.description}',
      color: pattern.primaryColor,
      icon: Icons.landscape,
      durationSeconds: 4,
    );
  }

// ✅ دالة لمزامنة الأسلحة مع Firebase
  void _syncWeaponsToFirestore() async {
    if (!_isRealPlayerMatch) return;

    try {
      // تحويل الأسلحة إلى JSON
      List<Map<String, dynamic>> weaponsJson = _weaponsOnGround.map((weapon) {
        final w = weapon['weapon'] as OnlineWeapon;
        return {
          'id': weapon['id'],
          'x': weapon['x'],
          'y': weapon['y'],
          'type': w.type.toString(),
          'name': w.name,
          'damage': w.damage,
          'imagePath': w.imagePath,
          'spawnTime': weapon['spawnTime'],
          'lifetime': weapon['lifetime'],
          'isDropped': weapon['isDropped'] ?? false,
        };
      }).toList();

      final now = DateTime.now().millisecondsSinceEpoch;

      // ✅ تحديث Firebase
      await FirebaseFirestore.instance
          .collection('real_matches_fixed')
          .doc(widget.roomId)
          .set({
        'weapons': weaponsJson,
        'lastWeaponSync': now,
        'lastSync': now,
      }, SetOptions(merge: true));

      print('📤 تم مزامنة ${weaponsJson.length} سلاح مع Firebase');

    } catch (e) {
      print('⚠️ خطأ في مزامنة الأسلحة: $e');
    }
  }

  // ✅ دالة للاستماع لتحديثات الأسلحة
  void _listenToWeaponUpdates() {
    _weaponSubscription?.cancel(); // ⭐ إلغاء أي اشتراك سابق

    _weaponSubscription = FirebaseFirestore.instance
        .collection('real_matches_fixed')
        .doc(widget.roomId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists || !mounted) return;

      final data = snapshot.data() as Map<String, dynamic>;

      // ✅ التحقق من أن اللعبة في حالة playing
      final status = data['status'] as String? ?? 'waiting';
      if (status != 'playing') return; // ⭐ لا نعالج الأسلحة إلا إذا كانت اللعبة بدأت

      // ✅ تحديث الأسلحة
      if (data.containsKey('weapons')) {
        final weaponsData = data['weapons'] as List<dynamic>?;
        if (weaponsData != null) {
          final lastSync = data['lastWeaponSync'] as int? ?? 0;
          if (lastSync > _lastWeaponSyncTime) {
            _lastWeaponSyncTime = lastSync;
            _syncWeaponsFromFirestore(weaponsData);
            print('📥 [WEAPONS] تم استقبال ${weaponsData.length} سلاح من Firebase');
          }
        }
      }
    }, onError: (error) {
      print('⚠️ [WEAPONS] خطأ في الاستماع: $error');
    });
  }

  // ✅ دالة تصحيح - استدعها مرة واحدة للتأكد
  void _debugForceRefreshWeapons() {
    print('🔧 [DEBUG] محاولة تحديث الأسلحة يدوياً...');

    FirebaseFirestore.instance
        .collection('real_matches_fixed')
        .doc(widget.roomId)
        .get()
        .then((snapshot) {
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;

      if (data.containsKey('weapons')) {
        final weaponsData = data['weapons'] as List<dynamic>?;
        if (weaponsData != null) {
          _syncWeaponsFromFirestore(weaponsData);
          print('✅ [DEBUG] تم تحديث الأسلحة يدوياً: ${weaponsData.length} سلاح');
        }
      }
    }).catchError((e) {
      print('⚠️ [DEBUG] خطأ في التحديث اليدوي: $e');
    });
  }

  // ✅ دالة مساعدة للحصول على السلاح من النص
  OnlineWeapon? _getWeaponFromType(String typeStr) {
    try {
      String typeName;
      if (typeStr.contains('.')) {
        typeName = typeStr.split('.').last;
      } else {
        typeName = typeStr;
      }

      final weaponType = OnlineWeaponType.values.firstWhere(
            (e) => e.toString().split('.').last.toLowerCase() == typeName.toLowerCase(),
        orElse: () => OnlineWeaponType.sword,
      );

      return OnlineWeaponLibrary.getWeapon(weaponType);
    } catch (e) {
      return OnlineWeaponLibrary.getWeapon(OnlineWeaponType.sword);
    }
  }

// ✅ دالة لمزامنة الأسلحة من Firestore - نسخة محسنة
  void _syncWeaponsFromFirestore(List<dynamic> weaponsData) {
    if (_isGameEnded) return;

    try {
      List<Map<String, dynamic>> newWeapons = [];

      for (var weaponJson in weaponsData) {
        final w = weaponJson as Map<String, dynamic>;

        if (!w.containsKey('x') || !w.containsKey('y') || !w.containsKey('type')) {
          continue;
        }

        OnlineWeapon? weapon = _getWeaponFromType(w['type'] as String);

        if (weapon != null) {
          newWeapons.add({
            'weapon': weapon,
            'x': (w['x'] as num?)?.toDouble() ?? 0.5,
            'y': (w['y'] as num?)?.toDouble() ?? 0.5,
            'id': w['id'] ?? 'weapon_${DateTime.now().millisecondsSinceEpoch}',
            'spawnTime': w['spawnTime'] ?? DateTime.now().millisecondsSinceEpoch,
            'lifetime': w['lifetime'] ?? 45,
            'isActive': true,
            'isDropped': w['isDropped'] ?? false,
          });
        }
      }

      if (!_isGameEnded && mounted) {
        setState(() {
          _weaponsOnGround = newWeapons;
          _hasReceivedWeapons = true; // ✅ تم استلام الأسلحة
        });
      }

      // ✅ إلغاء المؤقت الاحتياطي
      _weaponFallbackTimer?.cancel();

      print('🎯 [FIREBASE] تم تحديث الأسلحة: ${newWeapons.length} سلاح');

    } catch (e) {
      print('❌ خطأ في مزامنة الأسلحة: $e');
    }
  }

  // ✅ أضف واجهة لعرض نمط المنصات
  Widget _buildPlatformPatternIndicator() {
    if (!_showPlatformPatternNotification) return SizedBox.shrink();

    return Positioned(
      top: 150,
      left: 0,
      right: 0,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20),
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _currentPlatformPrimaryColor.withOpacity(0.9),
              _currentPlatformSecondaryColor.withOpacity(0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.landscape, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'نمط المنصات: $_platformPatternName',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                if (_currentPlatformPattern != null)
                  Text(
                    _currentPlatformPattern!.description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildKOEffects(Size screenSize) {
    List<Widget> effects = [];

    if (_showKOEffect['local']! && _gameService.localPlayer != null) {
      effects.add(
        Positioned(
          left: _gameService.localPlayer!.x * screenSize.width - 50,
          top: _gameService.localPlayer!.y * screenSize.height - 50,
          child: Container(
            width: 100,
            height: 100,
            child: Center(
              child: Text(
                'K.O',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 10,
                      color: Colors.white,
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (_showKOEffect['remote']! && _gameService.remotePlayer != null) {
      effects.add(
        Positioned(
          left: _gameService.remotePlayer!.x * screenSize.width - 50,
          top: _gameService.remotePlayer!.y * screenSize.height - 50,
          child: Container(
            width: 100,
            height: 100,
            child: Center(
              child: Text(
                'K.O',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 10,
                      color: Colors.white,
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return effects;
  }

  // List<Widget> _buildActiveAttacks(Size screenSize) {
  //   final attacks = _gameService.activeAttacks;
  //   return attacks.where((attack) => attack.isActive).map<Widget>((attack) {
  //     return Positioned(
  //       left: attack.x * screenSize.width - 20,
  //       top: attack.y * screenSize.height - 20,
  //       child: Container(
  //         width: 40,
  //         height: 40,
  //         decoration: BoxDecoration(
  //           shape: BoxShape.circle,
  //           color: attack.color.withOpacity(0.7),
  //           boxShadow: [
  //             BoxShadow(
  //               color: attack.color,
  //               blurRadius: 10,
  //               spreadRadius: 2,
  //             ),
  //           ],
  //         ),
  //         child: Center(
  //           child: Text(
  //             '⚔️',
  //             style: TextStyle(fontSize: 20),
  //           ),
  //         ),
  //       ),
  //     );
  //   }).toList();
  // }

  void _initializeBackgroundSystem() {
    print('🎨 === تحميل الخلفية ===');

    // ✅ استخدم الخلفية من بيانات المباراة إذا كانت موجودة
    String backgroundPath;

    // ✅ أولاً: تحقق من opponent مباشرة
    if (widget.opponent.containsKey('background')) {
      backgroundPath = 'assets/images/backgrounds/${widget.opponent['background']}';
      print('🎨 استخدام خلفية من opponent: ${widget.opponent['background']}');
    }
    // ✅ ثانياً: تحقق من matchData إذا كانت متاحة (للتوافق)
    else if (widget.opponent.containsKey('matchData') &&
        widget.opponent['matchData'] is Map &&
        widget.opponent['matchData'].containsKey('background')) {
      backgroundPath = 'assets/images/backgrounds/${widget.opponent['matchData']['background']}';
      print('🎨 استخدام خلفية من matchData: ${widget.opponent['matchData']['background']}');
    }
    // ✅ أخيراً: استخدم خلفية افتراضية (هذا لن يحدث بعد التعديل)
    else {
      print('⚠️ لا توجد خلفية محددة، استخدام خلفية عشوائية مؤقتة');

      // ⚠️ لا نستخدم عشوائي هنا، بل نأخذ خلفية المباراة بطريقة أخرى

      // هذا هو الخطأ - يجب إزالة هذه الأسطر:
      // final List<String> confirmedBackgrounds = [
      //   'assets/images/backgrounds/forest.png',
      //   'assets/images/backgrounds/desert.png',
      //   'assets/images/backgrounds/mountain.png',
      //   'assets/images/backgrounds/snow.png',
      //   'assets/images/backgrounds/arctic.png',
      //   'assets/images/backgrounds/castle.png',
      //   'assets/images/backgrounds/egypt.png',
      // ];
      // final random = Random();
      // backgroundPath = confirmedBackgrounds[random.nextInt(confirmedBackgrounds.length)];

      // ✅ بدلاً من ذلك، نأخذ الخلفية من أي مكان متاح
      backgroundPath = 'assets/images/backgrounds/forest.png'; // خلفية افتراضية ثابتة
    }

    _currentBackground = backgroundPath;
    _backgroundLoaded = true;

    print('✅ الخلفية المختارة: ${_currentBackground.split('/').last}');
    print('📁 المسار الكامل: $_currentBackground');

    // ✅ تحميل الخلفية بعد بناء الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
        print('🎨 الخلفية جاهزة للعرض');
      }
    });
  }

  Widget _buildBrawlhallaBackground(double width, double height) {
    return SizedBox(
      width: width,
      height: height,
      child: _backgroundLoaded && _currentBackground.isNotEmpty
          ? GameBackground(backgroundPath: _currentBackground)
          : Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f3460),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1a1a2e),
            Color(0xFF16213e),
            Color(0xFF0f3460),
          ],
        ),
      ),
    );
  }

  void _updateDeadPlayers() {
    // ✅ إذا كان اللاعب ميتاً، لا نغير الحالة
    if (_gameService.localPlayer?.state == PlayerState.death) {
      return;
    }

    if (_gameService.localPlayer?.state == PlayerState.death) {
      if (_playerLives['local']! > 0 && !_playerIsRespawning['local']!) {
        _handlePlayerDeath('local');
      }
    }

    if (_gameService.remotePlayer?.state == PlayerState.death) {
      if (_playerLives['remote']! > 0 && !_playerIsRespawning['remote']!) {
        _handlePlayerDeath('remote');
      }
    }
  }

  // ========== debug التشخصي==========
  // ✅ دالة تشخيص شاملة تعرض حالة اللاعب والخصم معاً
  void _debugFullState() {
    // تطبع كل 60 إطار (ثانية واحدة) لتجنب إغراق الـ Console
    if (_frameCounter % 60 != 0) return;

    print('\n' + '=' * 60);
    print('🔍 [DIAGNOSTIC] تشخيص شامل للحالة - الإطار: $_frameCounter');
    print('=' * 60);

    // ⏱️ الوقت
    print('⏱️ [TIME] الوقت: ${_gameService.gameTimer.toStringAsFixed(1)} ثانية');
    print('   المعوض: ${_compensatedGameTime.toStringAsFixed(1)} ثانية');
    print('   آخر تحديث خادم: $_lastServerTimestamp');

    // 🎮 اللاعب المحلي
    if (_gameService.localPlayer != null) {
      final p = _gameService.localPlayer!;
      print('\n👤 [LOCAL PLAYER] $_localPlayerName');
      print('   🆔 ID: ${p.playerId}');
      print('   📍 الموقع: (${p.x.toStringAsFixed(3)}, ${p.y.toStringAsFixed(3)})');
      print('   📊 الحالة: ${p.state}');
      print('   🎭 الأنيميشن: ${p.animationController.currentState}');
      print('   📁 الإطار: ${p.currentFramePath.split('/').last}');
      print('   ❤️ الصحة: ${p.health.toStringAsFixed(1)}');
      print('   💀 الأرواح: ${_playerLives['local']}');
      print('   🏃 السرعة: (${p.velocityX.toStringAsFixed(4)}, ${p.velocityY.toStringAsFixed(4)})');
      print('   🪂 على الأرض: ${p.isGrounded}');
      print('   🗡️ الأسلحة: ${p.weapons.length}');
      if (p.currentWeapon != null) {
        print('      🔫 السلاح الحالي: ${p.currentWeapon!.name}');
      }
    }

    // 👥 الخصم
    if (_gameService.remotePlayer != null) {
      final p = _gameService.remotePlayer!;
      print('\n👥 [REMOTE PLAYER] $_remotePlayerName');
      print('   🆔 ID: ${p.playerId}');
      print('   📍 الموقع: (${p.x.toStringAsFixed(3)}, ${p.y.toStringAsFixed(3)})');
      print('   📊 الحالة: ${p.state}');
      print('   🎭 الأنيميشن: ${p.animationController.currentState}');
      print('   📁 الإطار: ${p.currentFramePath.split('/').last}');
      print('   ❤️ الصحة: ${p.health.toStringAsFixed(1)}');
      print('   💀 الأرواح: ${_playerLives['remote']}');
      print('   🏃 السرعة: (${p.velocityX.toStringAsFixed(4)}, ${p.velocityY.toStringAsFixed(4)})');
      print('   🪂 على الأرض: ${p.isGrounded}');
      print('   🗡️ الأسلحة: ${p.weapons.length}');
      if (p.currentWeapon != null) {
        print('      🔫 السلاح الحالي: ${p.currentWeapon!.name}');
      }
    }

    // 🤝 مقارنة التطابق
    if (_gameService.localPlayer != null && _gameService.remotePlayer != null) {
      final local = _gameService.localPlayer!;
      final remote = _gameService.remotePlayer!;

      print('\n🤝 [COMPARISON] مقارنة بين اللاعبين');

      // مقارنة الموقع
      final distance = sqrt(pow(local.x - remote.x, 2) + pow(local.y - remote.y, 2));
      print('   📏 المسافة بين اللاعبين: ${distance.toStringAsFixed(3)}');

      // التحقق من تطابق الحالة مع الخادم
      if (_lastUpdateTime['remote'] != null) {
        final now = DateTime.now();
        final lastRemoteUpdate = _lastUpdateTime['remote']!;
        final latency = now.difference(lastRemoteUpdate).inMilliseconds;
        print('   📡 تأخير الخصم: ${latency}ms');
      }
    }

    // 🏔️ المنصات
    print('\n🏔️ [PLATFORMS]');
    print('   النمط: $_platformPatternName');
    print('   عدد المنصات: ${_randomPlatforms.length}');
    if (_randomPlatforms.isNotEmpty) {
      for (int i = 0; i < min(3, _randomPlatforms.length); i++) {
        final platform = _randomPlatforms[i];
        print('   🏔️ منصة $i: (${platform.x.toStringAsFixed(2)}, ${platform.y.toStringAsFixed(2)}) - ${platform.type}');
      }
      if (_randomPlatforms.length > 3) {
        print('   ... و ${_randomPlatforms.length - 3} منصات أخرى');
      }
    }

    // 🔫 الأسلحة
    print('\n🔫 [WEAPONS]');
    print('   أسلحة على الأرض: ${_weaponsOnGround.length}');
    if (_weaponsOnGround.isNotEmpty) {
      for (int i = 0; i < min(3, _weaponsOnGround.length); i++) {
        final weapon = _weaponsOnGround[i];
        final w = weapon['weapon'] as OnlineWeapon;
        print('   🔫 سلاح $i: ${w.name} في (${weapon['x'].toStringAsFixed(2)}, ${weapon['y'].toStringAsFixed(2)})');
      }
    }

    // ⚔️ الهجمات النشطة
    print('\n⚔️ [ACTIVE ATTACKS]');
    print('   عدد الهجمات: ${_gameService.activeAttacks.length}');
    for (int i = 0; i < min(3, _gameService.activeAttacks.length); i++) {
      final attack = _gameService.activeAttacks[i];
      print('   ⚔️ هجوم $i: ${attack.type} في (${attack.x.toStringAsFixed(2)}, ${attack.y.toStringAsFixed(2)})');
    }

    print('=' * 60 + '\n');
  }

  // ✅ دالة لتشخيص بيانات Firebase
  Future<void> _debugFirebaseState() async {
    try {
      print('\n' + '=' * 50);
      print('🔥 [FIREBASE DIAGNOSTIC]');
      print('=' * 50);

      final doc = await FirebaseFirestore.instance
          .collection('real_matches_fixed')
          .doc(widget.roomId)
          .get();

      if (!doc.exists) {
        print('❌ المستند غير موجود');
        return;
      }

      final data = doc.data() as Map<String, dynamic>;

      // حالة المباراة العامة
      print('📊 [MATCH STATE]');
      print('   الحالة: ${data['status'] ?? 'غير معروف'}');
      print('   عدد اللاعبين: ${data['playerCount'] ?? 0}');
      print('   وقت اللعبة: ${data['gameTime'] ?? 0}');
      print('   آخر مزامنة: ${data['lastSync'] ?? 0}');

      // حالة اللاعبين في Firebase
      print('\n👤 [PLAYERS IN FIREBASE]');
      final playerState = data['playerState'] as Map<String, dynamic>?;
      if (playerState != null) {
        for (final entry in playerState.entries) {
          final playerId = entry.key;
          final state = entry.value as Map<String, dynamic>;
          print('   🆔 $playerId');
          print('      📍 (${state['x']?.toStringAsFixed(2)}, ${state['y']?.toStringAsFixed(2)})');
          print('      📊 ${state['state']}');
          print('      ⏱️ آخر تحديث: ${state['timestamp']}');

          // مقارنة مع الحالة المحلية
          if (playerId == _userId) {
            print('      ✅ هذا أنت (محلي)');
          } else if (playerId == _opponentId) {
            print('      👥 هذا الخصم');
            if (_gameService.remotePlayer != null) {
              final localX = _gameService.remotePlayer!.x;
              final localY = _gameService.remotePlayer!.y;
              final firebaseX = (state['x'] as num).toDouble();
              final firebaseY = (state['y'] as num).toDouble();
              final diffX = (localX - firebaseX).abs();
              final diffY = (localY - firebaseY).abs();
              print('      📏 الفرق مع المحلي: Δx=${diffX.toStringAsFixed(3)}, Δy=${diffY.toStringAsFixed(3)}');
            }
          }
        }
      } else {
        print('   لا توجد بيانات لاعبين');
      }

      // الوفيات
      print('\n💀 [DEATHS]');
      final deaths = data['deaths'] as Map<String, dynamic>?;
      if (deaths != null) {
        deaths.forEach((playerId, lives) {
          print('   $playerId: $lives أرواح');
        });
      }

      // الأسلحة في Firebase
      print('\n🔫 [WEAPONS IN FIREBASE]');
      final weapons = data['weapons'] as List<dynamic>?;
      if (weapons != null) {
        print('   عدد الأسلحة: ${weapons.length}');
        for (int i = 0; i < min(3, weapons.length); i++) {
          final w = weapons[i] as Map<String, dynamic>;
          print('   🔫 سلاح $i: ${w['name']} في (${w['x'].toStringAsFixed(2)}, ${w['y'].toStringAsFixed(2)})');
        }
      } else {
        print('   لا توجد أسلحة');
      }

      // المنصات في Firebase
      print('\n🏔️ [PLATFORMS IN FIREBASE]');
      final platforms = data['platforms'] as List<dynamic>?;
      if (platforms != null) {
        print('   عدد المنصات: ${platforms.length}');
        print('   النمط: ${data['platformPattern'] ?? 'غير معروف'}');
      } else {
        print('   لا توجد منصات');
      }

      print('=' * 50 + '\n');

    } catch (e) {
      print('❌ خطأ في تشخيص Firebase: $e');
    }
  }

  // ✅ دالة لتشخيص حالة الأنيميشن للاعبين
  void _debugAnimationState() {
    if (_frameCounter % 120 != 0) return; // كل ثانيتين

    print('\n' + '=' * 50);
    print('🎭 [ANIMATION DIAGNOSTIC]');
    print('=' * 50);

    // اللاعب المحلي
    if (_gameService.localPlayer != null) {
      final p = _gameService.localPlayer!;
      print('\n👤 [LOCAL ANIMATION]');
      print('   📊 PlayerState: ${p.state}');
      print('   🎯 AnimationState: ${p.animationController.currentState}');
      print('   📁 الإطار: ${p.currentFramePath.split('/').last}');
      print('   🔄 سرعة الإطارات: ${p.animationController.debugInfo['currentFrame']}');
    }

    // الخصم
    if (_gameService.remotePlayer != null) {
      final p = _gameService.remotePlayer!;
      print('\n👥 [REMOTE ANIMATION]');
      print('   📊 PlayerState: ${p.state}');
      print('   🎯 AnimationState: ${p.animationController.currentState}');
      print('   📁 الإطار: ${p.currentFramePath.split('/').last}');
      print('   🔄 سرعة الإطارات: ${p.animationController.debugInfo['currentFrame']}');

      // التحقق من صحة الإطار
      final expectedKey = p.getAnimationStateKey(p.animationController.currentState);
      final currentFrame = p.currentFramePath.split('/').last;
      if (!currentFrame.contains(expectedKey)) {
        print('   ❌ [ERROR] إطار خاطئ! المتوقع: $expectedKey');
      } else {
        print('   ✅ الإطار صحيح');
      }
    }

    print('=' * 50 + '\n');
  }

  // ✅ دالة لتشخيص الفيزياء والتأخير
  void _debugPhysicsAndLatency() {
    if (_frameCounter % 90 != 0) return; // كل 1.5 ثانية

    print('\n' + '=' * 50);
    print('⚡ [PHYSICS & LATENCY DIAGNOSTIC]');
    print('=' * 50);

    // تأخير الشبكة
    if (_lastUpdateTime['remote'] != null) {
      final now = DateTime.now();
      final lastRemote = _lastUpdateTime['remote']!;
      final latency = now.difference(lastRemote).inMilliseconds;
      print('📡 [LATENCY] تأخير الشبكة: ${latency}ms');

      if (latency > 1000) {
        print('   ⚠️ تحذير: تأخير كبير جداً!');
      }
    }

    // الفيزياء
    if (_gameService.localPlayer != null) {
      final p = _gameService.localPlayer!;
      print('\n⚡ [LOCAL PHYSICS]');
      print('   📍 الموقع الفعلي: (${p.x.toStringAsFixed(3)}, ${p.y.toStringAsFixed(3)})');
      print('   🎯 الموقع السلس: (${_playerSmoothX['local']?.toStringAsFixed(3)}, ${_playerSmoothY['local']?.toStringAsFixed(3)})');
      print('   📊 vY: ${p.velocityY.toStringAsFixed(4)}');
      print('   🪂 isGrounded: ${p.isGrounded}');
    }

    if (_gameService.remotePlayer != null) {
      final p = _gameService.remotePlayer!;
      print('\n⚡ [REMOTE PHYSICS]');
      print('   📍 الموقع: (${p.x.toStringAsFixed(3)}, ${p.y.toStringAsFixed(3)})');
      print('   📊 vY: ${p.velocityY.toStringAsFixed(4)}');
      print('   🪂 isGrounded: ${p.isGrounded}');

      // التحقق من الموت بالسقوط
      if (p.y > 1.2) {
        print('   ⚠️ الخصم في منطقة الموت!');
      }
    }

    print('=' * 50 + '\n');
  }

  // ✅ تشخيص الهجمات - معرفة سبب عدم ظهورها على الجهاز الثاني
  void _debugAttacks() {
    if (_frameCounter % 30 != 0) return; // كل نصف ثانية

    print('\n' + '=' * 50);
    print('⚔️ [ATTACKS DIAGNOSTIC] - الإطار: $_frameCounter');
    print('=' * 50);

    // الهجمات في GameService
    print('\n📊 [GAME SERVICE ATTACKS]');
    print('   عدد الهجمات النشطة: ${_gameService.activeAttacks.length}');

    for (int i = 0; i < _gameService.activeAttacks.length; i++) {
      final attack = _gameService.activeAttacks[i];
      print('   ⚔️ هجوم $i:');
      print('      النوع: ${attack.type}');
      print('      الموقع: (${attack.x.toStringAsFixed(2)}, ${attack.y.toStringAsFixed(2)})');
      print('      الاتجاه: ${attack.directionX}');
      print('      نشط: ${attack.isActive}');
      print('      العمر: ${attack.lifetime}');
      print('      الضرر: ${attack.damage}');
      print('      المسار: ${attack.weaponImagePath.split('/').last}');
    }

    // التحقق من وجود هجمات في Firebase
    _debugFirebaseAttacks();
  }

// ✅ تشخيص الهجمات في Firebase
  Future<void> _debugFirebaseAttacks() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('real_matches_fixed')
          .doc(widget.roomId)
          .get();

      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;

      print('\n🔥 [FIREBASE ATTACKS]');

      if (data.containsKey('attacks')) {
        final attacks = data['attacks'] as Map<String, dynamic>;
        print('   عدد المهاجمين: ${attacks.length}');

        attacks.forEach((playerId, attackData) {
          print('   🎮 لاعب: $playerId');
          final attack = attackData as Map<String, dynamic>;
          print('      النوع: ${attack['type']}');
          print('      الضرر: ${attack['damage']}');
          print('      الوقت: ${attack['timestamp']}');

          // مقارنة مع الحالة المحلية
          if (playerId == _userId) {
            print('      ✅ هذا أنت');
          } else if (playerId == _opponentId) {
            print('      👥 هذا الخصم');
            if (_lastProcessedAttackTimes.containsKey(playerId)) {
              final lastProcessed = _lastProcessedAttackTimes[playerId]!;
              final diff = attack['timestamp'] - lastProcessed;
              print('      ⏱️ الفرق عن آخر معالجة: ${diff}ms');
            }
          }
        });
      } else {
        print('   لا توجد هجمات في Firebase');
      }

      print('=' * 50 + '\n');

    } catch (e) {
      print('❌ خطأ في تشخيص هجمات Firebase: $e');
    }
  }

// ✅ تشخيص مزامنة الخصم
  void _debugRemotePlayerSync() {
    if (_frameCounter % 45 != 0) return;

    print('\n' + '=' * 50);
    print('🔄 [REMOTE PLAYER SYNC DIAGNOSTIC]');
    print('=' * 50);

    if (_gameService.remotePlayer == null) {
      print('❌ الخصم غير موجود');
      return;
    }

    final remote = _gameService.remotePlayer!;

    print('👥 [REMOTE PLAYER STATE]');
    print('   🆔 ID: ${remote.playerId}');
    print('   📍 الموقع: (${remote.x.toStringAsFixed(3)}, ${remote.y.toStringAsFixed(3)})');
    print('   📊 PlayerState: ${remote.state}');
    print('   🎯 AnimationState: ${remote.animationController.currentState}');
    print('   📁 الإطار: ${remote.currentFramePath.split('/').last}');
    print('   ❤️ الصحة: ${remote.health}');
    print('   🏃 السرعة: (${remote.velocityX.toStringAsFixed(4)}, ${remote.velocityY.toStringAsFixed(4)})');

    // آخر تحديث من SyncService
    if (_lastUpdateTime['remote'] != null) {
      final lastUpdate = _lastUpdateTime['remote']!;
      final now = DateTime.now();
      final latency = now.difference(lastUpdate).inMilliseconds;
      print('   📡 آخر تحديث: قبل ${latency}ms');
    }

    print('=' * 50 + '\n');
  }

  // ✅ دالة تصحيح للتأكد من عمل المستمعين
  void _debugCheckListeners() {
    Future.delayed(Duration(seconds: 5), () {
      if (!mounted || _isGameEnded) return;

      print('\n🔍 [DEBUG CHECK] التحقق من حالة النظام:');
      print('   📡 _isRealPlayerMatch: $_isRealPlayerMatch');
      print('   🎯 _opponentId: $_opponentId');
      print('   🆔 _userId: $_userId');
      print('   👤 localPlayer موجود: ${_gameService.localPlayer != null}');
      print('   👥 remotePlayer موجود: ${_gameService.remotePlayer != null}');
      print('   ⚔️ عدد الهجمات الحالية: ${_gameService.activeAttacks.length}');

      // ✅ محاولة إنشاء هجوم تجريبي بعد 7 ثوانٍ
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          print('🧪 [DEBUG] محاولة إنشاء هجوم تجريبي...');
          _testShowAttack();
        }
      });
    });
  }

}

// ========== الفئات المساعدة ==========
class _BackgroundPainter extends CustomPainter {
  final String patternName;

  _BackgroundPainter({this.patternName = 'كلاسيكي'});

  @override
  void paint(Canvas canvas, Size size) {
    try {
      if (size.width.isNaN || size.height.isNaN || size.width <= 0 || size.height <= 0) return;

      // ✅ تدرج خلفية ديناميكي
      List<Color> gradientColors;

      switch (patternName) {
        case 'متاهة':
          gradientColors = [Color(0xFF2c3e50).withOpacity(0.6), Color(0xFF3498db).withOpacity(0.4)];
          break;
        case 'أبراج':
          gradientColors = [Color(0xFF4A235A).withOpacity(0.6), Color(0xFF8E44AD).withOpacity(0.4)];
          break;
        case 'جسر':
          gradientColors = [Color(0xFF784212).withOpacity(0.6), Color(0xFFD35400).withOpacity(0.4)];
          break;
        default:
          gradientColors = [Color(0xFF2c3e50).withOpacity(0.8), Color(0xFF3498db).withOpacity(0.6)];
      }

      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: gradientColors,
      );

      final rect = Rect.fromLTWH(0, 0, size.width, size.height);
      final paint = Paint()..shader = gradient.createShader(rect);
      canvas.drawRect(rect, paint);

      // ✅ النجوم - تختلف الكثافة حسب النمط
      final starPaint = Paint()..color = Colors.white.withOpacity(0.3);
      int starCount;

      switch (patternName) {
        case 'متاهة': starCount = 30; break;
        case 'أبراج': starCount = 40; break;
        case 'جسر': starCount = 25; break;
        default: starCount = 50;
      }

      final random = Random();
      for (int i = 0; i < starCount; i++) {
        final x = random.nextDouble() * size.width;
        final y = random.nextDouble() * size.height;
        final radius = 0.5 + random.nextDouble() * 1.5;
        canvas.drawCircle(Offset(x, y), radius, starPaint);
      }
    } catch (e) {
      // تجاهل الخطأ
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SmartCameraSystem {
  static const double _minZoom = 0.8;
  static const double _maxZoom = 1.5;
  static const double _defaultZoom = 1.0;
  static const double _smoothFactor = 0.05;

  double _currentZoom = _defaultZoom;
  double _targetZoom = _defaultZoom;
  Offset _currentOffset = Offset.zero;
  Offset _targetOffset = Offset.zero;

  void update(List<OnlinePlayer> players, Size viewportSize) {
    if (players.isEmpty) return;

    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (final player in players) {
      minX = min(minX, player.x);
      maxX = max(maxX, player.x);
      minY = min(minY, player.y);
      maxY = max(maxY, player.y);
    }

    final distanceX = (maxX - minX).abs();
    final distanceY = (maxY - minY).abs();
    final maxDistance = max(distanceX, distanceY);

    if (maxDistance > 0.4) {
      _targetZoom = _maxZoom - (maxDistance * 0.5);
    } else if (maxDistance < 0.1) {
      _targetZoom = _minZoom;
    } else {
      _targetZoom = _defaultZoom;
    }

    _targetZoom = _targetZoom.clamp(_minZoom, _maxZoom);

    final centerX = (minX + maxX) / 2;
    final centerY = (minY + maxY) / 2;

    _targetOffset = Offset(
        -centerX * viewportSize.width * _currentZoom + viewportSize.width / 2,
        -centerY * viewportSize.height * _currentZoom + viewportSize.height / 2
    );

    _currentZoom += (_targetZoom - _currentZoom) * _smoothFactor;
    _currentOffset = Offset(
        _currentOffset.dx + (_targetOffset.dx - _currentOffset.dx) * _smoothFactor,
        _currentOffset.dy + (_targetOffset.dy - _currentOffset.dy) * _smoothFactor
    );
  }

  Matrix4 getTransform(Size viewportSize) {
    return Matrix4.identity()
      ..translate(viewportSize.width / 2, viewportSize.height / 2)
      ..scale(_currentZoom, _currentZoom)
      ..translate(_currentOffset.dx / _currentZoom, _currentOffset.dy / _currentZoom)
      ..translate(-viewportSize.width / 2, -viewportSize.height / 2);
  }
}

class GameNotification {
  final String id;
  final String message;
  final Color color;
  final IconData icon;
  final int durationSeconds;

  GameNotification({
    required this.id,
    required this.message,
    this.color = Colors.blue,
    this.icon = Icons.info,
    this.durationSeconds = 3,
  });
}

class BackgroundSystem {
  static final List<String> _backgroundNames = [
    'egypt',        // موجود ✓
    'forest',       // موجود ✓
    'future',       // موجود ✓
    'desert',       // موجود ✓
    'mountain',     // موجود ✓
    'space',        // موجود ✓
    'snow',         // موجود ✓
    'volcano',      // موجود ✓
    'temple',       // موجود ✓
    'castle',       // موجود ✓
    'cave',         // موجود ✓
    // أضف هذه الخلفيات الإضافية:
    'arctic',       // موجود ✓
    'city',         // موجود ✓
    'default',      // موجود ✓
    'jungle',       // موجود ✓
    'lab',          // موجود ✓
    'mystery',      // موجود ✓
    'night',        // موجود ✓
    'ocean',        // موجود ✓
    'park',         // موجود ✓
    'storm',        // موجود ✓
  ];

  static String getRandomBackground() {
    final random = Random();
    final index = random.nextInt(_backgroundNames.length);
    return 'assets/images/backgrounds/${_backgroundNames[index]}.png'; // ← .png صغيرة
  }

  // ✅ دالة للحصول على جميع أسماء الخلفيات (للتوسعة المستقبلية)
  static List<String> getAllBackgrounds() {
    return List.from(_backgroundNames);
  }

  // ✅ دالة لإضافة خلفية جديدة مستقبلاً
  static void addBackground(String backgroundName) {
    if (!_backgroundNames.contains(backgroundName)) {
      _backgroundNames.add(backgroundName);
      print('✅ تمت إضافة خلفية جديدة: $backgroundName');
    }
  }
}

// ✅ Widget مبسط جداً لعرض الخلفية بدون أخطاء
class GameBackground extends StatelessWidget {
  final String backgroundPath;

  const GameBackground({
    super.key,
    required this.backgroundPath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Image.asset(
        backgroundPath,
        fit: BoxFit.cover,
        // ✅ معالج أخطاء بسيط
        errorBuilder: (context, error, stackTrace) {
          print('❌ لا يمكن تحميل الخلفية: $backgroundPath');
          return _buildDefaultBackground();
        },
        // ✅ تحسينات أداء
        cacheWidth: 800,
        cacheHeight: 600,
      ),
    );
  }

  Widget _buildDefaultBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1a1a2e),
            Color(0xFF16213e),
            Color(0xFF0f3460),
          ],
        ),
      ),
    );
  }
}
