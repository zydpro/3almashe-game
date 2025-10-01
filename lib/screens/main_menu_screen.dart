import 'package:flutter/material.dart';
import '../widgets/animated_logo.dart';
import '../widgets/game_button.dart';
import 'game_screen.dart';
import 'levels_screen.dart';
import 'settings_screen.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2E4057),
              Color(0xFF048A81),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Logo and title section
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated logo
                    const AnimatedLogo(
                      size: 180,
                      isWalking: true,
                    ),
                    const SizedBox(height: 30),
                    
                    // Game title with animation
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 1500),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Opacity(
                            opacity: value,
                            child: Column(
                              children: [
                                Text(
                                  'عالماشي .كوم',
                                  style: TextStyle(
                                    fontSize: 48 * value,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    shadows: const [
                                      Shadow(
                                        color: Colors.black54,
                                        offset: Offset(2, 2),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '3almaShe.com',
                                  style: TextStyle(
                                    fontSize: 24 * value,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              // Menu buttons section
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GameButton(
                        text: 'ابدأ اللعب',
                        icon: Icons.play_arrow,
                        color: const Color(0xFF4CAF50),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const GameScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 15),
                      
                      GameButton(
                        text: 'المراحل',
                        icon: Icons.list,
                        color: const Color(0xFF2196F3),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LevelsScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 15),
                      
                      GameButton(
                        text: 'الإعدادات',
                        icon: Icons.settings,
                        color: const Color(0xFF9C27B0),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SettingsScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 15),
                      
                      GameButton(
                        text: 'حول اللعبة',
                        icon: Icons.info,
                        color: const Color(0xFF607D8B),
                        onPressed: () {
                          _showAboutDialog(context);
                        },
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
  }
  
  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('حول اللعبة'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'عالماشي .كوم\n'
                      '3almaShe.com',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: 10),
                Text('الإصدار: 1.0.0'),
                SizedBox(height: 10),
                Text(
                  'لعبة جري لا نهائية ممتعة تتميز بشخصية عالماشي المحبوبة. تجنب العقبات، اجمع النقاط، وتقدم عبر المراحل المختلفة!\n'
                      'هذه لعبة ترفيهية تابعة لموقع التسوق الأضخم في سوريا موقع عالماشي يمكنكم زيارتنا على الموقع ونشر إعلاناتكم مجانا\n'
                      'فقط اكتب في المتصفح أو ابحث في جوجل:',
                ),
                SizedBox(height: 8),

                Center(
                  child: Text(
                    'عالماشي .كوم\n'
                        'WWW.3almaShe.com',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20),
                  ),
                ),

                SizedBox(height: 10),
                Text(
                  'المطور: فريق عالماشي',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('إغلاق'),
              ),
            ],
          ),
        );
      },
    );
  }
}