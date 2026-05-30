import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'p2p_matchmaking_service.dart';
import '../models/online_character_system.dart';

class GlobalP2PService {
  final P2PMatchmakingService _localService = P2PMatchmakingService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ إنشاء غرفة عالمية
  Future<Map<String, dynamic>> createGlobalRoom({
    required OnlineCharacter character,
    required String roomName,
    required int maxPlayers,
  }) async {
    try {
      // 1. استخدام خدمتك الحالية لإنشاء الغرفة المحلية
      final localResult = await _localService.createRoomAsHost(
        character: character,
        roomName: roomName,
        maxPlayers: maxPlayers,
      );

      if (!localResult['success']) {
        return localResult;
      }

      // 2. الحصول على IP عام
      final publicIP = await _getPublicIP();

      // 3. تسجيل الغرفة في Firebase
      await _firestore.collection('global_rooms').doc(localResult['roomId']).set({
        'roomId': localResult['roomId'],
        'roomName': roomName,
        'hostPublicIP': publicIP,
        'hostLocalIP': localResult['roomData']['localIP'],
        'port': localResult['roomData']['port'],
        'gameMode': maxPlayers == 2 ? '1v1' : '2v2',
        'maxPlayers': maxPlayers,
        'currentPlayers': 1,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActivity': FieldValue.serverTimestamp(),
        'status': 'waiting',
        'isActive': true,
      });

      print('🌍 غرفة عالمية تم إنشاؤها: $roomName');
      return localResult;

    } catch (e) {
      print('❌ خطأ في إنشاء الغرفة العالمية: $e');
      return {'success': false, 'error': 'فشل في إنشاء الغرفة العالمية: $e'};
    }
  }

  // ✅ جلب الغرف العالمية النشطة
  Stream<List<Map<String, dynamic>>> getGlobalRooms() {
    return _firestore
        .collection('global_rooms')
        .where('isActive', isEqualTo: true)
        .where('lastActivity', isGreaterThan: Timestamp.fromDate(
        DateTime.now().subtract(Duration(minutes: 5))
    ))
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'roomId': data['roomId'],
        'roomName': data['roomName'],
        'hostPublicIP': data['hostPublicIP'],
        'hostLocalIP': data['hostLocalIP'],
        'port': data['port'],
        'gameMode': data['gameMode'],
        'maxPlayers': data['maxPlayers'],
        'currentPlayers': data['currentPlayers'],
        'status': data['status'],
      };
    }).toList());
  }

  // ✅ الانضمام لغرفة عالمية
  Future<Map<String, dynamic>> joinGlobalRoom(Map<String, dynamic> room) async {
    try {
      // استخدام خدمتك الحالية للانضمام
      final result = await _localService.joinRoomAsGuest(
        roomId: room['roomId'],
        character: room['character'], // تحتاج تمرير الشخصية
      );

      if (result['success']) {
        // تحديث عدد اللاعبين في Firebase
        await _firestore.collection('global_rooms').doc(room['roomId']).update({
          'currentPlayers': FieldValue.increment(1),
          'lastActivity': FieldValue.serverTimestamp(),
        });
      }

      return result;
    } catch (e) {
      return {'success': false, 'error': 'فشل في الانضمام للغرفة العالمية: $e'};
    }
  }

  // ✅ دالة مساعدة للحصول على IP عام
  Future<String> _getPublicIP() async {
    try {
      final response = await http.get(Uri.parse('https://api.ipify.org'));
      return response.body;
    } catch (e) {
      return 'unknown';
    }
  }

  // ✅ تحديث نشاط الغرفة
  Future<void> updateRoomActivity(String roomId) async {
    try {
      await _firestore.collection('global_rooms').doc(roomId).update({
        'lastActivity': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ خطأ في تحديث نشاط الغرفة: $e');
    }
  }

  // ✅ حذف الغرفة
  Future<void> deleteGlobalRoom(String roomId) async {
    try {
      await _firestore.collection('global_rooms').doc(roomId).update({
        'isActive': false,
      });
    } catch (e) {
      print('❌ خطأ في حذف الغرفة: $e');
    }
  }
}