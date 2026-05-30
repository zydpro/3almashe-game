import 'package:flutter/material.dart';
import '../../Languages/localization.dart';
import '../../models/character_model.dart';
import '../services/global_p2p_service.dart';
import '../services/p2p_connection_service.dart';
import '../services/p2p_matchmaking_service.dart';
import 'character_selection_screen.dart';
import 'online_game_screen.dart';
import '../../services/game_data_service.dart';
import '../models/online_character_system.dart';
import 'p2p_waiting_room.dart';

class P2PLobbyScreen extends StatefulWidget {
  final String? gameMode; // '1v1' أو '2v2'
  final int teamSize;     // 2 لـ 1v1، 4 لـ 2v2
  final bool useGlobalMode; // ✅ اختيار بين المحلي والعالمي

  const P2PLobbyScreen({
    super.key,
    this.gameMode = '1v1',
    this.teamSize = 2,
    this.useGlobalMode = false,
  });

  @override
  State<P2PLobbyScreen> createState() => _P2PLobbyScreenState();
}

class _P2PLobbyScreenState extends State<P2PLobbyScreen> {
  final P2PMatchmakingService _matchmakingService = P2PMatchmakingService();
  final P2PConnectionService _connectionService = P2PConnectionService();
  final GlobalP2PService _globalService = GlobalP2PService(); // ✅ الخدمة الجديدة

  OnlineCharacter? _selectedCharacter;
  List<OnlineCharacter> _ownedCharacters = [];
  bool _isLoading = true;
  String _roomName = 'غرفتي';
  List<Map<String, dynamic>> _availableRooms = [];

  @override
  void initState() {
    super.initState();
    _loadPlayerData();
    _loadAvailableRooms();

    if (widget.gameMode == '2v2') {
      _roomName = 'فريق 2v2';
    }
  }

  Future<void> _loadPlayerData() async {
    try {
      final ownedCharacters = await GameDataService.getOwnedCharacters();
      final onlineCharacters = _convertToOnlineCharacters(ownedCharacters);

      setState(() {
        _ownedCharacters = onlineCharacters;
        _selectedCharacter = _ownedCharacters.isNotEmpty
            ? _ownedCharacters.first
            : OnlineCharacter.getDefaultCharacter();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<OnlineCharacter> _convertToOnlineCharacters(List<GameCharacter> gameCharacters) {
    final allOnlineCharacters = OnlineCharacter.getAllOnlineCharacters();
    final List<OnlineCharacter> result = [];

    for (var gameChar in gameCharacters) {
      final onlineChar = allOnlineCharacters.firstWhere(
            (online) => online.id == gameChar.id,
        orElse: () => _createOnlineCharacterFromGame(gameChar),
      );
      result.add(onlineChar);
    }

    return result;
  }

  OnlineCharacter _createOnlineCharacterFromGame(GameCharacter gameChar) {
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

    // دالة لتحديد الأسلحة بناءً على النوع
    OnlineWeaponType _getPrimaryWeapon(String type) {
      switch (type.toLowerCase()) {
        case 'سرعة': return OnlineWeaponType.sword;
        case 'قوة': return OnlineWeaponType.hammer;
        case 'دفاع': return OnlineWeaponType.gauntlets;
        case 'سحر': return OnlineWeaponType.staff;
        case 'تكنولوجيا': return OnlineWeaponType.blasters;
        case 'رشاقة': return OnlineWeaponType.katars;
        default: return OnlineWeaponType.sword;
      }
    }

    OnlineWeaponType _getSecondaryWeapon(String type) {
      switch (type.toLowerCase()) {
        case 'سرعة': return OnlineWeaponType.bow;
        case 'قوة': return OnlineWeaponType.axe;
        case 'دفاع': return OnlineWeaponType.sword;
        case 'سحر': return OnlineWeaponType.orb;
        case 'تكنولوجيا': return OnlineWeaponType.bow;
        case 'رشاقة': return OnlineWeaponType.spear;
        default: return OnlineWeaponType.bow;
      }
    }

    // ✅ دالة لتحديد الأيقونة بناءً على نوع الشخصية
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
      id: gameChar.id,
      name: gameChar.name,
      nameEn: gameChar.nameEn,
      type: gameChar.type,
      imagePath: gameChar.imagePath,
      iconPath: _getCharacterIconPath(gameChar.type), // ✅ إضافة iconPath
      isLocked: false,
      price: 0,
      primaryWeapon: _getPrimaryWeapon(gameChar.type),
      secondaryWeapon: _getSecondaryWeapon(gameChar.type),
      specialAbility: 'هجوم خاص',
      specialAbilityCooldown: 10.0,
      characterColor: _getCharacterColor(gameChar.type),
    );
  }

  void _loadAvailableRooms() {
    _matchmakingService.getAvailableRooms().listen((rooms) {
      if (mounted) {
        setState(() {
          _availableRooms = rooms;
        });
      }
    });
  }

  Future<void> _createRoom() async {
    if (_selectedCharacter == null) return;

    final result = widget.useGlobalMode
        ? await _globalService.createGlobalRoom(
      character: _selectedCharacter!,
      roomName: _roomName,
      maxPlayers: widget.teamSize,
    )
        : await _matchmakingService.createRoomAsHost(
      character: _selectedCharacter!,
      roomName: _roomName,
      maxPlayers: widget.teamSize,
      isPublic: true,
    );

    if (result['success'] == true && mounted) {
      await _connectionService.startAsHost(port: result['roomData']['port']);

      // ✅ أولاً انتقل إلى اختيار الشخصية
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CharacterSelectionScreen(
            gameMode: widget.gameMode ?? '1v1',
            opponentsData: [], // سيتم ملؤها لاحقاً
            roomId: result['roomId'],
            isQuickMatch: false,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'فشل في إنشاء الغرفة')),
      );
    }
  }

// في دالة _joinRoom
  Future<void> _joinRoom(Map<String, dynamic> room) async {
    // ✅ أولاً انتقل إلى اختيار الشخصية
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CharacterSelectionScreen(
          gameMode: widget.gameMode ?? '1v1',
          opponentsData: [
            {
              'playerId': room['hostId'] ?? 'host',
              'playerName': room['hostName'] ?? 'المضيف',
              'character': OnlineCharacter.getDefaultCharacter(),
              'isBot': false,
            }
          ],
          roomId: room['roomId'],
          isQuickMatch: false,
        ),
      ),
    );
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
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        width: size.width,
        height: size.height,
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
            padding: EdgeInsets.all(_responsiveWidth(0.03)),
            child: Column(
              children: [
                // ✅ إضافة زر اختيار النمط
                _buildModeSelector(),
                // Header - مضغوط
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white, size: _responsiveWidth(0.05)),
                      onPressed: () {
                        _connectionService.disconnect();
                        Navigator.pop(context);
                      },
                    ),
                    SizedBox(width: _responsiveWidth(0.02)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.gameMode == '2v2' ? '🎮 فريق 2v2' : '🎮 غرف P2P',
                          style: TextStyle(
                            fontSize: _responsiveText(20),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (widget.gameMode == '2v2')
                          Text(
                            'فريق ضد فريق - 4 لاعبين',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: _responsiveText(12),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: _responsiveHeight(0.02)),

                // ✅ إزالة اختيار الشخصية (مربع عالماشي السرعة)

                if (_isLoading)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.yellow, strokeWidth: 2),
                          SizedBox(height: _responsiveHeight(0.02)),
                          Text(
                            'جاري تحميل البيانات...',
                            style: TextStyle(color: Colors.white, fontSize: _responsiveText(12)),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: DefaultTabController(
                      length: 2,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TabBar(
                              labelColor: Colors.white,
                              unselectedLabelColor: Colors.white70,
                              indicator: BoxDecoration(
                                color: Colors.blue.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              tabs: [
                                Tab(
                                  icon: Icon(Icons.add, size: _responsiveWidth(0.04)),
                                  text: 'إنشاء غرفة',
                                ),
                                Tab(
                                  icon: Icon(Icons.search, size: _responsiveWidth(0.04)),
                                  text: 'الغرف (${_availableRooms.length})',
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: _responsiveHeight(0.01)),
                          Expanded(
                            child: TabBarView(
                              children: [
                                _buildCreateRoomTab(l10n),
                                _buildAvailableRoomsTab(l10n),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ دالة لبناء منتقي النمط
  Widget _buildModeSelector() {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.useGlobalMode ? Icons.public : Icons.wifi,
            color: widget.useGlobalMode ? Colors.green : Colors.blue,
            size: 20,
          ),
          SizedBox(width: 8),
          Text(
            widget.useGlobalMode ? '🌍 عالمي' : '📶 محلي',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateRoomTab(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(_responsiveWidth(0.03)),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              labelText: 'اسم الغرفة',
              labelStyle: TextStyle(color: Colors.white70, fontSize: _responsiveText(12)),
              hintText: widget.gameMode == '2v2' ? 'اسم فريق 2v2' : 'أدخل اسم الغرفة',
              hintStyle: TextStyle(color: Colors.white54, fontSize: _responsiveText(11)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.blue),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            style: TextStyle(color: Colors.white, fontSize: _responsiveText(12)),
            onChanged: (value) => _roomName = value,
          ),

          SizedBox(height: _responsiveHeight(0.02)),

          Container(
            padding: EdgeInsets.all(_responsiveWidth(0.03)),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildRoomInfoItem(
                    Icons.people,
                    '${widget.teamSize} لاعبين',
                    'الحد الأقصى'
                ),
                SizedBox(height: _responsiveHeight(0.01)),
                _buildRoomInfoItem(
                    Icons.groups,
                    widget.gameMode == '2v2' ? '2v2 فريق' : '1v1 فردي',
                    'نوع المباراة'
                ),
                SizedBox(height: _responsiveHeight(0.01)),
                _buildRoomInfoItem(Icons.public, 'عامة', 'نوع الغرفة'),
                SizedBox(height: _responsiveHeight(0.01)),
                _buildRoomInfoItem(Icons.security, 'P2P', 'نوع الاتصال'),
              ],
            ),
          ),

          SizedBox(height: _responsiveHeight(0.03)),

          ElevatedButton.icon(
            icon: Icon(Icons.add_circle_outline, size: _responsiveWidth(0.04)),
            label: Text(
              widget.gameMode == '2v2' ? 'إنشاء فريق 2v2' : 'إنشاء غرفة جديدة',
              style: TextStyle(fontSize: _responsiveText(13)),
            ),
            onPressed: _createRoom,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.gameMode == '2v2' ? Colors.purple : Colors.green,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                  horizontal: _responsiveWidth(0.06),
                  vertical: _responsiveHeight(0.015)
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomInfoItem(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: _responsiveWidth(0.04)),
        SizedBox(width: _responsiveWidth(0.02)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: _responsiveText(12),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: _responsiveText(10),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableRoomsTab(AppLocalizations l10n) {
    if (_availableRooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
                widget.gameMode == '2v2' ? Icons.groups : Icons.search_off,
                color: Colors.white54,
                size: _responsiveWidth(0.1)
            ),
            SizedBox(height: _responsiveHeight(0.02)),
            Text(
              widget.gameMode == '2v2' ? 'لا توجد فرق 2v2 متاحة' : 'لا توجد غرف متاحة',
              style: TextStyle(color: Colors.white54, fontSize: _responsiveText(13)),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: _responsiveHeight(0.01)),
            Text(
              'يمكنك إنشاء ${widget.gameMode == '2v2' ? 'فريق جديد' : 'غرفة جديدة'}',
              style: TextStyle(color: Colors.white38, fontSize: _responsiveText(11)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(_responsiveWidth(0.01)),
      itemCount: _availableRooms.length,
      itemBuilder: (context, index) {
        final room = _availableRooms[index];
        final is2v2Room = room['maxPlayers'] == 4;
        final isFull = room['currentPlayers'] >= room['maxPlayers'];

        return Card(
          color: Colors.white.withOpacity(0.05),
          margin: EdgeInsets.symmetric(
              vertical: _responsiveHeight(0.005),
              horizontal: _responsiveWidth(0.01)
          ),
          child: ListTile(
            contentPadding: EdgeInsets.all(_responsiveWidth(0.02)),
            leading: Container(
              padding: EdgeInsets.all(_responsiveWidth(0.02)),
              decoration: BoxDecoration(
                color: is2v2Room ? Colors.purple.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                is2v2Room ? Icons.groups : Icons.people,
                color: is2v2Room ? Colors.purple : Colors.blue,
                size: _responsiveWidth(0.05),
              ),
            ),
            title: Row(
              children: [
                if (is2v2Room)
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: _responsiveWidth(0.015),
                        vertical: _responsiveHeight(0.003)
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '2v2',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _responsiveText(9),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                SizedBox(width: _responsiveWidth(0.01)),
                Expanded(
                  child: Text(
                    room['roomName'] ?? 'غرفة بدون اسم',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: _responsiveText(12),
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'اللاعبون: ${room['currentPlayers']}/${room['maxPlayers']}',
                  style: TextStyle(color: Colors.white70, fontSize: _responsiveText(11)),
                ),
                if (room['hostName'] != null)
                  Text(
                    'المضيف: ${room['hostName']}',
                    style: TextStyle(color: Colors.white54, fontSize: _responsiveText(10)),
                  ),
              ],
            ),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isFull ? Colors.grey : (is2v2Room ? Colors.purple : Colors.green),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: EdgeInsets.symmetric(
                    horizontal: _responsiveWidth(0.02),
                    vertical: _responsiveHeight(0.005)
                ),
              ),
              child: Text(
                isFull ? 'ممتلئة' : (is2v2Room ? 'انضم' : 'انضم'),
                style: TextStyle(fontSize: _responsiveText(10)),
              ),
              onPressed: isFull ? null : () => _joinRoom(room),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _connectionService.dispose();
    super.dispose();
  }
}