import 'dart:async';
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:network_info_plus/network_info_plus.dart';

class P2PConnectionService {
  static final P2PConnectionService _instance = P2PConnectionService._internal();
  factory P2PConnectionService() => _instance;
  P2PConnectionService._internal();

  IO.Socket? _socket;
  WebSocketChannel? _webSocket;
  bool _isConnected = false;
  String? _connectionId;
  String? _role; // ✅ إضافة: 'host' أو 'guest'
  final NetworkInfo _networkInfo = NetworkInfo();
  final List<Function(Map<String, dynamic>)> _messageHandlers = []; // ✅ إضافة: قائمة المعالجات

  // ✅ المضيف: بدء السيرفر P2P
  Future<void> startAsHost({int port = 8080}) async {
    try {
      final localIP = await _getLocalIP();

      // محاكاة بدء سيرفر P2P
      _isConnected = true;
      _connectionId = 'host_${DateTime.now().millisecondsSinceEpoch}';
      _role = 'host';

      print('🎮 بدء السيرفر P2P - ID: $_connectionId');
      print('📍 العنوان: $localIP:$port');

      _setupMessageHandlers();
    } catch (e) {
      print('❌ فشل في بدء السيرفر: $e');
      rethrow;
    }
  }

  // ✅ الضيف: الاتصال بالمضيف
  Future<void> joinAsGuest(String hostIP, int port) async {
    try {
      print('🔗 جاري الاتصال بالمضيف: $hostIP:$port');

      // محاكاة الاتصال بالمضيف
      await Future.delayed(Duration(seconds: 1));

      _isConnected = true;
      _connectionId = 'guest_${DateTime.now().millisecondsSinceEpoch}';
      _role = 'guest';

      print('✅ تم الاتصال بالمضيف - ID: $_connectionId');

      _setupMessageHandlers();

      // إرسال رسالة انضمام
      _sendGameData({
        'type': 'playerJoined',
        'payload': {
          'playerId': _connectionId,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'role': _role,
        },
      });
    } catch (e) {
      print('❌ فشل في الاتصال بالمضيف: $e');
      rethrow;
    }
  }

  // ✅ إرسال حركة اللاعب
  void sendPlayerMovement(double x, double y, bool isFacingRight) {
    final message = {
      'type': 'player_movement',
      'payload': {  // ✅ إضافة payload
        'x': x,
        'y': y,
        'isFacingRight': isFacingRight,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'playerId': _connectionId,
      },
    };

    sendGameData(message); // ✅ استخدام sendGameData بدلاً من _sendMessage مباشرة
  }

  // ✅ إرسال هجوم اللاعب
  void sendPlayerAttack(String attackType, String weaponType) {
    _sendGameData({
      'type': 'playerAttack',
      'payload': {
        'attackType': attackType,
        'weapon': weaponType,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'playerId': _connectionId,
      },
    });
  }

  // ✅ إرسال حالة اللاعب (جديد)
  void sendPlayerState(String state, String animation) {
    _sendGameData({
      'type': 'playerState',
      'payload': {
        'state': state,
        'animation': animation,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'playerId': _connectionId,
      },
    });
  }

  // ✅ إرسال جاهزية اللاعب (جديد)
  void sendReadyStatus(bool isReady) {
    _sendGameData({
      'type': 'playerReady',
      'payload': {
        'isReady': isReady,
        'playerId': _connectionId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    });
  }

  // ✅ إرسال بدء اللعبة (جديد - للمضيف فقط)
  void sendStartGame() {
    if (_role != 'host') {
      print('⚠️ فقط المضيف يمكنه بدء اللعبة');
      return;
    }

    _sendGameData({
      'type': 'startGame',
      'payload': {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'hostId': _connectionId,
      },
    });
  }

  void _setupMessageHandlers() {
    // معالجات الرسائل الواردة
    print('🔄 معالجات الرسائل جاهزة');
  }

  // ✅ إرسال بيانات اللعبة
  void sendGameData(Map<String, dynamic> data) {
    if (!_isConnected) {
      print('⚠️ غير متصل - لا يمكن إرسال الرسالة');
      return;
    }

    try {
      final message = json.encode(data);
      print('📤 إرسال: ${data['type']}');

      // استخدام _sendMessage بدلاً من الكود المكرر
      _sendMessage(message);

    } catch (e) {
      print('❌ خطأ في إرسال البيانات: $e');
    }
  }

  // ✅ محاكاة استقبال الرسائل (جديد)
  void _simulateMessageReceipt(Map<String, dynamic> message) {
    Future.delayed(Duration(milliseconds: 100), () {
      for (var handler in _messageHandlers) {
        handler(message);
      }
    });
  }

  // ✅ الحصول على عنوان IP المحلي (جديد)
  Future<String?> _getLocalIP() async {
    try {
      final wifiIP = await _networkInfo.getWifiIP();
      return wifiIP ?? '192.168.1.100'; // عنوان افتراضي
    } catch (e) {
      return '192.168.1.100'; // عنوان افتراضي في حالة الخطأ
    }
  }

  // ✅ معالجة البيانات الواردة (للاستخدام من الشاشات)
  void setMessageHandler(Function(Map<String, dynamic>) handler) {
    _messageHandlers.add(handler);
  }

  // ✅ إزالة معالج الرسائل (جديد)
  void removeMessageHandler(Function(Map<String, dynamic>) handler) {
    _messageHandlers.remove(handler);
  }

  // ✅ محاكاة استقبال بيانات (للتجربة)
  void simulateIncomingMessage(Map<String, dynamic> data) {
    for (var handler in _messageHandlers) {
      handler(data);
    }
  }

  // ✅ إرسال بيانات عامة
  void _sendGameData(Map<String, dynamic> data) {
    sendGameData(data);
  }

  // ✅ التحقق من حالة الاتصال
  bool get isConnected => _isConnected;

  // ✅ الحصول على ID الاتصال
  String? get connectionId => _connectionId;

  // ✅ الحصول على دور اللاعب (جديد)
  String? get role => _role;

  // ✅ التحقق إذا كان مضيف (جديد)
  bool get isHost => _role == 'host';

  // ✅ إضافة دالة _sendMessage
  void _sendMessage(String message) {
    if (!_isConnected) {
      print('⚠️ غير متصل - لا يمكن إرسال الرسالة');
      return;
    }

    try {
      print('📤 إرسال رسالة: $message');

      // محاكاة إرسال الرسالة عبر Socket
      // _socket?.emit('game_message', message);
      // أو عبر WebSocket
      // _webSocket?.sink.add(message);

      // ✅ محاكاة استقبال الرسالة (للتجربة)
      _simulateMessageReceipt(json.decode(message));

    } catch (e) {
      print('❌ خطأ في إرسال الرسالة: $e');
    }
  }

  // ✅ إضافة دالة sendMessage (عامة)
  void sendMessage(String type, Map<String, dynamic> payload) {
    final message = {
      'type': type,
      'payload': payload,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'playerId': _connectionId,
    };

    _sendMessage(jsonEncode(message));
  }

  void disconnect() {
    _isConnected = false;
    _role = null;
    _socket?.disconnect();
    _webSocket?.sink.close();
    _messageHandlers.clear(); // ✅ تنظيف المعالجات
    print('🔌 تم قطع الاتصال P2P');
  }

  void dispose() {
    disconnect();
  }
}