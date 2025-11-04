import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../Languages/localization.dart';
import 'main_menu_screen.dart';

class SplashScreens extends StatefulWidget {
  const SplashScreens({super.key});

  @override
  State<SplashScreens> createState() => _SplashScreensState();
}

class _SplashScreensState extends State<SplashScreens>
    with SingleTickerProviderStateMixin {

  // اعدادات اللغة
  late AnimationController _languageAnimationController;
  late Animation<double> _languageScaleAnimation;

  late AnimationController _controller;
  late Animation<double> _heroAnimation;
  late Animation<double> _textAnimation;
  late Animation<double> _enemyAnimation;
  late Animation<double> _collisionAnimation;
  late Animation<Color?> _backgroundColor;
  late Animation<double> _glowAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _finalGlowAnimation;
  late Animation<double> _screenBreakAnimation;

  bool _showCollision = false;
  bool _showFinalEffect = false;
  bool _showScreenBreak = false;
  bool _transitionToMain = false;
  final List<Particle> _particles = [];
  final List<ScreenCrack> _cracks = [];
  final Random _random = Random();
  Timer? _particleTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 5), // تقليل المدة إلى 5 ثواني
      vsync: this,
    );

    _heroAnimation = Tween<double>(
      begin: -1.0,
      end: 0.15,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ));

    _enemyAnimation = Tween<double>(
      begin: 1.0,
      end: 0.25,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic),
    ));

    _collisionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.7, 0.85, curve: Curves.elasticOut),
    ));

    _textAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.9, curve: Curves.easeInOutCubic),
    ));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 0.9, curve: Curves.easeInOut),
    ));

    _finalGlowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.85, 0.95, curve: Curves.easeInOut),
    ));

    _screenBreakAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.95, 1.0, curve: Curves.easeIn),
    ));

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.9, 0.95, curve: Curves.easeIn),
    ));

    _backgroundColor = ColorTween(
      begin: const Color(0xFF0A0E21),
      end: const Color(0xFF1A1A3A),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _createParticles();
    _createCracks();

    _controller.forward();

    Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _showCollision = true;
          _createExplosionParticles();
        });
      }
    });

    Timer(const Duration(milliseconds: 3500), () {
      if (mounted) {
        setState(() {
          _showFinalEffect = true;
          _createFinalParticles();
        });
      }
    });

    _startGame();
  }

  void _createParticles() {
    for (int i = 0; i < 25; i++) {
      _particles.add(Particle(
        x: _random.nextDouble() * 400,
        y: _random.nextDouble() * 800,
        vx: (_random.nextDouble() - 0.5) * 0.2,
        vy: (_random.nextDouble() - 0.5) * 0.2,
        size: _random.nextDouble() * 1.5 + 0.5,
        color: _getRandomStarColor(),
      ));
    }
  }

  void _createCracks() {
    for (int i = 0; i < 15; i++) {
      _cracks.add(ScreenCrack(
        startX: _random.nextDouble(),
        startY: _random.nextDouble(),
        endX: _random.nextDouble(),
        endY: _random.nextDouble(),
        width: _random.nextDouble() * 3 + 1,
      ));
    }
  }

  void _createExplosionParticles() {
    for (int i = 0; i < 15; i++) {
      _particles.add(Particle(
        x: 200,
        y: 300,
        vx: (_random.nextDouble() - 0.5) * 4,
        vy: (_random.nextDouble() - 0.5) * 4,
        size: _random.nextDouble() * 3 + 1,
        color: _getRandomExplosionColor(),
        life: 1.5,
      ));
    }
  }

  void _createFinalParticles() {
    for (int i = 0; i < 20; i++) {
      _particles.add(Particle(
        x: 200,
        y: 400,
        vx: (_random.nextDouble() - 0.5) * 3,
        vy: -_random.nextDouble() * 4 - 2,
        size: _random.nextDouble() * 4 + 2,
        color: _getRandomFinalColor(),
        life: 2.0,
      ));
    }
  }

  void _createScreenBreakParticles() {
    for (int i = 0; i < 30; i++) {
      _particles.add(Particle(
        x: _random.nextDouble() * 400,
        y: _random.nextDouble() * 800,
        vx: (_random.nextDouble() - 0.5) * 10,
        vy: (_random.nextDouble() - 0.5) * 10,
        size: _random.nextDouble() * 8 + 4,
        color: _getRandomScreenBreakColor(),
        life: 1.0,
      ));
    }
  }

  Color _getRandomStarColor() {
    final colors = [
      const Color(0xFF4FC3F7),
      const Color(0xFF29B6F6),
      const Color(0xFF03A9F4),
      const Color(0xFF81D4FA),
    ];
    return colors[_random.nextInt(colors.length)];
  }

  Color _getRandomExplosionColor() {
    final colors = [
      const Color(0xFFFFD54F),
      const Color(0xFFFFB74D),
      const Color(0xFFFF8A65),
      const Color(0xFF4FC3F7),
    ];
    return colors[_random.nextInt(colors.length)];
  }

  Color _getRandomFinalColor() {
    final colors = [
      const Color(0xFFFFD54F),
      const Color(0xFFFFEB3B),
      const Color(0xFF4FC3F7),
      const Color(0xFF29B6F6),
      const Color(0xFFAB47BC),
    ];
    return colors[_random.nextInt(colors.length)];
  }

  Color _getRandomScreenBreakColor() {
    final colors = [
      const Color(0xFFFFFFFF),
      const Color(0xFFFFD54F),
      const Color(0xFF4FC3F7),
      const Color(0xFFAB47BC),
      const Color(0xFFEF5350),
    ];
    return colors[_random.nextInt(colors.length)];
  }

  void _updateParticles() {
    _particles.removeWhere((particle) => particle.life <= 0);
    for (var particle in _particles) {
      particle.x += particle.vx;
      particle.y += particle.vy;
      particle.life -= 0.01;

      particle.vx *= 0.98;
      particle.vy *= 0.98;
    }
  }

  void _startGame() async {
    _particleTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (mounted) {
        setState(() {
          _updateParticles();
        });
      } else {
        timer.cancel();
      }
    });

    // الانتظار 3.5 ثانية ثم بدء تأثير كسر الشاشة
    await Future.delayed(const Duration(milliseconds: 5000));

    if (mounted) {
      setState(() {
        _showScreenBreak = true;
        _createScreenBreakParticles();
      });

      // الانتقال السريع بعد 500 مللي ثانية من كسر الشاشة
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        setState(() {
          _transitionToMain = true;
        });

        // الانتقال الفوري إلى الشاشة الرئيسية
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
            pageBuilder: (context, animation, secondaryAnimation) => const MainMenuScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Languages = AppLocalizations.of(context);

    if (_transitionToMain) {
      return const MainMenuScreen();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: _backgroundColor.value ?? const Color(0xFF0A0E21),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final collisionScale = _collisionAnimation.value.clamp(0.0, 1.0);
          final textOpacity = _textAnimation.value.clamp(0.0, 1.0);
          final glowValue = _glowAnimation.value.clamp(0.0, 1.0);
          final fadeValue = _fadeAnimation.value.clamp(0.0, 1.0);
          final finalGlowValue = _finalGlowAnimation.value.clamp(0.0, 1.0);
          final screenBreakValue = _screenBreakAnimation.value.clamp(0.0, 1.0);

          return Stack(
            children: [
              // الخلفية الكونية المتدرجة
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.5,
                    colors: [
                      const Color(0xFF1A237E).withOpacity(0.8),
                      const Color(0xFF0A0E21).withOpacity(0.9),
                      const Color(0xFF050817),
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              ),

              // النجوم المتحركة
              for (final particle in _particles)
                Positioned(
                  left: particle.x,
                  top: particle.y,
                  child: Opacity(
                    opacity: particle.life.clamp(0.0, 1.0) * fadeValue,
                    child: Container(
                      width: particle.size,
                      height: particle.size,
                      decoration: BoxDecoration(
                        color: particle.color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: particle.color.withOpacity(0.6),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // الضباب الكوني
              Positioned.fill(
                child: Opacity(
                  opacity: fadeValue,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.topRight,
                        radius: 1.2,
                        colors: [
                          const Color(0xFF3949AB).withOpacity(0.08),
                          const Color(0xFF1A237E).withOpacity(0.03),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // البطل (يدخل من اليسار)
              Positioned(
                left: screenWidth * _heroAnimation.value.clamp(-1.0, 1.0),
                top: screenHeight * 0.3,
                child: Opacity(
                  opacity: fadeValue,
                  child: _buildHeroCharacter(glowValue),
                ),
              ),

              // الزعيم (يدخل من اليمين)
              Positioned(
                right: screenWidth * _enemyAnimation.value.clamp(-1.0, 1.0),
                top: screenHeight * 0.3,
                child: Opacity(
                  opacity: fadeValue,
                  child: _buildBossCharacter(glowValue),
                ),
              ),

              // تأثير التصادم المذهل
              if (_showCollision)
                Positioned(
                  left: screenWidth * 0.4,
                  top: screenHeight * 0.35,
                  child: Opacity(
                    opacity: fadeValue,
                    child: Transform.scale(
                      scale: collisionScale,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFFFFD54F).withOpacity(0.4),
                                  const Color(0xFFFFB74D).withOpacity(0.2),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                            ),
                          ),

                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.white.withOpacity(0.6),
                                  const Color(0xFFFFD54F).withOpacity(0.4),
                                  const Color(0xFFFFB74D).withOpacity(0.2),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // التأثير النهائي (قبل الانتقال)
              if (_showFinalEffect)
                Positioned(
                  left: screenWidth * 0.3,
                  right: screenWidth * 0.3,
                  top: screenHeight * 0.2,
                  bottom: screenHeight * 0.2,
                  child: Opacity(
                    opacity: finalGlowValue * fadeValue,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFFFD54F).withOpacity(0.3),
                            const Color(0xFF4FC3F7).withOpacity(0.2),
                            Colors.transparent,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  ),
                ),

              // تأثير كسر الشاشة
              if (_showScreenBreak) ...[
                // توهج أبيض
                Positioned.fill(
                  child: Container(
                    color: Colors.white.withOpacity(screenBreakValue * 0.3),
                  ),
                ),

                // جسيمات الانفجار الكبيرة
                for (final particle in _particles.where((p) => p.size > 5))
                  Positioned(
                    left: particle.x,
                    top: particle.y,
                    child: Opacity(
                      opacity: particle.life.clamp(0.0, 1.0),
                      child: Container(
                        width: particle.size,
                        height: particle.size,
                        decoration: BoxDecoration(
                          color: particle.color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: particle.color.withOpacity(0.8),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // خطوط التكسير
                Positioned.fill(
                  child: CustomPaint(
                    painter: ScreenBreakPainter(
                      progress: screenBreakValue,
                      cracks: _cracks,
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                    ),
                  ),
                ),
              ],

              // النص الرئيسي مع تأثيرات متطورة
              Positioned(
                bottom: screenHeight * 0.22,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: textOpacity * fadeValue * (1 - screenBreakValue),
                  child: Column(
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) {
                          return const LinearGradient(
                            colors: [
                              Color(0xFF4FC3F7),
                              Color(0xFF29B6F6),
                              Color(0xFF03A9F4),
                            ],
                            stops: [0.0, 0.5, 1.0],
                          ).createShader(bounds);
                        },
                        child: Text(
                          'عالماشي .كوم',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.8),
                                blurRadius: 12,
                                offset: const Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        '3almaShe.com',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFFAFAFA),
                          letterSpacing: 1.2,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.6),
                              blurRadius: 6,
                              offset: const Offset(1, 1),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      Text(
                        Languages.flash,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFFFD54F),
                          letterSpacing: 1.2,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.6),
                              blurRadius: 6,
                              offset: const Offset(1, 1),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      _buildPowerUpIndicators(),

                      const SizedBox(height: 25),

                      _buildAdvancedLoadingBar(),
                    ],
                  ),
                ),
              ),

              // تأثيرات إضافية
              Positioned.fill(
                child: Opacity(
                  opacity: fadeValue * (1 - screenBreakValue),
                  child: _buildGlowEffects(glowValue),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeroCharacter(double glowValue) {
    return Transform.scale(
      scale: 1.0 + glowValue * 0.08,
      child: Container(
        width: 130,
        height: 130,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const SweepGradient(
            colors: [
              Color(0xFF4FC3F7),
              Color(0xFF29B6F6),
              Color(0xFF03A9F4),
              Color(0xFF4FC3F7),
            ],
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.7),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF29B6F6).withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 115,
              height: 115,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),

            const Icon(
              Icons.directions_run_rounded,
              size: 60,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBossCharacter(double glowValue) {
    return Transform.scale(
      scale: 0.9 + glowValue * 0.04,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const SweepGradient(
            colors: [
              Color(0xFFAB47BC),
              Color(0xFF8E24AA),
              Color(0xFF7B1FA2),
              Color(0xFFAB47BC),
            ],
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.7),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8E24AA).withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 105,
              height: 105,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),

            const Icon(
              Icons.diamond,
              size: 55,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPowerUpIndicators() {
    final Languages = AppLocalizations.of(context);

    return Wrap(
      spacing: 16,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        _buildPowerUpIcon(Icons.bolt, const Color(0xFFFFD54F), Languages.speed),
        _buildPowerUpIcon(Icons.shield, const Color(0xFF4FC3F7), Languages.shield),
        _buildPowerUpIcon(Icons.favorite, const Color(0xFFEF5350), Languages.health),
        _buildPowerUpIcon(Icons.slow_motion_video, const Color(0xFF66BB6A), Languages.slow),
      ],
    );
  }

  Widget _buildPowerUpIcon(IconData icon, Color color, String text) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.3),
                color.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.6),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedLoadingBar() {
    final progress = _controller.value.clamp(0.0, 1.0);

    return Container(
      width: 250,
      height: 14,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              color: Colors.white.withOpacity(0.05),
            ),
          ),

          AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: 250 * progress,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF4FC3F7),
                  Color(0xFF29B6F6),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlowEffects(double glowValue) {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.4, 0.3),
            radius: 0.3 + glowValue * 0.08,
            colors: [
              const Color(0xFF4FC3F7).withOpacity(0.08 * glowValue),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _particleTimer?.cancel();
    super.dispose();
  }
}

class Particle {
  double x, y, vx, vy, size, life;
  Color color;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    this.life = 1.0,
  });
}

class ScreenCrack {
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final double width;

  ScreenCrack({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.width,
  });
}

class ScreenBreakPainter extends CustomPainter {
  final double progress;
  final List<ScreenCrack> cracks;
  final double screenWidth;
  final double screenHeight;

  ScreenBreakPainter({
    required this.progress,
    required this.cracks,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(progress * 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * progress
      ..strokeCap = StrokeCap.round;

    for (final crack in cracks) {
      final path = Path()
        ..moveTo(crack.startX * screenWidth, crack.startY * screenHeight)
        ..lineTo(crack.endX * screenWidth, crack.endY * screenHeight);

      canvas.drawPath(path, paint);
    }

    // إضافة خطوط تكسير إضافية
    for (int i = 0; i < 10; i++) {
      final startX = Random().nextDouble() * screenWidth;
      final startY = Random().nextDouble() * screenHeight;
      final endX = startX + (Random().nextDouble() - 0.5) * 100 * progress;
      final endY = startY + (Random().nextDouble() - 0.5) * 100 * progress;

      final path = Path()
        ..moveTo(startX, startY)
        ..lineTo(endX, endY);

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ScreenBreakPainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}