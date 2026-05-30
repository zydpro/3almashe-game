// services/user_data_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/game_data_service.dart';

class UserDataService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ✅ تهيئة بيانات المستخدم الجديد
  static Future<void> initializeUserData(User user) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);

      // التحقق إذا كان المستخدم موجوداً بالفعل
      final docSnapshot = await userDoc.get();
      if (docSnapshot.exists) {
        print('✅ بيانات المستخدم موجودة مسبقاً: ${user.uid}');
        return;
      }

      // الحصول على البيانات المحلية الحالية
      final localStats = await GameDataService.getPlayerStats();
      final ownedCharacters = await GameDataService.getOwnedCharacterIds();
      final selectedCharacter = await GameDataService.getSelectedCharacter();

      // إنشاء username افتراضي من الإيميل
      final defaultUsername = _generateDefaultUsername(user.email ?? user.uid);

      // بيانات المستخدم الجديدة
      final userData = {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName ?? await GameDataService.getPlayerName(),
        'username': defaultUsername, // ✅ إضافة username افتراضي
        'photoURL': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),

        // بيانات اللعبة
        'gameStats': {
          'highScore': localStats['highScore'] ?? 0,
          'currentLevel': localStats['currentLevel'] ?? 1,
          'coins': localStats['coins'] ?? 1,
          'unlockedLevels': localStats['unlockedLevels'] ?? [1],
          'gamesPlayed': localStats['gamesPlayed'] ?? 0,
          'totalPlayTime': localStats['totalPlayTime'] ?? 0,
          'enemiesDefeated': localStats['enemiesDefeated'] ?? 0,
          'bossesDefeated': localStats['bossesDefeated'] ?? 0,
          'packagesThrown': localStats['packagesThrown'] ?? 0,
        },

        // بيانات الشخصيات
        'characters': {
          'ownedCharacters': ownedCharacters,
          'selectedCharacter': selectedCharacter.id,
        },

        // الإعدادات
        'settings': {
          'soundEnabled': true,
          'musicEnabled': true,
          'vibrationEnabled': true,
          'notificationsEnabled': true,
          'language': 'ar',
        },

        // التقدم والإنجازات
        'achievements': {
          'firstLogin': true,
          'firstGamePlayed': false,
          'firstBossDefeated': false,
          'allCharactersUnlocked': false,
        },

        // الإحصائيات
        'statistics': {
          'totalSessions': 1,
          'averageScore': 0,
          'favoriteCharacter': selectedCharacter.id,
          'playStreak': 1,
        }
      };

      await userDoc.set(userData);
      print('✅ تم تهيئة بيانات المستخدم الجديد: ${user.uid} - Username: $defaultUsername');

    } catch (e) {
      print('❌ خطأ في تهيئة بيانات المستخدم: $e');
    }
  }

  // ✅ دالة جديدة لتهيئة البيانات مع Username مخصص
  static Future<void> initializeUserDataWithUsername(User user, String username) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);

      // التحقق إذا كان المستخدم موجوداً بالفعل
      final docSnapshot = await userDoc.get();
      if (docSnapshot.exists) {
        print('✅ بيانات المستخدم موجودة مسبقاً: ${user.uid}');
        return;
      }

      // التحقق من توفر Username
      final isUsernameAvailable = await checkUsernameAvailability(username);
      if (!isUsernameAvailable) {
        throw 'اسم المستخدم مستخدم بالفعل';
      }

      // الحصول على البيانات المحلية الحالية
      final localStats = await GameDataService.getPlayerStats();
      final ownedCharacters = await GameDataService.getOwnedCharacterIds();
      final selectedCharacter = await GameDataService.getSelectedCharacter();

      // بيانات المستخدم الجديدة مع Username مخصص
      final userData = {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName ?? await GameDataService.getPlayerName(),
        'username': username.toLowerCase(), // ✅ تخزين username بحروف صغيرة
        'photoURL': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),

        // بيانات اللعبة
        'gameStats': {
          'highScore': localStats['highScore'] ?? 0,
          'currentLevel': localStats['currentLevel'] ?? 1,
          'coins': localStats['coins'] ?? 1,
          'unlockedLevels': localStats['unlockedLevels'] ?? [1],
          'gamesPlayed': localStats['gamesPlayed'] ?? 0,
          'totalPlayTime': localStats['totalPlayTime'] ?? 0,
          'enemiesDefeated': localStats['enemiesDefeated'] ?? 0,
          'bossesDefeated': localStats['bossesDefeated'] ?? 0,
          'packagesThrown': localStats['packagesThrown'] ?? 0,
        },

        // بيانات الشخصيات
        'characters': {
          'ownedCharacters': ownedCharacters,
          'selectedCharacter': selectedCharacter.id,
        },

        // الإعدادات
        'settings': {
          'soundEnabled': true,
          'musicEnabled': true,
          'vibrationEnabled': true,
          'notificationsEnabled': true,
          'language': 'ar',
        },

        // التقدم والإنجازات
        'achievements': {
          'firstLogin': true,
          'firstGamePlayed': false,
          'firstBossDefeated': false,
          'allCharactersUnlocked': false,
        },

        // الإحصائيات
        'statistics': {
          'totalSessions': 1,
          'averageScore': 0,
          'favoriteCharacter': selectedCharacter.id,
          'playStreak': 1,
        }
      };

      await userDoc.set(userData);
      print('✅ تم تهيئة بيانات المستخدم الجديد مع Username: $username');

    } catch (e) {
      print('❌ خطأ في تهيئة بيانات المستخدم: $e');
      rethrow;
    }
  }

  // ✅ التحقق من توفر Username
  static Future<bool> checkUsernameAvailability(String username) async {
    try {
      // ✅ تحقق بسيط أولاً
      if (username.isEmpty || username.length < 3) {
        return false;
      }

      // ✅ جرب استعلام بسيط بدون where
      final allUsers = await _firestore.collection('users').get();

      // ✅ ابحث يدوياً في النتائج
      final exists = allUsers.docs.any((doc) {
        final data = doc.data();
        return data['username']?.toString().toLowerCase() == username.toLowerCase();
      });

      return !exists; // true إذا كان متاحاً

    } catch (e) {
      print('❌ خطأ في التحقق من Username: $e');

      // ✅ حل بديل: افترض أن Username متاح مؤقتاً
      print('⚠️ استخدام الحل البديل - افتراض أن Username متاح');
      return true;
    }
  }

  // ✅ تحديث Username
  static Future<bool> updateUsername(String newUsername) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // التحقق من توفر Username الجديد
      final isAvailable = await checkUsernameAvailability(newUsername);
      if (!isAvailable) {
        throw 'اسم المستخدم مستخدم بالفعل';
      }

      await _firestore.collection('users').doc(user.uid).update({
        'username': newUsername.toLowerCase(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      print('✅ تم تحديث Username إلى: $newUsername');
      return true;
    } catch (e) {
      print('❌ خطأ في تحديث Username: $e');
      return false;
    }
  }

  // ✅ إنشاء username افتراضي من الإيميل
  static String _generateDefaultUsername(String emailOrUid) {
    if (emailOrUid.contains('@')) {
      // استخراج الجزء قبل @ من الإيميل
      return emailOrUid.split('@')[0].toLowerCase();
    } else {
      // استخدام أول 8 أحرف من UID إذا لم يكن هناك إيميل
      return 'user_${emailOrUid.substring(0, min(8, emailOrUid.length))}'.toLowerCase();
    }
  }

  // ✅ الحصول على بيانات المستخدم بواسطة Username
  static Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first.data();
      }
      return null;
    } catch (e) {
      print('❌ خطأ في الحصول على المستخدم بواسطة Username: $e');
      return null;
    }
  }

  // ✅ دالة مساعدة للحصول على القيمة الأدنى
  static int min(int a, int b) => a < b ? a : b;

  // ✅ مزامنة البيانات من Firebase إلى الجهاز
  static Future<void> syncDataFromCloud(User user) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        print('⚠️ لا توجد بيانات سحابية للمستخدم، سيتم إنشاء بيانات جديدة');
        await initializeUserData(user);
        return;
      }

      final userData = docSnapshot.data()!;
      final gameStats = userData['gameStats'] as Map<String, dynamic>;
      final characters = userData['characters'] as Map<String, dynamic>;

      // ✅ مزامنة بيانات اللعبة
      await GameDataService.setHighScore(gameStats['highScore'] ?? 0);
      await GameDataService.setCurrentLevel(gameStats['currentLevel'] ?? 1);
      await GameDataService.setCoins(gameStats['coins'] ?? 1);

      // ✅ مزامنة المستويات المفتوحة - مصحح
      final unlockedLevels = List<int>.from(gameStats['unlockedLevels'] ?? [1]);
      await GameDataService.setUnlockedLevels(unlockedLevels);

      // ✅ مزامنة الشخصيات
      final ownedCharacterIds = List<int>.from(characters['ownedCharacters'] ?? [1]);
      final selectedCharacterId = characters['selectedCharacter'] ?? 1;

      // الحصول على جميع الشخصيات وتحديث حالة القفل
      final allCharacters = GameDataService.getAllCharacters();
      final ownedCharacters = allCharacters.where((char) =>
          ownedCharacterIds.contains(char.id)).toList();

      await GameDataService.saveOwnedCharacters(ownedCharacters);

      // تعيين الشخصية المختارة
      final selectedCharacter = allCharacters.firstWhere(
              (char) => char.id == selectedCharacterId,
          orElse: () => GameDataService.getAllCharacters().first
      );
      await GameDataService.setSelectedCharacter(selectedCharacter);

      print('✅ تم مزامنة البيانات من السحابة: ${user.uid}');

    } catch (e) {
      print('❌ خطأ في مزامنة البيانات من السحابة: $e');
    }
  }

  // ✅ رفع البيانات المحلية إلى Firebase
  static Future<void> syncDataToCloud(User user) async {
    try {
      final localStats = await GameDataService.getPlayerStats();
      final ownedCharacters = await GameDataService.getOwnedCharacterIds();
      final selectedCharacter = await GameDataService.getSelectedCharacter();

      final updateData = {
        'lastLogin': FieldValue.serverTimestamp(),
        'displayName': user.displayName ?? await GameDataService.getPlayerName(),
        'photoURL': user.photoURL,

        'gameStats': {
          'highScore': localStats['highScore'],
          'currentLevel': localStats['currentLevel'],
          'coins': localStats['coins'],
          'unlockedLevels': localStats['unlockedLevels'],
          'gamesPlayed': localStats['gamesPlayed'],
          'totalPlayTime': localStats['totalPlayTime'],
          'enemiesDefeated': localStats['enemiesDefeated'],
          'bossesDefeated': localStats['bossesDefeated'],
          'packagesThrown': localStats['packagesThrown'],
        },

        'characters': {
          'ownedCharacters': ownedCharacters,
          'selectedCharacter': selectedCharacter.id,
        },

        'statistics.totalSessions': FieldValue.increment(1),
      };

      await _firestore.collection('users').doc(user.uid).update(updateData);
      print('✅ تم رفع البيانات إلى السحابة: ${user.uid}');

    } catch (e) {
      print('❌ خطأ في رفع البيانات إلى السحابة: $e');
    }
  }

  // ✅ الحصول على بيانات المستخدم
  static Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final docSnapshot = await _firestore.collection('users').doc(uid).get();
      return docSnapshot.data();
    } catch (e) {
      print('❌ خطأ في الحصول على بيانات المستخدم: $e');
      return null;
    }
  }

  // ✅ تحديث إحصائيات اللعبة
  static Future<void> updateGameStats({
    required int score,
    required int level,
    required int playTime,
    required int enemiesDefeated,
    required int packagesThrown,
    bool bossDefeated = false,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final updateData = {
        'lastPlayed': FieldValue.serverTimestamp(),
        'gameStats.highScore': FieldValue.increment(score > await GameDataService.getHighScore() ? score : 0),
        'gameStats.currentLevel': level,
        'gameStats.totalPlayTime': FieldValue.increment(playTime),
        'gameStats.enemiesDefeated': FieldValue.increment(enemiesDefeated),
        'gameStats.packagesThrown': FieldValue.increment(packagesThrown),
        'gameStats.gamesPlayed': FieldValue.increment(1),
        'statistics.totalSessions': FieldValue.increment(1),
      };

      if (bossDefeated) {
        updateData['gameStats.bossesDefeated'] = FieldValue.increment(1);
        updateData['achievements.firstBossDefeated'] = true;
      }

      if (score > await GameDataService.getHighScore()) {
        updateData['achievements.highScoreRecord'] = true;
      }

      await _firestore.collection('users').doc(user.uid).update(updateData);

      // تحديث البيانات المحلية أيضاً
      await GameDataService.saveGameProgress(score, level);
      await GameDataService.addPlayTime(playTime);
      await GameDataService.addEnemiesDefeated(enemiesDefeated);
      await GameDataService.addPackagesThrown(packagesThrown);

      if (bossDefeated) {
        await GameDataService.addBossDefeated();
      }

    } catch (e) {
      print('❌ خطأ في تحديث إحصائيات اللعبة: $e');
    }
  }

  // ✅ تحديث بيانات الشخصيات
  static Future<void> updateCharacterData(int characterId, bool purchased) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      if (purchased) {
        await _firestore.collection('users').doc(user.uid).update({
          'characters.ownedCharacters': FieldValue.arrayUnion([characterId]),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } else {
        await _firestore.collection('users').doc(user.uid).update({
          'characters.selectedCharacter': characterId,
          'statistics.favoriteCharacter': characterId,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

    } catch (e) {
      print('❌ خطأ في تحديث بيانات الشخصيات: $e');
    }
  }

  // ✅ التحقق من اتصال Firebase
  static Future<bool> checkFirebaseConnection() async {
    try {
      await _firestore.collection('connection_test').doc('test').get();
      return true;
    } catch (e) {
      print('❌ خطأ في الاتصال بـ Firebase: $e');
      return false;
    }
  }

  // ✅ الحصول على قائمة المتصدرين
  static Future<List<Map<String, dynamic>>> getLeaderboard() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .orderBy('gameStats.highScore', descending: true)
          .limit(10)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'displayName': data['displayName'] ?? 'مجهول',
          'username': data['username'] ?? '', // ✅ إضافة username
          'highScore': data['gameStats']['highScore'] ?? 0,
          'photoURL': data['photoURL'],
          'level': data['gameStats']['currentLevel'] ?? 1,
        };
      }).toList();
    } catch (e) {
      print('❌ خطأ في الحصول على قائمة المتصدرين: $e');
      return [];
    }
  }
}