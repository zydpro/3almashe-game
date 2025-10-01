import 'package:flutter/material.dart';
import 'screens/main_menu_screen.dart'; // تأكد من وجود هذا المسار
import 'services/ads_service.dart';
import 'services/audio_service.dart';
import 'services/image_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  await AdsService.initialize();
  await AudioService().initialize();

  runApp(const AlmasheGame());
}

class AlmasheGame extends StatelessWidget {
  const AlmasheGame({super.key});

  @override
  Widget build(BuildContext context) {
    // precache الصور عند بدء التطبيق
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ImageService.preloadImages(context);
    });

    return MaterialApp(
      title: 'عالماشي - 3almashe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Cairo', // تأكد من match مع pubspec.yaml
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontFamily: 'Cairo'),
          bodyMedium: TextStyle(fontFamily: 'Cairo'),
          displayLarge: TextStyle(fontFamily: 'Cairo'),
          displayMedium: TextStyle(fontFamily: 'Cairo'),
          displaySmall: TextStyle(fontFamily: 'Cairo'),
          headlineLarge: TextStyle(fontFamily: 'Cairo'),
          headlineMedium: TextStyle(fontFamily: 'Cairo'),
          headlineSmall: TextStyle(fontFamily: 'Cairo'),
          titleLarge: TextStyle(fontFamily: 'Cairo'),
          titleMedium: TextStyle(fontFamily: 'Cairo'),
          titleSmall: TextStyle(fontFamily: 'Cairo'),
          labelLarge: TextStyle(fontFamily: 'Cairo'),
          labelMedium: TextStyle(fontFamily: 'Cairo'),
          labelSmall: TextStyle(fontFamily: 'Cairo'),
          bodySmall: TextStyle(fontFamily: 'Cairo'),
        ),
      ),
      home: const MainMenuScreen(),
    );
  }
}