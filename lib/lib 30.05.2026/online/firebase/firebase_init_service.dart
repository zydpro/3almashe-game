// lib/online/services/firebase_init_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseInitService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ✅ تهيئة بيانات المستخدم عند التسجيل الأول
  static Future<void> initializeUserData(User user) async {
    try {
      final userData = {
        'uid': user.uid,
        'displayName': user.displayName ?? 'لاعب',
        'email': user.email,
        'photoURL': user.photoURL,
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'gameStats': {
          'highScore': 0,
          'currentLevel': 1,
          'coins': 0,
          'gamesPlayed': 0,
          'totalPlayTime': 0,
        },
        'settings': {
          'language': 'ar',
          'soundEnabled': true,
          'musicEnabled': true,
        }
      };

      await _firestore.collection('users').doc(user.uid).set(userData);
      print('✅ تم تهيئة بيانات المستخدم في Firebase: ${user.uid}');
    } catch (e) {
      print('❌ خطأ في تهيئة بيانات المستخدم: $e');
    }
  }

  // ✅ إنشاء بيانات تجريبية للاختبار
  static Future<void> createTestData() async {
    try {
      // مستخدم تجريبي 1
      await _firestore.collection('users').doc('test_user_1').set({
        'uid': 'test_user_1',
        'displayName': 'أحمد',
        'email': 'ahmed@test.com',
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
        'gameStats': {
          'highScore': 1500,
          'currentLevel': 3,
          'coins': 200,
        },
      });

      // مستخدم تجريبي 2
      await _firestore.collection('users').doc('test_user_2').set({
        'uid': 'test_user_2',
        'displayName': 'محمد',
        'email': 'mohamed@test.com',
        'isOnline': false,
        'lastSeen': FieldValue.serverTimestamp(),
        'gameStats': {
          'highScore': 800,
          'currentLevel': 2,
          'coins': 150,
        },
      });

      print('✅ تم إنشاء البيانات التجريبية');
    } catch (e) {
      print('❌ خطأ في إنشاء البيانات التجريبية: $e');
    }
  }

  // ✅ التحقق من اتصال Firebase
  static Future<bool> checkConnection() async {
    try {
      await _firestore.collection('connection_test').doc('test').get();
      return true;
    } catch (e) {
      print('❌ خطأ في الاتصال بـ Firebase: $e');
      return false;
    }
  }

  // ✅ تنظيف البيانات القديمة (للتطوير)
  static Future<void> cleanupOldData() async {
    try {
      // حذف الغرف القديمة
      final oldRooms = await _firestore
          .collection('global_rooms')
          .where('lastActivity', isLessThan:
      Timestamp.fromDate(DateTime.now().subtract(Duration(hours: 1))))
          .get();

      for (var doc in oldRooms.docs) {
        await doc.reference.delete();
      }

      print('✅ تم تنظيف البيانات القديمة');
    } catch (e) {
      print('❌ خطأ في تنظيف البيانات: $e');
    }
  }
}