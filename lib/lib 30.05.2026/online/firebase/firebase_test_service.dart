// // lib/online/services/firebase_test_service.dart
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class FirebaseTestService {
//   static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   // ✅ اختبار إنشاء طلب صداقة
//   static Future<void> testFriendRequest() async {
//     try {
//       await _firestore.collection('friend_requests').doc('test1_test2').set({
//         'fromUserId': 'test_user_1',
//         'fromUserName': 'أحمد',
//         'toUserId': 'test_user_2',
//         'status': 'pending',
//         'sentAt': FieldValue.serverTimestamp(),
//       });
//       print('✅ تم اختبار طلب الصداقة بنجاح');
//     } catch (e) {
//       print('❌ فشل اختبار طلب الصداقة: $e');
//     }
//   }
//
//   // ✅ اختبار إنشاء غرفة
//   static Future<void> testRoomCreation() async {
//     try {
//       await _firestore.collection('global_rooms').doc('test_room_123').set({
//         'roomId': 'test_room_123',
//         'hostId': 'test_user_1',
//         'hostName': 'أحمد',
//         'roomName': 'غرفة اختبار',
//         'gameMode': '1v1',
//         'maxPlayers': 2,
//         'currentPlayers': 1,
//         'status': 'waiting',
//         'createdAt': FieldValue.serverTimestamp(),
//         'lastActivity': FieldValue.serverTimestamp(),
//       });
//       print('✅ تم اختبار إنشاء الغرفة بنجاح');
//     } catch (e) {
//       print('❌ فشل اختبار إنشاء الغرفة: $e');
//     }
//   }
// }