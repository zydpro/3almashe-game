// lib/online/services/global_matchmaking_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/online_character_system.dart';

class GlobalMatchmakingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ✅ البحث عن مباراة 1v1 عالمية
  static Future<Map<String, dynamic>> find1v1Match(OnlineCharacter character) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'error': 'يجب تسجيل الدخول أولاً'};
      }

      // البحث عن غرفة انتظار متاحة
      final availableRooms = await _firestore
          .collection('global_rooms')
          .where('gameMode', isEqualTo: '1v1')
          .where('status', isEqualTo: 'waiting')
          .where('currentPlayers', isLessThan: 2)
          .limit(1)
          .get();

      if (availableRooms.docs.isNotEmpty) {
        // الانضمام لغرفة موجودة
        return await _joinExistingRoom(availableRooms.docs.first, character, user);
      } else {
        // إنشاء غرفة جديدة
        return await _createNewRoom(character, user, '1v1', 2);
      }
    } catch (e) {
      return {'success': false, 'error': 'خطأ في البحث عن مباراة: $e'};
    }
  }

  // ✅ البحث عن مباراة مع صديق
  static Future<Map<String, dynamic>> createFriendMatch(
      String friendId, OnlineCharacter character, String gameMode) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'error': 'يجب تسجيل الدخول أولاً'};
      }

      // إنشاء غرفة خاصة
      final roomData = await _createPrivateRoom(character, user, gameMode, 2, friendId);

      // إرسال دعوة للصديق
      await _sendGameInvitation(friendId, roomData['roomId'] as String, gameMode);

      return {
        'success': true,
        'roomId': roomData['roomId'],
        'roomData': roomData,
        'isPrivate': true,
      };
    } catch (e) {
      return {'success': false, 'error': 'خطأ في إنشاء مباراة مع صديق: $e'};
    }
  }

  // ✅ إنشاء غرفة عالمية
  static Future<Map<String, dynamic>> createGlobalRoom({
    required OnlineCharacter character,
    required String roomName,
    required String gameMode,
    required int maxPlayers,
    bool isPrivate = false,
    List<String>? invitedFriends,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'error': 'يجب تسجيل الدخول أولاً'};
      }

      final publicIP = await _getPublicIP();
      final roomId = 'global_${DateTime.now().millisecondsSinceEpoch}';

      final roomData = {
        'roomId': roomId,
        'hostId': user.uid,
        'hostName': user.displayName ?? 'المضيف',
        'hostPublicIP': publicIP,
        'roomName': roomName,
        'gameMode': gameMode,
        'maxPlayers': maxPlayers,
        'currentPlayers': 1,
        'status': 'waiting',
        'isPrivate': isPrivate,
        'invitedPlayers': invitedFriends ?? [],
        'createdAt': FieldValue.serverTimestamp(),
        'lastActivity': FieldValue.serverTimestamp(),
        'players': [
          {
            'userId': user.uid,
            'playerName': user.displayName ?? 'اللاعب',
            'character': _characterToMap(character),
            'isHost': true,
            'isReady': false,
            'publicIP': publicIP,
            'joinedAt': FieldValue.serverTimestamp(),
          }
        ],
      };

      await _firestore.collection('global_rooms').doc(roomId).set(roomData);

      // إرسال دعوات للأصدقاء إذا كانت غرفة خاصة
      if (isPrivate && invitedFriends != null) {
        for (final friendId in invitedFriends) {
          await _sendGameInvitation(friendId, roomId, gameMode);
        }
      }

      return {
        'success': true,
        'roomId': roomId,
        'roomData': roomData,
      };
    } catch (e) {
      return {'success': false, 'error': 'خطأ في إنشاء الغرفة: $e'};
    }
  }

  // ✅ الحصول على الغرف العالمية المتاحة
  static Stream<List<Map<String, dynamic>>> getGlobalRoomsStream() {
    return _firestore
        .collection('global_rooms')
        .where('status', isEqualTo: 'waiting')
        .where('isPrivate', isEqualTo: false)
        .where('lastActivity', isGreaterThan: Timestamp.fromDate(
        DateTime.now().subtract(Duration(minutes: 5))))
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'roomId': doc.id,
        'roomName': data['roomName'] as String? ?? 'غرفة بدون اسم',
        'hostName': data['hostName'] as String? ?? 'مضيف',
        'gameMode': data['gameMode'] as String? ?? '1v1',
        'maxPlayers': data['maxPlayers'] as int? ?? 2,
        'currentPlayers': data['currentPlayers'] as int? ?? 1,
        'createdAt': data['createdAt'],
        'players': data['players'] as List<dynamic>? ?? [],
      };
    }).toList());
  }

  // ✅ الانضمام لغرفة عالمية
  static Future<Map<String, dynamic>> joinGlobalRoom(
      String roomId, OnlineCharacter character) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'error': 'يجب تسجيل الدخول أولاً'};
      }

      final roomDoc = await _firestore.collection('global_rooms').doc(roomId).get();
      if (!roomDoc.exists) {
        return {'success': false, 'error': 'الغرفة غير موجودة'};
      }

      final roomData = roomDoc.data()!;
      final currentPlayers = roomData['currentPlayers'] as int? ?? 0;
      final maxPlayers = roomData['maxPlayers'] as int? ?? 2;

      if (currentPlayers >= maxPlayers) {
        return {'success': false, 'error': 'الغرفة ممتلئة'};
      }

      final publicIP = await _getPublicIP();
      final playerData = {
        'userId': user.uid,
        'playerName': user.displayName ?? 'اللاعب',
        'character': _characterToMap(character),
        'isHost': false,
        'isReady': false,
        'publicIP': publicIP,
        'joinedAt': FieldValue.serverTimestamp(),
      };

      // تحديث الغرفة
      await _firestore.collection('global_rooms').doc(roomId).update({
        'currentPlayers': FieldValue.increment(1),
        'lastActivity': FieldValue.serverTimestamp(),
        'players': FieldValue.arrayUnion([playerData]),
      });

      // إذا اكتمل عدد اللاعبين، تحديث الحالة
      if (currentPlayers + 1 >= maxPlayers) {
        await _firestore.collection('global_rooms').doc(roomId).update({
          'status': 'full',
        });
      }

      final updatedRoom = {
        ...roomData,
        'currentPlayers': currentPlayers + 1,
        'players': [...(roomData['players'] as List<dynamic>? ?? []), playerData],
      };

      return {
        'success': true,
        'roomId': roomId,
        'roomData': updatedRoom,
      };
    } catch (e) {
      return {'success': false, 'error': 'خطأ في الانضمام للغرفة: $e'};
    }
  }

  // ✅ دوال مساعدة خاصة
  static Future<Map<String, dynamic>> _joinExistingRoom(
      QueryDocumentSnapshot roomDoc, OnlineCharacter character, User user) async {
    final roomData = roomDoc.data() as Map<String, dynamic>;
    final roomId = roomDoc.id;
    return await joinGlobalRoom(roomId, character);
  }

  static Future<Map<String, dynamic>> _createNewRoom(
      OnlineCharacter character, User user, String gameMode, int maxPlayers) async {
    return await createGlobalRoom(
      character: character,
      roomName: '${user.displayName ?? "اللاعب"} - $gameMode',
      gameMode: gameMode,
      maxPlayers: maxPlayers,
    );
  }

  static Future<Map<String, dynamic>> _createPrivateRoom(
      OnlineCharacter character, User user, String gameMode, int maxPlayers, String friendId) async {
    return await createGlobalRoom(
      character: character,
      roomName: 'مباراة خاصة - $gameMode',
      gameMode: gameMode,
      maxPlayers: maxPlayers,
      isPrivate: true,
      invitedFriends: [friendId],
    );
  }

  static Future<void> _sendGameInvitation(String friendId, String roomId, String gameMode) async {
    final user = _auth.currentUser!;

    await _firestore.collection('game_invitations').doc('${user.uid}_$roomId').set({
      'fromUserId': user.uid,
      'fromUserName': user.displayName ?? 'صديق',
      'toUserId': friendId,
      'roomId': roomId,
      'gameMode': gameMode,
      'sentAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }

  static Future<String> _getPublicIP() async {
    try {
      final response = await http.get(Uri.parse('https://api.ipify.org'));
      return response.body;
    } catch (e) {
      return 'unknown';
    }
  }

  static Map<String, dynamic> _characterToMap(OnlineCharacter character) {
    return {
      'id': character.id,
      'name': character.name,
      'nameEn': character.nameEn,
      'type': character.type,
      'imagePath': character.imagePath,
      'primaryWeapon': character.primaryWeapon.toString(),
      'secondaryWeapon': character.secondaryWeapon.toString(),
      'specialAbility': character.specialAbility,
    };
  }

  // ✅ تحديث حالة الغرفة
  static Future<void> updateRoomStatus(String roomId, String status) async {
    try {
      await _firestore.collection('global_rooms').doc(roomId).update({
        'status': status,
        'lastActivity': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ خطأ في تحديث حالة الغرفة: $e');
    }
  }

  // ✅ حذف الغرفة
  static Future<void> deleteRoom(String roomId) async {
    try {
      await _firestore.collection('global_rooms').doc(roomId).delete();
    } catch (e) {
      print('❌ خطأ في حذف الغرفة: $e');
    }
  }

  // ✅ الحصول على معلومات الغرفة
  static Stream<Map<String, dynamic>?> getRoomStream(String roomId) {
    return _firestore
        .collection('global_rooms')
        .doc(roomId)
        .snapshots()
        .map((snapshot) => snapshot.data() as Map<String, dynamic>?);
  }
}