import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../widgets/animated_logo.dart';
import 'game_screen.dart';
import 'levels_screen.dart';
import 'settings_screen.dart';
import 'about_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  // إعدادات الظل للأيقونات الجانبية (الزوايا)
  double cornerShadowBlur = 10.0;
  double cornerShadowSpread = 2.0;
  Color cornerShadowColor = Colors.black.withOpacity(0.5);
  Offset cornerShadowOffset = const Offset(2, 2);

  // إعدادات الظل للأيقونات الرئيسية (الوسط) - ظل دائري
  double centerShadowBlur = 15.0;
  double centerShadowSpread = 0.2;
  Color centerShadowColor = Colors.black.withOpacity(0.8);
  Offset centerShadowOffset = const Offset(4, 4);

  // إعدادات الظل للنصوص
  double textShadowBlur = 5.0;
  Color textShadowColor = Colors.black.withOpacity(0.6);
  Offset textShadowOffset = const Offset(1, 1);

  // إعدادات الحجم للأيقونات الجانبية
  double cornerIconSize = 50.0;
  double cornerButtonSize = 60.0;

  // إعدادات الحجم للأيقونات الرئيسية - حجم أكبر
  double mainButtonSize = 120.0;
  double menuButtonSize = 90.0;
  double centerIconSizeMultiplier = 1.2;

  // إعدادات الحجم للنصوص
  double mainTextSize = 18.0;
  double menuTextSize = 16.0;
  double textSizeMultiplier = 1.0;

  // Video Player Controller
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isVideoInitialized = false;
  String _videoError = '';
  bool _isLoading = true;
  bool _hasUserInteracted = false;
  bool _showPlayButton = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() async {
    try {
      print('🚀 بدء تحميل الفيديو...');

      setState(() {
        _isLoading = true;
        _videoError = '';
      });

      _videoPlayerController = VideoPlayerController.asset(
        'assets/images/main_menu/menu_background.mp4',
      );

      // إضافة مستمع لمراقبة حالة الفيديو
      _videoPlayerController.addListener(() {
        if (_videoPlayerController.value.hasError) {
          final error = _videoPlayerController.value.errorDescription ?? 'خطأ غير معروف';
          print('❌ خطأ في الفيديو: $error');
          setState(() {
            _videoError = error;
            _isVideoInitialized = false;
            _isLoading = false;
          });
        }

        // طباعة معلومات التصحيح
        if (_videoPlayerController.value.isInitialized) {
          print('📊 حالة الفيديو:');
          print('  - الأبعاد: ${_videoPlayerController.value.size}');
          print('  - المدة: ${_videoPlayerController.value.duration}');
          print('  - التشغيل: ${_videoPlayerController.value.isPlaying}');
          print('  - التحميل: ${_videoPlayerController.value.isBuffering}');
        }
      });

      print('🔄 جاري تهيئة الفيديو...');
      await _videoPlayerController.initialize();

      print('✅ الفيديو مهيأ: ${_videoPlayerController.value.isInitialized}');

      if (_videoPlayerController.value.isInitialized && !_videoPlayerController.value.hasError) {
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController,
          autoPlay: false, // تم التغيير إلى false لمنع التشغيل التلقائي
          looping: true,
          showControls: false,
          autoInitialize: true,
          allowedScreenSleep: false,
          materialProgressColors: ChewieProgressColors(
            playedColor: Colors.yellow,
            handleColor: Colors.yellow,
            backgroundColor: Colors.white24,
            bufferedColor: Colors.white38,
          ),
          placeholder: Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'جاري تحميل الفيديو...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          errorBuilder: (context, errorMessage) {
            print('🎬 خطأ في Chewie: $errorMessage');
            return _buildErrorWidget(errorMessage);
          },
        );

        // تم إزالة التشغيل التلقائي هنا
        setState(() {
          _isVideoInitialized = true;
          _videoError = '';
          _isLoading = false;
          _showPlayButton = true; // عرض زر التشغيل
        });

        print('✅ الفيديو جاهز - في انتظار تفاعل المستخدم');
      } else {
        final error = _videoPlayerController.value.errorDescription ?? 'الفيديو لم يتم تهيئته بشكل صحيح';
        setState(() {
          _videoError = error;
          _isVideoInitialized = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('💥 خطأ كبير في تحميل الفيديو: $e');
      setState(() {
        _videoError = 'خطأ في تحميل الفيديو: $e';
        _isVideoInitialized = false;
        _isLoading = false;
      });
    }
  }

  void _playVideoAfterInteraction() {
    if (_videoPlayerController.value.isInitialized &&
        !_videoPlayerController.value.isPlaying) {
      _videoPlayerController.play().then((_) {
        print('🎉 الفيديو يعمل الآن بعد تفاعل المستخدم!');
        setState(() {
          _hasUserInteracted = true;
          _showPlayButton = false;
        });
      }).catchError((error) {
        print('❌ خطأ في تشغيل الفيديو: $error');
        setState(() {
          _videoError = 'خطأ في تشغيل الفيديو: $error';
        });
      });
    }
  }

  Widget _buildErrorWidget(String errorMessage) {
    return Container(
      color: Colors.black,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 50),
          SizedBox(height: 16),
          Text(
            '⚠️ خطأ في تشغيل الفيديو',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              errorMessage,
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _initializeVideo,
            icon: Icon(Icons.refresh),
            label: Text('إعادة المحاولة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellow,
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1a2b3c),
            Color(0xFF0d5c7a),
            Color(0xFF048A81),
          ],
          stops: [0.0, 0.6, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // تأثيرات متحركة بسيطة بدلاً من الصورة
          Positioned.fill(
            child: AnimatedContainer(
              duration: Duration(seconds: 3),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.02),
                    Colors.transparent,
                    Colors.white.withOpacity(0.02),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'جاري تحميل الفيديو...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          // تشغيل الفيديو عند أول نقر على الشاشة إذا لم يكن يعمل
          if (_isVideoInitialized &&
              !_videoPlayerController.value.isPlaying &&
              !_hasUserInteracted) {
            _playVideoAfterInteraction();
          }
        },
        child: Stack(
          children: [
            // خلفية الفيديو أو البديلة
            if (_isVideoInitialized && _chewieController != null && _videoError.isEmpty)
              Positioned.fill(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _videoPlayerController.value.size.width,
                    height: _videoPlayerController.value.size.height,
                    child: Chewie(controller: _chewieController!),
                  ),
                ),
              )
            else
              _buildFallbackBackground(),

            // طبقة شفافة فوق الفيديو لجعل المحتوى أكثر وضوحاً
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.05),
              ),
            ),

            // زر التشغيل الكبير
            // if (_showPlayButton && _isVideoInitialized && !_isLoading)
            //   Positioned.fill(
            //     child: Container(
            //       color: Colors.black.withOpacity(0.3),
            //       child: Center(
            //         child: Column(
            //           mainAxisAlignment: MainAxisAlignment.center,
            //           children: [
            //             // GestureDetector(
            //             //   onTap: _playVideoAfterInteraction,
            //             //   child: Container(
            //             //     width: 100,
            //             //     height: 100,
            //             //     decoration: BoxDecoration(
            //             //       color: Colors.yellow.withOpacity(0.9),
            //             //       shape: BoxShape.circle,
            //             //       boxShadow: [
            //             //         BoxShadow(
            //             //           color: Colors.black.withOpacity(0.5),
            //             //           blurRadius: 15,
            //             //           spreadRadius: 2,
            //             //           offset: Offset(0, 4),
            //             //         ),
            //             //       ],
            //             //     ),
            //             //     // child: Icon(
            //             //     //   Icons.play_arrow,
            //             //     //   size: 60,
            //             //     //   color: Colors.black,
            //             //     // ),
            //             //   ),
            //             // ),
            //             SizedBox(height: 20),
            //             // Text(
            //             //   'انقر للتشغيل',
            //             //   style: TextStyle(
            //             //     color: Colors.white,
            //             //     fontSize: 24,
            //             //     fontWeight: FontWeight.bold,
            //             //     shadows: [
            //             //       Shadow(
            //             //         color: Colors.black.withOpacity(0.8),
            //             //         offset: Offset(2, 2),
            //             //         blurRadius: 4,
            //             //       ),
            //             //     ],
            //             //   ),
            //             // ),
            //             SizedBox(height: 10),
            //             // Text(
            //             //   'أو انقر في أي مكان على الشاشة',
            //             //   style: TextStyle(
            //             //     color: Colors.white70,
            //             //     fontSize: 16,
            //             //     shadows: [
            //             //       Shadow(
            //             //         color: Colors.black.withOpacity(0.6),
            //             //         offset: Offset(1, 1),
            //             //         blurRadius: 2,
            //             //       ),
            //             //     ],
            //             //   ),
            //             // ),
            //           ],
            //         ),
            //       ),
            //     ),
            //   ),

            // عرض معلومات الخطأ إذا وجد

            if (_videoError.isNotEmpty && !_isLoading)
              Positioned(
                top: 50,
                left: 20,
                right: 20,
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'مشكلة في الفيديو',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          Spacer(),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.white, size: 18),
                            onPressed: () {
                              setState(() {
                                _videoError = '';
                              });
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        _videoError,
                        style: TextStyle(color: Colors.white, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

            SafeArea(
              child: Stack(
                children: [
                  // Top right - Share icon (أيقونة جانبية)
                  Positioned(
                    top: 20,
                    right: 20,
                    child: _buildCornerIconButton(
                      icon: 'assets/images/main_menu/share_icon.png',
                      onPressed: () {
                        _shareGame(context);
                      },
                    ),
                  ),

                  // Top left - Like icon (أيقونة جانبية)
                  Positioned(
                    top: 20,
                    left: 20,
                    child: _buildCornerIconButton(
                      icon: 'assets/images/main_menu/like_icon.png',
                      onPressed: () {
                        _openLikeLink(context);
                      },
                    ),
                  ),

                  // Bottom right - Settings icon (أيقونة جانبية)
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: _buildCornerIconButton(
                      icon: 'assets/images/main_menu/settings_icon.png',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ),

                  // Bottom left - About icon (أيقونة جانبية)
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: _buildCornerIconButton(
                      icon: 'assets/images/main_menu/about_icon.png',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AboutScreen(),
                          ),
                        );
                      },
                    ),
                  ),

                  // زر إعادة تحميل الفيديو
                  if (_videoError.isNotEmpty)
                    Positioned(
                      top: 120,
                      right: 20,
                      child: _buildReloadButton(),
                    ),

                  // Center content - Logo at top
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.only(top: 110),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: 20),
                          // Game title
                          Text(
                            'عالماشي .كوم',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.yellowAccent,
                              shadows: [
                                Shadow(
                                  color: textShadowColor,
                                  offset: textShadowOffset,
                                  blurRadius: textShadowBlur,
                                ),
                                Shadow(
                                  color: Colors.black,
                                  offset: Offset(2, 2),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 10),

                          Text(
                            '3almaShe.com',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white70,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 2,
                              shadows: [
                                Shadow(
                                  color: textShadowColor,
                                  offset: textShadowOffset,
                                  blurRadius: textShadowBlur,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 120),

                          // AnimatedLogo(
                          //   size: 120,
                          //   isWalking: true,
                          // ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom center - Menu buttons with curved arrangement (أيقونات رئيسية)
                  Positioned(
                    bottom: 50,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 200,
                      child: Stack(
                        children: [
                          // Store button - أعلى على اليسار
                          Positioned(
                            bottom: 60,
                            left: MediaQuery.of(context).size.width * 0.10,
                            child: _buildCenterMenuButton(
                              icon: 'assets/images/main_menu/store_icon.png',
                              text: 'المتجر',
                              onPressed: () {
                                // Add store navigation here
                              },
                            ),
                          ),

                          // Play button - في المنتصف الأسفل
                          Positioned(
                            bottom: 10,
                            left: MediaQuery.of(context).size.width * 0.5 - (mainButtonSize / 2),
                            child: _buildCenterMainButton(
                              icon: 'assets/images/main_menu/play_icon.png',
                              text: 'بدأ اللعبة',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => GameScreen(),
                                  ),
                                );
                              },
                            ),
                          ),

                          // Levels button - أعلى على اليمين
                          Positioned(
                            bottom: 60,
                            right: MediaQuery.of(context).size.width * 0.10,
                            child: _buildCenterMenuButton(
                              icon: 'assets/images/main_menu/levels_icon.png',
                              text: 'المراحل',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LevelsScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReloadButton() {
    return FloatingActionButton.small(
      onPressed: _initializeVideo,
      backgroundColor: Colors.yellow,
      foregroundColor: Colors.black,
      child: Icon(Icons.refresh),
    );
  }

  // دوال للأيقونات الجانبية (الزوايا)
  Widget _buildCornerIconButton({
    required String icon,
    required VoidCallback onPressed,
  }) {
    return _CornerIconAnimationWrapper(
      shadowBlur: cornerShadowBlur,
      shadowSpread: cornerShadowSpread,
      shadowColor: cornerShadowColor,
      shadowOffset: cornerShadowOffset,
      buttonSize: cornerButtonSize,
      iconSize: cornerIconSize,
      child: IconButton(
        icon: Image.asset(
          icon,
          width: cornerIconSize,
          height: cornerIconSize,
        ),
        onPressed: onPressed,
      ),
    );
  }

  // دوال للأيقونات الرئيسية (الوسط) - ظل دائري
  Widget _buildCenterMainButton({
    required String icon,
    required String text,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        _CenterIconAnimationWrapper(
          shadowBlur: centerShadowBlur,
          shadowSpread: centerShadowSpread,
          shadowColor: centerShadowColor,
          shadowOffset: centerShadowOffset,
          buttonSize: mainButtonSize,
          child: _buildMainIcon(
            icon: icon,
            onPressed: onPressed,
          ),
        ),
        SizedBox(height: 10),
        _buildMainText(text: text),
      ],
    );
  }

  Widget _buildCenterMenuButton({
    required String icon,
    required String text,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        _CenterIconAnimationWrapper(
          shadowBlur: centerShadowBlur,
          shadowSpread: centerShadowSpread,
          shadowColor: centerShadowColor,
          shadowOffset: centerShadowOffset,
          buttonSize: menuButtonSize,
          child: _buildMenuIcon(
            icon: icon,
            onPressed: onPressed,
          ),
        ),
        SizedBox(height: 8),
        _buildMenuText(text: text),
      ],
    );
  }

  Widget _buildMainIcon({
    required String icon,
    required VoidCallback onPressed,
  }) {
    final iconSize = 85.0 * centerIconSizeMultiplier;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: mainButtonSize,
        height: mainButtonSize,
        child: Center(
          child: Image.asset(
            icon,
            width: iconSize,
            height: iconSize,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuIcon({
    required String icon,
    required VoidCallback onPressed,
  }) {
    final iconSize = 65.0 * centerIconSizeMultiplier;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: menuButtonSize,
        height: menuButtonSize,
        child: Center(
          child: Image.asset(
            icon,
            width: iconSize,
            height: iconSize,
          ),
        ),
      ),
    );
  }

  Widget _buildMainText({required String text}) {
    final fontSize = mainTextSize * textSizeMultiplier;

    return Text(
      text,
      style: TextStyle(
        color: Colors.white,
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            color: textShadowColor,
            offset: textShadowOffset,
            blurRadius: textShadowBlur,
          ),
          Shadow(
            color: Colors.black,
            offset: Offset(1, 1),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuText({required String text}) {
    final fontSize = menuTextSize * textSizeMultiplier;

    return Text(
      text,
      style: TextStyle(
        color: Colors.white,
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            color: textShadowColor,
            offset: textShadowOffset,
            blurRadius: textShadowBlur,
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('إعدادات الظل والحجم'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // إعدادات الأيقونات الجانبية
                Text('الأيقونات الجانبية:', style: TextStyle(fontWeight: FontWeight.bold)),
                _buildShadowSetting('وضوح الظل', cornerShadowBlur, 0.0, 20.0, (value) {
                  setState(() => cornerShadowBlur = value);
                }),
                _buildShadowSetting('انتشار الظل', cornerShadowSpread, 0.0, 10.0, (value) {
                  setState(() => cornerShadowSpread = value);
                }),
                _buildShadowSetting('إزاحة X', cornerShadowOffset.dx, -10.0, 10.0, (value) {
                  setState(() => cornerShadowOffset = Offset(value, cornerShadowOffset.dy));
                }),
                _buildShadowSetting('إزاحة Y', cornerShadowOffset.dy, -10.0, 10.0, (value) {
                  setState(() => cornerShadowOffset = Offset(cornerShadowOffset.dx, value));
                }),
                _buildShadowSetting('حجم الأيقونة', cornerIconSize, 30.0, 80.0, (value) {
                  setState(() => cornerIconSize = value);
                }),
                _buildShadowSetting('حجم الزر', cornerButtonSize, 40.0, 100.0, (value) {
                  setState(() => cornerButtonSize = value);
                }),

                SizedBox(height: 20),

                // إعدادات الأيقونات الرئيسية
                Text('الأيقونات الرئيسية:', style: TextStyle(fontWeight: FontWeight.bold)),
                _buildShadowSetting('وضوح الظل', centerShadowBlur, 0.0, 40.0, (value) {
                  setState(() => centerShadowBlur = value);
                }),
                _buildShadowSetting('انتشار الظل', centerShadowSpread, 0.0, 20.0, (value) {
                  setState(() => centerShadowSpread = value);
                }),
                _buildShadowSetting('إزاحة X', centerShadowOffset.dx, -10.0, 10.0, (value) {
                  setState(() => centerShadowOffset = Offset(value, centerShadowOffset.dy));
                }),
                _buildShadowSetting('إزاحة Y', centerShadowOffset.dy, -10.0, 10.0, (value) {
                  setState(() => centerShadowOffset = Offset(centerShadowOffset.dx, value));
                }),
                _buildShadowSetting('مضاعف حجم الأيقونة', centerIconSizeMultiplier, 0.5, 2.5, (value) {
                  setState(() => centerIconSizeMultiplier = value);
                }),
                _buildShadowSetting('حجم الزر الرئيسي', mainButtonSize, 80.0, 200.0, (value) {
                  setState(() => mainButtonSize = value);
                }),
                _buildShadowSetting('حجم الأزرار الجانبية', menuButtonSize, 60.0, 150.0, (value) {
                  setState(() => menuButtonSize = value);
                }),

                SizedBox(height: 20),

                // إعدادات النصوص
                Text('النصوص:', style: TextStyle(fontWeight: FontWeight.bold)),
                _buildShadowSetting('وضوح ظل النص', textShadowBlur, 0.0, 20.0, (value) {
                  setState(() => textShadowBlur = value);
                }),
                _buildShadowSetting('إزاحة X للنص', textShadowOffset.dx, -5.0, 5.0, (value) {
                  setState(() => textShadowOffset = Offset(value, textShadowOffset.dy));
                }),
                _buildShadowSetting('إزاحة Y للنص', textShadowOffset.dy, -5.0, 5.0, (value) {
                  setState(() => textShadowOffset = Offset(textShadowOffset.dx, value));
                }),
                _buildShadowSetting('حجم النص الرئيسي', mainTextSize, 12.0, 30.0, (value) {
                  setState(() => mainTextSize = value);
                }),
                _buildShadowSetting('حجم النص الجانبي', menuTextSize, 10.0, 24.0, (value) {
                  setState(() => menuTextSize = value);
                }),
                _buildShadowSetting('مضاعف حجم النص', textSizeMultiplier, 0.5, 2.0, (value) {
                  setState(() => textSizeMultiplier = value);
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('تم'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildShadowSetting(String title, double value, double min, double max, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$title: ${value.toStringAsFixed(1)}'),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
        ),
        SizedBox(height: 8),
      ],
    );
  }

  void _shareGame(BuildContext context) {
    // Implement share functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('مشاركة اللعبة'),
        content: Text('سيتم تفعيل خاصية المشاركة قريباً'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('حسناً'),
          ),
        ],
      ),
    );
  }

  void _openLikeLink(BuildContext context) {
    // Implement opening like link
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('دعم اللعبة'),
        content: Text('سيتم تفعيل خاصية التقييم قريباً'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('حسناً'),
          ),
        ],
      ),
    );
  }
}

// كلاس للأيقونات الجانبية (الزوايا) - ظل دائري
class _CornerIconAnimationWrapper extends StatefulWidget {
  final Widget child;
  final double shadowBlur;
  final double shadowSpread;
  final Color shadowColor;
  final Offset shadowOffset;
  final double buttonSize;
  final double iconSize;

  const _CornerIconAnimationWrapper({
    required this.child,
    required this.shadowBlur,
    required this.shadowSpread,
    required this.shadowColor,
    required this.shadowOffset,
    required this.buttonSize,
    required this.iconSize,
  });

  @override
  State<_CornerIconAnimationWrapper> createState() => _CornerIconAnimationWrapperState();
}

class _CornerIconAnimationWrapperState extends State<_CornerIconAnimationWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.85,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: widget.buttonSize,
                height: widget.buttonSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.shadowColor,
                      blurRadius: widget.shadowBlur,
                      spreadRadius: widget.shadowSpread,
                      offset: widget.shadowOffset,
                    ),
                  ],
                ),
                child: child,
              ),
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}

// كلاس للأيقونات الرئيسية (الوسط) - ظل دائري
class _CenterIconAnimationWrapper extends StatefulWidget {
  final Widget child;
  final double shadowBlur;
  final double shadowSpread;
  final Color shadowColor;
  final Offset shadowOffset;
  final double buttonSize;

  const _CenterIconAnimationWrapper({
    required this.child,
    required this.shadowBlur,
    required this.shadowSpread,
    required this.shadowColor,
    required this.shadowOffset,
    required this.buttonSize,
  });

  @override
  State<_CenterIconAnimationWrapper> createState() => _CenterIconAnimationWrapperState();
}

class _CenterIconAnimationWrapperState extends State<_CenterIconAnimationWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: widget.buttonSize,
                height: widget.buttonSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.shadowColor,
                      blurRadius: widget.shadowBlur,
                      spreadRadius: widget.shadowSpread,
                      offset: widget.shadowOffset,
                    ),
                  ],
                ),
                child: child,
              ),
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}