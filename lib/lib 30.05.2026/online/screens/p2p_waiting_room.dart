import 'package:flutter/material.dart';
import '../models/online_character_system.dart';
import 'character_selection_screen.dart';
import 'online_game_screen.dart';
import '../services/p2p_connection_service.dart';

class P2PWaitingRoom extends StatefulWidget {
  final String roomId;
  final Map<String, dynamic> roomData;
  final bool isHost;
  final P2PConnectionService connectionService;
  final String? gameMode;

  const P2PWaitingRoom({
    super.key,
    required this.roomId,
    required this.roomData,
    required this.isHost,
    required this.connectionService,
    this.gameMode = '1v1',
  });

  @override
  State<P2PWaitingRoom> createState() => _P2PWaitingRoomState();
}

class _P2PWaitingRoomState extends State<P2PWaitingRoom> {
  List<Map<String, dynamic>> _players = [];
  bool _isReady = false;
  bool _isRoomFull = false;

  @override
  void initState() {
    super.initState();
    _players = List<Map<String, dynamic>>.from(widget.roomData['players'] ?? []);
    _checkRoomFull();
    _setupConnectionHandlers();
    _updateRoomActivity(); // ✅ تحديث نشاط الغرفة
  }

  // ✅ تحديث نشاط الغرفة
  void _updateRoomActivity() {
    // يمكنك إرسال تحديث للمضيف لتحديث وقت النشاط
    if (!widget.isHost) {
      widget.connectionService.sendGameData({
        'type': 'roomActivity',
        'payload': {
          'roomId': widget.roomId,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      });
    }
  }

  void _checkRoomFull() {
    final maxPlayers = widget.roomData['maxPlayers'] ?? 2;
    setState(() {
      _isRoomFull = _players.length >= maxPlayers;
    });
  }

  void _navigateToCharacterSelection() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => CharacterSelectionScreen(
          gameMode: widget.gameMode ?? '1v1',
          opponentsData: _players.where((p) => p['id'] != widget.connectionService.connectionId).toList(),
          roomId: widget.roomId,
          isQuickMatch: false,
        ),
      ),
    );
  }

  void _setupConnectionHandlers() {
    widget.connectionService.setMessageHandler((data) {
      if (data['type'] == 'playerJoined') {
        setState(() {
          _players.add({
            'id': data['payload']['playerId'],
            'name': 'لاعب جديد',
            'isHost': false,
            'isReady': false,
          });
          _checkRoomFull();
        });

        // ✅ إشعار عند انضمام لاعب جديد
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('لاعب جديد انضم إلى الغرفة!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else if (data['type'] == 'playerReady') {
        setState(() {
          final playerId = data['payload']['playerId'];
          final playerIndex = _players.indexWhere((p) => p['id'] == playerId);
          if (playerIndex != -1) {
            _players[playerIndex]['isReady'] = true;
            _updateRoomActivity(); // ✅ تحديث النشاط عند استلام رسالة نشاط
          }
        });
      } else if (data['type'] == 'playerLeft') {
        setState(() {
          final playerId = data['payload']['playerId'];
          _players.removeWhere((p) => p['id'] == playerId);
          _checkRoomFull();
        });
      } else if (data['type'] == 'startGame') {
        _startGame();
      }
    });
  }

  void _toggleReady() {
    setState(() {
      _isReady = !_isReady;
    });

    widget.connectionService.sendGameData({
      'type': 'playerReady',
      'payload': {
        'playerId': widget.connectionService.connectionId,
        'isReady': _isReady,
      },
    });
  }

  void _startGame() {
    if (_allPlayersReady() && _isRoomFull) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OnlineGameScreen(
            playerCharacter: _getPlayerCharacter(),
            opponent: _getOpponentData(),
            roomId: widget.roomId,
            isQuickMatch: false,
            connectionService: widget.connectionService,
            gameMode: widget.gameMode,
          ),
        ),
      );
    }
  }

  void _sendStartGame() {
    if (widget.isHost && _allPlayersReady() && _isRoomFull) {
      widget.connectionService.sendGameData({
        'type': 'startGame',
        'payload': {
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      });
      _startGame();
    }
  }

  bool _allPlayersReady() {
    return _players.every((player) => player['isReady'] == true);
  }

  void _leaveRoom() {
    // ✅ إرسال رسالة مغادرة الغرفة
    widget.connectionService.sendGameData({
      'type': 'playerLeft',
      'payload': {
        'playerId': widget.connectionService.connectionId,
      },
    });

    widget.connectionService.disconnect();
    Navigator.pop(context);
  }

  void _cancelSearch() {
    widget.connectionService.disconnect();
    Navigator.pop(context);
  }

  void _deleteRoom() {
    if (widget.isHost) {
      // ✅ إرسال رسالة إغلاق الغرفة لجميع اللاعبين
      widget.connectionService.sendGameData({
        'type': 'roomClosed',
        'payload': {
          'reason': 'المضيف أغلق الغرفة',
        },
      });
    }
    widget.connectionService.disconnect();
    Navigator.pop(context);
  }

  OnlineCharacter _getPlayerCharacter() {
    final playerData = _players.firstWhere(
          (player) => player['id'] == widget.connectionService.connectionId,
      orElse: () => _players.first,
    );

    if (playerData['character'] is OnlineCharacter) {
      return playerData['character'] as OnlineCharacter;
    } else if (playerData['character'] is Map) {
      final charData = playerData['character'] as Map<String, dynamic>;

      // دالة مساعدة لتحديد اللون بناءً على النوع
      Color _getCharacterColor(String type) {
        switch (type.toLowerCase()) {
          case 'سرعة': return Colors.blue;
          case 'قوة': return Colors.red;
          case 'دفاع': return Colors.green;
          case 'سحر': return Colors.purple;
          case 'تكنولوجيا': return Colors.cyan;
          case 'رشاقة': return Colors.orange;
          case 'متوازن': return Colors.blue;
          case 'مدى': return Colors.green;
          default: return Colors.blue;
        }
      }

      // ✅ دالة لتحديد الأيقونة بناءً على النوع
      String _getCharacterIconPath(String type) {
        switch (type.toLowerCase()) {
          case 'سرعة': return 'assets/images/characters/almashe/almashe_icon.png';
          case 'قوة': return 'assets/images/characters/viking/viking_icon.png';
          case 'دفاع': return 'assets/images/characters/medieval/medieval_icon.png';
          case 'سحر': return 'assets/images/characters/greek/greek_icon.png';
          case 'تكنولوجيا': return 'assets/images/characters/techno/techno_icon.png';
          case 'رشاقة': return 'assets/images/characters/rainbow/rainbow_icon.png';
          default: return 'assets/images/characters/almashe/almashe_icon.png';
        }
      }

      return OnlineCharacter(
        id: charData['id'] ?? 1,
        name: charData['name'] ?? 'لاعب',
        nameEn: charData['nameEn'] ?? 'Player',
        type: charData['type'] ?? 'سرعة',
        imagePath: charData['imagePath'] ?? 'assets/images/characters/almashe/almashe_1.png',
        iconPath: _getCharacterIconPath(charData['type'] ?? 'سرعة'), // ✅ إضافة iconPath
        isLocked: false,
        price: 0,
        primaryWeapon: OnlineWeaponType.sword,
        secondaryWeapon: OnlineWeaponType.bow,
        specialAbility: charData['specialAbility'] ?? 'رمي الصناديق',
        specialAbilityCooldown: 10.0,
        characterColor: _getCharacterColor(charData['type'] ?? 'سرعة'),
      );
    }

    return OnlineCharacter.getDefaultCharacter();
  }

  Map<String, dynamic> _getOpponentData() {
    final opponent = _players.firstWhere(
          (player) => player['id'] != widget.connectionService.connectionId,
      orElse: () => _players.isNotEmpty ? _players.last : {'character': OnlineCharacter.getDefaultCharacter()},
    );

    return {
      'character': opponent['character'] ?? OnlineCharacter.getDefaultCharacter(),
      'playerId': opponent['id'] ?? 'opponent',
      'name': opponent['name'] ?? 'الخصم',
    };
  }

  // ✅ دالة مساعدة للأحجام المتجاوبة
  double _responsiveWidth(double percentage) {
    return MediaQuery.of(context).size.width * percentage;
  }

  double _responsiveHeight(double percentage) {
    return MediaQuery.of(context).size.height * percentage;
  }

  double _responsiveText(double baseSize) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return baseSize * 0.8;
    if (width < 800) return baseSize * 0.9;
    return baseSize;
  }


  @override
  Widget build(BuildContext context) {
    final maxPlayers = widget.roomData['maxPlayers'] ?? 2;
    final currentPlayers = _players.length;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0f3460),
              Color(0xFF16213e),
              Color(0xFF1a1a2e),
            ],
          ),
          image: DecorationImage(
            image: AssetImage('assets/online/backgrounds/main_bg.png'),
            fit: BoxFit.cover,
            opacity: 0.3,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(_responsiveWidth(0.02)),
            child: Column(
              children: [
                // ✅ Header مع زر العودة - مضغوط
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white, size: _responsiveWidth(0.035)), // ✅ تصغير
                      onPressed: _leaveRoom,
                    ),
                    SizedBox(width: _responsiveWidth(0.01)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🕒 غرفة الانتظار',
                            style: TextStyle(
                              fontSize: _responsiveText(16),
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'رقم الغرفة: ${widget.roomId}',
                            style: TextStyle(
                              fontSize: _responsiveText(10),
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: _responsiveHeight(0.01)),

                // ✅ حالة الاتصال واللاعبين - مضغوط
                Container(
                  padding: EdgeInsets.all(_responsiveWidth(0.02)),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people, color: Colors.green, size: _responsiveWidth(0.025)), // ✅ تصغير
                          SizedBox(width: _responsiveWidth(0.01)),
                          Text(
                            '$currentPlayers/$maxPlayers لاعبين',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: _responsiveText(11),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: _responsiveHeight(0.005)),
                      Text(
                        _isRoomFull ? '✅ الغرفة ممتلئة - جاهز للبدء' : '⏳ في انتظار اللاعبين...',
                        style: TextStyle(
                          color: _isRoomFull ? Colors.green : Colors.orange,
                          fontSize: _responsiveText(10),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: _responsiveHeight(0.01)),

                // ✅ قائمة اللاعبين
                Expanded(
                  child: _players.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          color: Colors.white54,
                          size: _responsiveWidth(0.07), // ✅ تصغير
                        ),
                        SizedBox(height: _responsiveHeight(0.01)),
                        Text(
                          'لا يوجد لاعبين بعد',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: _responsiveText(12),
                          ),
                        ),
                        Text(
                          'في انتظار انضمام اللاعبين...',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: _responsiveText(9),
                          ),
                        ),
                      ],
                    ),
                  )
                      : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: _players.length,
                    itemBuilder: (context, index) {
                      final player = _players[index];
                      return Card(
                        color: Colors.white.withOpacity(0.05),
                        margin: EdgeInsets.symmetric(
                          vertical: _responsiveHeight(0.002),
                          horizontal: _responsiveWidth(0.005),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(_responsiveWidth(0.015)),
                          leading: Icon(
                            player['isReady'] ? Icons.check_circle : Icons.schedule,
                            color: player['isReady'] ? Colors.green : Colors.orange,
                            size: _responsiveWidth(0.035), // ✅ تصغير
                          ),
                          title: Text(
                            player['name'],
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: _responsiveText(11),
                            ),
                          ),
                          subtitle: Text(
                            player['isHost'] ? 'المضيف' : 'اللاعب',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: _responsiveText(9),
                            ),
                          ),
                          trailing: player['isHost']
                              ? Icon(Icons.star, color: Colors.yellow, size: _responsiveWidth(0.025)) // ✅ تصغير
                              : null,
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(height: _responsiveHeight(0.01)),

                // ✅ أزرار التحكم - مضغوطة جداً
                Column(
                  children: [
                    // زر الجاهزية
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _toggleReady,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isReady ? Colors.green : Colors.blue,
                          padding: EdgeInsets.symmetric(vertical: _responsiveHeight(0.01)),
                        ),
                        child: Text(
                          _isReady ? 'جاهز ✓' : 'اضغط للتجهز',
                          style: TextStyle(fontSize: _responsiveText(12)),
                        ),
                      ),
                    ),

                    SizedBox(height: _responsiveHeight(0.005)),

                    // ✅ زر البدء (للمضيف فقط) عندما تكتمل الغرفة - إضافة شرط الجاهزية
                    if (widget.isHost && _isRoomFull && _allPlayersReady())
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _sendStartGame,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: EdgeInsets.symmetric(vertical: _responsiveHeight(0.01)),
                          ),
                          child: Text(
                            '🚀 بدء اللعبة',
                            style: TextStyle(fontSize: _responsiveText(12), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),

                    // ✅ رسالة توضيحية عندما تكون الغرفة مكتملة ولكن اللاعبين غير جاهزين
                    if (widget.isHost && _isRoomFull && !_allPlayersReady())
                      Container(
                        padding: EdgeInsets.all(_responsiveWidth(0.02)),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.info, color: Colors.orange, size: _responsiveWidth(0.03)), // ✅ تصغير
                            SizedBox(width: _responsiveWidth(0.01)),
                            Text(
                              'انتظر حتى يصبح جميع اللاعبين جاهزين',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: _responsiveText(9),
                              ),
                            ),
                          ],
                        ),
                      ),

                    SizedBox(height: _responsiveHeight(0.005)),

                    // ✅ أزرار الإدارة - مضغوطة
                    Row(
                      children: [
                        // زر إلغاء البحث
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _cancelSearch,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: EdgeInsets.symmetric(vertical: _responsiveHeight(0.008)),
                            ),
                            child: Text(
                              'إلغاء البحث',
                              style: TextStyle(fontSize: _responsiveText(10)),
                            ),
                          ),
                        ),

                        SizedBox(width: _responsiveWidth(0.01)),

                        // زر حذف الغرفة (للمضيف فقط)
                        if (widget.isHost)
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _deleteRoom,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepOrange,
                                padding: EdgeInsets.symmetric(vertical: _responsiveHeight(0.008)),
                              ),
                              child: Text(
                                'حذف الغرفة',
                                style: TextStyle(fontSize: _responsiveText(10)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}