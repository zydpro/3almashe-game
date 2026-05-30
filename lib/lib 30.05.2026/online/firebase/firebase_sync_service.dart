// lib/online/services/firebase_sync_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseSyncService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ✅ دالة تنظيف عامة
  static Future<void> cleanupOldData() async {
    try {
      print('🧹 بدء تنظيف البيانات القديمة...');

      // حذف المستخدمين التجريبيين
      await _firestore.collection('users').doc('test_user_1').delete().catchError((e) {});
      await _firestore.collection('users').doc('test_user_2').delete().catchError((e) {});
      await _firestore.collection('users').doc('test_user_3').delete().catchError((e) {});

      // تنظيف الغرف
      final oldRooms = await _firestore.collection('global_rooms').get();
      for (var doc in oldRooms.docs) {
        await doc.reference.delete();
      }

      // تنظيف طلبات الصداقة
      final oldRequests = await _firestore.collection('friend_requests').get();
      for (var doc in oldRequests.docs) {
        await doc.reference.delete();
      }

      // تنظيف الدعوات
      final oldInvitations = await _firestore.collection('game_invitations').get();
      for (var doc in oldInvitations.docs) {
        await doc.reference.delete();
      }

      print('✅ تم تنظيف جميع البيانات القديمة');
    } catch (e) {
      print('❌ خطأ في تنظيف البيانات: $e');
    }
  }

  // ✅ إضافة مستخدمين تجريبيين مع بيانات كاملة
  static Future<void> addCompleteTestUsers() async {
    try {
      // تنظيف البيانات القديمة أولاً
      await cleanupOldData(); // ✅ استدعاء الدالة العامة

      // المستخدم 1 - بيانات كاملة
      await _firestore.collection('users').doc('test_user_1').set({
        'uid': 'test_user_1',
        'displayName': 'أحمد المحارب',
        'email': 'ahmed@almashe.com',
        'photoURL': '',
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'gameStats': {
          'highScore': 1500,
          'currentLevel': 3,
          'coins': 200,
          'gamesPlayed': 15,
          'totalPlayTime': 3600,
          'enemiesDefeated': 120,
          'bossesDefeated': 5,
          'packagesThrown': 45,
        },
        'characters': {
          'ownedCharacters': [1, 2, 3],
          'selectedCharacter': 1,
        },
        'settings': {
          'soundEnabled': true,
          'musicEnabled': true,
          'vibrationEnabled': true,
          'notificationsEnabled': true,
          'language': 'ar',
        },
        'achievements': {
          'firstLogin': true,
          'firstGamePlayed': true,
          'firstBossDefeated': true,
          'allCharactersUnlocked': false,
        },
        'statistics': {
          'totalSessions': 20,
          'averageScore': 750,
          'favoriteCharacter': 1,
          'playStreak': 3,
        }
      });

      // المستخدم 2 - بيانات كاملة
      await _firestore.collection('users').doc('test_user_2').set({
        'uid': 'test_user_2',
        'displayName': 'سارة الساحرة',
        'email': 'sara@almashe.com',
        'photoURL': '',
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'gameStats': {
          'highScore': 2200,
          'currentLevel': 5,
          'coins': 350,
          'gamesPlayed': 25,
          'totalPlayTime': 5200,
          'enemiesDefeated': 180,
          'bossesDefeated': 8,
          'packagesThrown': 65,
        },
        'characters': {
          'ownedCharacters': [1, 2, 3, 4],
          'selectedCharacter': 3,
        },
        'settings': {
          'soundEnabled': true,
          'musicEnabled': false,
          'vibrationEnabled': true,
          'notificationsEnabled': true,
          'language': 'ar',
        },
        'achievements': {
          'firstLogin': true,
          'firstGamePlayed': true,
          'firstBossDefeated': true,
          'allCharactersUnlocked': false,
        },
        'statistics': {
          'totalSessions': 30,
          'averageScore': 880,
          'favoriteCharacter': 3,
          'playStreak': 5,
        }
      });

      // المستخدم 3 - بيانات كاملة
      await _firestore.collection('users').doc('test_user_3').set({
        'uid': 'test_user_3',
        'displayName': 'محمد المقاتل',
        'email': 'mohamed@almashe.com',
        'photoURL': '',
        'isOnline': false,
        'lastSeen': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'gameStats': {
          'highScore': 800,
          'currentLevel': 2,
          'coins': 150,
          'gamesPlayed': 8,
          'totalPlayTime': 1800,
          'enemiesDefeated': 60,
          'bossesDefeated': 1,
          'packagesThrown': 25,
        },
        'characters': {
          'ownedCharacters': [1, 2],
          'selectedCharacter': 2,
        },
        'settings': {
          'soundEnabled': true,
          'musicEnabled': true,
          'vibrationEnabled': false,
          'notificationsEnabled': false,
          'language': 'ar',
        },
        'achievements': {
          'firstLogin': true,
          'firstGamePlayed': true,
          'firstBossDefeated': false,
          'allCharactersUnlocked': false,
        },
        'statistics': {
          'totalSessions': 10,
          'averageScore': 400,
          'favoriteCharacter': 2,
          'playStreak': 1,
        }
      });

      print('✅ تم إضافة المستخدمين التجريبيين ببيانات كاملة');
    } catch (e) {
      print('❌ خطأ في إضافة المستخدمين التجريبيين: $e');
    }
  }

  // ✅ إنشاء غرف تجريبية
  static Future<void> addTestRooms() async {
    try {
      // غرفة 1v1
      await _firestore.collection('global_rooms').doc('room_1v1_test').set({
        'roomId': 'room_1v1_test',
        'hostId': 'test_user_1',
        'hostName': 'أحمد المحارب',
        'roomName': 'تحدي 1v1 - ادخل وشوف مين الأقوى! 💪',
        'gameMode': '1v1',
        'maxPlayers': 2,
        'currentPlayers': 1,
        'status': 'waiting',
        'isPrivate': false,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActivity': FieldValue.serverTimestamp(),
        'players': [
          {
            'userId': 'test_user_1',
            'playerName': 'أحمد المحارب',
            'username': 'ahmed_warrior',
            'character': {
              'id': 1,
              'name': 'عالماشي',
              'nameEn': 'Almashe',
              'type': 'سرعة',
              'imagePath': 'assets/images/characters/almashe/almashe_1.png',
              'primaryWeapon': 'sword',
              'secondaryWeapon': 'bow',
              'specialAbility': 'رمي الصناديق',
            },
            'isHost': true,
            'isReady': true,
            'publicIP': '192.168.1.100',
            'joinedAt': FieldValue.serverTimestamp(),
          }
        ],
      });

      // غرفة 2v2
      await _firestore.collection('global_rooms').doc('room_2v2_test').set({
        'roomId': 'room_2v2_test',
        'hostId': 'test_user_2',
        'hostName': 'سارة الساحرة',
        'roomName': 'فريق 2v2 - تعالوا نلعب سوا! 👥',
        'gameMode': '2v2',
        'maxPlayers': 4,
        'currentPlayers': 2,
        'status': 'waiting',
        'isPrivate': false,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActivity': FieldValue.serverTimestamp(),
        'players': [
          {
            'userId': 'test_user_2',
            'playerName': 'سارة الساحرة',
            'username': 'sara_sorceress',
            'character': {
              'id': 3,
              'name': 'ساحرة',
              'nameEn': 'Sorceress',
              'type': 'سحر',
              'imagePath': 'assets/images/characters/sorceress/sorceress_1.png',
              'primaryWeapon': 'staff',
              'secondaryWeapon': 'dagger',
              'specialAbility': 'سحر الثلج',
            },
            'isHost': true,
            'isReady': true,
            'publicIP': '192.168.1.101',
            'joinedAt': FieldValue.serverTimestamp(),
          },
          {
            'userId': 'test_user_3',
            'playerName': 'محمد المقاتل',
            'character': {
              'id': 2,
              'name': 'محارب',
              'nameEn': 'Warrior',
              'type': 'قوة',
              'imagePath': 'assets/images/characters/warrior/warrior_1.png',
              'primaryWeapon': 'axe',
              'secondaryWeapon': 'hammer',
              'specialAbility': 'ضربة قوية',
            },
            'isHost': false,
            'isReady': true,
            'publicIP': '192.168.1.102',
            'joinedAt': FieldValue.serverTimestamp(),
          }
        ],
      });

      print('✅ تم إضافة الغرف التجريبية');
    } catch (e) {
      print('❌ خطأ في إضافة الغرف: $e');
    }
  }

  // ✅ تهيئة كل شيء دفعة واحدة
  static Future<void> initializeCompleteTestEnvironment() async {
    try {
      print('🎮 بدء تهيئة بيئة الاختبار الكاملة...');

      await addCompleteTestUsers();
      await addTestRooms();

      print('🎉 تم تهيئة بيئة الاختبار بنجاح!');
      print('👤 المستخدمون: أحمد, سارة, محمد');
      print('🏠 الغرف: 1v1, 2v2');
    } catch (e) {
      print('❌ خطأ في تهيئة بيئة الاختبار: $e');
    }
  }
}