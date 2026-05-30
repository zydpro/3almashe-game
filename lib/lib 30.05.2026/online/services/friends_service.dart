// lib/online/services/friends_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ✅ البحث عن لاعب بالاسم أو الإيميل
  static Future<List<Map<String, dynamic>>> searchPlayers(String query) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      final usersRef = _firestore.collection('users');

      // ✅ البحث بالاسم
      final nameQuery = await usersRef
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThanOrEqualTo: query + '\uf8ff')
          .limit(10)
          .get();

      // ✅ البحث بالإيميل
      final emailQuery = await usersRef
          .where('email', isGreaterThanOrEqualTo: query)
          .where('email', isLessThanOrEqualTo: query + '\uf8ff')
          .limit(10)
          .get();

      // ✅ البحث بـ Username (جديد)
      final usernameQuery = await usersRef
          .where('username', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('username', isLessThanOrEqualTo: query.toLowerCase() + '\uf8ff')
          .limit(10)
          .get();

      final results = <Map<String, dynamic>>[];
      final addedIds = <String>{};

      // دمج النتائج مع إزالة التكرارات
      for (var doc in [...nameQuery.docs, ...emailQuery.docs, ...usernameQuery.docs]) {
        if (doc.id != currentUser.uid && !addedIds.contains(doc.id)) {
          final data = doc.data();
          results.add({
            'userId': doc.id,
            'displayName': data['displayName'] ?? 'لاعب',
            'username': data['username'] ?? '', // ✅ إضافة username للنتائج
            'email': data['email'] ?? '',
            'photoURL': data['photoURL'],
            'isOnline': data['isOnline'] ?? false,
            'lastSeen': data['lastSeen'],
            'gameStats': data['gameStats'] ?? {},
          });
          addedIds.add(doc.id);
        }
      }

      return results;
    } catch (e) {
      print('❌ خطأ في البحث عن لاعبين: $e');
      return [];
    }
  }

  // ✅ إرسال طلب صداقة
  static Future<bool> sendFriendRequest(String targetUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final requestData = {
        'fromUserId': currentUser.uid,
        'fromUserName': currentUser.displayName ?? 'لاعب',
        'fromUserPhoto': currentUser.photoURL,
        'toUserId': targetUserId,
        'status': 'pending', // pending, accepted, rejected
        'sentAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('friend_requests')
          .doc('${currentUser.uid}_$targetUserId')
          .set(requestData);

      // إرسال إشعار للمستخدم المستهدف
      await _sendFriendNotification(targetUserId, currentUser.uid);

      return true;
    } catch (e) {
      print('❌ خطأ في إرسال طلب الصداقة: $e');
      return false;
    }
  }

  // ✅ قبول طلب صداقة
  static Future<bool> acceptFriendRequest(String requestId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // تحديث حالة الطلب
      await _firestore
          .collection('friend_requests')
          .doc(requestId)
          .update({'status': 'accepted', 'acceptedAt': FieldValue.serverTimestamp()});

      // إضافة إلى قائمة الأصدقاء لكلا الطرفين
      final requestDoc = await _firestore.collection('friend_requests').doc(requestId).get();
      final requestData = requestDoc.data()!;

      await _addToFriendsList(currentUser.uid, requestData['fromUserId']);
      await _addToFriendsList(requestData['fromUserId'], currentUser.uid);

      return true;
    } catch (e) {
      print('❌ خطأ في قبول طلب الصداقة: $e');
      return false;
    }
  }

  // ✅ رفض طلب صداقة
  static Future<bool> rejectFriendRequest(String requestId) async {
    try {
      await _firestore
          .collection('friend_requests')
          .doc(requestId)
          .update({'status': 'rejected', 'rejectedAt': FieldValue.serverTimestamp()});
      return true;
    } catch (e) {
      print('❌ خطأ في رفض طلب الصداقة: $e');
      return false;
    }
  }

  // ✅ الحصول على قائمة الأصدقاء
  static Stream<List<Map<String, dynamic>>> getFriendsStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('friends')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'userId': doc.id,
        'displayName': data['displayName'],
        'photoURL': data['photoURL'],
        'isOnline': data['isOnline'] ?? false,
        'lastSeen': data['lastSeen'],
        'gameStats': data['gameStats'] ?? {},
        'friendsSince': data['friendsSince'],
      };
    }).toList());
  }

  // ✅ الحصول على طلبات الصداقة الواردة
  static Stream<List<Map<String, dynamic>>> getFriendRequestsStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _firestore
        .collection('friend_requests')
        .where('toUserId', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'requestId': doc.id,
        'fromUserId': data['fromUserId'],
        'fromUserName': data['fromUserName'],
        'fromUserPhoto': data['fromUserPhoto'],
        'sentAt': data['sentAt'],
      };
    }).toList());
  }

  // ✅ إزالة صديق
  static Future<bool> removeFriend(String friendId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // إزالة من قائمة الأصدقاء لكلا الطرفين
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('friends')
          .doc(friendId)
          .delete();

      await _firestore
          .collection('users')
          .doc(friendId)
          .collection('friends')
          .doc(currentUser.uid)
          .delete();

      return true;
    } catch (e) {
      print('❌ خطأ في إزالة الصديق: $e');
      return false;
    }
  }

  // ✅ دوال مساعدة خاصة
  static Future<void> _addToFriendsList(String userId, String friendId) async {
    final friendData = await _firestore.collection('users').doc(friendId).get();
    final friendUserData = friendData.data()!;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('friends')
        .doc(friendId)
        .set({
      'displayName': friendUserData['displayName'] ?? 'لاعب',
      'photoURL': friendUserData['photoURL'],
      'isOnline': friendUserData['isOnline'] ?? false,
      'gameStats': friendUserData['gameStats'] ?? {},
      'friendsSince': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> _sendFriendNotification(String targetUserId, String fromUserId) async {
    // يمكن إضافة إشعارات push هنا لاحقاً
    print('📨 إرسال إشعار صداقة إلى: $targetUserId');
  }

  // ✅ تحديث حالة المستخدم (Online/Offline)
  static Future<void> updateUserStatus(bool isOnline) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      await _firestore.collection('users').doc(currentUser.uid).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ خطأ في تحديث حالة المستخدم: $e');
    }
  }
}