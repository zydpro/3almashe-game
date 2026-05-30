import 'dart:async';
import 'dart:math';
import 'package:network_info_plus/network_info_plus.dart';
import '../models/online_character_system.dart';

class P2PMatchmakingService {
  static final P2PMatchmakingService _instance = P2PMatchmakingService._internal();
  factory P2PMatchmakingService() => _instance;

  final NetworkInfo _networkInfo = NetworkInfo();
  final List<Map<String, dynamic>> _localRooms = [];
  final List<Function(List<Map<String, dynamic>>)> _roomListeners = [];
  Timer? _discoveryTimer;
  Timer? _cleanupTimer;

  P2PMatchmakingService._internal() { // ✅ هذا الكونستركتور موجود أصلاً
    _startRoomCleanup(); // ✅ فقط أضف هذا السطر هنا
    print('⚠️ هذا النظام للشبكات المحلية فقط (LAN)');
  }

  // ✅ بدء عملية تنظيف الغرف تلقائياً
  void _startRoomCleanup() {
    _cleanupTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      _cleanupInactiveRooms();
    });
  }

  // ✅ تنظيف الغرف غير النشطة
  void _cleanupInactiveRooms() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final fiveMinutesAgo = now - (5 * 60 * 1000); // 5 دقائق بالملي ثانية

    _localRooms.removeWhere((room) {
      final lastActivity = room['lastActivity'] ?? room['createdAt'];
      final isInactive = lastActivity < fiveMinutesAgo;
      final isEmpty = (room['currentPlayers'] ?? 0) == 0;

      // ✅ حذف الغرف التي لا يوجد بها لاعبين وغير نشطة منذ 5 دقائق
      if (isInactive && isEmpty) {
        print('🧹 حذف غرفة غير نشطة: ${room['roomName']}');
        return true;
      }
      return false;
    });

    _notifyRoomListeners();
  }

  // ✅ تحديث وقت النشاط الأخير للغرفة
  void _updateRoomActivity(String roomId) {
    final roomIndex = _localRooms.indexWhere((room) => room['roomId'] == roomId);
    if (roomIndex != -1) {
      _localRooms[roomIndex]['lastActivity'] = DateTime.now().millisecondsSinceEpoch;
    }
  }

  // ✅ إنشاء غرفة P2P محلية
  Future<Map<String, dynamic>> createRoomAsHost({
    required OnlineCharacter character,
    required String roomName,
    int maxPlayers = 2,
    bool isPublic = true,
  }) async {
    try {
      final localIP = await _getLocalIP();

      final roomData = {
        'roomId': 'room_${DateTime.now().millisecondsSinceEpoch}',
        'hostId': 'host_${DateTime.now().millisecondsSinceEpoch}',
        'hostName': 'المضيف',
        'character': character.toJson(),
        'roomName': roomName,
        'maxPlayers': maxPlayers,
        'currentPlayers': 1,
        'isPublic': isPublic,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'lastActivity': DateTime.now().millisecondsSinceEpoch, // ✅ إضافة وقت النشاط
        'status': 'waiting',
        'localIP': localIP,
        'port': _generateRandomPort(),
        'connectionType': 'direct_p2p',
        'players': [
          {
            'id': 'host_${DateTime.now().millisecondsSinceEpoch}',
            'name': 'المضيف',
            'character': character.toJson(),
            'isHost': true,
            'isReady': true,
            'joinedAt': DateTime.now().millisecondsSinceEpoch,
          }
        ],
      };

      _localRooms.add(roomData);
      _notifyRoomListeners();

      print('🎮 غرفة P2P تم إنشاؤها: ${roomData['roomName']}');
      print('📍 العنوان: ${roomData['localIP']}:${roomData['port']}');

      return {
        'success': true,
        'roomId': roomData['roomId'],
        'roomData': roomData,
        'isHost': true,
      };
    } catch (e) {
      print('❌ فشل في إنشاء الغرفة: $e');
      return {
        'success': false,
        'error': 'فشل في إنشاء الغرفة: $e',
      };
    }
  }

  // ✅ الانضمام لغرفة P2P محلية
  Future<Map<String, dynamic>> joinRoomAsGuest({
    required String roomId,
    required OnlineCharacter character,
  }) async {
    try {
      final roomIndex = _localRooms.indexWhere((room) => room['roomId'] == roomId);

      if (roomIndex == -1) {
        return {'success': false, 'error': 'الغرفة غير موجودة'};
      }

      final room = _localRooms[roomIndex];

      if (room['currentPlayers'] >= room['maxPlayers']) {
        return {'success': false, 'error': 'الغرفة ممتلئة'};
      }

      final playerData = {
        'id': 'guest_${DateTime.now().millisecondsSinceEpoch}',
        'name': 'الضيف',
        'character': character.toJson(),
        'isHost': false,
        'isReady': true,
        'joinedAt': DateTime.now().millisecondsSinceEpoch,
      };

      // تحديث الغرفة المحلية
      final updatedRoom = {
        ...room,
        'currentPlayers': room['currentPlayers'] + 1,
        'lastActivity': DateTime.now().millisecondsSinceEpoch, // ✅ تحديث النشاط
        'players': [...room['players'], playerData],
        'status': room['currentPlayers'] + 1 >= room['maxPlayers'] ? 'full' : 'waiting',
      };

      _localRooms[roomIndex] = updatedRoom;
      _notifyRoomListeners();

      return {
        'success': true,
        'roomId': roomId,
        'roomData': updatedRoom,
        'isHost': false,
      };
    } catch (e) {
      print('❌ فشل في الانضمام للغرفة: $e');
      return {
        'success': false,
        'error': 'فشل في الانضمام للغرفة: $e',
      };
    }
  }

  // ✅ البحث عن غرف على الشبكة المحلية
  Stream<List<Map<String, dynamic>>> getAvailableRooms() {
    _startRoomDiscovery();
    return Stream.fromIterable([_getActiveRooms()]); // ✅ عرض الغرف النشطة فقط
  }

  // ✅ الحصول على الغرف النشطة فقط
  List<Map<String, dynamic>> _getActiveRooms() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final fiveMinutesAgo = now - (5 * 60 * 1000);

    return _localRooms.where((room) {
      final lastActivity = room['lastActivity'] ?? room['createdAt'];
      final isActive = lastActivity >= fiveMinutesAgo;
      final isPublic = room['isPublic'] == true;

      return isActive && isPublic;
    }).toList();
  }

  // ✅ محاكاة اكتشاف الغرف على LAN
  void _startRoomDiscovery() {
    _discoveryTimer?.cancel();

    _discoveryTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      _notifyRoomListeners();
    });
  }

  // ✅ الحصول على عنوان IP المحلي
  Future<String?> _getLocalIP() async {
    try {
      final wifiIP = await _networkInfo.getWifiIP();
      return wifiIP ?? '192.168.1.100';
    } catch (e) {
      return '192.168.1.100';
    }
  }

  // ✅ إنشاء منفذ عشوائي
  int _generateRandomPort() {
    final random = Random();
    return 8000 + random.nextInt(1000);
  }

  // ✅ إشعار المستمعين بتحديث الغرف
  void _notifyRoomListeners() {
    final activeRooms = _getActiveRooms();
    for (var listener in _roomListeners) {
      listener(activeRooms);
    }
  }

  // ✅ إضافة مستمع للغرف
  void addRoomListener(Function(List<Map<String, dynamic>>) listener) {
    _roomListeners.add(listener);
  }

  // ✅ إزالة مستمع
  void removeRoomListener(Function(List<Map<String, dynamic>>) listener) {
    _roomListeners.remove(listener);
  }

  // ✅ دوال مساعدة
  Future<void> deleteRoom(String roomId) async {
    _localRooms.removeWhere((room) => room['roomId'] == roomId);
    _notifyRoomListeners();
  }

  Future<void> updatePlayerReadyStatus(String roomId, String playerId, bool isReady) async {
    final roomIndex = _localRooms.indexWhere((room) => room['roomId'] == roomId);

    if (roomIndex != -1) {
      final room = _localRooms[roomIndex];
      final updatedPlayers = List<Map<String, dynamic>>.from(room['players']);

      for (int i = 0; i < updatedPlayers.length; i++) {
        if (updatedPlayers[i]['id'] == playerId) {
          updatedPlayers[i] = {...updatedPlayers[i], 'isReady': isReady};
          break;
        }
      }

      _localRooms[roomIndex] = {
        ...room,
        'players': updatedPlayers,
        'lastActivity': DateTime.now().millisecondsSinceEpoch // ✅ تحديث النشاط
      };
      _notifyRoomListeners();
    }
  }

  // ✅ تحديث نشاط الغرفة (للاستخدام من غرفة الانتظار)
  void updateRoomActivity(String roomId) {
    _updateRoomActivity(roomId);
  }

  void dispose() {
    _discoveryTimer?.cancel();
    _cleanupTimer?.cancel(); // ✅ إيقاف مؤقت التنظيف
    _roomListeners.clear();
  }
}