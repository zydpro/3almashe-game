// lib/online/widgets/searching_dialog_enhanced.dart
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class SearchingRealPlayerEnhanced extends StatefulWidget {
  final String gameMode;
  final Function() onCancel;

  const SearchingRealPlayerEnhanced({
    super.key,
    required this.gameMode,
    required this.onCancel,
  });

  @override
  State<SearchingRealPlayerEnhanced> createState() => _SearchingRealPlayerEnhanced();
}

class _SearchingRealPlayerEnhanced extends State<SearchingRealPlayerEnhanced>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  int _dotsCount = 0;
  String _searchStatus = 'جاري البحث عن لاعبين...';
  Timer? _statusTimer;
  Timer? _dotsTimer;

  @override
  void initState() {
    super.initState();

    // ✅ أنيميشن
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _colorAnimation = ColorTween(
      begin: Colors.blueAccent,
      end: Colors.purpleAccent,
    ).animate(_animationController);

    // ✅ تغيير حالة البحث تلقائياً
    _statusTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      final statuses = [
        'جاري البحث عن لاعبين...',
        'يبحث في السيرفرات القريبة...',
        'تحقق من اللاعبين المتاحين...',
        'جاري العثور على خصم مناسب...',
        'أصبح البحث أكثر نشاطاً...',
      ];

      if (mounted) {
        setState(() {
          _searchStatus = statuses[Random().nextInt(statuses.length)];
        });
      }
    });

    // ✅ أنيميشن النقاط
    _dotsTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          _dotsCount = (_dotsCount + 1) % 4;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _statusTimer?.cancel();
    _dotsTimer?.cancel();
    super.dispose();
  }

  String _getDots() {
    return '.' * _dotsCount;
  }

  @override
  Widget build(BuildContext context) {
    final is1v1 = widget.gameMode == '1v1';
    final title = is1v1 ? 'بحث عن خصم 1 ضد 1' : 'بحث عن فريق 2 ضد 2';
    final subtitle = is1v1
        ? 'مواجهة مثيرة مع لاعب حقيقي'
        : 'معركة جماعية مع لاعبين حقيقيين';

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 280, // ✅ تصغير من 300 إلى 280
                minWidth: 280, // ✅ تصغير من 300 إلى 280
              ),
              child: Container(
                padding: EdgeInsets.all(20), // ✅ تصغير من 25 إلى 20
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1a1a2e).withOpacity(0.95),
                      Color(0xFF16213e).withOpacity(0.95),
                      Color(0xFF0f3460).withOpacity(0.95),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(25), // ✅ تصغير من 30 إلى 25
                  border: Border.all(
                    color: _colorAnimation.value!.withOpacity(0.6),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _colorAnimation.value!.withOpacity(0.4),
                      blurRadius: 25, // ✅ تصغير من 30 إلى 25
                      spreadRadius: 4, // ✅ تصغير من 5 إلى 4
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15, // ✅ تصغير من 20 إلى 15
                      offset: Offset(0, 8), // ✅ تصغير من 10 إلى 8
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ✅ الرأس مع الأيقونة المتحركة (مصغر)
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // 🔄 الدائرة الخارجية الدوارة (مصغرة)
                        Container(
                          width: 80, // ✅ تصغير من 100 إلى 80
                          height: 80, // ✅ تصغير من 100 إلى 80
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: SweepGradient(
                              colors: [
                                Colors.blueAccent.withOpacity(0.3),
                                Colors.purpleAccent.withOpacity(0.3),
                                Colors.blueAccent.withOpacity(0.3),
                              ],
                              stops: [0.0, 0.5, 1.0],
                            ),
                          ),
                          child: CircularProgressIndicator(
                            strokeWidth: 3, // ✅ تصغير من 4 إلى 3
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _colorAnimation.value!,
                            ),
                          ),
                        ),

                        // 🎮 الأيقونة المركزية (مصغرة)
                        Container(
                          width: 50, // ✅ تصغير من 60 إلى 50
                          height: 50, // ✅ تصغير من 60 إلى 50
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.blueAccent,
                                Colors.purpleAccent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _colorAnimation.value!.withOpacity(0.5),
                                blurRadius: 12, // ✅ تصغير من 15 إلى 12
                                spreadRadius: 2, // ✅ تصغير من 3 إلى 2
                              ),
                            ],
                          ),
                          child: Icon(
                            is1v1 ? Icons.person_search : Icons.people_alt,
                            color: Colors.white,
                            size: 26, // ✅ تصغير من 30 إلى 26
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 12), // ✅ تصغير من 18 إلى 12

                    // ✅ العنوان (مصغر)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18, // ✅ تصغير من 22 إلى 18
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 8, // ✅ تصغير من 10 إلى 8
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 2), // ✅ تصغير من 4 إلى 2

                    // ✅ الوصف (مصغر)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12, // ✅ تصغير من 14 إلى 12
                        ),
                      ),
                    ),

                    SizedBox(height: 6), // ✅ تصغير من 8 إلى 6

                    // ✅ مؤشر البحث (مصغر)
                    Container(
                      padding: EdgeInsets.all(10), // ✅ تصغير من 15 إلى 10
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12), // ✅ تصغير من 15 إلى 12
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 🔍 حالة البحث (مصغرة)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.search,
                                color: Colors.cyan,
                                size: 16, // ✅ تصغير من 18 إلى 16
                              ),
                              SizedBox(width: 6), // ✅ تصغير من 8 إلى 6
                              Flexible(
                                child: Text(
                                  '$_searchStatus$_getDots',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13, // ✅ تصغير من 15 إلى 13
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1, // ✅ تغيير من 2 إلى 1
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 8), // ✅ تصغير من 12 إلى 8

                          // ⏱️ مؤقت تقديري (مصغر)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.timer,
                                color: Colors.amber,
                                size: 12, // ✅ تصغير من 14 إلى 12
                              ),
                              SizedBox(width: 4), // ✅ تصغير من 5 إلى 4
                              Flexible(
                                child: Text(
                                  'الوقت المتوقع: < 30 ثانية',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11, // ✅ تصغير من 12 إلى 11
                                    fontStyle: FontStyle.italic,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 4), // ✅ تصغير من 6 إلى 4

                          // 📊 إحصاءات محاكاة (مصغرة)
                          Wrap(
                            spacing: 6, // ✅ تصغير من 8 إلى 6
                            runSpacing: 4, // ✅ تصغير من 8 إلى 4
                            alignment: WrapAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3), // ✅ تصغير
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8), // ✅ تصغير من 10 إلى 8
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.people, size: 10, color: Colors.green), // ✅ تصغير من 12 إلى 10
                                    SizedBox(width: 3), // ✅ تصغير من 4 إلى 3
                                    Text(
                                      '${Random().nextInt(50) + 20} لاعب متصل',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 10, // ✅ تصغير من 11 إلى 10
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3), // ✅ تصغير
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8), // ✅ تصغير من 10 إلى 8
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.speed, size: 10, color: Colors.blue), // ✅ تصغير من 12 إلى 10
                                    SizedBox(width: 3), // ✅ تصغير من 4 إلى 3
                                    Text(
                                      'بينج: ${Random().nextInt(50) + 20}ms',
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontSize: 10, // ✅ تصغير من 11 إلى 10
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 6), // ✅ تصغير من 8 إلى 6

                    // ✅ زر الإلغاء (مصغر)
                    Container(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: widget.onCancel,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.9),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16), // ✅ تصغير من 14,20 إلى 10,16
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10), // ✅ تصغير من 12 إلى 10
                          ),
                          elevation: 4, // ✅ تصغير من 5 إلى 4
                          shadowColor: Colors.red.withOpacity(0.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.close, size: 16), // ✅ تصغير من 18 إلى 16
                            SizedBox(width: 6), // ✅ تصغير من 8 إلى 6
                            Flexible(
                              child: Text(
                                'إلغاء البحث',
                                style: TextStyle(
                                  fontSize: 13, // ✅ تصغير من 15 إلى 13
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
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
          );
        },
      ),
    );
  }
}