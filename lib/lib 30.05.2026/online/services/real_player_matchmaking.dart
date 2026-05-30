import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ✅ دالة عامة واحدة فقط للحصول على معرف ثابت للجهاز
Future<String> getStableDeviceId() async {
  final prefs = await SharedPreferences.getInstance();

  // ✅ مفتاح ثابت للجهاز
  const String deviceIdKey = 'device_unique_guest_id';

  // حاول الحصول على ID مخزن
  String? deviceId = prefs.getString(deviceIdKey);

  if (deviceId != null && deviceId.isNotEmpty) {
    print('📱 [DEVICE_ID] استخدام معرف الجهاز المخزن: $deviceId');
    return deviceId;
  }

  // ✅ إنشاء معرف فريد للجهاز
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final random = Random().nextInt(10000);
  deviceId = 'device_${timestamp}_$random';

  // ✅ حفظه في SharedPreferences
  await prefs.setString(deviceIdKey, deviceId);
  print('📱 [DEVICE_ID] تم إنشاء معرف جهاز جديد: $deviceId');

  return deviceId;
}

class RealPlayerMatchmakingFixed {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ✅ استخدم مجموعة واحدة فقط
  final String _collectionName = 'real_matches_fixed';

  // ✅ متغير للتتبع
  String? _currentMatchId;
  StreamSubscription? _matchSubscription;
  // متغير لتخزين الـ ID الثابت
  String? _cachedUserId;

  Future<String> get userId async {
    // إذا كان مخزناً في الكاش، استخدمه
    if (_cachedUserId != null) return _cachedUserId!;

    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) {
      // ✅ استخدام معرف الجهاز الثابت
      _cachedUserId = await getStableDeviceId();
      print('🆔 [USER_ID] معرف الجهاز: $_cachedUserId');
      return _cachedUserId!;
    }

    _cachedUserId = user.uid;
    print('🆔 [USER_ID] معرف Firebase: $_cachedUserId');
    return _cachedUserId!;
  }

  Future<String> get userName async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) {
      return 'ضيف';
    }
    return user.displayName ?? 'لاعب';
  }

  // ✅ البحث عن مباراة - نسخة محسنة تماماً
  Future<Map<String, dynamic>> findRealPlayerMatch(String gameMode) async {
    print('🎮 [MATCHMAKING] بدء البحث عن $gameMode');

    // ✅ اختبار الصلاحيات أولاً
    await _testFirestorePermissions();

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      // سجل دخول كضيف تلقائياً
      try {
        await _auth.signInAnonymously();
        print('✅ تم تسجيل الدخول كضيف تلقائياً');
      } catch (e) {
        throw Exception('فشل تسجيل الدخول: $e');
      }
    }

    try {
      // ✅ 1. تنظيف المباريات القديمة أولاً
      await _cleanupOldMatches();

      // ✅ 2. البحث عن مباراة موجودة بانتظار لاعب
      print('🔍 [MATCHMAKING] البحث عن مباراة قائمة...');
      final existingMatch = await _findExistingMatch(gameMode);

      if (existingMatch != null) {
        print('✅ [MATCHMAKING] وجدت مباراة قائمة!');
        return await _joinExistingMatch(existingMatch);
      }

      // ✅ 3. إذا لم يوجد، أنشئ مباراة جديدة وانتظر الخصم
      print('🆕 [MATCHMAKING] إنشاء مباراة جديدة وانتظار الخصم...');
      return await _createNewMatchAndWaitForOpponent(gameMode);

    } catch (e, stackTrace) {
      print('❌ [MATCHMAKING] خطأ في البحث: $e');
      print('📋 Stack Trace: $stackTrace');
      throw Exception('فشل في البحث: ${e.toString()}');
    }
  }

  // ✅ البحث عن مباراة قائمة
  Future<Map<String, dynamic>?> _findExistingMatch(String gameMode) async {
    try {
      final thirtySecondsAgo = DateTime.now()
          .subtract(Duration(seconds: 30))
          .millisecondsSinceEpoch;

      final currentUserId = await userId;

      print('🔍 [SEARCH] جاري البحث عن مباريات $gameMode...');
      print('👤 [SEARCH] معرف اللاعب: $currentUserId');

      final query = await _firestore
          .collection(_collectionName)
          .where('gameMode', isEqualTo: gameMode)
          .where('status', isEqualTo: 'waiting')
          .where('createdAt', isGreaterThanOrEqualTo: thirtySecondsAgo)
          .orderBy('createdAt', descending: false)
          .limit(5)
          .get();

      print('📊 [SEARCH] عدد المباريات الموجودة: ${query.docs.length}');

      for (var doc in query.docs) {
        final data = doc.data();
        final matchId = doc.id;
        final players = data['players'] as List<dynamic>? ?? [];
        final playerCount = data['playerCount'] as int? ?? 0;
        final maxPlayers = data['maxPlayers'] as int? ?? 2;

        print('🎯 [SEARCH] فحص مباراة $matchId: $playerCount/$maxPlayers');
        print('   👥 اللاعبون: ${players.map((p) => (p as Map)['playerId']).toList()}');

        // ✅ التحقق من أن اللاعب ليس موجوداً بالفعل
        bool alreadyJoined = false;
        for (var player in players) {
          final p = player as Map<String, dynamic>;
          if (p['playerId'] == currentUserId) {
            alreadyJoined = true;
            print('⚠️ [SEARCH] أنت موجود بالفعل في هذه المباراة!');
            break;
          }
        }

        if (!alreadyJoined && playerCount < maxPlayers) {
          print('✅ [SEARCH] مباراة مناسبة: $matchId');
          data['matchId'] = matchId;
          return data;
        } else {
          if (alreadyJoined) {
            print('🚫 [SEARCH] مباراة $matchId غير مناسبة: أنت موجود بالفعل');
          } else if (playerCount >= maxPlayers) {
            print('🚫 [SEARCH] مباراة $matchId غير مناسبة: مكتملة ($playerCount/$maxPlayers)');
          }
        }
      }

      print('🔍 [SEARCH] لا توجد مباريات مناسبة');
      return null;

    } catch (e) {
      print('❌ [SEARCH] خطأ في البحث: $e');
      return await _findExistingMatchFallback(gameMode);
    }
  }

  // ✅ نسخة احتياطية للبحث بدون ترتيب
  Future<Map<String, dynamic>?> _findExistingMatchFallback(String gameMode) async {
    try {
      final currentUserId = await userId;

      final query = await _firestore
          .collection(_collectionName)
          .where('gameMode', isEqualTo: gameMode)
          .where('status', isEqualTo: 'waiting')
          .limit(5)
          .get();

      for (var doc in query.docs) {
        final data = doc.data();
        final players = data['players'] as List<dynamic>? ?? [];
        final playerCount = data['playerCount'] as int? ?? 0;
        final maxPlayers = data['maxPlayers'] as int? ?? 2;

        // ✅ التحقق من عدم انضمام اللاعب
        bool alreadyJoined = false;
        for (var player in players) {
          final p = player as Map<String, dynamic>;
          if (p['playerId'] == currentUserId) {
            alreadyJoined = true;
            break;
          }
        }

        if (!alreadyJoined && playerCount < maxPlayers) {
          data['matchId'] = doc.id;
          return data;
        }
      }
      return null;
    } catch (e) {
      print('❌ [SEARCH] خطأ في البحث الاحتياطي: $e');
      return null;
    }
  }

  // ✅ انضم لمباراة قائمة
  Future<Map<String, dynamic>> _joinExistingMatch(Map<String, dynamic> matchData) async {
    final matchId = matchData['matchId'] as String;
    _currentMatchId = matchId;

    final currentUserId = await userId;
    final currentUserName = await userName;

    print('🤝 [JOIN] الانضمام للمباراة: $matchId');
    print('👤 [JOIN] معرف اللاعب: $currentUserId');

    try {
      // ✅ بيانات اللاعب الجديد
      final newPlayer = {
        'playerId': currentUserId,
        'playerName': currentUserName,
        'isReady': false,
        'character': null,
        'joinedAt': DateTime.now().millisecondsSinceEpoch,
        'isGuest': _auth.currentUser?.isAnonymous ?? true,
      };

      // ✅ تحديث المباراة باستخدام transaction لمنع التضارب
      await _firestore.runTransaction((transaction) async {
        final matchRef = _firestore.collection(_collectionName).doc(matchId);
        final matchDoc = await transaction.get(matchRef);

        if (!matchDoc.exists) {
          throw Exception('المباراة لم تعد موجودة');
        }

        final currentData = matchDoc.data() as Map<String, dynamic>;
        final currentPlayers = currentData['players'] as List<dynamic>? ?? [];
        final currentPlayerCount = currentData['playerCount'] as int? ?? 0;
        final maxPlayers = currentData['maxPlayers'] as int? ?? 2;

        // ✅ التحقق من عدم التكرار
        for (var player in currentPlayers) {
          final p = player as Map<String, dynamic>;
          if (p['playerId'] == currentUserId) {
            print('⚠️ [JOIN] اللاعب موجود بالفعل في المباراة');
            throw Exception('أنت منضم بالفعل لهذه المباراة');
          }
        }

        // ✅ تحديث المباراة
        transaction.update(matchRef, {
          'players': FieldValue.arrayUnion([newPlayer]),
          'playerCount': FieldValue.increment(1),
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });

        // ✅ إذا اكتمل عدد اللاعبين
        if (currentPlayerCount + 1 >= maxPlayers) {
          transaction.update(matchRef, {
            'status': 'character_selection',
            'isFull': true,
          });
          print('🎉 [JOIN] المباراة اكتملت!');
        }
      });

      // ✅ انتظار تحديث المباراة
      print('⏳ [JOIN] انتظار تحديث المباراة...');
      final updatedMatch = await _waitForMatchToBeReady(matchId);

      print('✅ [JOIN] تم الانضمام بنجاح!');
      return updatedMatch;

    } catch (e) {
      print('❌ [JOIN] خطأ في الانضمام: $e');
      rethrow;
    }
  }

  // ✅ إنشاء مباراة جديدة والانتظار (مع إضافة الخلفية)
  Future<Map<String, dynamic>> _createNewMatchAndWaitForOpponent(String gameMode) async {
    final matchId = 'match_${DateTime.now().millisecondsSinceEpoch}';
    _currentMatchId = matchId;
    final now = DateTime.now().millisecondsSinceEpoch;
    final maxPlayers = gameMode == '1v1' ? 2 : 4;

    final currentUserId = await userId;
    final currentUserName = await userName;

    // ✅ اختيار نمط منصات عشوائي
    final platformPattern = _getRandomPlatformPatternName();

    // ✅ اختيار خلفية عشوائية
    final background = _getRandomBackgroundName();

    print('🆕 [CREATE] إنشاء مباراة جديدة والانتظار: $matchId');
    print('👤 [CREATE] معرف اللاعب: $currentUserId');
    print('🎮 [CREATE] نمط المنصات: $platformPattern');
    print('🖼️ [CREATE] الخلفية: $background');

    final matchData = {
      'matchId': matchId,
      'gameMode': gameMode,
      'status': 'waiting',
      'playerCount': 1,
      'players': [
        {
          'playerId': currentUserId,
          'playerName': currentUserName,
          'joinedAt': now,
          'isGuest': _auth.currentUser?.isAnonymous ?? true,
        }
      ],
      'maxPlayers': maxPlayers,
      'createdAt': now,
      'updatedAt': now,
      'platformPattern': platformPattern,
      'background': background, // ✅ إضافة الخلفية
    };

    try {
      // ✅ إنشاء المباراة
      await _firestore
          .collection(_collectionName)
          .doc(matchId)
          .set(matchData);

      print('✅ [CREATE] تم إنشاء المباراة بنجاح!');

      // ✅ الانتظار حتى ينضم الخصم
      print('👥 [WAIT] انتظار انضمام الخصم...');
      final completer = Completer<Map<String, dynamic>>();

      _matchSubscription?.cancel();
      _matchSubscription = _firestore
          .collection(_collectionName)
          .doc(matchId)
          .snapshots()
          .listen((snapshot) {
        if (!snapshot.exists) {
          print('⚠️ [WAIT] المباراة حذفت!');
          return;
        }

        final data = snapshot.data() as Map<String, dynamic>;
        final playerCount = data['playerCount'] as int? ?? 0;
        final status = data['status'] as String? ?? 'waiting';

        print('📊 [WAIT] تحديث: $playerCount/$maxPlayers لاعب - $status');

        // ✅ إذا اكتمل عدد اللاعبين
        if (playerCount >= maxPlayers && status == 'character_selection') {
          print('✅ [WAIT] انضم الخصم! اكتمل الفريق');
          _matchSubscription?.cancel();
          data['matchId'] = matchId;
          completer.complete(data);
        }
      });

      // ✅ مهلة 45 ثانية
      Timer(Duration(seconds: 45), () {
        if (!completer.isCompleted) {
          print('⏰ [WAIT] انتهى وقت الانتظار، لم ينضم أحد');
          _matchSubscription?.cancel();
          _cleanupMatch(matchId);
          completer.completeError('لم ينضم لاعب آخر');
        }
      });

      return await completer.future;

    } catch (e) {
      print('❌ [CREATE] فشل: $e');
      rethrow;
    }
  }

  // ✅ دالة مساعدة للحصول على اسم نمط منصات عشوائي
  String _getRandomPlatformPatternName() {
    final patterns = [
      'كلاسيكي',
      'متاهة',
      'أبراج',
      'جسر',
      'عشوائي متقدم',
    ];

    final random = Random();
    return patterns[random.nextInt(patterns.length)];
  }

  // ✅ دالة مساعدة للحصول على خلفية عشوائية
  String _getRandomBackgroundName() {
    final backgrounds = [
      'forest.png',
      'desert.png',
      'mountain.png',
      'snow.png',
      'arctic.png',
      'castle.png',
      'egypt.png',
    ];

    final random = Random();
    return backgrounds[random.nextInt(backgrounds.length)];
  }

  // ✅ دالة مساعدة للانتظار حتى تصبح المباراة جاهزة
  Future<Map<String, dynamic>> _waitForMatchToBeReady(String matchId) async {
    final completer = Completer<Map<String, dynamic>>();

    _matchSubscription?.cancel();
    _matchSubscription = _firestore
        .collection(_collectionName)
        .doc(matchId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) {
        completer.completeError('المباراة حذفت');
        return;
      }

      final data = snapshot.data() as Map<String, dynamic>;
      final status = data['status'] as String? ?? 'waiting';

      if (status == 'character_selection') {
        print('🎉 [WAIT_FOR_READY] المباراة جاهزة لاختيار الشخصيات!');
        data['matchId'] = matchId;
        _matchSubscription?.cancel();
        completer.complete(data);
      }
    });

    Timer(Duration(seconds: 30), () {
      if (!completer.isCompleted) {
        print('⏰ [WAIT_FOR_READY] انتهى وقت الانتظار');
        _matchSubscription?.cancel();
        completer.completeError('انتهى وقت الانتظار');
      }
    });

    return completer.future;
  }

  // ✅ دالة لاختبار الصلاحيات
  Future<void> _testFirestorePermissions() async {
    print('🧪 ===== اختبار صلاحيات Firestore =====');

    try {
      final testId = 'test_${DateTime.now().millisecondsSinceEpoch}';
      await _firestore
          .collection(_collectionName)
          .doc(testId)
          .set({'test': true, 'timestamp': DateTime.now().millisecondsSinceEpoch});

      print('✅ [TEST] الكتابة ناجحة!');

      await _firestore.collection(_collectionName).doc(testId).delete();
      print('✅ [TEST] الحذف ناجح!');

    } catch (e) {
      print('❌ [TEST] فشل اختبار الصلاحيات: $e');
    }

    print('🧪 ================================');
  }

  // ✅ تنظيف المباريات القديمة
  Future<void> _cleanupOldMatches() async {
    try {
      final oneMinuteAgo = DateTime.now()
          .subtract(Duration(minutes: 1))
          .millisecondsSinceEpoch;

      final oldMatches = await _firestore
          .collection(_collectionName)
          .where('createdAt', isLessThan: oneMinuteAgo)
          .where('status', isEqualTo: 'waiting')
          .limit(10)
          .get();

      for (var doc in oldMatches.docs) {
        await doc.reference.delete();
        print('🗑️ [CLEANUP] حذف مباراة قديمة: ${doc.id}');
      }
    } catch (e) {
      print('⚠️ [CLEANUP] خطأ في التنظيف: $e');
    }
  }

  // ✅ تنظيف مباراة معينة
  Future<void> _cleanupMatch(String matchId) async {
    try {
      await _firestore.collection(_collectionName).doc(matchId).delete();
      print('🗑️ [CLEANUP] حذف مباراة: $matchId');
    } catch (e) {
      print('⚠️ [CLEANUP] خطأ في حذف المباراة: $e');
    }
  }

  // ✅ إلغاء البحث
  Future<void> cancelSearch() async {
    print('🛑 [CANCEL] إلغاء البحث...');

    _matchSubscription?.cancel();

    if (_currentMatchId != null) {
      try {
        final currentUserId = await userId;
        final matchRef = _firestore.collection(_collectionName).doc(_currentMatchId!);
        final matchDoc = await matchRef.get();

        if (matchDoc.exists) {
          final data = matchDoc.data() as Map<String, dynamic>;
          final players = data['players'] as List<dynamic>? ?? [];

          // ✅ إزالة اللاعب الحالي من القائمة
          final updatedPlayers = players.where((player) {
            final p = player as Map<String, dynamic>;
            return p['playerId'] != currentUserId;
          }).toList();

          if (updatedPlayers.isEmpty) {
            await matchRef.delete();
            print('🗑️ [CANCEL] تم حذف المباراة: ${_currentMatchId}');
          } else {
            await matchRef.update({
              'players': updatedPlayers,
              'playerCount': updatedPlayers.length,
              'status': 'waiting',
              'isFull': false,
              'updatedAt': DateTime.now().millisecondsSinceEpoch,
            });
            print('👋 [CANCEL] تم إزالة اللاعب من المباراة');
          }
        }
      } catch (e) {
        print('⚠️ [CANCEL] خطأ في الإلغاء: $e');
      }
    }

    _currentMatchId = null;
  }

  // ✅ دعم التطبيقات المتعددة
  void dispose() {
    _matchSubscription?.cancel();
    _matchSubscription = null;
  }
}

// ✅ دالة عامة واحدة فقط - استخدم هذا في كل مكان
Future<String> getStableGuestId() {
  return getStableDeviceId();
}