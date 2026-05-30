// lib/online/screens/friends_list_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../Languages/localization.dart';
import '../../Languages/LanguageProvider.dart';
import '../services/friends_service.dart';
import '../services/global_matchmaking_service.dart';
import '../models/online_character_system.dart';
import 'player_search_screen.dart';

class FriendsListScreen extends StatefulWidget {
  const FriendsListScreen({super.key});

  @override
  State<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen> {
  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _friendRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    setState(() {
      _isLoading = true;
    });

    // ستحمل البيانات من الـ Streams مباشرة
    setState(() {
      _isLoading = false;
    });
  }

  // ✅ تحميل الشخصية المختارة
  Future<OnlineCharacter> _getSelectedCharacter() async {
    // هنا يمكنك استدعاء خدمة الشخصيات الخاصة بك
    // هذا مثال مؤقت
    return OnlineCharacter.getAllOnlineCharacters().firstWhere(
          (char) => !char.isLocked,
      orElse: () => OnlineCharacter.getDefaultCharacter(),
    );
  }

  // ✅ بدء مباراة مع صديق
  void _startGameWithFriend(String friendId, String gameMode) async {
    try {
      final character = await _getSelectedCharacter();

      final result = await GlobalMatchmakingService.createFriendMatch(
        friendId,
        character,
        gameMode,
      );

      if (result['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إرسال دعوة للعب إلى الصديق'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'فشل في إرسال الدعوة'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إرسال الدعوة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ عرض قائمة الأصدقاء
  Widget _buildFriendsList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FriendsService.getFriendsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Colors.blue));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, color: Colors.white38, size: 80),
                SizedBox(height: 16),
                Text(
                  'لا يوجد أصدقاء بعد',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'ابحث عن لاعبين وأضفهم كأصدقاء',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final friends = snapshot.data!;
        return ListView.builder(
          padding: EdgeInsets.all(8),
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friend = friends[index];
            return _buildFriendCard(friend);
          },
        );
      },
    );
  }

  // ✅ بناء بطاقة صديق
  Widget _buildFriendCard(Map<String, dynamic> friend) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Colors.white.withOpacity(0.05),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withOpacity(0.3),
          backgroundImage: friend['photoURL'] != null
              ? NetworkImage(friend['photoURL'])
              : null,
          child: friend['photoURL'] == null
              ? Icon(Icons.person, color: Colors.white70)
              : null,
        ),
        title: Text(
          friend['displayName'] ?? 'صديق',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: friend['isOnline'] == true ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 6),
                Text(
                  friend['isOnline'] == true ? 'متصل الآن' : 'آخر ظهور: ${_formatTime(friend['lastSeen'])}',
                  style: TextStyle(
                    color: friend['isOnline'] == true ? Colors.green : Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.yellow, size: 14),
                SizedBox(width: 4),
                Text(
                  'أعلى نتيجة: ${friend['gameStats']?['highScore'] ?? 0}',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Colors.white70),
          color: Colors.grey[900],
          onSelected: (value) {
            if (value == 'play_1v1') {
              _startGameWithFriend(friend['userId'], '1v1');
            } else if (value == 'play_2v2') {
              _startGameWithFriend(friend['userId'], '2v2');
            } else if (value == 'remove') {
              _removeFriend(friend['userId'], friend['displayName']);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'play_1v1',
              child: Row(
                children: [
                  Icon(Icons.sports_esports, color: Colors.green),
                  SizedBox(width: 8),
                  Text('تحدي 1v1'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'play_2v2',
              child: Row(
                children: [
                  Icon(Icons.groups, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('تحدي 2v2'),
                ],
              ),
            ),
            PopupMenuDivider(),
            PopupMenuItem(
              value: 'remove',
              child: Row(
                children: [
                  Icon(Icons.person_remove, color: Colors.red),
                  SizedBox(width: 8),
                  Text('إزالة صديق'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ عرض طلبات الصداقة
  Widget _buildFriendRequests() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FriendsService.getFriendRequestsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Colors.orange));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'لا توجد طلبات صداقة جديدة',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        final requests = snapshot.data!;
        return ListView.builder(
          padding: EdgeInsets.all(8),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return _buildFriendRequestCard(request);
          },
        );
      },
    );
  }

  // ✅ بناء بطاقة طلب صداقة
  Widget _buildFriendRequestCard(Map<String, dynamic> request) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Colors.orange.withOpacity(0.1),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.withOpacity(0.3),
          backgroundImage: request['fromUserPhoto'] != null
              ? NetworkImage(request['fromUserPhoto'])
              : null,
          child: request['fromUserPhoto'] == null
              ? Icon(Icons.person_add, color: Colors.orange)
              : null,
        ),
        title: Text(
          request['fromUserName'] ?? 'لاعب',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'يريد إضافتك كصديق',
          style: TextStyle(color: Colors.white70),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.check, color: Colors.green),
              onPressed: () => _acceptFriendRequest(request['requestId']),
            ),
            IconButton(
              icon: Icon(Icons.close, color: Colors.red),
              onPressed: () => _rejectFriendRequest(request['requestId']),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ قبول طلب صداقة
  void _acceptFriendRequest(String requestId) async {
    final success = await FriendsService.acceptFriendRequest(requestId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم قبول طلب الصداقة'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // ✅ رفض طلب صداقة
  void _rejectFriendRequest(String requestId) async {
    final success = await FriendsService.rejectFriendRequest(requestId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم رفض طلب الصداقة'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // ✅ إزالة صديق
  void _removeFriend(String friendId, String friendName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('إزالة صديق', style: TextStyle(color: Colors.white)),
        content: Text('هل أنت متأكد من إزالة $friendName من قائمة الأصدقاء؟',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('إزالة', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await FriendsService.removeFriend(friendId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إزالة $friendName من الأصدقاء'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return 'غير معروف';
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'الآن';
    if (difference.inMinutes < 60) return 'منذ ${difference.inMinutes} دقيقة';
    if (difference.inHours < 24) return 'منذ ${difference.inHours} ساعة';
    return 'منذ ${difference.inDays} يوم';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
          ),
          child: SafeArea(
            child: Column(
              children: [
                // ✅ الهيدر
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[800]!, Colors.blue[900]!],
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          '👥 الأصدقاء',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.person_add, color: Colors.white),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => PlayerSearchScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // ✅ تبويبات
                Container(
                  color: Colors.white.withOpacity(0.05),
                  child: TabBar(
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    indicatorColor: Colors.blue,
                    tabs: [
                      Tab(
                        icon: Icon(Icons.people),
                        text: 'الأصدقاء',
                      ),
                      Tab(
                        icon: Icon(Icons.person_add),
                        text: 'طلبات الصداقة',
                      ),
                    ],
                  ),
                ),

                // ✅ المحتوى
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildFriendsList(),
                      _buildFriendRequests(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}