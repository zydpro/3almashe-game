// lib/online/services/sync_service.dart
import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../animation/advanced_animation_system.dart';
import '../models/online_character_system.dart';
import 'online_game_service.dart';
import 'package:flutter/widgets.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot>? _matchSubscription;
  Timer? _localSyncTimer;

  String? _currentMatchId;
  bool _isHost = false;
  bool _isConnected = false;

  int _lastLocalUpdate = 0;
  static const int SYNC_INTERVAL_MS = 150;

  Function(Map<String, dynamic>)? _onAttacksCallback;

  // ✅ متغيرات لمنع التكرار
  int? _lastSentAttackHash;
  int _lastSentAttackTime = 0;
  static const int MIN_ATTACK_INTERVAL = 300; // 100ms فقط للهجمات المتطابقة

  // ✅ Set بسيط لمنع التكرار
  final Set<String> _processedAttackIds = {};

  // ✅ إضافة queue للهجمات المعلقة
  final List<OnlineBattleAttack> _pendingAttacks = [];
  Timer? _attackQueueTimer;
  bool _isProcessingAttacks = false;

  void setAttacksCallback(Function(Map<String, dynamic>) callback) {
    _onAttacksCallback = callback;
  }

  void startSync({
    required String matchId,
    required bool isHost,
  }) {
    _currentMatchId = matchId;
    _isHost = isHost;
    _isConnected = true;

    print('🔄 بدء خدمة المزامنة');

    // ✅ تنظيف الـ Set كل 5 ثواني
    Timer.periodic(Duration(seconds: 5), (_) {
      _processedAttackIds.clear();
    });

    if (isHost) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeMatch();
      });
    }

    _listenToMatchUpdates();
    _startLocalSync();
  }

  Future<void> _initializeMatch() async {
    if (!_isConnected || _currentMatchId == null) return;

    try {
      final gameService = OnlineGameService.instance;
      final localPlayer = gameService.localPlayer;
      if (localPlayer == null) return;

      final now = DateTime.now().millisecondsSinceEpoch;

      await _firestore
          .collection('real_matches_fixed')
          .doc(_currentMatchId)
          .set({
        'matchId': _currentMatchId,
        'gameMode': '1v1',
        'status': 'waiting',
        'playerCount': 1,
        'maxPlayers': 2,
        'createdAt': now,
        'lastSync': now,
        'players': [
          {
            'playerId': localPlayer.playerId,
            'playerName': 'اللاعب',
            'isReady': true,
            'joinedAt': now,
          }
        ],
        'attacks': {},
      }, SetOptions(merge: true));
    } catch (e) {}
  }

  Future<bool> joinMatch(String matchId, String playerId, String playerName) async {
    if (!_isConnected) return false;

    try {
      final matchRef = _firestore.collection('real_matches_fixed').doc(matchId);

      await _firestore.runTransaction((transaction) async {
        final matchDoc = await transaction.get(matchRef);
        if (!matchDoc.exists) throw Exception();

        final data = matchDoc.data() as Map<String, dynamic>;
        final players = List<Map<String, dynamic>>.from(data['players'] ?? []);

        players.add({
          'playerId': playerId,
          'playerName': playerName,
          'isReady': true,
          'joinedAt': DateTime.now().millisecondsSinceEpoch,
        });

        transaction.update(matchRef, {
          'players': players,
          'playerCount': players.length,
          'status': 'character_selection',
        });
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  void _listenToMatchUpdates() {
    _matchSubscription?.cancel();

    _matchSubscription = _firestore
        .collection('real_matches_fixed')
        .doc(_currentMatchId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists || !_isConnected) return;

      final data = snapshot.data() as Map<String, dynamic>;

      _updateOpponentFromFirestore(data);

      // ✅ معالجة الهجمات - بسيطة جداً
      if (data.containsKey('attacks') && _onAttacksCallback != null) {
        final attacks = data['attacks'] as Map<String, dynamic>;

        // ✅ تصفية الهجمات القديمة (أحدث من 5 ثواني)
        final now = DateTime.now().millisecondsSinceEpoch;
        final recentAttacks = <String, dynamic>{};

        attacks.forEach((key, value) {
          final timestamp = value['timestamp'] as int? ?? 0;
          if (now - timestamp < 5000) {
            recentAttacks[key] = value;
          }
        });

        if (recentAttacks.isNotEmpty) {
          _onAttacksCallback!(recentAttacks);
        }
      }

    }, onError: (error) {});
  }

  void _updateOpponentFromFirestore(Map<String, dynamic> data) {
    final gameService = OnlineGameService.instance;
    if (gameService.localPlayer == null) return;

    try {
      if (data.containsKey('playerState')) {
        final playerState = data['playerState'] as Map<String, dynamic>?;

        if (playerState != null) {
          playerState.forEach((playerId, state) {
            if (playerId != gameService.localPlayer?.playerId) {
              final stateMap = state as Map<String, dynamic>;

              if (gameService.remotePlayer == null) {
                gameService.remotePlayer = OnlinePlayer(
                  playerId: playerId,
                  character: OnlineCharacter.getDefaultCharacter(),
                  x: (stateMap['x'] as num?)?.toDouble() ?? 0.7,
                  y: (stateMap['y'] as num?)?.toDouble() ?? 0.7,
                  isFacingRight: stateMap['isFacingRight'] as bool? ?? false,
                  weapons: [],
                );
              } else {
                if (stateMap.containsKey('x')) {
                  gameService.remotePlayer!.x = (stateMap['x'] as num).toDouble();
                }
                if (stateMap.containsKey('y')) {
                  gameService.remotePlayer!.y = (stateMap['y'] as num).toDouble();
                }
                if (stateMap.containsKey('health')) {
                  gameService.remotePlayer!.health = (stateMap['health'] as num).toDouble();
                }
              }
            }
          });
        }
      }
    } catch (e) {}
  }

  // ✅ إرسال الهجوم مع queue
  Future<void> sendFullAttack(OnlineBattleAttack attack) async {
    if (!_isConnected || _currentMatchId == null) return;

    final localPlayer = OnlineGameService.instance.localPlayer;
    if (localPlayer == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;

    // ✅ منع التكرار المحسن
    final attackHash = _generateAttackHash(attack);

    if (_lastSentAttackHash == attackHash && now - _lastSentAttackTime < MIN_ATTACK_INTERVAL) {
      print('⏭️ [SYNC] تجاهل هجوم مكرر - الفرق: ${now - _lastSentAttackTime}ms');
      return;
    }

    _lastSentAttackHash = attackHash;
    _lastSentAttackTime = now;

    // ✅ إضافة إلى queue بدلاً من الإرسال المباشر
    _pendingAttacks.add(attack);

    // ✅ بدء المعالج إذا لم يكن نشطاً
    if (_attackQueueTimer == null) {
      _startAttackProcessor();
    }
  }

  // ✅ الاستماع للهجمات
  void listenToAttacks(Function(Map<String, dynamic>) onAttackReceived) {
    if (_currentMatchId == null) return;

    print('👂 [SYNC] بدء الاستماع للهجمات...');

    _matchSubscription?.cancel(); // ⭐ إلغاء الاشتراك السابق

    _matchSubscription = FirebaseFirestore.instance
        .collection('real_matches_fixed')
        .doc(_currentMatchId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;

      if (data.containsKey('attacks')) {
        final attacks = data['attacks'] as Map<String, dynamic>;

        // ✅ تصفية الهجمات القديمة فقط (أحدث من 3 ثواني)
        final now = DateTime.now().millisecondsSinceEpoch;
        final recentAttacks = <String, dynamic>{};

        // ✅ استخدام Set لتتبع الـ IDs المستلمة في هذه الدفعة
        final receivedIds = <String>{};

        attacks.forEach((key, value) {
          final timestamp = value['timestamp'] as int? ?? 0;

          // ✅ 3 ثواني فقط كافية
          if (now - timestamp < 3000) {
            // ✅ التحقق من التكرار في نفس الدفعة
            if (!receivedIds.contains(key)) {
              receivedIds.add(key);
              recentAttacks[key] = value;
            }
          }
        });

        if (recentAttacks.isNotEmpty) {
          print('📢 [SYNC] إرسال ${recentAttacks.length} هجوم فريد للمعالجة');
          onAttackReceived(recentAttacks);
        }
      }
    }, onError: (error) {
      print('⚠️ [SYNC] خطأ في الاستماع: $error');
    });
  }

  void _startLocalSync() {
    _localSyncTimer?.cancel();
    _localSyncTimer = Timer.periodic(Duration(milliseconds: SYNC_INTERVAL_MS), (_) {
      if (!_isConnected || _currentMatchId == null) return;
      _sendLocalState();
    });
  }

  Future<void> _sendLocalState() async {
    final gameService = OnlineGameService.instance;
    if (gameService.localPlayer == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastLocalUpdate < SYNC_INTERVAL_MS) return;
    _lastLocalUpdate = now;

    try {
      final localPlayer = gameService.localPlayer!;

      final playerState = {
        'x': localPlayer.x,
        'y': localPlayer.y,
        'health': localPlayer.health,
        'isFacingRight': localPlayer.isFacingRight,
        'lastUpdate': now,
        'playerId': localPlayer.playerId,
        'timestamp': now,
      };

      await _firestore
          .collection('real_matches_fixed')
          .doc(_currentMatchId)
          .set({
        'playerState.${localPlayer.playerId}': playerState,
        'lastSync': now,
      }, SetOptions(merge: true));

    } catch (e) {}
  }

  Future<void> sendDeath(String playerId, int remainingLives) async {
    if (!_isConnected || _currentMatchId == null) return;

    try {
      await _firestore
          .collection('real_matches_fixed')
          .doc(_currentMatchId)
          .update({
        'deaths.$playerId': remainingLives,
        'lastSync': DateTime.now().millisecondsSinceEpoch,
      });
      print('📤 [SYNC] تم إرسال حالة الموت للاعب $playerId، الأرواح المتبقية: $remainingLives');
    } catch (e) {
      print('⚠️ [SYNC] خطأ في إرسال حالة الموت: $e');
    }
  }

  // ✅ بدء معالج الهجمات
  void _startAttackProcessor() {
    _attackQueueTimer?.cancel();
    _attackQueueTimer = Timer.periodic(Duration(milliseconds: 50), (_) {
      _processPendingAttacks();
    });
  }

  // ✅ معالجة الهجمات المعلقة بالتسلسل
  Future<void> _processPendingAttacks() async {
    if (_isProcessingAttacks || _pendingAttacks.isEmpty) return;

    _isProcessingAttacks = true;

    try {
      final attack = _pendingAttacks.removeAt(0);
      await _sendAttackImmediately(attack);
    } catch (e) {
      print('⚠️ [SYNC] خطأ في معالجة الهجوم المعلق: $e');
    } finally {
      _isProcessingAttacks = false;
    }
  }

  // ✅ إرسال الهجوم فعلياً
  Future<void> _sendAttackImmediately(OnlineBattleAttack attack) async {
    final localPlayer = OnlineGameService.instance.localPlayer;
    if (localPlayer == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final attackId = '${localPlayer.playerId}_${now}_${Random().nextInt(10000)}';

    final attackData = {
      'playerId': localPlayer.playerId,
      'type': attack.type.toString(),
      'damage': attack.damage,
      'x': attack.x,
      'y': attack.y,
      'directionX': attack.directionX,
      'weaponImagePath': attack.weaponImagePath,
      'timestamp': now,
      'hash': _generateAttackHash(attack), // ✅ تخزين الهاش للتتبع
    };

    try {
      await _firestore
          .collection('real_matches_fixed')
          .doc(_currentMatchId)
          .set({
        'attacks.$attackId': attackData,
        'lastAttackTime': now,
      }, SetOptions(merge: true));

      print('📤 [SYNC] تم إرسال هجوم (ID: $attackId)');
    } catch (e) {
      print('⚠️ [SYNC] خطأ في إرسال الهجوم: $e');
      // ✅ إعادة المحاولة بعد تأخير
      Future.delayed(Duration(milliseconds: 200), () {
        _pendingAttacks.insert(0, attack);
      });
    }
  }

  // ✅ توليد هاش فريد للهجوم
  int _generateAttackHash(OnlineBattleAttack attack) {
    return (attack.x * 1000).toInt() ^
    (attack.y * 1000).toInt() ^
    attack.damage ^
    (attack.type == OnlineAttackType.light ? 1 : 2);
  }

  void stopSync() {
    _isConnected = false;
    _matchSubscription?.cancel();
    _localSyncTimer?.cancel();
    _attackQueueTimer?.cancel();
    _processedAttackIds.clear();
    _pendingAttacks.clear();
  }
}