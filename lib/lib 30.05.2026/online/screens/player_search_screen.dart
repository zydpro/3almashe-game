// lib/online/screens/player_search_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../Languages/localization.dart';
import '../services/friends_service.dart';

class PlayerSearchScreen extends StatefulWidget {
  const PlayerSearchScreen({super.key});

  @override
  State<PlayerSearchScreen> createState() => _PlayerSearchScreenState();
}

class _PlayerSearchScreenState extends State<PlayerSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  String _searchError = '';

  // ✅ البحث عن لاعبين
  void _searchPlayers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _searchError = '';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchError = '';
    });

    try {
      final results = await FriendsService.searchPlayers(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _searchError = 'خطأ في البحث: $e';
        _isSearching = false;
      });
    }
  }

  // ✅ إرسال طلب صداقة
  void _sendFriendRequest(String userId, String userName) async {
    final success = await FriendsService.sendFriendRequest(userId);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إرسال طلب صداقة إلى $userName'),
          backgroundColor: Colors.green,
        ),
      );

      // إزالة النتيجة من القائمة
      setState(() {
        _searchResults.removeWhere((player) => player['userId'] == userId);
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل في إرسال طلب الصداقة'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ✅ بناء بطاقة لاعب مع Username
  Widget _buildPlayerCard(Map<String, dynamic> player) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: Colors.white.withOpacity(0.05),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withOpacity(0.3),
          backgroundImage: player['photoURL'] != null
              ? NetworkImage(player['photoURL'])
              : null,
          child: player['photoURL'] == null
              ? Icon(Icons.person, color: Colors.white70)
              : null,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ الاسم الرئيسي
            Text(
              player['displayName'] ?? 'لاعب',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            // ✅ Username (إذا موجود)
            if (player['username'] != null && player['username'].isNotEmpty)
              Text(
                '@${player['username']}',
                style: TextStyle(
                  color: Colors.blue[300],
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ الإيميل (يظهر فقط إذا لم يكن هناك username)
            if (player['username'] == null || player['username'].isEmpty)
              Text(
                player['email'] ?? '',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            SizedBox(height: 4),
            // ✅ الإحصائيات
            Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.yellow, size: 12),
                SizedBox(width: 4),
                Text(
                  'أعلى نتيجة: ${player['gameStats']?['highScore'] ?? 0}',
                  style: TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ],
            ),
            SizedBox(height: 2),
            // ✅ حالة الاتصال
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: player['isOnline'] == true ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 4),
                Text(
                  player['isOnline'] == true ? 'متصل الآن' : 'غير متصل',
                  style: TextStyle(
                    color: player['isOnline'] == true ? Colors.green : Colors.grey,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            // ✅ المستوى (معلومة إضافية)
            SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.star, color: Colors.orange, size: 10),
                SizedBox(width: 4),
                Text(
                  'المستوى: ${player['gameStats']?['currentLevel'] ?? 1}',
                  style: TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => _sendFriendRequest(player['userId'], player['displayName']),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'إضافة صديق',
            style: TextStyle(fontSize: 10),
          ),
        ),
      ),
    );
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
                        '🔍 البحث عن لاعبين',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ✅ حقل البحث
              Padding(
                padding: EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'ابحث بالاسم أو الإيميل...',
                    hintStyle: TextStyle(color: Colors.white70),
                    prefixIcon: Icon(Icons.search, color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                  style: TextStyle(color: Colors.white),
                  onChanged: _searchPlayers,
                ),
              ),

              // ✅ رسالة خطأ
              if (_searchError.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(16),
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _searchError,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),

              // ✅ نتائج البحث
              Expanded(
                child: _isSearching
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.blue),
                      SizedBox(height: 16),
                      Text(
                        'جاري البحث...',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                )
                    : _searchResults.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        color: Colors.white38,
                        size: 80,
                      ),
                      SizedBox(height: 16),
                      Text(
                        _searchController.text.isEmpty
                            ? '🔍 ابحث عن لاعبين بالاسم أو الإيميل'
                            : '❌ لم يتم العثور على لاعبين',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_searchController.text.isEmpty)
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'يمكنك إضافة أصدقاء للعب معهم أو تحدي بعضكم البعض',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                )
                    : ListView.builder(
                  padding: EdgeInsets.only(bottom: 16),
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    return _buildPlayerCard(_searchResults[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}