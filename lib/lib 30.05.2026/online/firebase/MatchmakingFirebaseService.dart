// // lib/online/services/matchmaking_firebase_service.dart
// import 'dart:async';
// import 'dart:io';
// import 'dart:math';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
//
// class MatchmakingFirebaseService {
//   static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   static final FirebaseAuth _auth = FirebaseAuth.instance;
//
//   // ✅ الأنظمة الأساسية
//   StreamSubscription? _matchmakingSubscription;
//   StreamSubscription? _queueMonitor;
//   Timer? _activityTimer;
//   Timer? _cleanupTimer;
//   Timer? _localMatchmakingTimer;
//   Timer? _quickActivityTimer;
//
//   // ✅ حالة البحث
//   String? _currentQueueId;
//   String? _currentMatchId;
//   bool _isDisposed = false;
//   bool _useFirebase = true;
//
//   // ✅ بيانات اللاعب المحلي
//   String _localUserId = '';
//   String _localUserName = '';
//   bool _isGuestMode = false;
//
//   // ✅ إحصائيات
//   int _totalPlayersFound = 0;
//   int _matchmakingAttempts = 0;
//   DateTime? _searchStartTime;
//
//   // 🔄 دالة محسنة للحصول على معرف المستخدم
//   String get currentUserId {
//     try {
//       // ✅ 1. حاول استخدام Firebase Auth أولاً
//       if (_auth.currentUser != null && _auth.currentUser!.uid.isNotEmpty) {
//         return _auth.currentUser!.uid;
//       }
//
//       // ✅ 2. إذا فشل، استخدم المعرف المحلي
//       if (_localUserId.isNotEmpty) {
//         return _localUserId;
//       }
//
//       // ✅ 3. أنشئ معرفاً جديداً
//       _localUserId = 'guest_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
//       _localUserName = 'لاعب_${_localUserId.substring(_localUserId.length - 4)}';
//       _isGuestMode = true;
//
//       print('🎭 تم إنشاء معرف ضيف محلي: $_localUserId');
//       return _localUserId;
//
//     } catch (e) {
//       print('⚠️ خطأ في الحصول على معرف المستخدم: $e');
//       return 'emergency_guest_${DateTime.now().millisecondsSinceEpoch}';
//     }
//   }
//
//   // 🔄 دالة محسنة للمصادقة (بدون إيقاف إذا فشلت)
//   Future<void> _ensureAuthenticated() async {
//     try {
//       print('🔑 بدء عملية المصادقة...');
//
//       // ✅ 1. إذا كان هناك مستخدم بالفعل
//       if (_auth.currentUser != null) {
//         print('✅ مستخدم موجود: ${_auth.currentUser!.uid}');
//         return;
//       }
//
//       // ✅ 2. محاولة الدخول كضيف عبر Firebase
//       try {
//         print('🔄 محاولة الدخول كضيف عبر Firebase...');
//         await _auth.signInAnonymously();
//         await Future.delayed(Duration(milliseconds: 300));
//
//         if (_auth.currentUser != null) {
//           print('🎉 تم الدخول كضيف: ${_auth.currentUser!.uid}');
//           _isGuestMode = true;
//           return;
//         }
//       } catch (authError) {
//         print('⚠️ فشل الدخول كضيف عبر Firebase: $authError');
//         _useFirebase = false;
//       }
//
//       // ✅ 3. استخدام وضع الضيف المحلي
//       print('🔄 استخدام النظام المحلي للمصادقة...');
//       _useFirebase = false;
//       _isGuestMode = true;
//
//     } catch (e) {
//       print('❌ خطأ غير متوقع في المصادقة: $e');
//       _useFirebase = false;
//     }
//   }
//
//   // إضافة في بداية joinMatchmakingQueue
//   void _debugMatchmakingStatus() {
//     Timer.periodic(Duration(seconds: 5), (timer) {
//       if (_isDisposed) {
//         timer.cancel();
//         return;
//       }
//
//       print('🔍 === حالة المطابقة ===');
//       print('🌐 استخدام Firebase: $_useFirebase');
//       print('📋 معرف القائمة: $_currentQueueId');
//       print('🎮 معرف المباراة: $_currentMatchId');
//       print('👥 اللاعبون الموجودون: $_totalPlayersFound');
//       print('⏱️ وقت البحث: ${DateTime.now().difference(_searchStartTime ?? DateTime.now()).inSeconds} ثانية');
//       print('========================');
//     });
//   }
//
//   Future<bool> checkIndexes() async {
//     try {
//       print('🔍 التحقق من فهارس Firebase...');
//
//       // محاولة استعلام لاختبار الفهرس
//       final testQuery = await _firestore
//           .collection('real_matches')
//           .where('gameMode', isEqualTo: '1v1')
//           .where('status', isEqualTo: 'character_selection')
//           .where('totalPlayers', isLessThan: 2)
//           .orderBy('createdAt')
//           .limit(1)
//           .get();
//
//       print('✅ فهارس Firebase تعمل بشكل صحيح');
//       return true;
//     } catch (e) {
//       if (e.toString().contains('FAILED_PRECONDITION')) {
//         print('❌ الفهرس مطلوب!');
//         print('🔗 الرابط: https://console.firebase.google.com/v1/r/project/almashe-run/firestore/indexes?create_composite=...');
//
//         // إظهار رسالة للمستخدم
//         return false;
//       }
//       print('⚠️ خطأ آخر: $e');
//       return false;
//     }
//   }
//
//   // 🚀 دالة محسنة للانضمام إلى قائمة الانتظار
//   Future<void> joinMatchmakingQueue({
//     required String gameMode,
//     required Function(Map<String, dynamic>) onMatchFound,
//     required Function(int playersFound, int playersNeeded, String status) onStatusUpdate,
//   }) async {
//     try {
//       // ✅ التحقق من الفهارس أولاً
//       final indexesOk = await checkIndexes();
//       if (!indexesOk) {
//         throw Exception('يجب إنشاء الفهرس في Firebase Console أولاً');
//       }
//       _isDisposed = false;
//       _searchStartTime = DateTime.now();
//       _matchmakingAttempts = 0;
//
//       // ✅ الحصول على الأرقام الصحيحة
//       final playersNeeded = _getPlayersNeeded(gameMode);
//       final opponentsNeeded = _getOpponentsNeeded(gameMode);
//
//       print('🎮 ===== بدء مطابقة لاعب ضد لاعب =====');
//       print('🎯 نمط اللعبة: $gameMode');
//       print('🔢 المطلوب: أنا + $opponentsNeeded خصم = $playersNeeded لاعبين');
//
//       // ✅ 1. المصادقة (بدون إيقاف إذا فشلت)
//       await _ensureAuthenticated();
//       _debugMatchmakingStatus();
//
//       // ✅ 2. الحصول على بيانات اللاعب
//       final userId = currentUserId;
//       final userName = _getPlayerName();
//
//       print('👤 اللاعب: $userName ($userId)');
//       print('🎭 الوضع: ${_isGuestMode ? "ضيف" : "مسجل"}');
//       print('🌐 النظام: ${_useFirebase ? "Firebase" : "محلي"}');
//
//       // ✅ 3. إذا كان Firebase يعمل، استخدمه
//       if (_useFirebase) {
//         await _startFirebaseMatchmaking(
//             userId,
//             userName,
//             gameMode,
//             onMatchFound,
//             onStatusUpdate
//         );
//       } else {
//         // ✅ 4. إذا فشل Firebase، استخدم النظام المحلي
//         _startLocalMatchmaking(gameMode, onMatchFound, onStatusUpdate);
//       }
//
//     } catch (e, stackTrace) {
//       print('❌ خطأ فادح في الانضمام للبحث: $e');
//       print('📋 Stack Trace: $stackTrace');
//
//       // ✅ الانتقال للنظام المحلي في حالة الخطأ
//       _startLocalMatchmaking(gameMode, onMatchFound, onStatusUpdate);
//     }
//   }
//
//   // 🔥 دالة Firebase للمطابقة
//   Future<void> _startFirebaseMatchmaking(
//       String userId,
//       String userName,
//       String gameMode,
//       Function(Map<String, dynamic>) onMatchFound,
//       Function(int playersFound, int playersNeeded, String status) onStatusUpdate,
//       ) async {
//     try {
//       // ✅ تنظيف القديم
//       await _cleanupPreviousEntries(userId);
//
//       // ✅ إضافة اللاعب إلى قائمة الانتظار
//       final playerData = _createPlayerData(userId, userName, gameMode);
//
//       final docRef = await _firestore.collection('matchmaking_queue').add(playerData);
//       _currentQueueId = docRef.id;
//
//       print('✅ انضم إلى Firebase Queue: $_currentQueueId');
//
//       final opponentsNeeded = _getOpponentsNeeded(gameMode);
//       final initialStatus = opponentsNeeded == 1
//           ? 'جاري البحث عن خصم...'
//           : 'جاري البحث عن $opponentsNeeded خصوم...';
//
//       onStatusUpdate(1, _getPlayersNeeded(gameMode), initialStatus);
//
//       // ✅ بدء أنظمة المراقبة
//       _startActivityUpdates();
//       _startQueueMonitor(gameMode, onStatusUpdate);
//       _startFirebaseListener(gameMode, onMatchFound, onStatusUpdate);
//       _startAutoCleanup();
//       _startQuickActivityUpdates();
//
//       print('📡 أنظمة Firebase جاهزة للبحث...');
//
//     } catch (e) {
//       print('❌ فشل Firebase: $e');
//       throw e; // سيتم معالجته في joinMatchmakingQueue
//     }
//   }
//
//   // 🔥 دالة النظام المحلي للمطابقة
//   void _startLocalMatchmaking(
//       String gameMode,
//       Function(Map<String, dynamic>) onMatchFound,
//       Function(int playersFound, int playersNeeded, String status) onStatusUpdate,
//       ) {
//     print('🔄 تفعيل نظام المطابقة المحلي...');
//
//     final playersNeeded = _getPlayersNeeded(gameMode);
//     final opponentsNeeded = _getOpponentsNeeded(gameMode);
//
//     _useFirebase = false;
//
//     // ✅ إلغاء أي مؤقت سابق
//     _localMatchmakingTimer?.cancel();
//
//     // ✅ رسالة بدء البحث
//     final initialStatus = opponentsNeeded == 1
//         ? '🔍 جاري البحث عن خصم محلي...'
//         : '🔍 جاري البحث عن $opponentsNeeded خصوم محليين...';
//
//     onStatusUpdate(1, playersNeeded, initialStatus);
//
//     // ✅ محاكاة البحث
//     _localMatchmakingTimer = Timer.periodic(Duration(seconds: 2), (timer) {
//       if (_isDisposed) {
//         timer.cancel();
//         return;
//       }
//
//       // ✅ محاكاة العثور على خصوم تدريجياً
//       final fakeOpponentsFound = min(_matchmakingAttempts + 1, opponentsNeeded);
//       final fakePlayersFound = 1 + fakeOpponentsFound;
//
//       _matchmakingAttempts++;
//
//       print('🔄 [محلي] المحاولة #$_matchmakingAttempts: وجدنا $fakeOpponentsFound خصم');
//
//       // ✅ تحديث الواجهة
//       if (mounted) {
//         onStatusUpdate(
//             fakePlayersFound,
//             playersNeeded,
//             _getLocalStatusMessage(fakeOpponentsFound, opponentsNeeded)
//         );
//       }
//
//       // ✅ إذا وجدنا العدد المطلوب
//       if (fakeOpponentsFound >= opponentsNeeded) {
//         timer.cancel();
//
//         print('🎯 [محلي] تم العثور على جميع الخصوم!');
//
//         Timer(Duration(seconds: 1), () {
//           if (!_isDisposed) {
//             final matchData = _createLocalMatchData(gameMode);
//             print('🎉 تم إنشاء مباراة محلية: ${matchData['matchId']}');
//             onMatchFound(matchData);
//           }
//         });
//       }
//     });
//   }
//
//   // 📡 نظام الاستماع لـ Firebase
//   void _startFirebaseListener(
//       String gameMode,
//       Function(Map<String, dynamic>) onMatchFound,
//       Function(int playersFound, int playersNeeded, String status) onStatusUpdate,
//       ) {
//     _matchmakingSubscription?.cancel();
//
//     final playersNeeded = _getPlayersNeeded(gameMode);
//     final opponentsNeeded = _getOpponentsNeeded(gameMode);
//
//     print('📡 بدء الاستماع لـ Firebase...');
//
//     try {
//       _matchmakingSubscription = _firestore
//           .collection('matchmaking_queue')
//           .where('gameMode', isEqualTo: gameMode)
//           .where('status', isEqualTo: 'searching')
//           .orderBy('joinedAt', descending: false)
//           .snapshots()
//           .listen((snapshot) async {
//
//         print('📊 [Firebase Listener] حدث جديد: ${snapshot.docs.length} لاعب');
//
//         if (_isDisposed) return;
//
//         final docs = snapshot.docs;
//         final activePlayers = _filterActivePlayers(docs);
//
//         // ✅ حساب العدد الصحيح
//         final totalPlayers = activePlayers.length + 1; // اللاعب الحالي + الخصوم
//
//         print('📈 [Firebase] اللاعبون النشطون: ${activePlayers.length}');
//         print('📈 [Firebase] الإجمالي مع اللاعب الحالي: $totalPlayers');
//
//         if (mounted) {
//           onStatusUpdate(
//               totalPlayers,
//               playersNeeded,
//               _getStatusMessage(totalPlayers, playersNeeded)
//           );
//         }
//
//         // ✅ إذا كان لدينا عدد كافٍ من الخصوم
//         if (activePlayers.length >= opponentsNeeded) {
//           print('🎯 [Firebase] وجدنا ${activePlayers.length} خصم من أصل $opponentsNeeded');
//
//           // ✅ إيقاف المؤقتات أولاً
//           _activityTimer?.cancel();
//           _quickActivityTimer?.cancel();
//
//           // ✅ محاولة إنشاء المباراة
//           try {
//             await _attemptToCreateRealMatch(gameMode, activePlayers, onMatchFound, onStatusUpdate);
//           } catch (e) {
//             print('❌ فشل في إنشاء المباراة: $e');
//
//             // ✅ إعادة تشغيل المؤقتات في حالة الفشل
//             _startActivityUpdates();
//             _startQuickActivityUpdates();
//           }
//         }
//       }, onError: (error) {
//         print('❌ خطأ في استماع Firebase: $error');
//
//         // ✅ إعادة المحاولة بعد تأخير
//         Timer(Duration(seconds: 3), () {
//           if (!_isDisposed) {
//             print('🔄 إعادة تشغيل الاستماع...');
//             _startFirebaseListener(gameMode, onMatchFound, onStatusUpdate);
//           }
//         });
//       });
//     } catch (e) {
//       print('❌ خطأ في بدء الاستماع: $e');
//     }
//   }
//
//   // 🔧 فلترة اللاعبين النشطين
//   List<Map<String, dynamic>> _filterActivePlayers(List<QueryDocumentSnapshot> docs) {
//     final now = DateTime.now();
//     final activePlayers = <Map<String, dynamic>>[];
//     final currentUserId = this.currentUserId;
//
//     for (var doc in docs) {
//       final data = doc.data() as Map<String, dynamic>?;
//       if (data == null) continue;
//
//       final playerId = data['playerId'] as String?;
//       final lastActive = data['lastActive'] as Timestamp?;
//       final status = data['status'] as String?;
//
//       // ✅ 1. تجاهل اللاعب الحالي
//       if (playerId == currentUserId) {
//         continue;
//       }
//
//       // ✅ 2. التحقق من الحالة
//       if (status != 'searching') {
//         continue;
//       }
//
//       // ✅ 3. التحقق من النشاط (30 ثانية)
//       if (lastActive != null) {
//         final secondsSinceActive = now.difference(lastActive.toDate()).inSeconds;
//
//         if (secondsSinceActive < 30) {
//           activePlayers.add({
//             ...data,
//             'docId': doc.id,
//             'secondsSinceActive': secondsSinceActive,
//           });
//           print('✅ لاعب نشط: ${data['playerName']} (منذ $secondsSinceActive ثانية)');
//         } else {
//           print('⚠️ لاعب غير نشط: ${data['playerName']} (منذ $secondsSinceActive ثانية)');
//         }
//       }
//     }
//
//     return activePlayers;
//   }
//
//   // 🎯 محاولة إنشاء مباراة حقيقية
//   Future<void> _attemptToCreateRealMatch(
//       String gameMode,
//       List<Map<String, dynamic>> activePlayers,
//       Function(Map<String, dynamic>) onMatchFound,
//       Function(int playersFound, int playersNeeded, String status) onStatusUpdate,
//       ) async {
//     try {
//       final opponentsNeeded = _getOpponentsNeeded(gameMode);
//
//       print('🎯 محاولة إنشاء مباراة: وجدنا ${activePlayers.length} خصم');
//
//       // ✅ تأكد من أن لدينا عدد كافٍ من الخصوم
//       if (activePlayers.length < opponentsNeeded) {
//         print('⚠️ عدد الخصوم غير كافٍ: ${activePlayers.length}/$opponentsNeeded');
//         return;
//       }
//
//       // ✅ أخذ العدد المطلوب فقط
//       final opponentsToMatch = activePlayers.take(opponentsNeeded).toList();
//
//       print('🎮 جاري إنشاء مباراة مع ${opponentsToMatch.length} خصم...');
//
//       // ✅ تحديث الواجهة أولاً
//       if (mounted) {
//         onStatusUpdate(
//             opponentsToMatch.length + 1,
//             _getPlayersNeeded(gameMode),
//             '🎉 جاري إنشاء المباراة...'
//         );
//       }
//
//       // ✅ إنشاء المباراة
//       await _createRealPlayerMatch(gameMode, opponentsToMatch, onMatchFound);
//
//     } catch (e, stackTrace) {
//       print('❌ خطأ في إنشاء المباراة: $e');
//       print('📋 Stack Trace: $stackTrace');
//
//       // ✅ إعادة حالة البحث
//       if (mounted) {
//         onStatusUpdate(1, _getPlayersNeeded(gameMode), '🔄 إعادة المحاولة...');
//       }
//
//       // ✅ استخدام النظام المحلي كبديل
//       _startLocalMatchmaking(gameMode, onMatchFound, onStatusUpdate);
//     }
//   }
//
// // 🏆 إنشاء مباراة حقيقية في Firebase (نسخة محسنة)
//   Future<void> _createRealPlayerMatch(
//       String gameMode,
//       List<Map<String, dynamic>> opponents,
//       Function(Map<String, dynamic>) onMatchFound,
//       ) async {
//     try {
//       // ✅ 1. تأخير عشوائي لمنع إنشاء مباريات متعددة في نفس الوقت
//       final randomDelay = Duration(milliseconds: Random().nextInt(2000));
//       print('⏳ تأخير عشوائي: ${randomDelay.inMilliseconds}ms');
//       await Future.delayed(randomDelay);
//
//       // ✅ 2. تحقق أولاً إذا كان هناك مباراة يمكن الانضمام إليها (بعد التأخير)
//       final existingMatch = await _checkExistingMatch(gameMode, opponents);
//       if (existingMatch != null && !_isDisposed) {
//         print('🎯 [بعد التأخير] الانضمام لمباراة موجودة: ${existingMatch['matchId']}');
//         print('👥 اللاعبون الحاليون: ${existingMatch['totalPlayers']}/${existingMatch['maxPlayers']}');
//
//         _currentMatchId = existingMatch['matchId'] as String;
//
//         // ✅ 3. انضم للمباراة الموجودة
//         await _joinExistingMatch(existingMatch);
//
//         // ✅ 4. تحديث بيانات المباراة مع اللاعب الجديد
//         final updatedMatch = await _getUpdatedMatchData(existingMatch['matchId'] as String);
//
//         // ✅ 5. أرسل بيانات المباراة المحدثة
//         if (!_isDisposed && updatedMatch != null) {
//           print('✅ تم الانضمام بنجاح للمباراة: ${updatedMatch['matchId']}');
//           Future.microtask(() => onMatchFound(updatedMatch));
//         }
//         return;
//       }
//
//       // ✅ 6. فقط إذا لم تكن هناك مباراة، أنشئ واحدة جديدة
//       print('🎮 إنشاء مباراة جديدة (بعد التأخير والفحص)...');
//
//       final matchId = 'real_match_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
//       _currentMatchId = matchId;
//
//       final user = _auth.currentUser;
//       final userId = user?.uid ?? currentUserId;
//       final userName = user?.displayName ?? _getPlayerName();
//
//       // ✅ 7. إنشاء قائمة اللاعبين مع التأكد من الحقول الصحيحة
//       final playersList = _createRealPlayersList(userId, userName, opponents);
//       final playersByIdMap = _createRealPlayersByIdMap(userId, userName, opponents);
//
//       // ✅ 8. بيانات المباراة الجديدة مع تحسينات
//       final matchData = {
//         'matchId': matchId,
//         'gameMode': gameMode,
//         'status': 'character_selection',
//         'phase': 'character_selection',
//         'createdAt': FieldValue.serverTimestamp(), // ✅ استخدام Timestamp من Firebase
//         'updatedAt': FieldValue.serverTimestamp(),
//         'maxPlayers': _getPlayersNeeded(gameMode),
//         'players': playersList,
//         'playersById': playersByIdMap,
//         'matchType': 'player_vs_player',
//         'isRealMatch': true,
//         'totalPlayers': opponents.length + 1, // أنت + الخصوم
//         'matchCreationTime': DateTime.now().toIso8601String(),
//         'appVersion': '1.0.0',
//         'createdBy': userId,
//         'isMatchReady': false,
//         'isFull': false,
//         'isLocal': false, // ✅ تأكيد أنها ليست محلية
//         'searchTimestamp': DateTime.now().millisecondsSinceEpoch, // ✅ لتتبع الوقت
//       };
//
//       print('🎉 ==== إنشاء مباراة جديدة ====');
//       print('🆔 Match ID: $matchId');
//       print('👤 المنشئ: $userName ($userId)');
//       print('🎮 نمط اللعبة: $gameMode');
//       print('👥 اللاعبون: ${opponents.length + 1} لاعب');
//       print('📊 السعة: ${opponents.length + 1}/${_getPlayersNeeded(gameMode)}');
//
//       // ✅ 9. التحقق أن جميع الخصوم في نفس القائمة
//       final allInSameQueue = await _ensureAllPlayersInSameMatch(matchId, opponents);
//       if (!allInSameQueue) {
//         print('⚠️ بعض الخصوم ليسوا في نفس القائمة، إعادة المحاولة...');
//         throw Exception('اللاعبون غير متوفرين');
//       }
//
//       // ✅ 10. حفظ المباراة في Firebase
//       await _firestore.collection('real_matches').doc(matchId).set(matchData);
//       print('✅ تم حفظ المباراة في Firebase');
//
//       // ✅ 11. تحديث حالة اللاعبين للانضمام لنفس المباراة
//       await _updatePlayersMatchStatus(opponents, matchId);
//
//       // ✅ 12. تحديث حالة اللاعب الحالي أيضاً
//       if (_currentQueueId != null) {
//         await _firestore.collection('matchmaking_queue').doc(_currentQueueId).update({
//           'status': 'matched',
//           'matchId': matchId,
//           'matchedAt': FieldValue.serverTimestamp(),
//           'matchFound': true,
//         });
//         print('✅ تم تحديث حالة اللاعب الحالي');
//       }
//
//       // ✅ 13. إضافة تأخير إضافي قبل تحديث حالة المباراة
//       await Future.delayed(Duration(milliseconds: 500));
//
//       // ✅ 14. تحديث حالة المباراة لتكون جاهزة
//       await _firestore.collection('real_matches').doc(matchId).update({
//         'isMatchReady': true,
//         'updatedAt': FieldValue.serverTimestamp(),
//       });
//
//       print('✅ تم إنشاء المباراة بنجاح!');
//
//       // ✅ 15. جلب البيانات المحدثة للمباراة
//       final updatedMatchDoc = await _firestore.collection('real_matches').doc(matchId).get();
//       final finalMatchData = updatedMatchDoc.data() as Map<String, dynamic>;
//       finalMatchData['matchId'] = matchId; // ✅ تأكيد وجود matchId
//
//       // ✅ 16. تسجيل معلومات المباراة للتصحيح
//       print('📊 معلومات المباراة النهائية:');
//       print('   - Match ID: ${finalMatchData['matchId']}');
//       print('   - Total Players: ${finalMatchData['totalPlayers']}');
//       print('   - Players Count: ${(finalMatchData['players'] as List).length}');
//       print('   - isRealMatch: ${finalMatchData['isRealMatch']}');
//
//       // ✅ 17. إرسال بيانات المباراة
//       if (!_isDisposed) {
//         Future.microtask(() => onMatchFound(finalMatchData));
//       }
//
//     } catch (e, stackTrace) {
//       print('❌ خطأ في إنشاء المباراة الحقيقية: $e');
//       print('📋 Stack Trace: $stackTrace');
//
//       // ✅ 18. تنظيف الموارد في حالة الخطأ
//       _currentMatchId = null;
//
//       // ✅ 19. إعادة تعيين حالة البحث للاعبين المتأثرين
//       await _resetPlayersSearchStatus(opponents);
//
//       throw Exception('فشل في إنشاء المباراة: $e');
//     }
//   }
//
// // ✅ دالة مساعدة: الحصول على بيانات المباراة المحدثة
//   Future<Map<String, dynamic>?> _getUpdatedMatchData(String matchId) async {
//     try {
//       final doc = await _firestore.collection('real_matches').doc(matchId).get();
//       if (doc.exists) {
//         final data = doc.data() as Map<String, dynamic>;
//         data['matchId'] = doc.id; // ✅ تأكيد وجود matchId
//         return data;
//       }
//       return null;
//     } catch (e) {
//       print('⚠️ خطأ في الحصول على بيانات المباراة: $e');
//       return null;
//     }
//   }
//
// // ✅ دالة مساعدة: التأكد من أن جميع اللاعبين في نفس المباراة
//   Future<bool> _ensureAllPlayersInSameMatch(String matchId, List<Map<String, dynamic>> opponents) async {
//     try {
//       print('🔍 التحقق من توحيد المباراة...');
//
//       for (var opponent in opponents) {
//         final playerDocId = opponent['docId'] as String?;
//         if (playerDocId != null) {
//           final playerDoc = await _firestore.collection('matchmaking_queue').doc(playerDocId).get();
//           if (playerDoc.exists) {
//             final playerData = playerDoc.data();
//             final playerStatus = playerData?['status'] as String?;
//             final playerMatchId = playerData?['matchId'] as String?;
//
//             // ✅ التحقق من أن اللاعب لا يزال يبحث
//             if (playerStatus != 'searching') {
//               print('⚠️ اللاعب $playerDocId ليس في حالة بحث (الحالة: $playerStatus)');
//               return false;
//             }
//
//             // ✅ التحقق من أن اللاعب ليس في مباراة أخرى
//             if (playerMatchId != null && playerMatchId != matchId) {
//               print('⚠️ الخصم في مباراة مختلفة: $playerMatchId != $matchId');
//               return false;
//             }
//           } else {
//             print('⚠️ وثيقة اللاعب $playerDocId غير موجودة');
//             return false;
//           }
//         }
//       }
//
//       print('✅ جميع اللاعبين متاحين لنفس المباراة');
//       return true;
//     } catch (e) {
//       print('⚠️ خطأ في التحقق من توحيد المباراة: $e');
//       return false;
//     }
//   }
//
// // ✅ دالة مساعدة: إعادة تعيين حالة البحث للاعبين
//   Future<void> _resetPlayersSearchStatus(List<Map<String, dynamic>> opponents) async {
//     try {
//       final batch = _firestore.batch();
//
//       for (var opponent in opponents) {
//         final playerDocId = opponent['docId'] as String?;
//         if (playerDocId != null) {
//           final playerRef = _firestore.collection('matchmaking_queue').doc(playerDocId);
//           batch.update(playerRef, {
//             'status': 'searching',
//             'matchId': null,
//             'matchedAt': null,
//             'matchFound': false,
//           });
//         }
//       }
//
//       if (_currentQueueId != null) {
//         final currentRef = _firestore.collection('matchmaking_queue').doc(_currentQueueId);
//         batch.update(currentRef, {
//           'status': 'searching',
//           'matchId': null,
//           'matchedAt': null,
//           'matchFound': false,
//         });
//       }
//
//       await batch.commit();
//       print('✅ تم إعادة تعيين حالة البحث للاعبين');
//     } catch (e) {
//       print('⚠️ خطأ في إعادة تعيين حالة البحث: $e');
//     }
//   }
//
//   // ✅ دالة جديدة للانضمام لمباراة موجودة
// // ✅ دالة محسنة للانضمام لمباراة موجودة
//   Future<void> _joinExistingMatch(Map<String, dynamic> matchData) async {
//     try {
//       final matchId = matchData['matchId'] as String;
//
//       print('🤝 محاولة الانضمام للمباراة: $matchId');
//
//       // ✅ الحصول على البيانات الحالية للمباراة أولاً
//       final currentMatchDoc = await _firestore.collection('real_matches').doc(matchId).get();
//       if (!currentMatchDoc.exists) {
//         print('❌ المباراة غير موجودة: $matchId');
//         return;
//       }
//
//       final currentData = currentMatchDoc.data() as Map<String, dynamic>;
//       final currentPlayers = currentData['totalPlayers'] as int? ?? 0;
//       final maxPlayers = currentData['maxPlayers'] as int? ?? 2;
//
//       // ✅ التحقق من أن المباراة لم تكتمل
//       if (currentPlayers >= maxPlayers) {
//         print('⚠️ المباراة $matchId مكتملة بالفعل ($currentPlayers/$maxPlayers)');
//         return;
//       }
//
//       // ✅ الحصول على بيانات اللاعب
//       final user = _auth.currentUser;
//       final userId = user?.uid ?? currentUserId;
//       final userName = user?.displayName ?? _getPlayerName();
//
//       // ✅ التأكد من أن اللاعب ليس في المباراة بالفعل
//       final playersById = currentData['playersById'] as Map<String, dynamic>? ?? {};
//       if (playersById.containsKey(userId)) {
//         print('⚠️ اللاعب موجود بالفعل في المباراة: $userName ($userId)');
//         return;
//       }
//
//       // ✅ إنشاء بيانات اللاعب الجديد
//       final newPlayerData = {
//         'playerId': userId,
//         'playerName': userName,
//         'isReady': false,
//         'character': null,
//         'joinedAt': FieldValue.serverTimestamp(),
//         'readyAt': null,
//         'isRealPlayer': true,
//         'playerType': 'real',
//         'isLocal': false,
//         'lastActive': FieldValue.serverTimestamp(),
//       };
//
//       print('👤 إضافة اللاعب: $userName ($userId)');
//
//       // ✅ تحديث المباراة بإضافة اللاعب الجديد
//       await _firestore.collection('real_matches').doc(matchId).update({
//         'players': FieldValue.arrayUnion([newPlayerData]),
//         'playersById.$userId': newPlayerData,
//         'totalPlayers': FieldValue.increment(1),
//         'updatedAt': FieldValue.serverTimestamp(),
//       });
//
//       print('✅ انضم اللاعب $userName للمباراة $matchId');
//
//       // ✅ تحديث حالة قائمة الانتظار
//       if (_currentQueueId != null) {
//         await _firestore.collection('matchmaking_queue').doc(_currentQueueId).update({
//           'status': 'matched',
//           'matchId': matchId,
//           'matchedAt': FieldValue.serverTimestamp(),
//           'matchFound': true,
//         });
//         print('✅ تم تحديث حالة قائمة الانتظار');
//       }
//
//       // ✅ إذا أصبحت المباراة مكتملة، عَلمها
//       final newTotal = currentPlayers + 1;
//       if (newTotal >= maxPlayers) {
//         await _firestore.collection('real_matches').doc(matchId).update({
//           'isFull': true,
//           'updatedAt': FieldValue.serverTimestamp(),
//         });
//         print('🎉 المباراة $matchId أصبحت مكتملة! ($newTotal/$maxPlayers)');
//       }
//
//     } catch (e, stackTrace) {
//       print('❌ خطأ في الانضمام للمباراة الموجودة: $e');
//       print('📋 Stack Trace: $stackTrace');
//       throw e;
//     }
//   }
//
// // ✅ دالة محسنة للبحث عن مباراة موجودة
//   Future<Map<String, dynamic>?> _checkExistingMatch(
//       String gameMode,
//       List<Map<String, dynamic>> opponents
//       ) async {
//     try {
//       print('🔍 [تفصيلي] البحث عن مباراة موجودة بنمط: $gameMode');
//
//       final now = DateTime.now();
//       // ✅ توسيع نافذة البحث إلى 120 ثانية
//       final timeWindow = now.subtract(Duration(seconds: 120));
//
//       // ✅ استخدام Timestamp للتوافق مع Firebase
//       final timestamp = Timestamp.fromDate(timeWindow);
//
//       print('⏰ نافذة البحث: منذ $timeWindow');
//
//       final query = _firestore
//           .collection('real_matches')
//           .where('gameMode', isEqualTo: gameMode)
//           .where('status', isEqualTo: 'character_selection')
//           .where('createdAt', isGreaterThan: timestamp)
//           .where('totalPlayers', isLessThan: _getPlayersNeeded(gameMode))
//           .orderBy('createdAt', descending: false)
//           .limit(1); // ✅ خذ أول مباراة فقط
//
//       final snapshot = await query.get();
//
//       if (snapshot.docs.isNotEmpty) {
//         final matchDoc = snapshot.docs.first;
//         final matchData = matchDoc.data() as Map<String, dynamic>;
//         matchData['matchId'] = matchDoc.id; // ✅ تأكيد وجود matchId
//
//         // ✅ الحصول على بيانات المباراة بالكامل
//         final players = matchData['players'] as List<dynamic>? ?? [];
//         final playersById = matchData['playersById'] as Map<String, dynamic>? ?? {};
//
//         print('✅ [تفصيلي] وجدنا مباراة للانضمام: ${matchData['matchId']}');
//         print('   👥 اللاعبون الحاليون: ${players.length}');
//         print('   📊 السعة: ${matchData['totalPlayers']}/${matchData['maxPlayers']}');
//         print('   🕐 الوقت المنقضي: ${now.difference(timeWindow).inSeconds} ثانية');
//
//         // ✅ التحقق من أن المباراة ليست مكتملة
//         final currentPlayers = matchData['totalPlayers'] as int? ?? 0;
//         final maxPlayers = matchData['maxPlayers'] as int? ?? 2;
//
//         if (currentPlayers < maxPlayers) {
//           return matchData;
//         } else {
//           print('⚠️ المباراة مكتملة بالفعل ($currentPlayers/$maxPlayers)');
//         }
//       } else {
//         print('🔍 [تفصيلي] لا توجد مباريات متاحة للانضمام');
//         print('   🔍 بحث عن: gameMode=$gameMode, status=character_selection');
//         print('   🔍 بعد الوقت: $timeWindow');
//         print('   🔍 totalPlayers < ${_getPlayersNeeded(gameMode)}');
//       }
//
//       return null;
//     } catch (e, stackTrace) {
//       print('❌ [تفصيلي] خطأ في البحث عن مباراة موجودة: $e');
//       print('📋 Stack Trace: $stackTrace');
//
//       // ✅ رسالة مساعدة للمطور
//       if (e.toString().contains('index')) {
//         print('''
//       ⚠️ **مشكلة في الفهرس!**
//       🔗 **الروابط لإنشاء الفهرس:**
//
//       1. الفهرس الأول:
//       https://console.firebase.google.com/v1/r/project/almashe-run/firestore/indexes?create_composite=ClFwcm9qZWN0cy9hbG1hc2hlLXJ1bi9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvcmVhbF9tYXRjaGVzL2luZGV4ZXMvXxACGgwKCGdhbWVNb2RlEAEaCgoGc3RhdHVzEAEaDQoJY3JlYXRlZEF0EAEaEAoMdG90YWxQbGF5ZXJzEAFgAA==
//
//       2. الفهرس الثاني:
//       https://console.firebase.google.com/v1/r/project/almashe-run/firestore/indexes?create_composite=ClFwcm9qZWN0cy9hbG1hc2hlLXJ1bi9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvcmVhbF9tYXRjaGVzL2luZGV4ZXMvXxACGgwKCGdhbWVNb2RlEAEaCgoGc3RhdHVzEAEaEAoMdG90YWxQbGF5ZXJzEAEaDQoJY3JlYXRlZEF0EAFgAA==
//       ''');
//       }
//
//       return null;
//     }
//   }
//   // ⏰ نظام تحديث النشاط
//   void _startActivityUpdates() {
//     _activityTimer?.cancel();
//
//     _activityTimer = Timer.periodic(Duration(seconds: 15), (timer) async {
//       if (_currentQueueId != null && !_isDisposed && _useFirebase) {
//         try {
//           await _firestore
//               .collection('matchmaking_queue')
//               .doc(_currentQueueId)
//               .update({
//             'lastActive': FieldValue.serverTimestamp(),
//             'updatedAt': FieldValue.serverTimestamp(),
//           });
//         } catch (e) {
//           print('⚠️ خطأ في تحديث النشاط: $e');
//         }
//       } else {
//         timer.cancel();
//       }
//     });
//   }
//
//   // ⚡ تحديثات نشاط سريعة
//   void _startQuickActivityUpdates() {
//     _quickActivityTimer?.cancel();
//
//     _quickActivityTimer = Timer.periodic(Duration(seconds: 5), (timer) {
//       if (_currentQueueId != null && !_isDisposed && _useFirebase) {
//         _firestore
//             .collection('matchmaking_queue')
//             .doc(_currentQueueId)
//             .update({
//           'lastActive': FieldValue.serverTimestamp(),
//         }).catchError((e) {
//           print('⚠️ خطأ في التحديث السريع: $e');
//         });
//       } else {
//         timer.cancel();
//       }
//     });
//   }
//
//   // 📊 مراقبة القائمة
//   void _startQueueMonitor(
//       String gameMode,
//       Function(int playersFound, int playersNeeded, String status) onStatusUpdate,
//       ) {
//     _queueMonitor?.cancel();
//
//     if (!_useFirebase) return;
//
//     _queueMonitor = _firestore
//         .collection('matchmaking_queue')
//         .where('gameMode', isEqualTo: gameMode)
//         .where('status', isEqualTo: 'searching')
//         .snapshots()
//         .listen((snapshot) {
//
//       if (_isDisposed) return;
//
//       final activeCount = _filterActivePlayers(snapshot.docs).length;
//       final playersNeeded = _getPlayersNeeded(gameMode);
//
//       if (mounted) {
//         onStatusUpdate(
//             activeCount + 1,
//             playersNeeded,
//             _getStatusMessage(activeCount + 1, playersNeeded)
//         );
//       }
//
//       _totalPlayersFound = activeCount;
//     });
//   }
//
//   // 🧹 التنظيف التلقائي
//   void _startAutoCleanup() {
//     _cleanupTimer?.cancel();
//
//     _cleanupTimer = Timer.periodic(Duration(minutes: 2), (timer) async {
//       if (_isDisposed || !_useFirebase) {
//         timer.cancel();
//         return;
//       }
//
//       try {
//         final fiveMinutesAgo = DateTime.now().subtract(Duration(minutes: 5));
//         final cutoffTimestamp = Timestamp.fromDate(fiveMinutesAgo);
//
//         final query = await _firestore
//             .collection('matchmaking_queue')
//             .where('lastActive', isLessThan: cutoffTimestamp)
//             .where('status', isEqualTo: 'searching')
//             .get();
//
//         if (query.docs.isNotEmpty) {
//           final batch = _firestore.batch();
//           for (var doc in query.docs) {
//             batch.delete(doc.reference);
//           }
//           await batch.commit();
//           print('🧹 تم تنظيف ${query.docs.length} لاعب غير نشط');
//         }
//       } catch (e) {
//         print('⚠️ خطأ في التنظيف التلقائي: $e');
//       }
//     });
//   }
//
//   // ❌ إلغاء البحث
//   Future<void> cancelSearch() async {
//     print('❌ إلغاء البحث...');
//
//     if (_useFirebase && _currentQueueId != null) {
//       try {
//         await _firestore
//             .collection('matchmaking_queue')
//             .doc(_currentQueueId)
//             .delete();
//         print('✅ تم إلغاء البحث بنجاح');
//       } catch (e) {
//         print('⚠️ خطأ في إلغاء البحث: $e');
//       }
//     }
//
//     _cleanup();
//   }
//
//   // 🧹 تنظيف الموارد
//   void _cleanup() {
//     if (_isDisposed) return;
//
//     print('🧹 تنظيف جميع الموارد...');
//
//     _matchmakingSubscription?.cancel();
//     _queueMonitor?.cancel();
//     _activityTimer?.cancel();
//     _cleanupTimer?.cancel();
//     _localMatchmakingTimer?.cancel();
//     _quickActivityTimer?.cancel();
//
//     _matchmakingSubscription = null;
//     _queueMonitor = null;
//     _activityTimer = null;
//     _cleanupTimer = null;
//     _localMatchmakingTimer = null;
//     _quickActivityTimer = null;
//
//     _currentQueueId = null;
//     _currentMatchId = null;
//     _isDisposed = true;
//
//     print('✅ تم تنظيف جميع الموارد');
//   }
//
//   // 🛠️ دوال مساعدة
//   int _getPlayersNeeded(String gameMode) {
//     return gameMode == '1v1' ? 2 : 4;
//   }
//
//   int _getOpponentsNeeded(String gameMode) {
//     return gameMode == '1v1' ? 1 : 3;
//   }
//
//   String _getStatusMessage(int playersFound, int playersNeeded) {
//     final opponentsFound = playersFound - 1;
//     final opponentsNeeded = playersNeeded - 1;
//
//     if (opponentsFound >= opponentsNeeded) {
//       return '🎉 تم العثور على جميع الخصوم!';
//     } else if (opponentsFound > 0) {
//       if (opponentsNeeded == 1) {
//         return '✅ وجدنا خصماً واحداً...';
//       } else {
//         return '👥 وجدنا $opponentsFound من أصل $opponentsNeeded خصوم...';
//       }
//     } else {
//       if (opponentsNeeded == 1) {
//         return '⏳ في انتظار خصم...';
//       } else {
//         return '⏳ في انتظار $opponentsNeeded خصوم...';
//       }
//     }
//   }
//
//   String _getLocalStatusMessage(int opponentsFound, int opponentsNeeded) {
//     if (opponentsFound >= opponentsNeeded) {
//       return '🎉 تم العثور على جميع الخصوم!';
//     } else if (opponentsFound > 0) {
//       if (opponentsNeeded == 1) {
//         return '✅ وجدنا خصماً محلياً...';
//       } else {
//         return '🔍 وجدنا $opponentsFound من أصل $opponentsNeeded خصوم محليين...';
//       }
//     } else {
//       if (opponentsNeeded == 1) {
//         return '🔍 جاري البحث عن خصم محلي...';
//       } else {
//         return '🔍 جاري البحث عن $opponentsNeeded خصوم محليين...';
//       }
//     }
//   }
//
//   Map<String, dynamic> _createPlayerData(String userId, String userName, String gameMode) {
//     return {
//       'playerId': userId,
//       'playerName': userName,
//       'gameMode': gameMode,
//       'joinedAt': FieldValue.serverTimestamp(),
//       'status': 'searching',
//       'lastActive': FieldValue.serverTimestamp(),
//       'searchTime': DateTime.now().millisecondsSinceEpoch,
//       'isRealPlayer': true,
//       'matchType': 'player_vs_player',
//       'appVersion': '1.0.0',
//       'deviceId': Platform.operatingSystem,
//       'deviceTimestamp': DateTime.now().millisecondsSinceEpoch,
//       'isGuest': _isGuestMode,
//     };
//   }
//
//   Future<void> _cleanupPreviousEntries(String userId) async {
//     if (!_useFirebase) return;
//
//     try {
//       final query = await _firestore
//           .collection('matchmaking_queue')
//           .where('playerId', isEqualTo: userId)
//           .where('status', whereIn: ['searching', 'matched'])
//           .get();
//
//       if (query.docs.isNotEmpty) {
//         final batch = _firestore.batch();
//         for (var doc in query.docs) {
//           batch.delete(doc.reference);
//         }
//         await batch.commit();
//         print('🧹 تم تنظيف ${query.docs.length} مدخلات سابقة');
//       }
//     } catch (e) {
//       print('⚠️ خطأ في تنظيف المدخلات السابقة: $e');
//     }
//   }
//
//   List<Map<String, dynamic>> _createRealPlayersList(
//       String userId,
//       String userName,
//       List<Map<String, dynamic>> opponents,
//       ) {
//     final players = <Map<String, dynamic>>[
//       {
//         'playerId': userId,
//         'playerName': userName,
//         'isReady': false,
//         'character': null,
//         'joinedAt': DateTime.now().toIso8601String(),
//         'readyAt': null,
//         'isRealPlayer': true,
//         'playerType': 'real',
//         'isLocal': false, // ✅ تأكد أنها false
//       }
//     ];
//
//     for (var opponent in opponents) {
//       players.add({
//         'playerId': opponent['playerId'],
//         'playerName': opponent['playerName'] ?? 'الخصم',
//         'isReady': false,
//         'character': null,
//         'joinedAt': DateTime.now().toIso8601String(),
//         'readyAt': null,
//         'isRealPlayer': true,
//         'playerType': 'real',
//         'isLocal': false, // ✅ تأكد أنها false
//       });
//     }
//
//     return players;
//   }
//
//   Map<String, dynamic> _createRealPlayersByIdMap(
//       String userId,
//       String userName,
//       List<Map<String, dynamic>> opponents,
//       ) {
//     final map = <String, dynamic>{};
//
//     map[userId] = {
//       'playerId': userId,
//       'playerName': userName,
//       'isReady': false,
//       'character': null,
//       'joinedAt': DateTime.now().toIso8601String(),
//       'readyAt': null,
//       'isRealPlayer': true,
//       'isLocal': true,
//     };
//
//     for (var opponent in opponents) {
//       final playerId = opponent['playerId'] as String;
//       map[playerId] = {
//         'playerId': playerId,
//         'playerName': opponent['playerName'] ?? 'الخصم',
//         'isReady': false,
//         'character': null,
//         'joinedAt': DateTime.now().toIso8601String(),
//         'readyAt': null,
//         'isRealPlayer': true,
//         'isLocal': false,
//       };
//     }
//
//     return map;
//   }
//
//   Map<String, dynamic> _createLocalMatchData(String gameMode) {
//     final matchId = 'local_match_${DateTime.now().millisecondsSinceEpoch}';
//     final playersNeeded = _getPlayersNeeded(gameMode);
//     final opponentsNeeded = _getOpponentsNeeded(gameMode);
//
//     // ✅ إنشاء اللاعب الحالي
//     final players = <Map<String, dynamic>>[
//       {
//         'playerId': currentUserId,
//         'playerName': _getPlayerName(),
//         'isReady': false,
//         'character': null,
//         'joinedAt': DateTime.now().toIso8601String(),
//         'readyAt': null,
//         'isRealPlayer': true,
//         'playerType': 'real',
//         'isLocal': true,
//       }
//     ];
//
//     // ✅ إنشاء الخصوم الافتراضيين
//     for (int i = 1; i <= opponentsNeeded; i++) {
//       players.add({
//         'playerId': 'local_opponent_${DateTime.now().millisecondsSinceEpoch}_$i',
//         'playerName': 'الخصم $i',
//         'isReady': false,
//         'character': null,
//         'joinedAt': DateTime.now().toIso8601String(),
//         'readyAt': null,
//         'isRealPlayer': true,
//         'playerType': 'real',
//         'isLocal': false,
//       });
//     }
//
//     // ✅ إنشاء خريطة اللاعبين
//     final playersById = <String, dynamic>{};
//     for (var player in players) {
//       playersById[player['playerId']] = player;
//     }
//
//     return {
//       'matchId': matchId,
//       'gameMode': gameMode,
//       'status': 'character_selection',
//       'phase': 'character_selection',
//       'createdAt': DateTime.now().toIso8601String(),
//       'updatedAt': DateTime.now().toIso8601String(),
//       'maxPlayers': playersNeeded,
//       'players': players,
//       'playersById': playersById,
//       'matchType': 'player_vs_player',
//       'isRealMatch': true,
//       'totalPlayers': players.length,
//       'matchCreationTime': DateTime.now().toIso8601String(),
//       'appVersion': '1.0.0',
//       'isLocalMatch': true,
//     };
//   }
//
//   Future<void> _updatePlayersMatchStatus(
//       List<Map<String, dynamic>> opponents,
//       String matchId,
//       ) async {
//     if (!_useFirebase) return;
//
//     try {
//       final batch = _firestore.batch();
//       final updateTime = FieldValue.serverTimestamp();
//
//       if (_currentQueueId != null) {
//         final currentDoc = _firestore.collection('matchmaking_queue').doc(_currentQueueId);
//         batch.update(currentDoc, {
//           'status': 'matched',
//           'matchId': matchId,
//           'matchedAt': updateTime,
//           'updatedAt': updateTime,
//           'matchFound': true,
//         });
//       }
//
//       for (var opponent in opponents) {
//         final playerDocId = opponent['docId'] as String?;
//         if (playerDocId != null) {
//           final playerDoc = _firestore.collection('matchmaking_queue').doc(playerDocId);
//           batch.update(playerDoc, {
//             'status': 'matched',
//             'matchId': matchId,
//             'matchedAt': updateTime,
//             'updatedAt': updateTime,
//             'matchFound': true,
//           });
//         }
//       }
//
//       await batch.commit();
//       print('✅ تم تحديث حالة ${opponents.length + 1} لاعب');
//
//     } catch (e) {
//       print('⚠️ خطأ في تحديث حالة اللاعبين: $e');
//     }
//   }
//
//   String _getPlayerName() {
//     try {
//       if (_auth.currentUser?.displayName != null &&
//           _auth.currentUser!.displayName!.isNotEmpty) {
//         return _auth.currentUser!.displayName!;
//       }
//       if (_localUserName.isNotEmpty) {
//         return _localUserName;
//       }
//       return 'لاعب_${Random().nextInt(1000)}';
//     } catch (e) {
//       return 'اللاعب';
//     }
//   }
//
//   bool get mounted => !_isDisposed;
//
//   // 📡 الاستماع لتحديثات المباراة
//   StreamSubscription listenToMatchUpdates(
//       String matchId,
//       Function(Map<String, dynamic>) onUpdate,
//       ) {
//     return _firestore
//         .collection('real_matches')
//         .doc(matchId)
//         .snapshots()
//         .listen((snapshot) {
//       if (snapshot.exists) {
//         final data = snapshot.data() as Map<String, dynamic>;
//         if (mounted) {
//           onUpdate(data);
//         }
//       }
//     }, onError: (error) {
//       print('❌ خطأ في تحديثات المباراة: $error');
//     });
//   }
//
//   // ✅ تحديث حالة الاستعداد
//   Future<void> updateReadyStatus(bool isReady, String characterId) async {
//     if (_currentMatchId == null) return;
//
//     try {
//       await _firestore
//           .collection('real_matches')
//           .doc(_currentMatchId)
//           .update({
//         'playersById.${currentUserId}.isReady': isReady,
//         'playersById.${currentUserId}.character': characterId,
//         'playersById.${currentUserId}.readyAt': DateTime.now().toIso8601String(),
//         'updatedAt': DateTime.now().toIso8601String(),
//       });
//
//       print('✅ تم تحديث حالة الجاهزية: $isReady');
//     } catch (e) {
//       print('❌ خطأ في تحديث حالة الجاهزية: $e');
//     }
//   }
//
//   // 🔍 الحصول على معلومات المباراة
//   Future<Map<String, dynamic>?> getCurrentMatch() async {
//     if (_currentMatchId == null) return null;
//
//     try {
//       final doc = await _firestore
//           .collection('real_matches')
//           .doc(_currentMatchId)
//           .get();
//
//       if (doc.exists) {
//         return doc.data() as Map<String, dynamic>;
//       }
//     } catch (e) {
//       print('❌ خطأ في الحصول على المباراة: $e');
//     }
//
//     return null;
//   }
//
//   // 🧹 تنظيف بيئة الاختبار
//   static Future<void> cleanupTestEnvironment() async {
//     try {
//       print('🧹 تنظيف بيئة الاختبار...');
//
//       final queueQuery = await _firestore
//           .collection('matchmaking_queue')
//           .get();
//
//       if (queueQuery.docs.isNotEmpty) {
//         final batch = _firestore.batch();
//         for (var doc in queueQuery.docs) {
//           batch.delete(doc.reference);
//         }
//         await batch.commit();
//         print('✅ تم تنظيف ${queueQuery.docs.length} من قوائم الانتظار');
//       }
//
//       final oneHourAgo = DateTime.now().subtract(Duration(hours: 1));
//       final matchesQuery = await _firestore
//           .collection('real_matches')
//           .where('createdAt', isLessThan: oneHourAgo.toIso8601String())
//           .get();
//
//       if (matchesQuery.docs.isNotEmpty) {
//         final batch = _firestore.batch();
//         for (var doc in matchesQuery.docs) {
//           batch.delete(doc.reference);
//         }
//         await batch.commit();
//         print('✅ تم تنظيف ${matchesQuery.docs.length} من المباريات القديمة');
//       }
//
//     } catch (e) {
//       print('⚠️ خطأ في تنظيف بيئة الاختبار: $e');
//     }
//   }
//
//   void close() {
//     _cleanup();
//   }
// }