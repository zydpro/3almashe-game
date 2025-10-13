import 'package:almashe_game/screens/splash_screens.dart';
import 'package:almashe_game/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'Languages/LanguageProvider.dart';
import 'screens/main_menu_screen.dart';
import 'services/ads_service.dart';
import 'services/audio_service.dart';
import 'services/image_service.dart';
import 'package:almashe_game/Languages/localization.dart';
import 'package:almashe_game/Languages/language_service.dart'; // تم التصحيح هنا

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة الخدمات
  await SettingsService().initialize();
  await AdsService.initialize();
  await AudioService().initialize();
  await LanguageService.initialize(); // إضافة تهيئة خدمة اللغة

  // تحسين الأداء - إخفاء debugPrint في الإصدار النهائي
  debugPrint = (String? message, {int? wrapWidth}) {
    // يمكن تركها فارغة أو تسجيل في ملف بدلاً من الكونسول
  };

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: const AlmasheGame(),
    ),
  );
}

class AlmasheGame extends StatelessWidget {
  const AlmasheGame({super.key});

  @override
  Widget build(BuildContext context) {
    // precache الصور عند بدء التطبيق
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ImageService.preloadImages(context);
    });

    return Consumer<LanguageProvider>( // ✅ استخدام Consumer للوصول إلى LanguageProvider
      builder: (context, languageProvider, child) {
        return MaterialApp(
          title: 'عالماشي - 3almashe',
          debugShowCheckedModeBanner: false,

          // ✅ إعدادات الترجمة - استخدم الـ locale من الـ Provider
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            const Locale('ar'), // العربية
            const Locale('en'), // الإنجليزية
          ],
          locale: languageProvider.locale, // ✅ الآن يعمل بشكل صحيح

          theme: ThemeData(
            primarySwatch: Colors.blue,
            fontFamily: 'Cairo',
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
          // home: const SplashScreens(),
          home: const MainMenuScreen(),
        );
      },
    );
  }
}