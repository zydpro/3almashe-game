// // lib/online/screens/MatchmakingScreen.dart
// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../firebase/MatchmakingFirebaseService.dart';
// import 'character_selection_screen.dart';
//
// class MatchmakingScreen extends StatefulWidget {
//   final String gameMode;
//   final int teamSize;
//
//   const MatchmakingScreen({
//     super.key,
//     required this.gameMode,
//     required this.teamSize,
//   });
//
//   @override
//   State<MatchmakingScreen> createState() => _MatchmakingScreenState();
// }
//
// class _MatchmakingScreenState extends State<MatchmakingScreen>
//     with SingleTickerProviderStateMixin {
//
//   // final MatchmakingFirebaseService _matchmakingService = MatchmakingFirebaseService();
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//
//   Timer? _searchTimer;
//   int _searchTime = 0;
//   bool _isSearching = false;
//   String _searchStatus = 'جاري التحضير...';
//   AnimationController? _animationController;
//   int _playersFound = 0;
//   int _playersNeeded = 2;
//
//   // ✅ متغيرات جديدة
//   bool _isOfflineMode = false;
//   bool _isLocalMatch = false;
//   int _opponentsFound = 0;
//   int _opponentsNeeded = 1;
//
//   @override
//   void initState() {
//     super.initState();
//
//     // ✅ حساب الأرقام الصحيحة
//     if (widget.gameMode == '1v1') {
//       _playersNeeded = 2;  // الإجمالي النهائي: أنا + 1 خصم
//       _opponentsNeeded = 1; // نحتاج خصم واحد فقط
//     } else if (widget.gameMode == '2v2') {
//       _playersNeeded = 4;  // الإجمالي النهائي: أنا + 3 خصوم
//       _opponentsNeeded = 3; // نحتاج 3 خصوم
//     }
//
//     // ✅ التحقق من الاتصال
//     _checkConnectionStatus();
//
//     _initializeAnimations();
//
//     // ✅ بدء البحث بعد تأخير قصير
//     // Future.delayed(Duration(milliseconds: 800), () {
//     //   if (mounted) {
//     //     _startMatchmaking();
//     //   }
//     // });
//   }
//
//   // ✅ دالة: التحقق من حالة الاتصال
//   Future<void> _checkConnectionStatus() async {
//     try {
//       // محاولة بسيطة للتحقق من اتصال Firebase
//       await FirebaseFirestore.instance
//           .collection('connection_test')
//           .limit(1)
//           .get()
//           .timeout(Duration(seconds: 3));
//
//       setState(() {
//         _isOfflineMode = false;
//       });
//       print('🌐 متصل بـ Firebase بنجاح');
//     } catch (e) {
//       setState(() {
//         _isOfflineMode = true;
//       });
//       print('📴 وضع عدم الاتصال: $e');
//     }
//   }
//
//   void _initializeAnimations() {
//     _animationController = AnimationController(
//       duration: const Duration(seconds: 2),
//       vsync: this,
//     )..repeat();
//   }
//
//   // void _startMatchmaking() async {
//   //   if (!mounted) return;
//   //
//   //   setState(() {
//   //     _isSearching = true;
//   //     _playersFound = 1; // اللاعب الحالي
//   //     _opponentsFound = 0;
//   //
//   //     // ✅ رسالة بدء البحث المناسبة
//   //     if (_opponentsNeeded == 1) {
//   //       _searchStatus = _isOfflineMode
//   //           ? '🔍 جاري البحث عن خصم محلي...'
//   //           : '🔍 جاري البحث عن خصم...';
//   //     } else {
//   //       _searchStatus = _isOfflineMode
//   //           ? '🔍 جاري البحث عن $_opponentsNeeded خصوم محليين...'
//   //           : '🔍 جاري البحث عن $_opponentsNeeded خصوم...';
//   //     }
//   //   });
//   //
//   //   print('🎮 ==== بدء البحث عن مباراة ====');
//   //   print('🎯 نمط اللعبة: ${widget.gameMode}');
//   //   print('👤 أنا + $_opponentsNeeded خصم = $_playersNeeded لاعبين');
//   //   print('🌐 الوضع: ${_isOfflineMode ? "محلي" : "متصل"}');
//   //
//   //   try {
//   //     await _matchmakingService.joinMatchmakingQueue(
//   //       gameMode: widget.gameMode,
//   //       onMatchFound: _onMatchFound,
//   //       onStatusUpdate: _onQueueUpdate,
//   //     );
//   //   } catch (e) {
//   //     print('⚠️ خطأ في بدء البحث: $e');
//   //     _handleSearchError();
//   //   }
//   //
//   //   _startTimer();
//   // }
//
//   // ✅ دالة: تحديث حالة القائمة
//   void _onQueueUpdate(int playersFound, int playersNeeded, String status) {
//     if (!mounted) return;
//
//     final newOpponentsFound = playersFound - 1; // استبعاد اللاعب الحالي
//
//     setState(() {
//       _playersFound = playersFound;
//       _playersNeeded = playersNeeded;
//       _opponentsFound = newOpponentsFound;
//
//       // ✅ تحديث الرسالة بناءً على التقدم
//       if (newOpponentsFound >= _opponentsNeeded) {
//         _searchStatus = '🎉 تم العثور على جميع الخصوم!';
//       } else if (newOpponentsFound > 0) {
//         if (_opponentsNeeded == 1) {
//           _searchStatus = '✅ وجدنا خصماً واحداً...';
//         } else {
//           _searchStatus = '✅ وجدنا $newOpponentsFound من أصل $_opponentsNeeded خصوم...';
//         }
//       } else {
//         _searchStatus = status;
//       }
//     });
//
//     print('📊 التقدم: $_playersFound/$_playersNeeded لاعب ($newOpponentsFound خصم)');
//   }
//
//   // void _startTimer() {
//   //   _searchTimer?.cancel();
//   //   _searchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
//   //     if (!mounted) {
//   //       timer.cancel();
//   //       return;
//   //     }
//   //
//   //     setState(() {
//   //       _searchTime++;
//   //     });
//   //
//   //     _updateSearchStatus();
//   //
//   //     // ✅ إذا تجاوز الوقت 120 ثانية، توقف
//   //     if (_searchTime >= 120) {
//   //       _showTimeoutDialog();
//   //       timer.cancel();
//   //     }
//   //   });
//   // }
//
//   void _updateSearchStatus() {
//     if (!mounted) return;
//
//     // ✅ إذا وجدنا جميع الخصوم، لا نغير الرسالة
//     if (_opponentsFound >= _opponentsNeeded) {
//       return;
//     }
//
//     // ✅ رسائل بناءً على وقت البحث
//     if (_searchTime < 10) {
//       // لا تغيير (الرسالة الأساسية من _onQueueUpdate)
//     } else if (_searchTime < 30) {
//       if (_opponentsFound > 0) {
//         // الرسالة تبقى كما هي من _onQueueUpdate
//       } else {
//         setState(() {
//           _searchStatus = '⚡ مستمرون في البحث...';
//         });
//       }
//     } else if (_searchTime < 60) {
//       setState(() {
//         _searchStatus = '🌍 نوسع نطاق البحث...';
//       });
//     } else {
//       setState(() {
//         if (_opponentsNeeded == 1) {
//           _searchStatus = '⏳ وقت البحث طويل...';
//         } else {
//           _searchStatus = '⏳ وقت البحث طويل ($_opponentsFound/$_opponentsNeeded)...';
//         }
//       });
//
//       // ✅ بعد 60 ثانية، عرض خيار الاستمرار
//       if (_searchTime == 60) {
//         _showContinueSearchDialog();
//       }
//     }
//   }
//
//   // ✅ دالة: عرض خيار الاستمرار في البحث
//   void _showContinueSearchDialog() {
//     if (!mounted) return;
//
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         title: Text('وقت البحث طويل'),
//         content: Text(
//             _opponentsNeeded == 1
//                 ? 'لم نتمكن من العثور على خصم بعد 60 ثانية.\nهل تريد الاستمرار في البحث؟'
//                 : 'لم نتمكن من العثور على خصوم كافيين بعد 60 ثانية.\nهل تريد الاستمرار في البحث؟'
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               _cancelSearch();
//             },
//             child: Text('إلغاء البحث'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(context);
//               setState(() {
//                 _searchStatus = '⚡ نواصل البحث...';
//               });
//             },
//             child: Text('استمر في البحث'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ✅ دالة: عرض تحذير انتهاء الوقت
//   // void _showTimeoutDialog() {
//   //   if (!mounted) return;
//   //
//   //   showDialog(
//   //     context: context,
//   //     barrierDismissible: false,
//   //     builder: (context) => AlertDialog(
//   //       title: Text('انتهى وقت البحث'),
//   //       content: Text('تجاوز البحث الوقت المحدد (120 ثانية).'),
//   //       actions: [
//   //         ElevatedButton(
//   //           onPressed: () {
//   //             Navigator.pop(context);
//   //             _cancelSearch();
//   //           },
//   //           child: Text('العودة'),
//   //         ),
//   //         TextButton(
//   //           onPressed: () {
//   //             Navigator.pop(context);
//   //             _restartSearch();
//   //           },
//   //           child: Text('إعادة المحاولة'),
//   //         ),
//   //       ],
//   //     ),
//   //   );
//   // }
//
//   // void _onMatchFound(Map<String, dynamic> matchData) {
//   //   if (!mounted) return;
//   //
//   //   print('🎯 تم العثور على مباراة: ${matchData['matchId']}');
//   //   print('📋 حالة المباراة: ${matchData['status']}');
//   //
//   //   // ✅ تأكد من أن المباراة جاهزة
//   //   if (matchData['isMatchReady'] != true) {
//   //     print('⏳ المباراة ليست جاهزة بعد، الانتظار...');
//   //
//   //     // استمع لتحديثات المباراة
//   //     _listenForMatchReady(matchData['matchId'] as String);
//   //     return;
//   //   }
//   //
//   //   _proceedToCharacterSelection(matchData);
//   // }
//
//   // void _listenForMatchReady(String matchId) {
//   //   final matchmakingService = MatchmakingFirebaseService();
//   //
//   //   // ✅ استخدام late للتأخير في التعيين
//   //   late final StreamSubscription matchSubscription;
//   //
//   //   matchSubscription = matchmakingService.listenToMatchUpdates(
//   //     matchId,
//   //         (updatedMatchData) {
//   //       if (updatedMatchData['isMatchReady'] == true) {
//   //         print('✅ المباراة جاهزة الآن!');
//   //
//   //         // ✅ إلغاء الاشتراك
//   //         matchSubscription.cancel();
//   //
//   //         if (mounted) {
//   //           _proceedToCharacterSelection(updatedMatchData);
//   //         }
//   //       }
//   //     },
//   //   );
//   // }
//
//   void _proceedToCharacterSelection(Map<String, dynamic> matchData) {
//     _stopSearching();
//
//     print('🚀 الانتقال لشاشة اختيار الشخصيات...');
//
//     // ✅ الانتقال إلى شاشة اختيار الشخصية
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(
//         builder: (context) => CharacterSelectionScreen(
//           gameMode: widget.gameMode,
//           opponentsData: _prepareOpponentsData(matchData),
//           roomId: matchData['matchId']!,
//           isQuickMatch: false,
//           isMatchmaking: true,
//           matchData: matchData,
//         ),
//       ),
//     );
//   }
//
//   List<Map<String, dynamic>> _prepareOpponentsData(Map<String, dynamic> matchData) {
//     final opponents = <Map<String, dynamic>>[];
//     final players = matchData['players'] as List<dynamic>? ?? [];
//
//     // ✅ الحصول على معرف اللاعب الحالي
//     final currentUser = _auth.currentUser;
//     final currentUserId = currentUser?.uid ?? '';
//
//     print('🔍 فحص ${players.length} لاعب في المباراة');
//     print('🎯 معرف المباراة: ${matchData['matchId']}');
//
//     int opponentCount = 0;
//
//     for (var player in players) {
//       final playerMap = player as Map<String, dynamic>;
//       final playerId = playerMap['playerId']?.toString() ?? '';
//       final playerName = playerMap['playerName']?.toString() ?? 'الخصم';
//       final isRealPlayer = playerMap['isRealPlayer'] == true;
//       final isLocal = playerMap['isLocal'] == true;
//
//       // ✅ استبعاد اللاعب الحالي فقط
//       if (playerId == currentUserId) {
//         print('👤 هذا أنا: $playerName ($playerId)');
//         continue;
//       }
//
//       // ✅ إذا كان لاعباً حقيقياً وغير محلي، أضفه كخصم
//       if (isRealPlayer && !isLocal) {
//         opponentCount++;
//
//         opponents.add({
//           'playerId': playerId,
//           'playerName': playerName,
//           'character': null,
//           'isBot': false, // ✅ هذا ليس بوتاً
//           'isRealPlayer': true,
//           'matchType': 'firebase',
//           'isLocal': false,
//         });
//
//         print('✅ وجد خصم حقيقي #$opponentCount: $playerName ($playerId)');
//       }
//     }
//
//     // ✅ التحقق إذا كان هناك خصوم
//     if (opponents.isEmpty) {
//       print('⚠️ لم يتم العثور على خصوم حقيقيين في المباراة');
//       print('📊 بيانات اللاعبين: $players');
//     }
//
//     print('🎯 إجمالي الخصوم الحقيقيين: ${opponents.length}');
//     return opponents;
//   }
//
//   // void _showError(String message) {
//   //   if (!mounted) return;
//   //
//   //   _stopSearching();
//   //
//   //   showDialog(
//   //     context: context,
//   //     barrierDismissible: false,
//   //     builder: (context) => AlertDialog(
//   //       title: Text('خطأ في البحث'),
//   //       content: Text(message),
//   //       actions: [
//   //         TextButton(
//   //           onPressed: () {
//   //             Navigator.pop(context);
//   //             _cancelSearch();
//   //           },
//   //           child: Text('حسناً'),
//   //         ),
//   //         ElevatedButton(
//   //           onPressed: () {
//   //             Navigator.pop(context);
//   //             _restartSearch();
//   //           },
//   //           child: Text('إعادة المحاولة'),
//   //         ),
//   //       ],
//   //     ),
//   //   );
//   // }
//
//   // void _handleSearchError() {
//   //   if (!mounted) return;
//   //
//   //   _stopSearching();
//   //
//   //   _showError('حدث خطأ في البحث عن لاعبين.\nيرجى المحاولة مرة أخرى.');
//   // }
//
//   // void _restartSearch() {
//   //   if (!mounted) return;
//   //
//   //   setState(() {
//   //     _isSearching = false;
//   //     _searchTime = 0;
//   //     _playersFound = 0;
//   //     _opponentsFound = 0;
//   //     _searchStatus = 'جاري إعادة التشغيل...';
//   //   });
//   //
//   //   // تنظيف البحث السابق
//   //   _matchmakingService.cancelSearch();
//   //
//   //   // بدء بحث جديد بعد تأخير قصير
//   //   Future.delayed(Duration(seconds: 1), () {
//   //     if (mounted) {
//   //       _startMatchmaking();
//   //     }
//   //   });
//   // }
//
//   void _cancelSearch() {
//     _stopSearching();
//     // _matchmakingService.cancelSearch();
//
//     // إخفاء أي رسائل حالية
//     if (Navigator.of(context).canPop()) {
//       Navigator.of(context).pop();
//     }
//
//     // العودة للشاشة السابقة
//     Navigator.pop(context);
//   }
//
//   void _stopSearching() {
//     _searchTimer?.cancel();
//     _searchTimer = null;
//
//     if (_animationController != null) {
//       try {
//         if (_animationController!.isAnimating) {
//           _animationController!.stop();
//         }
//         _animationController!.dispose();
//       } catch (e) {
//         print('⚠️ خطأ في إيقاف AnimationController: $e');
//       } finally {
//         _animationController = null;
//       }
//     }
//   }
//
//   // ✅ دالة: بناء مؤشر حالة النظام
//   Widget _buildSystemIndicator() {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//       decoration: BoxDecoration(
//         color: _isOfflineMode ? Colors.orange.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(
//           color: _isOfflineMode ? Colors.orange : Colors.blue,
//           width: 1,
//         ),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             _isOfflineMode ? Icons.wifi_off : Icons.cloud,
//             color: _isOfflineMode ? Colors.orange : Colors.blue,
//             size: 14,
//           ),
//           SizedBox(width: 4),
//           Text(
//             _isOfflineMode ? 'محلي' : 'متصل',
//             style: TextStyle(
//               color: _isOfflineMode ? Colors.orange : Colors.blue,
//               fontSize: 11,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ✅ دالة: بناء معلومات اللاعبين
//   Widget _buildPlayersInfo() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//       decoration: BoxDecoration(
//         color: Colors.black.withOpacity(0.3),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: _opponentsFound >= _opponentsNeeded
//               ? Colors.green
//               : Colors.orange.withOpacity(0.5),
//           width: 2,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: _opponentsFound >= _opponentsNeeded
//                 ? Colors.green.withOpacity(0.3)
//                 : Colors.orange.withOpacity(0.2),
//             blurRadius: 8,
//             spreadRadius: 1,
//           ),
//         ],
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(
//                 Icons.people,
//                 color: _opponentsFound >= _opponentsNeeded
//                     ? Colors.green
//                     : Colors.orange,
//                 size: 22,
//               ),
//               SizedBox(width: 8),
//               Text(
//                 'اللاعبون',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: 8),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceAround,
//             children: [
//               Column(
//                 children: [
//                   Text(
//                     'الإجمالي',
//                     style: TextStyle(
//                       color: Colors.white70,
//                       fontSize: 12,
//                     ),
//                   ),
//                   SizedBox(height: 4),
//                   Container(
//                     padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                     decoration: BoxDecoration(
//                       color: Colors.blue.withOpacity(0.2),
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(color: Colors.blue),
//                     ),
//                     child: Text(
//                       '$_playersFound/$_playersNeeded',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               Column(
//                 children: [
//                   Text(
//                     'الخصوم',
//                     style: TextStyle(
//                       color: Colors.white70,
//                       fontSize: 12,
//                     ),
//                   ),
//                   SizedBox(height: 4),
//                   Container(
//                     padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                     decoration: BoxDecoration(
//                       color: _opponentsFound >= _opponentsNeeded
//                           ? Colors.green.withOpacity(0.2)
//                           : Colors.orange.withOpacity(0.2),
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(
//                         color: _opponentsFound >= _opponentsNeeded
//                             ? Colors.green
//                             : Colors.orange,
//                       ),
//                     ),
//                     child: Text(
//                       '$_opponentsFound/$_opponentsNeeded',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ✅ دالة: بناء معلومات المباراة
//   Widget _buildMatchInfo() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.05),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: Colors.white.withOpacity(0.1),
//         ),
//       ),
//       child: Column(
//         children: [
//           _buildInfoRow(
//             Icons.sports_esports,
//             'نوع المباراة:',
//             widget.gameMode == '1v1' ? '1 ضد 1' : '2 ضد 2',
//           ),
//           SizedBox(height: 10),
//           _buildInfoRow(
//             Icons.people,
//             'المطلوب:',
//             _opponentsNeeded == 1
//                 ? 'خصم واحد'
//                 : '$_opponentsNeeded خصوم',
//           ),
//           SizedBox(height: 10),
//           _buildInfoRow(
//             Icons.verified,
//             'نوع الخصم:',
//             _isOfflineMode ? 'محلي' : 'لاعب حقيقي',
//             color: _isOfflineMode ? Colors.orange : Colors.green,
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildInfoRow(IconData icon, String label, String value, {Color color = Colors.white}) {
//     return Row(
//       children: [
//         Icon(
//           icon,
//           color: Colors.blueAccent,
//           size: 20,
//         ),
//         SizedBox(width: 10),
//         Expanded(
//           child: Text(
//             label,
//             style: TextStyle(
//               color: Colors.white70,
//               fontSize: 14,
//             ),
//           ),
//         ),
//         Text(
//           value,
//           style: TextStyle(
//             color: color,
//             fontSize: 14,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ],
//     );
//   }
//
//   String _formatTime(int seconds) {
//     final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
//     final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
//     return '$minutes:$remainingSeconds';
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//
//     return Scaffold(
//       body: Container(
//         width: size.width,
//         height: size.height,
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Color(0xFF0f3460),
//               Color(0xFF16213e),
//               Color(0xFF1a1a2e),
//             ],
//           ),
//         ),
//         child: SafeArea(
//           child: Column(
//             children: [
//               // Header
//               Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Row(
//                   children: [
//                     IconButton(
//                       icon: const Icon(Icons.arrow_back, color: Colors.white),
//                       onPressed: _cancelSearch,
//                     ),
//                     SizedBox(width: 10),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text(
//                             '🔍 البحث عن مباراة',
//                             style: TextStyle(
//                               fontSize: 20,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.white,
//                             ),
//                           ),
//                           SizedBox(height: 4),
//                           Text(
//                             widget.gameMode == '2v2'
//                                 ? 'فريق ضد فريق (2 ضد 2)'
//                                 : 'لاعب ضد لاعب (1 ضد 1)',
//                             style: const TextStyle(
//                               color: Colors.white70,
//                               fontSize: 12,
//                             ),
//                           ),
//                           SizedBox(height: 4),
//                           _buildSystemIndicator(),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//
//               Expanded(
//                 child: SingleChildScrollView(
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 16),
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         SizedBox(height: 20),
//
//                         // دائرة البحث المتحركة
//                         if (_animationController != null)
//                           Stack(
//                             alignment: Alignment.center,
//                             children: [
//                               AnimatedBuilder(
//                                 animation: _animationController!,
//                                 builder: (context, child) {
//                                   return Transform.rotate(
//                                     angle: _animationController!.value * 2 * 3.14159,
//                                     child: Container(
//                                       width: 140,
//                                       height: 140,
//                                       decoration: BoxDecoration(
//                                         shape: BoxShape.circle,
//                                         border: Border.all(
//                                           color: _isOfflineMode
//                                               ? Colors.orange
//                                               : Colors.blueAccent,
//                                           width: 4,
//                                         ),
//                                         gradient: RadialGradient(
//                                           colors: _isOfflineMode
//                                               ? [
//                                             Color(0x4DFF9800),
//                                             Color(0x1AFF9800),
//                                             Colors.transparent,
//                                           ]
//                                               : [
//                                             Color(0x4D2196F3),
//                                             Color(0x1A2196F3),
//                                             Colors.transparent,
//                                           ],
//                                           stops: [0.1, 0.5, 1.0],
//                                         ),
//                                       ),
//                                       child: Center(
//                                         child: Icon(
//                                           _isOfflineMode
//                                               ? Icons.person_search
//                                               : Icons.search,
//                                           color: _isOfflineMode
//                                               ? Colors.orange
//                                               : Colors.blueAccent,
//                                           size: 60,
//                                         ),
//                                       ),
//                                     ),
//                                   );
//                                 },
//                               ),
//
//                               // ✅ مؤشر التقدم
//                               Positioned(
//                                 bottom: 5,
//                                 child: Container(
//                                   padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//                                   decoration: BoxDecoration(
//                                     color: Colors.black.withOpacity(0.7),
//                                     borderRadius: BorderRadius.circular(12),
//                                     border: Border.all(color: Colors.white30),
//                                   ),
//                                   child: Text(
//                                     '${_formatTime(_searchTime)}',
//                                     style: TextStyle(
//                                       color: Colors.white,
//                                       fontSize: 12,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//
//                         SizedBox(height: 30),
//
//                         // حالة البحث
//                         Container(
//                           padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                           decoration: BoxDecoration(
//                             color: Colors.black.withOpacity(0.4),
//                             borderRadius: BorderRadius.circular(15),
//                             border: Border.all(
//                               color: _opponentsFound >= _opponentsNeeded
//                                   ? Colors.green
//                                   : Colors.blue.withOpacity(0.5),
//                               width: 2,
//                             ),
//                           ),
//                           child: Text(
//                             _searchStatus,
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                             ),
//                             textAlign: TextAlign.center,
//                           ),
//                         ),
//
//                         SizedBox(height: 20),
//
//                         // معلومات اللاعبين
//                         _buildPlayersInfo(),
//
//                         SizedBox(height: 20),
//
//                         // معلومات المباراة
//                         _buildMatchInfo(),
//
//                         SizedBox(height: 30),
//
//                         // ✅ مؤشر التقدم الزمني
//                         if (_searchTime > 0)
//                           Column(
//                             children: [
//                               LinearProgressIndicator(
//                                 value: (_searchTime / 120).clamp(0.0, 1.0),
//                                 backgroundColor: Colors.grey[800],
//                                 valueColor: AlwaysStoppedAnimation<Color>(
//                                   _searchTime > 90
//                                       ? Colors.orange
//                                       : Colors.blue,
//                                 ),
//                                 minHeight: 6,
//                               ),
//                               SizedBox(height: 8),
//                               Row(
//                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                 children: [
//                                   Text(
//                                     'البداية',
//                                     style: TextStyle(
//                                       color: Colors.white70,
//                                       fontSize: 11,
//                                     ),
//                                   ),
//                                   Text(
//                                     'الحد الأقصى: 120 ثانية',
//                                     style: TextStyle(
//                                       color: _searchTime > 90
//                                           ? Colors.orange
//                                           : Colors.white70,
//                                       fontSize: 11,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//
//               // زر إلغاء البحث
//               Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: _cancelSearch,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.red.withOpacity(0.3),
//                       foregroundColor: Colors.white,
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         side: BorderSide(
//                           color: Colors.red.withOpacity(0.5),
//                           width: 2,
//                         ),
//                       ),
//                       elevation: 3,
//                     ),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.close, size: 20),
//                         SizedBox(width: 8),
//                         Text(
//                           'إلغاء البحث',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _stopSearching();
//     super.dispose();
//   }
// }